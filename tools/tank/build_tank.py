"""Builds bin/sprites/tank-hull.mset - the HD art of the TeK-J02 tank - from
three generated pictures: the tank whole, the same tank battle-worn, and one
wheel seen from the front in flat light.

    python build_tank.py build <sources dir> ../../bin/sprites/tank-hull.mset

What comes out, back to front as the game is to draw it:
- chassis: the dark of the wheel wells, behind the wheels;
- wheel: one wheel, a square with the axle at its center; drawn twice and
  turned by code;
- hull: the tank with the wheels cut out, and in the cuts the shade the
  fenders cast on the wheels - it stands still while the wheel turns;
- hullDamaged: the worn tank cut by the frame of the whole one, blended
  over hull; clear in the cuts, so the shade is not laid twice.

DENSITY is the one number that ties the art to a screen: 6 px a screen unit
is just past what a 4K screen shows (2160 px for 384 units, 5.625), so the
art is never stretched there, and FullHD shrinks it 2.13 times - within
what a linear filter does without shimmer. A denser screen is this number
and a rebuild; the pictures are generated at about 35 px a unit.

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
WIDTH_UNITS = 38
HEIGHT_UNITS = 31
WHEEL_UNITS = 16

WHOLE_FILE = 'tank-whole.png'
DAMAGED_FILE = 'tank-damaged.png'
WHEEL_FILE = 'tank-wheel.png'

# measured on the sources (1374x1145): the box of the whole tank, two clear
# rows taller than the silhouette so that it scales by one factor both ways
# and stands on the bottom edge
FRAME = (17, 33, 1341, 1094)
FLOOR = FRAME[1] + FRAME[3]
# The painted tyres are pressed against the ground, wider than tall: this
# is what gets cut out. Their axles' x, the half-width and the top; the
# bottom is the floor.
PAINTED_TYRES = (425.0, 1042.5)
PAINTED_HALF_WIDTH = 283.0
PAINTED_TOP = 586.0
# Below this line the hull has nothing: the bar under the belly ends at 924
BELLY = 930.0
# The wheel the game turns is a circle: it stands on the floor and its top
# passes in the dark under the fender (the fender's edge is at 574)
WHEEL_RADIUS = 274.0
# measured on the wheel (1254x1254): the tyre and the hub are not
# concentric - the hub is moved onto the tyre's axis
TYRE_CENTRE = (624.4, 621.8)
TYRE_TIPS = 608.0
HUB_CENTRE = (625.2, 600.5)
# The hub (its rim is 272 from its centre) goes whole inside the first
# radius; the tyre stays put past the second; the side wall between them
# takes up the stretch
HUB_MOVES_WITHIN = 300.0
TYRE_STAYS_PAST = 440.0

WELL_COLOUR = (14, 14, 16)
# The dark of a well ends below the axle: under the belly there is air
WELL_FADE = (0.15, 0.45)  # shares of the wheel radius below the axle
SHADE_DEPTH = 0.62        # share of the wheel radius the shade reaches down
SHADE_LEVEL = 0.6

# measured on the sources, in source pixels; printed in screen units
POINTS = [
    ('eye', (890.5, 237.5)),
    ('headlight', (78.0, 496.0)),
    ('beacon', (860.0, 75.0)),
    ('muzzle top', (212.0, 163.5)),
    ('muzzle middle', (212.0, 224.0)),
    ('muzzle bottom', (212.0, 284.0)),
    ('torn deck with wiring', (1150.0, 250.0)),
    ('scorch on the turret', (705.0, 255.0)),
    ('scorch on the side', (852.0, 385.0)),
]


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


def smoothstep(low, high, value):
    share = np.clip((value - low) / (high - low), 0, 1)
    return share * share * (3 - 2 * share)


# --- the hull -----------------------------------------------------------------

def frame(picture):
    left, top, width, height = FRAME
    return picture[top:top + height, left:left + width]


def tyre_cuts(shape):
    """How far every pixel is inside a painted tyre: 0..1, a soft edge."""
    ys, xs = np.mgrid[0:shape[0], 0:shape[1]].astype(np.float32)
    half_height = (FLOOR - PAINTED_TOP) / 2
    middle = PAINTED_TOP + half_height
    cut = np.zeros(shape[:2], np.float32)
    for axle in PAINTED_TYRES:
        reach = np.hypot((xs + 0.5 - axle) / PAINTED_HALF_WIDTH, (ys + 0.5 - middle) / half_height)
        cut = np.maximum(cut, np.clip((1 - reach) * half_height / 1.5 + 0.5, 0, 1))
    return cut


def hull_layers(source_dir):
    whole = load_premult(os.path.join(source_dir, WHOLE_FILE))
    damaged = load_premult(os.path.join(source_dir, DAMAGED_FILE))
    ys = np.mgrid[0:whole.shape[0], 0:whole.shape[1]][0].astype(np.float32) + 0.5
    # below the belly all that is painted is tyre: a pressed tyre bulges
    # past its ellipse there, and its outline would stay behind
    tyres = tyre_cuts(whole.shape)
    cut = np.maximum(tyres, np.clip(ys - BELLY, 0, 1))

    # the worn tank in the frame of the whole one: its own silhouette is a
    # few pixels fatter and the torn deck sticks out of it
    worn = over(damaged, whole) * whole[..., 3:4]

    axle = FLOOR - WHEEL_RADIUS
    well = tyres * (1 - smoothstep(axle + WELL_FADE[0] * WHEEL_RADIUS, axle + WELL_FADE[1] * WHEEL_RADIUS, ys))
    chassis = np.dstack([well * (channel / 255) for channel in WELL_COLOUR] + [well])

    depth = np.clip(1 - (ys - PAINTED_TOP) / (SHADE_DEPTH * WHEEL_RADIUS), 0, 1)
    shade = tyres * SHADE_LEVEL * depth * depth
    shade_picture = np.dstack([shade * 0, shade * 0, shade * 0, shade])
    hull = over(whole * (1 - cut[..., None]), shade_picture)
    hull_damaged = worn * (1 - cut[..., None])

    size = (WIDTH_UNITS * DENSITY, HEIGHT_UNITS * DENSITY)
    return {name: shrink(frame(picture), size)
            for name, picture in (('chassis', chassis), ('hull', hull), ('hullDamaged', hull_damaged))}


# --- the wheel ----------------------------------------------------------------

def wheel_picture(source_dir):
    wheel = load_premult(os.path.join(source_dir, WHEEL_FILE))
    side = WHEEL_UNITS * DENSITY
    # source pixels a sprite pixel: the lug tips land at the wheel's radius
    tips_units = WHEEL_RADIUS / (FRAME[2] / WIDTH_UNITS)
    step = TYRE_TIPS / (tips_units * DENSITY)
    fine = side * 12
    ys, xs = np.mgrid[0:fine, 0:fine].astype(np.float32)
    dx = (xs + 0.5 - fine / 2) * step * side / fine
    dy = (ys + 0.5 - fine / 2) * step * side / fine
    moved = 1 - smoothstep(HUB_MOVES_WITHIN, TYRE_STAYS_PAST, np.hypot(dx, dy))
    sx = TYRE_CENTRE[0] + dx + (HUB_CENTRE[0] - TYRE_CENTRE[0]) * moved - 0.5
    sy = TYRE_CENTRE[1] + dy + (HUB_CENTRE[1] - TYRE_CENTRE[1]) * moved - 0.5
    master = np.dstack([ndimage.map_coordinates(wheel[..., k], [sy, sx], order=1, mode='constant')
                        for k in range(4)])
    return shrink(master, (side, side)), tips_units


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
    wheel, tips_units = wheel_picture(source_dir)
    axles = [units((axle, FLOOR - WHEEL_RADIUS)) for axle in PAINTED_TYRES]
    spots = {name: units(point) for name, point in POINTS}
    for name, (x, y) in list(spots.items()) + [('front axle', axles[0]), ('rear axle', axles[1])]:
        print('%-22s %5.1f, %4.1f' % (name, x, y))
    print('wheel radius to the lug tips %.2f' % tips_units)

    width, height = WIDTH_UNITS * DENSITY, HEIGHT_UNITS * DENSITY
    side = WHEEL_UNITS * DENSITY
    hull_size = f'{width}x{height}, {WIDTH_UNITS} x {HEIGHT_UNITS} units'
    spot = lambda name: '%.1f, %.1f' % spots[name]
    description = (
        f'HD art of the TeK-J02 tank, drawn by code in place of the \'alive\' frames of tank.mset: '
        f'{DENSITY} px per screen unit, side view, facing left, mirrored whole when it drives right. '
        f'Back to front: chassis, the wheel twice, hull, hullDamaged. The tank stands on the bottom '
        f'edge. Points in screen units from the top-left corner: axles %.1f and %.1f, y %.1f '
        f'(wheel radius %.1f to the lug tips); eye {spot("eye")} (lens radius 1.9); headlight '
        f'{spot("headlight")}; beacon {spot("beacon")}; muzzles x %.1f, y %.1f, %.1f and %.1f.'
        % (axles[0][0], axles[1][0], axles[0][1], tips_units, spots['muzzle top'][0],
           spots['muzzle top'][1], spots['muzzle middle'][1], spots['muzzle bottom'][1]))
    entries = [
        ('chassis', f'the dark of the two wheel wells, behind the wheels; fades out below the axles; {hull_size}',
         layers['chassis']),
        ('wheel', f'one wheel in flat light, the axle at the center, a yellow wedge on the hub; turned by code; '
                  f'{side}x{side}, {WHEEL_UNITS} units',
         wheel),
        ('hull', f'the tank whole, the wheels cut out, the fenders\' shade in the cuts: slab hull with the '
                 f'hazard band, turret with the lens and three stacked barrels, beacon on its roof, headlight '
                 f'on the nose; lens, beacon and headlight unlit; {hull_size}',
         layers['hull']),
        ('hullDamaged', f'the same tank battle-worn; blended over hull as the tank loses lives; clear in the '
                        f'cuts; torn deck with wiring at {spot("torn deck with wiring")}, scorches at '
                        f'{spot("scorch on the turret")} and {spot("scorch on the side")}, cracked lens and '
                        f'headlight; {hull_size}',
         layers['hullDamaged']),
    ]

    sprites, offset, blobs = [], 0, []
    for name, what, image in entries:
        data = png_bytes(image)
        sprites.append({'name': name, 'description': what, 'offset': offset, 'size': len(data)})
        offset += len(data)
        blobs.append(data)
    manifest = json.dumps({'id': 'tank-hull', 'description': description, 'sprites': sprites,
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
