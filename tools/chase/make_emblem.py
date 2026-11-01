"""Turns the TeK emblem into the neon sign hanging under the main dome
(chase-backdrop.md, "The emblem") and puts its pictures into
bin/sprites/chase-backdrop.mset.

The emblem comes as one PNG with a real alpha: a metal sign of separate
parts - the triangle's frame, the bar, T, e, K, the small triangle. Every
part that holds together in the alpha is one part of the sign, numbered by
the order the layout lights them in (top to bottom, left to right). Out of
the emblem come:

  tek-emblem       the metal, as drawn, its faint fringe dropped
  tek-N            the neon tube of part N: a band along the part's edge,
                   a little inside it, white with the tube in alpha
  tek-N-halo       the tube blurred, at a quarter of the size: the glow
  tek-paint        the emblem as old paint on a wall: one flat faded
                   colour, worn through in blotches and scratches - the
                   wear is baked, the same on the stand and in the game

Each part's pictures are cut to its own box; the boxes, in shares of the
emblem, go into the layout's "emblem" section ("parts", "halos"), so the
game and the stand place them by the numbers alone.

  python make_emblem.py <emblem>.png

Needs Pillow, numpy and scipy.
"""
import io
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

# Alpha that counts as the sign; below it the generation's fringe
BodyAlpha = 128
LeastPixels = 2000
# Shares of the emblem's width: the tube stands this far inside a part's
# edge and is this thick
TubeInset = 0.012
TubeWidth = 0.011
HaloSigma = 0.025
# The metal and the tubes at this width: 44 units of sign at 4K is about 250 px
MetalWidth = 768
TubeWidthPx = 768
HaloShare = 4
PaintWidth = 384
PaintColor = (250, 222, 140)
# Shares of the paint the wear takes: blotches where the low noise is low,
# scratches along thin random strokes
PaintBlotches = 0.16
PaintScratches = 60
PaintSeed = 1987


def read_set(APath):
  with open(APath, 'rb') as Source:
    Data = Source.read()
  Size = struct.unpack('<I', Data[6:10])[0]
  Manifest = json.loads(Data[10:10 + Size])
  Base = 10 + Size
  return Manifest, {Sprite['name']: Data[Base + Sprite['offset']:Base + Sprite['offset'] + Sprite['size']]
    for Sprite in Manifest['sprites']}


def write_set(APath, AManifest, ABlobs):
  Sprites, Offset = [], 0
  for Sprite in AManifest['sprites']:
    Blob = ABlobs[Sprite['name']]
    Sprites.append(dict(Sprite, offset=Offset, size=len(Blob)))
    Offset += len(Blob)
  AManifest = dict(AManifest, sprites=Sprites)
  Text = json.dumps(AManifest, indent=2).encode('utf-8')
  with open(APath, 'wb') as Out:
    Out.write(b'MSET')
    Out.write(struct.pack('<HI', 1, len(Text)))
    Out.write(Text)
    for Sprite in Sprites:
      Out.write(ABlobs[Sprite['name']])


def png(AArray):
  Buffer = io.BytesIO()
  Image.fromarray(AArray).save(Buffer, 'PNG', optimize=True)
  return Buffer.getvalue()


def white_alpha(ALevels):
  Out = np.zeros(ALevels.shape + (4,), dtype=np.uint8)
  Out[..., :3] = 255
  Out[..., 3] = np.clip(np.round(ALevels * 255), 0, 255).astype(np.uint8)
  return Out


def scaled(ALevels, AWidth):
  Height = max(1, round(ALevels.shape[0] * AWidth / ALevels.shape[1]))
  # float resampling keeps a thin tube smooth
  Picture = Image.fromarray(ALevels.astype(np.float32), mode='F').resize((AWidth, Height), Image.LANCZOS)
  return np.clip(np.asarray(Picture), 0, 1)


def worn_paint(ABody):
  Random = np.random.RandomState(PaintSeed)
  Height, Width = ABody.shape
  Low = ndimage.gaussian_filter(Random.rand(Height, Width), Width / 40)
  Low = (Low - Low.min()) / (Low.max() - Low.min())
  Keep = np.clip((Low - PaintBlotches) / 0.08, 0, 1)
  Scratch = Image.new('L', (Width, Height), 0)
  from PIL import ImageDraw
  Pen = ImageDraw.Draw(Scratch)
  for _ in range(PaintScratches):
    X, Y = Random.rand(2) * (Width, Height)
    Angle = Random.uniform(-0.5, 0.5) + (np.pi / 2 if Random.rand() < 0.3 else 0)
    Length = Random.uniform(0.04, 0.2) * Width
    Pen.line([(X, Y), (X + np.cos(Angle) * Length, Y + np.sin(Angle) * Length)],
      fill=255, width=max(1, round(Width / 400)))
  Keep = Keep * (1 - np.asarray(Scratch) / 255.0)
  Grain = 0.75 + 0.25 * Random.rand(Height, Width)
  Alpha = ABody * Keep * Grain
  Out = np.zeros((Height, Width, 4), dtype=np.uint8)
  Out[..., :3] = PaintColor
  Out[..., 3] = np.clip(Alpha * 255, 0, 255).astype(np.uint8)
  Small = Image.fromarray(Out).resize((PaintWidth, round(Height * PaintWidth / Width)), Image.LANCZOS)
  return np.asarray(Small)


