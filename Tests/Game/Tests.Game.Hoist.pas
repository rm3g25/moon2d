{
  Tests.Game.Hoist - the beam's way up with the hero: where he is free,
  straight up and exactly a cell, on the road and in the air alike; too
  near the left or the right edge, drawn clear of it first; by the hull,
  drawn off it on the side away from its middle, or the other side when
  that one has no room; on a pad over the hull, not drawn at all. And
  the path itself: from where he was caught, across at his own height
  first, then up, and at the top from its last tick on.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Game.Hoist;

interface

uses
  DUnitX.TestFramework,
  Sdl2.Core,
  Game.Hoist;

type
  [TestFixture]
  THoistPlanTests = class
  public
    [Test]
    procedure TestFreeItGoesStraightUpACell;
    [Test]
    procedure TestInTheAirItGoesUpACellToo;
    [Test]
    procedure TestByTheLeftEdgeItIsDrawnRight;
    [Test]
    procedure TestByTheRightEdgeItIsDrawnLeft;
    [Test]
    procedure TestLeftOfTheHullItIsDrawnLeft;
    [Test]
    procedure TestRightOfTheHullItIsDrawnRight;
    [Test]
    procedure TestAHullByTheEdgeSendsItTheOtherWay;
    [Test]
    procedure TestOnAPadOverTheHullItIsNotDrawn;
  end;

  [TestFixture]
  THoistPathTests = class
  public
    [Test]
    procedure TestItStartsWhereHeWasCaught;
    [Test]
    procedure TestAcrossFirstAtHisHeight;
    [Test]
    procedure TestThenUpToTheTopAndStays;
  end;

implementation

uses
  System.SysUtils,
  Render.Sprites,
  Game.Space;

const
  Slop = 0.001;
  Road = 352.0;
  // The Ram's hull as the boss arena has it, its left edge at HullLeft
  HullLeft = 150.0;
  HullWidth = 169.0;
  HullTop = 224.0;
  HullHeight = 128.0;
  RightmostLeft = ScreenWidth - HoistEdgeClear - TileSize;

function At(AX, AY: Single): TSdlFPoint;
begin
  Result.X := AX;
  Result.Y := AY;
end;

function NoHull: THoistWorld;
begin
  Result := Default(THoistWorld);
end;

function HullAt(ALeft: Single): THoistWorld;
begin
  Result.HasHull := True;
  Result.Hull.X := ALeft;
  Result.Hull.Y := HullTop;
  Result.Hull.W := HullWidth;
  Result.Hull.H := HullHeight;
end;

procedure ExpectPoint(const AExpected, AActual: TSdlFPoint; const AWhat: string);
begin
  Assert.AreEqual(Double(AExpected.X), Double(AActual.X), Slop, AWhat + ': across');
  Assert.AreEqual(Double(AExpected.Y), Double(AActual.Y), Slop, AWhat + ': down');
end;

{ THoistPlanTests }

procedure THoistPlanTests.TestFreeItGoesStraightUpACell;
begin
  var Path := PlanHoist(At(200, Road), NoHull);
  ExpectPoint(At(200, Road), Path.Clear, 'Not drawn');
  Assert.AreEqual(0, Path.DrawTicks, 'No way across');
  ExpectPoint(At(200, Road - TileSize), Path.Top, 'A cell up');
end;

procedure THoistPlanTests.TestInTheAirItGoesUpACellToo;
begin
  var Path := PlanHoist(At(250, 200), NoHull);
  Assert.AreEqual(0, Path.DrawTicks, 'Not drawn');
  ExpectPoint(At(250, 200 - TileSize), Path.Top, 'A cell up from the air');
end;

procedure THoistPlanTests.TestByTheLeftEdgeItIsDrawnRight;
begin
  var Path := PlanHoist(At(10, Road), NoHull);
  ExpectPoint(At(HoistEdgeClear, Road), Path.Clear, 'Clear of the left edge');
  Assert.IsTrue(Path.DrawTicks > 0, 'A way across');
  ExpectPoint(At(HoistEdgeClear, Road - TileSize), Path.Top, 'Then up');
end;

procedure THoistPlanTests.TestByTheRightEdgeItIsDrawnLeft;
begin
  var Path := PlanHoist(At(470, Road), NoHull);
  ExpectPoint(At(RightmostLeft, Road), Path.Clear, 'Clear of the right edge');
  ExpectPoint(At(RightmostLeft, Road - TileSize), Path.Top, 'Then up');
end;

procedure THoistPlanTests.TestLeftOfTheHullItIsDrawnLeft;
begin
  var Path := PlanHoist(At(130, Road), HullAt(HullLeft));
  ExpectPoint(At(HullLeft - HoistHullClear - TileSize, Road), Path.Clear,
    'Off the hull to the left');
end;

procedure THoistPlanTests.TestRightOfTheHullItIsDrawnRight;
begin
  var Path := PlanHoist(At(HullLeft + HullWidth + 4, Road), HullAt(HullLeft));
  ExpectPoint(At(HullLeft + HullWidth + HoistHullClear, Road), Path.Clear,
    'Off the hull to the right');
end;

procedure THoistPlanTests.TestAHullByTheEdgeSendsItTheOtherWay;
const
  NearEdge = 40.0;
begin
  var Path := PlanHoist(At(60, Road), HullAt(NearEdge));
  ExpectPoint(At(NearEdge + HullWidth + HoistHullClear, Road), Path.Clear,
    'No room on the left: to the right of it');
end;

procedure THoistPlanTests.TestOnAPadOverTheHullItIsNotDrawn;
const
  PadDeck = 192.0;
begin
  var Path := PlanHoist(At(200, PadDeck), HullAt(HullLeft));
  Assert.AreEqual(0, Path.DrawTicks, 'Not drawn');
  ExpectPoint(At(200, PadDeck - TileSize), Path.Top, 'A cell up from the pad');
end;

{ THoistPathTests }

procedure THoistPathTests.TestItStartsWhereHeWasCaught;
begin
  var Path := PlanHoist(At(10, Road), NoHull);
  ExpectPoint(At(10, Road), Path.At(0), 'At the catch');
end;

procedure THoistPathTests.TestAcrossFirstAtHisHeight;
begin
  var Path := PlanHoist(At(10, Road), NoHull);
  var LastX: Single := 10;
  for var i := 1 to Path.DrawTicks do
  begin
    var Place := Path.At(i);
    Assert.AreEqual(Double(Road), Double(Place.Y), Slop,
      Format('At his height at %d', [i]));
    Assert.IsTrue(Place.X >= LastX - Slop, Format('Only right, at %d', [i]));
    LastX := Place.X;
  end;
  ExpectPoint(Path.Clear, Path.At(Path.DrawTicks), 'Clear before the lift');
end;

procedure THoistPathTests.TestThenUpToTheTopAndStays;
begin
  var Path := PlanHoist(At(200, Road), NoHull);
  var LastY: Single := Road;
  for var i := 1 to Path.Ticks do
  begin
    var Place := Path.At(i);
    Assert.AreEqual(200.0, Double(Place.X), Slop, Format('Straight up at %d', [i]));
    Assert.IsTrue(Place.Y <= LastY + Slop, Format('Only up, at %d', [i]));
    LastY := Place.Y;
  end;
  ExpectPoint(Path.Top, Path.At(Path.Ticks), 'At the top');
  ExpectPoint(Path.Top, Path.At(10 * Path.Ticks), 'And there it stays');
end;

initialization
  TDUnitX.RegisterTestFixture(THoistPlanTests);
  TDUnitX.RegisterTestFixture(THoistPathTests);

end.
