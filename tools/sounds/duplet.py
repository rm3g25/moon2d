"""Makes the shot of the Duplet into bin/sounds: duplet.wav. 44.1 kHz,
16 bit, mono - as the armor pings.

Built out of the 2008 shotgun, so the two stay one family: shootgun.wav
slowed down to sound heavier, fired twice a hair apart - the two barrels
going off together, not one after the other - over a low thump that
slides down in pitch, the push of the stock into the shoulder. The sum
goes into a soft clip.

  python duplet.py [path/to/bin/sounds]

Needs numpy and armor.py beside it.
"""
import sys
import wave
from pathlib import Path

import numpy as np

from armor import SampleRate, finish, save

ShotSource = 'shootgun.wav'
DupletSeconds = 0.75
DupletPeak = 0.85 # of full scale: the loudest gun the hero has

Slowdown = 0.8 # the shotgun played at this speed: lower and longer
SecondBarrelDelay = 0.014 # seconds; under 20 ms the ear hears one blow
SecondBarrelLevel = 0.8

ThumpFrom = 110.0 # Hz
ThumpTo = 42.0
ThumpSlide = 0.04 # seconds for the pitch to cover 1/e of the way
ThumpDecay = 0.14 # seconds to 1/e
ThumpLevel = 0.7

Drive = 1.8 # into the soft clip
TailSeconds = 0.25 # the slowed shot is longer than the sound: it fades out


def read_source(path):
    with wave.open(str(path), 'rb') as source:
        rate = source.getframerate()
        width = source.getsampwidth()
        frames = source.readframes(source.getnframes())
    if width == 1:
        samples = (np.frombuffer(frames, dtype=np.uint8).astype(np.float64) - 128) / 128
    else:
        samples = np.frombuffer(frames, dtype='<i2').astype(np.float64) / 32768
    return samples, rate


def resampled(samples, rate, speed):
    """To SampleRate, played at the speed given."""
    length = int(samples.size * SampleRate / rate / speed)
    places = np.linspace(0, samples.size - 1, length)
    return np.interp(places, np.arange(samples.size), samples)


def thump(time):
    pitch = ThumpTo + (ThumpFrom - ThumpTo) * np.exp(-time / ThumpSlide)
    phase = 2 * np.pi * np.cumsum(pitch) / SampleRate
    return ThumpLevel * np.sin(phase) * np.exp(-time / ThumpDecay)


def main():
    here = Path(__file__).resolve().parent
    sounds = Path(sys.argv[1]) if len(sys.argv) > 1 else here.parents[1] / 'bin' / 'sounds'
    samples, rate = read_source(sounds / ShotSource)
    shot = resampled(samples, rate, Slowdown)

    length = int(SampleRate * DupletSeconds)
    time = np.arange(length) / SampleRate
    sound = np.zeros(length)
    first = shot[:length]
    sound[:first.size] += first
    delay = int(SampleRate * SecondBarrelDelay)
    second = shot[:length - delay]
    sound[delay:delay + second.size] += SecondBarrelLevel * second
    sound += thump(time)
    sound = np.tanh(Drive * sound) / np.tanh(Drive)
    tail = int(SampleRate * TailSeconds)
    sound[-tail:] *= np.linspace(1, 0, tail)

    target = sounds / 'duplet.wav'
    save(target, finish(sound, DupletPeak))
    print(f'{target}: {DupletSeconds} s')


if __name__ == '__main__':
    main()
