"""Adds to bin/sprites/tek-machine.mset the sprites made after its build,
without the build's source pictures: each is put in place of one of the
same name, or after the last one.

    python extend_machine.py <sources dir> ../../bin/sprites/tek-machine.mset

What it adds:
- wellShutter: the hatch over the mast well once the bunker is gone. Out
  of a generated picture of the hatch seen from above and in front, on a
  white ground (machine-hatch.png in the sources dir): the ground cleared,
  its top face squashed to the ellipse of the well's mouth as the eye
  sees it from the side, a little wider than the mouth so its own rim
  sits on the well's, its side band showing under it. The middle of its
  face is the middle of the sprite and the well's centre; drawn over the
  hull, slid shut from the far edge toward the eye.

The sources are not kept in the repository, as the build's are not.

The mouth of the well is measured on the hull: its dark (the hull clear
over its back half, painted dark over its front half) runs from about 69
to 105 px down, 319 to 519 across - an ellipse of about 100 by 18 px about
the well's centre; the hatch's own rim sits on it. Needs numpy and
Pillow.
"""
import io
import json
import os
import struct
import sys
from collections import deque

import numpy as np
from PIL import Image, ImageFilter

DENSITY = 6
# the well's centre, in screen units from the hull's top-left corner, and
# the half-axes of its mouth in px
WELL_X, WELL_Y = 69.9, 14.6
MOUTH_HALF_WIDTH = 100
MOUTH_HALF_HEIGHT = 18
MOUTH_ASPECT = MOUTH_HALF_WIDTH / MOUTH_HALF_HEIGHT
# the hatch a little wider than the mouth, px
SHUTTER_WIDTH = 206

HATCH_FILE = 'machine-hatch.png'
# measured on the hatch picture (2172x724), cropped to the hatch: its top
# face 533 px high, its middle 266 down; the side band under it
HATCH_FACE_HEIGHT = 533
HATCH_FACE_MIDDLE = 266
# its white ground: lighter than this and greyer than that
GROUND_LEVEL = 232
GROUND_TINT = 14


def read_set(path):
    raw = open(path, 'rb').read()
    if raw[:4] != b'MSET':
        sys.exit(f'{path}: not a sprite set')
    _, length = struct.unpack('<HI', raw[4:10])
    manifest = json.loads(raw[10:10 + length])
    blobs = raw[10 + length:]
    pictures = {}
    for sprite in manifest['sprites']:
        pictures[sprite['name']] = blobs[sprite['offset']:sprite['offset'] + sprite['size']]
    return manifest, pictures


def write_set(path, manifest, pictures):
    sprites, offset, blobs = [], 0, []
    for sprite in manifest['sprites']:
        blob = pictures[sprite['name']]
        sprites.append(dict(sprite, offset=offset, size=len(blob)))
        blobs.append(blob)
        offset += len(blob)
    manifest = dict(manifest, sprites=sprites)
    packed = json.dumps(manifest, ensure_ascii=False, indent=2).encode('utf-8')
    with open(path, 'wb') as out:
        out.write(b'MSET' + struct.pack('<HI', 1, len(packed)) + packed)
        for blob in blobs:
            out.write(blob)
    print(f'{len(sprites)} sprites, {10 + len(packed) + offset} bytes -> {path}')


def put(manifest, pictures, name, description, image):
    buffer = io.BytesIO()
    image.save(buffer, 'PNG', optimize=True)
    pictures[name] = buffer.getvalue()
    for sprite in manifest['sprites']:
        if sprite['name'] == name:
            sprite['description'] = description
            return
    manifest['sprites'].append({'name': name, 'description': description, 'offset': 0, 'size': 0})


def keyed(picture):
    """The white ground the picture was generated on, cleared from its edges
    inward: only white that touches the edge goes, the light paint inside
    the hatch stays."""
    rgb = np.asarray(picture.convert('RGB')).astype(np.int16)
    height, width, _ = rgb.shape
    ground = (rgb.min(axis=2) > GROUND_LEVEL) & (np.ptp(rgb, axis=2) < GROUND_TINT)
    seen = np.zeros((height, width), bool)
    queue = deque((y, x) for y in range(height) for x in (0, width - 1))
    queue.extend((y, x) for x in range(width) for y in (0, height - 1))
    while queue:
        y, x = queue.popleft()
        if not (0 <= y < height and 0 <= x < width) or seen[y, x] or not ground[y, x]:
            continue
        seen[y, x] = True
        queue.extend(((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)))
    alpha = Image.fromarray(np.where(seen, 0, 255).astype(np.uint8))
    alpha = alpha.filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(1.2))
    result = picture.convert('RGBA')
    result.putalpha(alpha)
    return result


def well_shutter(hatch):
    hatch = keyed(hatch)
    rows, cols = np.where(np.asarray(hatch)[..., 3] > 128)
    hatch = hatch.crop((cols.min(), rows.min(), cols.max() + 1, rows.max() + 1))
    # its top face squashed to the mouth's ellipse, its side band as it falls
    width = SHUTTER_WIDTH
    squash = width / MOUTH_ASPECT / HATCH_FACE_HEIGHT
    height = round(hatch.height * squash)
    lid = hatch.resize((width, height), Image.LANCZOS)
    face_middle = HATCH_FACE_MIDDLE * squash
    # room over it, so the middle of its face is the middle of the sprite
    room = round(height - 2 * face_middle)
    shutter = Image.new('RGBA', (width, height + room), (0, 0, 0, 0))
    shutter.alpha_composite(lid, (0, room))
    return shutter


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    sources, path = sys.argv[1], sys.argv[2]
    manifest, pictures = read_set(path)
    hatch = Image.open(os.path.join(sources, HATCH_FILE)).convert('RGBA')
    shutter = well_shutter(hatch)
    put(manifest, pictures, 'wellShutter',
        f'the hatch over the mast well once the bunker is gone, seen as the hull is: '
        f'its top face over the mouth of the well, the middle of the face on the '
        f'well\'s centre {WELL_X}, {WELL_Y}, its side band under it; '
        f'{shutter.width / DENSITY:.1f} x {shutter.height / DENSITY:.1f} units; drawn over '
        f'the hull, slid shut from the far edge', shutter)
    write_set(path, manifest, pictures)


if __name__ == '__main__':
    main()
