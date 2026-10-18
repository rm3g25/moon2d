"""Synthesises the burn of the TEK-Q6 scanner into bin/sounds:
cordonburn.wav. 44.1 kHz, 16 bit, mono - as the armor pings.

The beam of the cordon turns hot on the betoner in the pit of level 1
screen 9 and burns it through (docs/mechanics/scenes.md): electricity
crunching down the beam. An unsteady buzz of the arc under it, a sizzle
of high noise that never settles, and the crunch itself - short snaps
of noise, dense and uneven, each of its own strength. One heavy snap
lands where the body gives (KillSecond, the kill a second after the
beam turns hot); then the arc dies away.

  python cordonburn.py [path/to/bin/sounds]

Needs numpy and armor.py beside it.
"""
import sys
from pathlib import Path

import numpy as np

from armor import SampleRate, finish, save

Seconds = 1.8
Peak = 0.75 # of full scale: over the hum and the soundtrack
Seed = 693

Attack = 0.02 # seconds
KillSecond = 1.0 # the heavy snap: the scene's kill comes a second in
Release = 0.35 # seconds to 1/e after the kill

ArcPitch = 118.0 # Hz
ArcOvertones = 9
ArcLevel = 0.35
ArcFlutter = 0.6 # how deep the level of the arc shakes, 0..1
FlutterSmooth = 220 # samples: the shaking is fast, not a hiss

SizzleLevel = 0.25

SnapsPerSecond = 70.0
SnapShortest = 0.0015 # seconds to 1/e
SnapLongest = 0.006
SnapLevel = 1.0
KillSnapDecay = 0.03
KillSnapLevel = 2.2

Drive = 1.4 # into the soft clip


def smoothed(noise, width):
    return np.convolve(noise, np.ones(width) / width, mode='same')


def envelope(time):
    rise = np.clip(time / Attack, 0, 1)
    fall = np.where(time < KillSecond, 1.0, np.exp(-(time - KillSecond) / Release))
    return rise * fall


def arc(time, dice):
    phase = 2 * np.pi * ArcPitch * time
    tone = np.zeros(time.size)
    for overtone in range(1, ArcOvertones + 1):
        tone = tone + np.sin(overtone * phase) / overtone
    flutter = smoothed(dice.uniform(-1, 1, time.size), FlutterSmooth)
    flutter = flutter / np.abs(flutter).max()
    return ArcLevel * tone * (1 - ArcFlutter * (0.5 + 0.5 * flutter))


# High noise: each sample less its neighbour takes the low end off
def sizzle(time, dice):
    noise = dice.uniform(-1, 1, time.size)
    high = np.diff(noise, prepend=0.0)
    swell = smoothed(dice.uniform(0, 1, time.size), 2000)
    return SizzleLevel * high * swell / swell.max()


def snap(time, start, decay, level, dice):
    sound = np.zeros(time.size)
    first = int(start * SampleRate)
    length = min(int(decay * 8 * SampleRate), time.size - first)
    if length <= 0:
        return sound
    local = np.arange(length) / SampleRate
    burst = dice.uniform(-1, 1, length)
    burst = np.diff(burst, prepend=0.0)
    sound[first:first + length] = level * burst * np.exp(-local / decay)
    return sound


def crunch(time, dice):
    sound = np.zeros(time.size)
    count = dice.poisson(SnapsPerSecond * KillSecond)
    for start in dice.uniform(0, KillSecond, count):
        decay = dice.uniform(SnapShortest, SnapLongest)
        sound = sound + snap(time, start, decay, SnapLevel * dice.uniform(0.2, 1.0), dice)
    return sound + snap(time, KillSecond, KillSnapDecay, KillSnapLevel, dice)


def burn():
    dice = np.random.default_rng(Seed)
    time = np.arange(int(SampleRate * Seconds)) / SampleRate
    sound = (arc(time, dice) + sizzle(time, dice) + crunch(time, dice)) * envelope(time)
    return np.tanh(Drive * sound)


def main():
    here = Path(__file__).resolve().parent
    sounds = Path(sys.argv[1]) if len(sys.argv) > 1 else here.parents[1] / 'bin' / 'sounds'
    save(sounds / 'cordonburn.wav', finish(burn(), Peak))


if __name__ == '__main__':
    main()
