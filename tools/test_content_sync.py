# tools/test_content_sync.py
import json, os, shutil, subprocess, sys, tempfile, types, unittest
from pathlib import Path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from content import sync
from content import sections as sections_pkg
from content.model import Entry, Field, Group
ROOT = Path(__file__).resolve().parent.parent
TRAITS = "resources/data/traits.json"


class SyncTests(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp)
        shutil.copytree(ROOT / "resources/data", self.tmp / "resources/data")
        (self.tmp / "tools").mkdir()
        self.assertEqual(sync.run(self.tmp, write=True).exit_code, 0)
        self.doc = self.tmp / "CONTENT.md"

    def edit_doc(self, old, new):
        t = self.doc.read_text(encoding="utf-8")
        self.assertIn(old, t)
        self.doc.write_text(t.replace(old, new, 1), encoding="utf-8")

    def traits(self):
        return json.loads((self.tmp / TRAITS).read_text(encoding="utf-8"))

    def test_clean_after_first_run(self):
        r = sync.run(self.tmp, write=False)
        self.assertEqual((r.imported, r.to_inbox, r.conflicts, r.doc_changed), ([], [], [], False))

    def test_doc_edit_imports_exactly_that_field(self):
        desc = self.traits()["strong"]["description"]
        self.edit_doc(desc, "Broad in the shoulder.")
        r = sync.run(self.tmp, write=True)
        self.assertEqual([(k, f) for k, f, _, _ in r.imported], [("traits:strong", "desc")])
        self.assertEqual(self.traits()["strong"]["description"], "Broad in the shoulder.")

    def test_json_edit_flows_into_doc(self):
        d = self.traits(); d["strong"]["description"] = "Changed by code."
        (self.tmp / TRAITS).write_text(json.dumps(d, indent=2, ensure_ascii=False) + "\n")
        sync.run(self.tmp, write=True)
        self.assertIn("Changed by code.", self.doc.read_text(encoding="utf-8"))

    def test_conflict_writes_nothing(self):
        desc = self.traits()["strong"]["description"]
        self.edit_doc(desc, "Doc version.")
        d = self.traits(); d["strong"]["description"] = "JSON version."
        (self.tmp / TRAITS).write_text(json.dumps(d, indent=2, ensure_ascii=False) + "\n")
        before = self.doc.read_text(encoding="utf-8")
        r = sync.run(self.tmp, write=True)
        self.assertEqual(r.exit_code, 1)
        self.assertEqual(self.traits()["strong"]["description"], "JSON version.")
        self.assertEqual(self.doc.read_text(encoding="utf-8"), before)

    def test_context_edit_is_ignored_and_reported(self):
        self.edit_doc("`strong` — ", "`strong` — EDITED ")
        r = sync.run(self.tmp, write=True)
        self.assertEqual(r.imported, [])
        self.assertTrue(r.ignored)

    def test_broken_id_and_new_entry_go_to_inbox(self):
        self.edit_doc("`strong`", "`strongg`")
        self.edit_doc("# Traits\n", "# Traits\n\n- **Goat-Minded** `goat_minded`\n  - desc: Stubborn.\n")
        r = sync.run(self.tmp, write=True)
        text = self.doc.read_text(encoding="utf-8")
        inbox = text.split("# World")[0] if "# World" in text else text.split("\n# Traits")[0]
        self.assertIn("goat_minded", inbox)
        self.assertIn("strongg", inbox)
        self.assertIn("`strong`", text.split("# Traits")[1])      # original regenerated
        self.assertEqual(len(r.to_inbox), 2)

    def test_inbox_and_notes_survive(self):
        self.edit_doc("# Inbox\n", "# Inbox\n\nA goat oracle — maybe hell?\n")
        # Insert the notes line after the LAST line of the `strong` entry
        # (its desc may be one line or a ">" block), not after a guess.
        lines = self.doc.read_text(encoding="utf-8").split("\n")
        i = next(n for n, l in enumerate(lines) if "`strong`" in l) + 1
        while i < len(lines) and lines[i].startswith("  "):
            i += 1
        lines.insert(i, "  - notes: rebalance later")
        self.doc.write_text("\n".join(lines), encoding="utf-8")
        sync.run(self.tmp, write=True); sync.run(self.tmp, write=True)
        text = self.doc.read_text(encoding="utf-8")
        self.assertIn("A goat oracle — maybe hell?", text)
        self.assertIn("rebalance later", text)
        self.assertNotIn("rebalance later", (self.tmp / TRAITS).read_text(encoding="utf-8"))

    def test_check_mode(self):
        self.assertEqual(sync.run(self.tmp, write=False, check=True).exit_code, 0)
        desc = self.traits()["strong"]["description"]
        self.edit_doc(desc, "Pending.")
        self.assertEqual(sync.run(self.tmp, write=False, check=True).exit_code, 2)

    def test_missing_base_refuses(self):
        (self.tmp / "tools/content_base.json").unlink()
        self.assertEqual(sync.run(self.tmp, write=True).exit_code, 1)

    # --- beyond the brief: rules the brief implies but does not test ---------
    def test_dry_run_writes_nothing(self):
        desc = self.traits()["strong"]["description"]
        self.edit_doc(desc, "Dry.")
        before_doc = self.doc.read_text(encoding="utf-8")
        before_base = (self.tmp / "tools/content_base.json").read_text(encoding="utf-8")
        r = sync.run(self.tmp, write=False)
        self.assertEqual([(k, f) for k, f, _, _ in r.imported], [("traits:strong", "desc")])
        self.assertEqual(self.traits()["strong"]["description"], desc)
        self.assertEqual(self.doc.read_text(encoding="utf-8"), before_doc)
        self.assertEqual((self.tmp / "tools/content_base.json").read_text(encoding="utf-8"),
                         before_base)

    def test_record_deleted_from_json_drops_silently(self):
        d = self.traits(); del d["strong"]
        (self.tmp / TRAITS).write_text(json.dumps(d, indent=2, ensure_ascii=False) + "\n")
        r = sync.run(self.tmp, write=True)
        self.assertEqual(r.to_inbox, [])
        self.assertNotIn("`strong`", self.doc.read_text(encoding="utf-8"))

    def add_note(self, ident, note):
        """Insert a notes line after the last line of a top-level entry."""
        lines = self.doc.read_text(encoding="utf-8").split("\n")
        i = next(n for n, l in enumerate(lines) if f"`{ident}`" in l) + 1
        while i < len(lines) and lines[i].startswith("  "):
            i += 1
        lines.insert(i, f"  - notes: {note}")
        self.doc.write_text("\n".join(lines), encoding="utf-8")

    def test_deleted_record_with_notes_goes_to_inbox(self):
        self.add_note("strong", "keep this thought")
        sync.run(self.tmp, write=True)
        d = self.traits(); del d["strong"]
        (self.tmp / TRAITS).write_text(json.dumps(d, indent=2, ensure_ascii=False) + "\n")
        r = sync.run(self.tmp, write=True)
        self.assertEqual([why for _, why in r.to_inbox],
                         ["record deleted from the data; it had notes"])
        inbox = self.doc.read_text(encoding="utf-8").split("\n# Traits")[0]
        self.assertIn("keep this thought", inbox)

    def test_missing_doc_is_regenerated_with_notes(self):
        self.add_note("strong", "survives a lost doc")
        sync.run(self.tmp, write=True)
        self.doc.unlink()
        r = sync.run(self.tmp, write=True)
        self.assertEqual(r.exit_code, 0)
        self.assertIn("regenerated", r.notice)
        self.assertIn("survives a lost doc", self.doc.read_text(encoding="utf-8"))
        self.assertEqual(sync.run(self.tmp, write=False, check=True).exit_code, 0)

    def test_cli_check_and_write_are_exclusive(self):
        # run a copy of the CLI inside the temp root, so that even a broken
        # CLI that ignores the flags could never write to the real project
        shutil.copy(ROOT / "tools/content_sync.py", self.tmp / "tools")
        shutil.copytree(ROOT / "tools/content", self.tmp / "tools/content",
                        ignore=shutil.ignore_patterns("__pycache__"))
        p = subprocess.run([sys.executable, str(self.tmp / "tools/content_sync.py"),
                            "--check", "--write"], capture_output=True, text=True)
        self.assertEqual(p.returncode, 2)
        self.assertIn("not allowed with", p.stderr)

    def test_stray_line_goes_to_inbox(self):
        self.edit_doc("# Traits\n", "# Traits\n\nsome loose thought\n")
        r = sync.run(self.tmp, write=True)
        self.assertEqual([why for _, why in r.to_inbox], ["unrecognised line"])
        inbox = self.doc.read_text(encoding="utf-8").split("\n# Traits")[0]
        self.assertIn("some loose thought", inbox)
        self.assertIn("<!-- moved by content_sync: found under", inbox)
        # once moved, the next run is clean
        self.assertEqual(sync.run(self.tmp, write=False, check=True).exit_code, 0)


