"""Synthesises the three sounds of TeK-R13, the Ram, into bin/sounds:
ramrumble.wav, ramhiss.wav, ramwhine.wav. 44.1 kHz, 16 bit, mono - as the
armor pings.

The rumble is a loop that plays while the Ram drives: a low diesel-like
tone of the engine, the cleats of the two wheels striking the road in a
rolling "dr-dr-dr", and the grind of the road under them. Every part of
it repeats a whole number of times within the loop, and the noise is
shaped round the loop in the frequency domain, so the end runs into the
start with no seam.

The hiss is the brake: a dull clunk as the shoes bite, then the air let
out of the brakes, bright and dying away.

The whine is the mast rising out of its well: a hydraulic pump whose
pitch climbs as the sections slide out, a flutter of the pump's strokes
over it, and a heavy clank as the head locks at its height.

  python ram.py [path/to/bin/sounds]

Needs numpy, scipy and armor.py beside it.
"""
import sys
from pathlib import Path

import numpy as np
from scipy.signal import butter, sosfilt

from armor import SampleRate, finish, save

# The loop. 2 s holds a whole number of every period below.
LoopSeconds = 2.0
RumblePeak = 0.5 # of full scale: it runs under the boss track for a while
RumbleSeed = 1301
EnginePitch = 31.0 # Hz, 62 cycles a loop
EngineOvertones = 16
EngineOvertoneFall = 1.3
EngineLevel = 0.55
EngineThrob = 4.0 # Hz, the firing of the cylinders felt as a pulse
EngineThrobDepth = 0.35
CleatRate = 13.0 # strikes a second, 26 a loop: the "dr-dr-dr"
CleatPitch = 58.0 # Hz, the thud of a cleat on the plate
CleatDecay = 0.025 # seconds to 1/e
CleatLevel = 0.9
CleatClick = 0.25 # the bright edge of a strike
CleatJitter = 0.25 # of the level, strike to strike
RoadLevel = 0.35
RoadTop = 380.0 # Hz, the grind of the road
RumbleDrive = 1.2

HissSeconds = 1.3
HissPeak = 0.55
HissSeed = 1302
ClunkPitch = 46.0
ClunkDecay = 0.09
ClunkLevel = 1.0
AirFrom = 0.05 # seconds: the air comes after the clunk
AirAttack = 0.02
AirDecay = 0.33
AirLow = 2200.0 # Hz, the band of the escaping air
AirHigh = 7500.0
AirLevel = 0.55

WhineSeconds = 1.75
WhinePeak = 0.42
WhineSeed = 1303
RiseSeconds = 1.5 # the mast rises this long, then locks
PumpFrom = 150.0 # Hz
PumpTo = 330.0
PumpOvertones = 6
PumpStroke = 24.0 # Hz, the flutter of the strokes
PumpStrokeDepth = 0.4
PumpLevel = 0.6
PumpAttack = 0.08
LockPitch = 70.0 # the clank of the lock
LockDecay = 0.12
LockLevel = 1.0
LockRing = 640.0 # Hz, the steel ringing over it
LockRingDecay = 0.05
LockRingLevel = 0.35


def periodic_noise(samples, low, high, seed):
    """Noise of the given band that repeats seamlessly every `samples`."""
    dice = np.random.default_rng(seed)
    spectrum = np.fft.rfft(dice.standard_normal(samples))
    freqs = np.fft.rfftfreq(samples, 1 / SampleRate)
    spectrum[(freqs < low) | (freqs > high)] = 0
    noise = np.fft.irfft(spectrum, samples)
    return noise / np.abs(noise).max()


def band_noise(samples, low, high, seed):
    dice = np.random.default_rng(seed)
    sos = butter(4, (low, high), btype='bandpass', fs=SampleRate, output='sos')
    noise = sosfilt(sos, dice.uniform(-1, 1, samples))
    return noise / np.abs(noise).max()


def rumble():
    samples = int(SampleRate * LoopSeconds)
    time = np.arange(samples) / SampleRate
    phase = 2 * np.pi * EnginePitch * time
    engine = np.zeros(samples)
    for overtone in range(1, EngineOvertones + 1):
        engine = engine + np.sin(overtone * phase) / overtone ** EngineOvertoneFall
    throb = 1 - EngineThrobDepth * (0.5 + 0.5 * np.cos(2 * np.pi * EngineThrob * time))
    sound = EngineLevel * engine * throb

    # A strike's tail is wrapped round the end of the loop
    dice = np.random.default_rng(RumbleSeed)
    strikes = int(CleatRate * LoopSeconds)
    click = periodic_noise(samples, 600, 3000, RumbleSeed + 1)
    for strike in range(strikes):
        start = strike / CleatRate
        since = (time - start) % LoopSeconds
        level = CleatLevel * (1 + CleatJitter * dice.uniform(-1, 1))
        envelope = np.exp(-since / CleatDecay)
        thud = np.sin(2 * np.pi * CleatPitch * since) + CleatClick * click
        sound = sound + level * thud * envelope

    sound = sound + RoadLevel * periodic_noise(samples, 30, RoadTop, RumbleSeed + 2)
    sound = np.tanh(RumbleDrive * sound)
    sound = sound - sound.mean()
    return sound * (RumblePeak / np.abs(sound).max())


def hiss():
    samples = int(SampleRate * HissSeconds)
    time = np.arange(samples) / SampleRate
    clunk = ClunkLevel * np.sin(2 * np.pi * ClunkPitch * time) * np.exp(-time / ClunkDecay)
    since = np.maximum(time - AirFrom, 0)
    attack = np.minimum(since / AirAttack, 1)
    air = band_noise(samples, AirLow, AirHigh, HissSeed) * attack * np.exp(-since / AirDecay)
    air[time < AirFrom] = 0
    return clunk + AirLevel * air


def whine():
    samples = int(SampleRate * WhineSeconds)
    time = np.arange(samples) / SampleRate
    rising = np.minimum(time / RiseSeconds, 1)
    eased = rising * rising * (3 - 2 * rising)
    pitch = PumpFrom + (PumpTo - PumpFrom) * eased
    phase = 2 * np.pi * np.cumsum(pitch) / SampleRate
    pump = np.zeros(samples)
    for overtone in range(1, PumpOvertones + 1):
        pump = pump + np.sin(overtone * phase) / overtone
    stroke = 1 - PumpStrokeDepth * (0.5 + 0.5 * np.sin(2 * np.pi * PumpStroke * time))
    envelope = np.minimum(time / PumpAttack, 1)
    envelope = envelope * np.clip((RiseSeconds + 0.03 - time) / 0.03, 0, 1)
    sound = PumpLevel * np.tanh(pump) * stroke * envelope

    since = np.maximum(time - RiseSeconds, 0)
    locked = time >= RiseSeconds
    clank = LockLevel * np.sin(2 * np.pi * LockPitch * since) * np.exp(-since / LockDecay)
    ring = LockRingLevel * np.sin(2 * np.pi * LockRing * since) * np.exp(-since / LockRingDecay)
    grit = 0.3 * band_noise(samples, 800, 4000, WhineSeed) * np.exp(-since / 0.015)
    return sound + (clank + ring + grit) * locked


def main():
    here = Path(__file__).resolve().parent
    sounds = Path(sys.argv[1]) if len(sys.argv) > 1 else here.parents[1] / 'bin' / 'sounds'
    save(sounds / 'ramrumble.wav', rumble())
    save(sounds / 'ramhiss.wav', finish(hiss(), HissPeak))
    save(sounds / 'ramwhine.wav', finish(whine(), WhinePeak))


if __name__ == '__main__':
    main()
