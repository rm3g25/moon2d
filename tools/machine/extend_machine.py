"""Adds to bin/sprites/tek-machine.mset the sprites made after its build,
without the build's source pictures: each is put in place of one of the
same name, or after the last one.

    python extend_machine.py <sources dir> ../../bin/sprites/tek-machine.mset

All the generated pictures it takes are in the sources dir, under the
names below.

What it adds:
- wellShutter: the hatch over the mast well once the bunker is gone. Out
  of a generated picture of the hatch seen from above and in front, on a
  white ground (machine-hatch.png): the ground cleared, its top face
  squashed to the ellipse of the well's mouth as the eye sees it from the
  side, a little wider than the mouth so its own rim sits on the well's,
  its side band showing under it. The middle of its face is the middle of
  the sprite and the well's centre; drawn over the hull, slid shut from
  the far edge toward the eye.
- engineBay: what fills a wheel arch once its wheel is gone - a heat
  shield of tiles, a ribbed duct into a swivel ring, two actuators, bay
  doors folded open, a bulkhead at the bottom (machine-bay.png). The
  opening of the arch is read off the hull itself, as the clear run of
  each row about the axle down to the feet; both arches' openings, laid on
  their axles, make one mask, so one picture serves both. The bay is
  scaled to the width of the mask, its bottom on the feet's line, so the
  ring comes just under the axle; darkened, to half its light at the top
  of the opening and three quarters at the bottom, so it reads as
  recessed. The axle is the middle of the sprite.
- engineNozzle: the nozzle of steel petals that hangs under the ring
  (machine-nozzle.png), as wide as the ring; the middle of its top edge
  hangs from the ring. Not darkened.
- engineNozzleLit: the same nozzle warmed from below, as the fire under
  it lights it: blended over engineNozzle as the fire burns, nothing at
  its top.

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
BAY_FILE = 'machine-bay.png'
NOZZLE_FILE = 'machine-nozzle.png'
# measured on the hatch picture (2172x724), cropped to the hatch: its top
# face 533 px high, its middle 266 down; the side band under it
HATCH_FACE_HEIGHT = 533
HATCH_FACE_MIDDLE = 266
# its white ground: lighter than this and greyer than that
GROUND_LEVEL = 232
GROUND_TINT = 14

# The axles in screen units from the hull's top-left corner, front first
AXLES = ((61.1, 107.5), (133.2, 107.5))
# A unit of the hull is solid where it is this opaque, as the game reads it
BODY_ALPHA = 128
# Going down from the axle, the clear run of a row that grows by more than
# this on a side has left the arch: the feet are behind
LEAK = 12
# The mask reaches this far under the hull's own edge, so no seam of the
# arch's dark shows between the two
MASK_GROW = 3
# The bay a little wider than the opening, so its sides go under the frame
BAY_OVERSCAN = 1.04
# Its light at the top of the opening and at the bottom
BAY_TOP_LIGHT = 0.5
BAY_BOTTOM_LIGHT = 0.75
# measured on the bay picture (1254x1254): the swivel ring runs from 432 to
# 825 across; the nozzle tucks into its open bottom 925 down
RING_LEFT = 432
RING_RIGHT = 825
RING_HANG_Y = 925
# The nozzle as wide as the ring, a little narrower so the ring's lip
# shows round it
NOZZLE_SHARE = 0.97
# The fire's warmth on the nozzle: from LIT_FROM of its height down, up to
# LIT_GAIN more light and a warm cast at its lip
LIT_FROM = 0.3
LIT_GAIN = 1.1
LIT_WARMTH = (110, 45, 0)


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
    stays. A picture that came clear already keeps its own alpha."""
    rgba = np.asarray(picture.convert('RGBA'))
    rgb = rgba[..., :3].astype(np.int16)
    height, width, _ = rgb.shape
    ground = (rgb.min(axis=2) > GROUND_LEVEL) & (np.ptp(rgb, axis=2) < GROUND_TINT)
    ground |= rgba[..., 3] < 8
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
    alpha = np.minimum(np.asarray(alpha), rgba[..., 3])
    result = picture.convert('RGBA')
    result.putalpha(Image.fromarray(alpha))
    return result


