"""Synthesises the sounds of an arena rebuild into bin/sounds: the hum
that warns of one (padhum.wav), the click of a pad turning the corner of
its flight (padclick.wav) and the clack of two pads docking side by side
(padclack.wav). 44.1 kHz, 16 bit, mono - as the armor pings.

The hum is the pads' jets spooling up: two low buzzing tones a hair
apart, so they beat, climbing a little, swelling and throbbing at the
rate the alarm lamps blink. The buzz - overtones up to a kilohertz - is
what a small speaker makes of it: the low tone alone it cannot play.
The click is a small latch: the struck plate of the armor pings, higher
and shorter. The clack is two latches catching one after the other over
a thump of the bodies meeting.

  python pads.py [path/to/bin/sounds]

Needs numpy and armor.py beside it.
"""
import sys
from pathlib import Path

import numpy as np

from armor import SampleRate, finish, save, strike

HumSeconds = 0.6 # the warning lasts 0.4 s; the tail dies under the first flights
HumPeak = 0.5 # of full scale: under the crash, over a ping
HumPitch = 82.0 # Hz
HumBeat = 3.0 # Hz between the two low tones
HumOvertones = 10 # of each tone, the n-th at 1/n of its level: a soft saw
HumRise = 1.25 # the pitch at the end over the pitch at the start
HumSwell = 0.12 # seconds to 1 - 1/e of full level
HumThrob = 5.0 # Hz: the alarm lamps of level 1 blink at this rate
HumThrobDepth = 0.35
HumRelease = 0.18 # seconds the tail takes to die
HumDrive = 0.7 # into the soft clip: a little grit on the buzz

ClickSeconds = 0.07
ClickPeak = 0.26 # quiet: several pads turn their corners within a second
ClickPitch = 2900.0 # Hz
ClickSeed = 17

ClackSeconds = 0.22
ClackPeak = 0.5
ClackPitch = 1150.0 # Hz, the first latch
ClackSecondPitch = 930.0
ClackSecondAfter = 0.028 # seconds
ClackSecondLevel = 0.8
ClackThumpFrom = 210.0 # Hz
ClackThumpTo = 120.0
ClackThumpSlide = 0.02 # seconds for the pitch to cover 1/e of the way
ClackThumpDecay = 0.05 # seconds to 1/e
ClackThumpLevel = 0.9
ClackSeed = 29


def hum():
    time = np.arange(int(SampleRate * HumSeconds)) / SampleRate
    pitch = HumPitch * (1 + (HumRise - 1) * time / HumSeconds)
    phase = 2 * np.pi * np.cumsum(pitch) / SampleRate
    beat = 2 * np.pi * HumBeat * time
    tone = np.zeros(time.size)
    for overtone in range(1, HumOvertones + 1):
        tone = tone + np.sin(overtone * phase) / overtone
        tone = tone + np.sin(overtone * (phase + beat)) / overtone
    throb = 1 - HumThrobDepth * (0.5 + 0.5 * np.cos(2 * np.pi * HumThrob * time))
    swell = 1 - np.exp(-time / HumSwell)
    release = np.clip((HumSeconds - time) / HumRelease, 0, 1)
    return np.tanh(HumDrive * tone * throb * swell * release)


def click():
    return strike(ClickPitch, ClickSeconds, ClickSeed)


def clack():
    time = np.arange(int(SampleRate * ClackSeconds)) / SampleRate
    first = strike(ClackPitch, ClackSeconds, ClackSeed)
    second = strike(ClackSecondPitch, ClackSeconds, ClackSeed + 1)
    delay = int(SampleRate * ClackSecondAfter)
    sound = first.copy()
    sound[delay:] = sound[delay:] + ClackSecondLevel * second[:-delay]
    pitch = ClackThumpTo + (ClackThumpFrom - ClackThumpTo) * np.exp(-time / ClackThumpSlide)
    phase = 2 * np.pi * np.cumsum(pitch) / SampleRate
    thump = ClackThumpLevel * np.sin(phase) * np.exp(-time / ClackThumpDecay)
    return sound + thump


def main():
    here = Path(__file__).resolve().parent
    sounds = Path(sys.argv[1]) if len(sys.argv) > 1 else here.parents[1] / 'bin' / 'sounds'
    save(sounds / 'padhum.wav', finish(hum(), HumPeak))
    save(sounds / 'padclick.wav', finish(click(), ClickPeak))
    save(sounds / 'padclack.wav', finish(clack(), ClackPeak))


if __name__ == '__main__':
    main()
