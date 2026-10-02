"""Synthesises the sounds of a bullet on armor into bin/sounds: three
pings (armor1..3.wav), played in turn, and the whine of a tracer flying
off (ricochet.wav). 44.1 kHz, 16 bit, mono - as countdown.wav and
terminal.wav.

A ping is a struck steel plate: a click of noise, then a few partials at
the ratios of a free bar, the high ones dying first. The whine is the
same strike with a tone sliding down under it.

  python armor.py [path/to/bin/sounds]

Needs numpy.
"""
import sys
import wave
from pathlib import Path

import numpy as np

SampleRate = 44100
PingSeconds = 0.24
WhineSeconds = 0.5
PingPeak = 0.42 # of full scale: quieter than a gunshot, they come in bursts
WhinePeak = 0.36
FadeSeconds = 0.006

# The transverse modes of a free bar, relative to the lowest
BarRatios = (1.0, 2.76, 5.40, 8.93)
PartialLevels = (1.0, 0.6, 0.35, 0.2)
PartialDecays = (0.070, 0.045, 0.028, 0.016) # seconds to 1/e
# Each partial rings against a slightly detuned twin: the shimmer of a
# plate that is not perfectly even
TwinDetune = 1.006
TwinLevel = 0.5
ClickDecay = 0.0012
ClickLevel = 0.8
PingPitches = (1450.0, 1720.0, 2050.0) # Hz, one per file

WhineFrom = 3300.0 # Hz
WhineTo = 1150.0
WhineSlide = 0.16 # seconds for the pitch to cover 1/e of the way
WhineDecay = 0.17
WhineLevel = 0.9
WhineOvertone = 0.3
WhineStrikePitch = 2400.0
WhineStrikeLevel = 0.5


def strike(pitch, seconds, seed):
    time = np.arange(int(SampleRate * seconds)) / SampleRate
    dice = np.random.default_rng(seed)
    sound = ClickLevel * dice.uniform(-1, 1, time.size) * np.exp(-time / ClickDecay)
    for ratio, level, decay in zip(BarRatios, PartialLevels, PartialDecays):
        tone = pitch * ratio
        if tone * TwinDetune >= SampleRate / 2:
            continue
        ring = np.sin(2 * np.pi * tone * time)
        ring = ring + TwinLevel * np.sin(2 * np.pi * tone * TwinDetune * time)
        sound = sound + level * ring * np.exp(-time / decay)
    return sound


def whine(seed):
    time = np.arange(int(SampleRate * WhineSeconds)) / SampleRate
    pitch = WhineTo + (WhineFrom - WhineTo) * np.exp(-time / WhineSlide)
    phase = 2 * np.pi * np.cumsum(pitch) / SampleRate
    tone = np.sin(phase) + WhineOvertone * np.sin(2 * phase)
    sound = WhineLevel * tone * np.exp(-time / WhineDecay)
    return sound + WhineStrikeLevel * strike(WhineStrikePitch, WhineSeconds, seed)


def finish(sound, peak):
    fade = int(SampleRate * FadeSeconds)
    sound[-fade:] = sound[-fade:] * np.linspace(1, 0, fade)
    sound = sound - sound.mean()
    return sound * (peak / np.abs(sound).max())


def save(path, sound):
    samples = np.round(sound * 32767).astype('<i2')
    with wave.open(str(path), 'wb') as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(SampleRate)
        out.writeframes(samples.tobytes())


def main():
    here = Path(__file__).resolve().parent
    sounds = Path(sys.argv[1]) if len(sys.argv) > 1 else here.parents[1] / 'bin' / 'sounds'
    for number, pitch in enumerate(PingPitches, start=1):
        save(sounds / f'armor{number}.wav', finish(strike(pitch, PingSeconds, number), PingPeak))
    save(sounds / 'ricochet.wav', finish(whine(len(PingPitches) + 1), WhinePeak))


if __name__ == '__main__':
    main()