def cropped(picture):
    rows, cols = np.where(np.asarray(picture)[..., 3] > 128)
    return picture.crop((cols.min(), rows.min(), cols.max() + 1, rows.max() + 1))


def well_shutter(hatch):
    hatch = cropped(keyed(hatch))
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


def arch_opening(clear, axle_x, axle_y):
    """The rows of the arch about one axle, as (row, left, right) in px: the
    clear run through the axle's column, up while the column is clear,
    down till the run leaks out under the feet."""
    def run(row):
        left = right = axle_x
        while left > 0 and clear[row, left - 1]:
            left -= 1
        while right < clear.shape[1] - 1 and clear[row, right + 1]:
            right += 1
        return left, right

    rows = []
    row = axle_y
    while row >= 0 and clear[row, axle_x]:
        rows.append((row, *run(row)))
        row -= 1
    last = run(axle_y)
    row = axle_y + 1
    while row < clear.shape[0] and clear[row, axle_x]:
        left, right = run(row)
        if left < last[0] - LEAK or right > last[1] + LEAK:
            break
        rows.append((row, left, right))
        last = (left, right)
        row += 1
    return rows


def arch_mask(hull):
    """Both arches' openings laid on their axles, in one frame with the axle
    at its middle; soft at the edges, grown under the frame's edge but not
    below the feet."""
    clear = np.asarray(hull)[..., 3] < BODY_ALPHA
    openings = []
    for x, y in AXLES:
        axle_x, axle_y = round(x * DENSITY), round(y * DENSITY)
        openings.append([(row - axle_y, left - axle_x, right - axle_x)
                         for row, left, right in arch_opening(clear, axle_x, axle_y)])
    reach_x = max(max(-left, right) for rows in openings for _, left, right in rows)
    reach_y = max(abs(row) for rows in openings for row, _, _ in rows)
    half_width = reach_x + 2 * MASK_GROW
    half_height = reach_y + 2 * MASK_GROW
    mask = np.zeros((2 * half_height + 1, 2 * half_width + 1), np.uint8)
    for rows in openings:
        for row, left, right in rows:
            mask[row + half_height, left + half_width:right + half_width + 1] = 255
    bottom = max(row for rows in openings for row, _, _ in rows) + half_height
    top = min(row for rows in openings for row, _, _ in rows) + half_height
    grown = Image.fromarray(mask).filter(ImageFilter.MaxFilter(2 * MASK_GROW + 1))
    grown = np.asarray(grown).copy()
    grown[bottom + 1:] = 0
    soft = np.asarray(Image.fromarray(grown).filter(ImageFilter.GaussianBlur(1.0)))
    soft = soft.copy()
    soft[bottom + 1:] = 0
    return soft, (half_width, half_height), top, bottom


def engine_bay(bay, hull):
    """The bay fitted into the arches' mask, darkened; and where its ring's
    open bottom falls, in px from the axle."""
    mask, (half_width, half_height), top, bottom = arch_mask(hull)
    picture = keyed(bay)
    rows, cols = np.where(np.asarray(picture)[..., 3] > 128)
    content = (cols.min(), rows.min(), cols.max() + 1, rows.max() + 1)
    picture = picture.crop(content)
    opening_width = np.count_nonzero(mask.max(axis=0) > 128)
    scale = opening_width * BAY_OVERSCAN / picture.width
    fitted = picture.resize((round(picture.width * scale), round(picture.height * scale)),
                            Image.LANCZOS)
    ring_middle = ((RING_LEFT + RING_RIGHT) / 2 - content[0]) * scale
    left = round(half_width - ring_middle)
    up = bottom + 2 - fitted.height
    # laid on a canvas with room all round, then cut to the mask's frame
    room = fitted.width + fitted.height
    canvas = Image.new('RGBA', (mask.shape[1] + 2 * room, mask.shape[0] + 2 * room),
                       (0, 0, 0, 0))
    canvas.paste(fitted, (room + left, room + up))
    frame = canvas.crop((room, room, room + mask.shape[1], room + mask.shape[0]))
    pixels = np.asarray(frame).astype(np.float32)
    share = np.clip((np.arange(mask.shape[0]) - top) / max(bottom - top, 1), 0, 1)
    light = BAY_TOP_LIGHT + (BAY_BOTTOM_LIGHT - BAY_TOP_LIGHT) * share
    pixels[..., :3] *= light[:, None, None]
    pixels[..., 3] *= mask / 255.0
    result = Image.fromarray(np.clip(pixels, 0, 255).astype(np.uint8))
    hang_y = up + (RING_HANG_Y - content[1]) * scale - half_height
    ring_width = (RING_RIGHT - RING_LEFT) * scale
    return result, hang_y, ring_width


