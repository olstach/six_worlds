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

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REVIEW = os.path.join(ROOT, "docs/review")

ANCHOR = re.compile(r"<!--@ (.+?) -->\n(.*?)\n?<!--@end-->", re.S)

FILE_FOR = {
    "traits.json": "resources/data/traits.json",
    "companions.json": "resources/data/companions.json",
    "races.json": "resources/data/races.json",
    # Backgrounds live inside races.json but form their own record set,
    # so they get their own source name to keep anchors three parts wide.
    "backgrounds.json": "resources/data/races.json",
    "shops.json": "resources/data/shops.json",
    "animal_archetypes.json": "resources/data/enemies/animal_archetypes.json",
    "map_animal.json": "resources/data/map_configs/animal.json",
    "animal_realm_names.json": "resources/data/animal_realm_names.json",
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
    if source == "races.json":
        return data["races"]
    if source == "backgrounds.json":
        return data["backgrounds"]
    if source == "shops.json":
        return data["shops"]
    if source == "animal_archetypes.json":
        return data["archetypes"]
    if source == "animal_realm_names.json":
        return _dotted_records(data["regions"])
    if source == "map_animal.json":
        # A single map config rather than a set of records. Expose its parts
        # under stable ids; the values are the live sub-dicts, so writing
        # through them updates the loaded document.
        records = {"map": data, "location_names": data.get("location_names", {})}
        for z in data.get("zones", []):
            if z.get("id"):
                records[f"zone.{z['id']}"] = z
        for lm in data.get("fixed_landmarks", []):
            eid = lm.get("data", {}).get("event_id")
            if eid:
                records[f"landmark.{eid}"] = lm["data"]
        return records
    return data["events"]


def _dotted_records(regions):
    """Flatten the naming lore into dotted record ids: `ocean`,
    `ocean.landscape_features`, `ocean.births.naga`. Values are live
    sub-dicts, so edits write straight back into the loaded document."""
    out = {}
    for region, rdata in regions.items():
        out[region] = rdata
        if isinstance(rdata.get("landscape_features"), dict):
            out[f"{region}.landscape_features"] = rdata["landscape_features"]
        for birth, bdata in (rdata.get("births") or {}).items():
            out[f"{region}.births.{birth}"] = bdata
    return out


SEGMENT = re.compile(r"([^.\[\]]+)|\[(\d+)\]")


def walk_path(record, field):
    """Resolve a dotted path with optional list indices — `town[3]`,
    `personal_names[0].meaning` — to the (owner, key) that holds the string.
    Returns (None, None) if any step does not exist."""
    keys = [name if name else int(idx) for name, idx in SEGMENT.findall(field)]
    if not keys:
        return None, None
    owner = record
    for k in keys[:-1]:
        if isinstance(owner, dict) and isinstance(k, str) and k in owner:
            owner = owner[k]
        elif isinstance(owner, list) and isinstance(k, int) and k < len(owner):
            owner = owner[k]
        else:
            return None, None
    last = keys[-1]
    if isinstance(owner, dict) and isinstance(last, str) and last in owner:
        return owner, last
    if isinstance(owner, list) and isinstance(last, int) and last < len(owner):
        return owner, last
    return None, None


def resolve(record, field):
    """Return (owner, key) for a field path within one record."""
    if not field.startswith("choices."):
        # Plain field on the record, or a nested path into it.
        if "." in field or "[" in field:
            return walk_path(record, field)
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

            # build_weights round-trips as a comma list, strongest first.
            # Rewriting it only when the list actually changed keeps existing
            # weightings intact — re-importing an untouched document is a no-op.
            if k == "build_weights" and isinstance(owner, dict):
                names = [n.strip().rstrip(".").strip().lower().replace(" ", "_")
                         for n in new.split(",") if n.strip()]
                current = owner.get(k, {})
                if names == [x for x, _ in sorted(current.items(), key=lambda kv: -kv[1])]:
                    continue
                weights = [5, 4, 3, 2]
                rebuilt = {n: (weights[i] if i < len(weights) else 2)
                           for i, n in enumerate(names)}
                changes.append((rel, record_id, field, str(current), str(rebuilt)))
                if args.write:
                    owner[k] = rebuilt
                continue

            old = str(owner[k] if isinstance(owner, list) else owner.get(k, ""))
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
