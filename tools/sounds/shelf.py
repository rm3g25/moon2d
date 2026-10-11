"""Cuts the latch of a shelf (shelflatch.wav) into bin/sounds out of a
take generated in Suno: the first of its sounds, a heavy steel latch
striking twice with a low thud dying under it. 44.1 kHz, 16 bit, mono -
as the pads' other sounds.

The take is 48 kHz stereo and holds three sounds; the first starts at
0.062 s and has died by 0.8 s. Nothing is done to it but the cut: the
two channels are averaged, the rate is brought to the game's, a hair of
silence is left before the strike so that it does not begin on a step,
and the tail is faded where it has died anyway. The mean goes first: a
low thud cut mid-swing leaves one, and the fades would end on a step.

  python shelf.py <take.wav> [path/to/bin/sounds]

The take is not kept in the repository. Needs numpy, scipy and armor.py
beside it.
"""
import sys
import wave
from fractions import Fraction
from pathlib import Path

import numpy as np
from scipy.signal import resample_poly

from armor import SampleRate, save

CutFrom = 0.060 # seconds of the take
CutTo = 0.800
FadeIn = 0.002
FadeOut = 0.050
# Of full scale, well under the crash: the shelf of a screen latches
# every few seconds for as long as the hero is there
LatchPeak = 0.45


def read_mono(path):
    with wave.open(str(path), 'rb') as take:
        rate = take.getframerate()
        channels = take.getnchannels()
        if take.getsampwidth() != 2:
            raise SystemExit(f'{path}: 16 bit samples expected')
        samples = np.frombuffer(take.readframes(take.getnframes()), dtype='<i2')
    return samples.reshape(-1, channels).mean(axis=1) / 32768, rate


def latch(path):
    take, rate = read_mono(path)
    sound = take[int(rate * CutFrom):int(rate * CutTo)]
    ratio = Fraction(SampleRate, rate)
    sound = resample_poly(sound, ratio.numerator, ratio.denominator)
    sound = sound - sound.mean()
    rise = int(SampleRate * FadeIn)
    fall = int(SampleRate * FadeOut)
    sound[:rise] = sound[:rise] * np.linspace(0, 1, rise)
    sound[-fall:] = sound[-fall:] * np.linspace(1, 0, fall)
    return sound * (LatchPeak / np.abs(sound).max())


def main():
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    here = Path(__file__).resolve().parent
    sounds = Path(sys.argv[2]) if len(sys.argv) > 2 else here.parents[1] / 'bin' / 'sounds'
    save(sounds / 'shelflatch.wav', latch(sys.argv[1]))


if __name__ == '__main__':
    main()
