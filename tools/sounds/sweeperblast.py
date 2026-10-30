"""Synthesises the blast of the Ram's sweeper into bin/sounds:
sweeperblast.wav. 44.1 kHz, 16 bit, mono - as the armor pings.

The game plays it as the overloaded head bursts and the shock wave runs
out over the arena: a blow felt in the chest, then a drone that sinks
away under it - the stone's wake (stonewake.py) going down instead of
up. The blow is a low thump, a sine dropping fast, with a floor of noise
under it; the drone is the same two dark stacks of overtones beating
slowly, the pitch falling to its floor as it fades. All of it under a
low-pass: no crack, no crackle, nothing that hisses.

The blow and the drone sit under 100 Hz, where laptop speakers and most
headphones give nothing back, so the low-pass stands high enough to let
the drone's overtones through - the ear rebuilds the low pitch from them
- and a dull body of noise in the low mids carries the blow: a whump,
still no crack. A soft clip over the whole lifts it to the loudness of
the hunter's blast, its new overtones under the same low-pass.

  python sweeperblast.py [path/to/bin/sounds]

Needs numpy, scipy and armor.py beside it.
"""
import sys
from pathlib import Path

import numpy as np
from scipy.signal import butter, sosfilt

from armor import SampleRate, finish, save

BlastSeconds = 3.8
BlastPeak = 0.85 # of full scale: the loudest blow of the arena
BlastSeed = 1313

# The blow: a thump from ThumpFrom down to ThumpTo, dying fast
ThumpFrom = 70.0 # Hz
ThumpTo = 32.0
ThumpDrop = 0.12 # seconds to 1/e of the way down
ThumpDecay = 0.45 # seconds to 1/e of its level
ThumpLevel = 1.0
NoiseCutoff = 160.0 # Hz: a floor of noise, not a crack
NoiseDecay = 0.25
NoiseLevel = 0.6
# The body of the blow, heard where the thump is not
BodyLow = 90.0 # Hz
BodyHigh = 450.0
BodyDecay = 0.2
BodyLevel = 1.5

# The drone: it starts where the stone's settles and sinks an octave
DroneFrom = 44.0 # Hz
DroneTo = 24.0
DroneSink = 1.1 # seconds to 1/e of the way down
Beat = 0.6 # Hz between the two stacks
Overtones = 12 # of each stack, the n-th at 1/n^1.5 of its level
OvertoneFall = 1.5
Drive = 1.4 # into the soft clip
ToneCutoff = 700.0 # Hz: the low-pass over everything
DroneLevel = 0.7
BlastDrive = 3.0 # into the soft clip over the whole blast

# The drone's level, in seconds: (time, level) knots joined by straight
# lines - in under the blow, held a moment, gone as the screen clears
DroneEnvelope = [
    (0.0, 0.0),
    (0.15, 1.0),
    (1.0, 0.8),
    (BlastSeconds, 0.0),
]


def low_pass(sound, cutoff):
    return sosfilt(butter(4, cutoff, fs=SampleRate, output='sos'), sound)


def band_pass(sound, low, high):
    return sosfilt(butter(2, [low, high], btype='bandpass', fs=SampleRate, output='sos'), sound)


def sinking(time, start, floor, rate):
    return floor + (start - floor) * np.exp(-time / rate)


def thump(time, random):
    pitch = sinking(time, ThumpFrom, ThumpTo, ThumpDrop)
    phase = 2 * np.pi * np.cumsum(pitch) / SampleRate
    tone = np.sin(phase) * np.exp(-time / ThumpDecay)
    noise = low_pass(random.standard_normal(time.size), NoiseCutoff)
    noise = noise / np.abs(noise).max() * np.exp(-time / NoiseDecay)
    body = band_pass(random.standard_normal(time.size), BodyLow, BodyHigh)
    body = body / np.abs(body).max() * np.exp(-time / BodyDecay)
    return ThumpLevel * tone + NoiseLevel * noise + BodyLevel * body


def drone(time):
    pitch = sinking(time, DroneFrom, DroneTo, DroneSink)
    phase = 2 * np.pi * np.cumsum(pitch) / SampleRate
    beat = 2 * np.pi * Beat * time
    tone = np.zeros(time.size)
    for overtone in range(1, Overtones + 1):
        level = 1 / overtone ** OvertoneFall
        tone = tone + level * np.sin(overtone * phase)
        tone = tone + level * np.sin(overtone * (phase + beat))
    tone = np.tanh(Drive * tone / np.abs(tone).max())
    knots, levels = zip(*DroneEnvelope)
    return tone * np.interp(time, knots, levels)


def blast():
    random = np.random.default_rng(BlastSeed)
    time = np.arange(int(BlastSeconds * SampleRate)) / SampleRate
    sound = thump(time, random) + DroneLevel * drone(time)
    sound = np.tanh(BlastDrive * sound / np.abs(sound).max())
    return low_pass(sound, ToneCutoff)


def main():
    here = Path(__file__).resolve().parent
    sounds = Path(sys.argv[1]) if len(sys.argv) > 1 else here.parents[1] / 'bin' / 'sounds'
    save(sounds / 'sweeperblast.wav', finish(blast(), BlastPeak))


if __name__ == '__main__':
    main()
