"""Makes the two sounds of the Ram's magnet into bin/sounds: magnethum.wav,
the hum from the catch of a barge to its throw, and magnetthrow.wav, the
throw. 44.1 kHz, 16 bit, mono - as the armor pings.

The hum is a coil taking load: a mains-like tone and its first overtones,
sliding up an octave and growing from a murmur to full over its whole
length, a tremor coming into it as it rises - by its end it is plainly
about to let go. It is as long as the catch, the hold and the press take
together (Game.Magnet: 40, 56 and 8 ticks of 33 a second), and a little
more, so a late throw does not meet silence; the game cuts it at the
throw.

The throw is the load let go: a low blow sliding down in pitch, the dull
clang of the clamp's plates - inharmonic, damped hard - and a short breath
of dark noise, the barge leaving. Low sounds come out right in code,
clicks and crackles do not, so there is no click in either.

  python magnet.py [path/to/bin/sounds]

Needs numpy, and armor.py and orblauncher.py beside it.
"""
import sys
from pathlib import Path

import numpy as np

from armor import SampleRate, finish, save
from orblauncher import dark_noise, slide

HumSeconds = 3.3
HumPeak = 0.6 # under the jets' roar it plays over
HumFrom = 55.0 # Hz
HumTo = 110.0
# the tone's overtones and their shares of it
HumOvertones = ((1, 1.0), (2, 0.5), (3, 0.3), (5, 0.12))
HumQuiet = 0.2 # its level as it starts, of its level at the end
HumOnset = 0.08 # seconds: it does not click in
TremorPitch = 13.0 # Hz
TremorDepth = 0.35 # at the end; none at the start

ThrowSeconds = 0.55
ThrowPeak = 0.8
BlowFrom = 140.0
BlowTo = 44.0
BlowSlide = 0.03
BlowDecay = 0.12
ClangPitches = (173.0, 271.0, 419.0) # inharmonic: plates, not a bell
ClangDecays = (0.09, 0.06, 0.035)
ClangLevel = 0.3
BreathCutoff = 700.0
BreathDecay = 0.1
BreathLevel = 0.3

Drive = 1.5 # into the soft clip
Seed = 0x4D61676E # "Magn"


def hum():
    length = int(SampleRate * HumSeconds)
    time = np.arange(length) / SampleRate
    share = time / HumSeconds
    # up an octave evenly to the ear: the pitch grows by a ratio, not a step
    pitch = HumFrom * (HumTo / HumFrom) ** share
    phase = 2 * np.pi * np.cumsum(pitch) / SampleRate
    sound = np.zeros(length)
    for overtone, level in HumOvertones:
        sound += level * np.sin(overtone * phase)
    tremor = 1 - TremorDepth * share * (0.5 + 0.5 * np.sin(2 * np.pi * TremorPitch * time))
    swell = HumQuiet + (1 - HumQuiet) * share * share
    onset = np.clip(time / HumOnset, 0, 1)
    sound *= tremor * swell * onset
    return np.tanh(Drive * sound / np.abs(sound).max()) / np.tanh(Drive)


def throw(rng):
    length = int(SampleRate * ThrowSeconds)
    time = np.arange(length) / SampleRate
    sound = slide(time, BlowFrom, BlowTo, BlowSlide, BlowDecay)
    for pitch, decay in zip(ClangPitches, ClangDecays):
        sound += ClangLevel * np.sin(2 * np.pi * pitch * time) * np.exp(-time / decay)
    sound += BreathLevel * dark_noise(length, BreathCutoff, rng) * np.exp(-time / BreathDecay)
    return np.tanh(Drive * sound) / np.tanh(Drive)


def main():
    here = Path(__file__).resolve().parent
    sounds = Path(sys.argv[1]) if len(sys.argv) > 1 else here.parents[1] / 'bin' / 'sounds'
    rng = np.random.default_rng(Seed)
    save(sounds / 'magnethum.wav', finish(hum(), HumPeak))
    save(sounds / 'magnetthrow.wav', finish(throw(rng), ThrowPeak))
    print(f'{sounds / "magnethum.wav"}: {HumSeconds} s; '
          f'{sounds / "magnetthrow.wav"}: {ThrowSeconds} s')


if __name__ == '__main__':
    main()
