"""Makes the sound of the Ram's stern mortar rising for its turn into
bin/sounds: mortarrise.wav. 44.1 kHz, 16 bit, mono - as the armor pings.

The rise is a hydraulic ram pushing the mortar up out of the rear block: a
strained motor tone with its odd overtones, sliding up as the load comes
off, under a breath of dark noise - the oil - for as long as the rise takes
(Game.Mortar: 20 ticks of 33 a second); then the latch: a low blow and the
dull clank of heavy plates locking, inharmonic and damped hard. It is the
warning that shells are coming, so the latch is plain under the jets.
Low sounds come out right in code, clicks do not, so there is no click.

  python mortar.py [path/to/bin/sounds]

Needs numpy, and armor.py and orblauncher.py beside it.
"""
import sys
from pathlib import Path

import numpy as np

from armor import SampleRate, finish, save
from orblauncher import dark_noise, slide

RiseSeconds = 0.6
Seconds = 0.95
Peak = 0.8
MotorFrom = 70.0 # Hz
MotorTo = 125.0
# the motor's odd overtones and their shares of it
MotorOvertones = ((1, 1.0), (3, 0.4), (5, 0.18), (7, 0.08))
MotorLevel = 0.45
MotorOnset = 0.06 # seconds: it does not click in
OilCutoff = 500.0
OilLevel = 0.25
LatchBlowFrom = 120.0
LatchBlowTo = 50.0
LatchBlowSlide = 0.025
LatchBlowDecay = 0.09
ClankPitches = (191.0, 293.0, 457.0) # inharmonic: plates, not a bell
ClankDecays = (0.08, 0.05, 0.03)
ClankLevel = 0.35
LatchOnset = 0.003 # seconds: a hard edge, not a click

Drive = 1.6 # into the soft clip
Seed = 0x4D6F7274 # "Mort"


def rise(rng):
    length = int(SampleRate * Seconds)
    time = np.arange(length) / SampleRate
    share = np.clip(time / RiseSeconds, 0, 1)
    # up evenly to the ear: the pitch grows by a ratio, not a step
    pitch = MotorFrom * (MotorTo / MotorFrom) ** share
    phase = 2 * np.pi * np.cumsum(pitch) / SampleRate
    motor = np.zeros(length)
    for overtone, level in MotorOvertones:
        motor += level * np.sin(overtone * phase)
    onset = np.clip(time / MotorOnset, 0, 1)
    # the motor dies quickly once the latch has locked
    hold = np.where(time < RiseSeconds, 1.0, np.exp(-(time - RiseSeconds) / 0.03))
    sound = MotorLevel * motor * onset * hold
    sound += OilLevel * dark_noise(length, OilCutoff, rng) * onset * hold
    start = int(SampleRate * RiseSeconds)
    after = time[start:] - RiseSeconds
    latch = slide(after, LatchBlowFrom, LatchBlowTo, LatchBlowSlide, LatchBlowDecay)
    for pitch_hz, decay in zip(ClankPitches, ClankDecays):
        latch += ClankLevel * np.sin(2 * np.pi * pitch_hz * after) * np.exp(-after / decay)
    sound[start:] += latch * np.clip(after / LatchOnset, 0, 1)
    return np.tanh(Drive * sound) / np.tanh(Drive)


def main():
    here = Path(__file__).resolve().parent
    sounds = Path(sys.argv[1]) if len(sys.argv) > 1 else here.parents[1] / 'bin' / 'sounds'
    rng = np.random.default_rng(Seed)
    save(sounds / 'mortarrise.wav', finish(rise(rng), Peak))
    print(f'{sounds / "mortarrise.wav"}: {Seconds} s')


if __name__ == '__main__':
    main()
