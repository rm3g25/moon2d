"""Synthesises the end of the Ram's air fight into bin/sounds:
hullgroan.wav, hullbreak.wav, flightdown.wav and bargedock.wav. 44.1 kHz,
16 bit, mono - as the armor pings.

hullgroan.wav - the hull cracks (Game.Breakup: the throe, a second): a
groan of torn plates sliding down, inharmonic and beating, a crackle of
shorting wiring over it in fits, and a whine of a dying turbine falling
away under it all.

hullbreak.wav - it bursts: a blow far deeper than a dive's, the tearing
of metal, a long roll of thunder carrying it, and the debris rattling
under it as it dies - long, as the pieces fall slowly.

flightdown.wav - the flight slows to a stand (Game.Landing: six seconds):
the wind of the flight - a band of noise - sinking and thinning, a low
drone of the barges' engines sliding down an octave, both dying out as
the world comes to rest.

bargedock.wav - the main barge comes to rest against the road's edge: a
dull hydraulic thump, a short latch, a soft rattle settling.

  python finale.py [path/to/bin/sounds]

Needs numpy, scipy, armor.py and orblauncher.py beside it.
"""
import sys
from pathlib import Path

import numpy as np
from scipy.signal import butter, sosfilt

from armor import SampleRate, finish, save
from orblauncher import slide

Seed = 0x456E6421 # "End!"
Drive = 1.6 # into the soft clip

GroanSeconds = 1.1
GroanPeak = 0.75
GroanPitches = (61.0, 97.0, 149.0, 233.0) # inharmonic: plates, not a string
GroanFall = 0.7 # of itself by the end
GroanBeat = 0.012 # a twin this much sharp, beating
GroanLevel = 0.6
CrackleLow = 1500.0 # Hz
CrackleHigh = 7000.0
CrackleRate = 9.0 # fits a second
CrackleLevel = 0.35
WhineFrom = 900.0 # Hz
WhineTo = 180.0
WhineLevel = 0.18

BreakSeconds = 2.6
BreakPeak = 0.95
BlowFrom = 70.0 # Hz
BlowTo = 24.0
BlowSlide = 0.12
BlowDecay = 0.55
TearLow = 400.0 # Hz
TearHigh = 5000.0
TearDecay = 0.18
TearLevel = 0.55
ThunderLow = 25.0 # Hz
ThunderHigh = 220.0
ThunderAttack = 0.05 # seconds
ThunderDecay = 0.9
ThunderLevel = 0.8
RattleLow = 800.0 # Hz
RattleHigh = 3500.0
RattleRate = 14.0 # clinks a second, thinning
RattleLevel = 0.2
BreakOnset = 0.004 # seconds: a hard edge, not a click

DownSeconds = 198 / 33
DownPeak = 0.5
WindFrom = 2200.0 # Hz: the band of the wind, sinking with the speed
WindTo = 260.0
DroneFrom = 110.0 # Hz
DroneTo = 55.0
DroneLevel = 0.35

DockSeconds = 0.8
DockPeak = 0.7
ThumpFrom = 95.0 # Hz
ThumpTo = 48.0
ThumpSlide = 0.03
ThumpDecay = 0.18
LatchAt = 0.09 # seconds
LatchPitches = (612.0, 947.0, 1433.0)
LatchDecay = 0.05
LatchLevel = 0.25
SettleLow = 600.0 # Hz
SettleHigh = 3000.0
SettleDecay = 0.25
SettleLevel = 0.12


def band(sound, low, high):
    return sosfilt(butter(4, [low, high], btype='band', fs=SampleRate, output='sos'), sound)


def normalised(sound):
    return sound / np.abs(sound).max()


def times(seconds):
    return np.arange(int(SampleRate * seconds)) / SampleRate


def gliding(time, pitch_from, pitch_to, seconds):
    """A tone gliding by a ratio, evenly to the ear, over seconds."""
    share = np.clip(time / seconds, 0, 1)
    pitch = pitch_from * (pitch_to / pitch_from) ** share
    return np.sin(2 * np.pi * np.cumsum(pitch) / SampleRate)


def fits(time, rate, rng):
    """On and off at random, about rate times a second."""
    gate = np.zeros(len(time))
    at = 0.0
    while at < time[-1]:
        length = rng.uniform(0.3, 0.7) / rate
        start = int(at * SampleRate)
        stop = min(int((at + length) * SampleRate), len(time))
        gate[start:stop] = 1.0
        at += rng.uniform(0.8, 1.6) / rate
    return gate


