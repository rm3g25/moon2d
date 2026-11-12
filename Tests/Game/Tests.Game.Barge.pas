{
  Tests.Game.Barge - the hover-barge of the air phase: away till moored;
  moored it hangs a hop past the pier's end at once and rides with it, no
  farther left than its floor, and keeps its place once the pier is gone;
  the hero aboard it casts off, tells so once, glides to its station in
  the middle of the screen - from either side - and holds it; a restart
  puts it at its station at once; its way is what it went this tick; a
  clear sends it away. It holds its station till it is let go, then
  drifts: a gentle start from the station, its middle across the middle
  three fifths of the screen and its deck half a cell up and down, never
  still for long, on without him. A blow rocks its deck down and back to
  its line. Told to berth, it glides from its drift to its station and
  its line - going on a little the way it went at first, never far - and
  waits there, a blow still rocking it; neither away nor moored nor
  casting off does it berth. Docked, it is where it is told at once and
  rides with the world, its way the world's; only berthing or berthed
  does it dock, and only docked does it ride.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Game.Barge;

interface

uses
  DUnitX.TestFramework,
  Game.Barge;

type
  [TestFixture]
  TBargeRideTests = class
  private
    FBarge: TBargeRide;
    // Ticks with the pier's end at APierRight; True if he boarded on any
    function Run(ATicks: Integer; APierRight: Double; AAboard: Boolean = False;
      APierStands: Boolean = True): Boolean;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestAwayTillMoored;
    [Test]
    procedure TestMooredAHopPastThePiersEndAtOnce;
    [Test]
    procedure TestMooredItRidesWithThePiersEnd;
    [Test]
    procedure TestNeverLeftOfItsFloor;
    [Test]
    procedure TestKeepsItsPlaceOnceThePierIsGone;
    [Test]
    procedure TestBoardedItCastsOffToItsStation;
    [Test]
    procedure TestBoardedAtItsFloorItGlidesRightToTheMiddle;
    [Test]
    procedure TestTheStationIsTheMiddleOfTheScreen;
    [Test]
    procedure TestStationIsThereAtOnce;
    [Test]
    procedure TestWayIsWhatItWentThisTick;
    [Test]
    procedure TestClearSendsItAway;
    [Test]
    procedure TestItHoldsItsStationTillLetGo;
    [Test]
    procedure TestLetGoAtItsStationItDrifts;
    [Test]
    procedure TestLetGoElsewhereChangesNothing;
    [Test]
    procedure TestABlowRocksItsDeckAndDiesOut;
    [Test]
    procedure TestDriftSetsOffGentlyFromTheStation;
    [Test]
    procedure TestDriftKeepsToTheMiddleThreeFifths;
    [Test]
    procedure TestDriftIsNeverStillForLong;
    [Test]
    procedure TestDriftGoesOnWithoutHim;
    [Test]
    procedure TestWayDownIsWhatItWentThisTick;
    [Test]
    procedure TestClearEndsTheDrift;
    [Test]
    procedure TestBerthedItGlidesToItsStationAndLineAndStands;
    [Test]
    procedure TestBerthingItGoesOnTheWayItWentAtFirstNotFar;
    [Test]
    procedure TestBerthedABlowStillRocksIt;
    [Test]
    procedure TestOnlyAtItsStationOrDriftingDoesItBerth;
    [Test]
    procedure TestDockedItRidesWithTheWorld;
    [Test]
    procedure TestOnlyBerthingOrBerthedDoesItDockOnlyDockedRide;
  end;

implementation

uses
  System.Math,
  System.SysUtils,
  Render.Sprites,
  Game.Space;

const
  PierRight: Double = 352.0;
  UnitSlack = 0.001;
  // Two laps of the eight and some, at 18 s a lap
  TwoLapsTicks = 1300;
  // A share of a unit, as the edges of a drift are read
  EdgeSlack = 0.5;

procedure TBargeRideTests.Setup;
begin
  FBarge := TBargeRide.Create;
end;

procedure TBargeRideTests.TearDown;
begin
  FBarge.Free;
end;

function TBargeRideTests.Run(ATicks: Integer; APierRight: Double;
  AAboard, APierStands: Boolean): Boolean;
begin
  Result := False;
  for var i := 1 to ATicks do
    if FBarge.Tick(APierRight, APierStands, AAboard) then
      Result := True;
end;

procedure TBargeRideTests.TestAwayTillMoored;
begin
  Assert.AreEqual(Ord(bsAway), Ord(FBarge.Stage), 'Away');
  Assert.IsFalse(Run(100, PierRight, True), 'Nobody boards a barge away');
  Assert.AreEqual(Ord(bsAway), Ord(FBarge.Stage), 'Still away');
  Assert.IsTrue(FBarge.Left >= ScreenWidth, 'Beyond the right edge');
end;

procedure TBargeRideTests.TestMooredAHopPastThePiersEndAtOnce;
begin
  FBarge.Moor(PierRight);
  Assert.AreEqual(Ord(bsMoored), Ord(FBarge.Stage), 'Moored');
  Assert.AreEqual(PierRight + MoorGap, FBarge.Left, UnitSlack,
    'A hop past the pier''s end');
  Assert.AreEqual(0.0, FBarge.Way, UnitSlack, 'No glide to get there');
  FBarge.Moor(PierRight - 100);
  Assert.AreEqual(PierRight + MoorGap, FBarge.Left, UnitSlack,
    'A second mooring is nothing');
end;

procedure TBargeRideTests.TestMooredItRidesWithThePiersEnd;
begin
  FBarge.Moor(PierRight);
  for var i := 1 to 20 do
  begin
    var Right := PierRight - i;
    Run(1, Right);
    Assert.AreEqual(Right + MoorGap, FBarge.Left, UnitSlack,
      'Tick ' + i.ToString + ': with the pier''s end');
  end;
end;

procedure TBargeRideTests.TestNeverLeftOfItsFloor;
begin
  FBarge.Moor(PierRight);
  Run(1, MoorFloorX - MoorGap - 100);
  Assert.AreEqual(Double(MoorFloorX), FBarge.Left, UnitSlack,
    'Held at the floor');
  Run(10, -500);
  Assert.AreEqual(Double(MoorFloorX), FBarge.Left, UnitSlack, 'And kept there');
end;

procedure TBargeRideTests.TestKeepsItsPlaceOnceThePierIsGone;
begin
  FBarge.Moor(PierRight);
  Run(5, PierRight);
  var Left := FBarge.Left;
  Run(10, 0, False, False);
  Assert.AreEqual(Left, FBarge.Left, UnitSlack, 'Where the pier left it');
  Assert.AreEqual(0.0, FBarge.Way, UnitSlack, 'Going nowhere');
end;

procedure TBargeRideTests.TestBoardedItCastsOffToItsStation;
begin
  FBarge.Moor(PierRight);
  Run(5, PierRight);
  Assert.IsTrue(Run(1, PierRight, True), 'Told of the boarding');
  Assert.AreEqual(Ord(bsCasting), Ord(FBarge.Stage), 'Casting off');
  var LastLeft := FBarge.Left;
  for var i := 1 to CastOffTicks - 1 do
  begin
    Run(1, PierRight, True);
    Assert.IsTrue(FBarge.Left <= LastLeft + UnitSlack,
      'Tick ' + i.ToString + ': it turned back');
    LastLeft := FBarge.Left;
  end;
  Assert.IsTrue(FBarge.Left > StationLeft, 'Not at the station yet');
  Run(1, PierRight, True);
  Assert.AreEqual(Ord(bsStation), Ord(FBarge.Stage), 'At its station');
  Assert.AreEqual(Double(StationLeft), FBarge.Left, UnitSlack, 'Its left edge');
  Assert.IsFalse(Run(20, PierRight, True), 'Told once');
  Assert.AreEqual(Ord(bsStation), Ord(FBarge.Stage), 'Holding it with him aboard');
end;

procedure TBargeRideTests.TestBoardedAtItsFloorItGlidesRightToTheMiddle;
begin
  FBarge.Moor(PierRight);
  Run(1, -500);
  Assert.IsTrue(Run(1, 0, True, False), 'Boarded at the floor');
  var LastLeft := FBarge.Left;
  for var i := 1 to CastOffTicks do
  begin
    Run(1, 0, True, False);
    Assert.IsTrue(FBarge.Left >= LastLeft - UnitSlack,
      'Tick ' + i.ToString + ': it turned back');
    LastLeft := FBarge.Left;
  end;
  Assert.AreEqual(Double(StationLeft), FBarge.Left, UnitSlack, 'In the middle');
end;

procedure TBargeRideTests.TestTheStationIsTheMiddleOfTheScreen;
begin
  Assert.AreEqual(Double(ScreenWidth / 2), Double(StationLeft + BargeLength / 2),
    UnitSlack);
end;

procedure TBargeRideTests.TestStationIsThereAtOnce;
begin
  FBarge.Station;
  Assert.AreEqual(Ord(bsStation), Ord(FBarge.Stage), 'At its station');
  Assert.AreEqual(Double(StationLeft), FBarge.Left, UnitSlack, 'Its left edge');
  Assert.IsFalse(Run(100, 0, False, False), 'Nothing told');
  Assert.AreEqual(Double(StationLeft), FBarge.Left, UnitSlack, 'Holding it');
  Assert.IsFalse(Run(1, 0, True, False), 'Nothing told: he is aboard');
end;

procedure TBargeRideTests.TestWayIsWhatItWentThisTick;
begin
  FBarge.Moor(PierRight);
  Run(5, PierRight);
  Run(1, PierRight, True);
  for var i := 1 to CastOffTicks do
  begin
    var Before := FBarge.Left;
    Run(1, PierRight, True);
    Assert.AreEqual(FBarge.Left - Before, FBarge.Way, UnitSlack,
      'Tick ' + i.ToString);
    Assert.AreEqual((Before + FBarge.Left) / 2, FBarge.LeftAt(0.5), UnitSlack,
      'Tick ' + i.ToString + ': halfway between the ticks');
  end;
end;

procedure TBargeRideTests.TestClearSendsItAway;
begin
  FBarge.Moor(PierRight);
  Run(5, PierRight);
  FBarge.Clear;
  Assert.AreEqual(Ord(bsAway), Ord(FBarge.Stage), 'Away');
  Assert.IsTrue(FBarge.Left >= ScreenWidth, 'Beyond the right edge');
  FBarge.Moor(PierRight);
  Assert.AreEqual(PierRight + MoorGap, FBarge.Left, UnitSlack,
    'Moored anew after a clear');
end;

procedure TBargeRideTests.TestItHoldsItsStationTillLetGo;
begin
  FBarge.Station;
  for var i := 1 to 200 do
  begin
    // Nobody aboard for the first hundred ticks, he for the second
    Run(1, 0, i > 100, False);
    Assert.AreEqual(Ord(bsStation), Ord(FBarge.Stage), 'Tick ' + i.ToString);
    Assert.AreEqual(Double(StationLeft), FBarge.Left, UnitSlack,
      'Tick ' + i.ToString + ': its left edge');
    Assert.AreEqual(0.0, FBarge.Dip, UnitSlack, 'Tick ' + i.ToString + ': its deck');
  end;
end;

procedure TBargeRideTests.TestLetGoAtItsStationItDrifts;
begin
  FBarge.Station;
  FBarge.Loose;
  Assert.AreEqual(Ord(bsDrift), Ord(FBarge.Stage), 'Drifting');
  Run(100, 0, False, False);
  Assert.IsTrue(Abs(FBarge.Left - StationLeft) > TileSize,
    'Over a cell off its station in three seconds');
end;

procedure TBargeRideTests.TestLetGoElsewhereChangesNothing;
begin
  FBarge.Loose;
  Assert.AreEqual(Ord(bsAway), Ord(FBarge.Stage), 'Still away');
  FBarge.Moor(PierRight);
  FBarge.Loose;
  Run(10, PierRight);
  Assert.AreEqual(Ord(bsMoored), Ord(FBarge.Stage), 'Still moored');
  Assert.AreEqual(PierRight + MoorGap, FBarge.Left, UnitSlack, 'Where it hung');
end;

// Against a barge let go on the same tick and not struck: the drift is the
// same, so what is left is the rock
procedure TBargeRideTests.TestBerthedItGlidesToItsStationAndLineAndStands;
const
  BerthTicks = 165;
begin
  FBarge.Station;
  FBarge.Loose;
  Run(200, 0, False, False);
  Assert.IsTrue(Abs(FBarge.Left - StationLeft) > 10, 'Away from the station');
  FBarge.Berth(BerthTicks);
  Assert.AreEqual(Ord(bsBerthing), Ord(FBarge.Stage), 'Berthing');
  Run(BerthTicks - 1, 0, False, False);
  Assert.IsFalse(FBarge.Berthed, 'Not yet a tick short');
  Run(1, 0, False, False);
  Assert.IsTrue(FBarge.Berthed, 'Berthed');
  Assert.AreEqual(Double(StationLeft), FBarge.Left, UnitSlack, 'At its station');
  Assert.AreEqual(0.0, FBarge.Dip, UnitSlack, 'On its line');
  Run(100, 0, False, False);
  Assert.AreEqual(Double(StationLeft), FBarge.Left, UnitSlack, 'And stands there');
  Assert.AreEqual(0.0, FBarge.Way, UnitSlack, 'Still');
end;

procedure TBargeRideTests.TestBerthingItGoesOnTheWayItWentAtFirstNotFar;
const
  BerthTicks = 165;
begin
  FBarge.Station;
  FBarge.Loose;
  // A quarter lap: the middle swinging right at its fastest
  Run(DriftLapTicks div 8, 0, False, False);
  Run(1, 0, False, False);
  var Went := FBarge.Way;
  Assert.IsTrue(Went > 0.5, 'Going right');
  var From := FBarge.Left;
  FBarge.Berth(BerthTicks);
  Run(1, 0, False, False);
  Assert.IsTrue(FBarge.Way > 0, 'On to the right at first');
  var Farthest := From;
  for var i := 2 to BerthTicks do
  begin
    Run(1, 0, False, False);
    Farthest := Max(Farthest, FBarge.Left);
  end;
  Assert.IsTrue(Farthest - From <= BerthCarryX, 'Not far');
end;

procedure TBargeRideTests.TestBerthedABlowStillRocksIt;
const
  BlowDepth = 8.0;
begin
  FBarge.Station;
  FBarge.Berth(10);
  Run(10, 0, False, False);
  FBarge.Rock(BlowDepth);
  var Deepest := 0.0;
  for var i := 1 to 60 do
  begin
    Run(1, 0, False, False);
    Deepest := Max(Deepest, FBarge.Dip);
  end;
  Assert.IsTrue(Deepest > BlowDepth / 2, 'It dipped');
  Run(200, 0, False, False);
  Assert.AreEqual(0.0, FBarge.Dip, 0.5, 'Back on its line');
  Assert.AreEqual(Double(StationLeft), FBarge.Left, UnitSlack, 'Not moved across');
end;

procedure TBargeRideTests.TestOnlyAtItsStationOrDriftingDoesItBerth;
begin
  FBarge.Berth(10);
  Assert.AreEqual(Ord(bsAway), Ord(FBarge.Stage), 'Not away');
  FBarge.Moor(PierRight);
  FBarge.Berth(10);
  Assert.AreEqual(Ord(bsMoored), Ord(FBarge.Stage), 'Not moored');
  Run(1, PierRight, True);
  FBarge.Berth(10);
  Assert.AreEqual(Ord(bsCasting), Ord(FBarge.Stage), 'Not casting off');
end;

procedure TBargeRideTests.TestDockedItRidesWithTheWorld;
const
  DockLeft: Double = 150.0;
  WorldWay: Double = -1.5;
begin
  FBarge.Station;
  FBarge.Berth(10);
  Run(10, 0, False, False);
  FBarge.Dock(DockLeft);
  Assert.AreEqual(Ord(bsDocked), Ord(FBarge.Stage), 'Docked');
  Assert.AreEqual(DockLeft, FBarge.Left, UnitSlack, 'Where told, at once');
  for var i := 1 to 20 do
  begin
    Run(1, 0, False, False);
    FBarge.Ride(WorldWay);
    Assert.AreEqual(WorldWay, FBarge.Way, UnitSlack,
      'Tick ' + i.ToString + ': the world''s way');
  end;
  Assert.AreEqual(DockLeft + 20 * WorldWay, FBarge.Left, UnitSlack, 'Carried');
  Assert.AreEqual(0.0, FBarge.Dip, 0.5, 'On its line');
end;

procedure TBargeRideTests.TestOnlyBerthingOrBerthedDoesItDockOnlyDockedRide;
begin
  FBarge.Station;
  FBarge.Ride(-5);
  Assert.AreEqual(Double(StationLeft), FBarge.Left, UnitSlack,
    'At its station it rides nothing');
  FBarge.Dock(0);
  Assert.AreEqual(Ord(bsStation), Ord(FBarge.Stage), 'Not docked from its station');
  FBarge.Loose;
  Run(10, 0, False, False);
  FBarge.Dock(0);
  Assert.AreEqual(Ord(bsDrift), Ord(FBarge.Stage), 'Not docked drifting');
  FBarge.Berth(30);
  Run(5, 0, False, False);
  FBarge.Dock(100);
  Assert.AreEqual(Ord(bsDocked), Ord(FBarge.Stage), 'Docked on its way to its berth');
end;

procedure TBargeRideTests.TestABlowRocksItsDeckAndDiesOut;
const
  BlowDepth = 8.0;
  // Three seconds
  SettleTicks = 99;
begin
  var Calm := TBargeRide.Create;
  try
    FBarge.Station;
    FBarge.Loose;
    Calm.Station;
    Calm.Loose;
    Run(50, 0, False, False);
    for var i := 1 to 50 do
      Calm.Tick(0, False, False);
    FBarge.Rock(BlowDepth);
    var Deepest := 0.0;
    for var i := 1 to SettleTicks do
    begin
      Run(1, 0, False, False);
      Calm.Tick(0, False, False);
      Deepest := Max(Deepest, FBarge.Dip - Calm.Dip);
      Assert.AreEqual(Calm.Left, FBarge.Left, UnitSlack,
        'Tick ' + i.ToString + ': a blow does not move it across');
    end;
    Assert.IsTrue(Deepest > BlowDepth / 2, 'It dipped a good way');
    Assert.IsTrue(Deepest < 2 * BlowDepth, 'And no deeper than a blow gives');
    Assert.AreEqual(Calm.Dip, FBarge.Dip, 1.0, 'Back on its line');
  finally
    Calm.Free;
  end;
end;

procedure TBargeRideTests.TestDriftSetsOffGentlyFromTheStation;
begin
  FBarge.Station;
  FBarge.Loose;
  Run(1, 0, True, False);
  Assert.AreEqual(Double(StationLeft), FBarge.Left, EdgeSlack,
    'From the station itself');
  Assert.AreEqual(0.0, FBarge.Dip, EdgeSlack, 'On its line');
  var LastWay := 0.0;
  var LastWayDown := 0.0;
  for var i := 1 to 100 do
  begin
    Run(1, 0, True, False);
    Assert.IsTrue(Abs(FBarge.Way - LastWay) < 0.1,
      'Tick ' + i.ToString + ': a jerk across');
    Assert.IsTrue(Abs(FBarge.WayDown - LastWayDown) < 0.1,
      'Tick ' + i.ToString + ': a jerk up or down');
    LastWay := FBarge.Way;
    LastWayDown := FBarge.WayDown;
  end;
end;

procedure TBargeRideTests.TestDriftKeepsToTheMiddleThreeFifths;
begin
  FBarge.Station;
  FBarge.Loose;
  var Least := Double(ScreenWidth);
  var Most := 0.0;
  var Highest := 0.0;
  var Lowest := 0.0;
  for var i := 1 to TwoLapsTicks do
  begin
    Run(1, 0, True, False);
    var Middle := FBarge.Left + BargeLength / 2;
    Least := Min(Least, Middle);
    Most := Max(Most, Middle);
    Highest := Min(Highest, FBarge.Dip);
    Lowest := Max(Lowest, FBarge.Dip);
  end;
  Assert.IsTrue(Least >= 0.2 * ScreenWidth - EdgeSlack, 'Not left of a fifth');
  Assert.IsTrue(Most <= 0.8 * ScreenWidth + EdgeSlack, 'Not right of four fifths');
  Assert.IsTrue(Least < 0.25 * ScreenWidth, 'Wide to the left');
  Assert.IsTrue(Most > 0.75 * ScreenWidth, 'Wide to the right');
  Assert.IsTrue(Highest >= -TileSize / 2 - EdgeSlack, 'No higher than half a cell');
  Assert.IsTrue(Lowest <= TileSize / 2 + EdgeSlack, 'No lower than half a cell');
  Assert.IsTrue(Highest < -TileSize / 4, 'Up a good way');
  Assert.IsTrue(Lowest > TileSize / 4, 'Down a good way');
end;

procedure TBargeRideTests.TestDriftIsNeverStillForLong;
const
  StillPace = 0.2;
  // A second
  LongTicks = 33;
begin
  FBarge.Station;
  FBarge.Loose;
  Run(100, 0, True, False);
  var StillTicks := 0;
  for var i := 1 to TwoLapsTicks do
  begin
    Run(1, 0, True, False);
    if Hypot(FBarge.Way, FBarge.WayDown) < StillPace then
      Inc(StillTicks)
    else
      StillTicks := 0;
    Assert.IsTrue(StillTicks < LongTicks, 'Tick ' + i.ToString + ': still a second');
  end;
end;

procedure TBargeRideTests.TestDriftGoesOnWithoutHim;
begin
  FBarge.Station;
  FBarge.Loose;
  Run(10, 0, True, False);
  var Left := FBarge.Left;
  Run(100, 0, False, False);
  Assert.AreEqual(Ord(bsDrift), Ord(FBarge.Stage), 'Still drifting');
  Assert.IsTrue(Abs(FBarge.Left - Left) > TileSize, 'And going');
end;

procedure TBargeRideTests.TestWayDownIsWhatItWentThisTick;
begin
  FBarge.Station;
  FBarge.Loose;
  for var i := 1 to 400 do
  begin
    var Before := FBarge.Dip;
    var LeftBefore := FBarge.Left;
    Run(1, 0, True, False);
    Assert.AreEqual(FBarge.Dip - Before, FBarge.WayDown, UnitSlack,
      'Tick ' + i.ToString + ': down');
    Assert.AreEqual(FBarge.Left - LeftBefore, FBarge.Way, UnitSlack,
      'Tick ' + i.ToString + ': across');
  end;
end;

procedure TBargeRideTests.TestClearEndsTheDrift;
begin
  FBarge.Station;
  FBarge.Loose;
  Run(200, 0, True, False);
  FBarge.Clear;
  Assert.AreEqual(Ord(bsAway), Ord(FBarge.Stage), 'Away');
  Assert.AreEqual(0.0, FBarge.Dip, UnitSlack, 'On its line');
  FBarge.Station;
  Assert.AreEqual(Double(StationLeft), FBarge.Left, UnitSlack,
    'At its station anew');
  Assert.AreEqual(0.0, FBarge.Dip, UnitSlack, 'On its line anew');
end;

initialization
  TDUnitX.RegisterTestFixture(TBargeRideTests);

end.
