# tools/test_content_sections.py
import os, sys, unittest
from pathlib import Path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from content import jsonio, mdformat
from content.model import Doc
from content.sections import SECTIONS
ROOT = Path(__file__).resolve().parent.parent


def walk_entry(e):
    """An entry and all its descendants, at any depth."""
    yield e
    for c in e.children:
        yield from walk_entry(c)


def walk(group):
    for e in group.entries:
        yield from walk_entry(e)
    for g in group.groups:
        yield from walk(g)


def _json_value(ds, path):
    """The JSON value at path; a missing last key counts as ""."""
    try:
        return ds.get_at(path)
    except KeyError:
        ds.get_at(path[:-1])   # the parent must exist, or this raises
        return ""


def check_entry(test, ds, entry, parsed):
    """Compare one built Entry with what the PARSER read back from the text."""
    for f in entry.fields:
        if f.kind == "context":
            continue
        got = parsed.fields[f.name]
        if f.kind == "list":
            test.assertEqual(mdformat.split_list(got), f.value, (entry.key, f.name))
        else:
            test.assertEqual(got, f.value, (entry.key, f.name))
            # and the model really mirrors the JSON
            # An ABSENT writing key is shown as "" (its parent must exist,
            # so the sync can create the key); anything else must match.
            test.assertEqual(_json_value(ds, f.path), f.value, (entry.key, f.name))
    test.assertEqual(len(parsed.children), len(entry.children), entry.key)
    for ce, cp in zip(entry.children, parsed.children):
        check_entry(test, ds, ce, cp)


class SectionRoundTrip(unittest.TestCase):
    def test_every_section_round_trips_over_real_data(self):
        ds = jsonio.DataSet.load(ROOT)
        for mod in SECTIONS:
            with self.subTest(section=mod.TITLE):
                group = mod.build(ds)
                doc = Doc(sections=[group])
                text = mdformat.render(doc)
                parsed = mdformat.parse(text)
                self.assertEqual(parsed.stray, [], mod.TITLE)
                self.assertEqual([loc for loc, pe in parsed.entries.items() if pe.broken],
                                 [], mod.TITLE)
                keys = [e.key for e in walk(group)]
                self.assertEqual(len(keys), len(set(keys)), "duplicate entry keys")
                for e in walk(group):
                    self.assertNotIn("`", e.title, e.key)
                    self.assertNotIn("`", e.context, e.key)
                    self.assertNotIn("\n", e.context, e.key)
                index = mdformat.location_index(doc)
                self.assertEqual(set(index), set(parsed.entries))
                for loc, entry in index.items():
                    self.assertEqual(parsed.entries[loc].title, entry.title, loc)
                    check_entry(self, ds, entry, parsed.entries[loc])
                self.assertEqual(mdformat.render(Doc(sections=[mod.build(ds)])), text)

    def test_traits_cover_every_trait(self):
        ds = jsonio.DataSet.load(ROOT)
        from content.sections import traits
        n = sum(1 for _ in walk(traits.build(ds)))
        real = [k for k in ds.get("resources/data/traits.json") if not k.startswith("_")]
        self.assertEqual(n, len(real))


if __name__ == "__main__":
    unittest.main()
