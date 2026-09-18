# Six Worlds — Map Tile Art Brief

*Everything needed to draw the first set of overworld map tiles. No tileset
experience assumed — this explains what a tileset is, how this game wants one
arranged, and exactly which tiles to draw in which order. Companion to
`docs/SIX_WORLDS_COMPOSER_BRIEF.md`.*

---

> **The template is generated and waiting in `assets/tiles/`.** Cell size is
> settled at **24×24**. Read `assets/tiles/terrain_atlas_guide.png` for the
> labelled row-by-row reference, then paint the named blanks in
> `assets/tiles/terrain/`. `assets/tiles/README.md` is the two-minute version
> of this document.

## 0. The one-paragraph answer

Draw **one PNG**. It is a grid of equal-sized cells, no gaps. Each **row** is
one terrain type, in a fixed order given below. Each **column** is a different
random variant of that same terrain. The minimum useful delivery is **14 tiles
— a single column, one per terrain**. The comfortable target is **56 tiles — 4
variants each**. Every tile must fill its cell completely, be fully opaque,
and look correct with any other tile touching any of its four sides. Nothing
else is needed to see real art in the game.

---

## 1. What a tileset actually is

A map in a tile-based game is not one big painting. The world is a grid of
squares, and the engine paints each square by copying a small rectangle out of
one shared image. That shared image is the **tileset** (or **atlas**, or
**sheet**). It's just a PNG.

The only thing that makes it a tileset rather than a normal picture is that its
contents are laid out on a strict, regular grid, so the engine can address any
cell by two numbers: **column and row**. Cell (0,0) is top-left, (1,0) is the
one to its right, (0,1) is the one below it. Nothing is stored about what a
cell *means* — that's a mapping decided in code.

So there are really only three things to agree on:

1. **How big is a cell?** (section 3)
2. **What lives at each row and column?** (section 4)
3. **What rules must an individual tile obey so it works next to any other?**
   (section 5)

Two things you might have read about elsewhere and can safely ignore for now:

- **Godot's TileMap / TileSet editor.** This game does *not* use it. The
  overworld draws itself with custom code (`scripts/overworld/map_renderer.gd`),
  currently painting a flat colour rectangle per square. Swapping "paint a
  rectangle" for "copy cell (c,r) out of the sheet" is a small change inside
  that one file. You never have to open Godot's tile editor or configure
  anything in the engine. **Hand over a PNG; that's the whole handoff.**
- **Autotiling / Wang tiles / blob tiles.** That's the machinery for drawing
  smooth transitions where grass meets water — it needs 16 or 47 tiles per
  terrain instead of 1, and it's the single biggest reason first tilesets never
  get finished. **Not in scope.** Section 8 covers how to add it later if the
  hard edges bother us. Today the map has hard colour edges and reads fine.

---

## 2. What the map looks like right now

Worth knowing what you're replacing. The overworld is a grid up to 192×192
squares (Hell is 192×144, the other two 192×192). Terrain is generated in
small **clumps of 2–7 squares of the same type**, not as smooth continents —
so a screen is a mosaic of small patches, and *variety within one terrain
matters more than variety between terrains*. That's why variant columns earn
their keep.

Each square is currently a flat colour with a faint black grid line, plus
procedural overlays that will be **deleted once real art exists**:

- impassable squares get a black ✕ drawn across them
- slow squares get four small dark dots
- fast squares (road, bridge, ice) get a pale vertical line down the middle

Those overlays are placeholders for information the art must carry instead —
see section 6.

Drawn on top of the terrain, and staying as code-drawn shapes for now: the
party (gold circle), creatures (coloured circles with name labels under them),
map objects (squares/diamonds/circles), a dark fog wash over unvisited squares,
a translucent yellow path trail, and a hover outline.

---

## 3. Cell size — and one thing I need to fix in code

**Decided: 24×24 pixels per cell, displayed at 2×.** Every generated template
and blank is already this size.

