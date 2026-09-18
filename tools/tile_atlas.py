#!/usr/bin/env python3
"""Build and check the overworld terrain tile atlas.

The atlas is one PNG laid out as a strict grid: row = terrain ID (the
MapManager.Terrain enum order, which saved maps store), column = variant of
that terrain. See docs/MAP_TILES_ART_BRIEF.md for the full spec.

Two ways to draw:

  A. One file per tile (recommended while learning). `init` writes a named,
     correctly sized blank for every cell into assets/tiles/terrain/<palette>/;
     paint them, then `pack` assembles that palette's atlas. You never align a
     grid by hand.

  B. One atlas file. `init` also writes the template and a grid overlay; paint
     directly into the template, then `check` verifies it.

A palette is one full set of tiles, keyed by region id exactly as
MapManager.get_region_at() returns it — so cold_hell and fire_hell can draw the
same terrain differently. A palette carries only the tiles that differ;
everything else falls through to `base`, and then to the flat placeholder.

Commands:
  init     write the per-tile blanks, the atlas template, the grid overlay
           and the labelled guide sheet
  pack     terrain/<palette>/*.png  ->  terrain_atlas_<palette>.png
  split    terrain_atlas_<palette>.png  ->  terrain/<palette>/*.png
  check    report cell size, grid alignment and coverage per cell
  preview  composite the tiles over the realm backdrop

Pure standard library: it reads and writes PNG itself, so there is nothing to
install. Run from anywhere:  python3 tools/tile_atlas.py init
"""
import argparse
import json
import os
import re
import struct
import sys
import zlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# The one place the layout is decided. Cell size is what the artist draws at;
# the game's grid is 48 world-pixels, so 24 is displayed at a clean 2x.
CELL = 24
VARIANTS = 4          # columns; column 0 is required, 1-3 optional
VARIANT_LETTERS = "abcd"

PALETTE_ROOT = os.path.join(ROOT, "assets", "tiles", "terrain")
BASE_PALETTE = "base"
TEMPLATE = os.path.join(ROOT, "assets", "tiles", "terrain_atlas_template.png")
GRID = os.path.join(ROOT, "assets", "tiles", "terrain_atlas_grid.png")
GUIDE = os.path.join(ROOT, "assets", "tiles", "terrain_atlas_guide.png")

PREVIEW_DIR = os.path.join(ROOT, "assets", "tiles", "preview")

RENDERER = os.path.join(ROOT, "scripts", "overworld", "map_renderer.gd")
TERRAIN_JSON = os.path.join(ROOT, "resources", "data", "terrain.json")
MAP_CONFIGS = os.path.join(ROOT, "resources", "data", "map_configs")

# One backdrop per realm, not per zone: the realm is the thing the player is
# inside of, and holding one colour across it is what makes the realm feel like
# a single place. Hell is black, later with waves and ripples moving through it.
# Zones differ in their *tiles* instead — see PALETTES below.
REALM_BACKDROPS = {
    "hell":         ["#000000", "#05050A", "#0B0710", "#0A0A0F"],
    "hungry_ghost": ["#0E1512", "#16211A", "#150E18", "#181410"],
    "animal":       ["#07120C", "#0A120C", "#04101C", "#0F1C14"],
}
FALLBACK_BACKDROPS = ["#000000", "#0E1512", "#07120C", "#101A2B"]


# ── Terrain vocabulary ───────────────────────────────────────────────────────
# Read, never duplicated: ids/names/speeds from terrain.json (the shared
# terrain vocabulary), placeholder colours from the renderer's TERRAIN_COLORS.
# Those colours are what the map paints today and are the value anchor the art
# replaces, so a second copy of them here would drift the moment either moved.

def load_terrains():
    with open(TERRAIN_JSON, encoding="utf-8") as fh:
        data = json.load(fh)["terrain"]
    colors = load_placeholder_colors()
    out = []
    for key, entry in data.items():
        tid = entry["id"]
        if tid not in colors:
            sys.exit("terrain id %d (%s) has no colour in %s" % (tid, key, RENDERER))
        out.append({
            "id": tid,
            "key": key,
            "name": entry["name"],
            "speed": entry["speed"],
            "color": colors[tid],
        })
    out.sort(key=lambda t: t["id"])
    expected = list(range(len(out)))
    if [t["id"] for t in out] != expected:
        sys.exit("terrain ids are not a dense 0..N range — the atlas rows would "
                 "not line up with the enum")
    return out


def load_placeholder_colors():
    """Pull TERRAIN_COLORS out of map_renderer.gd."""
    with open(RENDERER, encoding="utf-8") as fh:
        src = fh.read()
    block = re.search(r"const TERRAIN_COLORS[^{]*\{(.*?)\n\}", src, re.S)
    if not block:
        sys.exit("could not find TERRAIN_COLORS in %s — if it was renamed or "
                 "removed, update this script" % RENDERER)
    colors = {}
    for tid, r, g, b in re.findall(
            r"(\d+)\s*:\s*Color\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)", block.group(1)):
        colors[int(tid)] = tuple(round(float(c) * 255) for c in (r, g, b))
    if not colors:
        sys.exit("TERRAIN_COLORS in %s parsed to nothing" % RENDERER)
    return colors


