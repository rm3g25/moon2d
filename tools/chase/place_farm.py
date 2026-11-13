"""The first placement of the farm under its long dome (chase-backdrop.md,
"The farm"): the greenhouses of the kit in rows at six depths inside the
capsule's footprint, every one under the shell with room to spare, the big
ones in the middle rows, the service pieces between; the deeper rows darker.
From there by hand on the stand, as the city was.

The depth of a row is its Z from the capsule's centre line, toward the far
side positive; its feet stand where the camera puts that depth, and a
piece's width in the layout is its width at its depth - the kit's size times
its nearness. A piece's centre along the layer is the dome's centre plus its
X from it, whatever the city's offset: the frame and the buildings ride as
one.

The city's buildings whose feet stand inside the footprint are taken out.
The farm's pieces already placed are replaced.

  python place_farm.py [seed]

Writes the city layer of bin/chase-backdrop.json, one element to a line,
back to front, the rest of the file as it was.
"""
import json
import math
import os
import random
import re
import sys

Here = os.path.dirname(os.path.abspath(__file__))
LayoutPath = os.path.join(Here, '..', '..', 'bin', 'chase-backdrop.json')
FarmPrefixes = ('agro-', 'hall-', 'svc-')
# The rows, back to front: depth from the centre line, the shade, and what
# stands in them
Rows = [(80, 0.30, 'halls'), (50, 0.33, 'mixed'), (18, 0.36, 'landmarks'),
  (-16, 0.39, 'landmarks'), (-50, 0.42, 'mixed'), (-80, 0.45, 'halls')]
# Room kept under the shell and to the ends, in units
HeadRoom = 6
EndRoom = 8


def inside(AFrame, AX, AY, AZ):
  R = AFrame['d'] / 2
  Barrel = AFrame['w'] / 2 - R
  Along = max(0.0, abs(AX) - Barrel)
  return (Along / R) ** 2 + (AZ / R) ** 2 + (AY / AFrame['h']) ** 2 <= 1


def element_line(E):
  Keys = ['id', 'x', 'y', 'w', 'h', 'tintsSun', 'shade', 'mirror', 'featherLeft', 'groundY', 'paint']
  Parts = [f'"{K}": {json.dumps(E[K]).replace(",", ", ")}' for K in Keys if K in E]
  return '        { ' + ', '.join(Parts) + ' }'


def main():
  Rng = random.Random(int(sys.argv[1]) if len(sys.argv) > 1 else 19)
  with open(LayoutPath, encoding='utf-8') as Source:
    Text = Source.read()
  Layout = json.loads(Text)
  Camera = Layout['camera']
  Frame = next(F for F in Layout['frames']['items'] if F['id'] == Layout['farm']['frame'])
  Kit = Layout['cityKit']['pieces']
  City = next(L for L in Layout['layers'] if L['id'] == 'city')
  Centre = Frame['x'] + Frame['w'] / 2
  R = Frame['d'] / 2
  Barrel = Frame['w'] / 2 - R

  def depth_of(AY):
    K = (AY - Camera['horizon']) / (Camera['baseY'] - Camera['horizon'])
    return Camera['focal'] / max(K, 1e-6) - Camera['focal']

  Kept = []
  for E in City['elements']:
    if E['id'].startswith(FarmPrefixes):
      continue
    Z = depth_of(E.get('groundY', E['y']))
    X = E['x'] + E['w'] / 2 - Centre
    if abs(Z) < R and abs(X) < Barrel + R and inside(Frame, X, 0, Z):
      print(f'out of the footprint: {E["id"]} at {E["x"]}')
      continue
    Kept.append(E)

  Pieces = {'landmarks': [I for I in Kit if I.startswith('agro-')],
    'halls': [I for I in Kit if I.startswith('hall-')],
    'service': [I for I in Kit if I.startswith('svc-')]}
  Placed = []
  for Z, Shade, Kind in Rows:
    K = Camera['focal'] / (Camera['focal'] + Z)
    Feet = round(Camera['horizon'] + (Camera['baseY'] - Camera['horizon']) * K, 1)
    Reach = Barrel + R * math.sqrt(max(0.0, 1 - (Z / R) ** 2)) - EndRoom
    X = -Reach + Rng.uniform(0, 12)
    Landmarks = Rng.sample(Pieces['landmarks'], 3) if Kind == 'landmarks' else []
    while X < Reach:
      if Landmarks and Rng.random() < 0.3:
        Pool = [Landmarks.pop()]
      else:
        Roll = Rng.random()
        Pool = Pieces['service'] if (Kind != 'halls' and Roll < 0.3) or Roll < 0.1 else Pieces['halls']
      Fitting = [I for I in Pool if all(inside(Frame, X + Dx, Kit[I][1] + HeadRoom, Z)
        for Dx in (0, Kit[I][0]))]
      if not Fitting:
        X += 6
        continue
      Id = Rng.choice(Fitting)
      W, H = Kit[Id]
      Placed.append({'id': Id, 'x': round(Centre + X + W / 2 - W * K / 2, 1), 'y': Feet,
        'w': round(W * K, 1), 'h': round(H * K, 1), 'shade': Shade, 'mirror': Rng.random() < 0.5})
      X += W + Rng.uniform(2, 9)
  Elements = sorted(Kept + Placed, key=lambda E: E.get('groundY', E['y']))
  Lines = ',\n'.join(element_line(E) for E in Elements)
  Pattern = re.compile(r'(\{ "id": "city"[\s\S]*?"elements": \[\n)([\s\S]*?)(\n      \] \},)')
  Text = Pattern.sub(lambda M: M.group(1) + Lines + M.group(3), Text, count=1)
  with open(LayoutPath, 'w', encoding='utf-8', newline='\n') as Out:
    Out.write(Text)
  print(f'{len(Placed)} pieces of the farm placed, {len(Kept)} of the city kept')


if __name__ == '__main__':
  main()