The game's grid is 48 world-pixels per square, in both the overworld and the
tactical battle grid (they deliberately match). A 24×24 drawing scaled up 2× is
exactly 48 — a clean doubling, where every drawn pixel becomes a crisp 2×2
block. This gives a classic chunky pixel-art read, is about a quarter of the
drawing labour of native 48×48, and stays flexible: upscaling further later is
free, whereas shrinking art you've already drawn is destructive.

| Option | You draw | On-screen scale | Verdict |
|---|---|---|---|
| **24×24** | 576 px per tile | 2× | **Chosen.** Classic, crisp, fastest to iterate |
| 16×16 | 256 px per tile | 3× | Fastest of all; may read too coarse against the ornate UI |
| 48×48 | 2304 px per tile | 1× | Most detail, ~4× the work, and harder to keep tiles reading cleanly at a glance |

If it turns out to be the wrong call once you've drawn a few, it is one
constant in `tools/tile_atlas.py` (`CELL`) plus a regenerate — but changing it
after a full set is drawn means redrawing, so the time to object is now. Don't
mix sizes within a sheet.

> **A problem on my side, not yours.** The overworld camera is currently fixed
> at zoom 1.5 (`scenes/overworld/overworld.tscn`), and the project has no
> texture-filter setting, so it defaults to smoothing. Pixel art at 1.5× gets
> unevenly stretched and blurred — some rows of pixels doubled, some not. Before
> any art lands I need to (a) set texture filtering to nearest-neighbour and
> (b) move the camera to an integer zoom. **Don't compensate for this in your
> drawings.** Draw at true pixel scale and I'll make the engine show them
> honestly.

---

## 4. The sheet layout

**Row = terrain type. Column = variant of that terrain.**

- Cells are butted directly together: **no margin around the sheet, no gaps
  between cells, no separator lines.** A stray 1px gutter shifts every tile
  after it.
- Rows must be in the exact order in the table below. That order is the
  `Terrain` enum in `scripts/autoload/map_manager.gd`, and it is baked into
  every saved game — so it cannot be rearranged for convenience. Row index =
  terrain ID.