def share_box(AX0, AY0, AX1, AY1, AWidth, AHeight):
  return [round(float(AX0) / AWidth, 4), round(float(AY0) / AHeight, 4),
    round(float(AX1 - AX0) / AWidth, 4), round(float(AY1 - AY0) / AHeight, 4)]


def main():
  if len(sys.argv) < 2:
    print(__doc__)
    sys.exit(2)
  Source = Image.open(sys.argv[1]).convert('RGBA')
  Rgba = np.asarray(Source)
  Height, Width = Rgba.shape[:2]
  Body = Rgba[..., 3] >= BodyAlpha
  Labels, Count = ndimage.label(Body)
  Parts = [Index for Index in range(1, Count + 1) if (Labels == Index).sum() >= LeastPixels]
  Boxes = {Index: ndimage.find_objects((Labels == Index).astype(int))[0] for Index in Parts}
  Parts.sort(key=lambda I: (Boxes[I][0].start // (Height // 5), Boxes[I][1].start))

  Metal = Rgba.copy()
  Metal[..., 3] = np.where(Body, Rgba[..., 3], 0)
  Metal = np.asarray(Image.fromarray(Metal).resize(
    (MetalWidth, round(Height * MetalWidth / Width)), Image.LANCZOS))
  Blobs = {'tek-emblem': png(Metal)}

  Blobs['tek-paint'] = png(worn_paint(Body))

  Inset = max(1, round(TubeInset * Width))
  Thick = max(1, round(TubeWidth * Width))
  Sigma = HaloSigma * Width
  Pad = int(3 * Sigma)
  PartBoxes, HaloBoxes = [], []
  for Number, Index in enumerate(Parts, start=1):
    Own = Labels == Index
    Outer = ndimage.binary_erosion(Own, iterations=Inset)
    Tube = Outer & ~ndimage.binary_erosion(Outer, iterations=Thick)
    Ys, Xs = np.nonzero(Tube)
    X0, X1, Y0, Y1 = Xs.min() - 2, Xs.max() + 3, Ys.min() - 2, Ys.max() + 3
    Levels = ndimage.gaussian_filter(Tube.astype(np.float32), 0.7)
    Scale = TubeWidthPx / Width
    Cut = Levels[Y0:Y1, X0:X1]
    Blobs[f'tek-{Number}'] = png(white_alpha(scaled(Cut, max(4, round(Cut.shape[1] * Scale)))))
    PartBoxes.append(share_box(X0, Y0, X1, Y1, Width, Height))

    Hx0, Hx1, Hy0, Hy1 = X0 - Pad, X1 + Pad, Y0 - Pad, Y1 + Pad
    Padded = np.zeros((Hy1 - Hy0, Hx1 - Hx0), dtype=np.float32)
    Sy0, Sx0 = max(0, Hy0), max(0, Hx0)
    Sy1, Sx1 = min(Height, Hy1), min(Width, Hx1)
    Padded[Sy0 - Hy0:Sy1 - Hy0, Sx0 - Hx0:Sx1 - Hx0] = Tube[Sy0:Sy1, Sx0:Sx1]
    Small = scaled(Padded, max(8, round(Padded.shape[1] * Scale / HaloShare)))
    Glow = ndimage.gaussian_filter(Small, Sigma * Scale / HaloShare)
    Glow = Glow / max(Glow.max(), 1e-6)
    Blobs[f'tek-{Number}-halo'] = png(white_alpha(Glow))
    HaloBoxes.append(share_box(Hx0, Hy0, Hx1, Hy1, Width, Height))
    print(f'tek-{Number}: box {PartBoxes[-1]}, halo {HaloBoxes[-1]}')

  Manifest, Old = read_set(SetPath)
  Kept = [Sprite for Sprite in Manifest['sprites'] if not Sprite['name'].startswith('tek-')]
  New = [{'name': Name, 'description': 'the TeK emblem under the main dome, make_emblem.py',
    'offset': 0, 'size': 0} for Name in Blobs]
  Manifest['sprites'] = Kept + New
  write_set(SetPath, Manifest, dict(Old, **Blobs))

  with open(LayoutPath, encoding='utf-8') as Source:
    Text = Source.read()
  Aspect = round(Height / Width, 4)
  Lines = f'"aspect": {Aspect}, "parts": {json.dumps(PartBoxes)},\n    "halos": {json.dumps(HaloBoxes)}'
  Pattern = re.compile(r'("emblem": \{\n[\s\S]*?\n    )"aspect": [^\n]*\n    "halos": [^\n]*')
  if not Pattern.search(Text):
    print('the layout has no "emblem" section with "aspect" and "halos": the set is written, the layout not')
    sys.exit(1)
  Text = Pattern.sub(lambda M: M.group(1) + Lines, Text, count=1)
  with open(LayoutPath, 'w', encoding='utf-8', newline='\n') as Out:
    Out.write(Text)
  print(f'{len(Parts)} parts into {SetPath} and the layout')


if __name__ == '__main__':
  main()
