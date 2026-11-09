{
  Tests.Game.Road - the road of the chase running out: its first tile
  stands a tile short of the belt's phase; its end, the cliff, starts
  beyond the right edge; the pier rides the belt and is gone once its end
  passes the left edge; a place between the ticks lies between them; a
  clear is a whole road again.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Game.Road;

interface

uses
  DUnitX.TestFramework,
  Game.Road;

type
  [TestFixture]
  TRoadEndTests = class
  private
    FRoad: TRoadEnd;
    procedure Run(ATicks: Integer; AWay: Double);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestNothingTillTheStart;
    [Test]
    procedure TestThePierStartsATileShortOfThePhase;
    [Test]
    procedure TestTheCliffComesInFromBeyondTheRightEdge;
    [Test]
    procedure TestThePierRidesTheBelt;
    [Test]
    procedure TestThePierIsGoneOncePastTheLeftEdge;
    [Test]
    procedure TestAPlaceBetweenTicksLiesBetweenThem;
    [Test]
    procedure TestClearIsAWholeRoadAgain;
  end;

implementation

uses
  Render.Sprites, Game.Space;

const
  Phase: Double = 12.0;
  UnitSlack = 0.001;

procedure TRoadEndTests.Setup;
begin
  FRoad := TRoadEnd.Create;
end;

procedure TRoadEndTests.TearDown;
begin
  FRoad.Free;
end;

procedure TRoadEndTests.Run(ATicks: Integer; AWay: Double);
begin
  for var i := 1 to ATicks do
    FRoad.Tick(AWay);
end;

procedure TRoadEndTests.TestNothingTillTheStart;
begin
  Assert.IsFalse(FRoad.Running, 'Not running');
  Run(10, -1);
  Assert.IsFalse(FRoad.PierStands, 'No pier');
  Assert.AreEqual(0.0, FRoad.PierRight, UnitSlack, 'No end');
end;

procedure TRoadEndTests.TestThePierStartsATileShortOfThePhase;
begin
  FRoad.Start(Phase);
  Assert.IsTrue(FRoad.Running, 'Running');
  Assert.AreEqual(Phase - TileSize, FRoad.PierLeft, UnitSlack, 'Its left end');
  Assert.AreEqual(Phase - TileSize, FRoad.LeftAt(1), UnitSlack,
    'Its first tile');
  Assert.AreEqual(Phase - TileSize + TileSize * RoadTiles, FRoad.PierRight,
    UnitSlack, 'Its end, a whole number of tiles on');
end;

procedure TRoadEndTests.TestTheCliffComesInFromBeyondTheRightEdge;
const
  // The belt's phase is a share of a tile, from its start to its end
  Phases: array [0..2] of Double = (0.0, 12.0, 31.9);
begin
  for var Start in Phases do
  begin
    FRoad.Start(Start);
    Assert.IsTrue(FRoad.PierRight >= ScreenWidth, 'Not on the screen yet');
    Assert.IsTrue(FRoad.PierRight <= ScreenWidth + TileSize,
      'No more than a tile beyond it');
  end;
end;

procedure TRoadEndTests.TestThePierRidesTheBelt;
const
  Way: Double = -1.5;
  Ticks = 40;
begin
  FRoad.Start(Phase);
  var Left := FRoad.PierLeft;
  var Right := FRoad.PierRight;
  Run(Ticks, Way);
  Assert.AreEqual(Left + Way * Ticks, FRoad.PierLeft, UnitSlack, 'The left end');
  Assert.AreEqual(Right + Way * Ticks, FRoad.PierRight, UnitSlack, 'The cliff');
  Assert.IsTrue(FRoad.PierStands, 'Standing');
end;

procedure TRoadEndTests.TestThePierIsGoneOncePastTheLeftEdge;
begin
  FRoad.Start(Phase);
  var Right := FRoad.PierRight;
  Run(1, -(Right - 1));
  Assert.IsTrue(FRoad.PierStands, 'A unit of it on the screen');
  Run(1, -1);
  Assert.IsFalse(FRoad.PierStands, 'Gone with its end at the left edge');
  Assert.IsTrue(FRoad.Running, 'The road still runs out: the grid stays air');
end;

procedure TRoadEndTests.TestAPlaceBetweenTicksLiesBetweenThem;
const
  Way: Double = -2.0;
begin
  FRoad.Start(Phase);
  Run(2, Way);
  var Before := FRoad.PierLeft;
  Run(1, Way);
  Assert.AreEqual(Before, FRoad.LeftAt(0), UnitSlack, 'The last tick');
  Assert.AreEqual(FRoad.PierLeft, FRoad.LeftAt(1), UnitSlack, 'This tick');
  Assert.AreEqual(Before + Way / 2, FRoad.LeftAt(0.5), UnitSlack, 'Halfway');
end;

procedure TRoadEndTests.TestClearIsAWholeRoadAgain;
begin
  FRoad.Start(Phase);
  Run(10, -1);

  FRoad.Clear;

  Assert.IsFalse(FRoad.Running, 'Not running');
  Assert.IsFalse(FRoad.PierStands, 'No pier of its own: the grid is the road');
  Run(10, -1);
  Assert.AreEqual(0.0, FRoad.PierLeft, UnitSlack, 'Nothing rides');
end;

initialization
  TDUnitX.RegisterTestFixture(TRoadEndTests);

end.
