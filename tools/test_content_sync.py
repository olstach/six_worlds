# tools/test_content_sync.py
import json, os, shutil, subprocess, sys, tempfile, types, unittest
from pathlib import Path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from content import sync
from content import sections as sections_pkg
from content.model import Entry, Field, Group
ROOT = Path(__file__).resolve().parent.parent
TRAITS = "resources/data/traits.json"
COMPANIONS = "resources/data/companions.json"
TABLES = "resources/data/equipment_tables.json"


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

    def test_full_document_round_trips(self):
        # setUp already ran the sync once; a second run must find nothing.
        r = sync.run(self.tmp, write=True)
        self.assertEqual((r.imported, r.to_inbox, r.conflicts, r.doc_changed), ([], [], [], False))
        heads = [l[2:] for l in self.doc.read_text(encoding="utf-8").splitlines()
                 if l.startswith("# ")]
        self.assertEqual(heads, ["Inbox", "World", "Births", "Companions", "Skills", "Perks",
                                 "Spells", "Statuses", "Traits", "Equipment", "Enemies",
                                 "Events", "Quests"])

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

    def test_rebase_base_keeps_notes_when_the_base_is_deleted(self):
        self.edit_doc("`strong`", "`strong`")
        t = self.doc.read_text(encoding="utf-8")
        i = t.index("`strong`")
        j = t.index("\n", i)
        self.doc.write_text(t[:j] + "\n  - notes: keep me" + t[j:], encoding="utf-8")
        sync.run(self.tmp, write=True)
        base = self.tmp / "tools/content_base.json"
        saved = base.read_text(encoding="utf-8")
        self.assertIn("keep me", saved)
        base.unlink()
        self.assertEqual(sync.run(self.tmp, write=True).exit_code, 1)   # refuses
        self.assertFalse(base.exists())
        r = sync.run(self.tmp, write=True, rebase_base=True)
        self.assertEqual(r.exit_code, 0)
        self.assertEqual(base.read_text(encoding="utf-8"), saved)

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
        # two loose lines in one stretch move as ONE chunk, under one comment
        self.edit_doc("# Traits\n", "# Traits\n\nsome loose thought\n\nand another\n")
        r = sync.run(self.tmp, write=True)
        self.assertEqual([why for _, why in r.to_inbox], ["unrecognised line"])
        inbox = self.doc.read_text(encoding="utf-8").split("\n# Traits")[0]
        self.assertIn("some loose thought", inbox)
        self.assertIn("<!-- moved by content_sync: found under", inbox)
        self.assertEqual(inbox.count("<!-- moved by content_sync"), 1)
        self.assertIn("some loose thought\n\nand another", inbox)
        # once moved, the next run is clean
        self.assertEqual(sync.run(self.tmp, write=False, check=True).exit_code, 0)


    # --- final review: duplicates, list ids, heading renames ----------------
    def companions(self):
        return json.loads((self.tmp / COMPANIONS).read_text(encoding="utf-8"))["companions"]

    def snapshot(self):
        return {p: (self.tmp / p).read_text(encoding="utf-8")
                for p in ("CONTENT.md", "tools/content_base.json", COMPANIONS, TABLES)}

    def karnak(self):
        """Karnak's lines exactly as the last sync wrote them."""
        text = self.doc.read_text(encoding="utf-8")
        start = text.index("- **Brother Karnak** `karnak`")
        end = text.index("\n- **", start + 1)
        return text[start:end + 1]

    def test_pasted_template_copy_imports_nothing(self):
        # The owner pastes a copy of Karnak ABOVE the original as a template
        # and edits the copy. Neither copy may import; the original stays.
        orig = self.karnak()
        copy = orig.replace("A red devil cast out", "A NEW companion cast out")
        self.edit_doc(orig, copy + orig)
        before = self.companions()["karnak"]
        r = sync.run(self.tmp, write=True)
        self.assertEqual(r.imported, [])
        self.assertEqual(r.to_inbox, [("Companions › hell › red_devil › karnak",
                                       "duplicate id — nothing imported")])
        self.assertEqual(self.companions()["karnak"], before)
        text = self.doc.read_text(encoding="utf-8")
        inbox, rest = text.split("\n# World")
        self.assertIn("A NEW companion cast out", inbox)
        self.assertEqual(rest.count("`karnak`"), 1)
        self.assertIn(orig, rest)                          # notes and all
        self.assertEqual(sync.run(self.tmp, write=False, check=True).exit_code, 0)

    def test_two_edited_copies_both_go_to_inbox(self):
        orig = self.karnak()
        one = orig.replace("A red devil cast out", "Copy one")
        two = orig.replace("A red devil cast out", "Copy two")
        self.edit_doc(orig, one + two)
        before = self.companions()["karnak"]
        r = sync.run(self.tmp, write=True)
        self.assertEqual(len(r.to_inbox), 2)
        self.assertEqual(r.imported, [])
        self.assertEqual(self.companions()["karnak"], before)
        text = self.doc.read_text(encoding="utf-8")
        inbox, rest = text.split("\n# World")
        self.assertIn("Copy one", inbox)
        self.assertIn("Copy two", inbox)
        self.assertIn(orig, rest)          # regenerated from the data + saved notes

    def test_list_split_on_bare_comma_and_names_normalised(self):
        self.edit_doc("  - skills: martial_arts, unarmed, yoga, fire_magic",
                      "  - skills: Martial Arts,yoga ,unarmed, Fire Magic")
        r = sync.run(self.tmp, write=True)
        self.assertEqual(r.exit_code, 0)
        self.assertEqual(self.companions()["karnak"]["build_weights"],
                         {"martial_arts": 5, "yoga": 4, "unarmed": 3, "fire_magic": 2})
        self.assertIn("  - skills: martial_arts, yoga, unarmed, fire_magic",
                      self.doc.read_text(encoding="utf-8"))
        self.assertEqual(sync.run(self.tmp, write=False, check=True).exit_code, 0)

    def test_normalised_but_unchanged_list_imports_nothing(self):
        self.edit_doc("  - traits: devout, brave", "  - traits: Devout, BRAVE")
        r = sync.run(self.tmp, write=True)
        self.assertEqual(r.imported, [])
        self.assertTrue(r.doc_changed)          # shown again in its canonical form

    def assert_refused(self, old, new, bad):
        self.edit_doc(old, new)
        before = self.snapshot()
        r = sync.run(self.tmp, write=True)
        self.assertEqual(r.exit_code, 1)
        self.assertTrue(any(bad in msg for _, _, msg in r.invalid), r.invalid)
        self.assertEqual(self.snapshot(), before)        # nothing written at all

    def test_unknown_skill_id_refuses(self):
        self.assert_refused("  - skills: martial_arts, unarmed, yoga, fire_magic",
                            "  - skills: martial_arts, kung_fu", "kung_fu")

    def test_unknown_trait_id_refuses(self):
        self.assert_refused("  - traits: devout, brave", "  - traits: devout, braveheart",
                            "braveheart")

    def test_unknown_equipment_type_refuses(self):
        self.assert_refused("  - allowed_types: staff, club", "  - allowed_types: staff, clubb",
                            "clubb")

    def test_renamed_heading_title_keeps_its_entries(self):
        self.edit_doc("### Red Devil `red_devil`", "### Red devils, renamed `red_devil`")
        r = sync.run(self.tmp, write=True)
        self.assertEqual((r.to_inbox, r.imported, r.conflicts), ([], [], []))
        text = self.doc.read_text(encoding="utf-8")
        self.assertNotIn("karnak", text.split("\n# World")[0])
        self.assertIn("### Red Devil `red_devil`", text)     # title regenerated
        self.assertEqual(sync.run(self.tmp, write=False, check=True).exit_code, 0)

    def test_report_preview_shows_where_a_truncation_starts(self):
        old = "The first paragraph is long enough to fill a preview. " * 3 + "LOST TAIL"
        new = old[:len(old) - len("LOST TAIL")]
        lines = sync.preview_change(old, new)
        joined = "\n".join(lines)
        self.assertIn("LOST TAIL", joined)
        self.assertNotEqual(lines[0], lines[1])


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
                                               (FAKE_FILE, eid, "tags")),
                                         Field("lore", ev["lore"], "text",
                                               (FAKE_FILE, eid, "lore"))],
                                 children=kids, children_label="choices"))
    return top


