# tools/test_content_sections_gear.py -- Equipment and Enemies sections (Task 5d)
import json, os, shutil, sys, tempfile, unittest
from pathlib import Path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from content import jsonio, mdformat, sync
from content import sections as sections_pkg
from content.model import Doc
from content.sections import equipment, enemies
from test_content_sections import walk   # reuse the shared helper

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "resources/data"


def get_or_empty(ds, path):
    """The JSON value at path, or "" when the key is absent."""
    try:
        return ds.get_at(path)
    except KeyError:
        return ""


def check_entry(test, ds, entry, parsed):
    """Like test_content_sections.check_entry, but an absent key reads as ""."""
    for f in entry.fields:
        if f.kind == "context":
            continue
        got = parsed.fields[f.name]
        if f.kind == "list":
            test.assertEqual(mdformat.split_list(got), f.value, (entry.key, f.name))
        else:
            test.assertEqual(got, f.value, (entry.key, f.name))
            test.assertEqual(get_or_empty(ds, f.path), f.value, (entry.key, f.name))
    test.assertEqual(len(parsed.children), len(entry.children), entry.key)
    for ce, cp in zip(entry.children, parsed.children):
        check_entry(test, ds, ce, cp)


def load():
    return jsonio.DataSet.load(ROOT)


class GearRoundTrip(unittest.TestCase):
    def test_round_trip_over_real_data(self):
        ds = load()
        for mod in (equipment, enemies):
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
                self.assertEqual(len(index), sum(1 for g in [group] for _ in _tops(g)))
                for loc, entry in index.items():
                    self.assertEqual(parsed.entries[loc].title, entry.title, loc)
                    check_entry(self, ds, entry, parsed.entries[loc])
                self.assertEqual(mdformat.render(Doc(sections=[mod.build(ds)])), text)


def _tops(group):
    for e in group.entries:
        yield e
    for g in group.groups:
        yield from _tops(g)


def count(group, prefix):
    return sum(1 for e in walk(group) if e.key.startswith(prefix))


