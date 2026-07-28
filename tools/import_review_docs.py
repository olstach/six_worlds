#!/usr/bin/env python3
"""Read the edited Markdown in docs/review/ back into the JSON data files.

Pairs with export_review_docs.py. Every editable string in those documents sits
between anchors naming its JSON path:

    <!--@ hell_events.json | hell_bone_arena | choices.fight.text -->
    Step into the arena and fight
    <!--@end-->

This script finds each anchor, compares the text against what is currently in
the JSON, and writes back anything that changed.

    python3 tools/import_review_docs.py            # show what would change
    python3 tools/import_review_docs.py --write    # apply it

Always run tools/validate_data.py afterwards.
"""
import argparse
import glob
import json
import os
import re
import sys

ROOT = "/home/user/six_worlds"
REVIEW = os.path.join(ROOT, "docs/review")

ANCHOR = re.compile(r"<!--@ (.+?) -->\n(.*?)\n?<!--@end-->", re.S)

FILE_FOR = {
    "traits.json": "resources/data/traits.json",
    "companions.json": "resources/data/companions.json",
}
for _n in ("hell", "hungry_ghost", "animal", "domain"):
    FILE_FOR[f"{_n}_events.json"] = f"resources/data/events/{_n}_events.json"


def container(data, source):
    """The dict of records for a given source file."""
    if source == "traits.json":
        return data
    if source == "companions.json":
        c = data["companions"]
        return c if isinstance(c, dict) else {x["id"]: x for x in c}
    return data["events"]


def resolve(record, field):
    """Return (owner_dict, key) for a field path within one record."""
    if not field.startswith("choices."):
        return record, field
    # choices.<choice_id>.text  |  choices.<choice_id>.<branch>.text
    parts = field.split(".")
    cid = parts[1]
    target = None
    choices = [c for c in record.get("choices", []) if isinstance(c, dict)]
    if cid.startswith("[") and cid.endswith("]"):
        # id-less choice, addressed by position (see export_review_docs.py)
        idx = int(cid[1:-1])
        if idx < len(choices):
            target = choices[idx]
    else:
        for c in choices:
            if str(c.get("id")) == cid:
                target = c
                break
    if target is None:
        return None, None
    if len(parts) == 3:            # choices.<id>.text
        return target, parts[2]
    branch = target.get(parts[2])  # choices.<id>.<branch>.text
    if not isinstance(branch, dict):
        return None, None
    return branch, parts[3]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--write", action="store_true", help="apply the changes")
    args = ap.parse_args()

    loaded, changes, misses = {}, [], []

    for md in sorted(glob.glob(os.path.join(REVIEW, "*.md"))):
        for key, text in ANCHOR.findall(open(md, encoding="utf-8").read()):
            parts = [p.strip() for p in key.split("|")]
            if len(parts) != 3:
                misses.append(f"{os.path.basename(md)}: malformed anchor '{key}'")
                continue
            source, record_id, field = parts
            rel = FILE_FOR.get(source)
            if rel is None:
                misses.append(f"unknown source file '{source}'")
                continue
            if rel not in loaded:
                loaded[rel] = json.load(open(os.path.join(ROOT, rel), encoding="utf-8"))
            records = container(loaded[rel], source)
            if record_id not in records:
                misses.append(f"{source}: no record '{record_id}'")
                continue
            owner, k = resolve(records[record_id], field)
            if owner is None:
                misses.append(f"{source}:{record_id}: cannot resolve '{field}'")
                continue
            new = text.strip()
            old = str(owner.get(k, ""))
            if new != old.strip():
                changes.append((rel, record_id, field, old, new))
                if args.write:
                    owner[k] = new

    if args.write and changes:
        for rel in {c[0] for c in changes}:
            with open(os.path.join(ROOT, rel), "w", encoding="utf-8") as f:
                json.dump(loaded[rel], f, indent=2, ensure_ascii=False)
                f.write("\n")

    for rel, rid, field, old, new in changes:
        print(f"{'APPLIED' if args.write else 'WOULD CHANGE'}  {rid} :: {field}")
        print(f"    - {old[:100]}")
        print(f"    + {new[:100]}")
    print(f"\n{len(changes)} edits {'applied' if args.write else 'pending'}"
          f"{' (run with --write)' if changes and not args.write else ''}")
    if misses:
        print(f"\n{len(misses)} anchors could not be matched:")
        for m in misses[:20]:
            print("   ", m)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
