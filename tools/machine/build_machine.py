"""Builds bin/sprites/tek-machine.mset - the HD art of the TeK machine, the
second level 2 boss - from five generated pictures: the machine whole, the
same machine battle-worn, one wheel, the mast kit (three telescopic sections
and the napalm mortar) and the turret heads (hunter, its barrel, sweeper,
bunker).

    python build_machine.py build <sources dir> ../../bin/sprites/tek-machine.mset

The pictures face right; the machine never turns round and faces left in
the game, so every sprite is mirrored here once and the game draws it as it
is. Every point in the descriptions is in screen units from the top-left
corner of its sprite, after the mirror.

What comes out, back to front as the game is to draw it:
- well: the back half of the dark of the mast well, behind the mast;
- chassis: the dark of the wheel arches, behind the wheels;
- wheel: one wheel, the axle at the center; drawn twice and turned by code;
- mortar: rises from behind the rear block, so it is drawn behind the hull;
- mast1, mast2, mast3: the telescope, the widest first; each next one is
  drawn behind the one below it, so its flange stays inside;
- hull: the machine whole, clear in the arches and over the back half of
  the well - a mast stands in the well's middle line;
- hullDamaged: the worn machine in the frame of the whole one, blended over
  hull, cut the same way;
- the heads on the top of mast3: hunter with hunterBarrel over it (turned
  by code about its pivot), sweeper with sweeperHeat (the barrels white,
  tinted red by code as the warning), bunker with bunkerLid (turned and
  moved by code to shut the hatch).

DENSITY is the same 6 px a screen unit as the tank's. The source pictures
are not kept in the repository; `build` looks for them in the sources dir
under the names below. The numbers under "measured" belong to those
pictures. Needs numpy, scipy and Pillow.
"""
import io
import json
import math
import os
import struct
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

DENSITY = 6
HEIGHT_UNITS = 128

WHOLE_FILE = 'machine-whole.png'
DAMAGED_FILE = 'machine-damaged.png'
WHEEL_FILE = 'machine-wheel.png'
MAST_FILE = 'machine-mast.png'
HEADS_FILE = 'machine-heads.png'

# measured on the whole machine (1254x1254): its box, standing on the lowest
# point of the ram; the width is set so the box is a whole number of units
FRAME_LEFT = 10.0
FRAME_TOP = 159.0
FLOOR = 1097.0
WIDTH_UNITS = 169
UNIT = HEIGHT_UNITS / (FLOOR - FRAME_TOP)
FRAME_WIDTH = WIDTH_UNITS / UNIT

# the worn machine came back a little smaller and higher: its box mapped
# onto the whole one's
DAMAGED_BOX = (11.0, 141.0, 1252.0, 1082.0)
WHOLE_BOX = (13.0, 160.0, 1246.0, 1096.0)

# the wheel arches: the axles' x and the radius of the wheel, which stands
# on the floor and hides its top and sides behind the arch
AXLES = (272.0, 801.0)
WHEEL_RADIUS = 150.0
WELL_COLOUR = (14, 14, 16)
WELL_FADE = (0.1, 0.5)  # shares of the wheel radius below the axle

# the mast well on the roof: the ellipse of its dark opening
WELL_CENTRE = (736.0, 266.0)
WELL_HALF = (121.0, 19.0)

# measured on the mast kit (1536x1024): the boxes of the sections and of
# the mortar, and the scale against the whole machine - the widest section
# fills the well's opening
SECTIONS = [(30, 51, 406, 985), (466, 142, 737, 976), (822, 188, 1023, 977)]
MORTAR = (1079, 319, 1511, 971)
MAST_SCALE = 230.0 / 376.0

