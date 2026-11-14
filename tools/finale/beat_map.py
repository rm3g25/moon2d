"""Hears the end track for the cues of the titles (docs/mechanics/finale-flight.md,
"The beat map").

  python beat_map.py [track.ogg]

Prints the track's length and tempo, its downbeats' grid, where its sections
begin and how loud each plays, where its low end comes in and leaves, and the
beat nearest each cue of bin/finale.json. The cues themselves are chosen by
ear from this map and written into bin/finale.json by hand. Needs librosa and
numpy.
"""
import json
import os
import sys

import librosa
import numpy as np

Here = os.path.dirname(os.path.abspath(__file__))
Root = os.path.join(Here, '..', '..')
DefaultTrack = os.path.join(Root, 'bin', 'music', 'credits.ogg')
FinalePath = os.path.join(Root, 'bin', 'finale.json')
SampleRate = 22050
Hop = 512
BeatsABar = 4
Sections = 12
LowBandHz = 150 # the kick and the bass: where the band comes in and leaves
LowBandGapSec = 4 # two changes nearer than this are one
LowBandChanges = 8


def frames_to_seconds(AFrames):
  return librosa.frames_to_time(AFrames, sr=SampleRate, hop_length=Hop)


def hear_beats(AOnset):
  Tempo, Frames = librosa.beat.beat_track(onset_envelope=AOnset, sr=SampleRate, hop_length=Hop)
  return float(np.atleast_1d(Tempo)[0]), Frames


def low_band(ASound):
  Spectrum = np.abs(librosa.stft(ASound, n_fft=2048, hop_length=Hop))
  Bins = librosa.fft_frequencies(sr=SampleRate, n_fft=2048) < LowBandHz
  return Spectrum[Bins].sum(axis=0)


def first_downbeat(ABeatFrames, ALow):
  """The beat the bars are counted from: the phase whose beats carry the most
  low end, taken at its first beat inside the band's entry."""
  Levels = ALow[np.minimum(ABeatFrames, len(ALow) - 1)]
  Loud = Levels > Levels.max() / 2
  First = int(np.argmax(Loud))
  Phase = max(range(BeatsABar), key=lambda P: Levels[First + P::BeatsABar].mean())
  return First + Phase


def section_starts(ASound, ABeatFrames):
  Harmonic = librosa.effects.harmonic(ASound)
  Chroma = librosa.feature.chroma_cqt(y=Harmonic, sr=SampleRate, hop_length=Hop)
  Timbre = librosa.feature.mfcc(y=ASound, sr=SampleRate, hop_length=Hop, n_mfcc=13)
  Features = np.vstack([librosa.util.normalize(Chroma, axis=1), librosa.util.normalize(Timbre, axis=1)])
  ByBeat = librosa.util.sync(Features, ABeatFrames, aggregate=np.median)
  Bounds = librosa.segment.agglomerative(ByBeat, Sections)
  Times = frames_to_seconds(ABeatFrames)
  return [0.0 if Bound == 0 else float(Times[min(Bound, len(Times)) - 1]) for Bound in Bounds]


def low_band_changes(ALow, ASign):
  """Where the low end rises (ASign 1) or falls (-1) the most over a second."""
  Second = SampleRate // Hop
  Smooth = np.convolve(ALow, np.ones(Second) / Second, mode='same')
  Change = ASign * (Smooth[Second:] - Smooth[:-Second])
  Times = frames_to_seconds(np.arange(len(Change)) + Second // 2)
  Found = []
  for Frame in np.argsort(-Change):
    if all(abs(Times[Frame] - Other) > LowBandGapSec for Other in Found):
      Found.append(float(Times[Frame]))
    if len(Found) == LowBandChanges:
      break
  return sorted(Found)


def cue_times(ACues):
  for Name, Value in ACues.items():
    if isinstance(Value, (int, float)):
      yield Name, float(Value)
    elif isinstance(Value, list):
      for Index, Each in enumerate(Value):
        yield f'{Name}[{Index}]', float(Each)


def main():
  TrackPath = sys.argv[1] if len(sys.argv) > 1 else DefaultTrack
  Sound, _ = librosa.load(TrackPath, sr=SampleRate, mono=True)
  Onset = librosa.onset.onset_strength(y=Sound, sr=SampleRate, hop_length=Hop)
  Tempo, BeatFrames = hear_beats(Onset)
  Beats = frames_to_seconds(BeatFrames)
  Low = low_band(Sound)
  Downbeat = first_downbeat(BeatFrames, Low)
  Level = librosa.amplitude_to_db(librosa.feature.rms(y=Sound, frame_length=2048, hop_length=Hop)[0], ref=1.0)
  LevelTimes = frames_to_seconds(np.arange(len(Level)))

  print(f'{os.path.basename(TrackPath)}: {len(Sound) / SampleRate:.2f} s, {Tempo:.2f} bpm, '
    f'a beat {60 / Tempo:.3f} s, a bar {60 / Tempo * BeatsABar:.3f} s')
  print(f'{len(Beats)} beats, the first heard at {Beats[0]:.2f} s; '
    f'the downbeats from {Beats[Downbeat]:.2f} s')

  Starts = section_starts(Sound, BeatFrames) + [len(Sound) / SampleRate]
  print('\nsections: from, to, mean level')
  for From, To in zip(Starts, Starts[1:]):
    Inside = (LevelTimes >= From) & (LevelTimes < To)
    print(f'  {From:7.2f} {To:7.2f}  {Level[Inside].mean():6.1f} dB')

  print('\nthe low end comes in at: ' + ', '.join(f'{T:.1f}' for T in low_band_changes(Low, 1)))
  print('the low end leaves at:   ' + ', '.join(f'{T:.1f}' for T in low_band_changes(Low, -1)))

  with open(FinalePath, encoding='utf-8') as Source:
    Cues = json.load(Source)['cues']
  print('\ncues of bin/finale.json: the cue, the beat nearest it, its place in its bar')
  for Name, At in cue_times(Cues):
    Nearest = int(np.argmin(np.abs(Beats - At)))
    print(f'  {Name:12s} {At:7.2f}  beat at {Beats[Nearest]:7.2f}  {(Nearest - Downbeat) % BeatsABar + 1} of {BeatsABar}')


if __name__ == '__main__':
  main()