- Column 0 is the one that must exist for every terrain. Columns 1–3 are extra
  variants, picked deterministically per map square (the same square always
  draws the same variant, so the map doesn't shimmer as you walk). **If a row
  has fewer variants drawn than others, leave the unused cells fully
  transparent and I'll fall back to column 0 for that terrain** — rows don't
  have to be equally full.
- Final sheet at 4 columns × 14 rows, 24px cells: **96 × 336 pixels.**
- PNG, 32-bit with alpha channel (alpha only for unused cells; drawn cells are
  fully opaque).

| Row | Terrain | ID | Speed | Placeholder colour | Notes |
|:--:|---|:--:|:--:|:--:|---|
| 0 | Plains | 0 | 1.0 (normal) | `#598C40` | The default ground. Most common tile in the game |
| 1 | Road | 1 | **2.0 (fastest)** | `#8C7359` | Paved. Must read as "travel here" |
| 2 | Forest | 2 | 0.5 (slow) | `#265926` | Dense woodland seen from above |
| 3 | Hills | 3 | 0.5 (slow) | `#80734C` | Steep, not impassable |
| 4 | Mountains | 4 | **impassable** | `#666673` | Also used as solid walls dividing realms |
| 5 | Water | 5 | **impassable** | `#335999` | Deep water |
| 6 | Swamp | 6 | 0.5 (slow) | `#4C6640` | Boggy marsh |
| 7 | Desert | 7 | 0.75 | `#BFA666` | Arid cracked wasteland |
| 8 | Snow | 8 | 0.5 (slow) | `#D9E0EB` | Deep snow tundra |
| 9 | Lava | 9 | **impassable** | `#D9401A` | Molten rock |
| 10 | Bridge | 10 | 1.5 (fast) | `#80664C` | Built crossing over water/chasm |
| 11 | Ice | 11 | 1.25 (fast, treacherous) | `#B2D9F2` | Frozen surface — *slick*, not deep snow |
| 12 | Sand | 12 | 0.75 | `#CCB273` | Loose dunes |
| 13 | Ruins | 13 | 0.75 | `#736661` | Crumbling stonework |

The placeholder colours are what the game paints today. Treat them as the
*value and hue anchor* — the map's current readability comes from those
relationships — but you're free to improve them. If you shift one a lot, tell
me so I can retire the matching constant rather than leave two truths in the
code.

---

### 4a. Palettes — the same terrain, different in each region

Cold hell is icy blues; fire hell is red embers. That is the same fourteen
terrains drawn twice, so one sheet cannot hold it. The extra axis is a
**palette**: a whole set of tiles in its own folder.

```
assets/tiles/terrain/base/          the fallback set
assets/tiles/terrain/cold_hell/     only the tiles that differ
assets/tiles/terrain/fire_hell/     only the tiles that differ
```

Each folder holds the same 56 filenames and packs to its own atlas
(`terrain_atlas_cold_hell.png`, …). A palette needs **only the tiles that
differ** — leave the rest empty and they fall through to `base`, and then to
the flat placeholder colour. So a palette is an override set, not a duplicate.

The folder name is a **region id**, exactly as `MapManager.get_region_at()`
already returns it: `cold_hell`, `fire_hell`, `fetid_swamps`,
`charnel_grounds`, `dry_graveyards`, `forest`, `meadow`, `ocean`. That is not
a convention I invented for the art — the map already records which region
every square belongs to, saves it, and reloads it, so the renderer can ask
per square and pick the palette with no mapping layer and no new map data.
Region rects don't overlap (`cols` separates the ones that share rows), so
every square resolves to exactly one.

`python3 tools/tile_atlas.py init --palette cold_hell --palette fire_hell`
creates them; both already exist.

## 5. The golden rule

> **Every tile must look correct with any other tile on any of its four sides,
> and must occupy its cell edge to edge — though not necessarily opaquely.**

This is what lets us skip autotiling entirely. In practice:

- **Transparency is intended** — see section 5a. Each realm has a coloured
  backdrop behind the tiles, and the gaps you leave are what lets it through.
  What still holds is the *edge* discipline below.
- **Nothing crosses the cell boundary.** No branch, shadow, or rock overhanging
  the edge. A tree crown that spills 3px past the edge will be cut off.
- **No directional features.** A road tile must not be "a road running
  north–south" — it must be *a square entirely made of road surface*, so that
  any arrangement of road tiles forms a connected road automatically. Same for
  rivers, bridges, walls. This is the rule beginners most often break, and it's
  the one that makes the whole set work or not work.
- **Edges should be quiet, centres can be busy.** Anything loud at the border
  of a cell will visibly repeat into a hard seam when two of the same tile sit
  side by side.
- **No baked-in lighting direction** that assumes a neighbour. Flat, even,
  top-down light.
- **Repeat-test each tile:** paste it in a 3×3 block. If your eye finds an
  obvious repeating shape — one bright flower, one distinct rock — soften it or
  move it to a variant.

---

### 5a. The realm backdrop

Tiles are **not** opaque. Each realm gets a coloured backdrop behind the whole
map, and the transparent areas of every tile let it through, so one colour
permeates everything and the ground reads as dreamlike rather than solid.

**One backdrop per realm, not per zone.** Hell is black. The realm is the thing
the player is inside of, and holding one colour across the whole of it is what
makes it feel like a single place; the two halves of hell differ in their
*tiles* — icy blues north, red embers south — not behind them. Waves and
ripples moving through that blackness come later: a canvas shader on the
existing `Background` node, which changes nothing about the tiles.

This replaces the per-realm colour grade proposed earlier in section 8. It is
the better mechanism: a grade multiplies the art and dulls it, whereas a
backdrop showing through *keeps* whatever opacity you painted at full strength
and tints only the gaps. It also means a single tile set genuinely serves all
six realms.

Consequences worth holding in mind while drawing:

- **A tile cannot be judged on its own.** How it reads depends entirely on what
  is behind it. Use `tools/tile_atlas.py preview` constantly — it composites
  your actual tiles over candidate backdrops on a map laid out with the real
  zone weights.
- **Opacity is a design tool, not a constant.** Ground the player walks on can
  be ghostly. The three hard walls — Mountains, Water, Lava — should stay
  substantially opaque, because a wall that takes on the backdrop colour stops
  reading as a wall. `check` flags an impassable tile under 60% coverage; that
  is a prompt to look, not a rule.
- **Black is the strongest case of this.** Over pure black, anything you leave
  transparent goes to black, so the opaque parts of a tile carry the entire
  read. Ghostly works, but a tile that is 30% opaque over black is a 30%-lit
  object floating in a void — which may be exactly the dream you want, or may
  vanish. Preview before committing to a coverage level.
- **Dark backdrops raise contrast between light and dark terrains and
  compress it among the dark ones.** Snow over a near-black backdrop stays
  bright and separates cleanly; forest, swamp and ruins over the same backdrop
  converge toward each other. If two terrains must not be confused (Snow vs
  Ice, Forest vs Swamp), separate them by *texture and silhouette*, which
  survives any backdrop, rather than by value.
- **The grid lines go.** A faint black line per square, seen through partly
  transparent tiles, reads as a hard lattice over a dreamy surface. That settles
  open question 5 — they're dropped.

Candidate backdrops per realm live in `REALM_BACKDROPS` in
`tools/tile_atlas.py` — hell's is `#000000`. `preview --backdrop "#RRGGBB"`
tries anything else.

### 5b. What still has to hold

Transparency does not relax the adjacency rules — if anything it tightens them,
because the backdrop is continuous underneath and any seam in your art now
shows against a smooth field:

- **Nothing crosses the cell boundary**, and nothing may *stop short* of it in
  a way that draws a visible square outline. Fading toward the edge is fine;
  a hard rectangular border of transparency is not — it will tile into a grid.
- **No directional features**, exactly as before.
- **Corners are the risk.** Four different tiles meet at every corner. Keep
  opacity roughly consistent along an edge, or the map grows a faint dot
  pattern at the corners.

## 6. What the art has to communicate

The procedural ✕ / dots / centre-line overlays come out when art goes in. So
the tiles themselves must make three things legible at a glance, without a
legend:

1. **Impassable vs passable.** Mountains, Water, and Lava are hard walls
   (barring rare abilities: flight, water-walking, lava immunity). A player
   must never route a path into one by mistake. These three want strong value
   contrast against everything around them and an obvious *density* — solid
   rock, deep dark water, molten flow. Nothing soft or ambiguous.
2. **Fast vs slow.** Road (2.0) and Bridge (1.5) are the fastest ground in the
   game and should read as *made, cleared, deliberate* — smooth, worked
   surfaces against organic ones. Forest, Hills, Swamp and Snow (all 0.5)
   should read as *cluttered and obstructive* — visual texture, broken
   silhouettes, things in the way.
3. **Ice is not snow.** Ice (11) is *fast* and slippery; Snow (8) is *slow* and
   deep. They sit next to each other constantly in the frozen half of Hell and
   must not be confusable. Suggested split: snow soft, matte, undulating,
   footprint-able; ice hard, glassy, cracked, with a specular glint.

Two more constraints from how the map is drawn:

- **Fog of war.** Unvisited squares get a 70%-opacity near-black wash over
  them — over the backdrop as well as the tile, so fogged ground goes uniformly
  dark. Tiles should still be *identifiable* when that dark, which means
  distinguishing terrains by texture and shape, not by hue alone.
- **Markers sit on the centre.** The party circle, creature circles and object
  markers occupy roughly the middle 50–70% of a square and have their name
  labels drawn just below. A tile with a single dominant feature dead-centre
  will be permanently hidden under a marker. Prefer detail distributed around
  the cell, or off-centre.

---

## 7. Draw them in this order

**This section was wrong in the first version of this brief and is now
corrected.** It ranked terrains by the raw `terrain_weights` in the map
configs. But the generator does not stop at those weights — it runs **three
passes of cellular-automata smoothing** (`_smooth_cell` in
`scripts/map_gen/map_generator.gd`), each cell becoming the majority of its
nine-neighbourhood with a bias toward keeping itself. Smoothing is not
neutral: it **amplifies whatever is already dominant and all but erases the
minority terrains**. A terrain weighted 30 ends up near 50% of the ground; a
terrain weighted 8 ends up under 2%.

Measured by reproducing the generator's fill and smoothing over the real
configs, six seeds each (spread under ±1%, so these are stable):

### Naraka — Hell

| Terrain | Share of the realm | Running |
|---|--:|--:|
| **Plains** | 48% | 48% |
| **Snow** | 15% | 63% |
| **Desert** | 14% | 77% |
| **Mountains** | 9% | 86% |
| **Lava** | 7% | 92% |
| Sand | 2.1% | 94% |
| Hills | 1.6% | 96% |
| Ruins | 1.2% | 97% |
| Water | 1.0% | 98% |
| Forest | 0.8% | 99% |
| Ice | 0.6% | 99.5% |
| Road | 0.5% | 100% |

Split by half: **cold hell is Plains 59% + Snow 34%** — those two are 93% of
the northern half. **Fire hell is Plains 50% + Desert 27% + Lava 13%** — 90% of
the southern half. The divider between them is a solid band of Mountains, 9% of
the whole map, and the only way through is a carved pass.

So for hell the first five tiles are **Plains, Snow, Desert, Mountains, Lava**
— 92% of everything the player sees. Plains wants the most variants of
anything in the game; at 48% it is half the realm.

Hills and Forest are under 2% of hell. They are worth drawing eventually,
because a rare tile that looks wrong is still conspicuous, but they are not
where the first hours go.

**Road is a special case.** At 0.5% of area it looks negligible, but roads are
not scattered — they are 1-tile-wide meandering paths carved from the start
position through the mountain passes to the portal. It is the line the player's
eye follows across the whole map and the route they actually walk. Draw it
early despite the number. It is also the terrain that will most want the
directional/connecting art in section 8, precisely because it is a thin line
always bordered by something else.

### Pretaloka — Hungry Ghost

Plains 47%, Forest 15%, Road 12%, Hills 9%, Mountains 9% — five tiles for 92%.
Note Road is 12% here, not 0.5%: this realm's configs weight it heavily.

### Tiryakloka — Animal

Plains 28%, Mountains 28%, Road 25%, Swamp 6%, Forest 4.5%.

> **The Animal realm's data is wrong, now with numbers.** A realm of ocean
> depths, ancient forest and open meadow comes out 28% mountains and 25% road,
> with water at 1% and forest at 4.5%. Its "ocean depths" zone is weighted 30%
> mountains and 10% water; its "ancient forest" zone is 38% road and 7% forest.
> This is a generation-data bug, not an art problem — don't design tiles around
> those numbers, and don't prioritise the Animal realm until it's fixed. Say
> the word and I'll fix the weights.

## 8. Deliberately out of scope (and what it would cost later)

**Directional roads, rivers and bridges.** Planned, not now. When we do them,
they need a different axis from the variant columns: a tile chosen by which of
its neighbours are the same terrain (a 4-bit or 8-bit connection index), which
is its own sheet with a fixed cell order rather than more variants. The columns
in the current layout cannot carry it, so it will be an added sheet, not a
redesign — nothing drawn now is wasted. Road is the one that will want it most,
being a 1-tile-wide line always bordered by something else.

**Terrain transitions.** Right now grass meets water on a hard square edge.
The cheap fix, if it bothers us once real art is in, is a second small sheet of
**edge overlay tiles** — semi-transparent fringes (one per side + four corners,
so 8 or 12 cells) drawn *on top of* the base tile, tinted per neighbouring
terrain in code. That's far less work than true autotiling (which needs 16–47
tiles per terrain) and covers 90% of the visual gain. Not now.

