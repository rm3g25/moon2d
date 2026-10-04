"""Builds bin/sprites/ventilation.mset - the art of the "fan" dynamic object
(TFan in Core/Levels.Dynamics.pas) - from generated pictures: rotors seen
from the front in flat light, the guards that stand in front of them, and a
blind louver panel.

    python build_fans.py measure rotor.png guard.png
    python build_fans.py build <sources dir> ../../bin/sprites/ventilation.mset

What the game expects of a fan picture:
- a square with the rotation axis at its center, in four sides (SIDES),
  named <picture>-<side>;
- a rotor painted turning counterclockwise (the blade tips trail, leaning
  clockwise), in three states of blur: rotor-<name>, rotor-<name>-smear,
  rotor-<name>-disc; a picture generated the other way round is mirrored;
- a guard, guard-<name>, that carries its own cast shadow: it never turns,
  so the shadow is baked into the same picture;
- a round guard keeps its ring inside the square with a margin, so the
  border stays clear of it down to 64 px; a plate fills the square edge to
  edge, like a tile;
- a back, back-<name>: what shows through the guard behind the rotor.

Every rotor fits behind every guard: the blade tips end under the ring.
The louver is not a fan picture: a static object places it by name.

The source pictures are not kept in the repository; `build` looks for them
in the sources dir under the names in ROTORS, GUARDS and LOUVER_FILE. The
numbers under "measured" belong to those pictures; `measure` prints them
for a new pair. Needs numpy, scipy and Pillow.
"""
import io
import json
import os
import struct
import sys

import numpy as np
from PIL import Image
from scipy import ndimage, optimize

MASTER = 1024
HALF = MASTER / 2
SIDES = (512, 256, 128, 64)

# measured on the sources (1254x1254): the axis, the farthest blade tip
ROTORS = [
    {'name': 'heavy', 'file': 'rotor-heavy.png', 'hub': (626.5, 623.9), 'max_tip': 638.0,
     'tip_share': 0.9065, 'mirror': False, 'smear_arc': 24.0, 'torn_blade_at': 45},
    # generated leaning the other way: mirrored
    {'name': 'turbine', 'file': 'rotor-turbine.png', 'hub': (625.9, 625.7), 'max_tip': 615.5,
     'tip_share': 0.88, 'mirror': True, 'smear_arc': 14.0, 'torn_blade_at': None},
]
# measured on the sources: the axis; `reach` source pixels from it land at
# `share` of the half-side; `opening` is the radius the rotor shows within
GUARDS = [
    # The ring is not a perfect circle: its widest point is 1.2% past the
    # mean radius, which is the reach here
    {'name': 'spider', 'file': 'guard-spider.png', 'centre': (625.6, 621.5), 'reach': 613.9,
     'share': 0.955, 'opening': 528.0, 'plate': False},
    # The opening sits 13 px above the middle of the plate: the square is
    # cut around the axis, just short of the nearest edge of the plate
    {'name': 'bezel', 'file': 'guard-bezel.png', 'centre': (624.8, 611.1), 'reach': 602.0,
     'share': 1.0, 'opening': 496.2, 'plate': True},
]
LOUVER_FILE = 'louver.png'
LOUVER_SIZE = (256, 128)

SMEAR_STEPS = 97

