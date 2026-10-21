"""Synthesises the waking of the moon stone into bin/sounds: stonewake.wav.
44.1 kHz, 16 bit, mono - as the armor pings.

The scene of screen 11 plays it from its first tick: the drone of
something huge coming awake under the rock, the way a ship's bulk
passes over in the old films - felt more than heard. Built as the hum
of the cordon (cordon.py) is: two dark stacks of overtones a hair apart
beating slowly, the pitch drifting, a soft clip for the grit of it. All
of it under a low-pass, so nothing above the bass hisses or buzzes, and
under it a rumble - noise filtered down to the floor. The pitch settles
a little as the stone comes awake. No clicks, no cracks: one sound from
the hush to the end, letting go as the music of the level comes back.

  python stonewake.py [path/to/bin/sounds]

Needs numpy, scipy and armor.py beside it.
"""
import sys
from pathlib import Path

import numpy as np
from scipy.signal import butter, sosfilt

from armor import SampleRate, finish, save

WakeSeconds = 13.0
WakePeak = 0.8 # of full scale: the music is ducked under it
WakeSeed = 1111

Pitch = 41.0 # Hz, where it settles
Settle = 0.06 # of the pitch: how far above it the drone starts
SettleSeconds = 4.0
Beat = 0.5 # Hz between the two stacks: a slow throb
Overtones = 12 # of each stack, the n-th at 1/n^1.5 of its level
OvertoneFall = 1.5
Drift = 0.012 # of the pitch, up and down
DriftRate = 0.09 # Hz
Drive = 1.2 # into the soft clip
ToneCutoff = 260.0 # Hz: the low-pass over the drone - no buzz
RumbleCutoff = 70.0 # Hz: the noise is only a floor
RumbleLevel = 0.5

# The level along the scene, in seconds: (time, level) knots joined by
# straight lines. The rocks rise from 1.8 s to 8.3 s, the music comes
# back from 10.3 s
Envelope = [
    (0.0, 0.0),
    (0.5, 0.0), # the hush
    (2.0, 0.55),
    (4.0, 1.0), # awake
    (8.5, 1.0),
    (12.5, 0.0),
    (WakeSeconds, 0.0),
]


def low_pass(sound, cutoff):
    return sosfilt(butter(4, cutoff, fs=SampleRate, output='sos'), sound)


def drone(time):
    settle = Settle * np.clip(1 - time / SettleSeconds, 0, 1) ** 2
    drift = Drift * np.sin(2 * np.pi * DriftRate * time)
    pitch = Pitch * (1 + settle + drift)
    phase = 2 * np.pi * np.cumsum(pitch) / SampleRate
    beat = 2 * np.pi * Beat * time
    tone = np.zeros(time.size)
    for overtone in range(1, Overtones + 1):
        level = 1 / overtone ** OvertoneFall
        tone = tone + level * np.sin(overtone * phase)
        tone = tone + level * np.sin(overtone * (phase + beat))
    tone = low_pass(np.tanh(Drive * tone), ToneCutoff)
    return tone / np.abs(tone).max()


def rumble(time, random):
    floor = low_pass(random.standard_normal(time.size), RumbleCutoff)
    return floor / np.abs(floor).max()


def wake():
    random = np.random.default_rng(WakeSeed)
    time = np.arange(int(WakeSeconds * SampleRate)) / SampleRate
    knots, levels = zip(*Envelope)
    envelope = np.interp(time, knots, levels)
    return (drone(time) + RumbleLevel * rumble(time, random)) * envelope


def main():
    here = Path(__file__).resolve().parent
    sounds = Path(sys.argv[1]) if len(sys.argv) > 1 else here.parents[1] / 'bin' / 'sounds'
    save(sounds / 'stonewake.wav', finish(wake(), WakePeak))


if __name__ == '__main__':
    main()
