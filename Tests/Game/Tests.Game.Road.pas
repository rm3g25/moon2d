{
  Tests.Game.Road - the road of the chase running out: its tiles stand a
  tile apart from the belt's phase; the tiles beyond the break fall away
  the farthest first, a gap apart; the pier ends at the last standing tile
  and rides the belt; a falling tile drops, turns and is gone under the
  screen; the collapse takes the pier down from its end; a tile between
  the ticks lies between them; a clear is a whole road again.

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
    // Ticks of a standing belt; the falls counted
    function Run(ATicks: Integer; AWay: Double = 0): Integer;
    function StandingCount: Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestNothingTillTheStart;
    [Test]
    procedure TestTilesStandATileApartFromThePhase;
    [Test]
    procedure TestTheFarthestTileFallsFirstAtOnce;
    [Test]
    procedure TestTilesBeyondTheBreakFallAGapApart;
    [Test]
    procedure TestThePierEndsAtTheLastStandingTile;
    [Test]
    procedure TestThePierRidesTheBelt;
    [Test]
    procedure TestAFallingTileDropsTurnsAndIsGone;
    [Test]
    procedure TestTheCollapseTakesThePierDownFromItsEnd;
    [Test]
    procedure TestATileBetweenTicksLiesBetweenThem;
    [Test]
    procedure TestClearIsAWholeRoadAgain;
  end;

implementation

uses
  System.SysUtils,
  Render.Sprites;

const
  Phase: Double = 12.0;
  // The tiles of a start at Phase that stand beyond RoadBreakX: their
  // lefts are Phase - 32 + 32 i, so from i = 11 (332) to 16 - six
  FallingAtStart = 6;
  UnitSlack = 0.001;

procedure TRoadEndTests.Setup;
begin
  FRoad := TRoadEnd.Create;
end;

procedure TRoadEndTests.TearDown;
begin
  FRoad.Free;
end;

function TRoadEndTests.Run(ATicks: Integer; AWay: Double): Integer;
begin
  Result := 0;
  for var i := 1 to ATicks do
    if FRoad.Tick(AWay).Broke then
      Inc(Result);
end;

function TRoadEndTests.StandingCount: Integer;
begin
  Result := 0;
  for var i := 0 to RoadTiles - 1 do
    if FRoad.Standing(i) then
      Inc(Result);
end;

procedure TRoadEndTests.TestNothingTillTheStart;
begin
  Assert.IsFalse(FRoad.Running, 'Not running');
  Assert.AreEqual(0, Run(10), 'Nothing breaks');
  Assert.IsFalse(FRoad.PierStands, 'No pier');
  Assert.IsFalse(FRoad.Standing(0), 'No tile standing');
end;

procedure TRoadEndTests.TestTilesStandATileApartFromThePhase;
begin
  FRoad.Start(Phase);
  Assert.IsTrue(FRoad.Running, 'Running');
  for var i := 0 to RoadTiles - 1 do
  begin
    var Tile := FRoad.TileAt(i, 1);
    Assert.AreEqual(Phase - TileSize + TileSize * i, Tile.Left, UnitSlack,
      'The left edge of tile ' + i.ToString);
    Assert.IsFalse(Tile.Falling, 'Standing before the first tick');
  end;
  Assert.AreEqual(Phase - TileSize, FRoad.PierLeft, UnitSlack,
    'The pier starts a tile short of the phase');
end;

procedure TRoadEndTests.TestTheFarthestTileFallsFirstAtOnce;
begin
  FRoad.Start(Phase);
  Assert.AreEqual(1, Run(1), 'One tile breaks on the first tick');
  Assert.IsTrue(FRoad.TileAt(RoadTiles - 1, 1).Falling, 'The farthest one');
  Assert.IsTrue(FRoad.Standing(RoadTiles - 2), 'The next one stands yet');
end;

procedure TRoadEndTests.TestTilesBeyondTheBreakFallAGapApart;
begin
  FRoad.Start(Phase);
  Assert.AreEqual(1, Run(1), 'The first');
  Assert.AreEqual(0, Run(BreakGapTicks - 1), 'None within the gap');
  Assert.AreEqual(1, Run(1), 'The second as the gap is over');
  Run(BreakGapTicks * RoadTiles);
  Assert.AreEqual(RoadTiles - FallingAtStart, StandingCount,
    'Every tile beyond the break fell, and no other');
  Assert.AreEqual(0, Run(BreakGapTicks * 3), 'And the falls are over');
end;

procedure TRoadEndTests.TestThePierEndsAtTheLastStandingTile;
begin
  FRoad.Start(Phase);
  var WholeRight := Phase - TileSize + TileSize * RoadTiles;
  Assert.AreEqual(WholeRight, FRoad.PierRight, UnitSlack, 'Whole');
  Run(1);
  Assert.AreEqual(WholeRight - TileSize, FRoad.PierRight, UnitSlack,
    'A tile shorter with the first fall');
  Run(BreakGapTicks * RoadTiles);
  Assert.AreEqual(WholeRight - TileSize * FallingAtStart, FRoad.PierRight,
    UnitSlack, 'Up to the break once the falls are over');
  Assert.IsTrue(FRoad.PierStands, 'Standing');
end;

procedure TRoadEndTests.TestThePierRidesTheBelt;
const
  Way: Double = -0.25;
  Ticks = 40;
begin
  FRoad.Start(Phase);
  Run(BreakGapTicks * RoadTiles);
  var Left := FRoad.PierLeft;
  var Right := FRoad.PierRight;
  Run(Ticks, Way);
  Assert.AreEqual(Left + Way * Ticks, FRoad.PierLeft, UnitSlack, 'The left end');
  Assert.AreEqual(Right + Way * Ticks, FRoad.PierRight, UnitSlack,
    'The right end');
end;

procedure TRoadEndTests.TestAFallingTileDropsTurnsAndIsGone;
const
  Way: Double = -0.25;
begin
  FRoad.Start(Phase);
  Run(1, Way);
  var LastDrop: Double := -1;
  var Ticks := 0;
  repeat
    var Tile := FRoad.TileAt(RoadTiles - 1, 1);
    Assert.IsTrue(Tile.Drop > LastDrop, 'It drops farther every tick');
    Assert.IsTrue(Abs(Tile.Tilt) > 0, 'It turns as it falls');
    Assert.AreEqual(Phase - TileSize + TileSize * (RoadTiles - 1) +
      Way * (Ticks + 1), Tile.Left, UnitSlack, 'It rides the belt as it falls');
    LastDrop := Tile.Drop;
    Run(1, Way);
    Inc(Ticks);
  until FRoad.TileAt(RoadTiles - 1, 1).Gone or (Ticks > 200);
  Assert.IsTrue(FRoad.TileAt(RoadTiles - 1, 1).Gone, 'Gone in the end');
  Assert.IsTrue(FRoad.TileAt(RoadTiles - 1, 1).Drop >= FallGone,
    'Gone no sooner than under the screen');
  Assert.IsTrue(Ticks < 60, 'Gone within two seconds');
end;

procedure TRoadEndTests.TestTheCollapseTakesThePierDownFromItsEnd;
begin
  FRoad.Start(Phase);
  Run(BreakGapTicks * RoadTiles);
  var Standing := StandingCount;
  Assert.IsFalse(FRoad.Collapsing, 'Not collapsing yet');

  FRoad.Collapse;

  Assert.IsTrue(FRoad.Collapsing, 'Collapsing');
  Assert.AreEqual(1, Run(1), 'The first falls at once');
  Assert.IsTrue(FRoad.TileAt(Standing - 1, 1).Falling, 'From the end');
  Assert.IsTrue(FRoad.Standing(0), 'The first tile stands yet');
  Assert.AreEqual(0, Run(CollapseGapTicks - 1), 'A gap between two');
  Assert.AreEqual(1, Run(1), 'The next');
  Run(CollapseGapTicks * Standing);
  Assert.IsFalse(FRoad.PierStands, 'Nothing left standing');
  Assert.AreEqual(0.0, FRoad.PierRight, UnitSlack, 'No pier, no end');
  FRoad.Collapse;
  Assert.AreEqual(0, Run(CollapseGapTicks * 2), 'A second collapse is nothing');
end;

procedure TRoadEndTests.TestATileBetweenTicksLiesBetweenThem;
const
  Way: Double = -2.0;
begin
  FRoad.Start(Phase);
  Run(2, Way);
  var Before := FRoad.TileAt(RoadTiles - 1, 1);
  Run(1, Way);
  var After := FRoad.TileAt(RoadTiles - 1, 1);
  var Halfway := FRoad.TileAt(RoadTiles - 1, 0.5);
  Assert.AreEqual((Before.Left + After.Left) / 2, Halfway.Left, UnitSlack,
    'Across');
  Assert.AreEqual((Before.Drop + After.Drop) / 2, Halfway.Drop, UnitSlack,
    'Down');
  Assert.AreEqual((Before.Tilt + After.Tilt) / 2, Halfway.Tilt, UnitSlack,
    'Turned');
end;

procedure TRoadEndTests.TestClearIsAWholeRoadAgain;
begin
  FRoad.Start(Phase);
  Run(BreakGapTicks * RoadTiles, -1);
  FRoad.Collapse;

  FRoad.Clear;

  Assert.IsFalse(FRoad.Running, 'Not running');
  Assert.IsFalse(FRoad.Collapsing, 'Not collapsing');
  Assert.IsFalse(FRoad.PierStands, 'No pier of its own: the grid is the road');
  Assert.AreEqual(0, Run(10), 'Nothing breaks');
end;

initialization
  TDUnitX.RegisterTestFixture(TRoadEndTests);

end.
