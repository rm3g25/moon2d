"""Synthesises the Ram's charge into bin/sounds: chargewarn.wav,
chargerush.wav and chargebrake.wav. 44.1 kHz, 16 bit, mono - as the armor
pings.

chargewarn.wav - the band at the left edge (Game.Charge: 43 ticks of 33 a
second, a blink in 8): a two-tone alarm gated at the band's blink, the
upper tone on the bright half, under it the Ram's roar swelling from far
off - it is gathering speed out of sight, behind.

chargerush.wav - in at speed: a roar of low noise rushing up and past,
its tone falling as it goes by, and a whoosh of air sweeping down from
bright to dull.

chargebrake.wav - the brake: the nozzles thrown ahead, the fire slamming
against the way it goes - a low blow, a flare of roar that settles as it
slows, and a hiss of hot metal dying under it.

  python charge.py [path/to/bin/sounds]

Needs numpy, scipy, armor.py and orblauncher.py beside it.
"""
import sys
from pathlib import Path

import numpy as np
from scipy.signal import butter, sosfilt

from armor import SampleRate, finish, save
from orblauncher import slide

Seed = 0x43687267 # "Chrg"
Drive = 1.6 # into the soft clip

WarnSeconds = 43 / 33
WarnPeak = 0.7
WarnBlinkHz = 33 / 8
WarnTones = (520.0, 690.0) # Hz: dark half, bright half
WarnOvertones = ((1, 1.0), (2, 0.35), (3, 0.2))
WarnLevel = 0.45
WarnEdge = 0.006 # seconds: the gate's edges, no clicks
WarnRoarLow = 45.0 # Hz
WarnRoarHigh = 500.0
WarnRoarLevel = 0.7

RushSeconds = 1.2
RushPeak = 0.8
RushPeakAt = 0.3 # seconds: the loudest, as it goes by
RushRoarLow = 50.0 # Hz
RushRoarHigh = 900.0
RushToneFrom = 170.0 # Hz: the engine's tone, falling as it passes
RushToneTo = 75.0
RushToneLevel = 0.35
WhooshFrom = 2400.0 # Hz: the band of the air, sweeping down
WhooshTo = 350.0
WhooshLevel = 0.4

BrakeSeconds = 1.0
BrakePeak = 0.75
BlowFrom = 95.0 # Hz
BlowTo = 42.0
BlowSlide = 0.05
BlowDecay = 0.2
BlowLevel = 0.9
FlareLow = 40.0 # Hz
FlareHigh = 800.0
FlareAttack = 0.02
FlareDecay = 0.35
FlareLevel = 0.8
HissLow = 3000.0 # Hz
HissDecay = 0.4
HissLevel = 0.15


def band(sound, low, high):
    return sosfilt(butter(4, [low, high], btype='band', fs=SampleRate, output='sos'), sound)


def high_pass(sound, cutoff):
    return sosfilt(butter(4, cutoff, btype='high', fs=SampleRate, output='sos'), sound)


def normalised(sound):
    return sound / np.abs(sound).max()


def times(seconds):
    return np.arange(int(SampleRate * seconds)) / SampleRate


def warn(rng):
    time = times(WarnSeconds)
    blink = (time * WarnBlinkHz) % 1.0
    # on for the first half of a blink, edges eased
    gate = np.clip(np.minimum(blink, 0.5 - blink) / (WarnEdge * WarnBlinkHz), 0, 1)
    bright = (time * WarnBlinkHz) % 2.0 < 1.0
    pitch = np.where(bright, WarnTones[1], WarnTones[0])
    phase = 2 * np.pi * np.cumsum(pitch) / SampleRate
    tone = sum(level * np.sin(overtone * phase) for overtone, level in WarnOvertones)
    roar = normalised(band(rng.uniform(-1, 1, len(time)), WarnRoarLow, WarnRoarHigh))
    swell = (time / WarnSeconds) ** 2
    sound = WarnLevel * tone * gate + WarnRoarLevel * roar * swell
    return np.tanh(Drive * sound) / np.tanh(Drive)


def rush(rng):
    time = times(RushSeconds)
    # up fast to the pass, then away
    envelope = np.where(time < RushPeakAt, (time / RushPeakAt) ** 2,
        np.exp(-(time - RushPeakAt) / 0.3))
    roar = normalised(band(rng.uniform(-1, 1, len(time)), RushRoarLow, RushRoarHigh))
    share = np.clip(time / RushSeconds, 0, 1)
    pitch = RushToneFrom * (RushToneTo / RushToneFrom) ** share
    tone = np.sin(2 * np.pi * np.cumsum(pitch) / SampleRate)
    # the whoosh: noise through a band sweeping down, block by block
    noise = rng.uniform(-1, 1, len(time))
    whoosh = np.zeros(len(time))
    block = SampleRate // 50
    for start in range(0, len(time), block):
        stop = min(start + block * 2, len(time))
        centre = WhooshFrom * (WhooshTo / WhooshFrom) ** (start / len(time))
        part = band(noise[start:stop], centre * 0.6, centre * 1.4)
        whoosh[start:start + block] += part[:min(block, stop - start)]
    whoosh = normalised(whoosh)
    sound = envelope * (roar + RushToneLevel * tone + WhooshLevel * whoosh)
    return np.tanh(Drive * sound) / np.tanh(Drive)


def brake(rng):
    time = times(BrakeSeconds)
    blow = BlowLevel * slide(time, BlowFrom, BlowTo, BlowSlide, BlowDecay)
    flare = normalised(band(rng.uniform(-1, 1, len(time)), FlareLow, FlareHigh))
    flare *= FlareLevel * np.clip(time / FlareAttack, 0, 1) * np.exp(-time / FlareDecay)
    hiss = normalised(high_pass(rng.uniform(-1, 1, len(time)), HissLow))
    hiss *= HissLevel * np.exp(-time / HissDecay)
    sound = blow + flare + hiss
    return np.tanh(Drive * sound) / np.tanh(Drive)


def main():
    here = Path(__file__).resolve().parent
    sounds = Path(sys.argv[1]) if len(sys.argv) > 1 else here.parents[1] / 'bin' / 'sounds'
    rng = np.random.default_rng(Seed)
    for name, make, peak, seconds in (
            ('chargewarn.wav', warn, WarnPeak, WarnSeconds),
            ('chargerush.wav', rush, RushPeak, RushSeconds),
            ('chargebrake.wav', brake, BrakePeak, BrakeSeconds)):
        save(sounds / name, finish(make(rng), peak))
        print(f'{sounds / name}: {seconds:.2f} s')


if __name__ == '__main__':
    main()