# ── Palettes ─────────────────────────────────────────────────────────────────
# A palette is one full set of tiles. The key is a region id, exactly as
# MapManager.get_region_at() returns it ("cold_hell", "fire_hell", ...), so the
# renderer needs no mapping layer: it asks which region a square is in and draws
# from that palette, falling back to `base` and then to the flat placeholder.

def palette_dir(name):
    return os.path.join(PALETTE_ROOT, name)


def atlas_path(name):
    return os.path.join(ROOT, "assets", "tiles", "terrain_atlas_%s.png" % name)


def known_palettes():
    """Every region id the shipped map configs can produce, plus base."""
    out = [BASE_PALETTE]
    if os.path.isdir(MAP_CONFIGS):
        for filename in sorted(os.listdir(MAP_CONFIGS)):
            if not filename.endswith(".json"):
                continue
            with open(os.path.join(MAP_CONFIGS, filename), encoding="utf-8") as fh:
                for zone in json.load(fh).get("zones", []):
                    # mountain_wall dividers have no terrain mix of their own;
                    # they fall back to base.
                    if zone.get("terrain_weights") and zone.get("id"):
                        out.append(zone["id"])
    return out


def existing_palettes():
    if not os.path.isdir(PALETTE_ROOT):
        return []
    found = sorted(d for d in os.listdir(PALETTE_ROOT)
                   if os.path.isdir(palette_dir(d)))
    # base first, it is what everything else falls back to
    return ([BASE_PALETTE] if BASE_PALETTE in found else []) + \
           [d for d in found if d != BASE_PALETTE]


# ── PNG out ──────────────────────────────────────────────────────────────────

def write_png(path, width, height, pixels):
    """pixels: flat bytearray of RGBA, width*height*4."""
    raw = bytearray()
    stride = width * 4
    for y in range(height):
        raw.append(0)                       # filter type 0 (None)
        raw += pixels[y * stride:(y + 1) * stride]

    def chunk(tag, payload):
        return (struct.pack(">I", len(payload)) + tag + payload
                + struct.pack(">I", zlib.crc32(tag + payload) & 0xFFFFFFFF))

    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(bytes(raw), 9))
    png += chunk(b"IEND", b"")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as fh:
        fh.write(png)


class Canvas:
    def __init__(self, w, h, fill=(0, 0, 0, 0)):
        self.w, self.h = w, h
        self.px = bytearray(bytes(fill) * (w * h))

    def set(self, x, y, rgba):
        if 0 <= x < self.w and 0 <= y < self.h:
            i = (y * self.w + x) * 4
            self.px[i:i + 4] = bytes(rgba)

    def get(self, x, y):
        i = (y * self.w + x) * 4
        return tuple(self.px[i:i + 4])

    def rect(self, x0, y0, w, h, rgba):
        for y in range(y0, y0 + h):
            for x in range(x0, x0 + w):
                self.set(x, y, rgba)

    def blit(self, src, x0, y0):
        for y in range(src.h):
            for x in range(src.w):
                self.set(x0 + x, y0 + y, src.get(x, y))

    def save(self, path):
        write_png(path, self.w, self.h, self.px)


# ── PNG in ───────────────────────────────────────────────────────────────────
# Handles what image editors actually export: 8-bit non-interlaced greyscale,
# RGB, palette and RGBA. Anything else gets a clear error rather than garbage.

def read_png(path):
    with open(path, "rb") as fh:
        data = fh.read()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        sys.exit("%s is not a PNG" % path)
    pos, idat, plte, trns, hdr = 8, bytearray(), None, None, None
    while pos < len(data):
        (length,) = struct.unpack(">I", data[pos:pos + 4])
        tag = data[pos + 4:pos + 8]
        payload = data[pos + 8:pos + 8 + length]
        if tag == b"IHDR":
            hdr = struct.unpack(">IIBBBBB", payload)
        elif tag == b"IDAT":
            idat += payload
        elif tag == b"PLTE":
            plte = payload
        elif tag == b"tRNS":
            trns = payload
        elif tag == b"IEND":
            break
        pos += 12 + length

    w, h, depth, ctype, _comp, _filt, interlace = hdr
    if depth != 8:
        sys.exit("%s is %d-bit; save it as 8 bits per channel" % (path, depth))
    if interlace:
        sys.exit("%s is interlaced; re-save it without interlacing" % path)
    channels = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}.get(ctype)
    if channels is None:
        sys.exit("%s has an unsupported colour type (%d)" % (path, ctype))

    raw = zlib.decompress(bytes(idat))
    stride = w * channels
    out, prev = bytearray(), bytearray(stride)
    p = 0
    for _ in range(h):
        ftype = raw[p]
        line = bytearray(raw[p + 1:p + 1 + stride])
        p += 1 + stride
        for i in range(stride):
            a = line[i - channels] if i >= channels else 0
            b = prev[i]
            c = prev[i - channels] if i >= channels else 0
            if ftype == 1:
                line[i] = (line[i] + a) & 0xFF
            elif ftype == 2:
                line[i] = (line[i] + b) & 0xFF
            elif ftype == 3:
                line[i] = (line[i] + ((a + b) >> 1)) & 0xFF
            elif ftype == 4:
                pa, pb, pc = abs(b - c), abs(a - c), abs(a + b - 2 * c)
                pred = a if (pa <= pb and pa <= pc) else (b if pb <= pc else c)
                line[i] = (line[i] + pred) & 0xFF
            elif ftype != 0:
                sys.exit("%s uses filter type %d" % (path, ftype))
        out += line
        prev = line

    canvas = Canvas(w, h)
    for y in range(h):
        for x in range(w):
            i = (y * stride) + x * channels
            if ctype == 0:
                v = out[i]; rgba = (v, v, v, 255)
            elif ctype == 4:
                v = out[i]; rgba = (v, v, v, out[i + 1])
            elif ctype == 2:
                rgba = (out[i], out[i + 1], out[i + 2], 255)
            elif ctype == 6:
                rgba = (out[i], out[i + 1], out[i + 2], out[i + 3])
            else:
                idx = out[i]
                rgba = (plte[idx * 3], plte[idx * 3 + 1], plte[idx * 3 + 2],
                        trns[idx] if trns and idx < len(trns) else 255)
            canvas.set(x, y, rgba)
    return canvas


