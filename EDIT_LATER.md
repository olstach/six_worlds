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

---

### Backgrounds whose names and descriptions no longer match what they do (2026-09-07)

Two passes changed what 28 backgrounds teach without touching a word of their
prose, because you said the naming and description pass is coming for all
backgrounds and births together. These are the ones where the gap is widest:

- **`wanderer` is now displayed as "Quickwit"** — `learning 1, comedy 1`. The id
  stays `wanderer`: it is the fallback background in `BASE_CHARACTER`,
  `save_manager`, `karma_system`, `companion_system` and `bardo_screen`, and six
  births list it. Its description still opens "A traveler who has seen many
  places" — it holds, since the wit is the "read people" half, but it is yours to
  re-pitch.
- **`herbalist`** headlines `earth_magic 2` now, with medicine as the minor. Its
  description was already about earth ("they see the weather, time, soil, animals
  and fungi, spirits and the dead") more than about medicine.
- **`honey_alchemist`** ("Honey-Keeper") has no alchemy left at all — it is
  `fire_magic 1, water_magic 1, white_magic 1`, your memory-medicine-and-slow-fire
  reading. The id is now misleading.
- **`temple_warden`** is `martial_arts 2, white_magic 1` and carries no spear or
  armour, though its description still says "martial readiness".
- **`bone_setter`** teaches water magic rather than black magic;
  **`ore_grafted`** teaches enchantment rather than smithing; **`bellows_hand`**
  teaches fire rather than smithing; **`charnel_yogi`** picked up summoning,
  which makes it chöd; **`temple_dove`** dropped ritual for white magic.

Nothing above is a bug — each was chosen from the background's own existing
words. They are listed here so the prose pass knows where to look first.

**New background, Claude's prose:** `shieldbearer` ("Shieldbearer") — Olaf
specified the mechanics (`armor 2`, `earth_magic 1`); the description is mine and
wants your pass like the rest.

### Four vanara companions (2026-09-07) — Claude's prose, wants your pass

`kapisha` (shrine_keeper), `chanchal` (forest_thief), `kelika` (treetop_wit),
`laghima` (storm_watcher). They take vanara from 2 companions to 6, level with
gana and rakshasa, and fill the three vanara-exclusive backgrounds that had
nobody in them; Laghima is a caster, which the roster had none of.

Names come from the vanara list in `animal_realm_names.json` rather than being
invented, and each one's recorded meaning drove the character — Laghima is
"lightness; the quality of being almost nothing, so cannot be caught", so she is
the one who is never caught in the rain. That file is read by nothing and this is
the first content to draw on it.

Edit them in `docs/review/ANIMAL_COMPANIONS.md` and re-import as usual.

