"""Makes the orb gun's two sounds into bin/sounds: orbgun.wav, the shot,
and orbhit.wav, an orb sinking into the Ram's bare hull. 44.1 kHz, 16 bit,
mono - as the armor pings.

The gun is a sledgehammer after a pistol, heavier in look and sound, not
slower: the shot is a low blow with no crack in it - a sub thump sliding
down in pitch under a short breath of dark noise, the air the orb pushes
out of the muzzle - and a hollow ring after it, two low partials a fifth
apart, dying fast: the moon in it. Low sounds come out right in code,
clicks and crackles do not, so there is no crack and no click.

The hit is the shot's thump an octave lower and longer, with the hull's
answer over it - a dull clang of three inharmonic partials low in the
range, damped hard, the plates taking a weight rather than ringing.

  python orbgun.py [path/to/bin/sounds]

Needs numpy and armor.py beside it.
"""
import sys
from pathlib import Path

import numpy as np

from armor import SampleRate, finish, save

ShotSeconds = 0.42
ShotPeak = 0.8 # under the Duplet's 0.85: it fires four times as often

ThumpFrom = 150.0 # Hz
ThumpTo = 48.0
ThumpSlide = 0.025 # seconds for the pitch to cover 1/e of the way
ThumpDecay = 0.09 # seconds to 1/e
ThumpLevel = 1.0

BreathCutoff = 900.0 # Hz: dark noise, no hiss
BreathDecay = 0.035
BreathLevel = 0.35

RingPitches = (196.0, 294.0) # a fifth apart
RingDecay = 0.12
RingLevel = 0.18
RingOnset = 0.012 # seconds: it swells in behind the blow

HitSeconds = 0.6
HitPeak = 0.75
HitThumpFrom = 90.0
HitThumpTo = 30.0
HitThumpSlide = 0.04
HitThumpDecay = 0.16
ClangPitches = (131.0, 207.0, 349.0) # inharmonic: a plate, not a bell
ClangDecays = (0.11, 0.07, 0.04)
ClangLevel = 0.3

Drive = 1.6 # into the soft clip
Seed = 0x4F726247 # "OrbG"


def slide(time, pitch_from, pitch_to, slide_seconds, decay):
    pitch = pitch_to + (pitch_from - pitch_to) * np.exp(-time / slide_seconds)
    phase = 2 * np.pi * np.cumsum(pitch) / SampleRate
    return np.sin(phase) * np.exp(-time / decay)


def dark_noise(length, cutoff, rng):
    """White noise through a one-pole low-pass, twice."""
    noise = rng.uniform(-1, 1, length)
    keep = np.exp(-2 * np.pi * cutoff / SampleRate)
    for _ in range(2):
        out = np.empty_like(noise)
        level = 0.0
        for i, sample in enumerate(noise):
            level = keep * level + (1 - keep) * sample
            out[i] = level
        noise = out
    return noise / np.abs(noise).max()


def shot(rng):
    length = int(SampleRate * ShotSeconds)
    time = np.arange(length) / SampleRate
    sound = ThumpLevel * slide(time, ThumpFrom, ThumpTo, ThumpSlide, ThumpDecay)
    sound += BreathLevel * dark_noise(length, BreathCutoff, rng) * np.exp(-time / BreathDecay)
    onset = np.clip(time / RingOnset, 0, 1)
    for pitch in RingPitches:
        sound += RingLevel * onset * np.sin(2 * np.pi * pitch * time) * np.exp(-time / RingDecay)
    return np.tanh(Drive * sound) / np.tanh(Drive)


def hit():
    length = int(SampleRate * HitSeconds)
    time = np.arange(length) / SampleRate
    sound = slide(time, HitThumpFrom, HitThumpTo, HitThumpSlide, HitThumpDecay)
    for pitch, decay in zip(ClangPitches, ClangDecays):
        sound += ClangLevel * np.sin(2 * np.pi * pitch * time) * np.exp(-time / decay)
    return np.tanh(Drive * sound) / np.tanh(Drive)


def main():
    here = Path(__file__).resolve().parent
    sounds = Path(sys.argv[1]) if len(sys.argv) > 1 else here.parents[1] / 'bin' / 'sounds'
    rng = np.random.default_rng(Seed)
    save(sounds / 'orbgun.wav', finish(shot(rng), ShotPeak))
    save(sounds / 'orbhit.wav', finish(hit(), HitPeak))
    print(f'{sounds / "orbgun.wav"}: {ShotSeconds} s; {sounds / "orbhit.wav"}: {HitSeconds} s')


if __name__ == '__main__':
    main()
