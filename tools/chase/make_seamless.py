"""Makes a texture band of the chase backdrop seamless along its width, so
the code can repeat it with no seam: the far ridge, the crater floor, the
near sand. A generation is never asked to be seamless - it would not be.

The right end of the band is laid over its left end and faded across
Overlap of the width; the band comes out that much narrower, and its last
pixel runs on into its first. Alpha is faded with the colour, so a ragged
skyline crosses the join as a blend of two skylines, not a step.

A generation's skyline often runs downhill across the picture; repeated,
its two ends would meet at different heights and the join would show two
skylines. So first the band is levelled: each column is lifted or lowered
by the straight trend of its skyline, a shear no one sees in rock. The
band also loses whatever empty rows are left above and below it.

Then the light is evened along the band: a generation is often brighter at
one end, and repeated, that is a step of light every repeat. Each column is
brought to the band's mean by its broad brightness (blurred over a sixth of
the width), row band by row band; the fine detail and the light from top to
bottom stay as they were.

  python make_seamless.py in.png out.png [overlap 0..0.5]

Needs numpy and Pillow.
"""
import sys

import numpy as np
from PIL import Image, ImageFilter

DefaultOverlap = 0.25 # of the width
Solid = 128 # alpha that counts as the band's skyline


def level_skyline(APixels):
  Alpha = APixels[..., 3]
  Width = APixels.shape[1]
  Tops = np.array([np.argmax(Alpha[:, x] > Solid) for x in range(Width)], dtype=float)
  Slope, Offset = np.polyfit(np.arange(Width), Tops, 1)
  Shift = np.round(Slope * (np.arange(Width) - Width / 2)).astype(int)
  Result = np.zeros_like(APixels)
  Height = APixels.shape[0]
  for x in range(Width):
    Result[:, x] = np.roll(APixels[:, x], -Shift[x], axis=0)
    # Rolled-in pixels from the other end of the column are not the band's.
    if Shift[x] < 0:
      Result[:-Shift[x], x] = 0
  # A column lifted leaves a gap at the foot of the band; the band is cut
  # above the deepest gap rather than smeared down into it.
  Foot = Height - max(0, Shift.max())
  print(f'levelled: the skyline fell {Slope * Width:.0f} px across the band, {Height - Foot} px cut at the foot')
  return Result[:Foot]


EvenBlur = 1 / 6 # of the width: what counts as broad light, not detail
EvenRows = 8 # row bands evened separately, so a sheen at the top stays a sheen
GainLimit = (0.6, 1.6)


def even_light(APixels):
  Height, Width = APixels.shape[:2]
  Light = APixels[..., :3] @ np.array([0.299, 0.587, 0.114])
  Solid = APixels[..., 3] > 128
  Result = APixels.copy()
  Gains = []
  for Band in range(EvenRows):
    Top, Bottom = Height * Band // EvenRows, Height * (Band + 1) // EvenRows
    Mask = Solid[Top:Bottom]
    if Mask.sum() < Width:
      continue
    Sums = np.where(Mask, Light[Top:Bottom], 0).sum(0)
    Counts = Mask.sum(0)
    Radius = Width * EvenBlur
    Reach = int(3 * Radius)
    Kernel = np.exp(-0.5 * (np.arange(-Reach, Reach + 1) / Radius) ** 2)
    Broad = np.convolve(np.pad(Sums, Reach, mode='wrap'), Kernel, 'valid') / \
      np.maximum(np.convolve(np.pad(Counts, Reach, mode='wrap'), Kernel, 'valid'), 1e-6)
    Gain = np.clip(Broad[Counts > 0].mean() / np.maximum(Broad, 1), *GainLimit)
    Gains.append(Gain)
    Result[Top:Bottom, :, :3] = np.clip(APixels[Top:Bottom, :, :3] * Gain[None, :, None], 0, 255)
  if Gains:
    print(f'light evened: gains {min(G.min() for G in Gains):.2f}..{max(G.max() for G in Gains):.2f}')
  return Result


def trim_rows(APixels):
  Rows = np.nonzero((APixels[..., 3] > 8).any(axis=1))[0]
  return APixels[Rows.min():Rows.max() + 1]


def make_seamless(APixels, AOverlap):
  Width = APixels.shape[1]
  Span = int(Width * AOverlap)
  Kept = Width - Span
  # Smoothstep across the join reads softer than a straight fade.
  Ramp = np.linspace(0.0, 1.0, Span)
  Ramp = Ramp * Ramp * (3 - 2 * Ramp)
  Ramp = Ramp[None, :, None]
  Head = APixels[:, :Span]
  Tail = APixels[:, Kept:]
  Result = APixels[:, :Kept].copy()
  Result[:, :Span] = Tail * (1 - Ramp) + Head * Ramp
  return Result


def main():
  if len(sys.argv) < 3:
    print(__doc__)
    sys.exit(2)
  Overlap = float(sys.argv[3]) if len(sys.argv) > 3 else DefaultOverlap
  Source = np.asarray(Image.open(sys.argv[1]).convert('RGBA')).astype(float)
  Result = make_seamless(even_light(trim_rows(level_skyline(Source))), Overlap)
  Image.fromarray(np.clip(Result, 0, 255).astype(np.uint8), 'RGBA').save(sys.argv[2])
  print(f'{Source.shape[1]} px -> {Result.shape[1]} px, the join faded over {int(Source.shape[1] * Overlap)} px')


if __name__ == '__main__':
  main()
