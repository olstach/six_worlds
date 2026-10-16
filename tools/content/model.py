"""The shapes CONTENT.md is built from.

An Entry is one record (a spell, a companion, an event, a choice inside an
event). Its Fields are the lines under it. Groups are headings. A Doc is the
whole file: the Inbox text plus the section headings.
"""
from dataclasses import dataclass, field
from typing import Literal

EMPTY = "(empty)"


@dataclass
class Field:
    name: str
    value: object                 # str for text/context, list[str] for list
    kind: Literal["text", "list", "context"] = "text"
    path: tuple = ()              # JSON address; () for context fields
    # For a list of ids (skills, traits, item types): every id the game
    # knows, and where they come from (for the error message). The sync
    # refuses to import an id that is not in this set. None = free text.
    ids: object = None            # frozenset[str] or None
    ids_from: str = ""            # e.g. "resources/data/skills.json"


@dataclass
class Entry:
    key: str                      # unique, e.g. "spells:fireball"
    title: str
    ident: str                    # shown in backticks
    title_path: tuple = ()        # JSON address of the title; () = not editable
    tag: str = ""                 # e.g. "grey" -> "[grey] "
    context: str = ""             # read-only text after " — "
    fields: list = field(default_factory=list)
    children: list = field(default_factory=list)   # child Entries ("choices")
    children_label: str = ""      # the key line children hang under
    notes: str = ""


@dataclass
class Group:
    title: str
    level: int                    # 1 = "#", 2 = "##", ...
    ident: str = ""
    entries: list = field(default_factory=list)
    groups: list = field(default_factory=list)


@dataclass
class Doc:
    inbox: str = ""
    sections: list = field(default_factory=list)
