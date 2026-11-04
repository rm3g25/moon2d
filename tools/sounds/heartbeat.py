"""Synthesises the heartbeat of the last of the charge into bin/sounds:
heartbeat.wav. 44.1 kHz, 16 bit, mono - as the armor pings.

One beat is a double "tuk-tuk", low: two dull thumps, the second a
little quieter and a little higher, as the two valves of one heart.
Each thump is a tone falling in pitch as it dies, with two overtones so
it reads on small speakers too, all under a low-pass - the way the
stone's drone is made (stonewake.py): low sounds work in code, clicks
and crackles do not. A soft attack, so no click starts it.

The game plays it once a beat, up to 90 a minute (0.67 s apart), so the
whole file is shorter than that.

  python heartbeat.py [path/to/bin/sounds]

Needs numpy, scipy and armor.py beside it.
"""
import sys
from pathlib import Path

import numpy as np
from scipy.signal import butter, sosfilt

from armor import SampleRate, finish, save

BeatSeconds = 0.6
BeatPeak = 0.85 # of full scale

# The second thump comes this long after the first. Game.Heartbeat draws
# its second pulse at DubTicks 8 (0.24 s at 33 ticks a second) - change
# both or the gauge beats off the sound
DubSeconds = 0.24
DubLevel = 0.75

PitchFrom = 70.0 # Hz, as the thump strikes
PitchTo = 45.0 # Hz, as it dies
PitchFall = 0.05 # seconds for the pitch to cover 1/e of the way
DubPitch = 1.12 # the second thump against the first
Overtones = ((2, 0.45), (3, 0.18)) # (multiple, level)
AttackSeconds = 0.008
Decay = 0.075 # seconds to 1/e
ToneCutoff = 220.0 # Hz: the low-pass over the beat - no buzz
Drive = 1.4 # into the soft clip: a little weight


def low_pass(sound, cutoff):
    return sosfilt(butter(4, cutoff, fs=SampleRate, output='sos'), sound)


def thump(time, start, pitch_scale):
    local = time - start
    alive = local >= 0
    local = np.where(alive, local, 0)
    pitch = pitch_scale * (PitchTo + (PitchFrom - PitchTo) * np.exp(-local / PitchFall))
    phase = 2 * np.pi * np.cumsum(pitch * alive) / SampleRate
    tone = np.sin(phase)
    for multiple, level in Overtones:
        tone = tone + level * np.sin(multiple * phase)
    attack = np.clip(local / AttackSeconds, 0, 1)
    attack = 0.5 - 0.5 * np.cos(np.pi * attack)
    return tone * attack * np.exp(-local / Decay) * alive


def beat():
    time = np.arange(int(BeatSeconds * SampleRate)) / SampleRate
    sound = thump(time, 0.0, 1.0) + DubLevel * thump(time, DubSeconds, DubPitch)
    return low_pass(np.tanh(Drive * sound), ToneCutoff)


def main():
    here = Path(__file__).resolve().parent
    sounds = Path(sys.argv[1]) if len(sys.argv) > 1 else here.parents[1] / 'bin' / 'sounds'
    save(sounds / 'heartbeat.wav', finish(beat(), BeatPeak))


if __name__ == '__main__':
    main()
