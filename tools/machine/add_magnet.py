"""Adds to bin/sprites/tek-machine.mset the magnet of the Ram's air fight,
out of one generated picture and without the other tools' sources: each
sprite is put in place of one of the same name, or after the last one.

    python add_magnet.py <sources dir> ../../bin/sprites/tek-machine.mset

The picture (machine-magnet.png, 1254 square, on a clear ground) is an
electromagnet clamp module seen from the side: an armoured collar with
four bolts and a hazard stripe, a neck with cable bundles on both sides,
and a squat coil housing whose round face points down. It is near enough
to symmetric that it is not mirrored with the hull's art.

What it adds:
- magnet: the picture cropped to its ink and scaled to MAGNET_WIDTH units
  across at the set's density. The middle of its top edge hangs from the
  hull's belly, sunk a little into it; drawn behind the hull, turned with
  it, slid out of the belly from the top.
- magnetHeat: what glows when the magnet is hot - the coil housing, its
  side panels and the face under them - in the frame of magnet, clear over
  the neck and the collar, which stay cold. Grey, keeping the housing's own
  light and dark, so the game's tint over the art leaves its seams and its
  honeycomb to be seen.

The source is not kept in the repository, as the other tools' are not.
The numbers under "measured" belong to that picture. Needs numpy and
Pillow.
"""
import os
import sys

import numpy as np
from PIL import Image

from extend_machine import DENSITY, put, read_set, write_set

MAGNET_FILE = 'machine-magnet.png'
MAGNET_WIDTH = 30
# generated alpha is dirty at both ends: opaque 249..253, clear 0..15
ALPHA_CLEAR = 16
ALPHA_OPAQUE = 249
# measured on the picture: the coil housing begins under the ring of the
# neck; the heat comes in over this band of rows, nothing above it
HEAT_FROM_Y = 640
HEAT_FULL_Y = 760
# the housing's own light is kept between these shares of white
HEAT_DARK = 0.55
HEAT_LIGHT = 1.0


def clean(picture):
    pixels = np.asarray(picture.convert('RGBA')).astype(np.float32)
    alpha = np.clip((pixels[..., 3] - ALPHA_CLEAR) / (ALPHA_OPAQUE - ALPHA_CLEAR), 0, 1)
    pixels[..., 3] = alpha * 255
    return Image.fromarray(pixels.round().astype(np.uint8), 'RGBA')


def ink_box(picture):
    rows, cols = np.where(np.asarray(picture)[..., 3] > 128)
    return cols.min(), rows.min(), cols.max() + 1, rows.max() + 1


def scaled(picture, size):
    # through premultiplied alpha, so the clear ground does not darken the edge
    return picture.convert('RGBa').resize(size, Image.LANCZOS).convert('RGBA')


def heat_of(picture, top):
    """The housing in grey on a clear ground, in the frame of the cropped
    picture; top - the row of the source its first row was."""
    pixels = np.asarray(picture).astype(np.float32) / 255
    light = pixels[..., :3] @ np.array([0.299, 0.587, 0.114], np.float32)
    inked = pixels[..., 3] > 0.5
    low, high = np.percentile(light[inked], (5, 95))
    grey = HEAT_DARK + (HEAT_LIGHT - HEAT_DARK) * np.clip((light - low) / (high - low), 0, 1)
    rows = np.arange(picture.height, dtype=np.float32) + top
    ramp = np.clip((rows - HEAT_FROM_Y) / (HEAT_FULL_Y - HEAT_FROM_Y), 0, 1)
    ramp = ramp * ramp * (3 - 2 * ramp)
    alpha = pixels[..., 3] * ramp[:, None]
    heat = np.dstack([grey, grey, grey, alpha])
    return Image.fromarray((heat * 255).round().astype(np.uint8), 'RGBA')


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    sources, path = sys.argv[1], sys.argv[2]
    manifest, pictures = read_set(path)

    source = clean(Image.open(os.path.join(sources, MAGNET_FILE)))
    box = ink_box(source)
    whole = source.crop(box)
    width = MAGNET_WIDTH * DENSITY
    size = (width, round(whole.height * width / whole.width))
    magnet = scaled(whole, size)
    heat = scaled(heat_of(whole, box[1]), size)
    units = f'{size[0] / DENSITY:.1f} x {size[1] / DENSITY:.1f} units'

    put(manifest, pictures, 'magnet',
        f'the electromagnet under the belly, between the engine bays: a collar with a '
        f'hazard stripe, cable bundles, a coil housing with its round face down; '
        f'{units}; the middle of its top edge hangs from the belly, sunk into it; '
        f'drawn behind the hull, turned with it, slid out from the top', magnet)
    put(manifest, pictures, 'magnetHeat',
        'the magnet\'s coil housing - its side panels and its face - in grey, clear '
        'over the neck and the collar; tinted hot by code and blended over magnet '
        'as it heats, same frame', heat)

    write_set(path, manifest, pictures)
    print(f'magnet {size[0]} x {size[1]} px ({units})')


if __name__ == '__main__':
    main()
