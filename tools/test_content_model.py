# tools/test_content_model.py
import json, os, re, sys, tempfile, shutil, unittest
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
        self.assertEqual(mdformat.split_list(entry.fields["skills"]), ["swords", "yoga"])
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
        self.assertEqual(mdformat.split_list(entry.fields["skills"]), ["swords", "yoga"])
        self.assertEqual(entry.children[0].fields["result"], "You learn nothing.")

    def test_unicode_survives(self):
        d = sample_doc()
        d.sections[0].groups[0].entries[0].fields[0].value = "Pāramitā ✨ — `odd`"
        p = mdformat.parse(mdformat.render(d))
        (entry,) = p.entries.values()
        self.assertEqual(entry.fields["text"], "Pāramitā ✨ — `odd`")

    def test_stray_line_inside_an_entry_taints_it(self):
        text = mdformat.render(sample_doc()).replace(
            "  - notes:", "this line is nonsense\n  - notes:")
        p = mdformat.parse(text)
        self.assertEqual(p.stray, [])               # not moved line by line
        (e,) = p.entries.values()
        self.assertTrue(e.broken)
        self.assertIn("this line is nonsense", e.raw)
        self.assertIn("keep this", e.raw)           # the WHOLE entry, to the end
        self.assertTrue(e.raw.startswith("- **Bone Arena**"))

    def test_stray_lines_in_a_region_are_one_chunk(self):
        text = ("# Inbox\n\n# T\n\nloose one\n\nloose two\n\n- **X** `x`\n  - a: b\n")
        p = mdformat.parse(text)
        self.assertEqual(p.stray, [("T", "loose one\n\nloose two")])
        (e,) = p.entries.values()
        self.assertFalse(e.broken)

    def test_location_keys_match_location_index(self):
        d = sample_doc()
        p = mdformat.parse(mdformat.render(d))
        idx = mdformat.location_index(d)
        self.assertEqual(list(p.entries), list(idx))
        self.assertEqual(list(idx), ["Events › hell › e1"])
        for key, parsed in p.entries.items():
            self.assertEqual(parsed.ident, idx[key].ident)
            self.assertEqual(parsed.children[0].location, key + "/watch")

    def test_inbox_ends_at_world_line(self):
        text = "# Inbox\n\n# not a section\nidea\n\n# World\n## A `a`\n\n- **X** `x`\n"
        p = mdformat.parse(text)
        self.assertEqual(p.inbox, "# not a section\nidea")
        self.assertEqual(list(p.entries), ["World › a › x"])   # the heading ident

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

    def test_fields_are_always_text(self):
        text = "# Inbox\n\n# T\n\n- **X** `x`\n  - a: one, two\n  - b: (empty)\n  - c: solo\n"
        (e,) = mdformat.parse(text).entries.values()
        self.assertEqual(e.fields, {"a": "one, two", "b": "", "c": "solo"})
        self.assertEqual(mdformat.split_list("one, two"), ["one", "two"])
        self.assertEqual(mdformat.split_list("one,two ,  three"), ["one", "two", "three"])
        self.assertEqual(mdformat.split_list("one, , two,"), ["one", "two"])
        self.assertEqual(mdformat.split_list("(empty)"), [])
        self.assertEqual(mdformat.split_list(""), [])

    def test_repeated_field_key_taints_the_entry(self):
        # A repeated key is ambiguous (which value is meant?), so the whole
        # entry is unreadable: nothing in it may be imported.
        for extra in ("  - f: two\n", "  - g:\n    > b\n"):
            with self.subTest(extra=extra):
                text = ("# Inbox\n\n# T\n\n- **X** `x`\n  - f: one\n"
                        "  - g:\n    > a\n" + extra)
                p = mdformat.parse(text)
                (e,) = p.entries.values()
                self.assertTrue(e.broken)
                self.assertEqual(p.stray, [])
                self.assertIn(extra.rstrip("\n"), e.raw)

    def test_child_nesting_is_relative(self):
        # Children only need to sit DEEPER than their label line; an exact
        # +2 is not required (an editor may paste them 4 deeper).
        text = ("# Inbox\n\n# T\n\n- **X** `x`\n  - kids:\n"
                "      - deep `d`\n    - ok `o`\n")
        p = mdformat.parse(text)
        (e,) = p.entries.values()
        self.assertEqual([c.ident for c in e.children], ["d", "o"])
        self.assertFalse(e.broken)
        self.assertEqual(p.stray, [])

    def test_child_not_deeper_than_label_taints(self):
        text = ("# Inbox\n\n# T\n\n- **X** `x`\n  - kids:\n"
                "  - flat `f`\n")
        (e,) = mdformat.parse(text).entries.values()
        self.assertTrue(e.broken)

    def test_context_newlines_flattened(self):
        d = sample_doc()
        d.sections[0].groups[0].entries[0].context = "a\nb"
        (e,) = mdformat.parse(mdformat.render(d)).entries.values()
        self.assertEqual(e.context, "a b")

    def test_duplicate_idents_are_kept(self):
        d = sample_doc()
        g = d.sections[0].groups[0]
        g.entries.append(Entry(key="k2", title="Other", ident="e1"))
        p = mdformat.parse(mdformat.render(d))
        self.assertEqual(len(p.entries), 2)
        # both copies know their real location, so the sync can group them
        self.assertEqual({e.location for e in p.entries.values()}, {"Events › hell › e1"})


