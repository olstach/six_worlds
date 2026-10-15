# tools/test_content_sections_world.py
# Round-trip + coverage tests for the World, Births and Companions sections.
import json, os, shutil, sys, tempfile, unittest
from pathlib import Path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from content import jsonio, mdformat, sync
from content import sections as sections_pkg
from content.model import Doc
from content.sections import traits, world, births, companions
from test_content_sections import walk
ROOT = Path(__file__).resolve().parent.parent
DATA = "resources/data/"


def safe_get(ds, path):
    """get_at, but an absent final key reads as "" (a gap the doc shows as (empty))."""
    try:
        return ds.get_at(path)
    except KeyError:
        ds.get_at(path[:-1])          # the parent must exist
        return ""


def check_entry(test, ds, entry, parsed):
    """Like test_content_sections.check_entry, tolerant of absent keys."""
    for f in entry.fields:
        if f.kind == "context":
            continue
        got = parsed.fields[f.name]
        if f.kind == "list":
            test.assertEqual(mdformat.split_list(got), f.value, (entry.key, f.name))
        else:
            test.assertEqual(got, f.value, (entry.key, f.name))
            test.assertEqual(safe_get(ds, f.path), f.value, (entry.key, f.name))
    test.assertEqual(len(parsed.children), len(entry.children), entry.key)
    for ce, cp in zip(entry.children, parsed.children):
        check_entry(test, ds, ce, cp)


def real(d):
    """The records of a dict: JSON keys starting with _ are comments."""
    return {k: v for k, v in d.items() if not k.startswith("_") and isinstance(v, dict)}


class RoundTrip(unittest.TestCase):
    def test_each_module_round_trips_over_real_data(self):
        ds = jsonio.DataSet.load(ROOT)
        for mod in (world, births, companions):
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

    def test_editable_titles_and_text_match_json(self):
        ds = jsonio.DataSet.load(ROOT)
        for mod in (world, births, companions):
            for e in walk(mod.build(ds)):
                if e.title_path:
                    self.assertEqual(ds.get_at(e.title_path), e.title, e.key)


class Coverage(unittest.TestCase):
    def setUp(self):
        self.ds = jsonio.DataSet.load(ROOT)

    def test_every_race_and_background_once(self):
        races = real(self.ds.get(DATA + "races.json")["races"])
        bgs = real(self.ds.get(DATA + "races.json")["backgrounds"])
        keys = [e.key for e in walk(births.build(self.ds))]
        self.assertEqual(sum(k.startswith("births:race:") for k in keys), len(races))
        self.assertEqual(sum(k.startswith("births:bg:") for k in keys), len(bgs))

    def test_every_companion_once(self):
        comps = real(self.ds.get(DATA + "companions.json")["companions"])
        keys = [e.key for e in walk(companions.build(self.ds))]
        self.assertEqual(len(keys), len(comps))

    def test_every_zone_landmark_and_shop(self):
        keys = [e.key for e in walk(world.build(self.ds))]
        zones = landmarks = 0
        for f in self.ds.files():
            if f.startswith(DATA + "map_configs/"):
                m = self.ds.get(f)
                zones += len(m.get("zones", []))
                landmarks += sum(1 for l in m.get("fixed_landmarks", [])
                                 if "event_id" in l.get("data", {}) and "name" in l["data"])
        shops = real(self.ds.get(DATA + "shops.json")["shops"])
        self.assertEqual(sum(k.startswith("world:zone:") for k in keys), zones)
        self.assertEqual(sum(k.startswith("world:landmark:") for k in keys), landmarks)
        self.assertEqual(sum(k.startswith("world:shop:") for k in keys), len(shops))
        terrain = real(self.ds.get(DATA + "terrain.json")["terrain"])
        domains = real(self.ds.get(DATA + "domains.json")["domains"])
        self.assertEqual(sum(k.startswith("world:terrain:") for k in keys), len(terrain))
        self.assertEqual(sum(k.startswith("world:domain:") for k in keys), len(domains))

    def test_every_realm_with_a_map_has_a_world_group(self):
        titles = {g.ident for g in world.build(self.ds).groups}
        for f in self.ds.files():
            if f.startswith(DATA + "map_configs/"):
                self.assertIn(self.ds.get(f)["id"], titles)

    def test_naming_lore_present(self):
        keys = [e.key for e in walk(births.build(self.ds))]
        self.assertTrue(any(k.startswith("births:names:") for k in keys))


class CompanionSkillsImport(unittest.TestCase):
    """Editing a companion's skills list in the doc rewrites build_weights."""
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp)
        shutil.copytree(ROOT / "resources/data", self.tmp / "resources/data")
        (self.tmp / "tools").mkdir()
        self.saved = sections_pkg.SECTIONS
        sections_pkg.SECTIONS = [traits, companions]
        self.addCleanup(setattr, sections_pkg, "SECTIONS", self.saved)
        self.assertEqual(sync.run(self.tmp, write=True).exit_code, 0)
        self.doc = self.tmp / "CONTENT.md"

    def comps(self):
        return json.loads((self.tmp / DATA / "companions.json").read_text(encoding="utf-8"))["companions"]

    def test_skills_edit_rebuilds_weights(self):
        before = self.comps()["karnak"]["build_weights"]
        old = ", ".join(k for k, _ in sorted(before.items(), key=lambda kv: -kv[1]))
        text = self.doc.read_text(encoding="utf-8")
        self.assertIn(f"- skills: {old}\n", text)
        new = "yoga, swords, fire_magic, unarmed, martial_arts, might"
        self.doc.write_text(text.replace(f"- skills: {old}\n", f"- skills: {new}\n", 1),
                            encoding="utf-8")
        r = sync.run(self.tmp, write=True)
        self.assertEqual(r.exit_code, 0)
        self.assertEqual(self.comps()["karnak"]["build_weights"],
                         {"yoga": 5, "swords": 4, "fire_magic": 3, "unarmed": 2,
                          "martial_arts": 2, "might": 2})

    def test_filling_an_absent_field_creates_the_key(self):
        # Remove flavor_text from one companion, rebuild the doc, then fill it in.
        p = self.tmp / DATA / "companions.json"
        d = json.loads(p.read_text(encoding="utf-8"))
        del d["companions"]["karnak"]["flavor_text"]
        p.write_text(json.dumps(d, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        sync.run(self.tmp, write=True)
        text = self.doc.read_text(encoding="utf-8")
        i = text.index("`karnak`")
        j = text.index("- flavor: (empty)", i)
        self.doc.write_text(text[:j] + "- flavor: Newly written." + text[j + len("- flavor: (empty)"):],
                            encoding="utf-8")
        r = sync.run(self.tmp, write=True)
        self.assertEqual(r.exit_code, 0)
        self.assertEqual(self.comps()["karnak"]["flavor_text"], "Newly written.")

    def test_untouched_skills_never_rewrite_weights(self):
        before = json.dumps(self.comps(), sort_keys=True)
        r = sync.run(self.tmp, write=True)
        self.assertEqual(r.imported, [])
        self.assertEqual(json.dumps(self.comps(), sort_keys=True), before)


if __name__ == "__main__":
    unittest.main()
