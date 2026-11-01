"""Finds the neon of the city's buildings by its saturation and proposes it
as the layout's "cityLights" (chase-backdrop.md, "The life of the city").

Every piece of the kit is read from bin/sprites/chase-backdrop.mset. A pixel
is neon when it is solid, strongly saturated, bright and not of the warm
hues the sheets paint their stripes and lit windows in - those cannot be
told from a sign by colour, so they are never taken. Hot pixels that hold
together (a few pixels of slack, more along a row) are one light; a light much longer than it
is high is a strip - a guide light along a beam or a train - and burns
steady, the rest are signs and flicker. Specks are dust.

Each light is a box in shares of its picture (u, v from the top left, w, h)
and the colour of its hottest pixels raised to full brightness. The eye
decides the rest: a proposal is printed, and with --write the file's
"cityLights" pieces are replaced by it - the pieces listed in --skip left
out (red paint on a chimney is saturated too).

The windows are found apart, on the pieces named in --windows: the dark
ribbons of glass the sheets paint, a box each; the game lights a share of
them at a time, so a city of dark windows wakes here and there. The lamps
on masts' tips are set by hand ("lamp", box [u, v, 0, 0]) and a write
keeps them.

  python find_lights.py [--write] [--skip id,id...] [--windows id,id...]

Needs Pillow, numpy and scipy.
"""
import json
import os
import re
import struct
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

Here = os.path.dirname(os.path.abspath(__file__))
LayoutPath = os.path.join(Here, '..', '..', 'bin', 'chase-backdrop.json')
SetPath = os.path.join(Here, '..', '..', 'bin', 'sprites', 'chase-backdrop.mset')

SolidAlpha = 0.8
LeastSaturation = 0.55
LeastValue = 0.45
# Degrees: the burnt-orange stripes and the warm windows of the sheets
WarmHues = (15, 45)
# Pixels of slack between two parts of one light: a guide light comes as
# dashes along its row, so the slack along a row is wider
Slack = 3
SlackAlong = 20
LeastPixels = 20
# Longer than this times its height: a strip
StripAspect = 8


def read_set(APath):
  with open(APath, 'rb') as Source:
    Data = Source.read()
  Size = struct.unpack('<I', Data[6:10])[0]
  Manifest = json.loads(Data[10:10 + Size])
  Base = 10 + Size
  return {Sprite['name']: Data[Base + Sprite['offset']:Base + Sprite['offset'] + Sprite['size']]
    for Sprite in Manifest['sprites']}


def hot_pixels(AImage):
  Rgba = np.asarray(AImage.convert('RGBA')).astype(np.float32) / 255
  Hsv = np.asarray(AImage.convert('RGB').convert('HSV')).astype(np.float32) / 255
  Hue = Hsv[..., 0] * 360
  Warm = (Hue >= WarmHues[0]) & (Hue < WarmHues[1])
  Hot = (Rgba[..., 3] > SolidAlpha) & (Hsv[..., 1] > LeastSaturation) & \
    (Hsv[..., 2] > LeastValue) & ~Warm
  return Hot, Rgba


def light_colour(ARgba, AMask):
  Mean = ARgba[..., :3][AMask].mean(axis=0)
  return [int(round(255 * Channel / Mean.max())) for Channel in Mean]


def find_lights(APng):
  import io
  Picture = Image.open(io.BytesIO(APng))
  Hot, Rgba = hot_pixels(Picture)
  Height, Width = Hot.shape
  Reach = np.ones((2 * Slack + 1, 2 * SlackAlong + 1), dtype=bool)
  Joined = ndimage.binary_dilation(Hot, structure=Reach)
  Labels, Count = ndimage.label(Joined)
  Lights = []
  for Index, Box in enumerate(ndimage.find_objects(Labels), start=1):
    Own = Hot & (Labels == Index)
    if Own.sum() < LeastPixels:
      continue
    Ys, Xs = np.nonzero(Own)
    X0, X1, Y0, Y1 = Xs.min(), Xs.max() + 1, Ys.min(), Ys.max() + 1
    Kind = 'strip' if (X1 - X0) > StripAspect * (Y1 - Y0) else 'neon'
    Lights.append({
      'kind': Kind,
      'box': [round(float(X0) / Width, 4), round(float(Y0) / Height, 4),
        round(float(X1 - X0) / Width, 4), round(float(Y1 - Y0) / Height, 4)],
      'color': light_colour(Rgba, Own),
      'pixels': int(Own.sum()),
    })
  Lights.sort(key=lambda L: (L['box'][1], L['box'][0]))
  return Lights


