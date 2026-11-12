"""Synthesises the Ram's dive into bin/sounds: divecut.wav, divefall.wav,
diveslam.wav and diverelight.wav. 44.1 kHz, 16 bit, mono - as the armor
pings.

divecut.wav - the jets go out (Game.Dive: the silence, 16 ticks of 33 a
second): the roar choking off fast, its tone sinking, a cough of the
fire's last breath, and under it a groan of the hull settling onto
nothing. Short on purpose: the rest of the half second is the silence.

divefall.wav - like a stone, about half a second: air tearing past the
hull, a band of noise rising as it gathers speed, and a low howl rising
with it, loudest at the end, where the blow comes in.

diveslam.wav - the blow over the main barge: a deep thud sliding down,
the clang of heavy plates, inharmonic, a crunch of torn metal, and the
rumble of the barge rocking under it dying away.

diverelight.wav - the jets catch again, hot: a dull pop, the roar
whooshing up out of it to a flare and settling, a hiss of hot metal
under it - the loop of the hanging jets takes over.

  python dive.py [path/to/bin/sounds]

Needs numpy, scipy, armor.py and orblauncher.py beside it.
"""
import sys
from pathlib import Path

import numpy as np
from scipy.signal import butter, sosfilt

from armor import SampleRate, finish, save
from orblauncher import slide

Seed = 0x44697665 # "Dive"
Drive = 1.6 # into the soft clip

CutSeconds = 0.5
CutPeak = 0.6
CutRoarLow = 45.0 # Hz
CutRoarHigh = 1200.0
CutChoke = 0.09 # seconds: the roar's fall
CutToneFrom = 150.0 # Hz: the jets' tone, sinking as they die
CutToneTo = 55.0
CutToneLevel = 0.4
CoughAt = 0.11 # seconds
CoughDecay = 0.04
CoughLevel = 0.5
GroanFrom = 70.0 # Hz
GroanTo = 48.0
GroanLevel = 0.25
GroanDecay = 0.25

FallSeconds = 17 / 33
FallPeak = 0.75
AirFrom = 300.0 # Hz: the band of the air, rising with the speed
AirTo = 2600.0
HowlFrom = 90.0 # Hz
HowlTo = 210.0
HowlLevel = 0.3

SlamSeconds = 1.3
SlamPeak = 0.9
ThudFrom = 85.0 # Hz
ThudTo = 30.0
ThudSlide = 0.06
ThudDecay = 0.3
ThudLevel = 1.0
ClangPitches = (143.0, 227.0, 351.0, 518.0) # inharmonic: plates, not a bell
ClangDecays = (0.35, 0.22, 0.14, 0.08)
ClangLevel = 0.3
CrunchLow = 300.0 # Hz
CrunchHigh = 4000.0
CrunchDecay = 0.07
CrunchLevel = 0.5
RumbleLow = 30.0 # Hz
RumbleHigh = 160.0
RumbleDecay = 0.5
RumbleLevel = 0.5
SlamOnset = 0.003 # seconds: a hard edge, not a click

RelightSeconds = 0.9
RelightPeak = 0.75
PopFrom = 110.0 # Hz
PopTo = 45.0
PopSlide = 0.02
PopDecay = 0.07
PopLevel = 0.7
FlareRoarLow = 45.0 # Hz
FlareRoarHigh = 1500.0
FlareAttack = 0.12 # seconds: the whoosh up
FlareSettle = 0.3
FlareLevel = 0.85
FlareRest = 0.45 # of itself, settled
HissLow = 3000.0 # Hz
HissDecay = 0.35
HissLevel = 0.15


def band(sound, low, high):
    return sosfilt(butter(4, [low, high], btype='band', fs=SampleRate, output='sos'), sound)


def high_pass(sound, cutoff):
    return sosfilt(butter(4, cutoff, btype='high', fs=SampleRate, output='sos'), sound)


def normalised(sound):
    return sound / np.abs(sound).max()


def times(seconds):
    return np.arange(int(SampleRate * seconds)) / SampleRate


def gliding(time, pitch_from, pitch_to, seconds):
    """A tone gliding by a ratio, evenly to the ear, over seconds."""
    share = np.clip(time / seconds, 0, 1)
    pitch = pitch_from * (pitch_to / pitch_from) ** share
    return np.sin(2 * np.pi * np.cumsum(pitch) / SampleRate)


