# Terrain and zones — audit

> **Steps 1–3 are done (2026-09-15).** One vocabulary in
> `resources/data/terrain.json`, read through `Ground` by both the map and the
> battle grid; the battlefield built in three passes by
> `BattlefieldGenerator`, so arrangement survives the zoom; all fourteen
> terrains carry battle traits. Both magic-number tables are gone.
>
> **Remaining: zones (step 4) and height from hills and mountains (step 5).**
> The three open questions at the foot of this document are still open.

**2026-09-15.** Covers the overworld map and the battle grid together, because
Olaf wants them contiguous: the battlefield should read as a zoom into the tile
the party is standing on, the way Moonring does it and Qud does to a lesser
degree.

That goal is the right one to audit against, and it turns out to be blocked by
two things rather than one. The systems do not share a vocabulary, and the
bridge between them is statistical rather than spatial.

---

## 1. Two vocabularies that share no words

**The overworld** has one concept: `MapManager.Terrain`, fourteen types, each
carrying a speed multiplier and passability.

```
PLAINS 0   ROAD 1     FOREST 2   HILLS 3    MOUNTAINS 4  WATER 5   SWAMP 6
DESERT 7   SNOW 8     LAVA 9     BRIDGE 10  ICE 11       SAND 12   RUINS 13
```

**The battle grid** has four, none of them that one:

| concept | values |
|---|---|
| `TileType` | FLOOR, WALL, PIT, WATER, DIFFICULT |
| `TerrainEffect` | NONE, FIRE, ICE, POISON, ACID, BLESSED, CURSED, WET, STORMY, VOID, SMOKE |
| `ObstacleType` | NONE, TREE, ROCK, PILLAR, BARRICADE, FALLEN_TREE |
| height | an integer per tile, with its own cover/accuracy/damage rules |

Nothing is named the same thing in both, and the two collisions are false
friends. Overworld `WATER` is *impassable ground*; combat `WATER` is a
`TileType` you can wade through. Overworld `ICE` is *fast but slippery ground*;
combat `ICE` is a `TerrainEffect` hazard sitting on top of a tile.

So a battle tile cannot currently answer "what kind of ground is this?" — only
"is it floor, wall, pit, water or difficult", which is a movement question, not
a place.

---

## 2. The bridge is statistical, not spatial

This is the part that actually blocks the zoom.

`_sample_terrain_context()` takes a **5×5 window** around the party, counts how
many tiles of each terrain it contains, and records the most common one as
`dominant`.

`_generate_combat_terrain()` then turns those counts into **budgets** —

```gdscript
match int(terrain_type):
    4:  # MOUNTAINS → walls + rocks
        wall_budget += count
        rock_budget += count * 2
    2:  # FOREST → trees + fallen logs
        difficult_budget += count
        tree_budget += count * 3
```

— and scatters that many obstacles at **random positions** across the 48×30
grid.

The battlefield therefore reflects the *proportions* of the terrain around the
party and discards its *arrangement*. Stand at the shore of a lake with forest
behind you and you get a field with some water somewhere and some trees
somewhere, rather than water on one side and trees on the other.

**A zoom needs the arrangement.** 48×30 over a 5×5 sample is roughly a 9×6
block of battle tiles per overworld tile, which is a good chunk size — big
enough to read as terrain, small enough that five of them across the field
still feels like one place.

---

## 3. Defects found on the way

- **The mapping is keyed on bare integers.** `match int(terrain_type): 4:` with
  the name in a comment. Two tables do this — the generator and
  `SUMMON_TERRAIN_AFFINITY` in combat_manager.gd. Reordering the `Terrain` enum
  would silently remap every battlefield and every summon bonus, and no
  validator can see it, because it is code rather than data.

- **Five of fourteen terrains generate nothing at all:** PLAINS, ROAD, DESERT,
  BRIDGE, SAND. A desert battle is a featureless plain with some random
  chasms — the same field you get in grassland. `SUMMON_TERRAIN_AFFINITY`
  misses SNOW as well, so a battle in deep snow offers no Water affinity while
  one on ice does.

- **`dominant` is computed, stored in GameState, passed into the generator, and
  never read there.** It is a dead local; the only live use is the summon
  affinity lookup elsewhere. The one comment mentioning it — "ICE patches
  (dominant snow/ice)" — describes behaviour driven by `counts`.