# measured on the heads (2172x724): the boxes, the scale against the whole
# machine (the socket sits on the top collar of mast3), and their points
HUNTER = (26, 336, 449, 623)
BARREL = (482, 403, 991, 545)
SWEEPER = (1034, 337, 1676, 623)
BUNKER = (1716, 101, 2146, 624)
HEADS_SCALE = 0.48
SOCKETS = {'hunter': 195.0, 'sweeper': 1230.0, 'bunker': 1988.0}
SOCKET_BOTTOM = 622.0
HUNTER_LENS = (188.0, 470.0)
HUNTER_SLEEVE = (420.0, 445.0)
BARREL_PIVOT = (520.0, 468.0)
BARREL_MUZZLE = (988.0, 468.0)
SWEEPER_BARRELS_FROM = 1405.0
SWEEPER_MUZZLES = [(1673.0, 389.0), (1673.0, 434.0), (1673.0, 481.0), (1673.0, 530.0)]
BUNKER_MUZZLES = [(1718.0, 470.0), (1718.0, 528.0)]
# the lid: everything of the bunker over this line right of LID_FROM_X; it
# turns about the hinge
LID_LINE = 283.0
LID_FROM_X = 1955.0
LID_HINGE = (2000.0, 278.0)
# shut: the lid turned this far about the hinge, counter-clockwise on the
# mirrored sprite, and moved this far in screen units to cover the opening
LID_OPEN_DEGREES = 52.0
LID_SHUT_SHIFT = (5.5, -1.5)

# measured on the whole machine, in source pixels
POINTS = [
    ('eye', (1085.5, 560.5)),
    ('brake lamp upper', (69.0, 476.5)),
    ('brake lamp lower', (69.0, 534.5)),
    ('exhaust upper', (45.0, 268.0)),
    ('exhaust lower', (45.0, 368.0)),
    ('mortar pivot', (285.0, 330.0)),
    ('rear block top', (285.0, 180.0)),
    ('ram tip', (1246.0, 1097.0)),
]


# --- pictures as float32 premultiplied RGBA, 0..1 ---------------------------

def load_premult(path):
    pixels = np.asarray(Image.open(path).convert('RGBA')).astype(np.float32)
    # generated alpha is dirty at both ends: opaque 249..253, clear 0..15
    alpha = np.clip((pixels[..., 3] - 16) / (249 - 16), 0, 1)
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
    return Image.fromarray(np.dstack([colour8, alpha8]), 'RGBA').transpose(Image.FLIP_LEFT_RIGHT)


def resample(picture, out_size, to_source):
    """The picture seen through to_source(x, y) -> (sx, sy), out_size wide
    and tall, bilinear."""
    ys, xs = np.mgrid[0:out_size[1], 0:out_size[0]].astype(np.float32) + 0.5
    sx, sy = to_source(xs, ys)
    return np.dstack([ndimage.map_coordinates(picture[..., k], [sy - 0.5, sx - 0.5], order=1, mode='constant')
                      for k in range(4)])


def smoothstep(low, high, value):
    share = np.clip((value - low) / (high - low), 0, 1)
    return share * share * (3 - 2 * share)


def crop(picture, box):
    left, top, right, bottom = box
    return picture[top:bottom, left:right]


def units_size(box, scale):
    width = (box[2] - box[0]) * scale * UNIT
    height = (box[3] - box[1]) * scale * UNIT
    return width, height


def pixel_size(width_units, height_units):
    return max(1, round(width_units * DENSITY)), max(1, round(height_units * DENSITY))


# --- the hull -----------------------------------------------------------------

def hull_frame(picture):
    """The frame of the whole machine, cut out of the picture at the scale
    of the sprite."""
    size = pixel_size(WIDTH_UNITS, HEIGHT_UNITS)
    step = FRAME_WIDTH / size[0]
    return resample(picture, size, lambda x, y: (FRAME_LEFT + x * step, FRAME_TOP + y * step))


