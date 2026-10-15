# tools/test_content_sections_rules.py -- Task 5c: skills, perks, spells, statuses
import json, os, shutil, sys, tempfile, unittest
from pathlib import Path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from content import jsonio, mdformat, sync
import content.sections as sections_pkg
from content.model import Doc
from content.sections import skills, perks, spells, statuses
from test_content_sections import walk   # reuse the shared helpers
ROOT = Path(__file__).resolve().parent.parent
MODULES = [skills, perks, spells, statuses]


def real(d):
    return [k for k in d if not k.startswith("_")]


class RulesRoundTrip(unittest.TestCase):
    def check_entry(self, ds, entry, parsed):
        """Like the shared check_entry, but a writing field whose JSON key is
        absent must read as "" (it renders as (empty))."""
        for f in entry.fields:
            if f.kind == "context":
                continue
            got = parsed.fields[f.name]
            if f.kind == "list":
                self.assertEqual(mdformat.split_list(got), f.value, (entry.key, f.name))
                continue
            self.assertEqual(got, f.value, (entry.key, f.name))
            node = ds.get_at(f.path[:-1])          # the parent must exist
            key = f.path[-1]
            present = key in node if isinstance(node, dict) else key < len(node)
            self.assertEqual(node[key] if present else "", f.value, (entry.key, f.name))
        self.assertEqual(len(parsed.children), len(entry.children), entry.key)
        for ce, cp in zip(entry.children, parsed.children):
            self.check_entry(ds, ce, cp)

    def test_every_module_round_trips_over_real_data(self):
        ds = jsonio.DataSet.load(ROOT)
        for mod in MODULES:
            with self.subTest(section=mod.TITLE):
                group = mod.build(ds)
                doc = Doc(sections=[group])
                text = mdformat.render(doc)
                parsed = mdformat.parse(text)
                self.assertEqual(parsed.stray, [], mod.TITLE)
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
                    self.check_entry(ds, entry, parsed.entries[loc])
                self.assertEqual(mdformat.render(Doc(sections=[mod.build(ds)])), text)

    def test_skills_cover_every_skill(self):
        ds = jsonio.DataSet.load(ROOT)
        data = ds.get(skills.FILE)
        n = sum(1 for e in walk(skills.build(ds)) if not e.key.startswith("skills:element:"))
        self.assertEqual(n, len(real(data["skills"])))
        n_el = sum(1 for e in walk(skills.build(ds)) if e.key.startswith("skills:element:"))
        self.assertEqual(n_el, len(real(data["elements"])))

    def test_perks_cover_every_perk(self):
        ds = jsonio.DataSet.load(ROOT)
        data = ds.get(perks.FILE)
        es = list(walk(perks.build(ds)))
        self.assertEqual(sum(e.key.startswith("perks:skill_perks:") for e in es),
                         len(real(data["skill_perks"])))
        self.assertEqual(sum(e.key.startswith("perks:cross_perks:") for e in es),
                         len(real(data["cross_perks"])))

    def test_spells_cover_every_spell(self):
        ds = jsonio.DataSet.load(ROOT)
        es = [e for e in walk(spells.build(ds)) if e.ident != "notes"]
        self.assertEqual(len(es), len(real(ds.get(spells.FILE)["spells"])))

    def test_school_notes_become_fields(self):
        ds = jsonio.DataSet.load(ROOT)
        notes = [e for e in walk(spells.build(ds)) if e.ident == "notes"]
        want = sum(1 for v in ds.get(spells.FILE)["school_notes"].values()
                   for x in v.values() if isinstance(x, str))
        self.assertEqual(sum(len(e.fields) for e in notes), want)

    def test_statuses_cover_every_status(self):
        ds = jsonio.DataSet.load(ROOT)
        es = list(walk(statuses.build(ds)))
        self.assertEqual(len(es), len(ds.get(statuses.FILE)["statuses"]))
        # a status address uses its list index
        e = es[0]
        self.assertEqual(e.title_path[1:3], ("statuses", int(e.key.split(":")[1])))

    def test_absent_status_description_can_be_filled_in(self):
        ds = jsonio.DataSet.load(ROOT)
        rows = ds.get(statuses.FILE)["statuses"]
        idx = next(i for i, s in enumerate(rows) if "description" not in s)
        name = rows[idx]["name"]
        tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, tmp)
        shutil.copytree(ROOT / "resources/data", tmp / "resources/data")
        (tmp / "tools").mkdir()
        saved = sections_pkg.SECTIONS
        sections_pkg.SECTIONS = [statuses]
        try:
            self.assertEqual(sync.run(tmp, write=True).exit_code, 0)
            doc = tmp / "CONTENT.md"
            lines = doc.read_text(encoding="utf-8").split("\n")
            at = next(i for i, l in enumerate(lines) if l.startswith(f"- **{name}** `"))
            self.assertIn("(empty)", lines[at + 1])
            lines[at + 1] = lines[at + 1].replace("(empty)", "A filled-in gap.")
            doc.write_text("\n".join(lines), encoding="utf-8")
            sync.run(tmp, write=True)
        finally:
            sections_pkg.SECTIONS = saved
        out = json.loads((tmp / statuses.FILE).read_text(encoding="utf-8"))
        self.assertEqual(out["statuses"][idx]["description"], "A filled-in gap.")


if __name__ == "__main__":
    unittest.main()