class ChildSyncTests(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp)
        (self.tmp / "resources/data").mkdir(parents=True)
        (self.tmp / "tools").mkdir()
        self.data = {"_comment": "x", "goat": {"name": "Goat", "tags": ["a", "b"],
                                               "lore": "Para one.\nPara two.", "choices": [
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
        self.assertEqual(r.to_inbox, [("Fakes › goat/pet", "duplicate id — nothing imported")])
        self.assertEqual(r.imported, [])
        self.assertEqual(self.load()["goat"]["choices"][1]["result"], "It bites.")
        self.assertIn("A copy.", self.doc.read_text(encoding="utf-8").split("\n# Fakes")[0])

    def test_duplicate_child_pasted_above_imports_nothing(self):
        self.edit_doc("    - [grey] Pet `pet`\n",
                      "    - [grey] Pet `pet`\n      - result: Overwritten!\n"
                      "    - [grey] Pet `pet`\n")
        r = sync.run(self.tmp, write=True)
        self.assertEqual(r.imported, [])
        self.assertEqual(self.load()["goat"]["choices"][1]["result"], "It bites.")
        self.assertIn("Overwritten!", self.doc.read_text(encoding="utf-8").split("\n# Fakes")[0])

    # --- final review CRITICAL 1: a broken ">" block -------------------------
    REASON = ("could not read this entry — nothing imported; fix it here and "
              "paste it back, or edit the original below")

    def test_sentence_typed_inside_a_quote_imports_nothing(self):
        self.edit_doc("    > Para one.\n",
                      "    > Para one.\nA plain sentence the owner typed.\n")
        self.edit_doc("tags: a, b", "tags: a, b, c")     # also edited: must NOT import
        r = sync.run(self.tmp, write=True)
        self.assertEqual(r.imported, [])
        self.assertEqual(r.to_inbox, [("Fakes › goat", self.REASON)])
        self.assertEqual(self.load()["goat"]["lore"], "Para one.\nPara two.")
        self.assertEqual(self.load()["goat"]["tags"], ["a", "b"])
        text = self.doc.read_text(encoding="utf-8")
        inbox, rest = text.split("\n# Fakes")
        self.assertEqual(inbox.count("<!-- moved by content_sync"), 1)   # ONE chunk
        for part in ("A plain sentence the owner typed.", "Para two.", "It bites.",
                     "tags: a, b, c"):
            self.assertIn(part, inbox)
        self.assertIn("    > Para one.\n    > Para two.\n", rest)       # original back
        self.assertEqual(sync.run(self.tmp, write=False, check=True).exit_code, 0)

    def test_quote_at_margin_imports_nothing(self):
        self.edit_doc("    > Para one.\n", "    > Para one.\n> at the margin\n")
        r = sync.run(self.tmp, write=True)
        self.assertEqual(r.imported, [])
        self.assertEqual(r.to_inbox, [("Fakes › goat", self.REASON)])
        self.assertEqual(self.load()["goat"]["lore"], "Para one.\nPara two.")

    def test_broken_entry_keeps_its_notes(self):
        self.edit_doc("      - result: It bites.\n",
                      "      - result: It bites.\n      - notes: cat?\n")
        self.edit_doc("  - lore:\n", "  - notes: top note\n  - lore:\n")
        sync.run(self.tmp, write=True)
        self.edit_doc("    > Para one.\n", "    > Para one.\noops\n")
        sync.run(self.tmp, write=True)
        rest = self.doc.read_text(encoding="utf-8").split("\n# Fakes")[1]
        self.assertIn("cat?", rest)
        self.assertIn("top note", rest)
        self.assertEqual(sync.run(self.tmp, write=False, check=True).exit_code, 0)

    def test_indented_plain_line_continues_the_quote(self):
        self.edit_doc("    > Para one.\n", "    > Para one.\n    typed without the marker\n")
        r = sync.run(self.tmp, write=True)
        self.assertEqual(r.to_inbox, [])
        self.assertEqual(self.load()["goat"]["lore"],
                         "Para one.\ntyped without the marker\nPara two.")
        self.assertIn("    > typed without the marker\n", self.doc.read_text(encoding="utf-8"))

    def test_choices_indented_four_deeper_still_import(self):
        # an editor pastes every choice 4 deeper than `choices:` (not 2), and
        # their fields 4 deeper again
        t = self.doc.read_text(encoding="utf-8")
        head, rest = t.split("  - choices:\n")
        rest = "\n".join("    " + l if l.startswith("    ") else l for l in rest.split("\n"))
        rest = rest.replace("          - result:", "            - result:")
        self.doc.write_text(head + "  - choices:\n" + rest, encoding="utf-8")
        self.edit_doc("It bites.", "It purrs.")
        r = sync.run(self.tmp, write=True)
        self.assertEqual(r.to_inbox, [])
        self.assertEqual(self.load()["goat"]["choices"][1]["result"], "It purrs.")

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
