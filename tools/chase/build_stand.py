"""Builds the stand of the chase backdrop: one self-contained HTML page that
plays the layers of layout.json over time, with every checked element of
chase-backdrop.mset and the backdrop of screen 13 put inside it.

  python build_stand.py [out.html]

Open the page in a browser or publish it as an artifact. Elements not in the
set yet are drawn as placeholders; a PNG named by its id can be dropped on
the stage to try a new take before it is packed. Needs Pillow.
"""
import base64
import io
import json
import os
import struct
import sys

from PIL import Image

Here = os.path.dirname(os.path.abspath(__file__))
Root = os.path.join(Here, '..', '..')
TemplatePath = os.path.join(Here, 'stand.template.html')
LayoutPath = os.path.join(Here, 'layout.json')
ChaseSet = os.path.join(Root, 'bin', 'sprites', 'chase-backdrop.mset')
BackdropSet = os.path.join(Root, 'bin', 'sprites', 'level2-backdrops.mset')
DefaultOut = 'chase-stand.html'
SolidTextures = {'floor-tex'} # shipped as JPEG: no alpha, a third of the size


def read_set(APath):
  with open(APath, 'rb') as Source:
    Data = Source.read()
  Size = struct.unpack('<I', Data[6:10])[0]
  Manifest = json.loads(Data[10:10 + Size])
  Base = 10 + Size
  return {Sprite['name']: Data[Base + Sprite['offset']:Base + Sprite['offset'] + Sprite['size']]
    for Sprite in Manifest['sprites']}


def data_url(APng, AJpeg=False):
  if not AJpeg:
    return 'data:image/png;base64,' + base64.b64encode(APng).decode()
  Buffer = io.BytesIO()
  Image.open(io.BytesIO(APng)).convert('RGB').save(Buffer, 'JPEG', quality=90)
  return 'data:image/jpeg;base64,' + base64.b64encode(Buffer.getvalue()).decode()


def main():
  OutPath = sys.argv[1] if len(sys.argv) > 1 else DefaultOut
  with open(TemplatePath, encoding='utf-8') as Source:
    Page = Source.read()
  with open(LayoutPath, encoding='utf-8') as Source:
    Layout = Source.read().strip()
  Shipped = {}
  if os.path.exists(ChaseSet):
    Shipped = {Id: data_url(Png, Id in SolidTextures) for Id, Png in read_set(ChaseSet).items()}
  Screen13 = data_url(read_set(BackdropSet)['screen13'], AJpeg=True)
  Page = Page.replace('/*LAYOUT*/null', Layout)
  Page = Page.replace('/*SHIPPED*/{}', json.dumps(Shipped))
  Page = Page.replace("/*SCREEN13*/''", json.dumps(Screen13))
  with open(OutPath, 'w', encoding='utf-8', newline='\n') as Out:
    Out.write(Page)
  print(f'{OutPath}: {len(Shipped)} elements, {len(Page) / 1e6:.1f} MB')


if __name__ == '__main__':
  main()