# ── A 5x7 bitmap font, for the guide sheet's labels ──────────────────────────

FONT = {
    "A": ("01110", "10001", "10001", "11111", "10001", "10001", "10001"),
    "B": ("11110", "10001", "11110", "10001", "10001", "10001", "11110"),
    "C": ("01111", "10000", "10000", "10000", "10000", "10000", "01111"),
    "D": ("11110", "10001", "10001", "10001", "10001", "10001", "11110"),
    "E": ("11111", "10000", "11110", "10000", "10000", "10000", "11111"),
    "F": ("11111", "10000", "11110", "10000", "10000", "10000", "10000"),
    "G": ("01111", "10000", "10000", "10111", "10001", "10001", "01111"),
    "H": ("10001", "10001", "11111", "10001", "10001", "10001", "10001"),
    "I": ("11111", "00100", "00100", "00100", "00100", "00100", "11111"),
    "J": ("00111", "00010", "00010", "00010", "00010", "10010", "01100"),
    "K": ("10001", "10010", "11100", "10100", "10010", "10010", "10001"),
    "L": ("10000", "10000", "10000", "10000", "10000", "10000", "11111"),
    "M": ("10001", "11011", "10101", "10001", "10001", "10001", "10001"),
    "N": ("10001", "11001", "10101", "10011", "10001", "10001", "10001"),
    "O": ("01110", "10001", "10001", "10001", "10001", "10001", "01110"),
    "P": ("11110", "10001", "10001", "11110", "10000", "10000", "10000"),
    "Q": ("01110", "10001", "10001", "10001", "10101", "10010", "01101"),
    "R": ("11110", "10001", "10001", "11110", "10100", "10010", "10001"),
    "S": ("01111", "10000", "10000", "01110", "00001", "00001", "11110"),
    "T": ("11111", "00100", "00100", "00100", "00100", "00100", "00100"),
    "U": ("10001", "10001", "10001", "10001", "10001", "10001", "01110"),
    "V": ("10001", "10001", "10001", "10001", "10001", "01010", "00100"),
    "W": ("10001", "10001", "10001", "10101", "10101", "11011", "10001"),
    "X": ("10001", "10001", "01010", "00100", "01010", "10001", "10001"),
    "Y": ("10001", "10001", "01010", "00100", "00100", "00100", "00100"),
    "Z": ("11111", "00001", "00010", "00100", "01000", "10000", "11111"),
    "0": ("01110", "10001", "10011", "10101", "11001", "10001", "01110"),
    "1": ("00100", "01100", "00100", "00100", "00100", "00100", "01110"),
    "2": ("01110", "10001", "00001", "00110", "01000", "10000", "11111"),
    "3": ("11111", "00010", "00100", "00010", "00001", "10001", "01110"),
    "4": ("00010", "00110", "01010", "10010", "11111", "00010", "00010"),
    "5": ("11111", "10000", "11110", "00001", "00001", "10001", "01110"),
    "6": ("00110", "01000", "10000", "11110", "10001", "10001", "01110"),
    "7": ("11111", "00001", "00010", "00100", "01000", "01000", "01000"),
    "8": ("01110", "10001", "10001", "01110", "10001", "10001", "01110"),
    "9": ("01110", "10001", "10001", "01111", "00001", "00010", "01100"),
    ".": ("00000", "00000", "00000", "00000", "00000", "01100", "01100"),
    ",": ("00000", "00000", "00000", "00000", "01100", "01100", "01000"),
    "-": ("00000", "00000", "00000", "11111", "00000", "00000", "00000"),
    "/": ("00001", "00010", "00010", "00100", "01000", "01000", "10000"),
    ":": ("00000", "01100", "01100", "00000", "01100", "01100", "00000"),
    "(": ("00010", "00100", "01000", "01000", "01000", "00100", "00010"),
    ")": ("01000", "00100", "00010", "00010", "00010", "00100", "01000"),
    "x": ("00000", "00000", "10001", "01010", "00100", "01010", "10001"),
    "_": ("00000", "00000", "00000", "00000", "00000", "00000", "11111"),
    " ": ("00000",) * 7,
}


