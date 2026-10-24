"""Draws the far lip of screen 12: the edge of the stratum the convoys ride
on, seen from far - a hair of light on its rim over a soft shadow, no
matter of its own. Matte painters show a far shelf this way: not its
detail but the light on its edge.

The light is warm at the left, under the vault, and turns cold toward the
gate; it fades in from the left edge and out before the gate. Its strength
and its height wander a little, as the rim of a stratum does.

  python build_far_lip.py out.png

1440 px wide - the backdrop's width, drawn 512 units - and LipRows tall.
The level draws it as a craft on the sky layer, so it stands still with
the backdrop when the world shakes. Needs numpy and Pillow.
"""
import sys

import numpy as np
from PIL import Image

Width = 1440 # px, the backdrop's
LipRows = 14 # px tall
LineRow = 5.0 # px from the top: the rim, the walking top of the stratum
Seed = 1212

LineThick = 1.5 # px
LineLevel = 0.55
LineBreath = 0.65 # of the level: how much it wanders along the rim
Wander = 3.0 # px up and down along the rim
WanderStep = 60 # px between the knots of the wandering
BreathStep = 25
ShadowThick = 3.0 # px under the rim
ShadowLevel = 0.32 # the alpha of black at its darkest
FadeLeft = 120 # px
FadeRight = 40 # px
Warm = (200, 170, 130)
Cold = (150, 180, 230)
ColdFrom = 900 # px: the light starts turning cold
ColdOver = 400


def knots(random, step):
    count = Width // step + 2
    return np.interp(np.arange(Width), np.linspace(0, Width, count),
                     random.uniform(0, 1, count))


def coverage(rows, top, thick):
    """How much of each pixel row a band from top, thick px tall, covers."""
    return np.clip(np.minimum(rows + 1, top + thick) - np.maximum(rows, top), 0, 1)


def lip():
    random = np.random.default_rng(Seed)
    columns = np.arange(Width)
    ends = np.clip(np.minimum(columns / FadeLeft, (Width - columns) / FadeRight), 0, 1)
    cold = np.clip((columns - ColdFrom) / ColdOver, 0, 1)[:, None]
    tint = np.array(Warm) * (1 - cold) + np.array(Cold) * cold
    rim = LineRow + (knots(random, WanderStep) - 0.5) * Wander
    level = ends * LineLevel * (1 - LineBreath + LineBreath * knots(random, BreathStep))

    rows = np.arange(LipRows)[:, None]
    light = coverage(rows, rim[None, :], LineThick) * level[None, :]
    shadow = coverage(rows, rim[None, :] + LineThick, ShadowThick)
    shadow = shadow * np.clip(1 - (rows - rim[None, :] - LineThick) / (ShadowThick + 1), 0, 1)
    shadow = shadow * ends[None, :] * ShadowLevel

    # Light over shadow, both in one picture of plain alpha
    alpha = light + shadow * (1 - light)
    colour = np.where(alpha[..., None] > 0,
                      tint[None, :, :] * (light / np.maximum(alpha, 1e-6))[..., None], 0)
    picture = np.dstack([np.clip(colour, 0, 255), np.clip(alpha * 255, 0, 255)])
    return Image.fromarray(picture.round().astype('uint8'), 'RGBA')


def main():
    lip().save(sys.argv[1])


if __name__ == '__main__':
    main()
