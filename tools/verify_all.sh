#!/usr/bin/env bash
# Is the game healthy? One command.
#
# Four layers, because each catches what the one before it cannot:
#
#   1. parse      — every .gd compiles (tools/parse_check.gd loads each one).
#                   A parse error in one scene is invisible until something
#                   loads it; combat_arena.gd was broken for six days this way.
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
# Usage:  tools/verify_all.sh                 run everything
#         tools/verify_all.sh --quick         skip the engine layers (parse/boot/scenes)
#         tools/verify_all.sh --only economy  layer 4 runs only verifiers whose
#                                             name matches — for the loop after
#                                             something fails, when re-running
#                                             all twenty scenes at up to 180s
#                                             each is most of a coffee break
#
# Exit code is non-zero if any layer fails, so it can gate a commit.

set -uo pipefail
cd "$(dirname "$0")/.." || exit 2

GODOT="${GODOT:-godot}"
QUICK=0
ONLY=""
while [ $# -gt 0 ]; do
    case "$1" in
        --quick) QUICK=1 ;;
        --only)
            shift
            [ $# -gt 0 ] || { echo "--only needs a pattern" >&2; exit 2; }
            ONLY="$1" ;;
        --only=*) ONLY="${1#--only=}" ;;
        *) echo "unknown argument: $1" >&2; exit 2 ;;
    esac
    shift
done

failed=0
log() { printf '\n\033[1m── %s\033[0m\n' "$1"; }
ok()  { printf '   \033[32mOK\033[0m  %s\n' "$1"; }
bad() { printf '   \033[31mFAIL\033[0m %s\n' "$1"; failed=1; }

# Running the editor rewrites files Godot 4.7 reformats on open and refreshes
# the .godot caches. Put the tree back afterwards so a verification run never
# shows up as a source change — but keep global_script_class_cache.cfg, which
# is tracked and must be current for any newly added class_name to resolve.
#
# Restore from a SNAPSHOT TAKEN AT STARTUP, not from git HEAD. Reverting to HEAD
# also destroys uncommitted edits to these files, which is a nasty trap: add a
# key to statuses.json, run the verifier to check it, and the verifier silently
# deletes your change and then reports that nothing reads it. That happened
# while this very aura refactor was being written. A snapshot undoes Godot's
# reformat and nothing else.
REFORMATTED_FILES=(project.godot resources/data/races.json resources/data/statuses.json)
SNAPSHOT_DIR=$(mktemp -d)
trap 'rm -rf "$SNAPSHOT_DIR"' EXIT

for f in "${REFORMATTED_FILES[@]}"; do
    [ -f "$f" ] && cp "$f" "$SNAPSHOT_DIR/$(echo "$f" | tr / _)"
done

restore_tree() {
    for f in "${REFORMATTED_FILES[@]}"; do
        snap="$SNAPSHOT_DIR/$(echo "$f" | tr / _)"
        [ -f "$snap" ] && cp "$snap" "$f"
    done
    git checkout -- .godot/editor .godot/uid_cache.bin 2>/dev/null
}

if [ "$QUICK" -eq 0 ]; then
    log "1. parse — every script compiles"
    # The editor pass refreshes the class_name cache, so it runs first. It is
    # NOT a compile of every script: the editor's scan only reads far enough to
    # find each class_name, so a duplicate function or undeclared name in a
    # script nothing loads (a tools/verify_*.gd, say) passed this layer and
    # surfaced only when its scene ran. parse_check.gd then loads every .gd
    # for real, which runs the full parser and analyzer.
    parse_out=$(timeout 300 "$GODOT" --headless --editor --quit 2>&1 \
        | grep -E "SCRIPT ERROR|Failed to load script" || true)
    restore_tree
    parse_log=$(mktemp)
    # Redirect, not pipe — same buffered-stdout reason as the boot layer below.
    timeout 300 "$GODOT" --headless -s tools/parse_check.gd > "$parse_log" 2>&1
    restore_tree
    nl=$'\n'
    broken=$(grep -E "SCRIPT ERROR: Parse Error|Failed to load script|PARSE BROKEN" "$parse_log" || true)
    grep -q "^PARSE CHECK:" "$parse_log" \
        || broken+="${broken:+$nl}parse_check.gd never reported — it crashed or timed out"
    [ -n "$broken" ] && parse_out+="${parse_out:+$nl}$broken"
    grep -E "^PARSE CHECK:" "$parse_log" | sed 's/^/        /'
    rm -f "$parse_log"
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
    if [ -n "$ONLY" ]; then
        log "4. verifiers — only those matching '$ONLY'"
    else
        log "4. verifiers — run inside the engine, against live autoloads"
    fi
    matched=0
    for scene in tools/verify_*.tscn; do
        name=$(basename "$scene" .tscn)
        if [ -n "$ONLY" ] && [ "${name#*$ONLY}" = "$name" ]; then
            continue
        fi
        matched=1
        out=$(timeout 180 "$GODOT" --headless "$scene" 2>&1)
        restore_tree
        # "VERIFY OK" alone is not enough: a script error that aborts one
        # check partway can still let the scene print it at the end. And show
        # SCRIPT ERROR lines on failure — a parse error in the verifier itself
        # otherwise prints nothing matching FAIL and the failure is a blank.
        if echo "$out" | grep -q "VERIFY OK" && ! echo "$out" | grep -q "SCRIPT ERROR"; then
            ok "$name"
        else
            bad "$name"
            echo "$out" | grep -E "FAIL|VERIFY|SCRIPT ERROR" | head -12 | sed 's/^/        /'
        fi
    done
    # A typo in --only silently running nothing would read as a clean pass.
    if [ -n "$ONLY" ] && [ "$matched" -eq 0 ]; then
        bad "no verifier matched '$ONLY'"
    fi
fi

echo
if [ "$failed" -eq 0 ]; then
    printf '\033[32mALL CHECKS PASSED\033[0m\n'
else
    printf '\033[31mSOME CHECKS FAILED\033[0m\n'
fi
exit "$failed"
