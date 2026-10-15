# tools/test_content_sections_rules.py -- Task 5c: skills, perks, spells, statuses
import os, sys, unittest
from pathlib import Path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from content import jsonio, mdformat
from content.model import Doc
from content.sections import skills, perks, spells, statuses
from test_content_sections import walk, check_entry   # reuse the shared helpers
ROOT = Path(__file__).resolve().parent.parent
MODULES = [skills, perks, spells, statuses]


def real(d):
    return [k for k in d if not k.startswith("_")]


class RulesRoundTrip(unittest.TestCase):
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
                    check_entry(self, ds, entry, parsed.entries[loc])
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


if __name__ == "__main__":
    unittest.main()
