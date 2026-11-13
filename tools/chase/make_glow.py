"""Finds the lit glass of the farm's pieces and writes it as a picture of
its own (chase-backdrop.md, "The farm").

The greenhouses come from their sheets with the glass glowing from inside -
hot magenta, amber sodium, cool blue - and the frame, the core and the walls
lit as the city's buildings are, from the front whatever the prompt said.
The shade puts a building in the night, and the glass with it; the glass is
the one thing of the farm that shines, so it is kept apart: <id>-glow is
the piece's own pixels where the glass is lit, its alpha the share of the
glow, nothing else. The stand and the game draw it over the shaded piece,
not shaded.

The glass is found by its colour: saturated and bright in one of the three
hues of the grow light. The thin warm rim of the sun along a silhouette is
pale, and the yellow and black stripes of a door are small: an opening by a
pixel takes both away. What is left of a piece under MinShare of its body
is no glass at all, and no picture is written.

The colour and the place of each piece's light - its mean colour, the centre
of its glass and its share of the picture - go into the layout's farm
("glass"): the light of the dome's air is gathered from them.

  python make_glow.py <work folder> <prefix,prefix...> [--write]

Reads the pieces of the city's kit (bin/chase-backdrop.json) named by the
prefixes - the farm's sheets: agro,hall,svc - and their pictures from the
folder, writes <id>-glow.png beside them; --write puts the lights into the
layout's farm. Needs Pillow, numpy and scipy.
"""
import colorsys
import json
import os
import re
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

Here = os.path.dirname(os.path.abspath(__file__))
LayoutPath = os.path.join(Here, '..', '..', 'bin', 'chase-backdrop.json')
# The hues of the grow light, in degrees, and how saturated and bright the
# lit glass is at the least: the blue is the palest of the three
Hues = {'magenta': (285, 350, 0.32, 0.42), 'amber': (18, 52, 0.32, 0.42),
  'blue': (185, 240, 0.15, 0.45)}
# A glow too small to be glass: a lit window, a stripe of a door
MinShare = 0.05


def glass_mask(APicture):
  Rgb = APicture[..., :3] / 255.0
  Most = Rgb.max(axis=2)
  Least = Rgb.min(axis=2)
  Saturation = np.where(Most > 0, (Most - Least) / np.maximum(Most, 1e-6), 0)
  Hue = np.zeros_like(Most)
  Span = np.maximum(Most - Least, 1e-6)
  R, G, B = Rgb[..., 0], Rgb[..., 1], Rgb[..., 2]
  Hue = np.where(Most == R, ((G - B) / Span) % 6, Hue)
  Hue = np.where(Most == G, (B - R) / Span + 2, Hue)
  Hue = np.where(Most == B, (R - G) / Span + 4, Hue)
  Hue = Hue * 60
  Lit = np.zeros(Most.shape, bool)
  for From, To, LeastSaturation, LeastValue in Hues.values():
    Lit |= (Hue >= From) & (Hue <= To) & (Saturation >= LeastSaturation) & (Most >= LeastValue)
  Lit &= APicture[..., 3] > 128
  Lit = ndimage.binary_opening(Lit, iterations=1)
  # the mullions between the panes are the frame's, not the glass's: a soft
  # edge of a pixel keeps the grid of the picture
  Soft = ndimage.gaussian_filter(Lit.astype(float), 0.7)
  return np.clip(Soft * 1.4, 0, 1) * Lit.any()


def light_of(APicture, AMask):
  Weight = AMask * (APicture[..., 3] / 255.0)
  Total = Weight.sum()
  Rgb = (APicture[..., :3] * Weight[..., None]).reshape(-1, 3).sum(axis=0) / Total
  # the colour of the light, not of the glass: brought up to full brightness
  Rgb = Rgb * 255 / max(Rgb.max(), 1)
  Rows, Cols = np.indices(AMask.shape)
  U = float((Cols * Weight).sum() / Total / AMask.shape[1])
  V = float((Rows * Weight).sum() / Total / AMask.shape[0])
  Share = float(Total / max((APicture[..., 3] > 128).sum(), 1))
  return [int(round(c)) for c in Rgb], [round(U, 4), round(V, 4)], round(Share, 4)


def main():
  if len(sys.argv) < 3:
    print(__doc__)
    sys.exit(2)
  Folder = sys.argv[1]
  Prefixes = tuple(Prefix + '-' for Prefix in sys.argv[2].split(','))
  with open(LayoutPath, encoding='utf-8') as Source:
    Text = Source.read()
  Kit = json.loads(Text)['cityKit']['pieces']
  Glass = {}
  for Id in [Id for Id in Kit if Id.startswith(Prefixes)]:
    Picture = np.array(Image.open(os.path.join(Folder, Id + '.png')).convert('RGBA'))
    Mask = glass_mask(Picture)
    Body = (Picture[..., 3] > 128).sum()
    if Mask.sum() < MinShare * Body:
      print(f'{Id}: no glass')
      continue
    Glow = Picture.copy()
    Glow[..., 3] = (Mask * Picture[..., 3]).astype(np.uint8)
    Image.fromarray(Glow).save(os.path.join(Folder, Id + '-glow.png'), optimize=True)
    Color, At, Share = light_of(Picture, Mask)
    Glass[Id] = {'color': Color, 'at': At, 'share': Share}
    print(f'{Id}: glass {Share:.0%} of the body, colour {Color}, at {At}')
  if '--write' not in sys.argv:
    return
  Pattern = re.compile(r'("farm": \{[\s\S]*?"glass": \{)([\s\S]*?)(\n    \})')
  if not Pattern.search(Text):
    print('the layout has no "farm" section with "glass": nothing written')
    sys.exit(1)
  Lines = ',\n'.join(f'      "{Id}": {{ "color": {json.dumps(G["color"])}, "at": {json.dumps(G["at"])}, '
    f'"share": {G["share"]} }}' for Id, G in Glass.items())
  Text = Pattern.sub(lambda M: M.group(1) + '\n' + Lines + M.group(3), Text, count=1)
  with open(LayoutPath, 'w', encoding='utf-8', newline='\n') as Out:
    Out.write(Text)
  print(f'{LayoutPath}: the glass of {len(Glass)} pieces written')


if __name__ == '__main__':
  main()