PICTURES = [
    ('rotor-heavy', 'heavy five-blade rotor, one blade tipped hazard yellow; painted turning counterclockwise, in flat light'),
    ('rotor-heavy-smear', 'rotor-heavy smeared 24 degrees along its turn: what shows between sharp blades and the disc'),
    ('rotor-heavy-disc', 'rotor-heavy averaged over a whole turn: the blur disc of a fast fan'),
    ('rotor-heavy-torn', 'rotor-heavy with one blade torn off past its bracket'),
    ('rotor-heavy-torn-smear', 'rotor-heavy-torn smeared 24 degrees along its turn'),
    ('rotor-heavy-torn-disc', 'rotor-heavy-torn averaged over a whole turn'),
    ('guard-spider', 'the standing guard over a rotor: shroud ring, four struts, motor cap; lit from above, with its own cast shadow and the shade of the recess under it'),
    ('rotor-turbine', 'eight-blade exhaust rotor, one blade tipped hazard yellow; mirrored to turn counterclockwise, in flat light'),
    ('rotor-turbine-smear', 'rotor-turbine smeared 14 degrees along its turn'),
    ('rotor-turbine-disc', 'rotor-turbine averaged over a whole turn'),
    ('guard-bezel', 'a square wall plate with a round opening under two rings and a cross of bars; fills the square edge to edge, with its own cast shadow and the shade of the recess in the opening'),
    ('back-shaft', 'the dark of the shaft behind a rotor, a faint rim of light low in the well; goes under a guard that covers its corners'),
]
SET_DESCRIPTION = (
    'Fans for the "fan" dynamic object, declared by levels in "objectSets". Every fan sprite is a square '
    'with the rotation axis at its center, and every picture comes in four sides - 512, 256, 128 and '
    '64 px - named <picture>-<side>; a fan takes the smallest that is as dense as the backdrops. '
    'A rotor is rotor-<name>, rotor-<name>-smear and rotor-<name>-disc; a guard is guard-<name>; a back is '
    'back-<name>. The spider ring reaches 95.5% of the half-side on average and 96.5% at its widest, with a '
    'margin that keeps it clear of the border down to 64 px; the bezel plate fills the square. Blade tips end '
    'under the ring of either guard: 90.6% of the half-side for the heavy rotor, 88% for the turbine. '
    'louver-2x1 is a plain picture for a static object: a blind louver panel, two cells by one.')
LOUVER_DESCRIPTION = 'blind louver panel in a bolted frame, for a static object; 256x128, 64 by 32 units'


# --- pictures as float32 premultiplied RGBA, 0..1 ---------------------------

def load_premult(path):
    pixels = np.asarray(Image.open(path).convert('RGBA')).astype(np.float32)
    # generated alpha is dirty at both ends: opaque 249..253, clear 0..7
    alpha = np.clip((pixels[..., 3] - 8) / (249 - 8), 0, 1)
    return np.dstack([pixels[..., :3] / 255 * alpha[..., None], alpha])


def place(source, centre, scale, mirror=False):
    """The source recentred on `centre` and scaled into the master square."""
    ys, xs = np.mgrid[0:MASTER, 0:MASTER].astype(np.float32)
    across = (xs + 0.5 - HALF) / scale
    if mirror:
        across = -across
    sx = centre[0] + across - 0.5
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

def smear(rotor, arc):
    total = np.zeros_like(rotor)
    for step in range(SMEAR_STEPS):
        total += rotate(rotor, -arc / 2 + arc * step / (SMEAR_STEPS - 1))
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


def seam_plate(plate, opening_radius):
    """A plate fills its square like a tile: whatever the picture left
    clear outside the opening - a groove, the antialiased edge the cut
    runs along - goes black instead of showing the wall behind. The cut
    around the axis also took the bevel of the edges it went through: a
    dark seam along the border stands in for it."""
    radius, _ = polar_coords()
    ys, xs = np.mgrid[0:MASTER, 0:MASTER].astype(np.float32)
    to_border = np.minimum(np.minimum(xs, MASTER - 1 - xs), np.minimum(ys, MASTER - 1 - ys))
    keep = 0.5 + 0.5 * np.clip(to_border / 9, 0, 1)
    out = plate.copy()
    out[..., :3] *= keep[..., None]
    solid = np.clip((radius - opening_radius - 6) / 4, 0, 1)
    out[..., 3] = np.maximum(out[..., 3], solid)
    return out


def shaft(opening_radius):
    """The dark behind a rotor. Light from above reaches the lower lip of
    the well and nothing deeper."""
    radius, angle = polar_coords()
    rim = np.exp(-((radius - (opening_radius - 14)) / 9) ** 2)
    low = np.clip(np.sin(np.radians(angle)), 0, 1) ** 2
    glint = (rim * low * 0.07)[..., None]
    out = np.zeros((MASTER, MASTER, 4), np.float32)
    out[..., :3] = np.array([0.020, 0.020, 0.026], np.float32) + glint * np.array([1.0, 0.95, 0.9], np.float32)
    out[..., 3] = 1
    return out


# --- the set ----------------------------------------------------------------

