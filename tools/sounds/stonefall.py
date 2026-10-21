"""Synthesises the fall of the risen rocks into bin/sounds: stonefall.wav.
44.1 kHz, 16 bit, mono - as the armor pings.

The scene of screen 11 plays it as the moon stone is taken: the drone
that woke with the stone (stonewake.py) powers down - the same two
stacks of overtones, the pitch sinking an octave as the level dies, the
way a ship's bulk winds down - and the rocks it held up drop out of
sight. Far below, a while later, they come down: one dull blow felt in
the floor, noise and a deep thump under a low-pass. No clicks, no
cracks, as the waking.

  python stonefall.py [path/to/bin/sounds]

Needs numpy, scipy and armor.py beside it.
"""
import sys
from pathlib import Path

import numpy as np
from scipy.signal import butter, sosfilt

from armor import SampleRate, finish, save

FallSeconds = 7.0
FallPeak = 0.8 # of full scale: the music is ducked under it
FallSeed = 1112

Pitch = 41.0 # Hz, where the waking drone settled
Sink = 0.5 # of the pitch: an octave down by the end of the slide
SinkSeconds = 3.0
Beat = 0.5 # Hz between the two stacks, as the waking
Overtones = 12
OvertoneFall = 1.5
Drive = 1.2
ToneCutoff = 260.0 # Hz
RumbleCutoff = 70.0 # Hz
RumbleLevel = 0.5

# The drone along the scene: in at once, but not with a click; dead by
# the time the rocks reach the bottom. The rocks let go from 0.75 s
DroneEnvelope = [
    (0.0, 0.0),
    (0.15, 1.0),
    (0.8, 0.9),
    (3.2, 0.0),
    (FallSeconds, 0.0),
]

# The rocks come down far below: the scene jolts the screen at 3 s
BlowAt = 3.0
BlowAttack = 0.03 # seconds: soft enough not to click
BlowDecay = 0.8 # seconds, the time to fall to 1/e
BlowPitch = 30.0 # Hz, the thump under the noise
BlowCutoff = 90.0 # Hz
BlowLevel = 0.9


def low_pass(sound, cutoff):
    return sosfilt(butter(4, cutoff, fs=SampleRate, output='sos'), sound)


def drone(time):
    sink = 1 - Sink * np.clip(time / SinkSeconds, 0, 1) ** 1.5
    phase = 2 * np.pi * np.cumsum(Pitch * sink) / SampleRate
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


def blow(time, random):
    since = time - BlowAt
    after = since >= 0
    attack = np.clip(since / BlowAttack, 0, 1)
    decay = np.where(after, np.exp(-np.maximum(since, 0) / BlowDecay), 0)
    noise = low_pass(random.standard_normal(time.size), BlowCutoff)
    noise = noise / np.abs(noise).max()
    thump = np.sin(2 * np.pi * BlowPitch * np.maximum(since, 0))
    return BlowLevel * attack * decay * (0.6 * noise + 0.4 * thump)


def fall():
    random = np.random.default_rng(FallSeed)
    time = np.arange(int(FallSeconds * SampleRate)) / SampleRate
    knots, levels = zip(*DroneEnvelope)
    envelope = np.interp(time, knots, levels)
    powered = (drone(time) + RumbleLevel * rumble(time, random)) * envelope
    return powered + low_pass(blow(time, random), BlowCutoff)


def main():
    here = Path(__file__).resolve().parent
    sounds = Path(sys.argv[1]) if len(sys.argv) > 1 else here.parents[1] / 'bin' / 'sounds'
    save(sounds / 'stonefall.wav', finish(fall(), FallPeak))


if __name__ == '__main__':
    main()
