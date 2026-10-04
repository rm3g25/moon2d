"""Builds bin/sprites/ventilation.mset - the art of the "fan" dynamic object
(TFan in Core/Levels.Dynamics.pas) - from two generated pictures: a rotor
seen from the front in flat light, and the guard that stands in front of it.

    python build_fans.py measure rotor.png guard.png
    python build_fans.py build rotor.png guard.png ../../bin/sprites/ventilation.mset

What the game expects of a fan picture:
- a square with the rotation axis at its center, in four sides (SIDES),
  named <picture>-<side>;
- a rotor painted turning counterclockwise (the blade tips trail), in three
  states of blur: rotor-<name>, rotor-<name>-smear, rotor-<name>-disc;
- a guard, guard-<name>, that carries its own cast shadow: it never turns,
  so the shadow is baked into the same picture;
- the guard ring at RING_SHARE of the half-side and the blade tips under it:
  the margin keeps the ring clear of the border down to 64 px.

The source pictures are not kept in the repository. The numbers under
"measured" belong to the two pictures this set was built from; `measure`
prints them for a new pair. Needs numpy, scipy and Pillow.
"""
import io
import json
import struct
import sys

import numpy as np
from PIL import Image
from scipy import ndimage, optimize

MASTER = 1024
HALF = MASTER / 2
SIDES = (512, 256, 128, 64)

# measured on the sources (1254x1254)
ROTOR_HUB = (626.5, 623.9)
ROTOR_MAX_TIP = 638.0
GUARD_CENTRE = (625.6, 621.5)
GUARD_OUTER = 613.9
GUARD_INNER_MIN = 528.0

# The ring is not a perfect circle: its widest point is 1.2% past the mean
RING_SHARE = 0.955
TIP_SHARE = 0.9065

SMEAR_ARC = 24.0
SMEAR_STEPS = 97
TORN_BLADE_AT = 45  # degrees clockwise from the right: the blade to tear off

PICTURES = [
    ('rotor-heavy', 'heavy five-blade rotor, one blade tipped hazard yellow; painted turning counterclockwise, in flat light'),
    ('rotor-heavy-smear', 'rotor-heavy smeared 24 degrees along its turn: what shows between sharp blades and the disc'),
    ('rotor-heavy-disc', 'rotor-heavy averaged over a whole turn: the blur disc of a fast fan'),
    ('rotor-heavy-torn', 'rotor-heavy with one blade torn off past its bracket'),
    ('rotor-heavy-torn-smear', 'rotor-heavy-torn smeared 24 degrees along its turn'),
    ('rotor-heavy-torn-disc', 'rotor-heavy-torn averaged over a whole turn'),
    ('guard-spider', 'the standing guard over a rotor: shroud ring, four struts, motor cap; lit from above, with its own cast shadow and the shade of the recess under it'),
]
SET_DESCRIPTION = (
    'Fans for the "fan" dynamic object, declared by levels in "objectSets". Every sprite is a square '
    'with the rotation axis at its center, and every picture comes in four sides - 512, 256, 128 and '
    '64 px - named <picture>-<side>; a fan takes the smallest that is as dense as the backdrops. '
    'A rotor is rotor-<name>, rotor-<name>-smear and rotor-<name>-disc; a guard is guard-<name>. '
    'In the square, the guard ring reaches 95.5% of the half-side on average and 96.5% at its widest, and '
    'the blade tips 90.6%, under the ring; '
    'the margin keeps the ring clear of the border down to 64 px.')


# --- pictures as float32 premultiplied RGBA, 0..1 ---------------------------

def load_premult(path):
    pixels = np.asarray(Image.open(path).convert('RGBA')).astype(np.float32)
    # generated alpha is dirty at both ends: opaque 249..253, clear 0..7
    alpha = np.clip((pixels[..., 3] - 8) / (249 - 8), 0, 1)
    return np.dstack([pixels[..., :3] / 255 * alpha[..., None], alpha])


def place(source, centre, scale):
    """The source recentred on `centre` and scaled into the master square."""
    ys, xs = np.mgrid[0:MASTER, 0:MASTER].astype(np.float32)
    sx = centre[0] + (xs + 0.5 - HALF) / scale - 0.5
    sy = centre[1] + (ys + 0.5 - HALF) / scale - 0.5
    sigma = max(0.0, 0.5 * (1 / scale - 1))
    out = np.zeros((MASTER, MASTER, 4), np.float32)
    for channel in range(4):
        plane = ndimage.gaussian_filter(source[..., channel], sigma) if sigma > 0 else source[..., channel]
        out[..., channel] = ndimage.map_coordinates(plane, [sy, sx], order=1, mode='constant')
    return out


def rotate(picture, degrees_clockwise):
    turn = np.radians(degrees_clockwise)
    cos, sin = np.cos(turn), np.sin(turn)
    ys, xs = np.mgrid[0:MASTER, 0:MASTER].astype(np.float32)
    dx = xs + 0.5 - HALF
    dy = ys + 0.5 - HALF
    sx = HALF + cos * dx + sin * dy - 0.5
    sy = HALF - sin * dx + cos * dy - 0.5
    return np.dstack([ndimage.map_coordinates(picture[..., k], [sy, sx], order=1, mode='constant')
                      for k in range(4)])