class GearCoverage(unittest.TestCase):
    def test_every_item_present(self):
        ds = load()
        real = [k for k in ds.get("resources/data/items.json")["items"] if not k.startswith("_")]
        self.assertEqual(count(equipment.build(ds), "items:"), len(real))

    def test_unknown_item_type_goes_to_other(self):
        ds = load()
        ds.get("resources/data/items.json")["items"]["zz_odd"] = {
            "name": "Odd", "type": "no_such_type", "description": "x"}
        g = equipment.build(ds)
        other = [x for x in g.groups[0].groups if x.title == "Other"]
        self.assertEqual(len(other), 1)
        self.assertIn("zz_odd", [e.ident for e in walk(other[0])])

    def test_ammo_upgrades_supplies_perks(self):
        ds = load()
        g = equipment.build(ds)
        self.assertEqual(count(g, "ammo:"), len([k for k in ds.get("resources/data/ammo.json")["ammo"] if not k.startswith("_")]))
        self.assertEqual(count(g, "upgrades:"), len([k for k in ds.get("resources/data/upgrades.json")["upgrades"] if not k.startswith("_")]))
        self.assertEqual(count(g, "supplies:"), len([k for k in ds.get("resources/data/supplies.json")["supply_types"] if not k.startswith("_")]))
        self.assertEqual(count(g, "talisman:perk:"), len(ds.get("resources/data/talisman_tables.json")["perks"]))

    def test_name_parts_are_list_fields(self):
        g = equipment.build(load())
        e = [x for x in walk(g) if x.key == "talisman:name_parts:prefixes"][0]
        self.assertEqual(e.fields[0].kind, "list")

    def test_archetypes_and_encounters(self):
        ds = load()
        g = enemies.build(ds)
        n_a = n_e = 0
        for f in ds.files():
            if f.endswith("_archetypes.json"):
                n_a += len([k for k in ds.get(f)["archetypes"] if not k.startswith("_")])
            if f.endswith("_encounters.json"):
                n_e += len([k for k in ds.get(f)["encounters"] if not k.startswith("_")])
        self.assertEqual(sum(1 for e in walk(g) if ":archetype:" in e.key), n_a)
        self.assertEqual(sum(1 for e in walk(g) if ":encounter:" in e.key), n_e)

    def test_domain_comment_key_is_not_a_record(self):
        g = enemies.build(load())
        self.assertFalse([e for e in walk(g) if e.ident == "comment"])
        notes = [e for e in walk(g) if e.key == "enemies:domain:notes"][0]
        self.assertEqual(notes.fields[0].path[-1], "comment")

    def test_summons_and_name_parts(self):
        ds = load()
        g = enemies.build(ds)
        self.assertEqual(sum(1 for e in walk(g) if e.key.startswith("enemies:summon:")),
                         len(ds.get("resources/data/summon_templates.json")["templates"]))
        n = sum(len([k for k in ds.get("resources/data/enemies/name_parts.json")[s] if not k.startswith("_")])
                for s in ("prefixes", "roots", "suffixes"))
        self.assertEqual(sum(1 for e in walk(g) if e.key.startswith("enemies:name_part:")), n)

    def test_titles_meanings_and_design_fields_present(self):
        ds = load()
        g = enemies.build(ds)
        by_key = {e.key: e for e in walk(g)}
        n_title = n_design = n_mean = 0
        for f in ds.files():
            if f.endswith("_archetypes.json"):
                realm = Path(f).name[:-len("_archetypes.json")]
                for aid, a in ds.get(f)["archetypes"].items():
                    if aid.startswith("_"):
                        continue
                    e = by_key[f"enemies:{realm}:archetype:{aid}"]
                    if "name" in a:
                        n_title += 1
                        self.assertEqual(e.title_path, (f, "archetypes", aid, "name"))
                    if "_comment" in a:
                        n_design += 1
                        self.assertEqual([x.name for x in e.fields], ["design"])
                    else:
                        self.assertEqual(e.fields, [])
        self.assertGreater(n_title, 0)
        self.assertGreater(n_design, 0)
        for kind in ("prefixes", "roots", "suffixes"):
            for pid in ds.get("resources/data/enemies/name_parts.json")[kind]:
                if pid.startswith("_"):
                    continue
                e = by_key[f"enemies:name_part:{kind}:{pid}"]
                self.assertEqual([x.name for x in e.fields], ["meaning"])
                n_mean += 1
        self.assertGreater(n_mean, 0)

    def test_single_other_group(self):
        ds = load()
        items = ds.get("resources/data/items.json")
        items["item_types"]["nocat"] = {"slots": ["x"]}
        items["items"]["zz_nocat"] = {"name": "N", "type": "nocat", "description": "d"}
        items["items"]["zz_odd"] = {"name": "O", "type": "nope", "description": "d"}
        titles = [c.title.lower() for c in equipment.build(ds).groups[0].groups]
        self.assertEqual(titles.count("other"), 1)


class FillAbsentField(unittest.TestCase):
    def test_sync_creates_the_key(self):
        """Writing into an (empty) gap makes the JSON gain the key."""
        tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, tmp)
        shutil.copytree(DATA, tmp / "resources/data")
        (tmp / "tools").mkdir()
        items = tmp / "resources/data/items.json"
        d = json.loads(items.read_text(encoding="utf-8"))
        del d["items"]["iron_sword"]["description"]
        items.write_text(json.dumps(d, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        saved = sections_pkg.SECTIONS
        sections_pkg.SECTIONS = [equipment]      # sync reads this at call time
        self.addCleanup(setattr, sections_pkg, "SECTIONS", saved)
        self.assertEqual(sync.run(tmp, write=True).exit_code, 0)
        doc = tmp / "CONTENT.md"
        text = doc.read_text(encoding="utf-8")
        head = text.index("`iron_sword`")
        marker = "- description: (empty)"
        at = text.index(marker, head)
        doc.write_text(text[:at] + "- description: A filled gap." + text[at + len(marker):],
                       encoding="utf-8")
        self.assertEqual(sync.run(tmp, write=True).exit_code, 0)
        d = json.loads(items.read_text(encoding="utf-8"))
        self.assertEqual(d["items"]["iron_sword"]["description"], "A filled gap.")


if __name__ == "__main__":
    unittest.main()
