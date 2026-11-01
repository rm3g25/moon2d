"""Cuts a sheet of the city's buildings into one PNG a building.

A sheet is one generation of many buildings in a row on a transparent
ground, a clear gap between any two (chase-backdrop.md, "The city"). Every
part of the alpha that holds together is a building; they are named
<prefix>-01, <prefix>-02... left to right. The edge of each is cleaned of
the coloured fringe the generations leave there: its colour is taken from
the solid pixels just inside, and the alpha is pulled in by a pixel.

The size of a building in units follows its pixels: every sheet is drawn at
one scale (the sheets after the first are made with the first attached), so
one number - pixels a unit - serves them all.

  python cut_sheet.py <sheet>.png <prefix> <work folder> [expected count]

Prints each building's size in pixels and in units; warns if the count is
not the one expected - two buildings joined by a painted base or a road come
out as one, and the sheet is to be generated again, not retouched.
Needs Pillow, numpy and scipy.
"""
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

# Pixels a unit on every sheet: the tallest tower of the first sheet, 645 px,
# stands 110 units
SheetPxPerUnit = 645 / 110
# Alpha that counts as the building; parts smaller than this are dust
BodyAlpha = 40
LeastPixels = 400
Margin = 4


def clean_edge(APiece, AOwn):
  Alpha = APiece[..., 3] * ndimage.binary_dilation(AOwn, iterations=2)
  Core = ndimage.binary_erosion(Alpha > 250, iterations=2)
  if Core.any():
    Rows, Cols = ndimage.distance_transform_edt(~Core, return_distances=False,
      return_indices=True)
    Inside = APiece[..., :3][Rows, Cols]
    APiece[..., :3][~Core] = Inside[~Core]
  APiece[..., 3] = np.minimum(Alpha, ndimage.grey_erosion(Alpha, size=(3, 3)))
  return APiece


def main():
  if len(sys.argv) < 4:
    print(__doc__)
    sys.exit(2)
  SheetPath, Prefix, Folder = sys.argv[1:4]
  Expected = int(sys.argv[4]) if len(sys.argv) > 4 else 0
  os.makedirs(Folder, exist_ok=True)
  Sheet = np.asarray(Image.open(SheetPath).convert('RGBA')).astype(np.float32)
  Body = ndimage.binary_closing(Sheet[..., 3] > BodyAlpha, iterations=2)
  Labels, _ = ndimage.label(Body)
  Found = []
  for Index, Box in enumerate(ndimage.find_objects(Labels)):
    if (Labels[Box] == Index + 1).sum() < LeastPixels:
      continue
    Top, Bottom = max(Box[0].start - Margin, 0), Box[0].stop + Margin
    Left, Right = max(Box[1].start - Margin, 0), Box[1].stop + Margin
    Piece = clean_edge(Sheet[Top:Bottom, Left:Right].copy(),
      Labels[Top:Bottom, Left:Right] == Index + 1)
    Found.append((Box[1].start, Piece))
  Found.sort(key=lambda Item: Item[0])
  for Number, (_, Piece) in enumerate(Found, 1):
    Name = f'{Prefix}-{Number:02d}'
    Image.fromarray(Piece.clip(0, 255).astype(np.uint8)).save(os.path.join(Folder, Name + '.png'))
    Height, Width = Piece.shape[:2]
    print(f'{Name}: {Width}x{Height} px, {Width / SheetPxPerUnit:.0f} x {Height / SheetPxPerUnit:.0f} units')
  if Expected and len(Found) != Expected:
    print(f'warning: {len(Found)} buildings, {Expected} expected - joined or split ones')


if __name__ == '__main__':
  main()