def groan(rng):
    time = times(GroanSeconds)
    share = time / GroanSeconds
    sound = np.zeros(len(time))
    for pitch_hz in GroanPitches:
        for twin in (1.0, 1.0 + GroanBeat):
            sound += gliding(time, pitch_hz * twin, pitch_hz * twin * GroanFall, GroanSeconds)
    sound = GroanLevel * normalised(sound) * np.clip(time / 0.03, 0, 1) * (1 - 0.5 * share)
    crackle = normalised(band(rng.uniform(-1, 1, len(time)), CrackleLow, CrackleHigh))
    sound += CrackleLevel * crackle * fits(time, CrackleRate, rng)
    sound += WhineLevel * gliding(time, WhineFrom, WhineTo, GroanSeconds) * (1 - share)
    return np.tanh(Drive * sound) / np.tanh(Drive)


def burst(rng):
    time = times(BreakSeconds)
    sound = slide(time, BlowFrom, BlowTo, BlowSlide, BlowDecay)
    tear = normalised(band(rng.uniform(-1, 1, len(time)), TearLow, TearHigh))
    sound += TearLevel * tear * np.exp(-time / TearDecay)
    thunder = normalised(band(rng.uniform(-1, 1, len(time)), ThunderLow, ThunderHigh))
    swell = np.clip(time / ThunderAttack, 0, 1)
    sound += ThunderLevel * thunder * swell * np.exp(-time / ThunderDecay)
    rattle = normalised(band(rng.uniform(-1, 1, len(time)), RattleLow, RattleHigh))
    thinning = np.exp(-time / (BreakSeconds / 2))
    sound += RattleLevel * rattle * fits(time, RattleRate, rng) * thinning
    sound *= np.clip(time / BreakOnset, 0, 1)
    return np.tanh(Drive * sound) / np.tanh(Drive)


def down(rng):
    time = times(DownSeconds)
    share = np.clip(time / DownSeconds, 0, 1)
    # the speed as the belt has it: a smooth step down
    speed = 1 - share * share * (3 - 2 * share)
    noise = rng.uniform(-1, 1, len(time))
    wind = np.zeros(len(time))
    block = SampleRate // 25
    for start in range(0, len(time), block):
        stop = min(start + block * 2, len(time))
        centre = WindTo * (WindFrom / WindTo) ** speed[start]
        part = band(noise[start:stop], centre * 0.5, centre * 1.5)
        wind[start:start + block] += part[:min(block, stop - start)]
    wind = normalised(wind)
    pitch = DroneTo + (DroneFrom - DroneTo) * speed
    drone = np.sin(2 * np.pi * np.cumsum(pitch) / SampleRate)
    sound = (wind + DroneLevel * drone) * speed * np.clip(time / 0.2, 0, 1)
    return np.tanh(Drive * sound) / np.tanh(Drive)


def dock(rng):
    time = times(DockSeconds)
    sound = slide(time, ThumpFrom, ThumpTo, ThumpSlide, ThumpDecay)
    after = np.clip(time - LatchAt, 0, None)
    latch = sum(np.sin(2 * np.pi * pitch_hz * time) for pitch_hz in LatchPitches)
    sound += LatchLevel * latch * (time >= LatchAt) * np.exp(-after / LatchDecay)
    settle = normalised(band(rng.uniform(-1, 1, len(time)), SettleLow, SettleHigh))
    sound += SettleLevel * settle * fits(time, 20.0, rng) * np.exp(-after / SettleDecay) * (time >= LatchAt)
    sound *= np.clip(time / 0.004, 0, 1)
    return np.tanh(Drive * sound) / np.tanh(Drive)


def main():
    here = Path(__file__).resolve().parent
    sounds = Path(sys.argv[1]) if len(sys.argv) > 1 else here.parents[1] / 'bin' / 'sounds'
    rng = np.random.default_rng(Seed)
    for name, make, peak, seconds in (
            ('hullgroan.wav', groan, GroanPeak, GroanSeconds),
            ('hullbreak.wav', burst, BreakPeak, BreakSeconds),
            ('flightdown.wav', down, DownPeak, DownSeconds),
            ('bargedock.wav', dock, DockPeak, DockSeconds)):
        save(sounds / name, finish(make(rng), peak))
        print(f'{sounds / name}: {seconds:.2f} s')


if __name__ == '__main__':
    main()