BLOCK_DOC = ("# Inbox\n\n# T\n\n- **X** `x`\n  - text:\n"
             "    > Para one.\n{mid}    > Para two.\n  - other: kept\n")


class BrokenQuoteTests(unittest.TestCase):
    """CRITICAL review finding 1: a non-">" line inside a ">" block used to
    close the block, so the field imported only its first part."""

    def test_plain_line_at_column_0_taints(self):
        p = mdformat.parse(BLOCK_DOC.format(mid="A sentence typed here.\n"))
        (e,) = p.entries.values()
        self.assertTrue(e.broken)
        self.assertEqual(p.stray, [])
        self.assertIn("A sentence typed here.", e.raw)
        self.assertIn("Para two.", e.raw)
        self.assertIn("other: kept", e.raw)

    def test_quote_at_column_0_taints(self):
        p = mdformat.parse(BLOCK_DOC.format(mid="> typed at the margin\n"))
        (e,) = p.entries.values()
        self.assertTrue(e.broken)
        self.assertIn("> typed at the margin", e.raw)

    def test_plain_line_shallower_than_the_quotes_taints(self):
        p = mdformat.parse(BLOCK_DOC.format(mid="  half indented\n"))
        (e,) = p.entries.values()
        self.assertTrue(e.broken)

    def test_indented_plain_line_continues_the_block(self):
        for mid, want in (("    plain at the quote indent\n", "plain at the quote indent"),
                          ("        deeper still\n", "deeper still")):
            with self.subTest(mid=mid):
                p = mdformat.parse(BLOCK_DOC.format(mid=mid))
                (e,) = p.entries.values()
                self.assertFalse(e.broken)
                self.assertEqual(e.fields["text"], f"Para one.\n{want}\nPara two.")
                self.assertEqual(e.fields["other"], "kept")

    def test_indented_plain_line_after_a_blank_line_taints(self):
        # not "directly continuing": a blank line came between
        p = mdformat.parse(BLOCK_DOC.format(mid="\n    after a gap\n"))
        (e,) = p.entries.values()
        self.assertTrue(e.broken)

    def test_indented_plain_line_with_no_quote_yet_taints(self):
        text = "# Inbox\n\n# T\n\n- **X** `x`\n  - text:\n    no quote marker\n"
        (e,) = mdformat.parse(text).entries.values()
        self.assertTrue(e.broken)

    def test_child_taint_taints_the_top_entry(self):
        text = ("# Inbox\n\n# T\n\n- **X** `x`\n  - kids:\n    - [grey] K `k`\n"
                "      - result:\n        > one\nloose\n        > two\n")
        (e,) = mdformat.parse(text).entries.values()
        self.assertTrue(e.broken)


class IndentTests(unittest.TestCase):
    def test_four_space_indent_parses_like_two(self):
        two = mdformat.render(sample_doc())
        four = "\n".join(re.sub(r"^( +)", lambda m: m.group(1) * 2, l)
                         for l in two.split("\n"))
        a, b = mdformat.parse(two), mdformat.parse(four)
        (ea,), (eb,) = a.entries.values(), b.entries.values()
        self.assertFalse(eb.broken)
        self.assertEqual(eb.fields, ea.fields)
        self.assertEqual([c.fields for c in eb.children], [c.fields for c in ea.children])
        self.assertEqual(b.stray, [])

    def test_choices_pasted_four_deeper(self):
        text = mdformat.render(sample_doc()).replace(
            "    - [grey] Watch", "      - [grey] Watch").replace(
            "      - result:", "        - result:")
        (e,) = mdformat.parse(text).entries.values()
        self.assertFalse(e.broken)
        self.assertEqual(e.children[0].fields["result"], "You learn nothing.")


class HeadingIdentTests(unittest.TestCase):
    def test_location_uses_heading_ident(self):
        d = sample_doc()
        self.assertEqual(list(mdformat.location_index(d)), ["Events › hell › e1"])
        text = mdformat.render(d).replace("## Hell `hell`", "## The Burning Place `hell`")
        self.assertEqual(list(mdformat.parse(text).entries), ["Events › hell › e1"])

    def test_heading_without_ident_uses_title(self):
        text = "# Inbox\n\n# T\n\n## Plain heading\n\n- **X** `x`\n"
        self.assertEqual(list(mdformat.parse(text).entries), ["T › Plain heading › x"])


if __name__ == "__main__":
    unittest.main()
