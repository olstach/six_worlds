# tools/test_content_model.py
import json, os, sys, tempfile, shutil, unittest
from pathlib import Path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from content import jsonio, mdformat
from content.model import Doc, Group, Entry, Field
ROOT = Path(__file__).resolve().parent.parent

class JsonIOTests(unittest.TestCase):
    def test_detect_indent(self):
        self.assertEqual(jsonio.detect_indent('{\n\t"a": 1\n}\n'), "\t")
        self.assertEqual(jsonio.detect_indent('{\n  "a": {\n    "b": 1\n  }\n}\n'), 2)

    def test_canonical_is_stable_and_unescaped(self):
        obj = {"name": "Pāramitā — ✨", "n": [1, 2]}
        once = jsonio.canonical_dumps(obj, 2)
        self.assertIn("Pāramitā — ✨", once)          # no \\u escapes
        self.assertEqual(jsonio.canonical_dumps(json.loads(once), 2), once)
        self.assertTrue(once.endswith("\n"))

    def test_set_at_writes_only_dirty_file(self):
        tmp = Path(tempfile.mkdtemp())
        shutil.copytree(ROOT / "resources/data", tmp / "resources/data")
        ds = jsonio.DataSet.load(tmp)
        path = ("resources/data/skills.json", "skills", "swords", "description")
        ds.set_at(path, "Edited.")
        self.assertEqual(ds.write_dirty(), ["resources/data/skills.json"])
        again = jsonio.DataSet.load(tmp)
        self.assertEqual(again.get_at(path), "Edited.")

    def test_list_index_paths(self):
        ds = jsonio.DataSet.load(ROOT)
        first = ds.get_at(("resources/data/statuses.json", "statuses", 0, "name"))
        self.assertIsInstance(first, str)

def sample_doc():
    choice = Entry(key="events:e1/choices:watch", title="Watch from the stands",
                   ident="watch", tag="grey",
                   fields=[Field("result", "You learn nothing.", "text", ("f", "r"))])
    e = Entry(key="events:e1", title="Bone Arena", ident="e1", title_path=("f", "t"),
              context="realm: hell",
              fields=[Field("text", "Line one.\n\nLine two — with - dash\n- not a list",
                            "text", ("f", "x")),
                      Field("skills", ["swords", "yoga"], "list", ("f", "s")),
                      Field("flavor", "", "text", ("f", "fl")),
                      Field("cost", "140 gold", "context")],
              children=[choice], children_label="choices", notes="keep this")
    return Doc(inbox="raw idea: a goat oracle\n\n- with a list",
               sections=[Group("Events", 1, groups=[Group("Hell", 2, "hell", entries=[e])])])


class FormatTests(unittest.TestCase):
    def test_round_trip(self):
        text = mdformat.render(sample_doc())
        p = mdformat.parse(text)
        self.assertEqual(p.inbox.strip(), "raw idea: a goat oracle\n\n- with a list")
        (entry,) = p.entries.values()
        self.assertEqual(entry.fields["text"], "Line one.\n\nLine two — with - dash\n- not a list")
        self.assertEqual(entry.fields["skills"], ["swords", "yoga"])
        self.assertEqual(entry.fields["flavor"], "")
        self.assertEqual(entry.notes, "keep this")
        self.assertEqual(entry.children[0].fields["result"], "You learn nothing.")
        self.assertEqual(entry.children[0].tag, "grey")
        self.assertEqual(mdformat.render(sample_doc()), text)    # deterministic
        self.assertEqual(p.stray, [])

    def test_tabs_and_crlf(self):
        text = mdformat.render(sample_doc()).replace("  ", "\t").replace("\n", "\r\n")
        p = mdformat.parse(text)
        (entry,) = p.entries.values()
        self.assertEqual(entry.fields["skills"], ["swords", "yoga"])
        self.assertEqual(entry.children[0].fields["result"], "You learn nothing.")

    def test_unicode_survives(self):
        d = sample_doc()
        d.sections[0].groups[0].entries[0].fields[0].value = "Pāramitā ✨ — `odd`"
        p = mdformat.parse(mdformat.render(d))
        (entry,) = p.entries.values()
        self.assertEqual(entry.fields["text"], "Pāramitā ✨ — `odd`")

    def test_stray_line_is_collected_not_raised(self):
        text = mdformat.render(sample_doc()).replace(
            "  - notes:", "this line is nonsense\n  - notes:")
        p = mdformat.parse(text)
        self.assertEqual(len(p.stray), 1)
        self.assertIn("Events › Hell", p.stray[0][0])

    def test_location_keys_match_location_index(self):
        d = sample_doc()
        p = mdformat.parse(mdformat.render(d))
        idx = mdformat.location_index(d)
        self.assertEqual(list(p.entries), list(idx))
        self.assertEqual(list(idx), ["Events › Hell › e1"])
        for key, parsed in p.entries.items():
            self.assertEqual(parsed.ident, idx[key].ident)
            self.assertEqual(parsed.children[0].location, key + "/watch")

    def test_inbox_ends_at_world_line(self):
        text = "# Inbox\n\n# not a section\nidea\n\n# World\n## A `a`\n\n- **X** `x`\n"
        p = mdformat.parse(text)
        self.assertEqual(p.inbox, "# not a section\nidea")
        self.assertEqual(list(p.entries), ["World › A › x"])

    def test_inbox_ends_at_first_h1_without_world(self):
        text = "# Inbox\n\nnote\n\n# Traits\n\n- **X** `x`\n  - a: b\n"
        p = mdformat.parse(text)
        self.assertEqual(p.inbox, "note")
        self.assertEqual(list(p.entries), ["Traits › x"])
        self.assertEqual(p.entries["Traits › x"].fields["a"], "b")

    def test_raw_is_exact_source_lines(self):
        text = mdformat.render(sample_doc())
        (entry,) = mdformat.parse(text).entries.values()
        start = text.index("- **Bone Arena**")
        self.assertEqual(entry.raw, text[start:].rstrip("\n"))

    def test_field_value_ending_in_backticks_is_a_field(self):
        text = "# Inbox\n\n# T\n\n- **X** `x`\n  - note: see `fire`\n"
        (e,) = mdformat.parse(text).entries.values()
        self.assertEqual(e.fields["note"], "see `fire`")

    def test_long_and_odd_text_uses_blocks(self):
        d = sample_doc()
        d.sections[0].groups[0].entries[0].fields[0].value = "x" * 200
        (e,) = mdformat.parse(mdformat.render(d)).entries.values()
        self.assertEqual(e.fields["text"], "x" * 200)

    def test_duplicate_idents_are_kept(self):
        d = sample_doc()
        g = d.sections[0].groups[0]
        g.entries.append(Entry(key="k2", title="Other", ident="e1"))
        p = mdformat.parse(mdformat.render(d))
        self.assertEqual(len(p.entries), 2)


if __name__ == "__main__":
    unittest.main()