def over(top, bottom):
    return top + bottom * (1 - top[..., 3:4])


def shrink(premult, side):
    """Lanczos in premultiplied alpha, then the edge colour bled outward:
    a linear filter mixes a silhouette pixel with its clear neighbour, and
    a black neighbour would leave a dark fringe."""
    small = np.dstack([np.asarray(Image.fromarray(premult[..., k], 'F').resize((side, side), Image.LANCZOS))
                       for k in range(4)])
    alpha = np.clip(small[..., 3], 0, 1)
    alpha8 = (alpha * 255 + 0.5).astype(np.uint8)
    colour = np.where(alpha[..., None] > 1e-3, small[..., :3] / np.maximum(alpha[..., None], 1e-3), 0)
    colour8 = (np.clip(colour, 0, 1) * 255 + 0.5).astype(np.uint8)
    painted = alpha8 > 0
    if painted.any() and not painted.all():
        nearest = ndimage.distance_transform_edt(~painted, return_distances=False, return_indices=True)
        colour8 = colour8[nearest[0], nearest[1]]
    return Image.fromarray(np.dstack([colour8, alpha8]), 'RGBA')


def polar_coords():
    ys, xs = np.mgrid[0:MASTER, 0:MASTER].astype(np.float32)
    dx = xs + 0.5 - HALF
    dy = ys + 0.5 - HALF
    return np.hypot(dx, dy), np.degrees(np.arctan2(dy, dx))


# --- the layers -------------------------------------------------------------

def smear(rotor):
    total = np.zeros_like(rotor)
    for step in range(SMEAR_STEPS):
        total += rotate(rotor, -SMEAR_ARC / 2 + SMEAR_ARC * step / (SMEAR_STEPS - 1))
    return total / SMEAR_STEPS


def disc(rotor):
    """The rotor averaged over a whole turn: the same from every angle."""
    radius, _ = polar_coords()
    angles = np.linspace(0, 2 * np.pi, 1440, endpoint=False)
    radii = np.arange(0, int(HALF * 1.42) + 2, dtype=np.float32)
    rr, aa = np.meshgrid(radii, angles)
    sx = HALF + rr * np.cos(aa) - 0.5
    sy = HALF + rr * np.sin(aa) - 0.5
    out = np.zeros_like(rotor)
    for channel in range(4):
        profile = ndimage.map_coordinates(rotor[..., channel], [sy, sx], order=1, mode='constant').mean(axis=0)
        out[..., channel] = np.interp(radius, radii, profile)
    return out


def tear_blade(rotor, toward_degrees, seed=7):
    """One blade torn off past its bracket: a ragged stub stays on the hub."""
    radius, angle = polar_coords()
    blades, count = ndimage.label((rotor[..., 3] > 0.5) & (radius > 215))
    best, best_gap = None, 1e9
    for index in range(1, count + 1):
        mask = blades == index
        if mask.sum() < 2000:
            continue
        cy, cx = ndimage.center_of_mass(mask)
        gap = abs((np.degrees(np.arctan2(cy - HALF, cx - HALF)) - toward_degrees + 180) % 360 - 180)
        if gap < best_gap:
            best, best_gap = mask, gap
    blade = ndimage.binary_dilation(best, iterations=4)
    dice = np.random.default_rng(seed)
    knots = np.linspace(-180, 180, 73)
    ragged = 232 + dice.uniform(-14, 22, knots.size)
    ragged[-1] = ragged[0]
    tear_at = np.interp(angle, knots, ragged)
    gone = blade & (radius > tear_at)
    torn = rotor * ndimage.gaussian_filter(1 - gone.astype(np.float32), 0.7)[..., None]
    # bare metal along the break
    lip = blade & (radius > tear_at - 5) & (radius <= tear_at)
    lip = ndimage.gaussian_filter(lip.astype(np.float32), 0.8)[..., None] * 0.4
    bare = np.array([0.55, 0.50, 0.44], np.float32)
    torn[..., :3] = torn[..., :3] * (1 - lip) + bare * torn[..., 3:4] * lip
    return torn


def guard_with_shadow(guard, opening_radius, ring_radius):
    """The guard over what it does to the rotor behind it: its own cast
    shadow, and the shade of a part that sits back in its housing. The
    shadow stays inside the ring: past it the square's edge would cut it."""
    radius, _ = polar_coords()
    shifted = ndimage.shift(guard[..., 3], (9, 5), order=1, mode='constant')
    cast = ndimage.gaussian_filter(shifted, 5.0) * 0.55
    cast *= np.clip((ring_radius - 4 - radius) / 4, 0, 1)
    ys = np.mgrid[0:MASTER, 0:MASTER][0].astype(np.float32)
    top = HALF - opening_radius
    recess = np.clip(1 - (ys - top) / (0.9 * opening_radius), 0, 1) ** 1.5 * 0.38
    recess *= np.clip((opening_radius - radius) / 3, 0, 1)
    shade = np.zeros_like(guard)
    shade[..., 3] = np.clip(1 - (1 - cast) * (1 - recess), 0, 1)
    return over(guard, shade)


