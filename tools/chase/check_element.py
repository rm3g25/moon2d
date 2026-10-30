"""Checks one generated element of the chase backdrop before it goes on:
a real alpha channel (not a painted checkerboard), the object whole
(nothing of it cut by the edge of the frame), no light fringe left by the
matting, and where the light falls on it. Then trims it to its alpha and
scales it to the size the layout gives it, within 2048 px.

  python check_element.py <id> in.png [out.png]

<id> is an element of layout.json (cliff, dome-main, dome-sat, monorail,
hangar, landing-ring, dish) or a texture (ridge-tex, floor-tex, sand-tex).
The verdict is PASS, WARN or FAIL per check; the exit code is 1 on any FAIL.
Needs numpy and Pillow.
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageFilter

MaxSide = 2048 # px: old cards
TargetPxPerUnit = 5.625 # 4K: 384 units letterboxed into 2160 px; 1080p is 2.8125
LeastPxPerUnit = 3.5 # below this the far plane goes soft at 4K
Opaque = 128
EdgeTouchShare = 0.002 # of a border's pixels, opaque, before it counts as cut
FringeLift = 1.35 # a rim this much brighter than the body next to it is a halo
BodyNearby = 0.15 # a rim pixel needs this much solid body around it to be judged

# The edges an element may touch. The cliff is a wall: it runs out of the
# frame on the left, the top and the bottom. A texture fills its frame.
AllowedEdges = {
  'cliff': {'left', 'top', 'bottom'},
  'ridge-tex': {'left', 'right', 'bottom'},
  'floor-tex': {'left', 'right', 'top', 'bottom'},
  'sand-tex': {'left', 'right', 'bottom'},
}

# A texture that fills its whole frame has no alpha to check.
SolidTextures = {'floor-tex'}

LayoutPath = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'layout.json')


def find_element(AId):
  with open(LayoutPath, encoding='utf-8') as Source:
    Layout = json.load(Source)
  for Layer in Layout['layers']:
    for Element in Layer.get('elements', []):
      if Element['id'] == AId:
        return Element
  return None


def report(AVerdict, AWhat):
  print(f'{AVerdict:5} {AWhat}')
  return AVerdict


def check_alpha(AImage):
  if AImage.mode not in ('RGBA', 'LA', 'PA') and 'transparency' not in AImage.info:
    return report('FAIL', 'no alpha channel at all - the background is painted')
  Alpha = np.asarray(AImage.convert('RGBA'))[..., 3]
  Clear = (Alpha < 8).mean()
  Half = ((Alpha >= 8) & (Alpha < 248)).mean()
  if Clear < 0.02:
    return report('FAIL', f'alpha present but only {Clear:.1%} clear - a painted ground?')
  return report('PASS', f'alpha: {Clear:.1%} clear, {Half:.1%} half-clear')


def check_checkerboard(ARgba):
  # A painted checkerboard is opaque, grey or white, in two levels that
  # alternate in squares. Look at the frame's outer band, where the ground is.
  Band = np.concatenate([ARgba[:24].reshape(-1, 4), ARgba[-24:].reshape(-1, 4),
    ARgba[:, :24].reshape(-1, 4), ARgba[:, -24:].reshape(-1, 4)])
  Solid = Band[Band[:, 3] > 240][:, :3].astype(int)
  if len(Solid) < len(Band) * 0.5:
    return report('PASS', 'no checkerboard: the frame band is clear')
  Grey = (Solid.max(1) - Solid.min(1) < 10) & (Solid.mean(1) > 150)
  if Grey.mean() > 0.6:
    Levels = np.unique((Solid[Grey].mean(1) // 16).astype(int))
    if len(Levels) <= 4:
      return report('FAIL', 'checkerboard painted into the picture (grey/white squares, opaque)')
  return report('PASS', 'no checkerboard in the frame band')


def check_edges(AAlpha, AAllowed):
  Edges = {'top': AAlpha[0], 'bottom': AAlpha[-1], 'left': AAlpha[:, 0], 'right': AAlpha[:, -1]}
  Verdict = 'PASS'
  for Name, Line in Edges.items():
    Touch = (Line > Opaque).mean()
    if Touch <= EdgeTouchShare:
      continue
    if Name in AAllowed:
      report('PASS', f'touches the {Name} edge ({Touch:.1%}), as it may')
      continue
    Verdict = report('FAIL', f'cut by the {Name} edge of the frame ({Touch:.1%} of it opaque)')
  if Verdict == 'PASS':
    report('PASS', 'whole: no edge cuts it')
  return Verdict


def luma(ARgb):
  return ARgb[..., 0] * 0.299 + ARgb[..., 1] * 0.587 + ARgb[..., 2] * 0.114


def body_colour_near(APixels):
  # The colour of the solid body nearest to every pixel, and how much body
  # there is nearby (0..1).
  Solid = (APixels[..., 3] > 248).astype(float)
  Spread = Image.fromarray((Solid * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(3))
  Weight = np.asarray(Spread).astype(float) / 255
  Colour = np.zeros(APixels.shape[:2] + (3,))
  for Channel in range(3):
    Body = Image.fromarray((APixels[..., Channel] * Solid).astype(np.uint8))
    Blurred = np.asarray(Body.filter(ImageFilter.GaussianBlur(3))).astype(float)
    Colour[..., Channel] = Blurred / np.maximum(Weight, 0.01)
  return np.clip(Colour, 0, 255), Weight


def rim_mask(APixels, AWeight):
  return (APixels[..., 3] > 24) & (APixels[..., 3] < 200) & (AWeight > BodyNearby)


def check_fringe(ARgba):
  Pixels = ARgba.astype(float)
  Colour, Weight = body_colour_near(Pixels)
  Rim = rim_mask(Pixels, Weight)
  if Rim.sum() < 100:
    return report('PASS', 'no fringe to speak of'), False
  Lift = np.median(luma(Pixels[..., :3])[Rim] / np.maximum(luma(Colour)[Rim], 8))
  if Lift > FringeLift:
    return report('WARN', f'light fringe: the half-clear rim is {Lift:.2f}x the body next to it - defringed'), True
  return report('PASS', f'fringe clean ({Lift:.2f}x the body next to it)'), False


def report_light(ARgba):
  # Where the light falls, for the eye to judge: contre-jour wanted, the
  # rim brighter than the faces, no side much brighter than the other.
  Alpha = ARgba[..., 3] > 248
  Light = luma(ARgba[..., :3].astype(float))
  Ys, Xs = np.nonzero(Alpha)
  if len(Xs) == 0:
    return
  MidX = (Xs.min() + Xs.max()) // 2
  Left = Light[Alpha & (np.arange(Alpha.shape[1])[None, :] < MidX)].mean()
  Right = Light[Alpha & (np.arange(Alpha.shape[1])[None, :] >= MidX)].mean()
  print(f'INFO  light: left half {Left:.0f}, right half {Right:.0f}, body mean {Light[Alpha].mean():.0f}')


def defringe(AImage):
  # The half-clear rim keeps the colour of the ground it was matted from -
  # white sky, as a rule - and glows on the black of the Moon's. Its colour
  # is taken from the solid body next to it; its alpha stays.
  Pixels = np.asarray(AImage).astype(float)
  Colour, Weight = body_colour_near(Pixels)
  Rim = rim_mask(Pixels, Weight)
  Pixels[..., :3] = np.where(Rim[..., None], Colour, Pixels[..., :3])
  return Image.fromarray(Pixels.astype(np.uint8), 'RGBA')


def trim_and_scale(AImage, AElement, AOutPath, AFringed):
  Box = AImage.getchannel('A').point(lambda AValue: 255 if AValue > 8 else 0).getbbox()
  Trimmed = AImage.crop(Box)
  # The faint glow some generations leave around the object (alpha under 10)
  # reads as a halo on the black sky; it goes. The body that stops at 254
  # would let the sun's halo through the rock; it is made solid.
  Alpha = Trimmed.getchannel('A').point(lambda AValue: 0 if AValue < 10 else 255 if AValue > 248 else AValue)
  Trimmed.putalpha(Alpha)
  if AFringed:
    Trimmed = defringe(Trimmed)
  if AElement is None:
    Trimmed.save(AOutPath)
    print(f'INFO  texture kept at {Trimmed.size}')
    return
  # Fit inside the layout's box: a full-height cliff is set by its height,
  # a dome by its width. The other side follows the picture.
  Scale = min(AElement['w'] / Trimmed.width, AElement['h'] / Trimmed.height) * TargetPxPerUnit
  Size = (round(Trimmed.width * Scale), round(Trimmed.height * Scale))
  if max(Size) > MaxSide:
    Shrink = MaxSide / max(Size)
    Size = (round(Size[0] * Shrink), round(Size[1] * Shrink))
  FitUnits = min(AElement['w'] / Trimmed.width, AElement['h'] / Trimmed.height)
  UnitsWide, UnitsTall = Trimmed.width * FitUnits, Trimmed.height * FitUnits
  Density = Size[0] / UnitsWide
  Trimmed.resize(Size, Image.LANCZOS).save(AOutPath)
  Verdict = 'PASS' if Density >= LeastPxPerUnit else 'WARN'
  report(Verdict, f'trimmed {Trimmed.size} -> {Size}, {Density:.1f} px a unit (4K wants {TargetPxPerUnit})')
  print(f'INFO  in the game: {UnitsWide:.0f} x {UnitsTall:.0f} units (layout box {AElement["w"]} x {AElement["h"]})')
  if Size[0] > Trimmed.width:
    print(f'INFO  upscaled x{Size[0] / Trimmed.width:.2f} - from a {Trimmed.width} px object')


def main():
  if len(sys.argv) < 3:
    print(__doc__)
    sys.exit(2)
  Id, InPath = sys.argv[1], sys.argv[2]
  OutPath = sys.argv[3] if len(sys.argv) > 3 else os.path.splitext(InPath)[0] + '.checked.png'
  Image.MAX_IMAGE_PIXELS = None
  Source = Image.open(InPath)
  print(f'INFO  {Id}: {InPath}, {Source.size}, {Source.mode}')
  if Id in SolidTextures:
    Verdicts = [report('PASS', 'solid texture: no alpha wanted')]
  else:
    Verdicts = [check_alpha(Source)]
    if Verdicts[0] == 'FAIL':
      sys.exit(1)
  Rgba = Source.convert('RGBA')
  Pixels = np.asarray(Rgba)
  if Id not in SolidTextures:
    Verdicts.append(check_checkerboard(Pixels))
    Verdicts.append(check_edges(Pixels[..., 3], AllowedEdges.get(Id, set())))
  FringeVerdict, Fringed = check_fringe(Pixels)
  Verdicts.append(FringeVerdict)
  report_light(Pixels)
  trim_and_scale(Rgba, find_element(Id), OutPath, Fringed)
  sys.exit(1 if 'FAIL' in Verdicts else 0)


if __name__ == '__main__':
  main()
