{
  Tests.Game.Barge - the hover-barge of the air phase: away till moored;
  moored it hangs a hop past the pier's end at once and rides with it, no
  farther left than its floor, and keeps its place once the pier is gone;
  the hero aboard it casts off, tells so once, glides to its station in
  the middle of the screen - from either side - and holds it; a restart
  puts it at its station at once; its way is what it went this tick; a
  clear sends it away.

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
  end;

implementation

uses
  System.SysUtils,
  Game.Space;

const
  PierRight: Double = 352.0;
  UnitSlack = 0.001;

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
  Assert.AreEqual(Double(StationLeft), FBarge.Left, UnitSlack, 'Holding it');
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
  Assert.IsFalse(Run(100, 0, True, False), 'Nothing told: he is aboard');
  Assert.AreEqual(Double(StationLeft), FBarge.Left, UnitSlack, 'Holding it');
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

initialization
  TDUnitX.RegisterTestFixture(TBargeRideTests);

end.
