{
  Tests.Game.Flock - the small barges of the air fight round the main
  barge: none till the flock starts; the escort first, at once, the next
  after a gap; never more than the count; a barge comes in from beyond the
  right edge fast and brakes, leaves only past the left edge and is
  replaced after a short gap; a barge within the jump of the main barge on
  every tick once the escort is in, the escort on the screen, relieved and
  let go; none up in the Ram's belly; the way is what it went; a clear
  grounds the flock; the same dice, the same flight. A barge taken out of
  the flock flies no more, is not sent again till it is given back, and is
  replaced - the escort at once, by its relief when one is on its way. A
  barge knocked off by a shell falls behind and sinks ever faster, is gone
  past the left or the bottom edge, and is out of the count at once -
  another comes in for it, the escort at once; knocking one that does not
  fly, or one knocked already, changes nothing.

  The main barge is Game.Barge's own, let go at its station and drifting
  on its loop, its deck on the road's line.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Game.Flock;

interface

uses
  DUnitX.TestFramework,
  Game.Barge,
  Game.Flock;

type
  [TestFixture]
  TBargeFlockTests = class
  private
    FRide: TBargeRide;
    FFlock: TBargeFlock;
    function MainNow: TMainBarge;
    // A tick of the main barge, then of the flock
    procedure Step;
    function AnyWithinJump: Boolean;
    // Ticks until a barge flies within the jump of the main one; fails
    // past ALimit
    function TicksTillNeighbour(ALimit: Integer): Integer;
    // Steps till a barge that is not the escort flies; its index. Fails
    // past ALimit.
    function StepTillAFreeBargeFlies(ALimit: Integer): Integer;
    // Flying on their paths: the knocked ones left out
    function OnTheirPaths: Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestNothingFliesTillStarted;
    [Test]
    procedure TestTheEscortComesFirstAtOnce;
    [Test]
    procedure TestTheNextComesAfterAGap;
    [Test]
    procedure TestNeverMoreThanTheCount;
    [Test]
    procedure TestStartedOnceTillAClear;
    [Test]
    procedure TestComesInFromBeyondTheRightEdgeFastAndBrakes;
    [Test]
    procedure TestLeavesOnlyPastTheLeftEdge;
    [Test]
    procedure TestAGoneBargeIsReplacedSoon;
    [Test]
    procedure TestAlwaysABargeWithinJumpOfTheMain;
    [Test]
    procedure TestTheEscortKeepsToTheScreen;
    [Test]
    procedure TestTheEscortIsRelievedAndLetGo;
    [Test]
    procedure TestNoneRisesIntoTheRamsBelly;
    [Test]
    procedure TestWayIsWhatItWentThisTick;
    [Test]
    procedure TestClearGroundsTheFlock;
    [Test]
    procedure TestSameDiceSameFlight;
    [Test]
    procedure TestASmallPoolFliesWhatItHas;
    [Test]
    procedure TestWithinJumpIsAJumpUpOrDownAndAcross;
    [Test]
    procedure TestATakenBargeFliesNoMore;
    [Test]
    procedure TestATakenBargeIsReplacedByAnother;
    [Test]
    procedure TestATakenEscortIsReplacedAtOnce;
    [Test]
    procedure TestTheEscortTakenItsReliefIsTheEscort;
    [Test]
    procedure TestGivenBackItFliesAgain;
    [Test]
    procedure TestTakingOneNotFlyingChangesNothing;
    [Test]
    procedure TestClearForgetsTheTaken;
    [Test]
    procedure TestAKnockedBargeFallsBehindAndSinks;
    [Test]
    procedure TestAKnockedBargeIsGoneSoon;
    [Test]
    procedure TestAKnockedBargeIsReplacedWhileItFalls;
    [Test]
    procedure TestAKnockedEscortIsReplacedAtOnce;
    [Test]
    procedure TestKnockingOneNotFlyingOrKnockedChangesNothing;
  end;

implementation

uses
  System.Math,
  System.SysUtils,
  Game.Space;

const
  // The deck of the main barge on its line: the road's
  MainLine = 352.0;
  // The pool of the level: three barges of each of the three lengths
  PoolWidths: array [0..8] of Double = (67, 104, 123, 67, 104, 123, 67, 104,
    123);
  Seed = 7;
  Count = 2;
  // Four minutes of the fight
  LongRunTicks = 8000;
  // The escort is in within this long
  EscortInTicks = 330;
  UnitSlack = 0.001;

function Pool: TArray<Double>;
begin
  Result := [];
  for var Width in PoolWidths do
    Result := Result + [Width];
end;

procedure TBargeFlockTests.Setup;
begin
  FRide := TBargeRide.Create;
  FRide.Station;
  FRide.Loose;
  FFlock := TBargeFlock.Create(Pool, Seed);
end;

procedure TBargeFlockTests.TearDown;
begin
  FFlock.Free;
  FRide.Free;
end;

function TBargeFlockTests.MainNow: TMainBarge;
begin
  Result.Left := FRide.Left;
  Result.Top := MainLine + FRide.Dip;
  Result.Width := BargeLength;
end;

procedure TBargeFlockTests.Step;
begin
  FRide.Tick(0, False, True);
  FFlock.Tick(MainNow);
end;

function TBargeFlockTests.AnyWithinJump: Boolean;
begin
  for var i := 0 to FFlock.PoolSize - 1 do
    if FFlock.Flying(i) and WithinJump(MainNow, FFlock.Left(i), FFlock.Top(i),
      FFlock.Width(i)) then
      Exit(True);
  Result := False;
end;

function TBargeFlockTests.TicksTillNeighbour(ALimit: Integer): Integer;
begin
  Result := 0;
  while not AnyWithinJump do
  begin
    Step;
    Inc(Result);
    if Result > ALimit then
      Assert.Fail(Format('No barge within the jump in %d ticks', [ALimit]));
  end;
end;

procedure TBargeFlockTests.TestNothingFliesTillStarted;
begin
  for var i := 1 to 200 do
    Step;
  Assert.IsFalse(FFlock.Started, 'Not started');
  Assert.AreEqual(0, FFlock.FlyingCount, 'None flies');
  Assert.AreEqual(-1, FFlock.Escort, 'No escort');
end;

procedure TBargeFlockTests.TestTheEscortComesFirstAtOnce;
begin
  FFlock.Start(Count);
  Assert.IsTrue(FFlock.Started, 'Started');
  Step;
  Assert.AreEqual(1, FFlock.FlyingCount, 'One at once');
  var Escort := FFlock.Escort;
  Assert.IsTrue(Escort >= 0, 'An escort');
  Assert.IsTrue(FFlock.Flying(Escort), 'The escort flies');
  Assert.AreEqual(Ord(fpEscort), Ord(FFlock.PathOf(Escort)), 'On the escort''s path');
end;

procedure TBargeFlockTests.TestTheNextComesAfterAGap;
begin
  FFlock.Start(Count);
  Step;
  var Ticks := 0;
  while FFlock.FlyingCount < 2 do
  begin
    Step;
    Inc(Ticks);
    Assert.IsTrue(Ticks <= ReplaceGapMost + 1, 'Not within two seconds');
  end;
  Assert.IsTrue(Ticks >= ReplaceGapLeast, 'Before a second: ' + Ticks.ToString);
end;

procedure TBargeFlockTests.TestNeverMoreThanTheCount;
begin
  FFlock.Start(Count);
  for var i := 1 to LongRunTicks do
  begin
    Step;
    Assert.IsTrue(FFlock.FlyingCount <= Count, 'Tick ' + i.ToString);
  end;
end;

procedure TBargeFlockTests.TestStartedOnceTillAClear;
begin
  FFlock.Start(Count);
  Step;
  FFlock.Start(4);
  for var i := 1 to 2000 do
  begin
    Step;
    Assert.IsTrue(FFlock.FlyingCount <= Count, 'Tick ' + i.ToString +
      ': the second start counts');
  end;
end;

procedure TBargeFlockTests.TestComesInFromBeyondTheRightEdgeFastAndBrakes;
const
  // A barge on its path goes no faster than this, the escort with the main
  // barge under it the fastest; five seconds in, it is on its path
  PathPaceMost = 4.5;
  OnItsPathTicks = 165;
var
  Since: TArray<Integer>;
begin
  SetLength(Since, FFlock.PoolSize);
  FFlock.Start(Count);
  var Arrivals := 0;
  for var i := 1 to LongRunTicks do
  begin
    Step;
    for var j := 0 to FFlock.PoolSize - 1 do
    begin
      if not FFlock.Flying(j) then
      begin
        Since[j] := 0;
        Continue;
      end;
      Inc(Since[j]);
      var When := Format('Tick %d, barge %d', [i, j]);
      if Since[j] = 1 then
      begin
        Inc(Arrivals);
        Assert.IsTrue(FFlock.Left(j) >= ScreenWidth, When + ': beyond the right edge');
      end;
      // Faster than the main barge ever goes, even for an escort coming in
      // against its drift
      if Since[j] = 2 then
        Assert.IsTrue(FFlock.WayX(j) < -2.5, When + ': fast in');
      if Since[j] = OnItsPathTicks then
        Assert.IsTrue(Abs(FFlock.WayX(j)) < PathPaceMost, When + ': braked');
    end;
  end;
  Assert.IsTrue(Arrivals > 6, 'Barges come and go');
end;

procedure TBargeFlockTests.TestLeavesOnlyPastTheLeftEdge;
var
  WasFlying: TArray<Boolean>;
begin
  SetLength(WasFlying, FFlock.PoolSize);
  FFlock.Start(Count);
  var Leavers := 0;
  for var i := 1 to LongRunTicks do
  begin
    Step;
    for var j := 0 to FFlock.PoolSize - 1 do
    begin
      if WasFlying[j] and not FFlock.Flying(j) then
      begin
        Inc(Leavers);
        Assert.IsTrue(FFlock.Left(j) + FFlock.Width(j) < 0,
          Format('Tick %d, barge %d: gone short of the left edge', [i, j]));
      end;
      WasFlying[j] := FFlock.Flying(j);
    end;
  end;
  Assert.IsTrue(Leavers > 4, 'Barges leave');
end;

procedure TBargeFlockTests.TestAGoneBargeIsReplacedSoon;
begin
  FFlock.Start(Count);
  while FFlock.FlyingCount < Count do
    Step;
  var ShortTicks := 0;
  for var i := 1 to LongRunTicks do
  begin
    Step;
    if FFlock.FlyingCount < Count then
      Inc(ShortTicks)
    else
      ShortTicks := 0;
    Assert.IsTrue(ShortTicks <= ReplaceGapMost + 1, 'Tick ' + i.ToString +
      ': not replaced within two seconds');
  end;
end;

procedure TBargeFlockTests.TestAlwaysABargeWithinJumpOfTheMain;
begin
  FFlock.Start(Count);
  TicksTillNeighbour(EscortInTicks);
  for var i := 1 to LongRunTicks do
  begin
    Step;
    Assert.IsTrue(AnyWithinJump, 'Tick ' + i.ToString + ': no floor within a jump');
  end;
end;

procedure TBargeFlockTests.TestTheEscortKeepsToTheScreen;
begin
  FFlock.Start(Count);
  TicksTillNeighbour(EscortInTicks);
  // Done with its way in
  for var i := 1 to EscortInTicks do
    Step;
  for var i := 1 to LongRunTicks do
  begin
    Step;
    var Escort := FFlock.Escort;
    Assert.IsTrue(FFlock.Left(Escort) >= -UnitSlack, 'Tick ' + i.ToString +
      ': past the left edge');
    Assert.IsTrue(FFlock.Left(Escort) + FFlock.Width(Escort) <=
      ScreenWidth + UnitSlack, 'Tick ' + i.ToString + ': past the right edge');
  end;
end;

procedure TBargeFlockTests.TestTheEscortIsRelievedAndLetGo;
begin
  FFlock.Start(Count);
  Step;
  var Escort := FFlock.Escort;
  var Reliefs := 0;
  for var i := 1 to LongRunTicks do
  begin
    Step;
    if FFlock.Escort = Escort then
      Continue;
    Inc(Reliefs);
    Assert.IsTrue(FFlock.Flying(Escort), 'Tick ' + i.ToString +
      ': the old escort is let go, not gone');
    Assert.AreNotEqual(Ord(fpEscort), Ord(FFlock.PathOf(Escort)),
      'Tick ' + i.ToString + ': the old escort flies free');
    Assert.IsTrue(WithinJump(MainNow, FFlock.Left(FFlock.Escort),
      FFlock.Top(FFlock.Escort), FFlock.Width(FFlock.Escort)),
      'Tick ' + i.ToString + ': the relief is in its place');
    Escort := FFlock.Escort;
  end;
  Assert.IsTrue(Reliefs >= 2, 'Relieved more than once in four minutes');
end;

procedure TBargeFlockTests.TestNoneRisesIntoTheRamsBelly;
const
  // The swell of a lane over its highest deck, loosely
  SwellSlack = 10;
begin
  FFlock.Start(Count);
  for var i := 1 to LongRunTicks do
  begin
    Step;
    for var j := 0 to FFlock.PoolSize - 1 do
      if FFlock.Flying(j) then
        Assert.IsTrue(FFlock.Top(j) >= LaneHighest - SwellSlack,
          Format('Tick %d, barge %d: at %g', [i, j, FFlock.Top(j)]));
  end;
end;

procedure TBargeFlockTests.TestWayIsWhatItWentThisTick;
var
  Lefts, Tops: TArray<Double>;
  WasFlying: TArray<Boolean>;
begin
  SetLength(Lefts, FFlock.PoolSize);
  SetLength(Tops, FFlock.PoolSize);
  SetLength(WasFlying, FFlock.PoolSize);
  FFlock.Start(Count);
  for var i := 1 to 2000 do
  begin
    Step;
    for var j := 0 to FFlock.PoolSize - 1 do
    begin
      if WasFlying[j] and FFlock.Flying(j) then
      begin
        var When := Format('Tick %d, barge %d', [i, j]);
        Assert.AreEqual(FFlock.Left(j) - Lefts[j], FFlock.WayX(j), UnitSlack,
          When + ': across');
        Assert.AreEqual(FFlock.Top(j) - Tops[j], FFlock.WayY(j), UnitSlack,
          When + ': down');
      end;
      WasFlying[j] := FFlock.Flying(j);
      Lefts[j] := FFlock.Left(j);
      Tops[j] := FFlock.Top(j);
    end;
  end;
end;

procedure TBargeFlockTests.TestClearGroundsTheFlock;
begin
  FFlock.Start(Count);
  for var i := 1 to 300 do
    Step;
  FFlock.Clear(Seed);
  Assert.IsFalse(FFlock.Started, 'Not started');
  Assert.AreEqual(0, FFlock.FlyingCount, 'None flies');
  Assert.AreEqual(-1, FFlock.Escort, 'No escort');
  for var i := 1 to 100 do
    Step;
  Assert.AreEqual(0, FFlock.FlyingCount, 'None comes in');
  FFlock.Start(Count);
  Step;
  Assert.AreEqual(1, FFlock.FlyingCount, 'Started anew');
end;

procedure TBargeFlockTests.TestSameDiceSameFlight;
begin
  var Ride := TBargeRide.Create;
  var Twin := TBargeFlock.Create(Pool, Seed);
  try
    Ride.Station;
    Ride.Loose;
    FFlock.Start(Count);
    Twin.Start(Count);
    for var i := 1 to 3000 do
    begin
      Step;
      Ride.Tick(0, False, True);
      var Main: TMainBarge;
      Main.Left := Ride.Left;
      Main.Top := MainLine + Ride.Dip;
      Main.Width := BargeLength;
      Twin.Tick(Main);
      for var j := 0 to FFlock.PoolSize - 1 do
      begin
        Assert.IsTrue(FFlock.Flying(j) = Twin.Flying(j),
          Format('Tick %d, barge %d: flies', [i, j]));
        Assert.AreEqual(FFlock.Left(j), Twin.Left(j), UnitSlack,
          Format('Tick %d, barge %d: across', [i, j]));
        Assert.AreEqual(FFlock.Top(j), Twin.Top(j), UnitSlack,
          Format('Tick %d, barge %d: its deck', [i, j]));
      end;
    end;
  finally
    Twin.Free;
    Ride.Free;
  end;
end;

procedure TBargeFlockTests.TestASmallPoolFliesWhatItHas;
begin
  FFlock.Free;
  FFlock := TBargeFlock.Create([104.0], Seed);
  FFlock.Start(Count);
  for var i := 1 to 2000 do
  begin
    Step;
    Assert.IsTrue(FFlock.FlyingCount <= 1, 'Tick ' + i.ToString);
  end;
  Assert.AreEqual(0, FFlock.Escort, 'The one barge escorts');
  Assert.IsTrue(FFlock.Flying(0), 'And flies');
  FFlock.Free;
  FFlock := TBargeFlock.Create(nil, Seed);
  FFlock.Start(Count);
  for var i := 1 to 100 do
    Step;
  Assert.AreEqual(0, FFlock.FlyingCount, 'No pool, no barge');
end;

procedure TBargeFlockTests.TestWithinJumpIsAJumpUpOrDownAndAcross;
var
  Main: TMainBarge;
begin
  Main.Left := 176;
  Main.Top := MainLine;
  Main.Width := BargeLength;
  Assert.IsTrue(WithinJump(Main, 200, MainLine - 64, 67), 'Over it, a jump up');
  Assert.IsTrue(WithinJump(Main, 200, MainLine - NeighbourRise, 67),
    'The highest it allows');
  Assert.IsFalse(WithinJump(Main, 200, MainLine - NeighbourRise - 1, 67),
    'Higher');
  Assert.IsTrue(WithinJump(Main, 200, MainLine + 64, 67), 'A drop down');
  Assert.IsTrue(WithinJump(Main, 336 + NeighbourGap, MainLine - 32, 67),
    'The farthest right');
  Assert.IsFalse(WithinJump(Main, 337 + NeighbourGap, MainLine - 32, 67),
    'Farther right');
  Assert.IsTrue(WithinJump(Main, 176 - NeighbourGap - 67, MainLine - 32, 67),
    'The farthest left');
  Assert.IsFalse(WithinJump(Main, 175 - NeighbourGap - 67, MainLine - 32, 67),
    'Farther left');
end;

function TBargeFlockTests.StepTillAFreeBargeFlies(ALimit: Integer): Integer;
begin
  for var Tick := 1 to ALimit do
  begin
    Step;
    for var i := 0 to FFlock.PoolSize - 1 do
      if FFlock.Flying(i) and (i <> FFlock.Escort) and
        (FFlock.PathOf(i) <> fpEscort) then
        Exit(i);
  end;
  Assert.Fail(Format('No free barge in %d ticks', [ALimit]));
  Result := -1;
end;

procedure TBargeFlockTests.TestATakenBargeFliesNoMore;
begin
  FFlock.Start(Count);
  var Loner := StepTillAFreeBargeFlies(EscortInTicks);
  var FlewBefore := FFlock.FlyingCount;
  FFlock.Take(Loner);
  Assert.IsFalse(FFlock.Flying(Loner), 'It flies no more');
  Assert.IsTrue(FFlock.Taken(Loner), 'It is taken');
  Assert.AreEqual(FlewBefore - 1, FFlock.FlyingCount, 'One fewer flies');
  for var i := 1 to LongRunTicks div 4 do
  begin
    Step;
    Assert.IsFalse(FFlock.Flying(Loner),
      'Tick ' + i.ToString + ': sent in while it is taken');
  end;
end;

procedure TBargeFlockTests.TestATakenBargeIsReplacedByAnother;
begin
  FFlock.Start(Count);
  var Loner := StepTillAFreeBargeFlies(EscortInTicks);
  FFlock.Take(Loner);
  for var i := 1 to ReplaceGapMost + 1 do
    Step;
  Assert.AreEqual(Count, FFlock.FlyingCount, 'Another came in for it');
end;

procedure TBargeFlockTests.TestATakenEscortIsReplacedAtOnce;
begin
  FFlock.Start(Count);
  TicksTillNeighbour(EscortInTicks);
  var Old := FFlock.Escort;
  Assert.IsTrue(Old >= 0, 'An escort flies');
  FFlock.Take(Old);
  Assert.IsFalse(FFlock.Flying(Old), 'The old escort flies no more');
  Step;
  Assert.IsTrue(FFlock.Escort >= 0, 'A new escort at once');
  Assert.AreNotEqual(Old, FFlock.Escort, 'Another barge');
  Assert.IsTrue(FFlock.Flying(FFlock.Escort), 'And it flies');
  // In its place within the jump as soon as the first one was
  TicksTillNeighbour(EscortInTicks);
end;

procedure TBargeFlockTests.TestTheEscortTakenItsReliefIsTheEscort;
begin
  FFlock.Start(Count);
  var Relief := -1;
  for var Tick := 1 to LongRunTicks do
  begin
    Step;
    for var i := 0 to FFlock.PoolSize - 1 do
      if FFlock.Flying(i) and (i <> FFlock.Escort) and
        (FFlock.PathOf(i) = fpEscort) then
        Relief := i;
    if Relief >= 0 then
      Break;
  end;
  Assert.IsTrue(Relief >= 0, 'A relief was sent');
  FFlock.Take(FFlock.Escort);
  Assert.AreEqual(Relief, FFlock.Escort, 'The relief is the escort');
  // On it flies, with no hand-over left to make
  for var i := 1 to EscortInTicks do
    Step;
  Assert.IsTrue(FFlock.Flying(Relief), 'Still flying');
  Assert.IsTrue(AnyWithinJump, 'A barge within the jump');
end;

procedure TBargeFlockTests.TestGivenBackItFliesAgain;
begin
  var Small := TBargeFlock.Create([67.0, 104.0], Seed);
  try
    Small.Start(2);
    Small.Tick(MainNow);
    var First := Small.Escort;
    Small.Take(First);
    for var i := 1 to EscortInTicks do
      Small.Tick(MainNow);
    Assert.IsFalse(Small.Flying(First), 'Not sent while taken');
    Small.GiveBack(First);
    Assert.IsFalse(Small.Taken(First), 'The pool''s again');
    var Flew := False;
    for var i := 1 to LongRunTicks do
    begin
      Small.Tick(MainNow);
      Flew := Flew or Small.Flying(First);
    end;
    Assert.IsTrue(Flew, 'It came in anew');
  finally
    Small.Free;
  end;
end;

procedure TBargeFlockTests.TestTakingOneNotFlyingChangesNothing;
begin
  FFlock.Start(Count);
  TicksTillNeighbour(EscortInTicks);
  var Idle := -1;
  for var i := 0 to FFlock.PoolSize - 1 do
    if not FFlock.Flying(i) then
      Idle := i;
  var Escort := FFlock.Escort;
  var Flew := FFlock.FlyingCount;
  FFlock.Take(Idle);
  Assert.IsFalse(FFlock.Taken(Idle), 'Not taken');
  Assert.AreEqual(Escort, FFlock.Escort, 'The escort as it was');
  Assert.AreEqual(Flew, FFlock.FlyingCount, 'As many fly');
end;

procedure TBargeFlockTests.TestClearForgetsTheTaken;
begin
  FFlock.Start(Count);
  TicksTillNeighbour(EscortInTicks);
  var Gone := FFlock.Escort;
  FFlock.Take(Gone);
  FFlock.Clear(Seed);
  Assert.IsFalse(FFlock.Taken(Gone), 'The pool''s again');
  Assert.AreEqual(0, FFlock.FlyingCount, 'None flies');
end;

function TBargeFlockTests.OnTheirPaths: Integer;
begin
  Result := 0;
  for var i := 0 to FFlock.PoolSize - 1 do
    if FFlock.Flying(i) and not FFlock.Knocked(i) then
      Inc(Result);
end;

procedure TBargeFlockTests.TestAKnockedBargeFallsBehindAndSinks;
const
  // A stone's fall and the flight's pace, at most
  SinkMost = 6.0;
  BehindMost = 4.0;
begin
  FFlock.Start(Count);
  var Loner := StepTillAFreeBargeFlies(EscortInTicks);
  FFlock.Knock(Loner);
  Assert.IsTrue(FFlock.Knocked(Loner), 'Knocked off');
  Assert.AreEqual(Ord(fpKnocked), Ord(FFlock.PathOf(Loner)), 'Off its path');
  Step;
  var LastWayX := FFlock.WayX(Loner);
  var LastWayY := FFlock.WayY(Loner);
  Assert.IsTrue(LastWayX < 0, 'Left at once');
  Assert.IsTrue(LastWayY > 0, 'Down at once');
  for var i := 1 to 20 do
  begin
    Step;
    if not FFlock.Flying(Loner) then
      Break;
    Assert.IsTrue(FFlock.WayX(Loner) <= LastWayX + UnitSlack, 'Ever farther behind');
    Assert.IsTrue(FFlock.WayY(Loner) >= LastWayY - UnitSlack, 'Ever faster down');
    Assert.IsTrue(FFlock.WayX(Loner) >= -BehindMost - UnitSlack, 'No faster than the flight');
    Assert.IsTrue(FFlock.WayY(Loner) <= SinkMost + UnitSlack, 'No faster than a stone');
    LastWayX := FFlock.WayX(Loner);
    LastWayY := FFlock.WayY(Loner);
  end;
end;

procedure TBargeFlockTests.TestAKnockedBargeIsGoneSoon;
const
  // Four seconds
  GoneTicks = 132;
begin
  FFlock.Start(Count);
  var Loner := StepTillAFreeBargeFlies(EscortInTicks);
  FFlock.Knock(Loner);
  var Ticks := 0;
  var Left: Double := 0;
  var Top: Double := 0;
  while FFlock.Flying(Loner) do
  begin
    Left := FFlock.Left(Loner);
    Top := FFlock.Top(Loner);
    Step;
    Inc(Ticks);
    if Ticks > GoneTicks then
      Assert.Fail(Format('Still falling after %d ticks', [GoneTicks]));
  end;
  var PastLeft := Left + FFlock.Width(Loner) + FFlock.WayX(Loner) < 0;
  var PastBottom := Top + FFlock.WayY(Loner) > ScreenHeight;
  Assert.IsTrue(PastLeft or PastBottom, 'Gone past the left or the bottom edge');
  Assert.IsFalse(FFlock.Knocked(Loner), 'Knocked no more once gone');
end;

procedure TBargeFlockTests.TestAKnockedBargeIsReplacedWhileItFalls;
begin
  FFlock.Start(Count);
  var Loner := StepTillAFreeBargeFlies(EscortInTicks);
  FFlock.Knock(Loner);
  Assert.AreEqual(Count - 1, OnTheirPaths, 'Out of the count at once');
  for var i := 1 to ReplaceGapMost + 1 do
    Step;
  Assert.AreEqual(Count, OnTheirPaths, 'Another came in for it');
end;

procedure TBargeFlockTests.TestAKnockedEscortIsReplacedAtOnce;
begin
  FFlock.Start(Count);
  TicksTillNeighbour(EscortInTicks);
  var Old := FFlock.Escort;
  FFlock.Knock(Old);
  Assert.AreNotEqual(Old, FFlock.Escort, 'The knocked one is no escort');
  Step;
  Assert.IsTrue(FFlock.Escort >= 0, 'A new escort at once');
  Assert.AreNotEqual(Old, FFlock.Escort, 'Another barge');
  Assert.IsFalse(FFlock.Knocked(FFlock.Escort), 'A barge on its path');
end;

procedure TBargeFlockTests.TestKnockingOneNotFlyingOrKnockedChangesNothing;
begin
  FFlock.Start(Count);
  var Loner := StepTillAFreeBargeFlies(EscortInTicks);
  var Idle := -1;
  for var i := 0 to FFlock.PoolSize - 1 do
    if not FFlock.Flying(i) then
      Idle := i;
  Assert.IsTrue(Idle >= 0, 'One of the pool idle');
  FFlock.Knock(Idle);
  Assert.IsFalse(FFlock.Flying(Idle), 'Not sent in by a knock');
  Assert.IsFalse(FFlock.Knocked(Idle), 'Not knocked');
  FFlock.Knock(Loner);
  for var i := 1 to 10 do
    Step;
  var Sinking := FFlock.WayY(Loner);
  FFlock.Knock(Loner);
  Step;
  Assert.IsTrue(FFlock.WayY(Loner) >= Sinking - UnitSlack,
    'The fall goes on, not thrown anew');
end;

initialization
  TDUnitX.RegisterTestFixture(TBargeFlockTests);

end.
