{
  Tests.Pads.Plunge - the cycle of a pad that plunges under the hero:
  it holds until trodden on, gives for its delay, falls out of the screen
  at a growing pace, lies below for the rest and climbs home unevenly to
  hold again. A pad that does not plunge never leaves its place.

  The cycle only counts, so every test runs it tick by tick and reads
  its phase, its depth, its twitch and its jets. What the twitch and
  the jets look like on a drawn pad is for the eye.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Pads.Plunge;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPlungeCycleTests = class
  public
    [Test]
    procedure TestHoldsUntilTrodden;
    [Test]
    procedure TestPadThatDoesNotPlungeNeverGives;
    [Test]
    procedure TestGivesForTheDelayThenFalls;
    [Test]
    procedure TestStandingOnDoesNotStartTheDelayOver;
    [Test]
    procedure TestNoDelayFallsOnTheNextTick;
    [Test]
    procedure TestFallSpeedsUpToTheReach;
    [Test]
    procedure TestLiesBelowForTheRestThenClimbs;
    [Test]
    procedure TestClimbsHomeUnevenlyAndHoldsAgain;
    [Test]
    procedure TestTroddenOnTheClimbItComesHomeThenGivesAgain;
    [Test]
    procedure TestFailingPadTwitchesWithinBounds;
    [Test]
    procedure TestDeadPadComesToRest;
    [Test]
    procedure TestJetsFollowThePhase;
    [Test]
    procedure TestDiceAreTheSeedsAlone;
    [Test]
    procedure TestRewindPutsItHomeHolding;
  end;

implementation

uses
  System.Generics.Collections,
  System.SysUtils,
  Levels.Pads,
  Pads.Plunge;

const
  ReachUnits = 200;
  DefaultSeed = 7;
  // Seconds and units a second of the cycle the tests share
  DefaultDelay = 1;
  DefaultRest = 1;
  DefaultRise = 66;
  // The world ticks 33 times a second
  TicksPerSecond = 33;
  // Six hundred ticks cover the whole cycle from the tread
  WholeCycle = 600;
  // No phase of any cycle here takes this long
  PhaseLimit = 1000;
  ZeroSlack = 0.0001; // units, or degrees
  PlaceSlack = 0.001; // units
  // The twitch of a failing pad stays within these
  DipLimit = 8; // units
  LeanLimit = 15; // degrees
  // A calm pad needs this long after it comes to rest
  SettleTicks = 99;

function PlungeOf(ADelay, ARest, ARise: Single): TPadPlunge;
begin
  Result := Default(TPadPlunge);
  Result.Plunges := True;
  Result.Delay := ADelay;
  Result.Rest := ARest;
  Result.Rise := ARise;
end;

function CycleOf(ADelay: Single = DefaultDelay; ARest: Single = DefaultRest;
  ARise: Single = DefaultRise; ASeed: Cardinal = DefaultSeed): TPlungeCycle;
begin
  Result := Default(TPlungeCycle);
  Result.Rewind(PlungeOf(ADelay, ARest, ARise), ReachUnits, ASeed);
end;

function IsZero(AValue: Double): Boolean;
begin
  Result := Abs(AValue) < ZeroSlack;
end;

function PhaseName(APhase: TPlungePhase): string;
const
  Names: array [TPlungePhase] of string =
    ('holding', 'giving', 'falling', 'fallen', 'climbing');
begin
  Result := Names[APhase];
end;

procedure ExpectPhase(const ACycle: TPlungeCycle; APhase: TPlungePhase;
  ATick: Integer);
begin
  Assert.IsTrue(ACycle.Phase = APhase,
    Format('Tick %d: the pad is %s, not %s',
      [ATick, PhaseName(ACycle.Phase), PhaseName(APhase)]));
end;

procedure ExpectAtHome(const ACycle: TPlungeCycle; ATick: Integer);
begin
  Assert.IsTrue(IsZero(ACycle.Below) and IsZero(ACycle.Dip) and
    IsZero(ACycle.Lean), Format('Tick %d: the pad is off its place: ' +
    'below %g, dip %g, lean %g', [ATick, ACycle.Below, ACycle.Dip,
    ACycle.Lean]));
end;

// Ticks the cycle until it is in the phase; how many ticks it took
function TicksUntil(var ACycle: TPlungeCycle; APhase: TPlungePhase): Integer;
begin
  Result := 0;
  while ACycle.Phase <> APhase do
  begin
    if Result = PhaseLimit then
      Assert.Fail(Format('The cycle is still in phase %s after %d ticks',
        [PhaseName(ACycle.Phase), Result]));
    ACycle.Tick;
    Inc(Result);
  end;
end;

procedure TPlungeCycleTests.TestHoldsUntilTrodden;
begin
  var Cycle := CycleOf;

  for var i := 1 to PhaseLimit do
  begin
    Cycle.Tick;
    ExpectPhase(Cycle, ppHolding, i);
    Assert.IsTrue(IsZero(Cycle.Below), Format('Tick %d: the pad is %g ' +
      'units below its place', [i, Cycle.Below]));
  end;
end;

procedure TPlungeCycleTests.TestPadThatDoesNotPlungeNeverGives;
begin
  var Plunge := PlungeOf(DefaultDelay, DefaultRest, DefaultRise);
  Plunge.Plunges := False;
  var Cycle := Default(TPlungeCycle);
  Cycle.Rewind(Plunge, ReachUnits, DefaultSeed);

  for var i := 1 to PhaseLimit do
  begin
    Cycle.Tread;
    Cycle.Tick;
    ExpectPhase(Cycle, ppHolding, i);
    ExpectAtHome(Cycle, i);
    Assert.IsTrue(IsZero(Cycle.Effort), Format('Tick %d: the jets of an ' +
      'ordinary pad work at %g', [i, Cycle.Effort]));
  end;
end;

procedure TPlungeCycleTests.TestGivesForTheDelayThenFalls;
begin
  var Cycle := CycleOf;

  Cycle.Tread;
  ExpectPhase(Cycle, ppGiving, 0);

  for var i := 1 to TicksPerSecond - 1 do
  begin
    Cycle.Tick;
    ExpectPhase(Cycle, ppGiving, i);
    Assert.IsTrue(IsZero(Cycle.Below), Format('Tick %d: the pad has ' +
      'fallen %g units while it gives', [i, Cycle.Below]));
  end;

  Cycle.Tick;
  Cycle.Tick;
  Assert.IsTrue(Cycle.Phase >= ppFalling,
    'The pad is still giving a second and a tick after the tread');
end;

procedure TPlungeCycleTests.TestStandingOnDoesNotStartTheDelayOver;
begin
  var Trodden := CycleOf;
  var Stood := CycleOf;
  Trodden.Tread;
  Stood.Tread;
  var TroddenLeft := -1;
  var StoodLeft := -1;

  for var i := 1 to PhaseLimit do
  begin
    Trodden.Tick;
    Stood.Tread;
    Stood.Tick;
    if (TroddenLeft < 0) and (Trodden.Phase <> ppGiving) then
      TroddenLeft := i;
    if (StoodLeft < 0) and (Stood.Phase <> ppGiving) then
      StoodLeft := i;
    if (TroddenLeft >= 0) and (StoodLeft >= 0) then
      Break;
  end;

  Assert.IsTrue(TroddenLeft > 0, 'The pad trodden once never gave way');
  Assert.AreEqual(TroddenLeft, StoodLeft,
    'The hero who stands still on the pad holds the fall back');
end;

procedure TPlungeCycleTests.TestNoDelayFallsOnTheNextTick;
begin
  var Cycle := CycleOf(0);

  Cycle.Tread;
  Cycle.Tick;

  ExpectPhase(Cycle, ppFalling, 1);
end;

procedure TPlungeCycleTests.TestFallSpeedsUpToTheReach;
begin
  var Cycle := CycleOf;
  Cycle.Tread;
  var Previous := 0.0;
  var PreviousStep := 0.0;
  var FirstStep := 0.0;
  var LargestStep := 0.0;
  var FallStart := -1;
  var FallenAt := -1;

  for var i := 1 to PhaseLimit do
  begin
    Cycle.Tick;
    var Step := Cycle.Below - Previous;
    Assert.IsTrue(Step > -PlaceSlack, Format('Tick %d: the pad went ' +
      'back up by %g units', [i, -Step]));
    Assert.IsTrue(Cycle.Below < ReachUnits + PlaceSlack,
      Format('Tick %d: the pad is %g units below, past its place under ' +
      'the screen', [i, Cycle.Below]));
    if (FirstStep = 0) and (Step > PlaceSlack) then
      FirstStep := Step;
    if Step > LargestStep then
      LargestStep := Step;
    if (FallStart < 0) and (Cycle.Phase = ppFalling) then
      FallStart := i;
    if Cycle.Phase = ppFalling then
      Assert.IsTrue(Step > PreviousStep - PlaceSlack, Format('Tick %d: ' +
        'the step of %g units is smaller than the one before, %g',
        [i, Step, PreviousStep]));
    Previous := Cycle.Below;
    PreviousStep := Step;
    if Cycle.Phase = ppFallen then
    begin
      FallenAt := i;
      Break;
    end;
  end;

  Assert.IsTrue(FallenAt > 0, 'The pad never came to rest');
  Assert.IsTrue(FirstStep > 0, 'The pad never moved');
  Assert.IsTrue(FirstStep < 1, Format('The first step is %g units: the ' +
    'pad drops off at once', [FirstStep]));
  Assert.IsTrue(LargestStep > 6, Format('The largest step is %g units: ' +
    'the pad never speeds up', [LargestStep]));
  Assert.IsTrue(Abs(Cycle.Below - ReachUnits) < PlaceSlack,
    Format('The pad rests %g units below', [Cycle.Below]));
  Assert.IsTrue(FallenAt - FallStart < 2 * TicksPerSecond,
    Format('The fall took %d ticks', [FallenAt - FallStart]));
end;

procedure TPlungeCycleTests.TestLiesBelowForTheRestThenClimbs;
begin
  var Cycle := CycleOf;
  Cycle.Tread;
  TicksUntil(Cycle, ppFallen);

  for var i := 1 to TicksPerSecond - 1 do
  begin
    Cycle.Tick;
    ExpectPhase(Cycle, ppFallen, i);
    Assert.IsTrue(Abs(Cycle.Below - ReachUnits) < PlaceSlack,
      Format('Tick %d of the rest: the pad is %g units below',
        [i, Cycle.Below]));
  end;

  Cycle.Tick;
  Cycle.Tick;
  Assert.IsTrue(Cycle.Phase >= ppClimbing,
    'The pad is still lying below a second and a tick after it came to rest');
end;

procedure TPlungeCycleTests.TestClimbsHomeUnevenlyAndHoldsAgain;
begin
  var Cycle := CycleOf;
  Cycle.Tread;
  TicksUntil(Cycle, ppClimbing);
  var Previous := Cycle.Below;
  var HomeAt := -1;
  var Steps := TList<Integer>.Create;
  try
    for var i := 1 to 400 do
    begin
      Cycle.Tick;
      var Step := Previous - Cycle.Below;
      Assert.IsTrue(Step > -PlaceSlack, Format('Tick %d of the climb: ' +
        'the pad went down by %g units', [i, -Step]));
      var Size: Integer := Round(Step * 100);
      if (Step > PlaceSlack) and not Steps.Contains(Size) then
        Steps.Add(Size);
      Previous := Cycle.Below;
      if Cycle.Phase = ppHolding then
      begin
        HomeAt := i;
        Break;
      end;
    end;

    Assert.IsTrue(HomeAt > 0, 'The pad never came home in 400 ticks');
    Assert.IsTrue(HomeAt >= 50, Format('The pad came home in %d ticks: ' +
      'the climb is a jump', [HomeAt]));
    Assert.IsTrue(IsZero(Cycle.Below), 'The pad holds again, but not at home');
    Assert.IsTrue(Steps.Count >= 5, Format('The climb goes in %d sizes of ' +
      'step: it is an even glide', [Steps.Count]));
  finally
    Steps.Free;
  end;
end;

procedure TPlungeCycleTests.TestTroddenOnTheClimbItComesHomeThenGivesAgain;
begin
  var Cycle := CycleOf;
  var HomeAt := -1;
  var Falls := 0;
  var Previous := Cycle.Phase;
  var PreviousBelow := Cycle.Below;

  for var i := 1 to 2 * WholeCycle do
  begin
    Cycle.Tread;
    Cycle.Tick;
    if (Previous = ppClimbing) and (Cycle.Phase = ppClimbing) and
      (HomeAt < 0) then
      Assert.IsTrue(Cycle.Below < PreviousBelow + PlaceSlack,
        Format('Tick %d of the first climb: the pad sank to %g units',
        [i, Cycle.Below]));
    if (Previous = ppClimbing) and (Cycle.Phase = ppHolding) and
      (HomeAt < 0) then
      HomeAt := i;
    if (HomeAt > 0) and (i = HomeAt + 1) then
      ExpectPhase(Cycle, ppGiving, i);
    if (Previous <> ppFalling) and (Cycle.Phase = ppFalling) then
      Inc(Falls);
    Previous := Cycle.Phase;
    PreviousBelow := Cycle.Below;
  end;

  Assert.IsTrue(HomeAt > 0, 'The pad never came home');
  Assert.IsTrue(Falls >= 2, Format('The pad fell %d times in two cycles',
    [Falls]));
end;

procedure TPlungeCycleTests.TestFailingPadTwitchesWithinBounds;
begin
  var Cycle := CycleOf;
  var DipMoved := False;
  var LeanMoved := False;

  for var i := 1 to 300 do
  begin
    Cycle.Tick;
    Assert.IsTrue(Abs(Cycle.Dip) <= DipLimit, Format('Tick %d: the dip is ' +
      '%g units', [i, Cycle.Dip]));
    Assert.IsTrue(Abs(Cycle.Lean) <= LeanLimit, Format('Tick %d: the lean ' +
      'is %g degrees', [i, Cycle.Lean]));
    DipMoved := DipMoved or not IsZero(Cycle.Dip);
    LeanMoved := LeanMoved or not IsZero(Cycle.Lean);
  end;

  Assert.IsTrue(DipMoved, 'The pad never dips');
  Assert.IsTrue(LeanMoved, 'The pad never leans');
end;

procedure TPlungeCycleTests.TestDeadPadComesToRest;
begin
  var Cycle := CycleOf(DefaultDelay, 10);
  Cycle.Tread;
  TicksUntil(Cycle, ppFallen);
  var Rested := 0;

  while (Cycle.Phase = ppFallen) and (Rested < PhaseLimit) do
  begin
    Cycle.Tick;
    Inc(Rested);
    if (Cycle.Phase = ppFallen) and (Rested >= SettleTicks) then
      Assert.IsTrue(IsZero(Cycle.Dip) and IsZero(Cycle.Lean),
        Format('%d ticks after it came to rest the pad still kicks: ' +
        'dip %g, lean %g', [Rested, Cycle.Dip, Cycle.Lean]));
  end;

  Assert.IsTrue(Rested > SettleTicks, 'The rest ended before the pad settled');
end;

procedure TPlungeCycleTests.TestJetsFollowThePhase;
begin
  var Holding := CycleOf;
  for var i := 1 to 300 do
  begin
    Holding.Tick;
    Assert.IsTrue((Holding.Effort >= 0) and (Holding.Effort < 1),
      Format('Tick %d of holding: the jets work at %g', [i, Holding.Effort]));
  end;

  var Cycle := CycleOf(5);
  Cycle.Tread;
  var SeenIdle := False;
  var SeenFull := False;
  var ClimbTicks := 0;
  for var i := 1 to PhaseLimit do
  begin
    Cycle.Tick;
    var Effort := Cycle.Effort;
    case Cycle.Phase of
      ppGiving:
        begin
          var IsIdle := IsZero(Effort);
          var IsFull := Abs(Effort - 1) < ZeroSlack;
          Assert.IsTrue(IsIdle or IsFull, Format('Tick %d of giving: the ' +
            'jets work at %g, not 0 or 1', [i, Effort]));
          SeenIdle := SeenIdle or IsIdle;
          SeenFull := SeenFull or IsFull;
        end;
      ppFalling, ppFallen:
        Assert.IsTrue(IsZero(Effort), Format('Tick %d of the fall: the ' +
          'jets work at %g', [i, Effort]));
      ppClimbing:
        begin
          Assert.IsTrue((Effort > 0) and (Effort <= 1), Format('Tick %d ' +
            'of the climb: the jets work at %g', [i, Effort]));
          Inc(ClimbTicks);
        end;
    end;
    if Cycle.Phase = ppHolding then
      Break;
  end;

  Assert.IsTrue(SeenIdle and SeenFull,
    'While it gives, the jets are not seen both idle and at the full');
  Assert.IsTrue(ClimbTicks > 0, 'The pad never climbed');
end;

procedure TPlungeCycleTests.TestDiceAreTheSeedsAlone;
begin
  var First := CycleOf;
  var Second := CycleOf;
  var Other := CycleOf(DefaultDelay, DefaultRest, DefaultRise, DefaultSeed + 1);
  First.Tread;
  Second.Tread;
  Other.Tread;
  var OtherDiffers := False;

  for var i := 1 to WholeCycle do
  begin
    First.Tick;
    Second.Tick;
    Other.Tick;
    var IsSame := (First.Below = Second.Below) and (First.Dip = Second.Dip) and
      (First.Lean = Second.Lean) and (First.Effort = Second.Effort);
    Assert.IsTrue(IsSame, Format('Tick %d: two pads of one seed part ways',
      [i]));
    OtherDiffers := OtherDiffers or (First.Dip <> Other.Dip);
  end;

  Assert.IsTrue(OtherDiffers, 'A pad of another seed twitches in step');
end;

procedure TPlungeCycleTests.TestRewindPutsItHomeHolding;
begin
  var Cycle := CycleOf;
  Cycle.Tread;
  for var i := 1 to PhaseLimit do
  begin
    Cycle.Tick;
    if Cycle.Below > ReachUnits / 2 then
      Break;
  end;
  ExpectPhase(Cycle, ppFalling, 0);

  Cycle.Rewind(PlungeOf(DefaultDelay, DefaultRest, DefaultRise), ReachUnits,
    DefaultSeed);

  ExpectPhase(Cycle, ppHolding, 0);
  ExpectAtHome(Cycle, 0);
end;

initialization
  TDUnitX.RegisterTestFixture(TPlungeCycleTests);

end.