# --- the set ----------------------------------------------------------------

def build(rotor_path, guard_path, set_path):
    guard_scale = RING_SHARE * HALF / GUARD_OUTER
    rotor_scale = TIP_SHARE * HALF / ROTOR_MAX_TIP
    rotor = place(load_premult(rotor_path), ROTOR_HUB, rotor_scale)
    guard = place(load_premult(guard_path), GUARD_CENTRE, guard_scale)
    sheets = {
        'rotor-heavy': rotor,
        'rotor-heavy-torn': tear_blade(rotor, TORN_BLADE_AT),
        'guard-spider': guard_with_shadow(guard, GUARD_INNER_MIN * guard_scale, RING_SHARE * HALF),
    }
    for name in ('rotor-heavy', 'rotor-heavy-torn'):
        sheets[name + '-smear'] = smear(sheets[name])
        sheets[name + '-disc'] = disc(sheets[name])

    sprites, blobs, offset = [], [], 0
    for name, what in PICTURES:
        for side in SIDES:
            buffer = io.BytesIO()
            shrink(sheets[name], side).save(buffer, 'PNG', optimize=True)
            data = buffer.getvalue()
            sprites.append({'name': f'{name}-{side}', 'description': f'{what}; {side}x{side}',
                            'offset': offset, 'size': len(data)})
            blobs.append(data)
            offset += len(data)
    manifest = json.dumps({'id': 'ventilation', 'description': SET_DESCRIPTION, 'sprites': sprites,
                           'sequences': []}, indent=2, ensure_ascii=False).encode('utf-8')
    with open(set_path, 'wb') as out:
        out.write(b'MSET' + struct.pack('<HI', 1, len(manifest)) + manifest + b''.join(blobs))
    print(f'{len(sprites)} sprites, {10 + len(manifest) + offset} bytes -> {set_path}')


# --- measuring a new pair ---------------------------------------------------

def outer_radii(mask, cx, cy, angles=360):
    reach = np.arange(0, 900, 0.5)
    out = []
    for k in range(angles):
        turn = 2 * np.pi * k / angles
        xs = cx + reach * np.cos(turn)
        ys = cy + reach * np.sin(turn)
        inside = (xs >= 0) & (xs < mask.shape[1] - 1) & (ys >= 0) & (ys < mask.shape[0] - 1)
        hit = np.zeros(reach.shape, bool)
        hit[inside] = mask[ys[inside].astype(int), xs[inside].astype(int)]
        found = np.nonzero(hit)[0]
        out.append(reach[found[-1]] if len(found) else 0)
    return np.array(out)


def measure(rotor_path, guard_path):
    guard = np.asarray(Image.open(guard_path).convert('RGBA'))[..., 3] > 128
    cy, cx = ndimage.center_of_mass(guard)
    fit = optimize.minimize(lambda p: outer_radii(guard, p[0], p[1], 180).std(), [cx, cy],
                            method='Nelder-Mead', options={'xatol': 0.05, 'fatol': 0.01})
    radii = outer_radii(guard, fit.x[0], fit.x[1])
    print('guard centre %.1f %.1f, outer radius mean %.1f (min %.1f, max %.1f)'
          % (fit.x[0], fit.x[1], radii.mean(), radii.min(), radii.max()))

    rotor = np.asarray(Image.open(rotor_path).convert('RGBA')).astype(np.float32)
    light = rotor[..., :3].mean(axis=2)

    # The hub is concentric circles: their edges are crispest in the profile
    # along the radius when the profile is taken from the true axis
    def hub_blur(point):
        radii_, angles_ = np.meshgrid(np.arange(40, 135, 1.0), np.linspace(0, 2 * np.pi, 360, endpoint=False))
        ring = ndimage.map_coordinates(light, [point[1] + radii_ * np.sin(angles_),
                                               point[0] + radii_ * np.cos(angles_)], order=1)
        return -np.abs(np.diff(ring.mean(axis=0))).sum()

    cy, cx = ndimage.center_of_mass(rotor[..., 3] > 128)
    start = min(((hub_blur((x, y)), x, y) for x in np.arange(cx - 24, cx + 25, 3)
                 for y in np.arange(cy - 24, cy + 25, 3)))
    hub = optimize.minimize(hub_blur, [start[1], start[2]], method='Nelder-Mead', options={'xatol': 0.1}).x
    tips = outer_radii(rotor[..., 3] > 128, hub[0], hub[1], 720)
    print('rotor hub %.1f %.1f, farthest blade tip %.1f' % (hub[0], hub[1], tips.max()))


if __name__ == '__main__':
    if len(sys.argv) == 4 and sys.argv[1] == 'measure':
        measure(sys.argv[2], sys.argv[3])
    elif len(sys.argv) == 5 and sys.argv[1] == 'build':
        build(sys.argv[2], sys.argv[3], sys.argv[4])
    else:
        sys.exit(__doc__)
