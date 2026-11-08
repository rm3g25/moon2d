"""Adds the TeK hover-barges to bin/sprites/pads.mset - the long flat
platforms of the arena 3 air phase - from one generated picture: a barge
in a flat side view, the turbine on the left, the prow on the right, five
identical bays between them, on a clear ground.

    python build_barge.py build <barge.png> ../../bin/sprites/pads.mset

The picture is cut at the middle of every rib between two bays, so every
slice carries half a rib on each side and two slices abutted make a whole
one. The barges are put together from the stern, a number of bays and the
prow, never stretched - the hexagonal armour would go oval:

- barge-5: the stern, all six bays, the prow - the whole generation, 160
  units long, five cells;
- barge-4: four bays, about four cells;
- barge-3: three bays, about three cells;
- barge-2: one bay, about two cells.

Every barge is DENSITY px a screen unit, as the pads; its length in units
is written into its description, for the level file. The top row of the
picture is the deck - the hazard stripe - so a pad placed on a line puts
its deck there.

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

DENSITY = 6
ALPHA_FLOOR = 8 / 255
ALPHA_CEILING = 250 / 255

# The whole barge is this many units long: five cells
WHOLE_UNITS = 160
# The bays each barge carries, by its name
BAYS = {'barge-5': 6, 'barge-4': 4, 'barge-3': 3, 'barge-2': 1}
# A rib - a smooth vertical strip in the band of the hexagonal armour -
# has a column deviation under this, the armour well over it
RIB_FLATNESS = 8
# The band of the armour, as shares of the body's height
BAND = (0.25, 0.65)
# The stern's junction with the first bay is a rib too, and the last bay's
# with the prow; the ribs between the six bays lie between them
LEAST_RIBS = 7


def load_premult(path):
    picture = np.asarray(Image.open(path).convert('RGBA'), dtype=np.float32) / 255
    alpha = np.clip((picture[..., 3] - ALPHA_FLOOR) / (ALPHA_CEILING - ALPHA_FLOOR), 0, 1)
    return np.dstack([picture[..., :3] * alpha[..., None], alpha])


def body_of(premult):
    rows, cols = np.where(premult[..., 3] >= 0.5)
    return premult[rows.min():rows.max() + 1, cols.min():cols.max() + 1]


def rib_cuts(body):
    """The middle column of every rib, left to right."""
    height = body.shape[0]
    band = body[int(height * BAND[0]):int(height * BAND[1]), :, :3].sum(axis=2)
    flat = band.std(axis=0) < RIB_FLATNESS / 255 * 3
    runs, start = [], None
    for x, is_flat in enumerate(flat):
        if is_flat and start is None:
            start = x
        if not is_flat and start is not None:
            runs.append((start, x - 1))
            start = None
    if start is not None:
        runs.append((start, len(flat) - 1))
    # A rib is a run of a few columns; the stern and the prow are wide
    # and smooth too, so only runs well inside the body count
    width = body.shape[1]
    ribs = [(a + b) // 2 for a, b in runs if 6 <= b - a + 1 <= 40 and width * 0.1 < a < width * 0.95]
    if len(ribs) < LEAST_RIBS:
        sys.exit(f'found {len(ribs)} ribs, need at least {LEAST_RIBS}: {runs}')
    return ribs


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


def assemble(stern, bays, prow, count):
    parts = [stern] + bays[:count] + [prow]
    return np.concatenate(parts, axis=1)


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
    body = body_of(load_premult(source))
    cuts = rib_cuts(body)
    stern = body[:, :cuts[0]]
    prow = body[:, cuts[-1]:]
    bays = [body[:, cuts[i]:cuts[i + 1]] for i in range(len(cuts) - 1)]
    print('ribs at', cuts, '- the stern %d px, %d bays of about %d px, the prow %d px'
          % (stern.shape[1], len(bays), bays[0].shape[1], prow.shape[1]))
    px_per_unit = body.shape[1] / WHOLE_UNITS

    manifest, blobs = read_set(set_path)
    manifest['sprites'] = [sprite for sprite in manifest['sprites']
                           if not sprite['name'].startswith('barge-')]
    for name, count in BAYS.items():
        whole = assemble(stern, bays, prow, count)
        units = whole.shape[1] / px_per_unit
        width = round(units * DENSITY)
        height = round(whole.shape[0] / px_per_unit * DENSITY)
        picture = shrink(whole, (width, height))
        what = ('TeK hover-barge, %d units long and %.1f high, the deck on the top row: the stern '
                'turbine, %d bay%s of hexagonal armour, the prow; %d px a unit, flat side view, '
                'prow to the right' % (round(units), whole.shape[0] / px_per_unit, count,
                                        '' if count == 1 else 's', DENSITY))
        manifest['sprites'].append({'name': name, 'description': what, 'offset': 0, 'size': 0})
        blobs[name] = png_bytes(picture)
        print('%s: %d bays, %.1f units (%d x %d px)' % (name, count, units, width, height))
    total = write_set(set_path, manifest, blobs)
    print(f'{len(manifest["sprites"])} sprites, {total} bytes -> {set_path}')


if __name__ == '__main__':
    if len(sys.argv) == 4 and sys.argv[1] == 'build':
        build(sys.argv[2], sys.argv[3])
    else:
        sys.exit(__doc__)
