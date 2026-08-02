#!/usr/bin/env python3
"""Moon 2D migration tool: convert every BMP under bin\\ to PNG.

Requires: pip install pillow scipy

TRANSPARENCY RULE
-----------------
The 2008 art keys on pure black, but the source BMPs are dirty in two
different ways, and telling them apart is the whole job here:

  * some files have a background painted in ONE near-black colour
    (12,12,11) instead of pure black - those render as black boxes in
    game (the provod\\lamp tiles were the worst);
  * sprite edges carry a thin fringe of almost-black pixels left by
    whatever tool resized the art two decades ago.

Both must go. But a third thing looks exactly like them to a naive
threshold and must STAY: dark art that touches the background - gravel's
legs are near-black, several pixels thick, and connected to the edge.
A plain "clear everything darker than N" eats them.

So a near-black region connected to the image border is cleared only if:

  thin      - it vanishes under a 3x3 erosion, i.e. it is at most two
              pixels thick: an antialiasing fringe, never a drawn shape;
  or flat   - one exact colour covers most of it AND that same colour
              sits on the image border: a background fill.

Measured on this asset set, the two cases do not overlap even slightly:
a background fill runs 71-100% single colour, while gravel's legs run
5-13% dominant colour across dozens of shades. Anything failing both
tests is treated as art and kept.

ALPHA folders  - textures\\, heroes\\, weapon\\, monsters\\, Stars\\:
                 served by caches with the color key on. Baked as above.
OPAQUE folders - levels\\ backgrounds (DisableColorKey) and the bin root
                 files whose transparency is applied at runtime by
                 verbatim 2008 code (menu thresholds, font atlas).
                 Converted as plain opaque RGB, never keyed.

PNGs are written next to the source BMPs. Sources are left untouched.

Usage:  python3 convert.py <path-to-bin> [--dry-run] [--report]
"""

import sys
from collections import Counter
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

ALPHA_DIRS = ("textures", "heroes", "weapon", "monsters", "Stars")

# A file whose background is a PAINTED near-black fill rather than pure
# black was never being keyed by the game in the first place - the 2008
# key is exact black, so that fill always rendered solid. Those are
# tiles meant to occlude: pustota ("void"), the lamps, the pipe runs.
# Keying them out now lets the layer behind bleed through - the glitch
# they exist to prevent. So a large fill means: save the file opaque.
FillIsTile = 0.25

# Max channel value still considered background-dark.
NearBlack = 16
# Share of one exact colour that marks a region as a painted fill.
FlatShare = 0.50
# How much of the border that colour must occupy to count as background.
BorderShare = 0.05


def is_alpha_class(bmp: Path, bin_dir: Path) -> bool:
    rel = bmp.relative_to(bin_dir)
    return len(rel.parts) > 1 and rel.parts[0] in ALPHA_DIRS


def border_colours(rgb):
    edge = np.concatenate([rgb[0, :], rgb[-1, :], rgb[:, 0], rgb[:, -1]])
    counts = Counter(map(tuple, edge))
    return {c: n / len(edge) for c, n in counts.items()}


def bake_alpha(img):
    """Return (RGBA or None, pure px, fringe px, fill px, kept-art px).

    None means the image turned out to be a painted tile, not a keyed
    sprite - the caller saves it opaque.
    """
    rgb = np.asarray(img.convert("RGB")).astype(int)
    brightest = rgb.max(axis=2)
    pure = brightest == 0
    candidate = brightest <= NearBlack

    labels, _ = ndimage.label(candidate)
    edge_labels = (set(labels[0, :]) | set(labels[-1, :])
                   | set(labels[:, 0]) | set(labels[:, -1]))
    edge_labels.discard(0)

    # The pure-black background and the fringe growing out of it form one
    # blob, so the near-black part has to be re-labelled on its own -
    # otherwise a single sprite's fringe and its dark legs land in the
    # same region and get one verdict for both.
    reachable = np.isin(labels, list(edge_labels)) & ~pure
    regions, region_count = ndimage.label(reachable)

    on_border = border_colours(rgb)
    clear = pure.copy()
    fringe = fill = kept = 0

    for index in range(1, region_count + 1):
        region = regions == index
        area = int(region.sum())
        if area == 0:
            continue

        if not ndimage.binary_erosion(region).any():
            clear |= region
            fringe += area
            continue

        colours = Counter(map(tuple, rgb[region]))
        dominant, hits = colours.most_common(1)[0]
        if (hits / area >= FlatShare
                and on_border.get(dominant, 0.0) >= BorderShare):
            clear |= region
            fill += area
        else:
            kept += area

    if fill >= FillIsTile * brightest.size:
        return None, 0, 0, fill, 0

    rgba = np.dstack([rgb.astype(np.uint8),
                      np.where(clear, 0, 255).astype(np.uint8)])
    return (Image.fromarray(rgba, "RGBA"),
            int(pure.sum()), fringe, fill, kept)


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    bin_dir = Path(sys.argv[1]).resolve()
    dry = "--dry-run" in sys.argv
    report = "--report" in sys.argv

    bmps = sorted(bin_dir.rglob("*.bmp")) + sorted(bin_dir.rglob("*.BMP"))
    alpha = opaque = 0
    totals = [0, 0, 0, 0]

    for bmp in bmps:
        img = Image.open(bmp)
        out = None
        if is_alpha_class(bmp, bin_dir):
            out, pure_px, fringe, fill, kept = bake_alpha(img)
            for i, v in enumerate((pure_px, fringe, fill, kept)):
                totals[i] += v
            if report and out is None:
                print(f"  {bmp.relative_to(bin_dir)}: painted tile "
                      f"-> opaque ({fill} px fill)")
            alpha += out is not None
        if out is None:
            out = img.convert("RGB")
            opaque += 1
        if not dry:
            out.save(bmp.with_suffix(".png"), "PNG", optimize=True)

    print(f"files: {alpha + opaque} (alpha {alpha}, opaque {opaque})")
    print(f"cleared: {totals[0]:,} pure black + {totals[1]:,} fringe "
          f"+ {totals[2]:,} background fill")
    print(f"kept as art: {totals[3]:,} px of near-black")
    if dry:
        print("DRY RUN - nothing written")
    return 0


if __name__ == "__main__":
    sys.exit(main())
