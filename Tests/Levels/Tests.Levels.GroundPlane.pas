{
  Tests.Levels.GroundPlane - the crater floor as a plane under the titles'
  eye, over the camera and the plane of the day the tests were written, so
  tuning the shipped layout breaks nothing here. A row of the screen lies
  as far off as the eye's height says, the lower the nearer; it is taken
  from the copy of the tile squeezed as it is, a finer window from a finer
  copy; the tile comes round every turn, along the strip and into the
  depth, and the turn that covers the screen's left edge begins at it or
  left of it. Far off, and past the deepest copy, a row goes to the far
  ground's colour. No ground over the horizon nor beyond the ridge's foot.
  The rows are the stand's, number for number.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Levels.GroundPlane;

interface

uses
  DUnitX.TestFramework,
  Levels.FarPlane, Levels.GroundPlane;

type
  [TestFixture]
  TGroundPlaneTests = class
  private
    FDef: TFarPlaneDef;
    FEye: TFarPlaneEye;
    function RowAt(ADown: Double): TPlaneRow;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure TestTheRowsAreTheStands;
    [Test]
    procedure TestTheLowerTheRowTheNearer;
    [Test]
    procedure TestNoGroundOverTheHorizon;
    [Test]
    procedure TestNoGroundBeyondTheRidgesFoot;
    [Test]
    procedure TestFarOffARowGoesToTheFarGroundsColour;
    [Test]
    procedure TestTheTileComesRoundEveryTurnAlongTheStrip;
    [Test]
    procedure TestTheTileComesRoundEveryTurnIntoTheDepth;
    [Test]
    procedure TestTheFirstTurnCoversTheLeftEdge;
    [Test]
    procedure TestAFinerWindowTakesAFinerCopy;
  end;

implementation

uses
  System.SysUtils, System.IOUtils, System.JSON;

type
  // A row of the stand's plane: its middle Down units under the horizon,
  // and what the stand lays there
  TStandRow = record
    Down, Depth: Double;
    Level: Integer;
    TileRow, Scale, FirstTurn, FarShare: Double;
  end;

const
  Slack = 0.000001;
  // The shipped layout's camera, ridge and plane of the day
  Layout = '{"screen": {"w": 512, "h": 384},'
    + '"sun": {"x": 288, "y": 208, "disc": 7, "halo": 120,'
    + ' "white": [255, 250, 240], "tint": [255, 128, 112], "tintRamp": 48},'
    + '"speeds": {"road": 33, "tunnelPeak": 6, "tunnelCruise": 6, "easeSec": 3,'
    + ' "cityShareInTunnel": 0.5, "cityCruise": 3, "cityBrakeZone": 512,'
    + ' "cityLeast": 0.3, "ridgeShareOfCity": 0.35, "ground": 14, "fangs": 20},'
    + '"camera": {"horizon": 238, "baseY": 266, "focal": 1024},'
    + '"plane": {"tile": "ground-top", "tileUnits": 448, "gain": 1.25, "levels": 8,'
    + ' "wideLevels": 2, "far": [1500, 3000], "farShade": 0.45, "mean": [38, 36, 36],'
    + ' "floor": {"meltLift": [2, 14], "meltPush": [30, 200], "slabDeep": 6,'
    + ' "slabFeather": 2, "sharpSeconds": 4, "sharpFade": 1.5, "foot": [20, 21, 25]}},'
    + '"layers": [{"id": "city", "speed": "city", "length": 2688}]}';
  TileUnits = 448;
  TileRows = 1254;
  // A pixel of the stand's stage, 1440 by 1080
  StandPixel = 1 / 2.8125;
  // The eye of the stand 16 s into the flight, the world having stood at
  // 2412: where it is along the strip, its lift and its push
  EyeAlong = 1037.875499646224;
  EyeLift = 5.987421179872983;
  EyePush = 93.15872323809313;
  // The stand's rows 704, 744, 800, 900 and 1079 under that eye
  StandRows: array [0..4] of TStandRow = (
    (Down: 12.48888888888888; Depth: 2786.726633395993; Level: 7;
      TileRow: 0.5716844717989158; Scale: 0.3674562074831579;
      FirstTurn: -125.37379493968902; FarShare: 0.9706063674868418),
    (Down: 26.71111111111111; Depth: 1302.945397644382; Level: 6;
      TileRow: 0.8836961587444749; Scale: 0.785911675079637;
      FirstTurn: -207.59004201540174; FarShare: 0),
    (Down: 46.622222222222206; Depth: 746.4920724349607; Level: 4;
      TileRow: 0.1257794739440763; Scale: 1.3717493297147072;
      FirstTurn: -553.1613212548357; FarShare: 0),
    (Down: 82.1777777777778; Depth: 423.5101049130737; Level: 2;
      TileRow: 0.8467213657340025; Scale: 2.417887998705906;
      FirstTurn: -87.03906790500884; FarShare: 0),
    (Down: 145.8222222222222; Depth: 238.66814507292705; Level: 1;
      TileRow: 0.25931502609147283; Scale: 4.2904762162001475;
      FirstTurn: -352.7134568936367; FarShare: 0));
  // The stand's row 690 lies beyond the ridge's foot
  BeyondTheRidge = 7.51111111111112;
  // 18 s into the flight the stand's row 744 lies 2028 units off, a third
  // of the way from the tile to the far ground's colour
  LaterLift = 24.90712629176242;
  LaterPush = 342.26555949486607;
  LaterAlong = 855.5496150986307;
  LaterDown = 26.71111111111111;
  LaterFarShare = 0.28471465007010827;

function ReadFromLayout(const ALayout: string): TFarPlaneDef;
begin
  var Dir := TPath.GetTempPath;
  var Name := 'moon2d-groundplane-' + TGUID.NewGuid.ToString + '.json';
  TFile.WriteAllText(TPath.Combine(Dir, Name), ALayout, TEncoding.ASCII);
  var Root := TJSONObject.ParseJSONValue(
    '{"farPlane": {"screen": 1, "layout": "' + Name + '"}}') as TJSONObject;
  try
    Result := ReadFarPlane(Root, 'test', Dir);
  finally
    Root.Free;
    TFile.Delete(TPath.Combine(Dir, Name));
  end;
end;

function Matches(AValue, AExpected: Double): Boolean;
begin
  Result := Abs(AValue - AExpected) < Slack;
end;

procedure TGroundPlaneTests.Setup;
begin
  FDef := ReadFromLayout(Layout);
  FEye := Default(TFarPlaneEye);
  FEye.Flying := True;
  FEye.Lift := EyeLift;
  FEye.Push := EyePush;
end;

function TGroundPlaneTests.RowAt(ADown: Double): TPlaneRow;
begin
  Result := PlaneRow(FDef, FEye, EyeAlong, ADown, StandPixel, TileRows);
end;

procedure TGroundPlaneTests.TestTheRowsAreTheStands;
begin
  for var Stand in StandRows do
  begin
    var Row := RowAt(Stand.Down);
    Assert.IsTrue(Row.Ground, 'On the ground');
    Assert.IsTrue(Matches(Row.Depth, Stand.Depth), 'As far off');
    Assert.AreEqual(Stand.Level, Row.Level, 'From the same copy');
    Assert.IsTrue(Matches(Row.TileRow, Stand.TileRow), 'From the same row of it');
    Assert.IsTrue(Matches(Row.Scale, Stand.Scale), 'As large across');
    Assert.IsTrue(Matches(Row.FirstTurn, Stand.FirstTurn), 'Its turns laid alike');
    Assert.IsTrue(Matches(Row.FarShare, Stand.FarShare), 'As far gone to the far ground');
  end;
end;

procedure TGroundPlaneTests.TestTheLowerTheRowTheNearer;
begin
  for var i := 1 to High(StandRows) do
  begin
    var Upper := RowAt(StandRows[i - 1].Down);
    var Lower := RowAt(StandRows[i].Down);
    Assert.IsTrue(Lower.Depth < Upper.Depth, 'Nearer');
    Assert.IsTrue(Lower.Level <= Upper.Level, 'And no more squeezed');
  end;
end;

procedure TGroundPlaneTests.TestNoGroundOverTheHorizon;
begin
  Assert.IsFalse(RowAt(0).Ground, 'On the horizon');
  Assert.IsFalse(RowAt(-10).Ground, 'Over it');
end;

procedure TGroundPlaneTests.TestNoGroundBeyondTheRidgesFoot;
begin
  Assert.IsFalse(RowAt(BeyondTheRidge).Ground, 'The ridge is the edge of the world');
  Assert.IsTrue(RowAt(StandRows[0].Down).Ground, 'Before its foot there is');
end;

procedure TGroundPlaneTests.TestFarOffARowGoesToTheFarGroundsColour;
begin
  FEye.Lift := LaterLift;
  FEye.Push := LaterPush;
  var Row := PlaneRow(FDef, FEye, LaterAlong, LaterDown, StandPixel, TileRows);
  Assert.IsTrue(Row.Ground, 'On the ground');
  Assert.IsTrue(Matches(Row.FarShare, LaterFarShare), 'As the stand has it');
  var Nearby := PlaneRow(FDef, FEye, LaterAlong, StandRows[4].Down, StandPixel, TileRows);
  Assert.IsTrue(Matches(Nearby.FarShare, 0), 'None of it near the eye');
end;

procedure TGroundPlaneTests.TestTheTileComesRoundEveryTurnAlongTheStrip;
begin
  var Down := StandRows[2].Down;
  var Here := PlaneRow(FDef, FEye, EyeAlong, Down, StandPixel, TileRows);
  var ATurnOn := PlaneRow(FDef, FEye, EyeAlong - TileUnits, Down, StandPixel, TileRows);
  var HalfATurnOn := PlaneRow(FDef, FEye, EyeAlong - TileUnits / 2, Down, StandPixel, TileRows);
  Assert.IsTrue(Matches(ATurnOn.FirstTurn, Here.FirstTurn), 'A turn on: the same picture');
  Assert.IsFalse(Matches(HalfATurnOn.FirstTurn, Here.FirstTurn), 'Half a turn on: another');
  Assert.IsTrue(Matches(HalfATurnOn.TileRow, Here.TileRow), 'The same row of the tile');
end;

procedure TGroundPlaneTests.TestTheTileComesRoundEveryTurnIntoTheDepth;
begin
  var Down := StandRows[3].Down;
  var Here := RowAt(Down);
  FEye.Push := EyePush + TileUnits;
  var ATurnIn := RowAt(Down);
  FEye.Push := EyePush + TileUnits / 2;
  var HalfATurnIn := RowAt(Down);
  Assert.IsTrue(Matches(ATurnIn.TileRow, Here.TileRow), 'A turn in: the same row');
  Assert.IsFalse(Matches(HalfATurnIn.TileRow, Here.TileRow), 'Half a turn in: another');
end;

procedure TGroundPlaneTests.TestTheFirstTurnCoversTheLeftEdge;
begin
  for var Stand in StandRows do
  begin
    var Row := RowAt(Stand.Down);
    Assert.IsTrue(Row.FirstTurn <= 0, 'At the edge or left of it');
    Assert.IsTrue(Row.FirstTurn + TileUnits * Row.Scale > 0, 'And reaching past it');
  end;
end;

procedure TGroundPlaneTests.TestAFinerWindowTakesAFinerCopy;
begin
  var Down := StandRows[2].Down;
  var Coarse := PlaneRow(FDef, FEye, EyeAlong, Down, StandPixel, TileRows);
  var Fine := PlaneRow(FDef, FEye, EyeAlong, Down, StandPixel / 2, TileRows);
  Assert.AreEqual(Coarse.Level - 1, Fine.Level, 'Half the pixel: a copy less squeezed');
  Assert.IsTrue(Matches(Fine.Depth, Coarse.Depth), 'The same ground');
end;

initialization
  TDUnitX.RegisterTestFixture(TGroundPlaneTests);

end.
