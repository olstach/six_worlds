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
    ap.add_argument("--write", action="store_true")
    ap.add_argument("--check", action="store_true")
    a = ap.parse_args()
    report = sync.run(Path(__file__).resolve().parent.parent, write=a.write, check=a.check)
    report.print()
    return report.exit_code

if __name__ == "__main__":
    sys.exit(main())