def engine_nozzle(nozzle, ring_width):
    nozzle = cropped(keyed(nozzle))
    width = round(ring_width * NOZZLE_SHARE)
    return nozzle.resize((width, round(nozzle.height * width / nozzle.width)), Image.LANCZOS)


def lit_nozzle(nozzle):
    """Warmed from below: nothing at the top, the most at the lip."""
    pixels = np.asarray(nozzle).astype(np.float32)
    height = pixels.shape[0]
    share = np.clip((np.arange(height) / (height - 1) - LIT_FROM) / (1 - LIT_FROM), 0, 1)
    warmth = (share * share)[:, None]
    for channel in range(3):
        pixels[..., channel] = (pixels[..., channel] * (1 + LIT_GAIN * warmth) +
                                LIT_WARMTH[channel] * warmth)
    pixels[..., 3] *= warmth
    return Image.fromarray(np.clip(pixels, 0, 255).astype(np.uint8))


def sprite_picture(pictures, name):
    return Image.open(io.BytesIO(pictures[name])).convert('RGBA')


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    sources, path = sys.argv[1], sys.argv[2]
    manifest, pictures = read_set(path)

    hatch = Image.open(os.path.join(sources, HATCH_FILE))
    shutter = well_shutter(hatch)
    put(manifest, pictures, 'wellShutter',
        f'the hatch over the mast well once the bunker is gone, seen as the hull is: '
        f'its top face over the mouth of the well, the middle of the face on the '
        f'well\'s centre {WELL_X}, {WELL_Y}, its side band under it; '
        f'{shutter.width / DENSITY:.1f} x {shutter.height / DENSITY:.1f} units; drawn over '
        f'the hull, slid shut from the far edge', shutter)

    hull = sprite_picture(pictures, 'hull')
    bay, hang_y, ring_width = engine_bay(Image.open(os.path.join(sources, BAY_FILE)), hull)
    put(manifest, pictures, 'engineBay',
        f'the engine bay that fills a wheel arch once its wheel is gone, one for both '
        f'arches: cut to their openings, darkened from half its light at the top to '
        f'three quarters at the bottom; the axle at its middle; '
        f'{bay.width / DENSITY:.1f} x {bay.height / DENSITY:.1f} units; drawn behind the '
        f'hull over the chassis; its ring\'s open bottom {hang_y / DENSITY:.1f} under the '
        f'axle, where the nozzle hangs', bay)

    nozzle = engine_nozzle(Image.open(os.path.join(sources, NOZZLE_FILE)), ring_width)
    put(manifest, pictures, 'engineNozzle',
        f'the petal nozzle under the bay\'s ring, the middle of its top edge hung '
        f'{hang_y / DENSITY:.1f} under the axle; turned with the hull; '
        f'{nozzle.width / DENSITY:.1f} x {nozzle.height / DENSITY:.1f} units', nozzle)
    put(manifest, pictures, 'engineNozzleLit',
        'engineNozzle warmed from below by the fire, clear at its top; blended over '
        'it as the fire burns, same frame', lit_nozzle(nozzle))

    write_set(path, manifest, pictures)
    print(f'engineBay {bay.width} x {bay.height} px; the nozzle hangs {hang_y:.1f} px '
          f'({hang_y / DENSITY:.2f} units) under the axle; engineNozzle '
          f'{nozzle.width} x {nozzle.height} px')


if __name__ == '__main__':
    main()
