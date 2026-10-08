"""Builds bin/sprites/cordon.mset - the art of the TEK-Q6 cordon, the
orbital quarantine machine that flies over level 1 screen 9 and is the boss
of level 6 - from four generated pictures and the iris of the level-1 boss.

    python build_cordon.py build <sources dir> ../../bin/sprites/cordon.mset

What comes out:
- hull: the lower hull, two generated sections joined at a structural rib.
  The ends and the top are straight cuts - the game never shows them. Kept
  at the density it was generated at (HULL_DENSITY): stretched to 6 px a
  unit it would be 9500 px wide and no sharper;
- eye: the sensor turret, its lens glass empty;
- iris: the iris of the level-1 boss (boss1-disc.mset), cut out and grown -
  the same eye family; slides inside the glass toward its target;
- turretMount, turretGun: a gun turret in two parts; the gun turns on its
  pivot by code, the mount stands still and is drawn over it.

The eye, the iris and the turret are at DENSITY, 6 px a unit, the rule for
the new art of the machines (see tools/tank/build_tank.py). They are to be
redrawn before the fight on level 6; the hull stays.

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
HULL_DENSITY = 2.6

EYE_UNITS = 66      # the eye's width
TURRET_UNITS = 46   # the mount's width; the gun is drawn at the same scale
IRIS_SHARE = 0.75   # of the glass across, as on the level-1 boss

SCAN_FILE = 'cordon-scan.png'
CARGO_FILE = 'cordon-cargo.png'
EYE_FILE = 'cordon-eye.png'
TURRET_FILE = 'cordon-turret.png'
BOSS_SET = 'boss1-disc.mset'

# --- measured on the hull sections (2172x724 each) ------------------------
# The scan section is cut just before its rib, the cargo section starts at
# the left edge of its own: one rib, the cargo's, makes the joint
SCAN_CUT = 2045
CARGO_RIB_LEFT = 45
# The scan section was generated 13 px higher: its keel at 395, the
# cargo's at 408. The keel is what the eye follows, so the keels meet; the
# tops then differ by 5 px, above the screen.
SCAN_DROP = 13
HULL_ROWS = (150, 566)        # the joined strip, the rib top to the doors
HULL_TOP_LINE = 177           # the top edge of the plating, cargo rows
KEEL_LINE = 408               # the seam the hull blocks hang from
BAY_CENTRE = 1447             # cargo x: the hazard bar over the bay, 1218..1676
BAY_MOUTH = 505               # cargo row: the bay's floor, where a load comes out
BAY_DOORS_BOTTOM = 562        # cargo row: the lowest point of the hull
# Where the eye hangs: under the keel blocks of the cargo section, 232
# units left of the bay - the hero's ledge when the bay is over the dock
EYE_MOUNT = (844, 440)        # cargo px: the flange's top center
# The flat plates left where the generated turrets were, scan px: their
# bottom centers. The widest one held the eye and stays free.
TURRET_PLATES = ((1281, 484), (1553, 484))
FREE_PLATE = (684, 482)

# --- measured on the eye (1254x1254) ---------------------------------------
EYE_BOX = (28, 56, 1227, 1194)
LENS_CENTRE = (622.0, 691.5)  # the glass's bounding box, 411..833 x 483..900
LENS_RADIUS = 209.0
SIDE_LENSES = ((95.0, 677.5), (1160.0, 677.5))

# --- measured on the turret (1254x1254): two parts, a clear gap between ----
TURRET_SPLIT = 470
MOUNT_BOX = (96, 28, 1160, 456)
GUN_BOX = (314, 486, 940, 1225)
# The gun's hub (283 px across, rows 486..560) seats in the mount's socket
# (281 px across, its bottom at 452): moved up so its top is 12 px inside
GUN_RISE = 46
PIVOT = (627.0, 523.0)        # the hub's center, gun rows as generated
MUZZLES = ((518.5, 1219.0), (731.5, 1219.0))

# --- measured on boss1-disc.mset 'iris' (144x144): the iris itself --------
IRIS_BOX = (62, 62, 83, 83)


# --- pictures as float32 premultiplied RGBA, 0..1 ---------------------------

def load_premult(path):
    pixels = np.asarray(Image.open(path).convert('RGBA')).astype(np.float32)
    return premult(pixels)


def premult(pixels):
    # generated alpha is dirty at both ends: opaque 249..253, clear 0..8;
    # and a haze of faint pixels floats away from the body - cut off
    alpha = np.clip((pixels[..., 3] - 8) / (249 - 8), 0, 1)
    alpha *= ndimage.binary_dilation(alpha > 0.5, iterations=4)
    return np.dstack([pixels[..., :3] / 255 * alpha[..., None], alpha])


def resize(premult_picture, size):
    """Lanczos in premultiplied alpha, then the edge colour bled outward:
    a linear filter mixes a silhouette pixel with its clear neighbour, and
    a black neighbour would leave a dark fringe."""
    small = np.dstack([np.asarray(Image.fromarray(np.ascontiguousarray(premult_picture[..., k]), 'F')
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


def crop(picture, box):
    left, top, right, bottom = box
    return picture[top:bottom, left:right]


def read_sprite(set_path, name):
    with open(set_path, 'rb') as source:
        data = source.read()
    size = struct.unpack('<I', data[6:10])[0]
    manifest = json.loads(data[10:10 + size].decode('utf-8'))
    base = 10 + size
    for sprite in manifest['sprites']:
        if sprite['name'] == name:
            return data[base + sprite['offset']:base + sprite['offset'] + sprite['size']]
    raise KeyError(f'{set_path}: no sprite "{name}"')


# --- the parts ----------------------------------------------------------------

def hull_picture(source_dir):
    scan = load_premult(os.path.join(source_dir, SCAN_FILE))
    cargo = load_premult(os.path.join(source_dir, CARGO_FILE))
    shift = SCAN_CUT - CARGO_RIB_LEFT
    width = shift + cargo.shape[1]
    joined = np.zeros((cargo.shape[0] + SCAN_DROP, width, 4), np.float32)
    joined[SCAN_DROP:SCAN_DROP + scan.shape[0], :SCAN_CUT] = scan[:, :SCAN_CUT]
    joined[:cargo.shape[0], SCAN_CUT:] = cargo[:, CARGO_RIB_LEFT:]
    strip = joined[HULL_ROWS[0]:HULL_ROWS[1]]
    return resize(strip, (strip.shape[1], strip.shape[0])), shift


def eye_picture(source_dir):
    eye = crop(load_premult(os.path.join(source_dir, EYE_FILE)), EYE_BOX)
    scale = EYE_UNITS * DENSITY / eye.shape[1]
    return resize(eye, (EYE_UNITS * DENSITY, round(eye.shape[0] * scale))), scale


def iris_picture(boss_set_path, lens_units):
    data = read_sprite(boss_set_path, 'iris')
    pixels = np.asarray(Image.open(io.BytesIO(data)).convert('RGBA')).astype(np.float32)
    iris = crop(np.dstack([pixels[..., :3] / 255 * (pixels[..., 3:4] / 255), pixels[..., 3] / 255]),
                IRIS_BOX)
    units = IRIS_SHARE * 2 * lens_units
    side = round(units * DENSITY)
    return resize(iris, (side, side)), units


def turret_pictures(source_dir):
    turret = load_premult(os.path.join(source_dir, TURRET_FILE))
    scale = TURRET_UNITS * DENSITY / (MOUNT_BOX[2] - MOUNT_BOX[0])
    pictures = {}
    for name, box in (('turretMount', MOUNT_BOX), ('turretGun', GUN_BOX)):
        part = crop(turret, box)
        size = (round(part.shape[1] * scale), round(part.shape[0] * scale))
        pictures[name] = resize(part, size)
    return pictures, scale


# --- the set ------------------------------------------------------------------

def png_bytes(image):
    buffer = io.BytesIO()
    image.save(buffer, 'PNG', optimize=True)
    return buffer.getvalue()


def build(source_dir, set_path):
    hull, shift = hull_picture(source_dir)
    eye, eye_scale = eye_picture(source_dir)
    lens_units = LENS_RADIUS * eye_scale / DENSITY
    iris, iris_units = iris_picture(os.path.join(os.path.dirname(os.path.abspath(set_path)), BOSS_SET),
                                    lens_units)
    turret, turret_scale = turret_pictures(source_dir)

    def cargo_units(x, y):
        return (x + shift) / HULL_DENSITY, (y - HULL_ROWS[0]) / HULL_DENSITY

    def scan_units(x, y):
        return x / HULL_DENSITY, (y + SCAN_DROP - HULL_ROWS[0]) / HULL_DENSITY

    def eye_units(x, y):
        return (x - EYE_BOX[0]) * eye_scale / DENSITY, (y - EYE_BOX[1]) * eye_scale / DENSITY

    def mount_units(x, y):
        return (x - MOUNT_BOX[0]) * turret_scale / DENSITY, (y - MOUNT_BOX[1]) * turret_scale / DENSITY

    def gun_units(x, y):
        return (x - GUN_BOX[0]) * turret_scale / DENSITY, (y - GUN_BOX[1]) * turret_scale / DENSITY

    pair = lambda point: '%.1f, %.1f' % point
    hull_w, hull_h = hull.size[0] / HULL_DENSITY, hull.size[1] / HULL_DENSITY
    points = {
        'hull: top of the plating': (0, (HULL_TOP_LINE - HULL_ROWS[0]) / HULL_DENSITY),
        'hull: keel': (0, (KEEL_LINE - HULL_ROWS[0]) / HULL_DENSITY),
        'hull: joint, the rib\'s left edge': (SCAN_CUT / HULL_DENSITY, 0),
        'hull: bay center, its mouth': cargo_units(BAY_CENTRE, BAY_MOUTH),
        'hull: bay doors, bottom': cargo_units(BAY_CENTRE, BAY_DOORS_BOTTOM),
        'hull: eye mount': cargo_units(*EYE_MOUNT),
        'hull: turret mount 1': scan_units(*TURRET_PLATES[0]),
        'hull: turret mount 2': scan_units(*TURRET_PLATES[1]),
        'hull: free plate': scan_units(*FREE_PLATE),
        'eye: flange top center': eye_units((EYE_BOX[0] + EYE_BOX[2]) / 2, EYE_BOX[1]),
        'eye: lens center': eye_units(*LENS_CENTRE),
        'eye: side lens left': eye_units(*SIDE_LENSES[0]),
        'eye: side lens right': eye_units(*SIDE_LENSES[1]),
        'mount: gun pivot': mount_units(PIVOT[0], PIVOT[1] - GUN_RISE),
        'gun: pivot': gun_units(*PIVOT),
        'gun: muzzle left': gun_units(*MUZZLES[0]),
        'gun: muzzle right': gun_units(*MUZZLES[1]),
    }
    for name, point in points.items():
        print('%-36s %7.1f, %6.1f' % ((name,) + point))
    print('hull %d x %d px, %.1f x %.1f units; lens radius %.2f, iris %.2f units'
          % (hull.size + (hull_w, hull_h, lens_units, iris_units)))

    size_of = lambda image, density: '%dx%d px, %.1f x %.1f units' % (
        image.size + (image.size[0] / density, image.size[1] / density))
    description = (
        f'The TEK-Q6 cordon - the orbital quarantine machine of TEK: flies over level 1 screen 9 '
        f'and is the boss of level 6. Side view, flat light, built of parts placed by code; points in '
        f'screen units from the top-left corner of their own sprite. Back to front: hull, turretGun, '
        f'turretMount, eye, iris. The hull is at {HULL_DENSITY} px a unit, the rest at {DENSITY}.')
    entries = [
        ('hull', f'the lower hull, two sections joined at a rib; the ends and the top are straight cuts and '
                 f'must stay off the screen; plating top y %.1f, keel y %.1f, joint (rib\'s left edge) x %.1f; '
                 f'cargo bay center x %.1f, its mouth y %.1f, doors down to y %.1f; eye mount {pair(points["hull: eye mount"])}; '
                 f'turret mounts {pair(points["hull: turret mount 1"])} and {pair(points["hull: turret mount 2"])}; '
                 f'free plate {pair(points["hull: free plate"])}; {size_of(hull, HULL_DENSITY)}'
                 % (points['hull: top of the plating'][1], points['hull: keel'][1],
                    points['hull: joint, the rib\'s left edge'][0], points['hull: bay center, its mouth'][0],
                    points['hull: bay center, its mouth'][1], points['hull: bay doors, bottom'][1]),
         hull),
        ('eye', f'the sensor turret, hung by the flange top center {pair(points["eye: flange top center"])}; the lens glass '
                f'dark and empty, center {pair(points["eye: lens center"])}, radius %.1f; side lenses '
                f'{pair(points["eye: side lens left"])} and {pair(points["eye: side lens right"])}, unlit; '
                f'{size_of(eye, DENSITY)}' % lens_units,
         eye),
        ('iris', f'the iris of the level-1 boss, cut out of boss1-disc.mset and grown to %.1f units ({IRIS_SHARE:.2f} of '
                 f'the glass across): blades, pupil and the red sensor; drawn centered on the lens center and slid '
                 f'toward its target; {size_of(iris, DENSITY)}' % iris_units,
         iris),
        ('turretGun', f'the gun of a turret, two barrels pointing down; turns on its pivot {pair(points["gun: pivot"])}, '
                      f'the hub\'s center; muzzles {pair(points["gun: muzzle left"])} and {pair(points["gun: muzzle right"])}; '
                      f'drawn under the mount; {size_of(turret["turretGun"], DENSITY)}',
         turret['turretGun']),
        ('turretMount', f'the armored mount of a turret, hung by its top edge center; the gun\'s pivot goes to '
                        f'{pair(points["mount: gun pivot"])}; {size_of(turret["turretMount"], DENSITY)}',
         turret['turretMount']),
    ]

    sprites, offset, blobs = [], 0, []
    for name, what, image in entries:
        data = png_bytes(image)
        sprites.append({'name': name, 'description': what, 'offset': offset, 'size': len(data)})
        offset += len(data)
        blobs.append(data)
    manifest = json.dumps({'id': 'cordon', 'description': description, 'sprites': sprites,
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
