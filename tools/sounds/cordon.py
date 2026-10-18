"""Synthesises the hum of the TEK-Q6 cordon passing over level 1 screen 9
into bin/sounds: cordonhum.wav. 44.1 kHz, 16 bit, mono - as the armor
pings.

The hum is the bulk of a machine three screens long hanging over the
hero: a low tone under the soundtrack (cordon.ogg) that the body feels
more than the ear hears. Two tones a hair apart beat slowly; a buzz of
overtones lets a small speaker play what the low tone alone it cannot;
a slow drift of the pitch keeps it alive. The level follows the scene's
timeline (docs/mechanics/scenes.md): out of silence before anything is
seen, swelling as the belly comes over, steady while it hangs, gone as
it rises away.

  python cordon.py [path/to/bin/sounds]

Needs numpy and armor.py beside it.
"""
import sys
from pathlib import Path

import numpy as np

from armor import SampleRate, finish, save

Seconds = 34.0
Peak = 0.42 # of full scale: under the soundtrack
Pitch = 41.0 # Hz
Beat = 0.45 # Hz between the two low tones
Overtones = 14 # of each tone, the n-th at 1/n^1.4 of its level: darker than a saw
OvertoneFall = 1.4
Drift = 0.015 # of the pitch, up and down
DriftRate = 0.07 # Hz
Drive = 0.9 # into the soft clip: the grit of a machine

# The level along the scene, in seconds: (time, level) knots joined by
# straight lines
Envelope = [
    (0.0, 0.0),
    (3.0, 0.35), # heard before seen
    (8.0, 0.9), # the belly comes over
    (13.0, 1.0), # it stops over the hero
    (25.6, 0.95),
    (30.6, 0.0), # risen away
    (Seconds, 0.0),
]


def hum():
    time = np.arange(int(SampleRate * Seconds)) / SampleRate
    pitch = Pitch * (1 + Drift * np.sin(2 * np.pi * DriftRate * time))
    phase = 2 * np.pi * np.cumsum(pitch) / SampleRate
    beat = 2 * np.pi * Beat * time
    tone = np.zeros(time.size)
    for overtone in range(1, Overtones + 1):
        level = 1 / overtone ** OvertoneFall
        tone = tone + level * np.sin(overtone * phase)
        tone = tone + level * np.sin(overtone * (phase + beat))
    knots, levels = zip(*Envelope)
    envelope = np.interp(time, knots, levels)
    return np.tanh(Drive * tone) * envelope


def main():
    here = Path(__file__).resolve().parent
    sounds = Path(sys.argv[1]) if len(sys.argv) > 1 else here.parents[1] / 'bin' / 'sounds'
    save(sounds / 'cordonhum.wav', finish(hum(), Peak))


if __name__ == '__main__':
    main()
