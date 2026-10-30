"""Packs the checked elements of the chase backdrop into
bin/sprites/chase-backdrop.mset (format: docs/MSET-FORMAT.md).

The folder holds one PNG per element, named by its id in layout.json -
cliff.png, dome-main.png, ridge-tex.png... - as check_element.py and
make_seamless.py left them. A solid texture (the floor) may be a .jpg; it is
stored as PNG, the only image the sets carry. The order of the set is the
order of layout.json, the textures last.

  python pack_set.py <folder> [out.mset]

Needs Pillow.
"""
import io
import json
import os
import struct
import sys

from PIL import Image

Here = os.path.dirname(os.path.abspath(__file__))
LayoutPath = os.path.join(Here, 'layout.json')
DefaultOut = os.path.join(Here, '..', '..', 'bin', 'sprites', 'chase-backdrop.mset')
SetId = 'chase-backdrop'
SetDescription = ('The far plane of the arena 3 chase: the end of the tunnel and the city in the '
  'crater. Placed by tools/chase/layout.json; the plan is docs/mechanics/chase-backdrop.md.')


def ordered_ids():
  with open(LayoutPath, encoding='utf-8') as Source:
    Layout = json.load(Source)
  Ids, Textures = [], []
  for Layer in Layout['layers']:
    for Element in Layer.get('elements', []):
      if 'existing' not in Element:
        Ids.append((Element['id'], f"{Element['w']} x {Element['h']} units, layer {Layer['id']}"))
    Band = Layer.get('band')
    if Band and Band['texture'] not in [Id for Id, _ in Textures]:
      Textures.append((Band['texture'], f"seamless band of layer {Layer['id']}"))
  return Ids + Textures


def png_bytes(APath):
  if APath.lower().endswith('.png'):
    with open(APath, 'rb') as Source:
      return Source.read()
  Buffer = io.BytesIO()
  Image.open(APath).save(Buffer, 'PNG', optimize=True)
  return Buffer.getvalue()


def main():
  if len(sys.argv) < 2:
    print(__doc__)
    sys.exit(2)
  Folder = sys.argv[1]
  OutPath = sys.argv[2] if len(sys.argv) > 2 else DefaultOut
  Sprites, Blobs, Offset = [], [], 0
  for Id, Description in ordered_ids():
    Found = [Name for Name in (Id + '.png', Id + '.jpg') if os.path.exists(os.path.join(Folder, Name))]
    if not Found:
      print(f'missing {Id} - not generated yet')
      continue
    Blob = png_bytes(os.path.join(Folder, Found[0]))
    Sprites.append({'name': Id, 'description': Description, 'offset': Offset, 'size': len(Blob)})
    Blobs.append(Blob)
    Offset += len(Blob)
  Manifest = json.dumps({'id': SetId, 'description': SetDescription, 'sprites': Sprites},
    indent=2).encode('utf-8')
  with open(OutPath, 'wb') as Out:
    Out.write(b'MSET')
    Out.write(struct.pack('<HI', 1, len(Manifest)))
    Out.write(Manifest)
    for Blob in Blobs:
      Out.write(Blob)
  print(f'{OutPath}: {len(Sprites)} sprites, {Offset // 1024} KB of images')


if __name__ == '__main__':
  main()
