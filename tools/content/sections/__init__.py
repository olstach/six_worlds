"""The sections of CONTENT.md, in document order. The Inbox is not a module:
the sync carries it over verbatim.

The section contract every module here follows:
  TITLE   the level-1 heading, e.g. "Traits"
  build(ds) -> Group
          a level-1 Group of subgroups and entries. Deterministic: it uses
          the data's own order, never set iteration.
  import_field(ds, entry_key, field, new_value)   (optional)
          only needed when importing a field is more than
          ds.set_at(field.path, new_value). Without it the sync uses set_at.
"""
from . import traits

SECTIONS = [traits]   # Task 5 extends this to the full ordered list