def fan_sheets(source_dir):
    sheets = {}
    for rotor in ROTORS:
        scale = rotor['tip_share'] * HALF / rotor['max_tip']
        base = 'rotor-' + rotor['name']
        whole = place(load_premult(os.path.join(source_dir, rotor['file'])), rotor['hub'], scale, rotor['mirror'])
        states = {base: whole}
        if rotor['torn_blade_at'] is not None:
            states[base + '-torn'] = tear_blade(whole, rotor['torn_blade_at'])
        for name, state in states.items():
            sheets[name] = state
            sheets[name + '-smear'] = smear(state, rotor['smear_arc'])
            sheets[name + '-disc'] = disc(state)
    for guard in GUARDS:
        scale = guard['share'] * HALF / guard['reach']
        placed = place(load_premult(os.path.join(source_dir, guard['file'])), guard['centre'], scale)
        opening = guard['opening'] * scale
        if guard['plate']:
            # the plate covers whatever shadow falls outside the opening
            sheets['guard-' + guard['name']] = guard_with_shadow(seam_plate(placed, opening), opening, MASTER)
            sheets['back-shaft'] = shaft(opening)
        else:
            sheets['guard-' + guard['name']] = guard_with_shadow(placed, opening, guard['share'] * HALF)
    return sheets


def png_bytes(image):
    buffer = io.BytesIO()
    image.save(buffer, 'PNG', optimize=True)
    return buffer.getvalue()


def build(source_dir, set_path):
    sheets = fan_sheets(source_dir)
    entries = []
    for name, what in PICTURES:
        for side in SIDES:
            entries.append((f'{name}-{side}', f'{what}; {side}x{side}', png_bytes(shrink(sheets[name], side))))
    louver = Image.open(os.path.join(source_dir, LOUVER_FILE)).convert('RGB').resize(LOUVER_SIZE, Image.LANCZOS)
    entries.append(('louver-2x1', LOUVER_DESCRIPTION, png_bytes(louver)))

    sprites, offset = [], 0
    for name, description, data in entries:
        sprites.append({'name': name, 'description': description, 'offset': offset, 'size': len(data)})
        offset += len(data)
    manifest = json.dumps({'id': 'ventilation', 'description': SET_DESCRIPTION, 'sprites': sprites,
                           'sequences': []}, indent=2, ensure_ascii=False).encode('utf-8')
    with open(set_path, 'wb') as out:
        out.write(b'MSET' + struct.pack('<HI', 1, len(manifest)) + manifest)
        for _, _, data in entries:
            out.write(data)
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


def inner_radii(mask, cx, cy, start, angles=360):
    """Where each ray that leaves the hub in the clear meets the ring. A
    ray along a strut never is in the clear and is left out."""
    reach = np.arange(start, 900, 0.5)
    out = []
    for k in range(angles):
        turn = 2 * np.pi * k / angles
        xs = cx + reach * np.cos(turn)
        ys = cy + reach * np.sin(turn)
        inside = (xs >= 0) & (xs < mask.shape[1] - 1) & (ys >= 0) & (ys < mask.shape[0] - 1)
        hit = np.zeros(reach.shape, bool)
        hit[inside] = mask[ys[inside].astype(int), xs[inside].astype(int)]
        if hit[0] or not hit.any():
            continue
        out.append(reach[np.nonzero(hit)[0][0]])
    return np.array(out)


def blade_lean(mask, hub, from_radius=330, to_radius=560):
    """How far each blade's middle turns on the way out, in degrees
    clockwise on the screen. Above zero the tips trail a counterclockwise
    turn - the way the game wants a rotor; below zero the picture needs
    the mirror."""
    angles = np.linspace(0, 2 * np.pi, 2880, endpoint=False)

    def middles(radius):
        hit = mask[(hub[1] + radius * np.sin(angles)).astype(int), (hub[0] + radius * np.cos(angles)).astype(int)]
        blades, count = ndimage.label(hit)
        if hit[0] and hit[-1] and count > 1:
            blades[blades == count] = 1
            count -= 1
        return [np.degrees(np.arctan2(np.sin(angles[blades == k]).mean(), np.cos(angles[blades == k]).mean()))
                for k in range(1, count + 1)]

    current = middles(from_radius)
    gained = np.zeros(len(current))
    for radius in range(from_radius + 5, to_radius + 1, 5):
        following = middles(radius)
        if len(following) != len(current):
            return None
        for k, middle in enumerate(current):
            steps = [(other - middle + 180) % 360 - 180 for other in following]
            nearest = int(np.argmin(np.abs(steps)))
            gained[k] += steps[nearest]
            current[k] = following[nearest]
    return gained


