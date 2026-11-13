"""Adds the facade with the gate - the sealed door of arena 3 given a body,
the picture the titles of 3.0 stand on (docs/mechanics/finale.md, "The
gate") - to bin/sprites/level2-objects.mset from one generated picture: a
facade in a flat front view on a clear ground, the gate shut, the housing
of its status lamp painted unlit.

    python build_gate.py build <gate.png> ../../bin/sprites/level2-objects.mset

The picture is cut to its body and scaled whole to DENSITY px a screen
unit, WIDTH_UNITS wide: from the gate's left to the right edge of the
screen. Its height in units and the place of its lamp housing are printed
and written into the description, for Game.Gate.

The source picture is not kept in the repository. Needs numpy, scipy and
Pillow.
"""
import io
import json
import struct
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

NAME = 's13-gate'
DENSITY = 6
ALPHA_FLOOR = 8 / 255
ALPHA_CEILING = 250 / 255

# From the gate's left, x 392, to the right edge of the screen
WIDTH_UNITS = 120
# The middle of the lamp housing over the portal, px of the source picture
LAMP_AT = (565, 383)


def load_premult(path):
    picture = np.asarray(Image.open(path).convert('RGBA'), dtype=np.float32) / 255
    alpha = np.clip((picture[..., 3] - ALPHA_FLOOR) / (ALPHA_CEILING - ALPHA_FLOOR), 0, 1)
    return np.dstack([picture[..., :3] * alpha[..., None], alpha])


def body_box(premult):
    rows, cols = np.where(premult[..., 3] >= 0.5)
    return cols.min(), rows.min(), cols.max() + 1, rows.max() + 1


def shrink(premult, size):
    """Lanczos in premultiplied alpha, then the edge colour bled outward, so
    the linear filter of the game finds no dark fringe."""
    small = np.dstack([np.asarray(Image.fromarray(np.ascontiguousarray(premult[..., k]), 'F')
                                  .resize(size, Image.LANCZOS)) for k in range(4)])
    alpha = np.clip(small[..., 3], 0, 1)
    alpha8 = (alpha * 255 + 0.5).astype(np.uint8)
    colour = np.where(alpha[..., None] > 1e-3, small[..., :3] / np.maximum(alpha[..., None], 1e-3), 0)
    colour8 = (np.clip(colour, 0, 1) * 255 + 0.5).astype(np.uint8)
    painted = alpha8 > 0
    if painted.any() and not painted.all():
        nearest = ndimage.distance_transform_edt(~painted, return_distances=False, return_indices=True)
        colour8 = colour8[nearest[0], nearest[1]]
    return Image.fromarray(np.dstack([colour8, alpha8]), 'RGBA')


def png_bytes(image):
    buffer = io.BytesIO()
    image.save(buffer, 'PNG', optimize=True)
    return buffer.getvalue()


def read_set(path):
    with open(path, 'rb') as source:
        data = source.read()
    size = struct.unpack('<I', data[6:10])[0]
    manifest = json.loads(data[10:10 + size].decode('utf-8'))
    images = data[10 + size:]
    blobs = {sprite['name']: images[sprite['offset']:sprite['offset'] + sprite['size']]
             for sprite in manifest['sprites']}
    return manifest, blobs


def write_set(path, manifest, blobs):
    offset = 0
    for sprite in manifest['sprites']:
        sprite['offset'] = offset
        sprite['size'] = len(blobs[sprite['name']])
        offset += sprite['size']
    packed = json.dumps(manifest, separators=(',', ':'), ensure_ascii=False).encode('utf-8')
    with open(path, 'wb') as out:
        out.write(b'MSET' + struct.pack('<HI', 1, len(packed)) + packed)
        for sprite in manifest['sprites']:
            out.write(blobs[sprite['name']])
    return 10 + len(packed) + offset


def build(source, set_path):
    premult = load_premult(source)
    left, top, right, bottom = body_box(premult)
    body = premult[top:bottom, left:right]
    px_per_unit = body.shape[1] / WIDTH_UNITS
    width = WIDTH_UNITS * DENSITY
    height = round(body.shape[0] / px_per_unit * DENSITY)
    picture = shrink(body, (width, height))
    lamp = ((LAMP_AT[0] - left) / px_per_unit, (LAMP_AT[1] - top) / px_per_unit)

    what = ('The facade with the gate at the right end of the road of screen 13, the sealed door '
            'of the arena: a capsule roof, a ribbon of windows, a burnt-orange stripe, the two '
            'ribbed leaves shut, front-lit - the game puts it in the night by its shade. One '
            'generation with the pieces of the city attached as the style, cut to its '
            'body (%d-%d by %d-%d px of %dx%d) and scaled whole to %d px a unit: %dx%d, %d by '
            '%.1f units, its foot on the road line 352. The housing of the status lamp over the '
            'portal is painted unlit: the lamp is the game\'s light, its middle at %.1f, %.1f '
            'units from the top-left corner.'
            % (left, right, top, bottom, premult.shape[1], premult.shape[0], DENSITY, width,
               height, WIDTH_UNITS, height / DENSITY, lamp[0], lamp[1]))

    manifest, blobs = read_set(set_path)
    manifest['sprites'] = [sprite for sprite in manifest['sprites'] if sprite['name'] != NAME]
    manifest['sprites'].append({'name': NAME, 'description': what, 'offset': 0, 'size': 0})
    blobs[NAME] = png_bytes(picture)
    total = write_set(set_path, manifest, blobs)
    print('%s: %d x %d px, %d by %.2f units, the lamp at %.2f, %.2f units'
          % (NAME, width, height, WIDTH_UNITS, height / DENSITY, lamp[0], lamp[1]))
    print(f'{len(manifest["sprites"])} sprites, {total} bytes -> {set_path}')


if __name__ == '__main__':
    if len(sys.argv) == 4 and sys.argv[1] == 'build':
        build(sys.argv[2], sys.argv[3])
    else:
        sys.exit(__doc__)