def hull_layers(source_dir):
    whole = load_premult(os.path.join(source_dir, WHOLE_FILE))
    damaged = load_premult(os.path.join(source_dir, DAMAGED_FILE))

    scale_x = (DAMAGED_BOX[2] - DAMAGED_BOX[0]) / (WHOLE_BOX[2] - WHOLE_BOX[0])
    scale_y = (DAMAGED_BOX[3] - DAMAGED_BOX[1]) / (WHOLE_BOX[3] - WHOLE_BOX[1])
    aligned = resample(damaged, (whole.shape[1], whole.shape[0]),
                       lambda x, y: (DAMAGED_BOX[0] + (x - WHOLE_BOX[0]) * scale_x,
                                     DAMAGED_BOX[1] + (y - WHOLE_BOX[1]) * scale_y))
    worn = over(aligned, whole) * whole[..., 3:4]

    ys, xs = np.mgrid[0:whole.shape[0], 0:whole.shape[1]].astype(np.float32) + 0.5
    # the back half of the well's dark: lifted out of the hull into its own
    # layer, so a mast stands in the middle line of the opening
    inside = np.hypot((xs - WELL_CENTRE[0]) / (WELL_HALF[0] + 2), (ys - WELL_CENTRE[1]) / (WELL_HALF[1] + 2)) < 1
    back = (inside & (ys < WELL_CENTRE[1])).astype(np.float32)
    well = whole * back[..., None]
    hull = whole * (1 - back[..., None])
    hull_damaged = worn * (1 - back[..., None])

    # the dark behind the wheels: where the hull is clear inside a wheel's
    # circle, fading out below the axle
    axle_y = FLOOR - WHEEL_RADIUS
    in_wheel = np.zeros(whole.shape[:2], np.float32)
    for axle_x in AXLES:
        in_wheel = np.maximum(in_wheel, (np.hypot(xs - axle_x, ys - axle_y) < WHEEL_RADIUS).astype(np.float32))
    fade = 1 - smoothstep(axle_y + WELL_FADE[0] * WHEEL_RADIUS, axle_y + WELL_FADE[1] * WHEEL_RADIUS, ys)
    dark = in_wheel * fade
    chassis = np.dstack([dark * (channel / 255) for channel in WELL_COLOUR] + [dark])

    return {name: shrink(hull_frame(picture), pixel_size(WIDTH_UNITS, HEIGHT_UNITS))
            for name, picture in (('well', well), ('chassis', chassis), ('hull', hull),
                                  ('hullDamaged', hull_damaged))}


# --- the wheel ----------------------------------------------------------------

def wheel_picture(source_dir):
    wheel = load_premult(os.path.join(source_dir, WHEEL_FILE))
    alpha = wheel[..., 3] > 0.5
    ys, xs = np.nonzero(alpha)
    centre = ((xs.min() + xs.max() + 1) / 2, (ys.min() + ys.max() + 1) / 2)
    tips = max(xs.max() + 1 - xs.min(), ys.max() + 1 - ys.min()) / 2
    radius_units = WHEEL_RADIUS * UNIT
    side = round(2 * radius_units * DENSITY)
    fine = side * 4
    step = tips * 2 / fine
    master = resample(wheel, (fine, fine),
                      lambda x, y: (centre[0] + (x - fine / 2) * step, centre[1] + (y - fine / 2) * step))
    return shrink(master, (side, side)), radius_units


# --- the parts ----------------------------------------------------------------

def part(picture, box, scale):
    width, height = units_size(box, scale)
    return shrink(crop(picture, box), pixel_size(width, height)), (width, height)


def spot(point, box, scale, width_units):
    """A source point of a part in screen units of its mirrored sprite."""
    x = (point[0] - box[0]) * scale * UNIT
    y = (point[1] - box[1]) * scale * UNIT
    return width_units - x, y


def heat_of(sweeper):
    """The barrels of the sweeper in white, keeping their shading; the
    body left clear."""
    xs = np.mgrid[0:sweeper.shape[0], 0:sweeper.shape[1]][1].astype(np.float32) + SWEEPER[0] + 0.5
    barrels = smoothstep(SWEEPER_BARRELS_FROM - 4, SWEEPER_BARRELS_FROM + 4, xs)
    alpha = sweeper[..., 3] * barrels
    colour = sweeper[..., :3] / np.maximum(sweeper[..., 3:4], 1e-3)
    light = 0.65 + 0.35 * colour.mean(axis=2)
    return np.dstack([light * alpha, light * alpha, light * alpha, alpha])


def split_lid(bunker):
    """The bunker without its lid, and the lid alone shut over the hatch:
    it is turned about the hinge by the angle it stands open."""
    ys, xs = np.mgrid[0:bunker.shape[0], 0:bunker.shape[1]].astype(np.float32) + 0.5
    xs += BUNKER[0]
    ys += BUNKER[1]
    lid_mask = ((ys < LID_LINE) & (xs > LID_FROM_X)).astype(np.float32)
    lid = bunker * lid_mask[..., None]
    body = bunker * (1 - lid_mask[..., None])
    return body, lid


# --- the set ------------------------------------------------------------------

def png_bytes(image):
    buffer = io.BytesIO()
    image.save(buffer, 'PNG', optimize=True)
    return buffer.getvalue()


