"""Makes the two sounds of the Ram's honeycomb aloft into bin/sounds:
honeycombdown.wav, the honeycomb blinking out as the magnet softens, and
honeycombup.wav, the honeycomb kindling back as it hardens. 44.1 kHz,
16 bit, mono - as the armor pings.

The honeycomb is a field: a hollow tone, its fundamental and a few
overtones, each beating against a slightly detuned twin - the shimmer of
the cells.

Down, the field slides an octave down and dies, gated in step with the
blink of the cells (Game.Shield: two ticks lit, two dark, at 33 a second;
the fall takes 14 ticks) - the ear hears it stutter out as the eye sees
it.

Up, the field slides an octave up from silence, a tremor quickening in it
as the cells kindle outward (15 ticks), and locks as the last one kindles:
a short low blow as it comes whole.

Low sounds come out right in code, clicks and crackles do not: the gate
opens and shuts over a few milliseconds, never at once.

  python honeycomb.py [path/to/bin/sounds]

Needs numpy, and armor.py and orblauncher.py beside it.
"""
import sys
from pathlib import Path

import numpy as np

from armor import SampleRate, finish, save
from orblauncher import slide

TickSeconds = 1 / 33

FieldPitch = 196.0 # Hz, G3: above the jets' roar and the magnet's hum
FieldOvertones = ((1, 1.0), (2, 0.45), (3, 0.3), (4, 0.12))
TwinDetune = 1.012
TwinLevel = 0.6

DownSeconds = 0.5
DownPeak = 0.5 # under the jets' roar it plays over
DownSlide = 0.5 # of the pitch, by the end
BlinkTicks = 2 # lit, then as long dark
FallTicks = 14
GateEdge = 0.004 # seconds the gate takes to open or shut
DownDecay = 0.22

UpSeconds = 0.62
UpPeak = 0.5
UpFrom = 0.5 # of the pitch, as it starts
KindleTicks = 15
TremorFrom = 6.0 # Hz, quickening to
TremorTo = 24.0
TremorDepth = 0.4
LockAt = KindleTicks * TickSeconds
LockFrom = 150.0
LockTo = 55.0
LockSlide = 0.03
LockDecay = 0.09
LockLevel = 0.9
LockRing = 0.12 # seconds the field rings on past the lock

Drive = 1.4 # into the soft clip


def field(pitch):
    """The field's tone along a pitch curve, one value a sample."""
    sound = np.zeros(pitch.size)
    for overtone, level in FieldOvertones:
        phase = 2 * np.pi * np.cumsum(overtone * pitch) / SampleRate
        twin = 2 * np.pi * np.cumsum(overtone * pitch * TwinDetune) / SampleRate
        sound += level * (np.sin(phase) + TwinLevel * np.sin(twin))
    return sound / np.abs(sound).max()


def gate(time):
    """Open while the cells are lit: BlinkTicks on, BlinkTicks off, over
    the fall; shut after it. Soft at its edges."""
    period = 2 * BlinkTicks * TickSeconds
    into = np.mod(time, period)
    lit = np.clip(np.minimum(into, BlinkTicks * TickSeconds - into) / GateEdge, 0, 1)
    over = np.clip((FallTicks * TickSeconds - time) / GateEdge, 0, 1)
    return lit * over


def down():
    length = int(SampleRate * DownSeconds)
    time = np.arange(length) / SampleRate
    share = time / DownSeconds
    pitch = FieldPitch * DownSlide ** share
    sound = field(pitch) * gate(time) * np.exp(-time / DownDecay)
    return np.tanh(Drive * sound) / np.tanh(Drive)


def up():
    length = int(SampleRate * UpSeconds)
    time = np.arange(length) / SampleRate
    share = np.clip(time / LockAt, 0, 1)
    pitch = FieldPitch * UpFrom ** (1 - share)
    tremor_pitch = TremorFrom + (TremorTo - TremorFrom) * share
    tremor_phase = 2 * np.pi * np.cumsum(tremor_pitch) / SampleRate
    tremor = 1 - TremorDepth * share * (0.5 + 0.5 * np.sin(tremor_phase))
    swell = share * share
    ring = np.clip(1 - (time - LockAt) / LockRing, 0, 1)
    sound = field(pitch) * tremor * swell * ring
    lock = int(SampleRate * LockAt)
    after = time[lock:] - time[lock]
    sound[lock:] += LockLevel * slide(after, LockFrom, LockTo, LockSlide, LockDecay)
    return np.tanh(Drive * sound) / np.tanh(Drive)


def main():
    here = Path(__file__).resolve().parent
    sounds = Path(sys.argv[1]) if len(sys.argv) > 1 else here.parents[1] / 'bin' / 'sounds'
    save(sounds / 'honeycombdown.wav', finish(down(), DownPeak))
    save(sounds / 'honeycombup.wav', finish(up(), UpPeak))
    print(f'{sounds / "honeycombdown.wav"}: {DownSeconds} s; '
          f'{sounds / "honeycombup.wav"}: {UpSeconds} s')


if __name__ == '__main__':
    main()
