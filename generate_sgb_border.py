#!/usr/bin/env python3
"""
Generate SGB border data for mGBA from a PNG.

Input:
  - 256x224 PNG named 'sgb-border.png'

Output:
  - sgb_border.c with:
      _defaultBorderPalette[16]
      _defaultBorderChardata[0x2000]
      _defaultBorderTilemap[...]

This version correctly uses ONE SGB border palette (palette 4, colors 0–3).
"""

import sys
from pathlib import Path
from PIL import Image

SGB_SIZE_CHAR_RAM = 0x2000
SGB_SIZE_MAP_RAM = 0x1000


def to_rgb555(r, g, b):
    return (r >> 3) | ((g >> 3) << 5) | ((b >> 3) << 10)


def load_image(path: Path):
    img = Image.open(path).convert("RGBA")
    if img.size != (256, 224):
        img = img.resize((256, 224), Image.NEAREST)

    # FORCE EXACTLY 4 COLOURS (SGB palette)
    pal = img.convert("P", palette=Image.ADAPTIVE, colors=4)

    palette = pal.getpalette()
    data = list(pal.getdata())

    colors = []
    for i in range(4):
        colors.append((
            palette[i * 3 + 0],
            palette[i * 3 + 1],
            palette[i * 3 + 2],
        ))

    w, h = pal.size
    pix = [[data[y * w + x] for x in range(w)] for y in range(h)]

    return colors, pix


def build_tiles(pix):
    tiles = []
    tile_map = {}
    ids = [[0] * 32 for _ in range(28)]

    for ty in range(28):
        for tx in range(32):
            block = tuple(
                pix[ty * 8 + y][tx * 8 + x]
                for y in range(8)
                for x in range(8)
            )

            if block not in tile_map:
                if len(tiles) >= 256:
                    sys.exit("Too many unique tiles (>256)")
                tile_map[block] = len(tiles)
                tiles.append(block)

            ids[ty][tx] = tile_map[block]

    return tiles, ids


def build_char_ram(tiles):
    ram = bytearray(SGB_SIZE_CHAR_RAM)

    for i, tile in enumerate(tiles):
        base = i * 32
        for y in range(8):
            p0 = p1 = 0
            for x in range(8):
                c = tile[y * 8 + x] & 3
                bit = 7 - x
                if c & 1:
                    p0 |= 1 << bit
                if c & 2:
                    p1 |= 1 << bit
            ram[base + y * 2 + 0] = p0
            ram[base + y * 2 + 1] = p1

    return ram


def build_map_ram(tile_ids):
    ram = bytearray(SGB_SIZE_MAP_RAM)
    palette_index = 4  # ONE border palette

    for ty in range(28):
        for tx in range(32):
            tile = tile_ids[ty][tx]
            attr = tile | (palette_index << 10)
            off = 2 * tx + 64 * ty
            ram[off] = attr & 0xFF
            ram[off + 1] = (attr >> 8) & 0xFF

    return ram


def write_c(path, colors, char_ram, map_ram):
    with open(path, "w") as f:
        f.write("/* Auto-generated SGB border */\n\n")

        f.write("static const uint16_t _defaultBorderPalette[16] = {\n")
        for i in range(16):
            if i < 4:
                f.write(f"    0x{to_rgb555(*colors[i]):04X},\n")
            else:
                f.write("    0x0000,\n")
        f.write("};\n\n")

        f.write(f"static const uint8_t _defaultBorderChardata[{len(char_ram)}] = {{\n")
        for i, b in enumerate(char_ram):
            f.write(f"0x{b:02X},")
            if i % 16 == 15:
                f.write("\n")
        f.write("\n};\n\n")

        used = max(i for i, b in enumerate(map_ram) if b != 0) + 1
        f.write(f"static const uint8_t _defaultBorderTilemap[{used}] = {{\n")
        for i in range(used):
            f.write(f"0x{map_ram[i]:02X},")
            if i % 16 == 15:
                f.write("\n")
        f.write("\n};\n")


def main():
    root = Path(__file__).parent
    png = root / "sgb-border.png"
    if not png.exists():
        sys.exit("Missing sgb-border.png")

    colors, pix = load_image(png)
    tiles, ids = build_tiles(pix)
    char_ram = build_char_ram(tiles)
    map_ram = build_map_ram(ids)

    write_c(root / "sgb_border.c", colors, char_ram, map_ram)
    print("OK: sgb_border.c generated")


if __name__ == "__main__":
    main()