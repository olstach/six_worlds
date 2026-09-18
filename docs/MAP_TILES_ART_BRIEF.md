# Six Worlds — Map Tile Art Brief

*Everything needed to draw the first set of overworld map tiles. No tileset
experience assumed — this explains what a tileset is, how this game wants one
arranged, and exactly which tiles to draw in which order. Companion to
`docs/SIX_WORLDS_COMPOSER_BRIEF.md`.*

---

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

**Recommended: draw at 24×24 pixels per cell, displayed at 2×.**

The game's grid is 48 world-pixels per square, in both the overworld and the
tactical battle grid (they deliberately match). A 24×24 drawing scaled up 2× is
exactly 48 — a clean doubling, where every drawn pixel becomes a crisp 2×2
block. This gives a classic chunky pixel-art read, is about a quarter of the
drawing labour of native 48×48, and stays flexible: upscaling further later is
free, whereas shrinking art you've already drawn is destructive.

| Option | You draw | On-screen scale | Verdict |
|---|---|---|---|
| **24×24** | 576 px per tile | 2× | **Recommended.** Classic, crisp, fastest to iterate |
| 16×16 | 256 px per tile | 3× | Fastest of all; may read too coarse against the ornate UI |
| 48×48 | 2304 px per tile | 1× | Most detail, ~4× the work, and harder to keep tiles reading cleanly at a glance |

Whichever you pick, tell me and I'll set the scale factor — it's one constant.
Just don't mix sizes within a sheet.

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

## 5. The golden rule

> **Every tile must look correct with any other tile on any of its four sides,
> and must fill its cell edge to edge.**

This is what lets us skip autotiling entirely. In practice:

- **No transparency inside a drawn cell.** Nothing shows through from behind;
  there is no background layer.
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
  them. Tiles should still be *identifiable* when that dark — which means
  distinguishing terrains by texture and shape, not by hue alone.
- **Markers sit on the centre.** The party circle, creature circles and object
  markers occupy roughly the middle 50–70% of a square and have their name
  labels drawn just below. A tile with a single dominant feature dead-centre
  will be permanently hidden under a marker. Prefer detail distributed around
  the cell, or off-centre.

---

## 7. Draw them in this order

Terrain frequency, averaged over every zone in all three built realms:

| Priority | Terrain | Share of map | Why |
|---|---|---|---|
| **Tier 1** | Plains, Road, Hills, Forest | ~59% combined | Over half of every screen. Ship these four and the map already looks like a game |
| **Tier 2** | Mountains, Water, Ice, Swamp | ~23% | Mountains and Water are also the two hard walls, so they carry the most gameplay weight per tile |
| **Tier 3** | Snow, Ruins, Lava, Desert, Sand, Bridge | ~18% | Regionally concentrated — Snow/Ice for cold Hell, Lava/Desert/Sand for fire Hell, Ruins for the Hungry Ghost graveyards |

A completely reasonable first delivery is **Tier 1, one variant each — four
tiles.** I can wire those up, leave the other ten as flat colours, and you'll
see your art in the running game the same day. That's a much better loop than
drawing 56 tiles blind.

### Where each terrain shows up — worth knowing before you draw

| Realm | Zone | Dominant terrain |
|---|---|---|
| **Naraka (Hell)** | Cold hell, north | Plains 30%, **Snow 25%**, Water/Ice/Forest/Hills |
| | Mountain wall divider | Solid Mountains |
| | Fire hell, south | Plains 25%, **Desert 20%, Lava 15%**, Sand, Ruins |
| **Pretaloka (Hungry Ghost)** | Fetid swamps | Forest 25%, Plains, **Hills 20%**, Water, Swamp |
| | Charnel grounds | Plains 25%, Road 18%, Lava, **Ruins** |
| | Dry graveyards | **Plains 35%, Road 20%**, Mountains, Hills, Ruins |
| **Tiryakloka (Animal)** | Ancient forest | Road 38%, Plains 20%, Hills, Forest |
| | Open meadow | Plains 38%, Forest, Road, Hills |
| | Ocean depths | Mountains 30%, Swamp, Forest, Water |

> **Flagging a data oddity, not an art problem:** the Animal realm's weights
> look wrong — its "ocean depths" zone is 30% mountains and only 10% water, and
> its "ancient forest" zone is 38% road and 7% forest. That's a generation-data
> bug to fix separately; don't design tiles around those numbers. Assume ocean
> means water and forest means forest.

---

## 8. Deliberately out of scope (and what it would cost later)

**Terrain transitions.** Right now grass meets water on a hard square edge.
The cheap fix, if it bothers us once real art is in, is a second small sheet of
**edge overlay tiles** — semi-transparent fringes (one per side + four corners,
so 8 or 12 cells) drawn *on top of* the base tile, tinted per neighbouring
terrain in code. That's far less work than true autotiling (which needs 16–47
tiles per terrain) and covers 90% of the visual gain. Not now.

**Animation.** Water, lava and portals would all benefit from a 2–4 frame
cycle. Structurally that's just more columns on the sheet plus a timer in the
renderer. Worth doing, after the static set exists.

**Per-realm variants.** Hell's plains and the Animal realm's meadow currently
draw from the same tile. Rather than you drawing 14 tiles × 3 realms, my
recommendation is **one neutral set from you, plus a per-realm colour grade in
code** — a warm ash tint for fire Hell, a blue-grey for cold Hell, a sickly
green for the Hungry Ghost realm, saturated naturalism for the Animal realm.
Cheap, consistent, and reversible. Draw the set neutral and mid-saturation so
it takes a grade well.

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

- Put them in **`assets/tiles/`** (create it — the repo currently has no art
  assets at all beyond the app icon).
- Name the terrain sheet **`terrain_atlas.png`**.
- Keep your layered working files out of the repo, or in `assets/tiles/src/` if
  you want them versioned — either is fine, just don't let a 200MB layered file
  into git.
- If you'd rather hand over **one PNG per tile** while experimenting, that's
  genuinely easier to iterate on — name them `plains_0.png`, `plains_1.png`,
  `road_0.png` … and I'll assemble the atlas with a script. Say the word and
  I'll write that packer so you never have to align a grid by hand.

Once the files land I will: set nearest-neighbour filtering and an integer
camera zoom, replace the `draw_rect` terrain pass in `map_renderer.gd` with
atlas blits, add deterministic per-square variant selection, delete the
placeholder ✕/dots/centre-line overlays, and run `tools/verify_all.sh`.

---

## 10. Open decisions — your call

1. **Cell size:** 24×24 (recommended), 16×16, or 48×48?
2. **Variants:** how many columns are you willing to draw? 1 works, 4 is the
   sweet spot, more than 4 is diminishing returns given terrain clumps are only
   2–7 squares.
3. **Delivery shape:** single atlas PNG, or one PNG per tile plus a packer
   script from me?
4. **Per-realm look:** one neutral set + code colour grade (recommended), or do
   you want to hand-paint per-realm variants eventually?
5. **Grid lines:** the map currently draws a faint black line around every
   square. Keep it once art is in, or drop it? Recommend dropping — good tile
   art makes it redundant and it fights the pixel grid.