def opening_fit(mask, start):
    """The axis of a plate's opening: the point from which the first edge
    met on the way out lies at the same distance in every direction. The
    bars of a cross are skipped."""
    turns = [np.radians(d) for d in range(0, 360, 3) if min(d % 90, 90 - d % 90) > 12]
    reach = np.arange(100, 700, 0.5)

    def edges(centre, turn):
        xs = centre[0] + reach * np.cos(turn)
        ys = centre[1] + reach * np.sin(turn)
        inside = (xs >= 0) & (xs < mask.shape[1] - 1) & (ys >= 0) & (ys < mask.shape[0] - 1)
        hit = np.zeros(reach.shape, bool)
        hit[inside] = mask[ys[inside].astype(int), xs[inside].astype(int)]
        return [reach[k + 1] for k in np.nonzero(np.diff(hit.astype(int)))[0]]

    def first_edges(centre):
        return np.array([found[0] for found in (edges(centre, turn) for turn in turns) if found])

    centre = optimize.minimize(lambda c: first_edges(c).std(), start, method='Nelder-Mead',
                               options={'xatol': 0.05, 'fatol': 0.01}).x
    rings = [edges(centre, turn) for turn in turns]
    return centre, [float(np.mean([ring[k] for ring in rings if len(ring) > k])) for k in range(3)]


def measure(rotor_path, guard_path):
    rotor = np.asarray(Image.open(rotor_path).convert('RGBA')).astype(np.float32)
    light = rotor[..., :3].mean(axis=2)
    blades = rotor[..., 3] > 128

    # The hub is concentric circles: their edges are crispest in the profile
    # along the radius when the profile is taken from the true axis
    def hub_blur(point):
        radii_, angles_ = np.meshgrid(np.arange(40, 135, 1.0), np.linspace(0, 2 * np.pi, 360, endpoint=False))
        ring = ndimage.map_coordinates(light, [point[1] + radii_ * np.sin(angles_),
                                               point[0] + radii_ * np.cos(angles_)], order=1)
        return -np.abs(np.diff(ring.mean(axis=0))).sum()

    cy, cx = ndimage.center_of_mass(blades)
    start = min(((hub_blur((x, y)), x, y) for x in np.arange(cx - 24, cx + 25, 3)
                 for y in np.arange(cy - 24, cy + 25, 3)))
    hub = optimize.minimize(hub_blur, [start[1], start[2]], method='Nelder-Mead', options={'xatol': 0.1}).x
    tips = outer_radii(blades, hub[0], hub[1], 720)
    print('rotor hub %.1f %.1f, farthest blade tip %.1f' % (hub[0], hub[1], tips.max()))
    lean = blade_lean(blades, hub)
    if lean is not None:
        print('rotor blades %d, tips lean %.1f degrees clockwise on average: %s'
              % (len(lean), lean.mean(), 'as the game wants' if lean.mean() > 0 else 'mirror it'))

    guard = np.asarray(Image.open(guard_path).convert('RGBA'))[..., 3] > 128
    cy, cx = ndimage.center_of_mass(guard)
    fit = optimize.minimize(lambda p: outer_radii(guard, p[0], p[1], 180).std(), [cx, cy],
                            method='Nelder-Mead', options={'xatol': 0.05, 'fatol': 0.01})
    radii = outer_radii(guard, fit.x[0], fit.x[1])
    inner = inner_radii(guard, fit.x[0], fit.x[1], 0.6 * radii.mean())
    print('guard as a ring: centre %.1f %.1f, outer radius mean %.1f (min %.1f, max %.1f), '
          'inner edge %.1f at its nearest'
          % (fit.x[0], fit.x[1], radii.mean(), radii.min(), radii.max(), inner.min()))
    centre, rings = opening_fit(guard, [cx, cy])
    ys, xs = np.nonzero(guard)
    print('guard as a plate: opening axis %.1f %.1f, edges on the way out at %.1f, %.1f, %.1f; '
          'from the axis to the plate edges: left %.1f, right %.1f, top %.1f, bottom %.1f'
          % (centre[0], centre[1], rings[0], rings[1], rings[2],
             centre[0] - xs.min(), xs.max() - centre[0], centre[1] - ys.min(), ys.max() - centre[1]))


if __name__ == '__main__':
    if len(sys.argv) == 4 and sys.argv[1] == 'measure':
        measure(sys.argv[2], sys.argv[3])
    elif len(sys.argv) == 4 and sys.argv[1] == 'build':
        build(sys.argv[2], sys.argv[3])
    else:
        sys.exit(__doc__)