def text(canvas, x, y, string, rgba, scale=1):
    """Draw `string` with its top-left at (x, y). Returns the width used."""
    cx = x
    for ch in string:
        glyph = FONT.get(ch, FONT.get(ch.upper()))
        if glyph is None:
            glyph = FONT[" "]
        for row, bits in enumerate(glyph):
            for col, bit in enumerate(bits):
                if bit == "1":
                    canvas.rect(cx + col * scale, y + row * scale, scale, scale, rgba)
        cx += 6 * scale
    return cx - x


def text_width(string, scale=1):
    return len(string) * 6 * scale


# ── Commands ─────────────────────────────────────────────────────────────────

def tile_filename(terrain, variant):
    return "%02d_%s_%s.png" % (terrain["id"], terrain["key"], VARIANT_LETTERS[variant])


def cmd_init(args):
    terrains = load_terrains()
    made = []

    _migrate_flat_layout()

    palettes = args.palette or [BASE_PALETTE]
    if BASE_PALETTE not in palettes:
        palettes = [BASE_PALETTE] + palettes
    unknown = [p for p in palettes if p not in known_palettes()]
    if unknown:
        print("note: %s is not a region id in any map config. Region ids are: %s"
              % (", ".join(unknown), ", ".join(sorted(set(known_palettes())))))
        print("      A palette by that name will still be built, but nothing "
              "will select it at runtime.\n")

    for name in palettes:
        target = palette_dir(name)
        os.makedirs(target, exist_ok=True)
        for terrain in terrains:
            for v in range(VARIANTS):
                path = os.path.join(target, tile_filename(terrain, v))
                if os.path.exists(path) and not args.force:
                    continue
                cell = Canvas(CELL, CELL)
                # Only `base` gets the flat placeholder pre-fill. An override
                # palette starts fully empty, because a cell that is merely
                # flat colour would silently hide the base tile underneath it.
                if name == BASE_PALETTE and v == 0:
                    cell.rect(0, 0, CELL, CELL, terrain["color"] + (255,))
                cell.save(path)
                made.append(os.path.relpath(path, ROOT))

    # One sheet-shaped template and grid overlay, shared by every palette.
    atlas = Canvas(VARIANTS * CELL, len(terrains) * CELL)
    for terrain in terrains:
        atlas.rect(0, terrain["id"] * CELL, CELL, CELL, terrain["color"] + (255,))
    atlas.save(TEMPLATE)
    made.append(os.path.relpath(TEMPLATE, ROOT))

    grid = Canvas(VARIANTS * CELL, len(terrains) * CELL)
    for c in range(VARIANTS + 1):
        x = min(c * CELL, grid.w - 1)
        for y in range(grid.h):
            grid.set(x, y, (255, 0, 255, 140))
    for r in range(len(terrains) + 1):
        y = min(r * CELL, grid.h - 1)
        for x in range(grid.w):
            grid.set(x, y, (255, 0, 255, 140))
    grid.save(GRID)
    made.append(os.path.relpath(GRID, ROOT))

    _write_guide(terrains)
    made.append(os.path.relpath(GUIDE, ROOT))

    if args.verbose:
        for path in made:
            print("wrote", path)
    else:
        print("wrote %d files" % len(made))
    print("\npalettes: %s" % ", ".join(existing_palettes()))
    print("%d cells each: %d terrains x %d variants."
          % (len(terrains) * VARIANTS, len(terrains), VARIANTS))
    print("A palette other than `base` only needs the tiles that differ; leave")
    print("the rest empty and they fall through to base.")
    print("\nWhen you have painted some, run:  python3 tools/tile_atlas.py pack")


def _migrate_flat_layout():
    """Move a pre-palette assets/tiles/terrain/*.png into terrain/base/.

    The layout used to be one flat folder. Anything already painted there is
    base art by definition, so it moves rather than being left orphaned.
    """
    if not os.path.isdir(PALETTE_ROOT):
        return
    loose = [f for f in os.listdir(PALETTE_ROOT)
             if f.endswith(".png") and os.path.isfile(os.path.join(PALETTE_ROOT, f))]
    if not loose:
        return
    target = palette_dir(BASE_PALETTE)
    os.makedirs(target, exist_ok=True)
    moved = 0
    for filename in loose:
        src = os.path.join(PALETTE_ROOT, filename)
        dst = os.path.join(target, filename)
        if os.path.exists(dst):
            continue                      # already migrated; leave the newer one
        os.rename(src, dst)
        moved += 1
    if moved:
        print("moved %d tile(s) from terrain/ into terrain/%s/ — the layout now "
              "has one folder per palette\n" % (moved, BASE_PALETTE))


