"""Synthesises the sound of the boss ramming a wall into bin/sounds:
crash.wav. 44.1 kHz, 16 bit, mono - as the armor pings.

A heavy steel disc stopped dead by concrete: a thud sliding down in
pitch, a crunch of noise with the treble taken off, and the hull ringing
after them - the partials of a free bar again, low and slow to die. The
sum is pushed into a soft clip: a blow that size does not stay clean.

  python crash.py [path/to/bin/sounds]

Needs numpy and armor.py beside it.
"""
import sys
from pathlib import Path

import numpy as np

from armor import BarRatios, SampleRate, TwinDetune, TwinLevel, finish, save

CrashSeconds = 0.9
CrashPeak = 0.8 # of full scale: louder than a ping, under a death blast
CrashSeed = 2026

ThudFrom = 150.0 # Hz
ThudTo = 58.0
ThudSlide = 0.05 # seconds for the pitch to cover 1/e of the way
ThudDecay = 0.17 # seconds to 1/e
ThudLevel = 0.6
ThudOvertone = 0.35

CrunchDecay = 0.045
CrunchSmooth = 9 # samples averaged: takes the hiss off the noise

HullPitch = 205.0 # Hz, the lowest partial
HullPartialLevels = (0.5, 0.42, 0.26, 0.14)
HullPartialDecays = (0.30, 0.21, 0.12, 0.07)
HullLevel = 0.9

Drive = 1.6 # into the soft clip


def thud(time):
    pitch = ThudTo + (ThudFrom - ThudTo) * np.exp(-time / ThudSlide)
    phase = 2 * np.pi * np.cumsum(pitch) / SampleRate
    tone = np.sin(phase) + ThudOvertone * np.sin(2 * phase)
    return ThudLevel * tone * np.exp(-time / ThudDecay)


def crunch(time, seed):
    dice = np.random.default_rng(seed)
    noise = dice.uniform(-1, 1, time.size)
    noise = np.convolve(noise, np.ones(CrunchSmooth) / CrunchSmooth, mode='same')
    return noise / np.abs(noise).max() * np.exp(-time / CrunchDecay)


def hull(time):
    sound = np.zeros(time.size)
    for ratio, level, decay in zip(BarRatios, HullPartialLevels, HullPartialDecays):
        tone = HullPitch * ratio
        ring = np.sin(2 * np.pi * tone * time)
        ring = ring + TwinLevel * np.sin(2 * np.pi * tone * TwinDetune * time)
        sound = sound + level * ring * np.exp(-time / decay)
    return HullLevel * sound


def crash(seed):
    time = np.arange(int(SampleRate * CrashSeconds)) / SampleRate
    return np.tanh(Drive * (thud(time) + crunch(time, seed) + hull(time)))


def main():
    here = Path(__file__).resolve().parent
    sounds = Path(sys.argv[1]) if len(sys.argv) > 1 else here.parents[1] / 'bin' / 'sounds'
    save(sounds / 'crash.wav', finish(crash(CrashSeed), CrashPeak))


if __name__ == '__main__':
    main()
