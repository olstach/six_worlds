# Edit Later

### Hungry-ghost-specific content events — ✓ ALL WRITTEN (2026-07-27)

Every ID formerly listed here has been written: the three map-critical events
(boss + both pass guardians) during the audit pass, and the remaining 34
(dungeons, NPC encounters, environmental hazards) in the content pass. The
hungry ghost map now has no dead markers.

**The prose on all of them is Claude's and wants your pass.** Same for the 47
animal realm zone events and the 24 animal companion bios.

---

### Hell and hungry ghost births — the balance pass (2026-09-07)

Hell went from 6 births to 13 and hungry ghost from 14 to 16. **All of the new
prose is Claude's and wants your pass**, and it now round-trips through the
review documents the way the animal realm always has:

```bash
python3 tools/export_review_docs.py     # writes docs/review/
# edit docs/review/HELL_RACES.md and HUNGRY_GHOST_RACES.md between the anchors
python3 tools/import_review_docs.py --write
python3 tools/validate_data.py
```

**Wholly new, no wording of yours in them:**

- Six imps — `flame_imp`, `frost_imp`, `gravel_imp`, `static_imp`,
  `tinnitus_imp`, `sloth_imp`
- `wretch`
- `chidrib` and `zadrib`, the outer and food obscurations of the yidag
- 24 backgrounds — 14 in hell, 10 in hungry ghost
- Four racial traits — `imp_stature`, `wretched`, `outer_obscuration`,
  `flame_mouth`

**Expanded, with your sentence kept verbatim at the front:** the six devils,
`shaza`, `yidag`, and the five elemental skeletons. In every case your original
opening is untouched and a second beat was added after it — the expansion script
refuses to run if the opening no longer matches, so nothing of yours can be
overwritten silently. If a beat is wrong, cut it; the first sentence is still
yours.