def _write_guide(terrains):
    """A labelled reference sheet — which row is which, and what it must say."""
    scale, pad, swatch = 2, 16, 64
    label_w = 300
    note_w = 430
    row_h = swatch + 12
    head = 60
    w = pad + label_w + VARIANTS * (swatch + 6) + note_w + pad
    h = head + len(terrains) * row_h + pad

    bg = (24, 22, 28, 255)
    ink = (232, 228, 220, 255)
    dim = (150, 145, 140, 255)
    warn = (232, 120, 100, 255)
    fast = (140, 210, 255, 255)

    g = Canvas(w, h, bg)
    text(g, pad, 12, "SIX WORLDS  TERRAIN ATLAS", ink, scale)
    text(g, pad, 34, "ROW = TERRAIN ID", dim, 1)
    text(g, pad, 46, "COLUMN = VARIANT, %dx%d PER CELL" % (CELL, CELL), dim, 1)

    cols_x = pad + label_w
    for v in range(VARIANTS):
        x = cols_x + v * (swatch + 6)
        text(g, x + 2, 30, VARIANT_LETTERS[v].upper(), ink, scale)
        text(g, x + 2, 48, "REQUIRED" if v == 0 else "OPTIONAL",
             ink if v == 0 else dim, 1)

    for terrain in terrains:
        y = head + terrain["id"] * row_h
        text(g, pad, y + 6, "%02d  %s" % (terrain["id"], terrain["name"].upper()),
             ink, scale)

        speed = terrain["speed"]
        if speed < 0:
            text(g, pad, y + 32, "IMPASSABLE", warn, 1)
        else:
            colour = fast if speed > 1.0 else (dim if speed < 1.0 else ink)
            text(g, pad, y + 32, "SPEED %.2f" % speed, colour, 1)
        text(g, pad, y + 46, tile_filename(terrain, 0), dim, 1)

        for v in range(VARIANTS):
            x = cols_x + v * (swatch + 6)
            if v == 0:
                g.rect(x, y, swatch, swatch, terrain["color"] + (255,))
            else:
                for sy in range(swatch):        # checker = "leave empty if unused"
                    for sx in range(swatch):
                        on = ((sx // 8) + (sy // 8)) % 2 == 0
                        g.set(x + sx, y + sy,
                              (44, 42, 48, 255) if on else (34, 32, 38, 255))
            for i in range(swatch):             # thin frame
                g.set(x + i, y, dim); g.set(x + i, y + swatch - 1, dim)
                g.set(x, y + i, dim); g.set(x + swatch - 1, y + i, dim)

        nx = cols_x + VARIANTS * (swatch + 6) + 12
        for i, line in enumerate(_guide_note(terrain)):
            text(g, nx, y + 8 + i * 18, line, dim, 2)

    g.save(GUIDE)


def _guide_note(terrain):
    """What this tile has to communicate, in the artist's words not the code's."""
    notes = {
        0:  ["THE DEFAULT GROUND. THE MOST", "COMMON TILE IN THE GAME"],
        1:  ["FASTEST GROUND. READS AS MADE,", "CLEARED. NO DIRECTION IN IT"],
        2:  ["DENSE WOODLAND FROM ABOVE.", "CLUTTERED, OBSTRUCTIVE"],
        3:  ["STEEP BUT PASSABLE. NOT A WALL"],
        4:  ["HARD WALL. SOLID AND DENSE.", "ALSO USED AS REALM DIVIDERS"],
        5:  ["HARD WALL. DEEP, NOT SHALLOW.", "MUST NOT LOOK WADEABLE"],
        6:  ["BOGGY MARSH. WET AND CLINGING"],
        7:  ["ARID CRACKED WASTELAND"],
        8:  ["DEEP SNOW. SOFT, MATTE, SLOW.", "MUST NOT LOOK LIKE ICE"],
        9:  ["HARD WALL. MOLTEN AND BRIGHT.", "OBVIOUSLY LETHAL"],
        10: ["BUILT CROSSING. FAST.", "WORKED TIMBER OR STONE"],
        11: ["FAST AND SLICK. GLASSY,", "CRACKED. NOT SNOW"],
        12: ["LOOSE DUNES. SOFTER THAN DESERT"],
        13: ["CRUMBLING WORKED STONE"],
    }
    return notes.get(terrain["id"], [])


def cmd_pack(args):
    terrains = load_terrains()
    _migrate_flat_layout()
    palettes = args.palette or existing_palettes()
    if not palettes:
        sys.exit("no palettes in %s — run `init` first"
                 % os.path.relpath(PALETTE_ROOT, ROOT))

    problems = []
    for name in palettes:
        source = palette_dir(name)
        if not os.path.isdir(source):
            problems.append("no palette folder %s" % os.path.relpath(source, ROOT))
            continue
        atlas = Canvas(VARIANTS * CELL, len(terrains) * CELL)
        drawn = 0
        for terrain in terrains:
            for v in range(VARIANTS):
                path = os.path.join(source, tile_filename(terrain, v))
                if not os.path.exists(path):
                    continue
                cell = read_png(path)
                if (cell.w, cell.h) != (CELL, CELL):
                    problems.append("%s/%s is %dx%d, expected %dx%d"
                                    % (name, tile_filename(terrain, v),
                                       cell.w, cell.h, CELL, CELL))
                    continue
                atlas.blit(cell, v * CELL, terrain["id"] * CELL)
                if not _is_blank(cell):
                    drawn += 1
        if problems:
            continue
        atlas.save(atlas_path(name))
        total = len(terrains) * VARIANTS
        print("%-16s %s  %d/%d cells drawn"
              % (name, os.path.relpath(atlas_path(name), ROOT), drawn, total))

    if problems:
        for problem in problems:
            print("ERROR:", problem)
        sys.exit(1)

    base = atlas_path(BASE_PALETTE)
    if os.path.exists(base):
        _report_missing_required(read_png(base), terrains, BASE_PALETTE)


def cmd_split(args):
    terrains = load_terrains()
    name = args.palette or BASE_PALETTE
    src = args.atlas or atlas_path(name)
    if not os.path.exists(src):
        sys.exit("no %s" % os.path.relpath(src, ROOT))
    atlas = read_png(src)
    _assert_atlas_shape(atlas, terrains, src)
    target = palette_dir(name)
    os.makedirs(target, exist_ok=True)
    for terrain in terrains:
        for v in range(VARIANTS):
            _cell_from(atlas, terrain["id"], v).save(
                os.path.join(target, tile_filename(terrain, v)))
    print("wrote %d files into %s"
          % (len(terrains) * VARIANTS, os.path.relpath(target, ROOT)))


def cmd_check(args):
    terrains = load_terrains()
    palettes = args.palette or existing_palettes() or [BASE_PALETTE]
    print("per cell: percent of the cell that is opaque enough to hide the backdrop")
    print("(a dash means nothing drawn there, so it falls through to base)\n")

    thin = []
    for name in palettes:
        src = args.atlas or atlas_path(name)
        if not os.path.exists(src):
            print("%s: no atlas yet (run `pack`)\n" % name)
            continue
        atlas = read_png(src)
        _assert_atlas_shape(atlas, terrains, src)
        print("%s  (%s)" % (name, os.path.relpath(src, ROOT)))
        for terrain in terrains:
            marks = []
            for v in range(VARIANTS):
                cell = _cell_from(atlas, terrain["id"], v)
                if _is_blank(cell):
                    marks.append("  - ")
                    continue
                cov = _coverage(cell)
                marks.append("%3d%%" % round(cov * 100))
                # The three hard walls have to read as walls. Everything else
                # is free to be as ghostly as it likes.
                if v == 0 and terrain["speed"] < 0 and cov < 0.60:
                    thin.append((name, terrain["name"], cov))
            print("  %02d %-10s %s" % (terrain["id"], terrain["name"], " ".join(marks)))
        if name == BASE_PALETTE:
            _report_missing_required(atlas, terrains, name)
        print()

    for name, terrain_name, cov in thin:
        print("note: %s/%s is impassable but its column 0 tile is only %d%% opaque."
              % (name, terrain_name, round(cov * 100)))
        print("      A player must never mistake it for walkable ground — worth")
        print("      previewing it against the realm backdrop before committing.")


def _cell_from(atlas, row, col):
    cell = Canvas(CELL, CELL)
    for y in range(CELL):
        for x in range(CELL):
            cell.set(x, y, atlas.get(col * CELL + x, row * CELL + y))
    return cell


def _coverage(cell):
    """Fraction of the cell that is fully opaque, counting partial alpha partly."""
    total = sum(cell.px[i] for i in range(3, len(cell.px), 4))
    return total / (255.0 * CELL * CELL)


def _assert_atlas_shape(atlas, terrains, src):
    want = (VARIANTS * CELL, len(terrains) * CELL)
    if (atlas.w, atlas.h) != want:
        sys.exit("%s is %dx%d but the layout wants %dx%d "
                 "(%d columns x %d rows of %dx%d). Check for a stray margin or "
                 "gap between cells."
                 % (os.path.relpath(src, ROOT), atlas.w, atlas.h, want[0], want[1],
                    VARIANTS, len(terrains), CELL, CELL))


def _is_blank(cell):
    return all(cell.px[i] == 0 for i in range(3, len(cell.px), 4))


def _report_missing_required(atlas, terrains, name):
    missing = []
    for terrain in terrains:
        if _is_blank(_cell_from(atlas, terrain["id"], 0)):
            missing.append(terrain["name"])
    if missing:
        print("  %s: column 0 still empty for %s" % (name, ", ".join(missing)))
    else:
        print("  %s: every terrain has its required column 0 tile" % name)


# ── Preview ──────────────────────────────────────────────────────────────────

def fake_map(zone, w, h, seed):
    """Reproduce what the generator actually produces for this zone.

    Weighted random fill, then three passes of majority-of-nine smoothing with
    a bias toward keeping the current cell — the same as `_generate_zone_terrain`
    and `_smooth_cell` in scripts/map_gen/map_generator.gd. A preview built on
    uniform noise would lie about how the tiles read, because the real map comes
    out in blobs, not static.
    """
    import random
    rng = random.Random(seed)
    table = []
    for tid, weight in zone["terrain_weights"].items():
        table.extend([int(tid)] * int(weight))
    grid = [rng.choice(table) for _ in range(w * h)]

    for _ in range(3):
        nxt = list(grid)
        for y in range(h):
            for x in range(w):
                counts = {}
                current = grid[y * w + x]
                counts[current] = 1                 # bias toward keeping current
                for dy in (-1, 0, 1):
                    for dx in (-1, 0, 1):
                        if dx == 0 and dy == 0:
                            continue
                        nx, ny = x + dx, y + dy
                        if 0 <= nx < w and 0 <= ny < h:
                            t = grid[ny * w + nx]
                            counts[t] = counts.get(t, 0) + 1
                best, best_count = current, 0
                for t, c in counts.items():         # ties go to the first seen
                    if c > best_count:
                        best, best_count = t, c
                nxt[y * w + x] = best
        grid = nxt
    return grid


def load_cells(terrains, palette):
    """Drawn variants per terrain, resolving palette -> base -> flat colour.

    The same fallback the renderer will use: a palette only carries the tiles
    that differ, everything else falls through.
    """
    cells, sources = {}, {}
    for terrain in terrains:
        for name in ([palette, BASE_PALETTE] if palette != BASE_PALETTE
                     else [BASE_PALETTE]):
            drawn = []
            for v in range(VARIANTS):
                path = os.path.join(palette_dir(name), tile_filename(terrain, v))
                if os.path.exists(path):
                    cell = read_png(path)
                    if (cell.w, cell.h) == (CELL, CELL) and not _is_blank(cell):
                        drawn.append(cell)
            if drawn:
                cells[terrain["id"]] = drawn
                sources[terrain["id"]] = name
                break
        if terrain["id"] not in cells:
            flat = Canvas(CELL, CELL)
            flat.rect(0, 0, CELL, CELL, terrain["color"] + (255,))
            cells[terrain["id"]] = [flat]
            sources[terrain["id"]] = "placeholder"
    return cells, sources


def parse_hex(text_value):
    value = text_value.strip().lstrip("#")
    if len(value) != 6:
        sys.exit("backdrop %r should look like #1A2B3C" % text_value)
    try:
        return tuple(int(value[i:i + 2], 16) for i in (0, 2, 4))
    except ValueError:
        sys.exit("backdrop %r is not hex" % text_value)


def render_panel(grid, w, h, cells, backdrop, scale):
    """Composite the tiles over the backdrop — straight alpha, same as Godot."""
    panel = Canvas(w * CELL * scale, h * CELL * scale, backdrop + (255,))
    for ty in range(h):
        for tx in range(w):
            tid = grid[ty * w + tx]
            variants = cells[tid]
            # Deterministic per square, the way the renderer will pick: the same
            # square always draws the same variant, so nothing shimmers.
            cell = variants[(tx * 73856093 ^ ty * 19349663) % len(variants)]
            for y in range(CELL):
                for x in range(CELL):
                    r, g, b, a = cell.get(x, y)
                    if a == 0:
                        continue
                    if a < 255:
                        br, bg, bb = backdrop
                        r = (r * a + br * (255 - a)) // 255
                        g = (g * a + bg * (255 - a)) // 255
                        b = (b * a + bb * (255 - a)) // 255
                    px = (tx * CELL + x) * scale
                    py = (ty * CELL + y) * scale
                    panel.rect(px, py, scale, scale, (r, g, b, 255))
    return panel


def cmd_preview(args):
    terrains = load_terrains()

    if args.terrain:
        by_key = {t["key"]: t for t in terrains}
        if args.terrain not in by_key:
            sys.exit("no terrain %r. Have: %s"
                     % (args.terrain, ", ".join(sorted(by_key))))
        tid = by_key[args.terrain]["id"]
        w = h = 6
        panels = []
        # The repeat test: one terrain, nothing else, so a tile that visibly
        # repeats has nowhere to hide. Shown across the palettes that carry it.
        palettes = args.palette or existing_palettes() or [BASE_PALETTE]
        backdrop = parse_hex(args.backdrop or _realm_backdrops(args.realm)[0])
        for name in palettes:
            cells, _ = load_cells(terrains, name)
            panels.append((name, render_panel([tid] * (w * h), w, h, cells,
                                              backdrop, args.scale)))
        title = "%s  REPEAT TEST" % args.terrain.upper()
        stem = "repeat_" + args.terrain
        subtitle = args.backdrop or _realm_backdrops(args.realm)[0]
    else:
        zones = realm_zones(args.realm)
        if args.zone:
            zones = [z for z in zones if z.get("id") == args.zone]
            if not zones:
                sys.exit("no zone %r in %s. Have: %s"
                         % (args.zone, args.realm,
                            ", ".join(z.get("id", "?") for z in realm_zones(args.realm))))
        w, h = args.width, args.height
        # One backdrop for the whole realm — the realm is the thing the player
        # is inside of. The zones differ in their tiles, not behind them.
        backdrops = [args.backdrop] if args.backdrop else _realm_backdrops(args.realm)
        backdrop = parse_hex(backdrops[0])
        panels = []
        for zone in zones:
            cells, sources = load_cells(terrains, zone.get("id", BASE_PALETTE))
            grid = fake_map(zone, w, h, args.seed)
            label = zone.get("id", "?")
            used = {sources[t] for t in set(grid)}
            if used == {"placeholder"}:
                label += "  (no tiles yet)"
            elif "placeholder" in used:
                label += "  (partly placeholder)"
            panels.append((label, render_panel(grid, w, h, cells, backdrop,
                                               args.scale)))
        title = args.realm.upper()
        stem = args.realm if not args.zone else "%s_%s" % (args.realm, args.zone)
        subtitle = "backdrop %s" % backdrops[0].upper()

    pad, head, label_h = 12, 50, 22
    cols = 1 if len(panels) == 1 else 2
    rows = (len(panels) + cols - 1) // cols
    pw, ph = panels[0][1].w, panels[0][1].h
    sheet = Canvas(pad + cols * (pw + pad), head + rows * (ph + label_h + pad),
                   (14, 13, 16, 255))
    text(sheet, pad, 10, title, (232, 228, 220, 255), 2)
    text(sheet, pad, 30, subtitle, (150, 145, 140, 255), 1)

    for i, (name, panel) in enumerate(panels):
        x = pad + (i % cols) * (pw + pad)
        y = head + (i // cols) * (ph + label_h + pad)
        text(sheet, x, y + 4, name.upper(), (200, 196, 190, 255), 2)
        sheet.blit(panel, x, y + label_h)

    os.makedirs(PREVIEW_DIR, exist_ok=True)
    out = os.path.join(PREVIEW_DIR, stem + ".png")
    sheet.save(out)
    print("wrote %s  (%dx%d)" % (os.path.relpath(out, ROOT), sheet.w, sheet.h))


def _realm_backdrops(realm):
    return REALM_BACKDROPS.get(realm, FALLBACK_BACKDROPS)


def realm_zones(realm):
    """The zones of a realm that have a terrain mix of their own."""
    path = os.path.join(MAP_CONFIGS, realm + ".json")
    if not os.path.exists(path):
        have = sorted(f[:-5] for f in os.listdir(MAP_CONFIGS) if f.endswith(".json"))
        sys.exit("no map config for realm %r. Have: %s" % (realm, ", ".join(have)))
    with open(path, encoding="utf-8") as fh:
        return [z for z in json.load(fh)["zones"] if z.get("terrain_weights")]


def _is_flat(cell):
    first = cell.get(0, 0)
    return all(cell.get(x, y) == first for y in range(CELL) for x in range(CELL))


def main():
    # Let `... | head` close the pipe quietly rather than dumping a traceback.
    try:
        import signal
        signal.signal(signal.SIGPIPE, signal.SIG_DFL)
    except (ImportError, AttributeError, ValueError):
        pass

    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)

    p = sub.add_parser("init", help="write blanks, template, grid overlay, guide")
    p.add_argument("--palette", action="append", metavar="REGION",
                   help="palette to create, repeatable (default: base). Use a "
                        "region id such as cold_hell or fire_hell")
    p.add_argument("--force", action="store_true",
                   help="overwrite per-tile files that already exist")
    p.add_argument("--verbose", action="store_true", help="list every file written")
    p.set_defaults(func=cmd_init)

    p = sub.add_parser("pack", help="assemble each palette's tiles into its atlas")
    p.add_argument("--palette", action="append", metavar="REGION",
                   help="limit to these palettes (default: all that exist)")
    p.set_defaults(func=cmd_pack)

    p = sub.add_parser("split", help="cut an atlas back into per-tile files")
    p.add_argument("--palette", metavar="REGION", help="palette to write into")
    p.add_argument("--atlas", help="atlas to read (default: that palette's)")
    p.set_defaults(func=cmd_split)

    p = sub.add_parser("check", help="verify size and report coverage per cell")
    p.add_argument("--palette", action="append", metavar="REGION",
                   help="limit to these palettes (default: all that exist)")
    p.add_argument("--atlas", help="a specific atlas file to read instead")
    p.set_defaults(func=cmd_check)

    p = sub.add_parser("preview",
                       help="composite the tiles over the realm backdrop")
    p.add_argument("--realm", default="hell", help="hell, hungry_ghost, animal")
    p.add_argument("--zone", help="one zone only (default: all zones of the realm)")
    p.add_argument("--terrain", help="preview one terrain tiled 6x6 instead of a map")
    p.add_argument("--palette", action="append", metavar="REGION",
                   help="with --terrain, which palettes to show")
    p.add_argument("--backdrop", help="override the realm backdrop, e.g. \"#1A2B3C\"")
    p.add_argument("--width", type=int, default=20, help="map width in tiles")
    p.add_argument("--height", type=int, default=13, help="map height in tiles")
    p.add_argument("--scale", type=int, default=2, help="pixel scale (default 2)")
    p.add_argument("--seed", type=int, default=3, help="layout seed")
    p.set_defaults(func=cmd_preview)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
