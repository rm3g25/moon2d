{
  Tests.Levels.Capsule - the shape of a capsule frame over the farm's long
  dome of the layout (bin/chase-backdrop.json, "dome-farm"), its numbers
  set here so tuning the layout breaks nothing.

  Its feet stand on the base line, its far foot behind its centre and its
  near one in front; the crown stands its height over the centre, exactly
  halfway between the halves; the ends turn down to their tips on the
  ground. The frame is the stand's, edge for edge and node for node -
  1272 edges, 291 nodes, 240 of the belts' and 128 of the ring's; no edge
  is a point; the belts cross the barrel every BeltEvery cells, its ends
  among them; the nodes stand above the feet, each with a seed key of its
  own, rows apart too.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Levels.Capsule;

interface

uses
  DUnitX.TestFramework, Levels.FarPlane, Levels.Capsule;

type
  [TestFixture]
  TCapsuleTests = class
  private
    FFrame: TDomeFrame;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure TestFeetStandOnTheBaseLine;
    [Test]
    procedure TestFarFootBehindNearFootInFront;
    [Test]
    procedure TestCrownIsItsHeightHalfwayBetweenTheHalves;
    [Test]
    procedure TestEndsTurnDownToTheirTips;
    [Test]
    procedure TestShapeIsTheStands;
    [Test]
    procedure TestNoEdgeIsAPoint;
    [Test]
    procedure TestBeltsCrossTheBarrelEveryBeltEveryCells;
    [Test]
    procedure TestNodesStandAboveTheFeet;
    [Test]
    procedure TestEveryNodeHasAKeyOfItsOwn;
  end;

implementation

uses
  System.Math, System.SysUtils, System.Generics.Collections;

const
  // The layout's dome-farm of the day the tests were written
  FarmX = 2290;
  FarmLength = 640;
  FarmDepth = 220;
  FarmHeight = 90;
  FarmRows = 12;
  FarmCells = 16;
  FarmBeltEvery = 4;
  FarmCapCells = 5;
  FarmRib = 0.85;
  // The stand's capsule over these numbers
  StandEdges = 1272;
  StandNodes = 291;
  StandBeltEdges = 240;
  StandRingEdges = 128;
  BeltThickening = 2.2;
  Slack = 1E-9;
  PlaceSlack = 1E-3;
  // A thickening is a Single: 2.2 is not 2.2 of the constants
  ThickeningSlack = 1E-5;

procedure TCapsuleTests.Setup;
begin
  FFrame := Default(TDomeFrame);
  FFrame.Id := 'dome-farm';
  FFrame.Kind := fkCapsule;
  FFrame.X := FarmX;
  FFrame.W := FarmLength;
  FFrame.D := FarmDepth;
  FFrame.H := FarmHeight;
  FFrame.Rows := FarmRows;
  FFrame.Cells := FarmCells;
  FFrame.BeltEvery := FarmBeltEvery;
  FFrame.CapCells := FarmCapCells;
  FFrame.Rib := FarmRib;
end;

procedure TCapsuleTests.TestFeetStandOnTheBaseLine;
begin
  for var Along in TArray<Double>.Create(-200, 0, 150) do
  begin
    Assert.IsTrue(CapsulePoint(FFrame, Along, 0).Y = 0, 'The far foot, exactly');
    Assert.IsTrue(CapsulePoint(FFrame, Along, FarmRows).Y = 0, 'The near foot, exactly');
  end;
end;

procedure TCapsuleTests.TestFarFootBehindNearFootInFront;
begin
  Assert.AreEqual(Double(FarmDepth / 2), CapsulePoint(FFrame, 0, 0).Z, Slack, 'Far');
  Assert.AreEqual(Double(-FarmDepth / 2), CapsulePoint(FFrame, 0, FarmRows).Z, Slack,
    'Near');
end;

procedure TCapsuleTests.TestCrownIsItsHeightHalfwayBetweenTheHalves;
begin
  var Crown := CapsulePoint(FFrame, 0, FarmRows / 2);
  Assert.IsTrue(Crown.Y = FarmHeight, 'Its height');
  Assert.IsTrue(Crown.Z = 0, 'Exactly between the halves');
end;

procedure TCapsuleTests.TestEndsTurnDownToTheirTips;
begin
  var Tip := CapsuleEnd(FFrame);
  for var Side in TArray<Integer>.Create(-1, 1) do
  begin
    var AtTip := CapsulePoint(FFrame, Side * Tip, FarmRows / 2);
    Assert.IsTrue(AtTip.Y = 0, 'On the ground, exactly');
    Assert.AreEqual(Side * (CapsuleBarrel(FFrame) + FarmDepth / 2), AtTip.X, Slack,
      'A quarter turn past the barrel');
  end;
  Assert.IsTrue(CapsuleBarrel(FFrame) < Tip, 'The ends past the barrel');
end;

procedure TCapsuleTests.TestShapeIsTheStands;
begin
  var Shape := CapsuleShape(FFrame);
  Assert.AreEqual(StandEdges, Length(Shape.Edges), 'Edges');
  Assert.AreEqual(StandNodes, Length(Shape.Nodes), 'Nodes');
  var Belts := 0;
  var Rings := 0;
  for var Edge in Shape.Edges do
    if SameValue(Edge.Thickening, BeltThickening, ThickeningSlack) then
      Inc(Belts)
    else if SameValue(Edge.Thickening, FrameRingThickening, ThickeningSlack) then
      Inc(Rings);
  Assert.AreEqual(StandBeltEdges, Belts, 'The belts''');
  Assert.AreEqual(StandRingEdges, Rings, 'The ring''s');
end;

procedure TCapsuleTests.TestNoEdgeIsAPoint;
begin
  for var Edge in CapsuleShape(FFrame).Edges do
  begin
    var Length := Sqrt(Sqr(Edge.A.X - Edge.B.X) + Sqr(Edge.A.Y - Edge.B.Y) +
      Sqr(Edge.A.Z - Edge.B.Z));
    Assert.IsTrue(Length > Slack, 'An edge with a length');
  end;
end;

procedure TCapsuleTests.TestBeltsCrossTheBarrelEveryBeltEveryCells;
begin
  var Cell: Double := 2 * CapsuleBarrel(FFrame) / FarmCells;
  // By the thousandth of a unit: the last belt may land a hair past the
  // barrel's end
  var Places := TList<Double>.Create;
  try
    for var Edge in CapsuleShape(FFrame).Edges do
    begin
      var Place: Double := Round(Edge.A.X * 1000) / 1000;
      if SameValue(Edge.Thickening, BeltThickening, ThickeningSlack) and not Places.Contains(Place) then
        Places.Add(Place);
    end;
    Places.Sort;
    Assert.AreEqual(FarmCells div FarmBeltEvery + 1, Places.Count, 'The barrel''s ends too');
    for var i := 0 to Places.Count - 1 do
      Assert.AreEqual(-CapsuleBarrel(FFrame) + i * FarmBeltEvery * Cell, Places[i],
        PlaceSlack, Format('Belt %d', [i]));
  finally
    Places.Free;
  end;
end;

procedure TCapsuleTests.TestNodesStandAboveTheFeet;
begin
  for var Node in CapsuleShape(FFrame).Nodes do
  begin
    Assert.IsTrue(Node.At.Y >= 0, 'Not under the ground');
    Assert.IsTrue(Node.KeyZ > 0, 'Not on the far foot');
    Assert.IsTrue(Node.KeyZ < 1, 'Not on the near foot');
  end;
end;

procedure TCapsuleTests.TestEveryNodeHasAKeyOfItsOwn;
begin
  var Keys := TDictionary<string, Boolean>.Create;
  try
    for var Node in CapsuleShape(FFrame).Nodes do
    begin
      var Key := Format('%.6f|%.6f', [Node.KeyX, Node.KeyZ]);
      Assert.IsFalse(Keys.ContainsKey(Key), 'A key taken twice: ' + Key);
      Keys.Add(Key, True);
    end;
  finally
    Keys.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TCapsuleTests);

end.