**Animation.** Water, lava and portals would all benefit from a 2–4 frame
cycle. Structurally that's just more columns on the sheet plus a timer in the
renderer. Worth doing, after the static set exists.

**Per-realm variants.** ~~A per-realm colour grade over one neutral set.~~
Superseded by the backdrop in section 5a, which achieves the same thing more
directly and without dulling the art. One tile set serves every realm.

**Phase 2 — object and creature icons.** Once terrain is done, the next set is
the markers currently drawn as coloured shapes. The icon vocabulary is already
fixed by the event data: `npc` (79 uses), `shrine` (216), `enemy` (55),
`shop` (48), `treasure` (46), `event` (35), `dungeon` (33), `rest` (32),
`enemy_elite` (15), `merchant` (8), `enemy_fast` (5), `boss` (3). Plus the
party marker and the portal. Those are ~14 icons at the same cell size, and
they *do* want transparency. Separate brief when we get there.

**Phase 3 — battle grid.** The tactical grid uses the same 48px square and the
same terrain vocabulary (a battlefield is defined as "a zoom into a 9×6 block
of overworld ground"), so the terrain sheet largely transfers. What it adds is
scatter objects: `tree`, `fallen_tree`, `rock`, `pillar`, `barricade`, and
floor/water/difficult/wall/pit variants. Also later.

---

## 9. Delivering the files

All of this is generated — run `python3 tools/tile_atlas.py init` if anything
is missing, and see `assets/tiles/README.md`.

| File | What it is |
|---|---|
| `assets/tiles/terrain_atlas_guide.png` | Labelled reference sheet: row → terrain, speed, filename, and what the tile must communicate |
| `assets/tiles/terrain/` | 56 correctly sized, correctly named blanks — one per cell. **Paint here** |
| `assets/tiles/terrain_atlas_template.png` | The same grid as one 96×336 sheet, for painting into directly |
| `assets/tiles/terrain_atlas_grid.png` | Transparent 1px grid overlay for a top layer while painting the template |
| `assets/tiles/terrain_atlas.png` | The assembled atlas. Generated; don't hand-edit |

The per-file route is the one to use: each blank is already the right size and
already named for its slot, so there is no grid to align and no way to land a
tile in the wrong row. `tools/tile_atlas.py pack` assembles them and reports
what is still empty; `check` verifies an atlas you painted as one sheet;
`split` converts between the two. It is pure standard library — nothing to
install, on any machine.

Variant `a` of each terrain ships pre-filled with the flat placeholder colour
the game paints today, so a half-finished set still packs into a working
atlas. Variants `b`–`d` start empty, because empty is exactly how the renderer
is told to fall back to `a`.

Once real tiles land I will: set nearest-neighbour filtering and an integer
camera zoom, replace the `draw_rect` terrain pass in `map_renderer.gd` with
atlas blits, add deterministic per-square variant selection, delete the
placeholder ✕/dots/centre-line overlays, and run `tools/verify_all.sh`.

## 10. Open decisions — your call

1. ~~**Cell size**~~ — settled at 24×24; the templates are generated.
2. ~~**Delivery shape**~~ — both work; `tools/tile_atlas.py` converts between
   per-tile files and a single atlas in either direction.
3. **Variants:** how many columns will you actually draw? 1 works, 4 is the
   sweet spot, more than 4 is diminishing returns given terrain clumps are only
   2–7 squares. Say the word and I'll change `VARIANTS` and regenerate.
4. **Per-realm look:** one neutral set + code colour grade (recommended), or do
   you want to hand-paint per-realm variants eventually?
5. **Grid lines:** the map currently draws a faint black line around every
   square. Keep it once art is in, or drop it? Recommend dropping — good tile
   art makes it redundant and it fights the pixel grid.