def cut(rng):
    time = times(CutSeconds)
    choke = np.exp(-time / CutChoke)
    roar = normalised(band(rng.uniform(-1, 1, len(time)), CutRoarLow, CutRoarHigh))
    tone = CutToneLevel * gliding(time, CutToneFrom, CutToneTo, CutChoke * 2)
    sound = choke * (roar + tone)
    after = np.clip(time - CoughAt, 0, None)
    cough = normalised(band(rng.uniform(-1, 1, len(time)), 80.0, 600.0))
    sound += CoughLevel * cough * (time >= CoughAt) * np.exp(-after / CoughDecay)
    groan = gliding(time, GroanFrom, GroanTo, CutSeconds)
    sound += GroanLevel * groan * np.clip(time / 0.05, 0, 1) * np.exp(-time / GroanDecay)
    return np.tanh(Drive * sound) / np.tanh(Drive)


def fall(rng):
    time = times(FallSeconds)
    share = np.clip(time / FallSeconds, 0, 1)
    # the air: noise through a band rising, block by block
    noise = rng.uniform(-1, 1, len(time))
    air = np.zeros(len(time))
    block = SampleRate // 50
    for start in range(0, len(time), block):
        stop = min(start + block * 2, len(time))
        centre = AirFrom * (AirTo / AirFrom) ** (start / len(time))
        part = band(noise[start:stop], centre * 0.6, centre * 1.4)
        air[start:start + block] += part[:min(block, stop - start)]
    air = normalised(air)
    howl = HowlLevel * gliding(time, HowlFrom, HowlTo, FallSeconds)
    # louder with the speed, which grows evenly
    sound = (0.15 + 0.85 * share ** 2) * (air + howl)
    return np.tanh(Drive * sound) / np.tanh(Drive)


def slam(rng):
    time = times(SlamSeconds)
    sound = ThudLevel * slide(time, ThudFrom, ThudTo, ThudSlide, ThudDecay)
    for pitch_hz, decay in zip(ClangPitches, ClangDecays):
        sound += ClangLevel * np.sin(2 * np.pi * pitch_hz * time) * np.exp(-time / decay)
    crunch = normalised(band(rng.uniform(-1, 1, len(time)), CrunchLow, CrunchHigh))
    sound += CrunchLevel * crunch * np.exp(-time / CrunchDecay)
    rumble = normalised(band(rng.uniform(-1, 1, len(time)), RumbleLow, RumbleHigh))
    sound += RumbleLevel * rumble * np.exp(-time / RumbleDecay)
    sound *= np.clip(time / SlamOnset, 0, 1)
    return np.tanh(Drive * sound) / np.tanh(Drive)


def relight(rng):
    time = times(RelightSeconds)
    sound = PopLevel * slide(time, PopFrom, PopTo, PopSlide, PopDecay)
    roar = normalised(band(rng.uniform(-1, 1, len(time)), FlareRoarLow, FlareRoarHigh))
    up = np.clip(time / FlareAttack, 0, 1) ** 2
    settle = FlareRest + (1 - FlareRest) * np.exp(-np.clip(time - FlareAttack, 0, None) / FlareSettle)
    sound += FlareLevel * roar * up * settle
    hiss = normalised(high_pass(rng.uniform(-1, 1, len(time)), HissLow))
    sound += HissLevel * hiss * np.exp(-time / HissDecay)
    return np.tanh(Drive * sound) / np.tanh(Drive)


def main():
    here = Path(__file__).resolve().parent
    sounds = Path(sys.argv[1]) if len(sys.argv) > 1 else here.parents[1] / 'bin' / 'sounds'
    rng = np.random.default_rng(Seed)
    for name, make, peak, seconds in (
            ('divecut.wav', cut, CutPeak, CutSeconds),
            ('divefall.wav', fall, FallPeak, FallSeconds),
            ('diveslam.wav', slam, SlamPeak, SlamSeconds),
            ('diverelight.wav', relight, RelightPeak, RelightSeconds)):
        save(sounds / name, finish(make(rng), peak))
        print(f'{sounds / name}: {seconds:.2f} s')


if __name__ == '__main__':
    main()
