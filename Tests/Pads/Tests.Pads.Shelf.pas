{
  Tests.Pads.Shelf - the cycle of a shelf: a pad that slides out of the
  wall behind it and back in by a program of steps that goes round. It
  is a floor only while it is out all the way, warns before it starts
  in, and latches on the tick it is out again.

  The cycle keeps no state, so every test asks it about ticks, in any
  order, and reads the phase, the floor, the warning, the latch and the
  depth. How the slide looks on a drawn shelf is for the eye.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Pads.Shelf;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TShelfCycleTests = class
  public
    [Test]
    procedure TestPadThatIsNoShelfNeverLeavesTheFront;
    [Test]
    procedure TestProgramGoesRoundAndRepeats;
    [Test]
    procedure TestShelfHoldsOnlyWhileOutAllTheWay;
    [Test]
    procedure TestWarningLastsItsTicksAtTheEndOfTheStand;
    [Test]
    procedure TestLatchComesOnceWhenTheShelfIsOut;
    [Test]
    procedure TestDepthRisesEvenlyOnTheWayInAndFallsOnTheWayOut;
    [Test]
    procedure TestOffsetStartsTheProgramFurtherIn;
    [Test]
    procedure TestStepsOfAProgramRunInOrder;
    [Test]
    procedure TestProgramMayStartInTheWall;
    [Test]
    procedure TestStepAndSlideShorterThanATickTakeATick;
    [Test]
    procedure TestCycleIsAFunctionOfTheTickAlone;
    [Test]
    procedure TestTimeBeforeTheStartIsTheEndOfTheLap;
  end;

implementation

uses
  System.SysUtils,
  Levels.Pads,
  Pads.Shelf;

const
  // The world ticks 33 times a second
  TicksPerSecond = 33;
  // The base shelf: out 5 s, in 2 s, a slide of 1 s, a warning of 3 s.
  // Whole seconds: Round takes a half tick to the even one.
  BaseOutSeconds = 5;
  BaseInSeconds = 2;
  BaseSlideSeconds = 1;
  BaseWarnSeconds = 3;
  OutTicks = BaseOutSeconds * TicksPerSecond; // ticks 0 to 164
  SlideTicks = BaseSlideSeconds * TicksPerSecond;
  InTicks = BaseInSeconds * TicksPerSecond;
  WarnTicks = BaseWarnSeconds * TicksPerSecond;
  // Going in on 165 to 197, in the wall on 198 to 263, going out on 264 to
  // 296, out again from 297
  GoingInFrom = OutTicks;
  InFrom = GoingInFrom + SlideTicks;
  GoingOutFrom = InFrom + InTicks;
  LapTicks = GoingOutFrom + SlideTicks;
  DepthSlack = 1E-9;

function StepOf(AStand: TShelfStand; ASeconds: Single): TShelfStep;
begin
  Result.Stand := AStand;
  Result.Seconds := ASeconds;
end;

function ShelfOf(const ASteps: array of TShelfStep; ASlide, AWarn: Single;
  AOffset: Single = 0): TPadShelf;
begin
  Result := Default(TPadShelf);
  Result.Slides := True;
  SetLength(Result.Steps, Length(ASteps));
  for var i := 0 to High(ASteps) do
    Result.Steps[i] := ASteps[i];
  Result.SlideSeconds := ASlide;
  Result.WarnSeconds := AWarn;
  Result.OffsetSeconds := AOffset;
end;

function CycleOf(const AShelf: TPadShelf): TShelfCycle;
begin
  Result := Default(TShelfCycle);
  Result.Build(AShelf);
end;

function BaseShelf(AWarn: Single = BaseWarnSeconds;
  AOffset: Single = 0): TPadShelf;
begin
  Result := ShelfOf([StepOf(shOut, BaseOutSeconds),
    StepOf(shIn, BaseInSeconds)], BaseSlideSeconds, AWarn, AOffset);
end;

function PhaseName(APhase: TShelfPhase): string;
const
  Names: array [TShelfPhase] of string =
    ('out', 'going in', 'in the wall', 'going out');
begin
  Result := Names[APhase];
end;

procedure ExpectPhase(const ACycle: TShelfCycle; APhase: TShelfPhase;
  ATick: Integer);
begin
  var Phase := ACycle.PhaseAt(ATick);
  Assert.IsTrue(Phase = APhase, Format('Tick %d: the shelf is %s, not %s',
    [ATick, PhaseName(Phase), PhaseName(APhase)]));
end;

function IsNear(AValue, AExpected: Double): Boolean;
begin
  Result := Abs(AValue - AExpected) < DepthSlack;
end;

// The phases of a lap, run by run
procedure AddRun(var ARuns: TArray<TShelfPhase>; APhase: TShelfPhase;
  ACount: Integer);
begin
  var Start := Length(ARuns);
  SetLength(ARuns, Start + ACount);
  for var i := Start to High(ARuns) do
    ARuns[i] := APhase;
end;

// The cycle from AFirstTick on goes through ARuns tick by tick
procedure ExpectRuns(const ACycle: TShelfCycle;
  const ARuns: TArray<TShelfPhase>; AFirstTick: Integer);
begin
  for var i := 0 to High(ARuns) do
    ExpectPhase(ACycle, ARuns[i], AFirstTick + i);
end;

function BaseLap: TArray<TShelfPhase>;
begin
  Result := [];
  AddRun(Result, spOut, OutTicks);
  AddRun(Result, spGoingIn, SlideTicks);
  AddRun(Result, spIn, InTicks);
  AddRun(Result, spGoingOut, SlideTicks);
end;

procedure TShelfCycleTests.TestPadThatIsNoShelfNeverLeavesTheFront;
begin
  var Cycle := CycleOf(Default(TPadShelf));

  Assert.IsFalse(Cycle.Slides, 'A pad with no shelf word slides');
  for var i := 0 to 1000 do
  begin
    ExpectPhase(Cycle, spOut, i);
    Assert.IsTrue(Cycle.Holds(i), Format('Tick %d: an ordinary pad is ' +
      'no floor', [i]));
    Assert.IsFalse(Cycle.Warns(i), Format('Tick %d: an ordinary pad warns',
      [i]));
    Assert.IsFalse(Cycle.Latches(i), Format('Tick %d: an ordinary pad ' +
      'latches', [i]));
    Assert.IsTrue(IsNear(Cycle.Depth(i), 0) and IsNear(Cycle.Depth(i + 0.5),
      0), Format('Tick %d: an ordinary pad is %g into the wall',
      [i, Cycle.Depth(i + 0.5)]));
  end;
end;

procedure TShelfCycleTests.TestProgramGoesRoundAndRepeats;
begin
  var Cycle := CycleOf(BaseShelf);
  var Lap := BaseLap;

  Assert.IsTrue(Cycle.Slides, 'A shelf does not slide');
  ExpectRuns(Cycle, Lap, 0);
  ExpectRuns(Cycle, Lap, LapTicks);
  ExpectRuns(Cycle, Lap, 7 * LapTicks);
end;

procedure TShelfCycleTests.TestShelfHoldsOnlyWhileOutAllTheWay;
begin
  var Cycle := CycleOf(BaseShelf);
  var Held := 0;

  for var i := 0 to 2 * LapTicks - 1 do
  begin
    var IsOut := Cycle.PhaseAt(i) = spOut;
    Assert.AreEqual<Boolean>(IsOut, Cycle.Holds(i), Format('Tick %d: the ' +
      'shelf is %s and holds: %s', [i, PhaseName(Cycle.PhaseAt(i)),
      BoolToStr(Cycle.Holds(i), True)]));
    if (i >= LapTicks) and Cycle.Holds(i) then
      Inc(Held);
  end;

  Assert.AreEqual(OutTicks, Held, 'The ticks a lap the shelf holds');
  Assert.IsTrue(Cycle.Holds(GoingInFrom - 1), 'The last tick out holds');
  Assert.IsFalse(Cycle.Holds(GoingInFrom),
    'The first tick of the slide in holds');
  Assert.IsFalse(Cycle.Holds(LapTicks - 1),
    'The last tick of the slide out holds');
  Assert.IsTrue(Cycle.Holds(LapTicks), 'The first tick out again holds not');
end;

procedure TShelfCycleTests.TestWarningLastsItsTicksAtTheEndOfTheStand;
begin
  var Cycle := CycleOf(BaseShelf);
  var Warned := 0;

  for var i := 0 to LapTicks - 1 do
  begin
    var Expected := (i >= GoingInFrom - WarnTicks) and (i < GoingInFrom);
    Assert.AreEqual<Boolean>(Expected, Cycle.Warns(i),
      Format('Tick %d, %s: warns', [i, PhaseName(Cycle.PhaseAt(i))]));
    if Cycle.Warns(i) then
    begin
      Inc(Warned);
      Assert.IsTrue(Cycle.Holds(i), Format('Tick %d: warns and holds not',
        [i]));
    end;
  end;
  Assert.AreEqual(WarnTicks, Warned, 'The ticks a lap the shelf warns');

  var Silent := CycleOf(BaseShelf(0));
  for var i := 0 to 2 * LapTicks - 1 do
    Assert.IsFalse(Silent.Warns(i), Format('Tick %d: a warning of no ' +
      'seconds lights', [i]));

  // Nine seconds of warning over a stand of five
  var Long := CycleOf(BaseShelf(9));
  var LongWarned := False;
  for var i := 0 to 2 * LapTicks - 1 do
    if Long.Warns(i) then
    begin
      LongWarned := True;
      Assert.IsTrue(Long.Holds(i), Format('Tick %d: a long warning lights ' +
        'a shelf that is no floor', [i]));
    end;
  Assert.IsTrue(LongWarned, 'A warning longer than the stand never lights');
end;

procedure TShelfCycleTests.TestLatchComesOnceWhenTheShelfIsOut;
const
  // 33 + 33 + 66 + 33 + 99 + 33 + 132 + 33
  TwoOutsLap = 462;
begin
  var Cycle := CycleOf(BaseShelf);
  var Latches := 0;

  // The game raises the clock before it asks: from tick 1 on
  for var i := 1 to 3 * LapTicks do
    if Cycle.Latches(i) then
    begin
      Inc(Latches);
      Assert.IsTrue(Cycle.Holds(i), Format('Tick %d: latches and holds not',
        [i]));
      ExpectPhase(Cycle, spGoingOut, i - 1);
    end;
  Assert.AreEqual(3, Latches, 'Latches in three laps');

  var TwoOuts := CycleOf(ShelfOf([StepOf(shOut, 1), StepOf(shIn, 2),
    StepOf(shOut, 3), StepOf(shIn, 4)], 1, 0));
  var TwoOutsLatches := 0;
  for var i := 1 to TwoOutsLap do
    if TwoOuts.Latches(i) then
      Inc(TwoOutsLatches);
  Assert.AreEqual(2, TwoOutsLatches, 'Latches a lap of a program of two outs');
end;

procedure TShelfCycleTests.TestDepthRisesEvenlyOnTheWayInAndFallsOnTheWayOut;
begin
  var Cycle := CycleOf(BaseShelf);

  for var i := 0 to GoingInFrom - 1 do
    Assert.IsTrue(IsNear(Cycle.Depth(i), 0), Format('Tick %d out: the ' +
      'shelf is %g into the wall', [i, Cycle.Depth(i)]));

  Assert.IsTrue(IsNear(Cycle.Depth(GoingInFrom), 0), Format('The first ' +
    'tick of the slide in: %g into the wall', [Cycle.Depth(GoingInFrom)]));
  var FirstStep := Cycle.Depth(GoingInFrom + 1) - Cycle.Depth(GoingInFrom);
  Assert.IsTrue(FirstStep > 0, 'The slide in does not go in');
  for var i := GoingInFrom + 1 to InFrom - 1 do
  begin
    var Step := Cycle.Depth(i) - Cycle.Depth(i - 1);
    Assert.IsTrue(IsNear(Step, FirstStep), Format('Tick %d of the slide ' +
      'in: a step of %g, the first was %g', [i, Step, FirstStep]));
  end;

  for var i := InFrom to GoingOutFrom - 1 do
    Assert.IsTrue(IsNear(Cycle.Depth(i), 1), Format('Tick %d in the wall: ' +
      'the shelf is %g into it', [i, Cycle.Depth(i)]));

  Assert.IsTrue(IsNear(Cycle.Depth(GoingOutFrom), 1), Format('The first ' +
    'tick of the slide out: %g into the wall', [Cycle.Depth(GoingOutFrom)]));
  for var i := GoingOutFrom + 1 to LapTicks - 1 do
    Assert.IsTrue(Cycle.Depth(i) < Cycle.Depth(i - 1), Format('Tick %d of ' +
      'the slide out: %g, the tick before %g', [i, Cycle.Depth(i),
      Cycle.Depth(i - 1)]));
  Assert.IsTrue(Cycle.Depth(LapTicks - 1) > 0,
    'The shelf is out before the slide out is over');
  Assert.IsTrue(IsNear(Cycle.Depth(LapTicks), 0), Format('The first tick ' +
    'out again: %g into the wall', [Cycle.Depth(LapTicks)]));

  for var i := 0 to LapTicks - 1 do
  begin
    var Between := Cycle.Depth(i + 0.5);
    var Lower := Cycle.Depth(i);
    var Upper := Cycle.Depth(i + 1);
    if Lower > Upper then
    begin
      Lower := Cycle.Depth(i + 1);
      Upper := Cycle.Depth(i);
    end;
    Assert.IsTrue((Between > Lower - DepthSlack) and
      (Between < Upper + DepthSlack), Format('Half a tick after %d: %g, ' +
      'not between %g and %g', [i, Between, Lower, Upper]));
  end;
end;

procedure TShelfCycleTests.TestOffsetStartsTheProgramFurtherIn;
const
  ShiftSeconds = 2;
  ShiftTicks = ShiftSeconds * TicksPerSecond;
  // More than a lap: 429 ticks, a lap and 132
  WrapSeconds = 13;
  WrapTicks = WrapSeconds * TicksPerSecond - LapTicks;
begin
  var Plain := CycleOf(BaseShelf);
  var Shifted := CycleOf(BaseShelf(BaseWarnSeconds, ShiftSeconds));
  var Wrapped := CycleOf(BaseShelf(BaseWarnSeconds, WrapSeconds));

  for var i := 0 to 2 * LapTicks - 1 do
  begin
    ExpectPhase(Shifted, Plain.PhaseAt(i + ShiftTicks), i);
    Assert.AreEqual<Boolean>(Plain.Warns(i + ShiftTicks), Shifted.Warns(i),
      Format('Tick %d: the shifted shelf warns', [i]));
    Assert.IsTrue(IsNear(Shifted.Depth(i + 0.5),
      Plain.Depth(i + ShiftTicks + 0.5)), Format('Half a tick after %d: ' +
      'the shifted shelf is %g into the wall', [i, Shifted.Depth(i + 0.5)]));
    ExpectPhase(Wrapped, Plain.PhaseAt(i + WrapTicks), i);
  end;
end;

procedure TShelfCycleTests.TestStepsOfAProgramRunInOrder;
begin
  var Cycle := CycleOf(ShelfOf([StepOf(shOut, 1), StepOf(shIn, 2),
    StepOf(shOut, 3), StepOf(shIn, 4)], 1, 0));
  var Lap: TArray<TShelfPhase> := [];
  AddRun(Lap, spOut, 1 * TicksPerSecond);
  AddRun(Lap, spGoingIn, TicksPerSecond);
  AddRun(Lap, spIn, 2 * TicksPerSecond);
  AddRun(Lap, spGoingOut, TicksPerSecond);
  AddRun(Lap, spOut, 3 * TicksPerSecond);
  AddRun(Lap, spGoingIn, TicksPerSecond);
  AddRun(Lap, spIn, 4 * TicksPerSecond);
  AddRun(Lap, spGoingOut, TicksPerSecond);

  ExpectRuns(Cycle, Lap, 0);
  ExpectRuns(Cycle, Lap, Length(Lap));
end;

procedure TShelfCycleTests.TestProgramMayStartInTheWall;
begin
  var Cycle := CycleOf(ShelfOf([StepOf(shIn, 1), StepOf(shOut, 2)], 1, 0));

  ExpectPhase(Cycle, spIn, 0);
  Assert.IsFalse(Cycle.Holds(0), 'A shelf that starts in the wall holds');
  Assert.IsTrue(IsNear(Cycle.Depth(0), 1), Format('A shelf that starts in ' +
    'the wall is %g into it', [Cycle.Depth(0)]));
  ExpectPhase(Cycle, spGoingOut, TicksPerSecond);
  ExpectPhase(Cycle, spOut, 2 * TicksPerSecond);
  Assert.IsTrue(Cycle.Latches(2 * TicksPerSecond),
    'The first tick out does not latch');
  Assert.IsFalse(Cycle.Latches(2 * TicksPerSecond - 1),
    'The last tick of the slide out latches');
end;

procedure TShelfCycleTests.TestStepAndSlideShorterThanATickTakeATick;
begin
  var NoSlide := CycleOf(ShelfOf([StepOf(shOut, 2), StepOf(shIn, 2)], 0, 0));
  var GoingIn := 0;
  var GoingOut := 0;
  // Out 66, in 66 and a slide of a tick each way
  for var i := 0 to 4 * TicksPerSecond + 2 - 1 do
    case NoSlide.PhaseAt(i) of
      spGoingIn:
        Inc(GoingIn);
      spGoingOut:
        Inc(GoingOut);
    end;
  Assert.AreEqual(1, GoingIn, 'Ticks of a slide in of no seconds');
  Assert.AreEqual(1, GoingOut, 'Ticks of a slide out of no seconds');

  var Blink := CycleOf(ShelfOf([StepOf(shOut, 0.01), StepOf(shIn, 2)], 1, 0));
  var Held := 0;
  // Out 1, in 66 and two slides of 33
  for var i := 0 to 1 + 2 * TicksPerSecond + 2 * TicksPerSecond - 1 do
    if Blink.Holds(i) then
      Inc(Held);
  Assert.AreEqual(1, Held, 'Ticks out of a step of a hundredth of a second');
end;

procedure TShelfCycleTests.TestCycleIsAFunctionOfTheTickAlone;
const
  Ticks: array [0 .. 10] of Integer =
    (500, 3, 296, 0, 500, 165, 164, 1000, 3, 297, 298);
type
  TAnswer = record
    Phase: TShelfPhase;
    Holds: Boolean;
    Warns: Boolean;
    Latches: Boolean;
    Depth: Double;
  end;

  function AnswerAt(const ACycle: TShelfCycle; ATick: Integer): TAnswer;
  begin
    Result.Phase := ACycle.PhaseAt(ATick);
    Result.Holds := ACycle.Holds(ATick);
    Result.Warns := ACycle.Warns(ATick);
    Result.Latches := ACycle.Latches(ATick);
    Result.Depth := ACycle.Depth(ATick + 0.25);
  end;

var
  Asked: array [0 .. 10] of TAnswer;
begin
  var Cycle := CycleOf(BaseShelf);
  for var i := Low(Ticks) to High(Ticks) do
    Asked[i] := AnswerAt(Cycle, Ticks[i]);

  for var i := High(Ticks) downto Low(Ticks) do
  begin
    var Again := AnswerAt(Cycle, Ticks[i]);
    var Same := (Again.Phase = Asked[i].Phase) and
      (Again.Holds = Asked[i].Holds) and (Again.Warns = Asked[i].Warns) and
      (Again.Latches = Asked[i].Latches) and
      IsNear(Again.Depth, Asked[i].Depth);
    Assert.IsTrue(Same, Format('Tick %d asked again gives another answer',
      [Ticks[i]]));
  end;
end;

procedure TShelfCycleTests.TestTimeBeforeTheStartIsTheEndOfTheLap;
const
  Before: array [0 .. 6] of Double = (0.25, 0.5, 1, 1.75, 5, 33, 40.5);
begin
  var Cycle := CycleOf(BaseShelf);

  for var Back in Before do
  begin
    var Depth := Cycle.Depth(-Back);
    Assert.IsTrue(IsNear(Depth, Cycle.Depth(LapTicks - Back)), Format('%g ' +
      'ticks before the start: %g into the wall, at the end of the lap %g',
      [Back, Depth, Cycle.Depth(LapTicks - Back)]));
    Assert.IsTrue((Depth > -DepthSlack) and (Depth < 1 + DepthSlack),
      Format('%g ticks before the start: %g into the wall', [Back, Depth]));
  end;
  ExpectPhase(Cycle, spGoingOut, -1);
end;

initialization
  TDUnitX.RegisterTestFixture(TShelfCycleTests);

end.
