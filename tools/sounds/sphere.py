"""Synthesises the life sphere into bin/sounds: sphereform.wav and
spheretake.wav. 44.1 kHz, 16 bit, mono - as the armor pings.

Forming: the green sparks spiral in for 1.6 seconds - a glassy shimmer
of a few partials gliding up an octave and a half, each with a flutter of
its own, and tiny ticks of light that come thicker as the sphere grows.
As it comes whole, a soft chime of three notes rings out.

Taking: the sphere bursts - a short hiss of light over a soft thump -,
the sparks fly into the hero - the shimmer again, gliding up fast, and a
spray of ticks as they come in -, and a higher chime with a major
seventh closes it: the pickup of 200%, brighter than a medkit's.

  python sphere.py [path/to/bin/sounds]

Needs numpy, scipy and armor.py beside it.
"""
import sys
from pathlib import Path

import numpy as np
from scipy.signal import butter, sosfilt

from armor import SampleRate, finish, save

FormSeconds = 2.4
FormPeak = 0.7
FormSeed = 1201
FormWhole = 1.6 # seconds: the sphere comes whole, the chime
FormGlideFrom = 330.0 # Hz
FormGlideTo = 990.0 # Hz
FormChime = (1046.5, 1318.5, 1568.0) # C6 E6 G6

TakeSeconds = 1.6
TakePeak = 0.9
TakeSeed = 1202
TakeGlideFrom = 440.0 # Hz
TakeGlideTo = 1320.0 # Hz
TakeGlideSeconds = 0.45
TakeHome = (0.5, 0.75) # seconds: the sparks come into the hero
TakeChimeAt = 0.7
TakeChime = (1318.5, 1661.2, 1975.5, 2489.0) # E6 G#6 B6 D#7

Partials = (1.0, 1.5, 2.0, 3.0) # of the glide: a fifth and an octave over it
PartialFall = 0.8
Flutter = (5.0, 11.0) # Hz, the range of the partials' flutter
TickPitch = (2600.0, 5200.0) # Hz
TickSeconds = 0.025
ChimeDecay = 0.55 # seconds to 1/e
HissCutoff = 2400.0 # Hz, the hiss of the burst is above it
HissDecay = 0.12
ThumpFrom = 180.0 # Hz
ThumpTo = 60.0
ThumpSeconds = 0.25


def high_pass(sound, cutoff):
    return sosfilt(butter(4, cutoff, btype='highpass', fs=SampleRate,
                          output='sos'), sound)


def glide(time, start, end, seconds, random):
    """Partials gliding from start to end Hz over seconds, each fluttering."""
    share = np.clip(time / seconds, 0, 1)
    pitch = start * (end / start) ** share
    phase = 2 * np.pi * np.cumsum(pitch) / SampleRate
    tone = np.zeros(time.size)
    for number, partial in enumerate(Partials, start=1):
        rate = random.uniform(*Flutter)
        flutter = 0.6 + 0.4 * np.sin(2 * np.pi * rate * time + random.uniform(0, 6.3))
        tone = tone + flutter * np.sin(partial * phase) / number ** PartialFall
    return tone / np.abs(tone).max()


def ticks(time, moments, random):
    """A short bright blip at every moment, in seconds."""
    sound = np.zeros(time.size)
    length = int(TickSeconds * SampleRate)
    local = np.arange(length) / SampleRate
    shape = np.exp(-local / (TickSeconds / 4)) * np.sin(np.pi * local / TickSeconds)
    for moment in moments:
        start = int(moment * SampleRate)
        if start + length > time.size:
            continue
        pitch = random.uniform(*TickPitch)
        level = random.uniform(0.4, 1.0)
        sound[start:start + length] += level * shape * np.sin(2 * np.pi * pitch * local)
    return sound


def chime(time, at, notes):
    since = np.maximum(time - at, 0)
    after = time >= at
    attack = np.clip(since / 0.004, 0, 1)
    tone = np.zeros(time.size)
    for number, note in enumerate(notes):
        decay = np.exp(-since / (ChimeDecay * (1 - 0.12 * number)))
        tone = tone + decay * (np.sin(2 * np.pi * note * since) +
                               0.25 * np.sin(4 * np.pi * note * since))
    return np.where(after, attack * tone / len(notes), 0)


def form():
    random = np.random.default_rng(FormSeed)
    time = np.arange(int(FormSeconds * SampleRate)) / SampleRate
    swell = np.clip(time / FormWhole, 0, 1) ** 1.5
    fade = np.interp(time, [0, FormWhole, FormWhole + 0.3, FormSeconds], [1, 1, 0.15, 0])
    shimmer = glide(time, FormGlideFrom, FormGlideTo, FormWhole, random)
    shimmer = shimmer * (0.15 + 0.6 * swell) * fade
    # Thicker as the sphere grows: the moments fall closer toward the end
    moments = FormWhole * np.sqrt(random.uniform(0, 1, 70))
    sparkle = 0.5 * ticks(time, np.sort(moments), random)
    return shimmer + sparkle + 0.9 * chime(time, FormWhole, FormChime)


def burst(time, random):
    hiss = high_pass(random.standard_normal(time.size), HissCutoff)
    hiss = hiss / np.abs(hiss).max() * np.exp(-time / HissDecay)
    share = np.clip(time / ThumpSeconds, 0, 1)
    pitch = ThumpFrom * (ThumpTo / ThumpFrom) ** share
    thump = np.sin(2 * np.pi * np.cumsum(pitch) / SampleRate) * (1 - share) ** 2
    return 0.5 * hiss + 0.8 * thump


def take():
    random = np.random.default_rng(TakeSeed)
    time = np.arange(int(TakeSeconds * SampleRate)) / SampleRate
    fly = np.interp(time, [0, 0.05, TakeHome[1], TakeHome[1] + 0.2, TakeSeconds],
                    [0, 0.7, 0.6, 0, 0])
    shimmer = glide(time, TakeGlideFrom, TakeGlideTo, TakeGlideSeconds, random) * fly
    moments = random.uniform(*TakeHome, 26)
    sparkle = 0.6 * ticks(time, np.sort(moments), random)
    return burst(time, random) + shimmer + sparkle + chime(time, TakeChimeAt, TakeChime)


def main():
    here = Path(__file__).resolve().parent
    sounds = Path(sys.argv[1]) if len(sys.argv) > 1 else here.parents[1] / 'bin' / 'sounds'
    save(sounds / 'sphereform.wav', finish(form(), FormPeak))
    save(sounds / 'spheretake.wav', finish(take(), TakePeak))


if __name__ == '__main__':
    main()