# --- children (event choices etc.), via a tiny stand-in section -------------
FAKE_FILE = "resources/data/fake.json"


def _fake_build(ds):
    data = ds.get(FAKE_FILE)
    top = Group("Fakes", 1)
    for eid, ev in data.items():
        if eid.startswith("_"):
            continue
        kids = [Entry(key=f"fake:{eid}/{cid}", title=c["text"], ident=cid, tag="grey",
                      fields=[Field("result", c["result"], "text",
                                    (FAKE_FILE, eid, "choices", n, "result"))])
                for n, (cid, c) in enumerate((c["id"], c) for c in ev["choices"])]
        top.entries.append(Entry(key=f"fake:{eid}", title=ev["name"], ident=eid,
                                 title_path=(FAKE_FILE, eid, "name"),
                                 fields=[Field("tags", ev["tags"], "list",
                                               (FAKE_FILE, eid, "tags"))],
                                 children=kids, children_label="choices"))
    return top


class ChildSyncTests(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp)
        (self.tmp / "resources/data").mkdir(parents=True)
        (self.tmp / "tools").mkdir()
        self.data = {"_comment": "x", "goat": {"name": "Goat", "tags": ["a", "b"], "choices": [
            {"id": "watch", "text": "Watch", "result": "Nothing."},
            {"id": "pet", "text": "Pet", "result": "It bites."}]}}
        self.save(self.data)
        fake = types.SimpleNamespace(TITLE="Fakes", build=_fake_build)
        old = list(sections_pkg.SECTIONS)
        sections_pkg.SECTIONS[:] = [fake]
        self.addCleanup(sections_pkg.SECTIONS.__setitem__, slice(None), old)
        self.assertEqual(sync.run(self.tmp, write=True).exit_code, 0)
        self.doc = self.tmp / "CONTENT.md"

    def save(self, d):
        (self.tmp / FAKE_FILE).write_text(json.dumps(d, indent=2) + "\n", encoding="utf-8")

    def load(self):
        return json.loads((self.tmp / FAKE_FILE).read_text(encoding="utf-8"))

    def edit_doc(self, old, new):
        t = self.doc.read_text(encoding="utf-8")
        self.assertIn(old, t)
        self.doc.write_text(t.replace(old, new, 1), encoding="utf-8")

    def test_child_field_and_list_import(self):
        self.edit_doc("It bites.", "It purrs.")
        self.edit_doc("tags: a, b", "tags: a, b, c")
        r = sync.run(self.tmp, write=True)
        self.assertEqual(sorted((k, f) for k, f, _, _ in r.imported),
                         [("fake:goat", "tags"), ("fake:goat/pet", "result")])
        d = self.load()
        self.assertEqual(d["goat"]["choices"][1]["result"], "It purrs.")
        self.assertEqual(d["goat"]["tags"], ["a", "b", "c"])
        self.assertEqual(sync.run(self.tmp, write=False, check=True).exit_code, 0)

    def test_child_title_without_path_is_ignored(self):
        self.edit_doc("[grey] Pet", "[grey] Stroke")
        r = sync.run(self.tmp, write=True)
        self.assertEqual(r.ignored, [("fake:goat/pet", "title")])
        self.assertEqual(r.imported, [])

    def test_unknown_child_goes_to_inbox(self):
        self.edit_doc("    - [grey] Pet `pet`", "    - [grey] Pett `pett`")
        r = sync.run(self.tmp, write=True)
        self.assertEqual([loc for loc, _ in r.to_inbox], ["Fakes › goat/pett"])
        inbox = self.doc.read_text(encoding="utf-8").split("\n# Fakes")[0]
        self.assertIn("Pett `pett`", inbox)

    def test_duplicate_child_id_goes_to_inbox(self):
        self.edit_doc("    - [grey] Pet `pet`\n      - result: It bites.\n",
                      "    - [grey] Pet `pet`\n      - result: It bites.\n"
                      "    - [grey] Pet `pet`\n      - result: A copy.\n")
        r = sync.run(self.tmp, write=True)
        self.assertEqual(r.to_inbox, [("Fakes › goat/pet", "duplicate id")])
        self.assertEqual(r.imported, [])
        self.assertEqual(self.load()["goat"]["choices"][1]["result"], "It bites.")
        self.assertIn("A copy.", self.doc.read_text(encoding="utf-8").split("\n# Fakes")[0])

    def test_deleted_child_with_notes_goes_to_inbox(self):
        self.edit_doc("      - result: It bites.\n",
                      "      - result: It bites.\n      - notes: a cat?\n")
        sync.run(self.tmp, write=True)
        self.data["goat"]["choices"].pop()
        self.save(self.data)
        r = sync.run(self.tmp, write=True)
        self.assertEqual(r.to_inbox, [("Fakes › goat/pet",
                                       "record deleted from the data; it had notes")])
        self.assertIn("a cat?", self.doc.read_text(encoding="utf-8").split("\n# Fakes")[0])

    def test_child_deleted_from_json_drops_silently(self):
        self.data["goat"]["choices"].pop()
        self.save(self.data)
        r = sync.run(self.tmp, write=True)
        self.assertEqual(r.to_inbox, [])
        self.assertNotIn("`pet`", self.doc.read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
