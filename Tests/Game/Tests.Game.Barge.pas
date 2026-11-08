{
  Tests.Game.Barge - the hover-barge of the air phase: away till told to
  come; it glides in to its mooring a hop past the pier's end and tells
  so once; moored it rides with the pier's end, no farther left than its
  floor, and keeps its place once the pier is gone; the hero aboard it
  casts off, tells so, glides to its station and holds it; the pier is
  told to fall when the grace is over, or soon after he boards, and only
  once; a restart puts it at its station at once; its way is what it went
  this tick; a clear sends it away.

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
    // Ticks with the pier's end at APierRight, the hero not aboard; the
    // cues summed up
    function Run(ATicks: Integer; APierRight: Double; AAboard: Boolean = False;
      APierStands: Boolean = True): TBargeCue;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestAwayTillToldToCome;
    [Test]
    procedure TestComesToTheMooringAndTellsSoOnce;
    [Test]
    procedure TestMooredItRidesWithThePiersEnd;
    [Test]
    procedure TestNeverLeftOfItsFloor;
    [Test]
    procedure TestKeepsItsPlaceOnceThePierIsGone;
    [Test]
    procedure TestBoardedItCastsOffToItsStation;
    [Test]
    procedure TestBoardedWhileComingItCastsOffToo;
    [Test]
    procedure TestThePierFallsWhenTheGraceIsOver;
    [Test]
    procedure TestThePierFallsSoonAfterHeBoards;
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
  AAboard, APierStands: Boolean): TBargeCue;
begin
  Result := Default(TBargeCue);
  for var i := 1 to ATicks do
  begin
    var Cue := FBarge.Tick(APierRight, APierStands, AAboard);
    Result.Moored := Result.Moored or Cue.Moored;
    Result.Boarded := Result.Boarded or Cue.Boarded;
    Result.PierFalls := Result.PierFalls or Cue.PierFalls;
  end;
end;

procedure TBargeRideTests.TestAwayTillToldToCome;
begin
  Assert.AreEqual(Ord(bsAway), Ord(FBarge.Stage), 'Away');
  var Cue := Run(ComeTicks * 2, PierRight);
  Assert.IsFalse(Cue.Moored or Cue.Boarded or Cue.PierFalls, 'Nothing told');
  Assert.AreEqual(Ord(bsAway), Ord(FBarge.Stage), 'Still away');
  Assert.IsTrue(FBarge.Left >= ScreenWidth, 'Beyond the right edge');
end;

procedure TBargeRideTests.TestComesToTheMooringAndTellsSoOnce;
begin
  FBarge.Come;
  Assert.AreEqual(Ord(bsComing), Ord(FBarge.Stage), 'Coming');
  var Cue := Run(ComeTicks - 1, PierRight);
  Assert.IsFalse(Cue.Moored, 'Not moored before its time');
  Assert.IsTrue(FBarge.Left > PierRight + MoorGap, 'Still short of the mooring');
  Cue := Run(1, PierRight);
  Assert.IsTrue(Cue.Moored, 'Moored as the glide ends');
  Assert.AreEqual(Ord(bsMoored), Ord(FBarge.Stage), 'Moored');
  Assert.AreEqual(PierRight + MoorGap, FBarge.Left, UnitSlack,
    'A hop past the pier''s end');
  Cue := Run(10, PierRight);
  Assert.IsFalse(Cue.Moored, 'Told once');
end;

procedure TBargeRideTests.TestMooredItRidesWithThePiersEnd;
begin
  FBarge.Come;
  Run(ComeTicks, PierRight);
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
  FBarge.Come;
  Run(ComeTicks, PierRight);
  Run(1, MoorFloorX - MoorGap - 100);
  Assert.AreEqual(Double(MoorFloorX), FBarge.Left, UnitSlack,
    'Held at the floor');
  Run(10, -500);
  Assert.AreEqual(Double(MoorFloorX), FBarge.Left, UnitSlack, 'And kept there');
end;

procedure TBargeRideTests.TestKeepsItsPlaceOnceThePierIsGone;
begin
  FBarge.Come;
  Run(ComeTicks, PierRight);
  var Left := FBarge.Left;
  Run(10, 0, False, False);
  Assert.AreEqual(Left, FBarge.Left, UnitSlack, 'Where the pier left it');
  Assert.AreEqual(0.0, FBarge.Way, UnitSlack, 'Going nowhere');
