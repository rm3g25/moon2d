"""Synthesises the hum of the pads spinning up on the threads of the throw
into bin/sounds: spinrise.wav, the run up, and spinhold.wav, the top of it
held. 44.1 kHz, 16 bit, mono - as the armor pings.

The hum is the pad hum's kin (pads.py): two low buzzing tones a hair
apart, so they beat, with overtones up to a kilohertz - what a small
speaker makes of it. Spinning up, it climbs an octave and swells, its
beat quickening as the pads go faster. Spun up, it holds the top: the
game loops the second file until the throw, so its pitch, its beat and
its throb are whole numbers of hertz and the loop a whole second - every
tone ends where it began, and the loop has no seam. The run up ends with
a short release under the start of the loop.

  python spin.py [path/to/bin/sounds]

Needs numpy and armor.py beside it.
"""
import sys
from pathlib import Path

import numpy as np

from armor import SampleRate, finish, save

# The run up lasts SpinUpTicks of Game.Throw (132 ticks, 4 s); the release
# runs on under the loop's start
RiseSeconds = 4.0
RiseRelease = 0.1
HoldSeconds = 1.0
Peak = 0.45 # of full scale: under the heartbeat

PitchFrom = 55.0 # Hz
PitchTop = 110.0 # Hz, a whole number: the loop
BeatFrom = 1.5 # Hz between the two tones
BeatTop = 6.0 # a whole number
Overtones = 10 # of each tone, the n-th at 1/n of its level: a soft saw
ThrobTop = 4.0 # Hz, a whole number
ThrobDepth = 0.25
LevelFrom = 0.3 # of the top, as the run up starts
Drive = 0.8 # into the soft clip: a little grit on the buzz


def tones(phase, beat_phase):
    tone = np.zeros(phase.size)
    for overtone in range(1, Overtones + 1):
        tone = tone + np.sin(overtone * phase) / overtone
        tone = tone + np.sin(overtone * (phase + beat_phase)) / overtone
    return tone


def rise():
    seconds = RiseSeconds + RiseRelease
    time = np.arange(int(SampleRate * seconds)) / SampleRate
    share = np.clip(time / RiseSeconds, 0, 1)
    pitch = PitchFrom * (PitchTop / PitchFrom) ** share
    beat = BeatFrom + (BeatTop - BeatFrom) * share
    phase = 2 * np.pi * np.cumsum(pitch) / SampleRate
    beat_phase = 2 * np.pi * np.cumsum(beat) / SampleRate
    throb = 1 - ThrobDepth * share * (0.5 + 0.5 * np.cos(beat_phase * ThrobTop / BeatTop))
    level = LevelFrom + (1 - LevelFrom) * share
    release = np.clip((seconds - time) / RiseRelease, 0, 1)
    return np.tanh(Drive * tones(phase, beat_phase) * throb) * level * release


def hold():
    time = np.arange(int(SampleRate * HoldSeconds)) / SampleRate
    phase = 2 * np.pi * PitchTop * time
    beat_phase = 2 * np.pi * BeatTop * time
    throb = 1 - ThrobDepth * (0.5 + 0.5 * np.cos(2 * np.pi * ThrobTop * time))
    return np.tanh(Drive * tones(phase, beat_phase) * throb)


def main():
    here = Path(__file__).resolve().parent
    sounds = Path(sys.argv[1]) if len(sys.argv) > 1 else here.parents[1] / 'bin' / 'sounds'
    held = hold()
    # No fade on the loop: it would sound once a second
    save(sounds / 'spinhold.wav', held * (Peak / np.abs(held).max()))
    save(sounds / 'spinrise.wav', finish(rise(), Peak))


if __name__ == '__main__':
    main()
