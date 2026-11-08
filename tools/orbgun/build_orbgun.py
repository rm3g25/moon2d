"""Builds bin/sprites/orbgun.mset - the orb gun, the moon form's weapon of
the arena 3 fight, from one generated picture: a white blaster in a flat
side view, muzzle to the right, on a clear ground.

    python build_orbgun.py build <orbgun.png> ../../bin/sprites/orbgun.mset

What comes out:
- lying: the pickup on the road, a frame of the 2008 cell (LYING_SIDE_UNITS
  square), the gun LYING_UNITS long standing on the foot of its grip at
  the frame's bottom, in the middle - the frame the shroud of its
  appearance is made of, too;
- gone: the same frame, clear - a gun that is taken leaves no body;
- held: the gun in the hero's hands, HELD_UNITS long, in a square of
  HELD_SIDE_UNITS: the grip sits in the fist of the 2008 arm frame, so the
  gun sticks out ahead of the hero and turns with the arm as every gun
  does - as the Duplet's held frame (tools/duplet/build_duplet.py).
The sequences are the Duplet's: alive - lying, death - gone.

DENSITY is 6 px a screen unit, as the Duplet. The generator's alpha is
put right here: a veil of alpha under the floor goes, the gun under the
ceiling is made whole. Its vents and trim lines are finer than a unit:
they show only at 4K.

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

HELD_UNITS = 16
# The grip sits far back: 84% of the gun ahead of the hand, against the
# Duplet's 70%
HELD_SIDE_UNITS = 32
LYING_UNITS = 24
LYING_SIDE_UNITS = 32

# The hand on the grip - the top of the black grip, where it meets the
# frame - and the middle of the muzzle ring, as shares of the gun's box in
# the source (measured on the generation of 2026-11-07: the box is the
# crescent fin's tip on the right and its top, the stern on the left, the
# foot of the grip at the bottom)
GRIP_SHARE = (0.1583, 0.6535)
MUZZLE_SHARE = (0.9529, 0.4554)
# Where the fist at the end of the 2008 arm frame lies against the middle
# of the gun frame: 1 unit ahead along the barrel, on its line
HAND_FROM_MIDDLE = (1, 0)


def load_premult(path):
    picture = np.asarray(Image.open(path).convert('RGBA'), dtype=np.float32) / 255
    alpha = np.clip((picture[..., 3] - ALPHA_FLOOR) / (ALPHA_CEILING - ALPHA_FLOOR), 0, 1)
    return np.dstack([picture[..., :3] * alpha[..., None], alpha])


def gun_of(premult):
    rows, cols = np.where(premult[..., 3] >= 0.5)
    return premult[rows.min():rows.max() + 1, cols.min():cols.max() + 1]


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


def bled_canvas(width, height, picture, left, top):
    """The picture pasted into a clear canvas, the colour of its edge carried
    over the clear pixels as well."""
    canvas = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    canvas.paste(picture, (left, top))
    pixels = np.asarray(canvas).copy()
    painted = pixels[..., 3] > 0
    nearest = ndimage.distance_transform_edt(~painted, return_distances=False, return_indices=True)
    pixels[..., :3] = pixels[nearest[0], nearest[1], :3]
    return Image.fromarray(pixels, 'RGBA')


def held_of(gun):
    length = HELD_UNITS * DENSITY
    height = round(gun.shape[0] * length / gun.shape[1])
    picture = shrink(gun, (length, height))
    side = HELD_SIDE_UNITS * DENSITY
    hand_x = side / 2 + HAND_FROM_MIDDLE[0] * DENSITY
    hand_y = side / 2 + HAND_FROM_MIDDLE[1] * DENSITY
    left = round(hand_x - GRIP_SHARE[0] * length)
    top = round(hand_y - GRIP_SHARE[1] * height)
    if left < 0 or top < 0 or left + length > side or top + height > side:
        sys.exit(f'the held gun does not fit its square of {side} px')
    muzzle = (left + MUZZLE_SHARE[0] * length - side / 2,
              top + MUZZLE_SHARE[1] * height - side / 2)
    return bled_canvas(side, side, picture, left, top), muzzle


def lying_of(gun):
    length = LYING_UNITS * DENSITY
    height = round(gun.shape[0] * length / gun.shape[1])
    picture = shrink(gun, (length, height))
    side = LYING_SIDE_UNITS * DENSITY
    return bled_canvas(side, side, picture, (side - length) // 2, side - height)


def gone_of():
    side = LYING_SIDE_UNITS * DENSITY
    return Image.new('RGBA', (side, side), (0, 0, 0, 0))


def png_bytes(image):
    buffer = io.BytesIO()
    image.save(buffer, 'PNG', optimize=True)
    return buffer.getvalue()


def build(source, set_path):
    gun = gun_of(load_premult(source))
    held, muzzle = held_of(gun)
    print('held %dx%d px; the muzzle %.2f, %.2f units from the middle'
          % (held.width, held.height, muzzle[0] / DENSITY, muzzle[1] / DENSITY))

    made = [
        ('lying', f'the pickup on the road, {LYING_UNITS} units long, standing on its grip at the bottom '
                  f'of a frame of {LYING_SIDE_UNITS}', png_bytes(lying_of(gun))),
        ('held', f'the orb gun in the hands, {HELD_UNITS} units long in a square of {HELD_SIDE_UNITS}, '
                 f'the grip {HAND_FROM_MIDDLE[0]} units ahead of the middle and {HAND_FROM_MIDDLE[1]} down; '
                 f'the muzzle {muzzle[0] / DENSITY:.2f}, {muzzle[1] / DENSITY:.2f} units from the middle',
         png_bytes(held)),
        ('gone', 'a clear frame: a gun that is taken leaves no body', png_bytes(gone_of())),
    ]
    sprites, offset = [], 0
    for name, what, blob in made:
        sprites.append({'name': name, 'description': what, 'offset': offset, 'size': len(blob)})
        offset += len(blob)
    description = ('The orb gun, the moon form\'s weapon of the arena 3 fight: a white blaster in the '
                   'spirit of tokusatsu hero gear - pearl-white plates, a black grip and muzzle ring, '
                   'a crescent-moon fin along its top, a crystal window with a black orb in it. '
                   '"lying" is the pickup, "held" the gun in the hands.')
    sequences = [
        {'name': 'alive', 'description': 'one still frame', 'frames': ['lying'] * 8},
        {'name': 'death', 'description': 'a gun that is taken leaves no body', 'frames': ['gone'] * 8},
    ]
    packed = json.dumps({'id': 'orbgun', 'description': description, 'sprites': sprites,
                         'sequences': sequences}, separators=(',', ':'), ensure_ascii=False).encode('utf-8')
    with open(set_path, 'wb') as out:
        out.write(b'MSET' + struct.pack('<HI', 1, len(packed)) + packed)
        for _, _, blob in made:
            out.write(blob)
    print(f'{len(sprites)} sprites, {10 + len(packed) + offset} bytes -> {set_path}')


if __name__ == '__main__':
    if len(sys.argv) == 4 and sys.argv[1] == 'build':
        build(sys.argv[2], sys.argv[3])
    else:
        sys.exit(__doc__)
