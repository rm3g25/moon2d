"""Synthesises the Ram's jets into bin/sounds: jetfire.wav and
jethover.wav. 44.1 kHz, 16 bit, mono - as the armor pings.

jetfire.wav - a jet catching in an empty wheel well: a dull "whump" as
the fuel takes, then a roar of low noise that swells for a moment and
settles, still burning as the file ends - the loop of the hover takes it
over. A hiss of flame rides on top of the roar.

jethover.wav - the two jets burning while the hull hangs: a loop of low
roar, wavering slowly as the jets breathe, the flame's hiss over it. The
noise is shaped round the loop in the frequency domain, as the rumble's
is, so the end runs into the start with no seam.

  python jet.py [path/to/bin/sounds]

Needs numpy, scipy, armor.py and ram.py beside it.
"""
import sys
from pathlib import Path

import numpy as np
from scipy.signal import butter, sosfilt

from armor import SampleRate, finish, save
from ram import periodic_noise

FireSeconds = 1.6
FirePeak = 0.6
FireSeed = 1901
# The fuel taking: a low thump
WhumpPitch = 48.0 # Hz
WhumpCutoff = 150.0
WhumpAttack = 0.01
WhumpDecay = 0.18
WhumpLevel = 1.0
# The roar: low noise swelling past its steady level, then settling
RoarLow = 40.0 # Hz
RoarHigh = 700.0
RoarAttack = 0.08
RoarSwell = 0.6 # over its steady level at the top of the swell
RoarSwellDecay = 0.35
RoarLevel = 0.7
# The flame's hiss on top
HissLow = 1800.0 # Hz
HissHigh = 6000.0
HissLevel = 0.12
FireDrive = 1.4

# The loop. 2 s holds a whole number of every period below.
LoopSeconds = 2.0
HoverPeak = 0.38 # of full scale: it hangs under the boss track for long
HoverSeed = 1902
BreathRate = 1.5 # Hz, 3 breaths a loop: the jets wavering
BreathDepth = 0.25
HoverDrive = 1.2


def low_pass(sound, cutoff):
    return sosfilt(butter(4, cutoff, fs=SampleRate, output='sos'), sound)


def band_pass(sound, low, high):
    return sosfilt(butter(4, [low, high], btype='band', fs=SampleRate, output='sos'), sound)


def normalised(sound):
    return sound / np.abs(sound).max()


def fire():
    random = np.random.default_rng(FireSeed)
    time = np.arange(int(FireSeconds * SampleRate)) / SampleRate
    attack = np.clip(time / WhumpAttack, 0, 1)
    thump = normalised(low_pass(random.standard_normal(time.size), WhumpCutoff))
    tone = np.sin(2 * np.pi * WhumpPitch * time)
    whump = WhumpLevel * attack * np.exp(-time / WhumpDecay) * (0.5 * thump + 0.5 * tone)
    swell = np.clip(time / RoarAttack, 0, 1) * (1 + RoarSwell * np.exp(-time / RoarSwellDecay))
    roar = RoarLevel * swell * normalised(band_pass(random.standard_normal(time.size), RoarLow, RoarHigh))
    hiss = HissLevel * swell * normalised(band_pass(random.standard_normal(time.size), HissLow, HissHigh))
    return np.tanh(FireDrive * (whump + roar + hiss))


def hover():
    samples = int(SampleRate * LoopSeconds)
    time = np.arange(samples) / SampleRate
    breath = 1 - BreathDepth * (0.5 + 0.5 * np.cos(2 * np.pi * BreathRate * time))
    roar = RoarLevel * periodic_noise(samples, RoarLow, RoarHigh, HoverSeed)
    hiss = HissLevel * periodic_noise(samples, HissLow, HissHigh, HoverSeed + 1)
    sound = np.tanh(HoverDrive * breath * (roar + hiss))
    sound = sound - sound.mean()
    return sound * (HoverPeak / np.abs(sound).max())


def main():
    here = Path(__file__).resolve().parent
    sounds = Path(sys.argv[1]) if len(sys.argv) > 1 else here.parents[1] / 'bin' / 'sounds'
    save(sounds / 'jetfire.wav', finish(fire(), FirePeak))
    save(sounds / 'jethover.wav', hover())


if __name__ == '__main__':
    main()
