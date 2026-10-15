# tools/test_content_sections_events.py -- Events and Quests sections (Task 5a)
import os, sys, unittest
from pathlib import Path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from content import jsonio, mdformat
from content.model import Doc
from content.sections import events, quests
from test_content_sections import walk, walk_entry, check_entry   # reuse the helpers

ROOT = Path(__file__).resolve().parent.parent


class EventQuestRoundTrip(unittest.TestCase):
    def test_modules_round_trip_over_real_data(self):
        ds = jsonio.DataSet.load(ROOT)
        for mod in (events, quests):
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
                    self.assertTrue(e.key.startswith(mod.TITLE.lower() + ":"), e.key)
                index = mdformat.location_index(doc)
                self.assertEqual(set(index), set(parsed.entries))
                for loc, entry in index.items():
                    self.assertEqual(parsed.entries[loc].title, entry.title, loc)
                    check_entry(self, ds, entry, parsed.entries[loc])
                    if entry.title_path:
                        self.assertEqual(ds.get_at(entry.title_path), entry.title, loc)
                self.assertEqual(mdformat.render(Doc(sections=[mod.build(ds)])), text)

    def test_events_cover_every_event_and_choice(self):
        ds = jsonio.DataSet.load(ROOT)
        n_events = n_choices = 0
        for src, _t, _i in events.REALMS:
            for k, e in ds.get(events.EVENTS_DIR + src)["events"].items():
                if k.startswith("_") or not isinstance(e, dict):
                    continue
                n_events += 1
                n_choices += sum(1 for c in e.get("choices", []) if isinstance(c, dict))
        entries = list(walk(events.build(ds)))
        built_choices = sum(len(e.children) for e in entries)
        self.assertEqual(len(entries) - built_choices, n_events)
        self.assertEqual(built_choices, n_choices)

    def test_every_outcome_text_is_exposed(self):
        # Every outcome branch that exists in the JSON must show up as a field.
        ds = jsonio.DataSet.load(ROOT)
        paths = {f.path for e in walk(events.build(ds)) for f in e.fields}
        for src, _t, _i in events.REALMS:
            file = events.EVENTS_DIR + src
            for eid, e in ds.get(file)["events"].items():
                if eid.startswith("_") or not isinstance(e, dict):
                    continue
                for i, c in enumerate(e.get("choices", [])):
                    for b, _l in events.BRANCHES:
                        if isinstance(c.get(b), dict) and 'text' in c[b]:
                            self.assertIn((file, "events", eid, "choices", i, b, "text"), paths)

    def test_idless_choices_use_position_and_odd_events_survive(self):
        ds = jsonio.DataSet.load(ROOT)
        group = events.build(ds)
        idents = [c.ident for e in walk(group) for c in e.children]
        self.assertTrue(any(i.startswith("#") for i in idents))
        self.assertIn("hell_waystation", [e.ident for e in walk(group)])

    def test_quests_cover_every_quest_and_step(self):
        ds = jsonio.DataSet.load(ROOT)
        data = {k: v for k, v in ds.get(quests.FILE)["quests"].items() if not k.startswith("_")}
        entries = list(walk(quests.build(ds)))
        self.assertEqual(len(entries), len(data))
        steps = sum(1 for e in entries for f in e.fields if f.name.startswith("step_"))
        self.assertEqual(steps, sum(len(q.get("steps", [])) for q in data.values()))


if __name__ == "__main__":
    unittest.main()
