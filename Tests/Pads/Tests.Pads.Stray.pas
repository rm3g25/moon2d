{
  Tests.Pads.Stray - the cycle of a pad that strays: asleep out of sight
  until its flock is let go, then in from beyond an edge to a point of its
  zone, hanging there, on to another point or out again; now and then a
  fall after half a second of shaking. A deck only inside the room, and
  with the hero on it never out of the room. Sent away, it flies out
  quietly - no fall, no turn back, its jets at half - and stays out, but
  not while the hero stands on it.

  The cycle only counts, and its dice are its seed alone, so the tests
  run it tick by tick over a few seeds and read its phase, its place, its
  twitch and its jets. What a stall or a turn back looks like is for the
  eye.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Pads.Stray;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TStrayCycleTests = class
  public
    [Test]
    procedure TestAsleepUntilLetGo;
    [Test]
    procedure TestWaitsItsWaitThenFliesInFromBeyondAnEdge;
    [Test]
    procedure TestLetGoOnceOnly;
    [Test]
    procedure TestHangsOnlyAtPointsOfItsZone;
    [Test]
    procedure TestDeckOnlyInsideTheRoom;
    [Test]
    procedure TestHeroAboardNeverLeavesTheRoom;
    [Test]
    procedure TestEmptyPadComesAndGoes;
    [Test]
    procedure TestShakesThenFallsOutOfTheScreenAndComesBack;
    [Test]
    procedure TestTwitchStaysWithinBounds;
    [Test]
    procedure TestJetsFollowThePhase;
    [Test]
    procedure TestDiceAreTheSeedsAlone;
    [Test]
    procedure TestSentAwayFromAHangLeavesQuietlyAndStaysOut;
    [Test]
    procedure TestSentAwayWaitsForTheHeroToGetOff;
    [Test]
    procedure TestSentAwayWhileWaitingNeverComesIn;
    [Test]
    procedure TestSentAwayWhileFallingDoesNotComeBack;
    [Test]
    procedure TestAsleepPadIsNotSentAwayAndARewindForgets;
  end;

implementation

uses
  System.Math,
  System.SysUtils,
  Render.Sprites,
  Game.Space,
  Levels.Pads,
  Pads.Stray;

const
  PadWidth = 32;
  WaitLeft = -96;
  WaitTop = -64;
  // The zone of the arena: the decks hang at columns 2..13, rows 3..8
  ZoneLeft = 2;
  ZoneTop = 3;
  ZoneRight = 13;
  ZoneBottom = 8;
  // The world ticks 33 times a second
  TicksPerSecond = 33;
  // Long enough for every pad here to come, hang, leave and fall a few times
  LongRun = 6000;
  // The seeds every run over many seeds tries
  SeedCount = 12;
  // Half a second of shaking before a fall, give or take a tick
  GivingTicks = 16;
  // The twitch of a stray pad stays within these
  DipLimit = 10; // units
  LeanLimit = 20; // degrees
  PlaceSlack = 0.001;

function StrayOf(AWait: Single): TPadStray;
begin
  Result := Default(TPadStray);
  Result.Strays := True;
  Result.Flock := 'flock';
  Result.Zone.Left := ZoneLeft;
  Result.Zone.Top := ZoneTop;
  Result.Zone.Right := ZoneRight;
  Result.Zone.Bottom := ZoneBottom;
  Result.Wait := AWait;
end;

function CycleOf(AWait: Single): TStrayCycle;
begin
  Result := Default(TStrayCycle);
  Result.Rewind(StrayOf(AWait), PadWidth, WaitLeft, WaitTop);
end;

// Let go at once, with ASeed
function LaunchedCycle(ASeed: Cardinal): TStrayCycle;
begin
  Result := CycleOf(0);
  Result.Launch(ASeed);
end;

function SeedOf(AIndex: Integer): Cardinal;
begin
  Result := Cardinal(AIndex * 7919 + 13);
end;

function OutOfSight(const ACycle: TStrayCycle): Boolean;
begin
  Result := (ACycle.Left + PadWidth <= 0) or (ACycle.Left >= ScreenWidth) or
    (ACycle.Top < 0);
end;

function InsideTheRoom(const ACycle: TStrayCycle): Boolean;
begin
  var Across := (ACycle.Left >= TileSize - PlaceSlack) and
    (ACycle.Left + PadWidth <= ScreenWidth - TileSize + PlaceSlack);
  Result := Across and (ACycle.Top >= TileSize - PlaceSlack);
end;

function IsNear(AValue, AExpected: Double): Boolean;
begin
  Result := Abs(AValue - AExpected) < PlaceSlack;
end;

function OnACell(AValue: Double): Boolean;
begin
  Result := Abs(AValue - TileSize * Round(AValue / TileSize)) < PlaceSlack;
end;

procedure TStrayCycleTests.TestAsleepUntilLetGo;
begin
  var Cycle := CycleOf(0);
  for var Tick := 1 to 300 do
    Cycle.Tick(False);
  Assert.AreEqual<TStrayPhase>(spAsleep, Cycle.Phase);
  Assert.IsTrue(IsNear(Cycle.Left, WaitLeft) and IsNear(Cycle.Top, WaitTop),
    'It waits where it was put');
  Assert.IsFalse(Cycle.Deck, 'Asleep, it is no deck');
end;

procedure TStrayCycleTests.TestWaitsItsWaitThenFliesInFromBeyondAnEdge;
const
  WaitSeconds = 1;
  WaitTicks = WaitSeconds * TicksPerSecond;
begin
  for var i := 0 to SeedCount - 1 do
  begin
    var Cycle := CycleOf(WaitSeconds);
    Cycle.Launch(SeedOf(i));
    for var Tick := 1 to WaitTicks - 1 do
    begin
      Cycle.Tick(False);
      Assert.AreEqual<TStrayPhase>(spWaiting, Cycle.Phase,
        Format('Seed %d, tick %d of the wait', [i, Tick]));
    end;
    Cycle.Tick(False);
    Assert.AreEqual<TStrayPhase>(spFlying, Cycle.Phase,
      Format('Seed %d: it sets off once the wait is over', [i]));
    Assert.AreEqual<TStrayLeg>(slIn, Cycle.Leg, 'It flies in');
    Assert.IsTrue(OutOfSight(Cycle), Format('Seed %d: it sets off beyond an ' +
      'edge, from (%g, %g)', [i, Cycle.Left, Cycle.Top]));
    Assert.IsFalse(Cycle.Deck, 'Out there it is no deck');
  end;
end;

procedure TStrayCycleTests.TestLetGoOnceOnly;
const
  LateTick = 100;
begin
  var Once := LaunchedCycle(SeedOf(1));
  var Twice := LaunchedCycle(SeedOf(1));
  for var Tick := 1 to LongRun do
  begin
    if Tick = LateTick then
      Twice.Launch(SeedOf(2));
    Once.Tick(False);
    Twice.Tick(False);
    Assert.IsTrue(IsNear(Once.Left, Twice.Left) and
      IsNear(Once.Top, Twice.Top),
      Format('Tick %d: a second letting go changed its flight', [Tick]));
  end;
end;

procedure TStrayCycleTests.TestHangsOnlyAtPointsOfItsZone;
begin
  var Hangs := 0;
  for var i := 0 to SeedCount - 1 do
  begin
    var Cycle := LaunchedCycle(SeedOf(i));
    for var Tick := 1 to LongRun do
    begin
      Cycle.Tick(False);
      if Cycle.Phase <> spHanging then
        Continue;
      Inc(Hangs);
      var Col := Round(Cycle.Left / TileSize);
      var Row := Round(Cycle.Top / TileSize);
      var InZone := OnACell(Cycle.Left) and OnACell(Cycle.Top) and
        InRange(Col, ZoneLeft, ZoneRight) and InRange(Row, ZoneTop, ZoneBottom);
      Assert.IsTrue(InZone, Format('Seed %d, tick %d: it hangs at (%g, %g)',
        [i, Tick, Cycle.Left, Cycle.Top]));
    end;
  end;
  Assert.IsTrue(Hangs > 0, 'The pads hang somewhere');
end;

procedure TStrayCycleTests.TestDeckOnlyInsideTheRoom;
begin
  var Decks := 0;
  var Outs := 0;
  for var i := 0 to SeedCount - 1 do
  begin
    var Cycle := LaunchedCycle(SeedOf(i));
    for var Tick := 1 to LongRun do
    begin
      Cycle.Tick(False);
      if Cycle.Deck then
      begin
        Inc(Decks);
        Assert.IsTrue(InsideTheRoom(Cycle), Format('Seed %d, tick %d: a deck ' +
          'at (%g, %g)', [i, Tick, Cycle.Left, Cycle.Top]));
      end
      else if Cycle.Phase = spFlying then
        Inc(Outs);
    end;
  end;
  Assert.IsTrue(Decks > 0, 'It is a deck in the room');
  Assert.IsTrue(Outs > 0, 'It flies out of the room too');
end;

// The hero boards whenever he can: from then on it neither flies out nor
// turns a leg out into one, and leaves only by a fall
procedure TStrayCycleTests.TestHeroAboardNeverLeavesTheRoom;
begin
  var Rides := 0;
  for var i := 0 to SeedCount - 1 do
  begin
    var Cycle := LaunchedCycle(SeedOf(i));
    for var Tick := 1 to LongRun do
    begin
      var Aboard := Cycle.Deck;
      Cycle.Tick(Aboard);
      if not Aboard then
        Continue;
      Inc(Rides);
      var StillOn := Cycle.Phase in [spFlying, spHanging, spGiving];
      if StillOn then
        Assert.IsTrue(Cycle.Deck, Format('Seed %d, tick %d: it took him out ' +
          'to (%g, %g)', [i, Tick, Cycle.Left, Cycle.Top]));
      var FliesOut := (Cycle.Phase = spFlying) and (Cycle.Leg = slOut);
      Assert.IsFalse(FliesOut, Format('Seed %d, tick %d: it flies out with ' +
        'him', [i, Tick]));
    end;
  end;
  Assert.IsTrue(Rides > 0, 'The hero rides it');
end;

// Out, out of sight for a while, and in again
procedure TStrayCycleTests.TestEmptyPadComesAndGoes;
begin
  var Returns := 0;
  for var i := 0 to SeedCount - 1 do
  begin
    var Cycle := LaunchedCycle(SeedOf(i));
    var WasOut := False;
    for var Tick := 1 to LongRun do
    begin
      Cycle.Tick(False);
      var FliesOut := (Cycle.Phase = spFlying) and (Cycle.Leg = slOut);
      WasOut := WasOut or FliesOut;
      var FliesIn := (Cycle.Phase = spFlying) and (Cycle.Leg = slIn);
      if WasOut and FliesIn then
      begin
        Inc(Returns);
        WasOut := False;
      end;
    end;
  end;
  Assert.IsTrue(Returns > 0, 'A pad flown out comes in again');
end;

procedure TStrayCycleTests.TestShakesThenFallsOutOfTheScreenAndComesBack;
begin
  var Falls := 0;
  for var i := 0 to SeedCount - 1 do
  begin
    var Cycle := LaunchedCycle(SeedOf(i));
    var Tick := 0;
    while Tick < LongRun do
    begin
      Inc(Tick);
      Cycle.Tick(False);
      if Cycle.Phase <> spGiving then
        Continue;

      var ShakeLeft := Cycle.Left;
      var ShakeTicks := 0;
      while Cycle.Phase = spGiving do
      begin
        Inc(ShakeTicks);
        Assert.IsTrue(IsNear(Cycle.Left, ShakeLeft), 'It shakes where it hangs');
        Cycle.Tick(False);
      end;
      Assert.IsTrue(Abs(ShakeTicks - GivingTicks) <= 1, Format('Seed %d: it ' +
        'shook for %d ticks', [i, ShakeTicks]));
      Assert.AreEqual<TStrayPhase>(spFalling, Cycle.Phase, 'Then it falls');

      // The last top it fell to: the tick it is out of the screen, it is
      // already back out of sight
      var LastTop := Cycle.Top;
      while Cycle.Phase = spFalling do
      begin
        LastTop := Cycle.Top;
        Cycle.Tick(False);
        if Cycle.Phase = spFalling then
          Assert.IsTrue(Cycle.Top >= LastTop, 'It falls, never rises');
      end;
      Assert.IsTrue(LastTop > ScreenHeight, 'It falls out of the screen');
      Assert.AreEqual<TStrayPhase>(spWaiting, Cycle.Phase,
        'Then it waits out of sight to come in again');
      Inc(Falls);
    end;
  end;
  Assert.IsTrue(Falls > 0, 'The pads fall now and then');
end;

procedure TStrayCycleTests.TestTwitchStaysWithinBounds;
begin
  var Twitched := False;
  for var i := 0 to SeedCount - 1 do
  begin
    var Cycle := LaunchedCycle(SeedOf(i));
    for var Tick := 1 to LongRun do
    begin
      Cycle.Tick(False);
      Assert.IsTrue(Abs(Cycle.Dip) < DipLimit, Format('Seed %d, tick %d: a ' +
        'dip of %g', [i, Tick, Cycle.Dip]));
      Assert.IsTrue(Abs(Cycle.Lean) < LeanLimit, Format('Seed %d, tick %d: a ' +
        'lean of %g', [i, Tick, Cycle.Lean]));
      Twitched := Twitched or (Abs(Cycle.Lean) > 1);
    end;
  end;
  Assert.IsTrue(Twitched, 'The pads twitch now and then');
end;

// Out of sight the jets are cold; on a leg flat out or cut; at a hang idle
// or in fits; shaking, flat out or choking
procedure TStrayCycleTests.TestJetsFollowThePhase;
begin
  var Cycle := CycleOf(1);
  Assert.IsTrue(IsNear(Cycle.Effort, 0), 'Asleep');
  Cycle.Launch(SeedOf(3));
  Cycle.Tick(False);
  Assert.IsTrue(IsNear(Cycle.Effort, 0), 'Waiting');

  for var Tick := 1 to LongRun do
  begin
    Cycle.Tick(False);
    var Effort := Cycle.Effort;
    var Allowed := (Effort >= 0) and (Effort <= 1);
    case Cycle.Phase of
      spFlying, spGiving:
        Allowed := IsNear(Effort, 0) or IsNear(Effort, 1);
      spWaiting, spFalling:
        Allowed := IsNear(Effort, 0);
    end;
    Assert.IsTrue(Allowed, Format('Tick %d: the jets at %g', [Tick, Effort]));
  end;
end;

procedure TStrayCycleTests.TestDiceAreTheSeedsAlone;
begin
  var First := LaunchedCycle(SeedOf(4));
  var Again := LaunchedCycle(SeedOf(4));
  var Other := LaunchedCycle(SeedOf(5));
  var Differs := False;
  for var Tick := 1 to LongRun do
  begin
    First.Tick(False);
    Again.Tick(False);
    Other.Tick(False);
    Assert.IsTrue(IsNear(First.Left, Again.Left) and
      IsNear(First.Top, Again.Top),
      Format('Tick %d: one seed, two flights', [Tick]));
    Differs := Differs or not IsNear(First.Left, Other.Left);
  end;
  Assert.IsTrue(Differs, 'Two seeds, one flight');
end;

// Ticked empty until it stands in APhase; False when it never does
function TickUntil(var ACycle: TStrayCycle; APhase: TStrayPhase): Boolean;
begin
  for var Tick := 1 to LongRun do
  begin
    if ACycle.Phase = APhase then
      Exit(True);
    ACycle.Tick(False);
  end;
  Result := ACycle.Phase = APhase;
end;

// Ticked empty for ATicks: whether it ever fell, turned back or worked its
// jets past half, and whether it ends asleep out of sight
procedure RunSentAway(var ACycle: TStrayCycle; ASeed: Integer);
begin
  for var Tick := 1 to LongRun do
  begin
    ACycle.Tick(False);
    Assert.IsFalse(ACycle.Phase in [spGiving, spFalling], Format('Seed %d, ' +
      'tick %d: a pad sent away fell', [ASeed, Tick]));
    Assert.IsFalse((ACycle.Phase = spFlying) and (ACycle.Leg = slBack),
      Format('Seed %d, tick %d: a pad sent away turned back', [ASeed, Tick]));
    Assert.IsTrue(ACycle.Effort <= 0.5, Format('Seed %d, tick %d: jets at %g',
      [ASeed, Tick, ACycle.Effort]));
  end;
  Assert.AreEqual<TStrayPhase>(spAsleep, ACycle.Phase,
    Format('Seed %d: it did not leave', [ASeed]));
  Assert.IsTrue(OutOfSight(ACycle), Format('Seed %d: asleep in sight', [ASeed]));
end;

procedure TStrayCycleTests.TestSentAwayFromAHangLeavesQuietlyAndStaysOut;
begin
  for var i := 0 to SeedCount - 1 do
  begin
    var Cycle := LaunchedCycle(SeedOf(i));
    Assert.IsTrue(TickUntil(Cycle, spHanging), 'It never hung');
    Cycle.Dismiss;
    Assert.IsTrue(Cycle.Dismissed, 'It was not sent away');

    Cycle.Tick(False);
    Assert.AreEqual<TStrayPhase>(spFlying, Cycle.Phase, 'It leaves the hang at once');
    Assert.AreEqual<TStrayLeg>(slOut, Cycle.Leg, 'out');
    RunSentAway(Cycle, i);
  end;
end;

procedure TStrayCycleTests.TestSentAwayWaitsForTheHeroToGetOff;
const
  RideTicks = 500;
begin
  for var i := 0 to SeedCount - 1 do
  begin
    var Cycle := LaunchedCycle(SeedOf(i));
    Assert.IsTrue(TickUntil(Cycle, spHanging), 'It never hung');
    Cycle.Dismiss;

    for var Tick := 1 to RideTicks do
    begin
      Cycle.Tick(True);
      Assert.AreEqual<TStrayPhase>(spHanging, Cycle.Phase,
        Format('Seed %d, tick %d: it left with the hero aboard', [i, Tick]));
      Assert.IsTrue(Cycle.Deck, 'and stays a deck');
    end;
    RunSentAway(Cycle, i);
  end;
end;

procedure TStrayCycleTests.TestSentAwayWhileWaitingNeverComesIn;
begin
  var Cycle := CycleOf(1);
  Cycle.Launch(SeedOf(0));
  Cycle.Dismiss;

  Assert.AreEqual<TStrayPhase>(spAsleep, Cycle.Phase, 'Asleep at once');
  for var Tick := 1 to LongRun do
    Cycle.Tick(False);
  Assert.AreEqual<TStrayPhase>(spAsleep, Cycle.Phase, 'It came in');
  Cycle.Launch(SeedOf(1));
  Assert.AreEqual<TStrayPhase>(spAsleep, Cycle.Phase,
    'A pad sent away was let go again');
end;

// The fall runs out; out of sight the pad does not come in again
procedure TStrayCycleTests.TestSentAwayWhileFallingDoesNotComeBack;
begin
  var Falls := 0;
  for var i := 0 to SeedCount - 1 do
  begin
    var Cycle := LaunchedCycle(SeedOf(i));
    if not TickUntil(Cycle, spGiving) then
      Continue;
    Inc(Falls);
    Cycle.Dismiss;
    for var Tick := 1 to LongRun do
      Cycle.Tick(False);
    Assert.AreEqual<TStrayPhase>(spAsleep, Cycle.Phase,
      Format('Seed %d: it came back after its fall', [i]));
  end;
  Assert.IsTrue(Falls > 0, 'No pad fell');
end;

procedure TStrayCycleTests.TestAsleepPadIsNotSentAwayAndARewindForgets;
begin
  var Cycle := CycleOf(0);
  Cycle.Dismiss;
  Assert.IsFalse(Cycle.Dismissed, 'A pad asleep was sent away');
  Cycle.Launch(SeedOf(0));
  Cycle.Tick(False);
  Assert.AreEqual<TStrayPhase>(spFlying, Cycle.Phase, 'It is let go as ever');

  Cycle.Dismiss;
  Cycle.Rewind(StrayOf(0), PadWidth, WaitLeft, WaitTop);
  Assert.IsFalse(Cycle.Dismissed, 'The rewind kept the dismissal');
  Cycle.Launch(SeedOf(0));
  Cycle.Tick(False);
  Assert.AreEqual<TStrayPhase>(spFlying, Cycle.Phase, 'Let go after a rewind');
end;

initialization
  TDUnitX.RegisterTestFixture(TStrayCycleTests);

end.
