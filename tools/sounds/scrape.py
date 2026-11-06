"""Synthesises the Ram's front wheel coming off into bin/sounds:
scrape.wav and wheelland.wav. 44.1 kHz, 16 bit, mono - as the armor
pings.

scrape.wav - the hull dropping onto the point of its plough and dragging
it over the road as it settles: a band of noise, steel on stone, that
swells at once and dies over a second, the grind wavering as the point
catches and slips; under it the plates of the hull ringing - the
partials of a free bar, as the pings, low and slow - and a dull knock as
the nose lands. The crash of the wheel breaking off (crash.wav) plays
with it.

wheelland.wav - the wheel coming down on the road from its hop: one
heavy blow, felt rather than heard - a thump under a low-pass and a
short ring of its rim. No clicks, as the stone's fall.

  python scrape.py [path/to/bin/sounds]

Needs numpy, scipy and armor.py beside it.
"""
import sys
from pathlib import Path

import numpy as np
from scipy.signal import butter, sosfilt

from armor import BarRatios, SampleRate, finish, save

ScrapeSeconds = 1.3
ScrapePeak = 0.7 # of full scale: under the crash it starts with
ScrapeSeed = 1813

# The grind: noise through a band, the band wandering as the point
# catches and slips
GrindLow = 900.0 # Hz
GrindHigh = 3800.0
GrindAttack = 0.02 # seconds: soft enough not to click
GrindDecay = 0.45 # seconds to 1/e
GrindWobble = 17.0 # Hz, how fast it catches and slips
GrindWobbleDepth = 0.55

# The hull's plates ringing under it
RingPitch = 210.0 # Hz
RingDecay = 0.5
RingLevel = 0.35
RingPartialFall = 0.5 # each partial at this share of the one under it

# The nose landing on the road
KnockPitch = 55.0 # Hz
KnockCutoff = 160.0
KnockDecay = 0.12
KnockLevel = 0.8

LandSeconds = 0.8
LandPeak = 0.6
LandSeed = 1814
LandPitch = 42.0 # Hz
LandCutoff = 140.0
LandAttack = 0.008
LandDecay = 0.16
RimPitch = 330.0 # Hz, the rim's short ring
RimDecay = 0.09
RimLevel = 0.18


def band_pass(sound, low, high):
    return sosfilt(butter(4, [low, high], btype='band', fs=SampleRate, output='sos'), sound)


def low_pass(sound, cutoff):
    return sosfilt(butter(4, cutoff, fs=SampleRate, output='sos'), sound)


def envelope(time, attack, decay):
    return np.clip(time / attack, 0, 1) * np.exp(-time / decay)


def ring(time, pitch, decay):
    sound = np.zeros(time.size)
    level = 1.0
    for ratio in BarRatios:
        sound = sound + level * np.sin(2 * np.pi * pitch * ratio * time)
        level = level * RingPartialFall
    return sound * np.exp(-time / decay)


def thump(time, random, pitch, cutoff, attack, decay):
    noise = low_pass(random.standard_normal(time.size), cutoff)
    noise = noise / np.abs(noise).max()
    tone = np.sin(2 * np.pi * pitch * time)
    return envelope(time, attack, decay) * (0.5 * noise + 0.5 * tone)


def scrape():
    random = np.random.default_rng(ScrapeSeed)
    time = np.arange(int(ScrapeSeconds * SampleRate)) / SampleRate
    grind = band_pass(random.standard_normal(time.size), GrindLow, GrindHigh)
    grind = grind / np.abs(grind).max()
    wobble = 1 - GrindWobbleDepth * (0.5 + 0.5 * np.sin(2 * np.pi * GrindWobble * time))
    grind = grind * wobble * envelope(time, GrindAttack, GrindDecay)
    plates = RingLevel * ring(time, RingPitch, RingDecay)
    knock = KnockLevel * thump(time, random, KnockPitch, KnockCutoff, GrindAttack, KnockDecay)
    return grind + plates + knock


def land():
    random = np.random.default_rng(LandSeed)
    time = np.arange(int(LandSeconds * SampleRate)) / SampleRate
    blow = thump(time, random, LandPitch, LandCutoff, LandAttack, LandDecay)
    rim = RimLevel * ring(time, RimPitch, RimDecay)
    return blow + rim


def main():
    here = Path(__file__).resolve().parent
    sounds = Path(sys.argv[1]) if len(sys.argv) > 1 else here.parents[1] / 'bin' / 'sounds'
    save(sounds / 'scrape.wav', finish(scrape(), ScrapePeak))
    save(sounds / 'wheelland.wav', finish(land(), LandPeak))


if __name__ == '__main__':
    main()
