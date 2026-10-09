"""Builds bin/sprites/mount-hull.mset - the HD art of the TeK ceiling mount -
from two generated pictures: the pod whole and the same pod battle-worn.

    python build_mount.py build <sources dir> ../../bin/sprites/mount-hull.mset

What comes out, back to front as the game is to draw it:
- hull: the pod whole, seen from the front, mirror-symmetric, never
  mirrored: the flat top of the flange is the line it hangs from, then the
  neck, the housing with the hazard band and the lens, and the manifold bar
  with the seven gun ports; the lens is unlit, the game lights it;
- hullDamaged: the worn pod cut by the frame of the whole one, blended over
  hull as the mount loses lives; a torn plate with wiring on the right of the
  housing, a scorch on the left, a cracked lens.

DENSITY is the one number that ties the art to a screen: 6 px a screen unit
is just past what a 4K screen shows (2160 px for 384 units, 5.625), so the
art is never stretched there, and FullHD shrinks it 2.13 times - within
what a linear filter does without shimmer. A denser screen is this number
and a rebuild; the pictures are generated at about 34 px a unit.

The source pictures are not kept in the repository; `build` looks for them
in the sources dir under the names below. The numbers under "measured"
belong to those pictures. Needs numpy, scipy and Pillow.
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
# The pod is as tall as its cell: the flange then lies flush under the
# ceiling, and the hull is as wide as the picture's proportions make it
HEIGHT_UNITS = 32
WIDTH_UNITS = 36.5

WHOLE_FILE = 'mount-whole.png'
DAMAGED_FILE = 'mount-damaged.png'

# measured on the sources (1254x1254): the box of the whole pod, one clear
# row above the flange so that the picture scales by one factor both ways
FRAME = (7, 78, 1240, 1087)

# measured on the sources, in source pixels; printed in screen units
LENS = (621.6, 642.5)
LENS_RADIUS = 69.5
PORTS = [(192.2, 1105.3), (335.5, 1105.3), (480.4, 1105.3), (624.1, 1105.3),
         (770.4, 1105.3), (915.4, 1105.3), (1059.2, 1105.3)]
POINTS = [
    ('lens', LENS),
    ('torn plate with wiring', (968.0, 704.0)),
    ('scorch', (282.0, 690.0)),
] + [('port %d' % (number + 1), port) for number, port in enumerate(PORTS)]


# --- pictures as float32 premultiplied RGBA, 0..1 ---------------------------

def load_premult(path):
    pixels = np.asarray(Image.open(path).convert('RGBA')).astype(np.float32)
    # generated alpha is dirty at both ends: opaque 249..253, clear 0..7
    alpha = np.clip((pixels[..., 3] - 8) / (249 - 8), 0, 1)
    return np.dstack([pixels[..., :3] / 255 * alpha[..., None], alpha])


def over(top, bottom):
    return top + bottom * (1 - top[..., 3:4])


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


# --- the hull -----------------------------------------------------------------

def frame(picture):
    left, top, width, height = FRAME
    return picture[top:top + height, left:left + width]


def hull_layers(source_dir):
    whole = load_premult(os.path.join(source_dir, WHOLE_FILE))
    damaged = load_premult(os.path.join(source_dir, DAMAGED_FILE))
    # the worn pod in the frame of the whole one: its own silhouette is a few
    # pixels fatter and the torn plate sticks out of it
    worn = over(damaged, whole) * whole[..., 3:4]
    size = (round(WIDTH_UNITS * DENSITY), round(HEIGHT_UNITS * DENSITY))
    return {name: shrink(frame(picture), size)
            for name, picture in (('hull', whole), ('hullDamaged', worn))}


# --- the set ------------------------------------------------------------------

def units(point):
    scale = WIDTH_UNITS / FRAME[2]
    return (point[0] - FRAME[0]) * scale, (point[1] - FRAME[1]) * scale


def png_bytes(image):
    buffer = io.BytesIO()
    image.save(buffer, 'PNG', optimize=True)
    return buffer.getvalue()


def build(source_dir, set_path):
    layers = hull_layers(source_dir)
    spots = {name: units(point) for name, point in POINTS}
    for name, (x, y) in spots.items():
        print('%-24s %5.2f, %5.2f' % (name, x, y))
    pitch = [spots['port %d' % (n + 1)][0] - spots['port %d' % n][0] for n in range(1, 7)]
    print('port pitch %.2f units, row %.2f wide' % (sum(pitch) / len(pitch), sum(pitch)))
    print('lens radius %.2f' % (LENS_RADIUS * WIDTH_UNITS / FRAME[2]))

    width, height = round(WIDTH_UNITS * DENSITY), round(HEIGHT_UNITS * DENSITY)
    hull_size = f'{width}x{height}, {WIDTH_UNITS} x {HEIGHT_UNITS} units'
    spot = lambda name: '%.1f, %.1f' % spots[name]
    description = (
        f'HD art of the TeK ceiling mount, drawn by code in place of the \'alive\' frame of krep.mset: '
        f'{DENSITY} px per screen unit, front view, mirror-symmetric, never mirrored. Back to front: hull, '
        f'hullDamaged. The pod is as tall as its cell and hangs from the flat top edge of its flange. Points '
        f'in screen units from the top-left corner: lens {spot("lens")} (lens radius %.1f); gun ports, '
        f'seven, y %.1f, x %s; torn plate with wiring {spot("torn plate with wiring")}; scorch '
        f'{spot("scorch")}.'
        % (LENS_RADIUS * WIDTH_UNITS / FRAME[2], spots['port 1'][1],
           ', '.join('%.1f' % spots['port %d' % (n + 1)][0] for n in range(7))))
    entries = [
        ('hull', f'the pod whole: flange with four bolts, neck, housing with the hazard band and the lens, '
                 f'manifold bar with seven gun ports; lens unlit; {hull_size}',
         layers['hull']),
        ('hullDamaged', f'the same pod battle-worn; blended over hull as the mount loses lives; torn plate '
                        f'with wiring at {spot("torn plate with wiring")}, scorch at {spot("scorch")}, '
                        f'cracked lens, one port sooted; {hull_size}',
         layers['hullDamaged']),
    ]

    sprites, offset, blobs = [], 0, []
    for name, what, image in entries:
        data = png_bytes(image)
        sprites.append({'name': name, 'description': what, 'offset': offset, 'size': len(data)})
        offset += len(data)
        blobs.append(data)
    manifest = json.dumps({'id': 'mount-hull', 'description': description, 'sprites': sprites,
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