def hull_spot(point):
    return WIDTH_UNITS - (point[0] - FRAME_LEFT) * UNIT, (point[1] - FRAME_TOP) * UNIT


def fmt(point):
    return '%.1f, %.1f' % point


def build(source_dir, set_path):
    layers = hull_layers(source_dir)
    wheel, radius = wheel_picture(source_dir)
    mast_kit = load_premult(os.path.join(source_dir, MAST_FILE))
    heads = load_premult(os.path.join(source_dir, HEADS_FILE))

    axles = [hull_spot((x, FLOOR - WHEEL_RADIUS)) for x in AXLES]
    well = hull_spot(WELL_CENTRE)
    spots = {name: hull_spot(point) for name, point in POINTS}
    hull_size = f'{WIDTH_UNITS} x {HEIGHT_UNITS} units'

    sections = [part(mast_kit, box, MAST_SCALE) for box in SECTIONS]
    mortar, mortar_size = part(mast_kit, MORTAR, MAST_SCALE)

    hunter, hunter_size = part(heads, HUNTER, HEADS_SCALE)
    barrel, barrel_size = part(heads, BARREL, HEADS_SCALE)
    sweeper_source = crop(heads, SWEEPER)
    sweeper_size = units_size(SWEEPER, HEADS_SCALE)
    sweeper = shrink(sweeper_source, pixel_size(*sweeper_size))
    heat = shrink(heat_of(sweeper_source), pixel_size(*sweeper_size))
    bunker_body, bunker_lid = split_lid(crop(heads, BUNKER))
    bunker_size = units_size(BUNKER, HEADS_SCALE)
    bunker = shrink(bunker_body, pixel_size(*bunker_size))
    lid = shrink(bunker_lid, pixel_size(*bunker_size))

    def socket(name, box, width_units):
        return spot((SOCKETS[name], SOCKET_BOTTOM), box, HEADS_SCALE, width_units)

    def head_spot(point, box, width_units):
        return fmt(spot(point, box, HEADS_SCALE, width_units))

    def mast_entry(index):
        image, (width, height) = sections[index]
        return (f'mast{index + 1}',
                f'telescopic mast section {index + 1} of 3, the widest first; top collar centre '
                f'{width / 2:.1f}, 0, bottom centre {width / 2:.1f}, {height:.1f}; '
                f'{image.width}x{image.height}, {width:.1f} x {height:.1f} units', image)

    description = (
        f'HD art of the TeK machine, the second level 2 boss: {DENSITY} px per screen unit, side view, '
        f'facing left for good (mirrored here, never in the game). Back to front: well, chassis, the wheel '
        f'twice, mortar, mast3, mast2, mast1, hull, hullDamaged, then the head on mast3. The hull stands on '
        f'the bottom edge (the ram tip). Points in screen units from the top-left corner of the hull: axles '
        f'{fmt(axles[0])} and {fmt(axles[1])} (wheel radius {radius:.1f}); mast well centre {fmt(well)} '
        f'(opening half-width {WELL_HALF[0] * UNIT:.1f}); eye {fmt(spots["eye"])}; brake lamps '
        f'{fmt(spots["brake lamp upper"])} and {fmt(spots["brake lamp lower"])}; exhausts '
        f'{fmt(spots["exhaust upper"])} and {fmt(spots["exhaust lower"])}; mortar pivot (its bottom centre '
        f'when out) {fmt(spots["mortar pivot"])}, the rear block top at y {spots["rear block top"][1]:.1f}.')

    entries = [
        ('well', f'the back half of the mast well\'s dark, behind the mast; {hull_size}', layers['well']),
        ('chassis', f'the dark of the two wheel arches, behind the wheels; fades out below the axles; '
                    f'{hull_size}', layers['chassis']),
        ('wheel', f'one cleated wheel, the axle at the center, a hazard ring on the hub; turned by code; '
                  f'{wheel.width}x{wheel.height}, radius {radius:.1f} units', wheel),
        ('mortar', f'the napalm mortar pointing up, on its pivot block; rises from behind the rear block; '
                   f'pivot (bottom centre) {mortar_size[0] / 2:.1f}, {mortar_size[1]:.1f}, muzzle at the '
                   f'top of the tube; {mortar.width}x{mortar.height}, '
                   f'{mortar_size[0]:.1f} x {mortar_size[1]:.1f} units', mortar),
        mast_entry(2), mast_entry(1), mast_entry(0),
        ('hull', f'the machine whole: ram blade, eye slit, mast well, rear block with the launcher bay, '
                 f'exhausts, brake lamps; clear in the arches and over the back half of the well; eye and '
                 f'lamps unlit; {hull_size}', layers['hull']),
        ('hullDamaged', f'the same machine battle-worn, in the frame of the whole one, cut the same way; '
                        f'blended over hull; {hull_size}', layers['hullDamaged']),
        ('hunter', f'turret head 1: a lens and a barrel sleeve; socket (bottom centre) '
                   f'{fmt(socket("hunter", HUNTER, hunter_size[0]))}, lens {head_spot(HUNTER_LENS, HUNTER, hunter_size[0])}, '
                   f'sleeve {head_spot(HUNTER_SLEEVE, HUNTER, hunter_size[0])}; {hunter.width}x{hunter.height}, '
                   f'{hunter_size[0]:.1f} x {hunter_size[1]:.1f} units', hunter),
        ('hunterBarrel', f'the hunter\'s barrel lying level, pointing left; drawn over the head, its pivot on '
                         f'the sleeve and turned about it; pivot {head_spot(BARREL_PIVOT, BARREL, barrel_size[0])}, '
                         f'muzzle {head_spot(BARREL_MUZZLE, BARREL, barrel_size[0])}; '
                         f'{barrel.width}x{barrel.height}, {barrel_size[0]:.1f} x {barrel_size[1]:.1f} units',
         barrel),
        ('sweeper', f'turret head 2: four level barrels pointing left; socket '
                    f'{fmt(socket("sweeper", SWEEPER, sweeper_size[0]))}, muzzles '
                    + '; '.join(head_spot(p, SWEEPER, sweeper_size[0]) for p in SWEEPER_MUZZLES)
                    + f'; {sweeper.width}x{sweeper.height}, {sweeper_size[0]:.1f} x {sweeper_size[1]:.1f} units',
         sweeper),
        ('sweeperHeat', f'the sweeper\'s barrels in white, the body clear; tinted red and blended over '
                        f'sweeper as the warning; same frame as sweeper', heat),
        ('bunker', f'turret head 3 without its lid: an armoured dome, the hatch open on top, two low barrels '
                   f'pointing right (backward); socket {fmt(socket("bunker", BUNKER, bunker_size[0]))}, muzzles '
                   + '; '.join(head_spot(p, BUNKER, bunker_size[0]) for p in BUNKER_MUZZLES)
                   + f'; {bunker.width}x{bunker.height}, {bunker_size[0]:.1f} x {bunker_size[1]:.1f} units',
         bunker),
        ('bunkerLid', f'the bunker\'s hatch lid standing open, in the bunker\'s frame; turned about the hinge '
                      f'{head_spot(LID_HINGE, BUNKER, bunker_size[0])} by {LID_OPEN_DEGREES:.0f} degrees '
                      f'counter-clockwise and moved {fmt(LID_SHUT_SHIFT)} units it lies shut over the '
                      f'opening', lid),
    ]

    sprites, offset, blobs = [], 0, []
    for name, what, image in entries:
        data = png_bytes(image)
        sprites.append({'name': name, 'description': what, 'offset': offset, 'size': len(data)})
        offset += len(data)
        blobs.append(data)
        print('%-12s %4dx%-4d %s' % (name, image.width, image.height, what[:90]))
    manifest = json.dumps({'id': 'tek-machine', 'description': description, 'sprites': sprites,
                           'sequences': []}, indent=2, ensure_ascii=False).encode('utf-8')
    with open(set_path, 'wb') as out:
        out.write(b'MSET' + struct.pack('<HI', 1, len(manifest)) + manifest)
        for data in blobs:
            out.write(data)
    print(description)
    print(f'{len(sprites)} sprites, {10 + len(manifest) + offset} bytes -> {set_path}')


if __name__ == '__main__':
    if len(sys.argv) == 4 and sys.argv[1] == 'build':
        build(sys.argv[2], sys.argv[3])
    else:
        sys.exit(__doc__)
