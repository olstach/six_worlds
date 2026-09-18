#!/usr/bin/env python3
"""Build and check the overworld terrain tile atlas.

The atlas is one PNG laid out as a strict grid: row = terrain ID (the
MapManager.Terrain enum order, which saved maps store), column = variant of
that terrain. See docs/MAP_TILES_ART_BRIEF.md for the full spec.

Two ways to draw:

  A. One file per tile (recommended while learning). `init` writes a named,
     correctly sized blank for every cell into assets/tiles/terrain/; paint
     them, then `pack` assembles the atlas. You never align a grid by hand.

  B. One atlas file. `init` also writes the template and a grid overlay; paint
     directly into the template, then `check` verifies it.

Commands:
  init     write the per-tile blanks, the atlas template, the grid overlay
           and the labelled guide sheet
  pack     assets/tiles/terrain/*.png  ->  assets/tiles/terrain_atlas.png
  split    assets/tiles/terrain_atlas.png  ->  assets/tiles/terrain/*.png
  check    report cell size, grid alignment and which cells are drawn

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

TILE_DIR = os.path.join(ROOT, "assets", "tiles", "terrain")
ATLAS = os.path.join(ROOT, "assets", "tiles", "terrain_atlas.png")
TEMPLATE = os.path.join(ROOT, "assets", "tiles", "terrain_atlas_template.png")
GRID = os.path.join(ROOT, "assets", "tiles", "terrain_atlas_grid.png")
GUIDE = os.path.join(ROOT, "assets", "tiles", "terrain_atlas_guide.png")

RENDERER = os.path.join(ROOT, "scripts", "overworld", "map_renderer.gd")
TERRAIN_JSON = os.path.join(ROOT, "resources", "data", "terrain.json")


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

    # One file per tile. Variant `a` starts as the flat placeholder colour, so
    # a half-finished set still packs into a working atlas; variants b-d start
    # empty, because an empty cell is how the renderer is told to fall back to
    # variant `a`.
    os.makedirs(TILE_DIR, exist_ok=True)
    for terrain in terrains:
        for v in range(VARIANTS):
            path = os.path.join(TILE_DIR, tile_filename(terrain, v))
            if os.path.exists(path) and not args.force:
                continue
            cell = Canvas(CELL, CELL)
            if v == 0:
                cell.rect(0, 0, CELL, CELL, terrain["color"] + (255,))
            cell.save(path)
            made.append(os.path.relpath(path, ROOT))

    # The same thing as one sheet, for drawing straight into.
    atlas = Canvas(VARIANTS * CELL, len(terrains) * CELL)
    for terrain in terrains:
        atlas.rect(0, terrain["id"] * CELL, CELL, CELL, terrain["color"] + (255,))
    atlas.save(TEMPLATE)
    made.append(os.path.relpath(TEMPLATE, ROOT))

    # A transparent 1px overlay to park on a top layer while drawing. It is not
    # part of the atlas — the atlas itself has no gaps or separator lines.
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

    for path in made:
        print("wrote", path)
    print("\n%d tiles to fill in: %d terrains x %d variants."
          % (len(terrains) * VARIANTS, len(terrains), VARIANTS))
    print("Only the %d `_a` files are required; `_b`/`_c`/`_d` are optional "
          "variants." % len(terrains))
    print("When you have painted some, run:  python3 tools/tile_atlas.py pack")


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
    if not os.path.isdir(TILE_DIR):
        sys.exit("no %s — run `init` first" % os.path.relpath(TILE_DIR, ROOT))

    atlas = Canvas(VARIANTS * CELL, len(terrains) * CELL)
    drawn = empty = 0
    problems = []
    for terrain in terrains:
        for v in range(VARIANTS):
            path = os.path.join(TILE_DIR, tile_filename(terrain, v))
            if not os.path.exists(path):
                empty += 1
                continue
            cell = read_png(path)
            if (cell.w, cell.h) != (CELL, CELL):
                problems.append("%s is %dx%d, expected %dx%d"
                                % (tile_filename(terrain, v), cell.w, cell.h, CELL, CELL))
                continue
            atlas.blit(cell, v * CELL, terrain["id"] * CELL)
            if _is_blank(cell):
                empty += 1
            else:
                drawn += 1

    if problems:
        for p in problems:
            print("ERROR:", p)
        sys.exit(1)

    atlas.save(ATLAS)
    print("wrote %s  (%dx%d)" % (os.path.relpath(ATLAS, ROOT), atlas.w, atlas.h))
    print("%d cells drawn, %d still empty" % (drawn, empty))
    _report_missing_required(atlas, terrains)


def cmd_split(args):
    terrains = load_terrains()
    src = args.atlas or ATLAS
    atlas = read_png(src)
    _assert_atlas_shape(atlas, terrains, src)
    os.makedirs(TILE_DIR, exist_ok=True)
    for terrain in terrains:
        for v in range(VARIANTS):
            cell = Canvas(CELL, CELL)
            for y in range(CELL):
                for x in range(CELL):
                    cell.set(x, y, atlas.get(v * CELL + x, terrain["id"] * CELL + y))
            cell.save(os.path.join(TILE_DIR, tile_filename(terrain, v)))
    print("wrote %d files into %s"
          % (len(terrains) * VARIANTS, os.path.relpath(TILE_DIR, ROOT)))


def cmd_check(args):
    terrains = load_terrains()
    src = args.atlas or (ATLAS if os.path.exists(ATLAS) else TEMPLATE)
    atlas = read_png(src)
    print("checking %s  (%dx%d)" % (os.path.relpath(src, ROOT), atlas.w, atlas.h))
    _assert_atlas_shape(atlas, terrains, src)
    print("size ok: %d columns x %d rows of %dx%d cells"
          % (VARIANTS, len(terrains), CELL, CELL))

    bad = []
    for terrain in terrains:
        marks = []
        for v in range(VARIANTS):
            cell = Canvas(CELL, CELL)
            for y in range(CELL):
                for x in range(CELL):
                    cell.set(x, y, atlas.get(v * CELL + x, terrain["id"] * CELL + y))
            if _is_blank(cell):
                marks.append(".")
            else:
                marks.append("#")
                holes = _transparent_pixels(cell)
                if holes:
                    bad.append("%s row %d col %d has %d transparent pixels — a "
                               "drawn tile must be fully opaque"
                               % (terrain["name"], terrain["id"], v, holes))
        print("  %02d %-10s %s" % (terrain["id"], terrain["name"], " ".join(marks)))

    for b in bad:
        print("WARN:", b)
    _report_missing_required(atlas, terrains)


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


def _transparent_pixels(cell):
    return sum(1 for i in range(3, len(cell.px), 4) if cell.px[i] < 255)


def _report_missing_required(atlas, terrains):
    missing = []
    for terrain in terrains:
        cell = Canvas(CELL, CELL)
        for y in range(CELL):
            for x in range(CELL):
                cell.set(x, y, atlas.get(x, terrain["id"] * CELL + y))
        if _is_blank(cell):
            missing.append(terrain["name"])
    if missing:
        print("column 0 still empty for: %s" % ", ".join(missing))
    else:
        print("every terrain has its required column 0 tile")


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
    p.add_argument("--force", action="store_true",
                   help="overwrite per-tile files that already exist")
    p.set_defaults(func=cmd_init)

    p = sub.add_parser("pack", help="assemble the per-tile files into the atlas")
    p.set_defaults(func=cmd_pack)

    p = sub.add_parser("split", help="cut an atlas back into per-tile files")
    p.add_argument("--atlas", help="atlas to read (default assets/tiles/terrain_atlas.png)")
    p.set_defaults(func=cmd_split)

    p = sub.add_parser("check", help="verify size and report which cells are drawn")
    p.add_argument("--atlas", help="atlas to read")
    p.set_defaults(func=cmd_check)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
