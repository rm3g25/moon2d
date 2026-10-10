"""Puts the HD art of the medkit into bin/sprites/medic.mset, from one
generated picture: the TeK case seen from the front on a clear ground.

    python build_medkit.py build <medkit-whole.png> ../../bin/sprites/medic.mset

The set is read and written: the 2008 frames in it are carried over byte for
byte, and what this script makes is made anew on every run. What comes out:
- medkit: the case in the frame of a monster's cell, 32 x 32 units, standing
  on the bottom edge - the engine draws it as it draws any frame;
- light: the cross alone, white with its shape in alpha, in the same frame -
  the light the code lays over the painted cross;
- gone: a clear frame, for the death of a thing that is taken, not killed.
Sequences: 'alive' is medkit eight times and 'death' is gone eight times; the
2008 ones stay under 'alive-2008' and 'death-2008'.

DENSITY is the one number that ties the art to a screen: 6 px a screen unit
is just past what a 4K screen shows (2160 px for 384 units, 5.625).

The generator's alpha is not clean, and all of it is put right here: the
case stands at 253 of 255, a hair see-through, and a veil of alpha 1..5
lies around it and in specks off it - the veil alone would stretch the
frame of the case to the edges of the picture.

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
CELL_UNITS = 32
WIDTH_UNITS = 20
FRAME_2008 = 64
# Alpha at or below the floor is the veil; at or above the ceiling - the case
ALPHA_FLOOR = 8 / 255
ALPHA_CEILING = 250 / 255
# The cross is what is green enough: green over red and over blue by this much
GREEN_LEAD = 40 / 255
CROSS_ALPHA = 200 / 255

MADE = ('medkit', 'light', 'gone')
DESCRIPTION = (
    'The medkit. "medkit" is the HD art: a TeK field case, {side}x{side}, {density} px per screen unit, '
    'one still frame in the cell of a monster; the case is {width:.0f} x {height:.0f} units and stands on '
    'the bottom edge. "light" is its cross alone, white with the shape in alpha: the code lights it. '
    'The middle of the cross is at {cross_x:.2f}, {cross_y:.2f} units from the top-left corner of the '
    'frame. "gone" is a clear frame: a medkit that is taken leaves no body. 1-5 and d1-d8 are the 2008 '
    'frames.')


# --- pictures as float32 premultiplied RGBA, 0..1 ---------------------------

def load_premult(path):
    picture = np.asarray(Image.open(path).convert('RGBA'), dtype=np.float32) / 255
    alpha = np.clip((picture[..., 3] - ALPHA_FLOOR) / (ALPHA_CEILING - ALPHA_FLOOR), 0, 1)
    return np.dstack([picture[..., :3] * alpha[..., None], alpha])


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


# --- the case -----------------------------------------------------------------

def case_of(premult):
    """The box of the silhouette."""
    rows, cols = np.where(premult[..., 3] >= 0.5)
    return premult[rows.min():rows.max() + 1, cols.min():cols.max() + 1]


def in_cell(case):
    """The case in a square of the cell's size in source pixels: centered,
    standing on the bottom edge."""
    height, width = case.shape[:2]
    side = round(width * CELL_UNITS / WIDTH_UNITS)
    left = (side - width) // 2
    cell = np.zeros((side, side, 4), dtype=np.float32)
    cell[side - height:, left:left + width] = case
    return cell


def cross_of(cell):
    """The cross as a light: white, premultiplied, the shape in alpha."""
    alpha = np.maximum(cell[..., 3], 1e-3)
    red, green, blue = (cell[..., k] / alpha for k in range(3))
    lit = (green > red + GREEN_LEAD) & (green > blue + GREEN_LEAD) & (cell[..., 3] > CROSS_ALPHA)
    # specks of green in the scuffed paint are not the cross
    marks, count = ndimage.label(lit)
    if count > 1:
        sizes = ndimage.sum(lit, marks, range(1, count + 1))
        lit = marks == 1 + int(np.argmax(sizes))
    shape = lit.astype(np.float32)
    return np.dstack([shape, shape, shape, shape])


# --- the set ------------------------------------------------------------------

def read_set(path):
    with open(path, 'rb') as source:
        data = source.read()
    if data[:4] != b'MSET':
        sys.exit(f'{path} is not a sprite set')
    size = struct.unpack('<I', data[6:10])[0]
    manifest = json.loads(data[10:10 + size].decode('utf-8'))
    base = 10 + size
    blobs = {sprite['name']: data[base + sprite['offset']:base + sprite['offset'] + sprite['size']]
             for sprite in manifest['sprites']}
    return manifest, blobs


def png_bytes(image):
    buffer = io.BytesIO()
    image.save(buffer, 'PNG', optimize=True)
    return buffer.getvalue()


def keep_2008(sequences, name):
    """The sequence the 2008 frames play, whatever its name is by now."""
    by_name = {sequence['name']: sequence for sequence in sequences}
    old = by_name.get(name + '-2008') or by_name[name]
    return {'name': name + '-2008', 'description': old['description'], 'frames': old['frames']}


def build(source, set_path):
    manifest, blobs = read_set(set_path)
    cell = in_cell(case_of(load_premult(source)))
    side = CELL_UNITS * DENSITY
    medkit = shrink(cell, (side, side))
    light = shrink(cross_of(cell), (side, side))
    gone = Image.new('RGBA', (FRAME_2008, FRAME_2008), (0, 0, 0, 0))

    painted = np.asarray(medkit)[..., 3] >= 128
    rows, cols = np.where(painted)
    lit = np.asarray(light)[..., 3] >= 128
    lit_rows, lit_cols = np.where(lit)
    cross_x = (lit_cols.min() + lit_cols.max() + 1) / 2 / DENSITY
    cross_y = (lit_rows.min() + lit_rows.max() + 1) / 2 / DENSITY
    width = (cols.max() - cols.min() + 1) / DENSITY
    height = (rows.max() - rows.min() + 1) / DENSITY
    print('case %.2f x %.2f units, left %.2f, top %.2f' % (width, height, cols.min() / DENSITY, rows.min() / DENSITY))
    print('cross %.2f..%.2f, %.2f..%.2f; middle %.2f, %.2f'
          % (lit_cols.min() / DENSITY, (lit_cols.max() + 1) / DENSITY, lit_rows.min() / DENSITY,
             (lit_rows.max() + 1) / DENSITY, cross_x, cross_y))

    made = {
        'medkit': ('HD TeK field case, light grey scuffed steel, green cross unlit, hazard band; '
                   f'{side}x{side}, {CELL_UNITS} units', png_bytes(medkit)),
        'light': (f'the cross of "medkit" alone, white, the shape in alpha; {side}x{side}', png_bytes(light)),
        'gone': ('a clear frame', png_bytes(gone)),
    }
    sprites, offset, data = [], 0, []
    for sprite in manifest['sprites']:
        if sprite['name'] in MADE:
            continue
        blob = blobs[sprite['name']]
        sprites.append({'name': sprite['name'], 'description': sprite['description'], 'offset': offset,
                        'size': len(blob)})
        offset += len(blob)
        data.append(blob)
    for name in MADE:
        what, blob = made[name]
        sprites.append({'name': name, 'description': what, 'offset': offset, 'size': len(blob)})
        offset += len(blob)
        data.append(blob)

    sequences = [
        {'name': 'alive', 'description': 'one still frame: the light of the cross is the code\'s',
         'frames': ['medkit'] * 8},
        {'name': 'death', 'description': 'a medkit that is taken leaves no body', 'frames': ['gone'] * 8},
        keep_2008(manifest['sequences'], 'alive'),
        keep_2008(manifest['sequences'], 'death'),
    ]
    description = DESCRIPTION.format(side=side, density=DENSITY, width=width, height=height,
                                     cross_x=cross_x, cross_y=cross_y)
    packed = json.dumps({'id': manifest['id'], 'description': description, 'sprites': sprites,
                         'sequences': sequences}, separators=(',', ':'), ensure_ascii=False).encode('utf-8')
    with open(set_path, 'wb') as out:
        out.write(b'MSET' + struct.pack('<HI', 1, len(packed)) + packed)
        for blob in data:
            out.write(blob)
    print(f'{len(sprites)} sprites, {10 + len(packed) + offset} bytes -> {set_path}')


if __name__ == '__main__':
    if len(sys.argv) == 4 and sys.argv[1] == 'build':
        build(sys.argv[2], sys.argv[3])
    else:
        sys.exit(__doc__)
