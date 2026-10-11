{
  Tests.Effects.Traces - what a monitor trace is: the height it answers
  for a moment, for every shape.

  The answers: every shape stays inside -1..1 whatever the time, the
  frequency and the seed, the same question gets the same answer, and the
  frequency only scales time. The plain waves are what their names say.
  The heartbeat beats once a cycle, rests flat before the next beat, dips
  under its baseline, and no two beats are as high as each other - nor
  are the beats of another seed. Noise holds still inside a slot and
  rolls a new value for the next. Bars differ from each other, never jump
  from one tick to the next and never stand still.

  The tuned numbers - how much of a cycle a beat takes, how fast a bar may
  move - are not spelled: the tests bound them loosely. What the trace
  looks like on a screen has no test here: none of it shows without
  drawing.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Effects.Traces;

interface

uses
  DUnitX.TestFramework, Effects.Traces;

type
  [TestFixture]
  TTraceAnswerTests = class
  public
    [Test]
    procedure TestEveryShapeStaysWithinOne;
    [Test]
    procedure TestSameQuestionGetsSameAnswer;
    [Test]
    procedure TestFrequencyOnlyScalesTime;
    [Test]
    procedure TestSineHighAtQuarterCycle;
    [Test]
    procedure TestSquareIsHighThenLow;
    [Test]
    procedure TestSawClimbsAcrossTheCycle;
    [Test]
    procedure TestFlatStaysOnTheBaseline;
  end;

  [TestFixture]
  TTraceHeartbeatTests = class
  public
    [Test]
    procedure TestHeartbeatBeatsOncePerCycle;
    [Test]
    procedure TestHeartbeatRestsBeforeTheNextBeat;
    [Test]
    procedure TestHeartbeatDipsUnderItsBaseline;
    [Test]
    procedure TestBeatsStayNearTheTop;
    [Test]
    procedure TestNoTwoBeatsAreAsHighAsEachOther;
    [Test]
    procedure TestOtherSeedMakesOtherBeats;
  end;

  [TestFixture]
  TTraceNoiseAndBarsTests = class
  public
    [Test]
    procedure TestNoiseHoldsStillInsideASlot;
    [Test]
    procedure TestNoiseRollsNewValueEverySlot;
    [Test]
    procedure TestOtherSeedMakesOtherNoiseNotItsMirror;
    [Test]
    procedure TestBarsDifferFromEachOther;
    [Test]
    procedure TestBarsNeverJumpBetweenTicks;
    [Test]
    procedure TestBarsKeepMoving;
  end;

implementation

uses
  System.SysUtils, System.Math;

const
  Slack = 0.0001;
  // Quantized rolls: two values less than this apart are the same roll
  SameRoll = 0.000001;
  SeedA: Cardinal = $1234;
  SeedB: Cardinal = $4321;
  BoundSeeds: array [0..2] of Cardinal = (1, $1234, $FFFFFFFF);
  BoundFrequencies: array [0..2] of Double = (0.5, 1, 3);
  BoundCells: array [0..1] of Integer = (0, 5);
  BarMoments: array [0..2] of Double = (0.37, 1.2, 5.5);
  BarSeeds: array [0..1] of Cardinal = ($1234, $4321);
  TicksPerSecond = 33;
  SamplesPerCycle = 400;
  Cycles = 20;
  Slots = 120;
  Cells = 8;
  BarSeconds = 10;

  // Decided in the design: when one of them changes, a red test is the
  // right answer
  NoiseSlotsPerCycle = 24;
  SpikeLevel = 0.5;
  BeatFloor = 0.7;
  DipDepth = -0.05;
  RestFrom = 0.9;
  StepCeiling = 0.1;
  SwingFloor = 1.0;

procedure ExpectNear(AExpected, AActual: Single; const AWhat: string);
begin
  Assert.IsTrue(Abs(AExpected - AActual) <= Slack,
    Format('%s is %g, not %g', [AWhat, AActual, AExpected]));
end;

function MakeSource(AShape: TTraceShape; AFrequency: Double;
  ASeed: Cardinal): TTraceSource;
begin
  Result.Shape := AShape;
  Result.Frequency := AFrequency;
  Result.Seed := ASeed;
end;

function CountDistinct(const AValues: TArray<Single>): Integer;
begin
  Result := 0;
  for var i := 0 to High(AValues) do
  begin
    var Seen := False;
    for var j := 0 to i - 1 do
      if Abs(AValues[i] - AValues[j]) < SameRoll then
      begin
        Seen := True;
        Break;
      end;
    if not Seen then
      Inc(Result);
  end;
end;

// The highest point of one cycle, found by looking
function PeakOf(const ASource: TTraceSource; ACycle: Integer): Single;
begin
  Result := -1;
  for var i := 0 to SamplesPerCycle - 1 do
    Result := Max(Result, TraceAt(ASource, ACycle + i / SamplesPerCycle));
end;

function LowOf(const ASource: TTraceSource; ACycle: Integer): Single;
begin
  Result := 1;
  for var i := 0 to SamplesPerCycle - 1 do
    Result := Min(Result, TraceAt(ASource, ACycle + i / SamplesPerCycle));
end;

function SpikesIn(const ASource: TTraceSource; ACycle: Integer): Integer;
begin
  Result := 0;
  var Before := TraceAt(ASource, ACycle);
  for var i := 1 to SamplesPerCycle - 1 do
  begin
    var Current := TraceAt(ASource, ACycle + i / SamplesPerCycle);
    if (Before < SpikeLevel) and (Current >= SpikeLevel) then
      Inc(Result);
    Before := Current;
  end;
end;

procedure ExpectWithinOne(const ASource: TTraceSource; const AWhat: string);
begin
  for var Step := -200 to 400 do
    for var Cell in BoundCells do
    begin
      var Level := TraceAt(ASource, Step / 50, Cell);
      Assert.IsTrue((Level >= -1) and (Level <= 1),
        Format('%s at %d/50 is %g', [AWhat, Step, Level]));
    end;
end;

// The biggest change of one bar between two ticks, over BarSeconds
function BiggestStep(const ASource: TTraceSource; ACell: Integer): Single;
begin
  Result := 0;
  var Before := TraceAt(ASource, 0, ACell);
  for var Tick := 1 to BarSeconds * TicksPerSecond do
  begin
    var Current := TraceAt(ASource, Tick / TicksPerSecond, ACell);
    Result := Max(Result, Abs(Current - Before));
    Before := Current;
  end;
end;

// How far one bar travels between its lowest and its highest, over BarSeconds
function SwingOf(const ASource: TTraceSource; ACell: Integer): Single;
begin
  var Highest: Single := -1;
  var Lowest: Single := 1;
  for var Tick := 0 to BarSeconds * TicksPerSecond do
  begin
    var Level := TraceAt(ASource, Tick / TicksPerSecond, ACell);
    Highest := Max(Highest, Level);
    Lowest := Min(Lowest, Level);
  end;
  Result := Highest - Lowest;
end;

function PeaksOf(const ASource: TTraceSource): TArray<Single>;
begin
  SetLength(Result, Cycles);
  for var i := 0 to Cycles - 1 do
    Result[i] := PeakOf(ASource, i);
end;

// The value of every slot of one cycle, taken in the middle of the slot
function SlotValues(const ASource: TTraceSource): TArray<Single>;
begin
  SetLength(Result, Slots);
  for var i := 0 to Slots - 1 do
    Result[i] := TraceAt(ASource, (i + 0.5) / NoiseSlotsPerCycle);
end;

// ---------------------------------------------------------------------------
// TTraceAnswerTests
// ---------------------------------------------------------------------------

// A shape that leaves -1..1 draws outside its frame
procedure TTraceAnswerTests.TestEveryShapeStaysWithinOne;
begin
  for var Shape := Low(TTraceShape) to High(TTraceShape) do
    for var Frequency in BoundFrequencies do
      for var Seed in BoundSeeds do
        ExpectWithinOne(MakeSource(Shape, Frequency, Seed),
          Format('shape %d at %g', [Ord(Shape), Frequency]));
end;

// A trace that remembers anything redraws differently between two ticks
procedure TTraceAnswerTests.TestSameQuestionGetsSameAnswer;
begin
  for var Shape := Low(TTraceShape) to High(TTraceShape) do
  begin
    var Source := MakeSource(Shape, 1.3, SeedA);
    for var Step := 0 to 100 do
      Assert.IsTrue(TraceAt(Source, Step / 7, 3) = TraceAt(Source, Step / 7, 3),
        Format('shape %d at %d/7', [Ord(Shape), Step]));
  end;
end;

// Frequency 2 is the same trace in half the time
procedure TTraceAnswerTests.TestFrequencyOnlyScalesTime;
begin
  for var Shape := Low(TTraceShape) to High(TTraceShape) do
  begin
    var Slow := MakeSource(Shape, 1, SeedA);
    var Fast := MakeSource(Shape, 2, SeedA);
    for var Step := 0 to 60 do
    begin
      var Moment := Step * 0.07;
      Assert.IsTrue(TraceAt(Slow, Moment, 2) = TraceAt(Fast, Moment / 2, 2),
        Format('shape %d at step %d', [Ord(Shape), Step]));
    end;
  end;
end;

procedure TTraceAnswerTests.TestSineHighAtQuarterCycle;
begin
  var Source := MakeSource(trSine, 1, SeedA);
  ExpectNear(0, TraceAt(Source, 0), 'start');
  ExpectNear(1, TraceAt(Source, 0.25), 'quarter');
  ExpectNear(0, TraceAt(Source, 0.5), 'half');
  ExpectNear(-1, TraceAt(Source, 0.75), 'three quarters');
end;

procedure TTraceAnswerTests.TestSquareIsHighThenLow;
begin
  var Source := MakeSource(trSquare, 1, SeedA);
  ExpectNear(1, TraceAt(Source, 0.25), 'first half');
  ExpectNear(-1, TraceAt(Source, 0.75), 'second half');
  ExpectNear(1, TraceAt(Source, 1.25), 'next cycle');
end;

procedure TTraceAnswerTests.TestSawClimbsAcrossTheCycle;
begin
  var Source := MakeSource(trSaw, 1, SeedA);
  ExpectNear(-1, TraceAt(Source, 0), 'start');
  ExpectNear(0, TraceAt(Source, 0.5), 'half');
  Assert.IsTrue(TraceAt(Source, 0.99) > 0.9, 'end of the cycle');
  ExpectNear(-1, TraceAt(Source, 1), 'back down');
end;

procedure TTraceAnswerTests.TestFlatStaysOnTheBaseline;
begin
  var Source := MakeSource(trFlat, 1, SeedA);
  for var Step := -20 to 80 do
    Assert.IsTrue(TraceAt(Source, Step / 9) = 0, Format('at %d/9', [Step]));
end;

// ---------------------------------------------------------------------------
// TTraceHeartbeatTests
// ---------------------------------------------------------------------------

// A beat that splits in two, or goes missing, is read as another patient
procedure TTraceHeartbeatTests.TestHeartbeatBeatsOncePerCycle;
begin
  var Source := MakeSource(trHeartbeat, 1, SeedA);
  for var Cycle := 0 to 9 do
    Assert.AreEqual(1, SpikesIn(Source, Cycle), Format('spikes in cycle %d', [Cycle]));
end;

// Without the rest it is a wave, not a heartbeat
procedure TTraceHeartbeatTests.TestHeartbeatRestsBeforeTheNextBeat;
begin
  var Source := MakeSource(trHeartbeat, 1, SeedA);
  for var Cycle := 0 to 9 do
    for var i := 0 to 98 do
      Assert.IsTrue(TraceAt(Source, Cycle + RestFrom + i * 0.001) = 0,
        Format('cycle %d, step %d', [Cycle, i]));
end;

procedure TTraceHeartbeatTests.TestHeartbeatDipsUnderItsBaseline;
begin
  var Source := MakeSource(trHeartbeat, 1, SeedA);
  for var Cycle := 0 to 9 do
    Assert.IsTrue(LowOf(Source, Cycle) < DipDepth,
      Format('cycle %d never dips', [Cycle]));
end;

procedure TTraceHeartbeatTests.TestBeatsStayNearTheTop;
begin
  var Source := MakeSource(trHeartbeat, 1, SeedA);
  for var Peak in PeaksOf(Source) do
  begin
    Assert.IsTrue(Peak >= BeatFloor, Format('a beat of %g is too low', [Peak]));
    Assert.IsTrue(Peak <= 1 + Slack, Format('a beat of %g is too high', [Peak]));
  end;
end;

// Beats rolled in pairs - slot 2k as slot 2k+1 - look like a stutter
procedure TTraceHeartbeatTests.TestNoTwoBeatsAreAsHighAsEachOther;
begin
  var Peaks := PeaksOf(MakeSource(trHeartbeat, 1, SeedA));
  Assert.AreEqual(Cycles, CountDistinct(Peaks), 'distinct beat heights');
  for var i := 0 to Cycles div 2 - 1 do
    Assert.IsTrue(Abs(Peaks[2 * i] - Peaks[2 * i + 1]) > SameRoll,
      Format('beats %d and %d are one', [2 * i, 2 * i + 1]));
end;

procedure TTraceHeartbeatTests.TestOtherSeedMakesOtherBeats;
begin
  var Ours := PeaksOf(MakeSource(trHeartbeat, 1, SeedA));
  var Theirs := PeaksOf(MakeSource(trHeartbeat, 1, SeedB));
  var Apart := 0;
  for var i := 0 to Cycles - 1 do
    if Abs(Ours[i] - Theirs[i]) > SameRoll then
      Inc(Apart);
  Assert.IsTrue(Apart >= Cycles - 2,
    Format('only %d of %d beats differ', [Apart, Cycles]));
end;

// ---------------------------------------------------------------------------
// TTraceNoiseAndBarsTests
// ---------------------------------------------------------------------------

// Noise that shivers inside a slot is not a stepped signal
procedure TTraceNoiseAndBarsTests.TestNoiseHoldsStillInsideASlot;
begin
  var Source := MakeSource(trNoise, 1, SeedA);
  Assert.IsTrue(TraceAt(Source, 0.01) = TraceAt(Source, 0.02),
    'two moments of the first slot');
end;

// Slots rolled in pairs make half the resolution
procedure TTraceNoiseAndBarsTests.TestNoiseRollsNewValueEverySlot;
begin
  var Distinct := CountDistinct(SlotValues(MakeSource(trNoise, 1, SeedA)));
  Assert.IsTrue(Distinct >= Slots - 5,
    Format('%d distinct values in %d slots', [Distinct, Slots]));
end;

// Two seeds that roll the same numbers less a constant draw a mirrored
// noise, not another one
procedure TTraceNoiseAndBarsTests.TestOtherSeedMakesOtherNoiseNotItsMirror;
begin
  var Ours := SlotValues(MakeSource(trNoise, 1, SeedA));
  var Theirs := SlotValues(MakeSource(trNoise, 1, SeedB));
  var Apart: Single := 0;
  var Together: Single := 0;
  for var i := 0 to Slots - 1 do
  begin
    Apart := Apart + Abs(Ours[i] - Theirs[i]);
    Together := Together + Ours[i] * Theirs[i];
  end;
  Assert.IsTrue(Apart / Slots > 0.3, 'the seeds roll alike');
  Assert.IsTrue(Abs(Together / Slots) < 0.3, 'the seeds roll in step');
end;

procedure TTraceNoiseAndBarsTests.TestBarsDifferFromEachOther;
begin
  var Source := MakeSource(trBars, 1, SeedA);
  for var Moment in BarMoments do
  begin
    var Levels: TArray<Single>;
    SetLength(Levels, Cells);
    for var Cell := 0 to Cells - 1 do
      Levels[Cell] := TraceAt(Source, Moment, Cell);
    Assert.AreEqual(Cells, CountDistinct(Levels),
      Format('distinct bars at %g', [Moment]));
  end;
end;

// A bar that jumps flickers; it must glide between the targets it rolls
procedure TTraceNoiseAndBarsTests.TestBarsNeverJumpBetweenTicks;
begin
  for var Seed in BarSeeds do
    for var Cell := 0 to Cells - 1 do
      Assert.IsTrue(BiggestStep(MakeSource(trBars, 1, Seed), Cell) < StepCeiling,
        Format('bar %d jumps', [Cell]));
end;

// A bar that stays put is a dead meter
procedure TTraceNoiseAndBarsTests.TestBarsKeepMoving;
begin
  var Source := MakeSource(trBars, 1, SeedA);
  for var Cell := 0 to Cells - 1 do
    Assert.IsTrue(SwingOf(Source, Cell) > SwingFloor,
      Format('bar %d swings only %g', [Cell, SwingOf(Source, Cell)]));
end;

initialization
  TDUnitX.RegisterTestFixture(TTraceAnswerTests);
  TDUnitX.RegisterTestFixture(TTraceHeartbeatTests);
  TDUnitX.RegisterTestFixture(TTraceNoiseAndBarsTests);

end.
