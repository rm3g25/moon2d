{
  Effects.Traces - what a monitor draws: the height of a trace at a moment.
  A pure function of the time and of the seed, so a frame drawn between two
  ticks never disagrees with either of them and nothing is buffered: the
  one who draws asks for the moment of every column.

  Seven shapes. A heartbeat is one beat, a short flat line and the next
  beat, as a patient's monitor draws it, every beat a little lower or
  higher than the one before. Sine, square and saw are the plain waves.
  Noise takes a new value several times a cycle. A flat line is a dead
  monitor. Bars are the columns of a level meter, each going its own way
  between targets it rolls for itself.

  A trace knows no screen, no color and no size: it answers -1..1, and
  whoever draws chooses the scale.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Effects.Traces;
{$I ..\Moon2D.inc}

interface

type
  TTraceShape = (trHeartbeat, trSine, trSquare, trSaw, trNoise, trFlat,
    trBars);

  // What a trace is made of. Frequency is in cycles a second - beats, for a
  // heartbeat - and above zero. Another seed, another beat height, noise
  // and set of bars.
  TTraceSource = record
    Shape: TTraceShape;
    Frequency: Double;
    Seed: Cardinal;
  end;

// The trace at ATime seconds, -1..1. ACell is the bar a bars trace answers
// for; the other shapes do not read it.
function TraceAt(const ASource: TTraceSource; ATime: Double;
  ACell: Integer = 0): Single;

implementation

uses
  System.Math, Render.Brush;

const
  // A beat takes this share of a cycle, the rest of it is a flat line
  BeatShare = 0.55;
  // A beat comes out up to this share lower than the full one
  BeatJitter = 0.15;
  // One beat, node by node, up is positive: the small P bump, the dip of
  // Q, the spike of R, the dip of S, the round T wave
  BeatNodes: array [0..14] of Single = (0, 0.15, 0.15, 0, 0, -0.16, 1, -0.38,
    0, 0, 0.12, 0.3, 0.3, 0.12, 0);
  NoiseSlotsPerCycle = 24;
  // Neighboring slot numbers make neighboring seeds; a few draws apart them
  NoiseWarmUp = 3;
  // A bar's own clock and its own targets are rolled from the seed with
  // these mixed in
  BarClockSalt: Cardinal = $5BD1E995;
  // Odd, and under 2^31: the product with a slot or a cell stays inside an
  // Int64, so the overflow check has nothing to catch
  SlotFactor = $2C1B3C6D;
  BarCellFactor = $3C6EF373;

// 0..1 for a numbered slot of time. It follows from the number alone, so a
// frame drawn between two ticks never disagrees with either of them. The
// slot is multiplied and added, not xored, to the seed: xorshift is linear,
// and two seeds xored with the same slots would roll the same numbers
// less a constant - a mirrored trace, not another one.
function SlotRoll(ASlot: Integer; ASeed: Cardinal): Single;
var
  Noise: TXorShift;
begin
  Noise.Seed := Cardinal((Int64(ASlot) * SlotFactor + ASeed) and $FFFFFFFF)
    or 1;
  for var i := 1 to NoiseWarmUp do
    Noise.NextUnit;
  Result := Noise.NextUnit;
end;

function HeartbeatAt(ACycle: Integer; APhase: Double; ASeed: Cardinal): Single;
begin
  if APhase >= BeatShare then
    Exit(0);

  var Position := APhase / BeatShare * High(BeatNodes);
  // A phase a hair under the share can divide out to the last node itself
  var Node: Integer := Min(Trunc(Position), High(BeatNodes) - 1);
  var Between := Position - Node;
  var Level := BeatNodes[Node] + (BeatNodes[Node + 1] - BeatNodes[Node]) * Between;
  Result := Level * (1 - BeatJitter * SlotRoll(ACycle, ASeed));
end;

function BarAt(ACell: Integer; ACycles: Double; ASeed: Cardinal): Single;
begin
  var Shifted := ACycles + SlotRoll(ACell, ASeed xor BarClockSalt);
  var Slot: Integer := Floor(Shifted);
  var Along := Shifted - Slot;
  var Eased := Along * Along * (3 - 2 * Along);

  var BarSeed: Cardinal :=
    Cardinal((Int64(ACell) * BarCellFactor + ASeed) and $FFFFFFFF);
  var Start := SlotRoll(Slot, BarSeed);
  var Target := SlotRoll(Slot + 1, BarSeed);
  Result := 2 * (Start + (Target - Start) * Eased) - 1;
end;

function TraceAt(const ASource: TTraceSource; ATime: Double;
  ACell: Integer): Single;
begin
  var Cycles := ATime * ASource.Frequency;
  var Cycle: Integer := Floor(Cycles);
  var Phase := Cycles - Cycle;
  case ASource.Shape of
    trHeartbeat:
      Result := HeartbeatAt(Cycle, Phase, ASource.Seed);
    trSine:
      Result := Sin(2 * Pi * Phase);
    trSquare:
      if Phase < 0.5 then
        Result := 1
      else
        Result := -1;
    trSaw:
      Result := 2 * Phase - 1;
    trNoise:
      Result := 2 * SlotRoll(Floor(Cycles * NoiseSlotsPerCycle),
        ASource.Seed) - 1;
    trBars:
      Result := BarAt(ACell, Cycles, ASource.Seed);
  else
    // trFlat
    Result := 0;
  end;
end;

end.
