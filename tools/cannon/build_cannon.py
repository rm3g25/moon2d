"""Builds bin/sprites/tek-cannon.mset - the HD art of the TeK wall cannon of
the gravel arena - from one generated picture.

    python build_cannon.py build <sources dir> ../../bin/sprites/tek-cannon.mset

What comes out:
- hull: the cannon whole, facing right: the clamp plate that grips the side
  face of a wall pillar on the left, the receiver with the hazard band and
  the sensor lens, the twin ribbed barrels to the right; the lens is unlit,
  the game lights it. The cannon of the right wall is this picture mirrored,
  so it carries no text and no emblem;
- heat: the barrels alone, white, their shape in alpha - the game adds it in
  red over the hull as the barrels overheat.

DENSITY is the number of build_mount.py: 6 px a screen unit. The cannon is
two cells by one, 64 x 32 units, and the picture is generated at exactly
2:1, so it is scaled whole.

The source picture is not kept in the repository; `build` looks for it in
the sources dir under the name below. The numbers under "measured" belong
to that picture. Needs numpy, scipy and Pillow.
"""
import io
import json
import os
import struct
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

DENSITY = 6
WIDTH_UNITS = 64
HEIGHT_UNITS = 32

SOURCE_FILE = 'cannon.png'

# measured on the source (1774x887)
SOURCE_WIDTH = 1774
LENS = (891.5, 343.0)
LENS_RADIUS = 38.0
# the tips of the two barrels, on their axes
MUZZLES = [(1757.0, 390.0), (1757.0, 597.0)]
# where the barrels leave the receiver: the heat starts here
HEAT_FROM = 1100.0
HEAT_RAMP = 80.0
# the bands of the body a hero touches, from the alpha: the clamp plate,
# the receiver, the barrels with the narrow gap between them
CONTACT_BANDS = [(17, 230), (230, 1130), (1130, 1757)]


def load_premult(path):
    pixels = np.asarray(Image.open(path).convert('RGBA')).astype(np.float32)
    # generated alpha is dirty at both ends: opaque 249..253, clear 0..7
    alpha = np.clip((pixels[..., 3] - 8) / (249 - 8), 0, 1)
    return np.dstack([pixels[..., :3] / 255 * alpha[..., None], alpha])


def shrink(premult, size):
    """Lanczos in premultiplied alpha, then the edge colour bled outward:
    a linear filter mixes a silhouette pixel with its clear neighbour, and
    a black neighbour would leave a dark fringe."""
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


def heat_layer(premult):
    """White with the barrels in alpha; the dark grooves of the ribs glow
    less than the steel between them."""
    alpha = premult[..., 3]
    colour = premult[..., :3] / np.maximum(alpha[..., None], 1e-3)
    light = colour.mean(axis=2)
    columns = np.arange(alpha.shape[1], dtype=np.float32)
    ramp = np.clip((columns - HEAT_FROM) / HEAT_RAMP, 0, 1)[None, :]
    level = alpha * ramp * (0.45 + 0.55 * np.clip(light / 0.6, 0, 1))
    white = np.ones_like(premult[..., :3]) * level[..., None]
    return np.dstack([white, level])


def contact_boxes(premult):
    """The rows a band covers more than half of: the empty air over and
    under the barrels stays out, the barrels themselves do not."""
    solid = premult[..., 3] > 0.5
    boxes = []
    for left, right in CONTACT_BANDS:
        rows = np.nonzero(solid[:, left:right].mean(axis=1) > 0.5)[0]
        boxes.append((left, rows.min(), right, rows.max() + 1))
    return boxes


def units(value):
    return value * WIDTH_UNITS / SOURCE_WIDTH


def png_bytes(image):
    buffer = io.BytesIO()
    image.save(buffer, 'PNG', optimize=True)
    return buffer.getvalue()


def build(source_dir, set_path):
    source = load_premult(os.path.join(source_dir, SOURCE_FILE))
    size = (WIDTH_UNITS * DENSITY, HEIGHT_UNITS * DENSITY)
    hull = shrink(source, size)
    heat = shrink(heat_layer(source), size)

    boxes = [tuple(units(v) for v in box) for box in contact_boxes(source)]
    muzzles = [(units(x), units(y)) for x, y in MUZZLES]
    lens = (units(LENS[0]), units(LENS[1]))
    for box in boxes:
        print('contact %5.2f, %5.2f .. %5.2f, %5.2f' % box)
    for x, y in muzzles:
        print('muzzle  %5.2f, %5.2f' % (x, y))
    print('lens    %5.2f, %5.2f radius %.2f' % (lens[0], lens[1], units(LENS_RADIUS)))

    hull_size = f'{size[0]}x{size[1]}, {WIDTH_UNITS} x {HEIGHT_UNITS} units'
    description = (
        f'HD art of the TeK wall cannon of the gravel arena: {DENSITY} px per screen unit, side view, facing '
        f'right, mirrored whole for the right wall. Back to front: hull, heat. Points in screen units from '
        f'the top-left corner of the right-facing picture: lens %.1f, %.1f (radius %.1f); muzzles %s; '
        f'contact boxes (left, top .. right, bottom) %s.'
        % (lens[0], lens[1], units(LENS_RADIUS),
           ' and '.join('%.1f, %.1f' % m for m in muzzles),
           '; '.join('%.1f, %.1f .. %.1f, %.1f' % b for b in boxes)))
    entries = [
        ('hull', f'the cannon whole: clamp plate, receiver with the hazard band and the lens, twin ribbed '
                 f'barrels; lens unlit; {hull_size}', hull),
        ('heat', f'the barrels alone, white, their shape in alpha: added in red as they overheat; '
                 f'{hull_size}', heat),
    ]

    sprites, offset, blobs = [], 0, []
    for name, what, image in entries:
        data = png_bytes(image)
        sprites.append({'name': name, 'description': what, 'offset': offset, 'size': len(data)})
        offset += len(data)
        blobs.append(data)
    manifest = json.dumps({'id': 'tek-cannon', 'description': description, 'sprites': sprites,
                           'sequences': []}, indent=2, ensure_ascii=False).encode('utf-8')
    with open(set_path, 'wb') as out:
        out.write(b'MSET' + struct.pack('<HI', 1, len(manifest)) + manifest)
        for data in blobs:
            out.write(data)
    print(f'{len(sprites)} sprites, {10 + len(manifest) + offset} bytes -> {set_path}')


if __name__ == '__main__':
    if len(sys.argv) == 4 and sys.argv[1] == 'build':
        build(sys.argv[2], sys.argv[3])
    else:
        sys.exit(__doc__)