- **Nine of eleven `TerrainEffect` values are never produced by terrain.** Only
  FIRE and ICE are placed. POISON, ACID, BLESSED, CURSED, WET, STORMY, VOID and
  SMOKE exist and only spells create them, which is defensible — but WET on a
  water map and SMOKE on a lava one are free wins nobody took.

- **Height has no overworld counterpart.** The battle grid has elevation with
  real rules — cover, accuracy, range and damage bonuses — and HILLS and
  MOUNTAINS produce rocks and walls rather than high ground. The most obviously
  spatial terrain in the game generates none of the spatial mechanic that
  exists for it.

---

## 4. Zones do not exist

Five spells are inert for want of them, and three more are partly so.

| spell | wants |
|---|---|
| `grave_soil` | ground that turns anything dying on it into an allied zombie |
| `false_terrain` | ground that lies about what it is, hiding traps and faking walls |
| `shroud_of_darkness` | an area that obscures sight and cuts ranged reach by half |
| `vajra_gate` | two marked points with a short-lived passage between them |
| `clear_air` | removal of "cloud effects", a category that exists in no file |
| `vajra_mandala` | a circle protecting allies inside and hurting enemies entering |
| `tornado` | a hazard that **relocates itself** each round |
| `rain_of_mud` | ground that stays muddy after the spell lands |

**A zone is an aura with a place instead of a body.** That is the whole
insight. `AuraSystem` already answers "what does an area do to whoever is in
it" — `grant_status`, `heal`, `damage`, `stat`, `damage_taken_pct`, with
`affects`, a radius, and payloads that may be gated on a save. Every one of
those payloads is equally meaningful anchored to a set of tiles.

What a zone needs that an aura does not: a set of tiles rather than a centre
and radius, a duration that ticks down on its own, enter/leave semantics
(`unit_moved` already exists for the trigger), and — for the tornado — the
ability to move.

What it does NOT need is a new payload vocabulary. Building zones on
`AuraSystem`'s is the difference between one mechanism with two anchors and
two mechanisms that drift apart, which is the specific failure this codebase
keeps finding.

---

## 5. The proposal

### One vocabulary

A battle tile gains a **ground type** drawn from `MapManager.Terrain` — the
same fourteen names — alongside what it already has. `TileType` stops being the
answer to "what is this place" and becomes what it actually is: whether the
tile can be walked, blocked, fallen into or waded.

So a tile is: *ground* (forest) + *passability* (floor) + *hazard* (none) +
*obstacle* (tree) + *height* (0). Each answers a different question, and the
first one is currently missing.

### Spatial generation

Map the 5×5 sample onto the grid as a 5×5 arrangement of ~9×6 blocks, each
block taking its ground type from the corresponding overworld tile. Seed
obstacles and hazards *within* each block according to its own ground, rather
than scattering a global budget.

The party deploys at x 16–19 and the enemy at x 28–31, which straddles the
centre block — the tile the party is actually standing on. That is the correct
place for them to be.

Borders between blocks want softening so the field does not read as a grid of
squares, but that is a generation detail rather than a design question.

### Zones as placed auras

Extend `AuraSystem` with a placed anchor, or add a `ZoneSystem` sharing its
payload vocabulary. Either way the payloads stay in one list.

### Terrain names, not numbers

Move the terrain-to-battlefield mapping out of a `match` on integers and into
data, so that `validate_data.py` can check it and so that adding a terrain
means adding a row rather than remembering two tables.

---

## 6. Order

1. **Ground type on battle tiles, and the mapping into data.** Nothing visible
   changes; it makes everything after it possible and kills the magic numbers.
2. **Spatial generation.** This is the contiguity Olaf asked for, and the
   biggest visible change.
3. **The five missing terrains**, which become one data row each once (1) is
   done.
4. **Zones**, and with them five inert spells and the three partial ones.
5. **Height from HILLS and MOUNTAINS** — the cheapest remaining win, since the
   height mechanics already exist and go unused.

Open questions for Olaf, which the work above does not settle:

- Should combat change the overworld? A forest burned down in a fight, a wall
  broken, a chasm opened — the maps persist now, so it is possible.
- Should battlefields persist too, if the same tile is fought on twice?
- Is height worth sampling from the overworld at all, or is it a battle-only
  concept that HILLS merely suggests?