end;

procedure TBargeRideTests.TestBoardedItCastsOffToItsStation;
begin
  FBarge.Come;
  Run(ComeTicks, PierRight);
  var Cue := Run(1, PierRight, True);
  Assert.IsTrue(Cue.Boarded, 'Told of the boarding');
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
  Cue := Run(20, PierRight, True);
  Assert.IsFalse(Cue.Boarded, 'Told once');
  Assert.AreEqual(Double(StationLeft), FBarge.Left, UnitSlack, 'Holding it');
end;

procedure TBargeRideTests.TestBoardedWhileComingItCastsOffToo;
begin
  FBarge.Come;
  Run(ComeTicks div 2, PierRight);
  var Cue := Run(1, PierRight, True);
  Assert.IsTrue(Cue.Boarded, 'Boarded on the way in');
  Assert.IsFalse(Cue.Moored, 'Never moored');
  Assert.AreEqual(Ord(bsCasting), Ord(FBarge.Stage), 'Casting off');
end;

procedure TBargeRideTests.TestThePierFallsWhenTheGraceIsOver;
begin
  FBarge.Come;
  Run(ComeTicks, PierRight);
  var Cue := Run(GraceTicks - 1, PierRight);
  Assert.IsFalse(Cue.PierFalls, 'Not within the grace');
  Cue := Run(1, PierRight);
  Assert.IsTrue(Cue.PierFalls, 'As the grace is over');
  Cue := Run(GraceTicks, PierRight);
  Assert.IsFalse(Cue.PierFalls, 'Told once');
  Cue := Run(1, PierRight, True);
  Assert.IsTrue(Cue.Boarded, 'He may still board');
  Cue := Run(BoardedPierTicks * 2, PierRight, True);
  Assert.IsFalse(Cue.PierFalls, 'And the pier is not told again');
end;

procedure TBargeRideTests.TestThePierFallsSoonAfterHeBoards;
begin
  FBarge.Come;
  Run(ComeTicks, PierRight);
  Run(10, PierRight);
  Run(1, PierRight, True);
  var Cue := Run(BoardedPierTicks - 1, PierRight, True);
  Assert.IsFalse(Cue.PierFalls, 'Not at once');
  Cue := Run(1, PierRight, True);
  Assert.IsTrue(Cue.PierFalls, 'Soon after him');
  Cue := Run(GraceTicks, PierRight, True);
  Assert.IsFalse(Cue.PierFalls, 'Told once');
end;

procedure TBargeRideTests.TestStationIsThereAtOnce;
begin
  FBarge.Station;
  Assert.AreEqual(Ord(bsStation), Ord(FBarge.Stage), 'At its station');
  Assert.AreEqual(Double(StationLeft), FBarge.Left, UnitSlack, 'Its left edge');
  var Cue := Run(GraceTicks * 2, 0, True, False);
  Assert.IsFalse(Cue.Moored or Cue.Boarded or Cue.PierFalls,
    'Nothing told: the pier is long gone');
  Assert.AreEqual(Double(StationLeft), FBarge.Left, UnitSlack, 'Holding it');
end;

procedure TBargeRideTests.TestWayIsWhatItWentThisTick;
begin
  FBarge.Come;
  for var i := 1 to ComeTicks do
  begin
    var Before := FBarge.Left;
    Run(1, PierRight);
    Assert.AreEqual(FBarge.Left - Before, FBarge.Way, UnitSlack,
      'Tick ' + i.ToString);
    Assert.AreEqual((Before + FBarge.Left) / 2, FBarge.LeftAt(0.5), UnitSlack,
      'Tick ' + i.ToString + ': halfway between the ticks');
  end;
end;

procedure TBargeRideTests.TestClearSendsItAway;
begin
  FBarge.Come;
  Run(ComeTicks, PierRight);
  FBarge.Clear;
  Assert.AreEqual(Ord(bsAway), Ord(FBarge.Stage), 'Away');
  Assert.IsTrue(FBarge.Left >= ScreenWidth, 'Beyond the right edge');
  var Cue := Run(GraceTicks * 2, PierRight);
  Assert.IsFalse(Cue.PierFalls, 'No grace runs');
end;

initialization
  TDUnitX.RegisterTestFixture(TBargeRideTests);

end.
