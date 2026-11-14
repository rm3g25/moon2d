"""Builds the stand of the chase backdrop: one self-contained HTML page that
plays the layers of the layout (bin/chase-backdrop.json) over time, with every checked element of
chase-backdrop.mset and the backdrop of screen 13 put inside it. For the
titles (docs/mechanics/finale-flight.md) it takes the camera's path and the track's
cues (bin/finale.json), and the play layer's pictures from their sets: the
road's tile, the gate's facade, the main barge, the hero and the menu's logo.
The fangs' kit comes from the sets the layout names.

  python build_stand.py [out.html] [--track]

--track puts the end track (bin/music/credits.ogg) inside too: the titles
play under it. Open the page in a browser or publish it as an artifact.
Elements not in the set yet are drawn as placeholders; a PNG named by its id
can be dropped on the stage to try a new take before it is packed. Needs
Pillow.
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
LayoutPath = os.path.join(Here, '..', '..', 'bin', 'chase-backdrop.json')
FinalePath = os.path.join(Root, 'bin', 'finale.json')
TrackPath = os.path.join(Root, 'bin', 'music', 'credits.ogg')
ChaseSet = os.path.join(Root, 'bin', 'sprites', 'chase-backdrop.mset')
BackdropSet = os.path.join(Root, 'bin', 'sprites', 'level2-backdrops.mset')
ObjectSet = os.path.join(Root, 'bin', 'sprites', 'level2-objects.mset')
UiSet = os.path.join(Root, 'bin', 'sprites', 'ui.mset')
PadSet = os.path.join(Root, 'bin', 'sprites', 'pads.mset')
HeroSet = os.path.join(Root, 'bin', 'sprites', 'hero.mset')
TrackFlag = '--track'
# The play layer's pictures of the titles: the stand's id, the set, the sprite
TitlePictures = [('road-tile', ObjectSet, 'tek-road-tile'), ('gate', ObjectSet, 's13-gate'),
  ('barge', PadSet, 'barge-5'), ('hero', HeroSet, '1'), ('logo', UiSet, 'logo')]
DefaultOut = 'chase-stand.html'
SolidTextures = {'floor-tex'} # shipped as JPEG: no alpha, a third of the size
SpritesPath = os.path.join(Root, 'bin', 'sprites')
# The fangs are packed at 6 px a unit and drawn at 0.8 of their size at the
# most: 2.25 px a unit on the stand's stage. Halved, they ship at a quarter
# of the bytes and still over that
FangShipScale = 0.5
# The ground from above, for the plane under a lifted eye: checked, its weave
# taken out, not packed into the set yet
GroundTopPath = os.path.join(Here, 'ground-top.png')


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


def scaled(APng, AScale):
  Picture = Image.open(io.BytesIO(APng))
  Size = (round(Picture.width * AScale), round(Picture.height * AScale))
  Buffer = io.BytesIO()
  Picture.resize(Size, Image.LANCZOS).save(Buffer, 'PNG')
  return Buffer.getvalue()


def track_url():
  with open(TrackPath, 'rb') as Source:
    return 'data:audio/ogg;base64,' + base64.b64encode(Source.read()).decode()


def main():
  Names = [Arg for Arg in sys.argv[1:] if Arg != TrackFlag]
  OutPath = Names[0] if Names else DefaultOut
  with open(TemplatePath, encoding='utf-8') as Source:
    Page = Source.read()
  with open(LayoutPath, encoding='utf-8') as Source:
    Layout = Source.read().strip()
  Shipped = {}
  if os.path.exists(ChaseSet):
    Shipped = {Id: data_url(Png, Id in SolidTextures) for Id, Png in read_set(ChaseSet).items()}
  for Id, SetPath, Sprite in TitlePictures:
    Shipped[Id] = data_url(read_set(SetPath)[Sprite])
  for Kind in json.loads(Layout).get('fangs', {}).get('kit', []):
    SetName, Sprite = Kind['sprite'].split(':')
    Picture = read_set(os.path.join(SpritesPath, SetName + '.mset'))[Sprite]
    Shipped[Sprite] = data_url(scaled(Picture, FangShipScale))
  if os.path.exists(GroundTopPath):
    with open(GroundTopPath, 'rb') as Source:
      Shipped['ground-top'] = data_url(Source.read(), AJpeg=True)
  Screen13 = data_url(read_set(BackdropSet)['screen13'], AJpeg=True)
  with open(FinalePath, encoding='utf-8') as Source:
    Finale = Source.read().strip()
  Track = track_url() if TrackFlag in sys.argv else ''
  Page = Page.replace('/*LAYOUT*/null', Layout)
  Page = Page.replace("/*LAYOUTTEXT*/''", json.dumps(Layout + '\n'))
  Page = Page.replace('/*SHIPPED*/{}', json.dumps(Shipped))
  Page = Page.replace("/*SCREEN13*/''", json.dumps(Screen13))
  Page = Page.replace('/*FINALE*/null', Finale)
  Page = Page.replace("/*TRACK*/''", json.dumps(Track))
  with open(OutPath, 'w', encoding='utf-8', newline='\n') as Out:
    Out.write(Page)
  print(f'{OutPath}: {len(Shipped)} elements, {len(Page) / 1e6:.1f} MB')


if __name__ == '__main__':
  main()
