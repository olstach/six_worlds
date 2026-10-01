#!/usr/bin/env bash
# Build docs/SIX_WORLDS_WRITERS_GUIDE.pdf from the game data.  Two passes so the contents page has real page numbers.
set -euo pipefail
cd "$(dirname "$0")/../.."
W=tools/writer_guide
TMP=${TMPDIR:-/tmp}/six_worlds_guide; mkdir -p "$TMP"
python3 $W/build.py "$TMP/guide.html"
node $W/render.js "$TMP/guide.html" "$TMP/pass1.pdf"
python3 $W/pages.py "$TMP/pass1.pdf" "$TMP/guide.toc.json" "$TMP/pages.json"
python3 $W/build.py "$TMP/guide.html" "$TMP/pages.json"
node $W/render.js "$TMP/guide.html" docs/SIX_WORLDS_WRITERS_GUIDE.pdf
python3 $W/pages.py docs/SIX_WORLDS_WRITERS_GUIDE.pdf "$TMP/guide.toc.json" "$TMP/pages2.json"
cmp -s "$TMP/pages.json" "$TMP/pages2.json" && echo "page numbers stable" || echo "WARNING: page numbers shifted between passes"
