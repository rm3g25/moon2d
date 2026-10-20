"""Builds bin/sprites/dust.mset - the bands of levitating dust of the
tunnel screens of level 2, drawn here from noise, not generated: soft
alpha is where an image generator leaves junk.

    python build_dust.py ../../bin/sprites/dust.mset

What comes out: BANDS long strips, white, the dust in the alpha alone -
the dust kind of the dynamics (Levels.Dynamics, TDust) lights them where
the light of the screen falls and adds them over the backdrop. Every
strip is seamless across: its last column meets its first, so a band
rolls along without a joint. Its top and bottom edges are clear.

The noise is value noise on a lattice that wraps across, octaves halved
in size and in weight, the lattice stretched across far more than down:
long threads, not blots. An envelope of a soft bell gives the band its
body; a slow wave of the same wrapping noise bends the bell up and down
and thins it in places, so the band is not a ruler.

The seeds are fixed: the same script makes the same set. Needs numpy and
Pillow.
"""
import io
import json
import struct
import sys

import numpy as np
from PIL import Image

# The strips are drawn stretched over their length and height in units,
# which the level gives; this is their size in pixels
WIDTH = 1536

# name, height in px, seed, lattice cells across in the first octave,
# how far the bell bends (share of the half height), how hard the threads
# are cut (the noise floor, then the gain over it), and what it is for
BANDS = [
    ('dust-band-1', 96, 11, 5, 0.45, 0.44, 3.0,
     'thin and torn: a high thread of dust'),
    ('dust-band-2', 192, 12, 3, 0.35, 0.40, 2.8,
     'wide and even: the body of the haze'),
    ('dust-band-3', 160, 13, 4, 0.30, 0.36, 2.6,
     'dense with gaps: the low dust over the floor of the tube'),
]

OCTAVES = 5
PERSISTENCE = 0.55
# Lattice rows per lattice column in the first octave, against the
# strip's own height to width: above 1 stretches the threads across
STRETCH = 6
# The bell: exp(-(y * BELL_TIGHTNESS)^2), y from -1 to 1 down the strip
BELL_TIGHTNESS = 1.7
# The edges are made clear, whatever the bell leaves there
EDGE_ROWS = 3


def wrapping_noise(width, height, seed, cells_across):
    """Value noise, 0..1, seamless across: the lattice column past the
    last is the first again."""
    rng = np.random.default_rng(seed)
    total = np.zeros((height, width))
    weight, weights = 1.0, 0.0
    for octave in range(OCTAVES):
        cols = cells_across * 2 ** octave
        rows = max(2, int(cols * height / width * STRETCH))
        lattice = rng.random((rows + 2, cols))
        lattice = np.concatenate([lattice, lattice[:, :1]], axis=1)
        ys = np.linspace(0, rows, height)
        xs = np.linspace(0, cols, width, endpoint=False)
        yi, xi = ys.astype(int), xs.astype(int)
        fy, fx = (ys - yi)[:, None], (xs - xi)[None, :]
        fy, fx = fy * fy * (3 - 2 * fy), fx * fx * (3 - 2 * fx)
        top = lattice[yi][:, xi] * (1 - fx) + lattice[yi][:, xi + 1] * fx
        bottom = lattice[yi + 1][:, xi] * (1 - fx) + lattice[yi + 1][:, xi + 1] * fx
        total += (top * (1 - fy) + bottom * fy) * weight
        weights += weight
        weight *= PERSISTENCE
    return total / weights


def band(height, seed, cells_across, bend, floor, gain):
    threads = wrapping_noise(WIDTH, height, seed, cells_across)
    wave = wrapping_noise(WIDTH, 1, seed + 100, 3)
    down = np.linspace(-1, 1, height)[:, None]
    bell = np.exp(-((down - bend * (wave - 0.5)) * BELL_TIGHTNESS) ** 2)
    alpha = np.clip((threads - floor) * gain, 0, 1) ** 1.3 * bell * (0.5 + wave)
    alpha = np.clip(alpha, 0, 1)
    alpha[:EDGE_ROWS] = 0
    alpha[-EDGE_ROWS:] = 0
    return alpha


def png_bytes(alpha):
    rgba = np.zeros(alpha.shape + (4,), dtype=np.uint8)
    rgba[..., :3] = 255
    rgba[..., 3] = np.round(alpha * 255).astype(np.uint8)
    out = io.BytesIO()
    Image.fromarray(rgba, 'RGBA').save(out, 'PNG', optimize=True)
    return out.getvalue()


def build(set_path):
    made = []
    for name, height, seed, cells, bend, floor, gain, what in BANDS:
        alpha = band(height, seed, cells, bend, floor, gain)
        seam = np.abs(alpha[:, 0] - alpha[:, -1]).max()
        made.append((name, f'{what}; {WIDTH} x {height} px, seed {seed}, '
                           f'white, the dust in the alpha, seamless across', png_bytes(alpha)))
        print(f'{name}: {WIDTH} x {height}, peak alpha {alpha.max():.2f}, '
              f'step across the seam {seam:.3f}')

    sprites, offset = [], 0
    for name, what, blob in made:
        sprites.append({'name': name, 'description': what, 'offset': offset, 'size': len(blob)})
        offset += len(blob)
    description = ('Bands of levitating dust for the tunnel screens of level 2, drawn by '
                   'tools/dust/build_dust.py from noise. White strips, the dust in the alpha, '
                   'seamless across; the dust kind of the dynamics lights and adds them.')
    packed = json.dumps({'id': 'dust', 'description': description, 'sprites': sprites,
                         'sequences': []}, separators=(',', ':'), ensure_ascii=False).encode('utf-8')
    with open(set_path, 'wb') as out:
        out.write(b'MSET' + struct.pack('<HI', 1, len(packed)) + packed)
        for _, _, blob in made:
            out.write(blob)
    print(f'{len(sprites)} sprites, {10 + len(packed) + offset} bytes -> {set_path}')


if __name__ == '__main__':
    if len(sys.argv) == 2:
        build(sys.argv[1])
    else:
        sys.exit(__doc__)
