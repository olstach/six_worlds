#!/usr/bin/env bash
# Is the game healthy? One command.
#
# Four layers, because each catches what the one before it cannot:
#
#   1. parse      — every .gd compiles. A parse error in one scene is invisible
#                   until something loads it; combat_arena.gd was broken for six
#                   days this way.
#   2. boot       — autoloads actually initialise, and load the counts they
#                   should. A clean parse does not mean a clean boot.
#   3. data       — cross-references between JSON files, and the reverse check:
#                   values declared in data that no code reads.
#   4. verifiers  — the verify_*.tscn scenes, which run inside the engine
#                   against the live autoloads. validate_data.py parses JSON in
#                   Python and never exercises a GDScript loader, which is how
#                   animal_events.json once loaded 0 of its 86 events while the
#                   validator reported no issues at all.
#
# Usage:  tools/verify_all.sh          run everything
#         tools/verify_all.sh --quick  skip the engine layers (parse/boot/scenes)
#
# Exit code is non-zero if any layer fails, so it can gate a commit.

set -uo pipefail
cd "$(dirname "$0")/.." || exit 2

GODOT="${GODOT:-godot}"
QUICK=0
[ "${1:-}" = "--quick" ] && QUICK=1

failed=0
log() { printf '\n\033[1m── %s\033[0m\n' "$1"; }
ok()  { printf '   \033[32mOK\033[0m  %s\n' "$1"; }
bad() { printf '   \033[31mFAIL\033[0m %s\n' "$1"; failed=1; }

# Running the editor rewrites files Godot 4.7 reformats on open and refreshes
# the .godot caches. Put the tree back afterwards so a verification run never
# shows up as a source change — but keep global_script_class_cache.cfg, which
# is tracked and must be current for any newly added class_name to resolve.
restore_tree() {
    git checkout -- project.godot resources/data/races.json \
        resources/data/statuses.json 2>/dev/null
    git checkout -- .godot/editor .godot/uid_cache.bin 2>/dev/null
}

if [ "$QUICK" -eq 0 ]; then
    log "1. parse — every script compiles"
    parse_out=$(timeout 300 "$GODOT" --headless --editor --quit 2>&1 \
        | grep -E "SCRIPT ERROR|Failed to load script" || true)
    restore_tree
    if [ -n "$parse_out" ]; then
        bad "parse errors:"; echo "$parse_out" | sed 's/^/        /'
    else
        ok "no parse errors"
    fi

    log "2. boot — autoloads initialise"
    boot_log=$(mktemp)
    # Redirect rather than pipe: timeout SIGTERMs Godot before its buffered
    # stdout flushes, so a pipe silently yields nothing and a broken boot
    # looks clean.
    timeout 40 "$GODOT" --headless > "$boot_log" 2>&1
    restore_tree
    boot_err=$(grep -cE "ERROR|SCRIPT ERROR" "$boot_log")
    if [ "$boot_err" -ne 0 ]; then
        bad "$boot_err error line(s) during boot:"
        grep -E "ERROR|SCRIPT ERROR" "$boot_log" | head -10 | sed 's/^/        /'
    else
        ok "boot clean"
    fi
    # An autoload that dies mid-_ready() prints no error and simply never
    # reports. Check the ones whose absence would gut the game.
    for system in PerkSystem CharacterSystem CombatManager EventManager ItemSystem; do
        grep -q "^$system initialized" "$boot_log" \
            || bad "$system never reported initialising"
    done
    grep -E "^(Loaded|.*initialized)" "$boot_log" | sed 's/^/        /'
    rm -f "$boot_log"
fi

log "3. data — cross-references, and values no code reads"
if python3 tools/validate_data.py > /tmp/_vd.log 2>&1; then
    ok "$(head -1 /tmp/_vd.log)"
else
    bad "validate_data.py:"; sed 's/^/        /' /tmp/_vd.log
fi
rm -f /tmp/_vd.log

if [ "$QUICK" -eq 0 ]; then
    log "4. verifiers — run inside the engine, against live autoloads"
    for scene in tools/verify_*.tscn; do
        name=$(basename "$scene" .tscn)
        out=$(timeout 180 "$GODOT" --headless "$scene" 2>&1)
        restore_tree
        if echo "$out" | grep -q "VERIFY OK"; then
            ok "$name"
        else
            bad "$name"
            echo "$out" | grep -E "FAIL|VERIFY" | head -12 | sed 's/^/        /'
        fi
    done
fi

echo
if [ "$failed" -eq 0 ]; then
    printf '\033[32mALL CHECKS PASSED\033[0m\n'
else
    printf '\033[31mSOME CHECKS FAILED\033[0m\n'
fi
exit "$failed"
