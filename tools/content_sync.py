#!/usr/bin/env python3
"""Keep CONTENT.md and resources/data in agreement.

  python3 tools/content_sync.py            dry run: show what would change
  python3 tools/content_sync.py --write    apply it
  python3 tools/content_sync.py --check    for verify_all.sh: fail if anything is pending

Edit writing in CONTENT.md, run --write, and the JSON follows. Code that
changes the JSON shows up in CONTENT.md the next time this runs. If the same
text changed in both places, nothing is written and both versions are shown.
"""
import argparse, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))
from content import sync

def main() -> int:
    ap = argparse.ArgumentParser()
    mode = ap.add_mutually_exclusive_group()   # one or the other, not both
    mode.add_argument("--write", action="store_true")
    mode.add_argument("--check", action="store_true")
    ap.add_argument("--rebase-base", action="store_true",
                    help="rebuild content_base.json from the JSON as it is now "
                         "and the notes in CONTENT.md (use after a git conflict)")
    a = ap.parse_args()
    report = sync.run(Path(__file__).resolve().parent.parent, write=a.write,
                      check=a.check, rebase_base=a.rebase_base)
    report.print()
    return report.exit_code

if __name__ == "__main__":
    sys.exit(main())