# A ribbon of glass: solid, dark, many times wider than it is high
WindowValue = 0.16
WindowAspect = 5
WindowLeastHeight = 3
WindowLeastWidth = 20
WindowColour = [255, 184, 110]


def overlaps(A, B):
  return A[0] < B[0] + B[2] and B[0] < A[0] + A[2] and A[1] < B[1] + B[3] and B[1] < A[1] + A[3]


def find_windows(APng):
  import io
  Rgba = np.asarray(Image.open(io.BytesIO(APng)).convert('RGBA')).astype(np.float32) / 255
  Height, Width = Rgba.shape[:2]
  Dark = (Rgba[..., 3] > 0.9) & (Rgba[..., :3].max(axis=-1) < WindowValue)
  Dark = ndimage.binary_opening(Dark, structure=np.ones((2, 4)))
  Labels, _ = ndimage.label(ndimage.binary_closing(Dark, structure=np.ones((1, 7))))
  Boxes = []
  for Box in ndimage.find_objects(Labels):
    W, H = Box[1].stop - Box[1].start, Box[0].stop - Box[0].start
    if W >= WindowAspect * H and H >= WindowLeastHeight and W >= WindowLeastWidth:
      Boxes.append((Box[1].start, Box[0].start, W, H))
  # the larger of two that overlap
  Boxes.sort(key=lambda B: -B[2] * B[3])
  Kept = []
  for Box in Boxes:
    if not any(overlaps(Box, Other) for Other in Kept):
      Kept.append(Box)
  Kept.sort(key=lambda B: (B[1], B[0]))
  return [{'kind': 'window', 'box': [round(X / Width, 4), round(Y / Height, 4),
    round(W / Width, 4), round(H / Height, 4)], 'color': WindowColour, 'pixels': W * H}
    for X, Y, W, H in Kept]


def light_line(ALight):
  Parts = [f'"kind": "{ALight["kind"]}"', f'"box": {json.dumps(ALight["box"])}',
    f'"color": {json.dumps(ALight["color"])}']
  return '{ ' + ', '.join(Parts) + ' }'


def pieces_text(AFound):
  Lines = []
  for Id, Lights in AFound.items():
    if len(Lights) <= 3:
      Lines.append(f'      "{Id}": [{", ".join(light_line(L) for L in Lights)}]')
    else:
      Inner = ',\n'.join('        ' + light_line(L) for L in Lights)
      Lines.append(f'      "{Id}": [\n{Inner}\n      ]')
  return ',\n'.join(Lines)


def main():
  Write = '--write' in sys.argv
  Skip = set()
  if '--skip' in sys.argv:
    Skip = set(sys.argv[sys.argv.index('--skip') + 1].split(','))
  with open(LayoutPath, encoding='utf-8') as Source:
    Text = Source.read()
  Windowed = set()
  if '--windows' in sys.argv:
    Windowed = set(sys.argv[sys.argv.index('--windows') + 1].split(','))
  Layout = json.loads(Text)
  Kit = Layout.get('cityKit', {}).get('pieces', {})
  Old = Layout.get('cityLights', {}).get('pieces', {})
  Pictures = read_set(SetPath)
  Found = {}
  for Id in Kit:
    if Id not in Pictures:
      continue
    Lights = find_lights(Pictures[Id])
    if Id in Windowed:
      Lights += find_windows(Pictures[Id])
    Windows = [Light for Light in Lights if Light['kind'] == 'window']
    if Windows:
      print(f'{Id:14s} {len(Windows)} windows')
    for Light in Lights:
      if Light['kind'] == 'window':
        continue
      Mark = '  (skipped)' if Id in Skip else ''
      print(f'{Id:14s} {Light["kind"]:5s} box {Light["box"]} colour {Light["color"]} '
        f'{Light["pixels"]} px{Mark}')
    if Id in Skip:
      Lights = []
    Lights += [Light for Light in Old.get(Id, []) if Light['kind'] == 'lamp']
    if Lights:
      Found[Id] = Lights
  if not Write:
    return
  Pattern = re.compile(r'("cityLights": \{[\s\S]*?"pieces": \{\n)([\s\S]*?)\n?(    \})')
  if not Pattern.search(Text):
    print('the layout has no "cityLights" section with "pieces": nothing written')
    sys.exit(1)
  Text = Pattern.sub(lambda M: M.group(1) + pieces_text(Found) + '\n' + M.group(3), Text, count=1)
  with open(LayoutPath, 'w', encoding='utf-8', newline='\n') as Out:
    Out.write(Text)
  print(f'{LayoutPath}: lights of {len(Found)} pieces written')


if __name__ == '__main__':
  main()
