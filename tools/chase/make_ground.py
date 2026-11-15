"""Packs the ground from above - the tile of the plane under the titles' lifted
eye (docs/mechanics/finale-flight.md, "The ground for a lifted eye") - into
bin/sprites/chase-backdrop.mset, and prints the two colours the layout's
"plane" section wants.

The game has no sampler that wraps and none that squeezes: a far row of the
plane covers many rows of the tile, and taken from the tile itself it
shimmers in motion. So the tile goes into the set as copies, <tile>-0 the
tile itself with its light raised by the layout's gain, each next one the
one before it squeezed twice in height - and in width too past the first
wideLevels of them: across, a row is foreshortened far less than into the
depth. The numbers are the layout's (bin/chase-backdrop.json, "plane"):
tile, gain, levels, wideLevels. Every other picture of the set is kept
byte for byte.

Printed, to be put into "plane" by hand: mean - the tile's mean colour under
the gain, what the far ground goes to; foot - the mean of the lowest rows of
the crater floor's band, the fill under its foot.

  python make_ground.py [ground-top.png] [out.mset]

Needs Pillow and numpy.
"""
import io
import json
import os
import struct
import sys

import numpy as np
from PIL import Image

Here = os.path.dirname(os.path.abspath(__file__))
Root = os.path.join(Here, '..', '..')
LayoutPath = os.path.join(Root, 'bin', 'chase-backdrop.json')
DefaultTile = os.path.join(Here, 'ground-top.png')
DefaultSet = os.path.join(Root, 'bin', 'sprites', 'chase-backdrop.mset')
# The rows of the floor's texture its foot is the mean of, as the stand takes it
FootRows = 4


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
  Text = json.dumps(dict(AManifest, sprites=Sprites), indent=2).encode('utf-8')
  with open(APath, 'wb') as Out:
    Out.write(b'MSET')
    Out.write(struct.pack('<HI', 1, len(Text)))
    Out.write(Text)
    for Sprite in Sprites:
      Out.write(ABlobs[Sprite['name']])


def png(APicture):
  Buffer = io.BytesIO()
  APicture.save(Buffer, 'PNG', optimize=True)
  return Buffer.getvalue()


def level_size(ASize, ALevel, AWideLevels):
  Width, Height = ASize
  return max(1, Width >> max(0, ALevel - AWideLevels)), max(1, Height >> ALevel)


def squeezed_copies(ATile, APlane):
  """The tile under the gain, then each copy from the one before it."""
  Lit = np.asarray(ATile.convert('RGB')).astype(np.float64) * APlane['gain']
  Copies = [Image.fromarray(np.clip(np.rint(Lit), 0, 255).astype(np.uint8), 'RGB')]
  for Level in range(1, APlane['levels']):
    Size = level_size(ATile.size, Level, APlane['wideLevels'])
    Copies.append(Copies[-1].resize(Size, Image.BOX))
  return Copies


def mean_colour(APicture):
  return [int(round(Channel)) for Channel in
    np.asarray(APicture.convert('RGB')).reshape(-1, 3).mean(axis=0)]


def main():
  TilePath = sys.argv[1] if len(sys.argv) > 1 else DefaultTile
  SetPath = sys.argv[2] if len(sys.argv) > 2 else DefaultSet
  with open(LayoutPath, encoding='utf-8') as Source:
    Layout = json.load(Source)
  Plane = Layout['plane']
  Manifest, Blobs = read_set(SetPath)
  Copies = squeezed_copies(Image.open(TilePath), Plane)

  Named = [f"{Plane['tile']}-{Level}" for Level in range(len(Copies))]
  Sprites = [Sprite for Sprite in Manifest['sprites'] if Sprite['name'] not in Named]
  for Level, (Name, Copy) in enumerate(zip(Named, Copies)):
    Blobs[Name] = png(Copy)
    What = 'the tile under its gain' if Level == 0 else f'squeezed to {Copy.width} x {Copy.height}'
    Sprites.append({'name': Name, 'description':
      f"the ground from above, the plane under the titles' eye: {What}"})
  write_set(SetPath, dict(Manifest, sprites=Sprites), Blobs)
  print(f'{SetPath}: {", ".join(f"{Name} {Copy.width}x{Copy.height}" for Name, Copy in zip(Named, Copies))}')

  Floor = next(Layer['band']['texture'] for Layer in Layout['layers']
    if Layer['id'] == 'city' and 'band' in Layer)
  FloorPicture = Image.open(io.BytesIO(Blobs[Floor]))
  Foot = FloorPicture.crop((0, FloorPicture.height - FootRows, FloorPicture.width, FloorPicture.height))
  print(f'"mean": {mean_colour(Copies[0])}')
  print(f'"foot": {mean_colour(Foot)}')


if __name__ == '__main__':
  main()
