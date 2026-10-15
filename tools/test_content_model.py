# tools/test_content_model.py
import json, os, sys, tempfile, shutil, unittest
from pathlib import Path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from content import jsonio
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

if __name__ == "__main__":
    unittest.main()
