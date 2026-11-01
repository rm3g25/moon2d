{
  Tests.Game.FarPlane - the far plane of the chase, ridden by the belt over
  a layout of the tests' own: the stand's first tuning, whose timeline the
  stand has given, so tuning the shipped layout breaks nothing here. It
  stands until the road runs; the city opens, the tunnel goes and the brake
  begins when the stand says they do, to a tick or so; the speeds ease to
  cruise; the strip never ends in sight; the ridge rides a share of the
  city, the near ground at its own speed; a stopped belt stands it all, the
  brake's floor included; between ticks it lies between them; a clear
  brings it back to the start. The sun is white until a dome stands before
  it, then takes the dome's tint - a frame drawn by code as well. A band
  dark in the tunnel brightens to the full as the tunnel leaves. The city
  has a depth by the feet: a building on the domes' base line rides with
  its layer, one halfway to the horizon at half its speed, the lower the
  feet the faster; every one comes to the middle of the screen when its
  layer has ridden its centre there; a thing hanging in the air rides by
  what it stands on; without a camera the city is flat, and the other
  layers are flat always. Level 2 reads its far plane, its camera and
  frames among it; a layout that does not make sense raises.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Game.FarPlane;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  Game.Belt, Levels.FarPlane, Game.FarPlane;

type
  [TestFixture]
  TFarPlaneTests = class
  private
    FDef: TFarPlaneDef;
    FBelt: TBelt;
    FPlane: TFarPlane;
    procedure TickBoth;
    procedure RunSeconds(ASeconds: Single);
    // Ticks until ADone holds, at most ASeconds; the seconds it took, or -1
    function SecondsUntil(ASeconds: Single; const ADone: TFunc<Boolean>): Single;
    function CityLeft: Double;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestStandsBeforeTheBelt;
    [Test]
    procedure TestTheCityOpensAsOnTheStand;
    [Test]
    procedure TestTheTunnelGoesAsOnTheStand;
    [Test]
    procedure TestEasesToCruise;
    [Test]
    procedure TestTheBrakeBeginsAsOnTheStand;
    [Test]
    procedure TestTheStripNeverEndsInSight;
    [Test]
    procedure TestTheRidgeIsAShareOfTheCity;
    [Test]
    procedure TestTheGroundRunsAtItsSpeed;
    [Test]
    procedure TestAStoppedBeltStandsIt;
    [Test]
    procedure TestBetweenTicksLiesBetweenThem;
    [Test]
    procedure TestClearGoesBackToTheStart;
    [Test]
    procedure TestNoFarPlaneNeverMoves;
  end;

  [TestFixture]
  TFarPlaneSunTests = class
  private
    FDef: TFarPlaneDef;
    // The city's offset that puts the main dome's left edge AUnits left of
    // the sun
    function DomeInside(AUnits: Single): TFarPlaneOffsets;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure TestWhiteWithNoDomeBeforeIt;
    [Test]
    procedure TestTintedDeepInsideADome;
    [Test]
    procedure TestRampedInAtTheDomesEdge;
    [Test]
    procedure TestTintedDeepInsideAFrame;
  end;

  [TestFixture]
  TFarPlaneDepthTests = class
  private
    FDef: TFarPlaneDef;
    // How far an element moves on the screen while the city and the tunnel
    // ride ARide
    function Drift(const ADef: TFarPlaneDef; const AId: string; ARide: Double): Double;
    function LeftAt(const ADef: TFarPlaneDef; const AId: string; AOffset: Double): Double;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure TestOnTheBaseLineRidesWithItsLayer;
    [Test]
    procedure TestHalfwayToTheHorizonRidesAtHalfTheSpeed;
    [Test]
    procedure TestTheLowerTheFeetTheFaster;
    [Test]
    procedure TestOnTheHorizonStillRides;
    [Test]
    procedure TestCentreComesToTheMiddleAtAnyDepth;
    [Test]
    procedure TestHangingThingRidesByWhatItStandsOn;
    [Test]
    procedure TestWithoutACameraTheCityIsFlat;
    [Test]
    procedure TestOtherLayersRideFlat;
  end;

  [TestFixture]
  TFarPlaneShadeTests = class
  private
    FDef: TFarPlaneDef;
    FBand: TFarPlaneBand;
    function ShadeWithTunnelAt(AOffset: Double): Single;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure TestDarkWhileTheTunnelIsAllOnTheScreen;
    [Test]
    procedure TestFullOnceTheTunnelHasLeft;
    [Test]
    procedure TestBrightensAlongTheWay;
  end;

  [TestFixture]
  TFarPlaneReadTests = class
  public
    [Test]
    procedure TestLevelTwoReadsItsFarPlane;
    [Test]
    procedure TestNoSectionNoFarPlane;
    [Test]
    procedure TestAMissingLayoutRaises;
    [Test]
    procedure TestAnUnknownSpeedRaises;
    [Test]
    procedure TestAnElementWithoutWidthRaises;
    [Test]
    procedure TestLevelTwoReadsItsCityDepth;
    [Test]
    procedure TestACameraWithoutDepthRaises;
    [Test]
    procedure TestAFrameWithoutSizeRaises;
    [Test]
    procedure TestFramesWithoutACameraRaise;
  end;

implementation

uses
  System.IOUtils, System.JSON, System.Math,
  Levels.Defs;

const
  LevelTwoFile = 'level2.json';
  // The stand's timeline of its first tuning
  StandCityOpens = 4.9;
  StandTunnelGone = 22.0;
  StandBrakeBegins = 222.3;
  // A tick or so: the stand's ramp starts a tick earlier than the belt's
  StandSlack = 0.2;
  // The cliff's nearest notch and the left of the city's view on the stand
  CliffNearestNotch = 517;
  CityViewLeft = 400;
  LongChaseSeconds = 900;

function BinDir: string;
begin
  Result := ExtractFilePath(ParamStr(0));
end;

function ReadFromLayout(const ALayout: string): TFarPlaneDef;
begin
  var Dir := TPath.GetTempPath;
  var Name := 'moon2d-farplane-' + TGUID.NewGuid.ToString + '.json';
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

// The stand's first tuning: the tunnel fast past the cliff, then easing.
// ALayers - the layers after the city's.
const
  StandScreenSunSpeeds = '"screen": {"w": 512, "h": 384},'
    + '"sun": {"x": 288, "y": 208, "disc": 7, "halo": 120,'
    + ' "white": [255, 250, 240], "tint": [255, 128, 112], "tintRamp": 48},'
    + '"speeds": {"tunnelPeak": 30, "tunnelCruise": 14, "easeSec": 3,'
    + ' "cityShareInTunnel": 0.4, "cityCruise": 7, "cityBrakeZone": 512,'
    + ' "cityLeast": 0.3, "ridgeShareOfCity": 0.35, "ground": 14},';
  StandCamera = '"camera": {"horizon": 238, "baseY": 266, "focal": 1024},';
  StandFrames = '"frames": {"items": [{"id": "dome", "x": 468, "w": 512, "h": 170,'
    + ' "frequency": 4, "rib": 2.2, "tintsSun": true}]},';

function StandLayout(const ALayers: string): string;
begin
  Result := '{' + StandScreenSunSpeeds
    + '"layers": ['
    + '{"id": "city", "speed": "city", "length": 2688, "elements": ['
    + ' {"id": "dome-main", "x": 468, "y": 266, "w": 512, "tintsSun": true},'
    + ' {"id": "dome-sat", "x": 1300, "y": 262, "w": 320, "tintsSun": true}]}, '
    + ALayers + ']}';
end;

// A city in depth: buildings 40 units wide, all at x 600, their feet on the
// base line, halfway to the horizon, below the base line, on the horizon,
// and a beam hanging over the base line; a rock in the tunnel. ARoot - what
// goes before the layers (the camera, the frames)
function DepthLayout(const ARoot: string): string;
begin
  Result := '{' + StandScreenSunSpeeds + ARoot
    + '"layers": ['
    + '{"id": "city", "speed": "city", "length": 2688, "elements": ['
    + ' {"id": "base", "x": 600, "y": 266, "w": 40},'
    + ' {"id": "half", "x": 600, "y": 252, "w": 40},'
    + ' {"id": "near", "x": 600, "y": 280, "w": 40},'
    + ' {"id": "far", "x": 600, "y": 238, "w": 40},'
    + ' {"id": "beam", "x": 600, "y": 245, "w": 40, "groundY": 266}]},'
    + '{"id": "tunnel", "speed": "tunnel", "elements": ['
    + ' {"id": "rock", "x": 600, "y": 252, "w": 40}]}]}';
end;

function StandFarPlane: TFarPlaneDef;
begin
  Result := ReadFromLayout(StandLayout(
    '{"id": "tunnel", "speed": "tunnel", "elements": ['
    + ' {"id": "screen13", "x": 0, "y": 384, "w": 512, "existing": "screen13"},'
    + ' {"id": "cliff", "x": 400, "y": 384, "w": 228, "featherLeft": 64}]},'
    + '{"id": "ground", "speed": "ground", "band": {"texture": "sand-tex",'
    + ' "from": 520, "featherLeft": 48, "top": 276, "bottom": 384}}'));
end;

function ElementById(const ADef: TFarPlaneDef; const AId: string): TFarPlaneElement;
begin
  for var Layer in ADef.Layers do
    for var Element in Layer.Elements do
      if Element.Id = AId then
        Exit(Element);
  raise Exception.CreateFmt('No element "%s" in the layout', [AId]);
end;

// TFarPlaneTests

procedure TFarPlaneTests.Setup;
begin
  FDef := StandFarPlane;
  FBelt := TBelt.Create;
  FPlane := TFarPlane.Create(FDef);
end;

procedure TFarPlaneTests.TearDown;
begin
  FPlane.Free;
  FBelt.Free;
end;

procedure TFarPlaneTests.TickBoth;
begin
  FBelt.Tick;
  FPlane.Tick(FBelt.Speed / BeltCruise);
end;

procedure TFarPlaneTests.RunSeconds(ASeconds: Single);
begin
  for var i := 1 to Round(ASeconds * FarPlaneTicksPerSecond) do
    TickBoth;
end;

function TFarPlaneTests.SecondsUntil(ASeconds: Single;
  const ADone: TFunc<Boolean>): Single;
begin
  for var i := 1 to Round(ASeconds * FarPlaneTicksPerSecond) do
  begin
    TickBoth;
    if ADone() then
      Exit(i / FarPlaneTicksPerSecond);
  end;
  Result := -1;
end;

function TFarPlaneTests.CityLeft: Double;
begin
  Result := FDef.CityLength - FDef.ScreenWidth - FPlane.Offsets[fmCity];
end;

procedure TFarPlaneTests.TestStandsBeforeTheBelt;
begin
  for var i := 1 to 100 do
    TickBoth;
  Assert.AreEqual(0.0, FPlane.Offsets[fmTunnel], 0.0001, 'The tunnel stands');
  Assert.AreEqual(0.0, FPlane.Offsets[fmCity], 0.0001, 'The city stands');
  Assert.AreEqual(0.0, FPlane.Offsets[fmRidge], 0.0001, 'The ridge stands');
end;

procedure TFarPlaneTests.TestTheCityOpensAsOnTheStand;
begin
  FBelt.Start;
  var Took := SecondsUntil(30,
    function: Boolean
    begin
      Result := CliffNearestNotch - FPlane.Offsets[fmTunnel] < CityViewLeft;
    end);
  Assert.AreEqual(Double(StandCityOpens), Double(Took), StandSlack);
end;

procedure TFarPlaneTests.TestTheTunnelGoesAsOnTheStand;
begin
  FBelt.Start;
  var Took := SecondsUntil(40,
    function: Boolean
    begin
      Result := FDef.TunnelEnd - FPlane.Offsets[fmTunnel] < 0;
    end);
  Assert.AreEqual(Double(StandTunnelGone), Double(Took), StandSlack);
  Assert.IsFalse(FPlane.TunnelGone, 'Not gone on its last pixel');
  SecondsUntil(2,
    function: Boolean
    begin
      Result := FPlane.TunnelGone;
    end);
  Assert.IsTrue(FPlane.TunnelGone, 'Gone a little after');
end;

procedure TFarPlaneTests.TestEasesToCruise;
begin
  FBelt.Start;
  SecondsUntil(40,
    function: Boolean
    begin
      Result := FPlane.TunnelGone;
    end);
  Assert.AreEqual(Double(FDef.Speeds.TunnelPeak), Double(FPlane.TunnelSpeed), 0.01,
    'At its peak while the tunnel goes');
  RunSeconds(FDef.Speeds.EaseSec + 0.1);
  Assert.AreEqual(Double(FDef.Speeds.TunnelCruise), Double(FPlane.TunnelSpeed), 0.01,
    'The tunnel at cruise');
  Assert.AreEqual(Double(FDef.Speeds.CityCruise), Double(FPlane.CitySpeed), 0.01,
    'The city at cruise');
end;

procedure TFarPlaneTests.TestTheBrakeBeginsAsOnTheStand;
begin
  FBelt.Start;
  var Took := SecondsUntil(300,
    function: Boolean
    begin
      Result := CityLeft < FDef.Speeds.CityBrakeZone;
    end);
  Assert.AreEqual(Double(StandBrakeBegins), Double(Took), StandSlack);
end;

procedure TFarPlaneTests.TestTheStripNeverEndsInSight;
begin
  FBelt.Start;
  var Ended := SecondsUntil(LongChaseSeconds,
    function: Boolean
    begin
      Result := CityLeft < -0.001;
    end);
  Assert.AreEqual(-1.0, Double(Ended), 0.0001, 'Its end never passes the right edge');
  Assert.IsTrue(FPlane.CitySpeed < FDef.Speeds.CityCruise, 'It crawls at the end');
end;

procedure TFarPlaneTests.TestTheRidgeIsAShareOfTheCity;
begin
  FBelt.Start;
  RunSeconds(60);
  Assert.AreEqual(Double(FPlane.Offsets[fmCity] * FDef.Speeds.RidgeShareOfCity),
    FPlane.Offsets[fmRidge], 0.01);
end;

procedure TFarPlaneTests.TestTheGroundRunsAtItsSpeed;
const
  Seconds = 10;
begin
  FBelt.Start;
  RunSeconds(BeltRampTicks / FarPlaneTicksPerSecond + 1);
  var Before := FPlane.Offsets[fmGround];
  RunSeconds(Seconds);
  Assert.AreEqual(Double(FDef.Speeds.Ground * Seconds),
    FPlane.Offsets[fmGround] - Before, 0.01);
end;

procedure TFarPlaneTests.TestAStoppedBeltStandsIt;
begin
  FBelt.Start;
  SecondsUntil(300,
    function: Boolean
    begin
      Result := CityLeft < FDef.Speeds.CityBrakeZone / 2;
    end);
  FBelt.Stop;
  for var i := 1 to BeltRampTicks do
    TickBoth;
  var Stood := FPlane.Offsets;
  for var i := 1 to 100 do
    TickBoth;
  Assert.AreEqual(Stood[fmTunnel], FPlane.Offsets[fmTunnel], 0.0001, 'The tunnel');
  Assert.AreEqual(Stood[fmCity], FPlane.Offsets[fmCity], 0.0001,
    'The city, its brake floor no reason to crawl');
  Assert.AreEqual(Stood[fmGround], FPlane.Offsets[fmGround], 0.0001, 'The ground');
end;

procedure TFarPlaneTests.TestBetweenTicksLiesBetweenThem;
begin
  FBelt.Start;
  for var i := 1 to 100 do
    TickBoth;
  var Before := FPlane.Offsets;
  TickBoth;
  var After := FPlane.Offsets;
  var Halfway := FPlane.OffsetsAt(0.5);
  for var Motion := Low(TFarPlaneMotion) to High(TFarPlaneMotion) do
    Assert.AreEqual(Double((Before[Motion] + After[Motion]) / 2), Halfway[Motion], 0.0001);
end;

procedure TFarPlaneTests.TestClearGoesBackToTheStart;
begin
  FBelt.Start;
  SecondsUntil(40,
    function: Boolean
    begin
      Result := FPlane.TunnelGone;
    end);
  FPlane.Clear;
  Assert.IsFalse(FPlane.TunnelGone, 'The tunnel back');
  for var Motion := Low(TFarPlaneMotion) to High(TFarPlaneMotion) do
  begin
    Assert.AreEqual(0.0, FPlane.Offsets[Motion], 0.0001, 'At the start');
    Assert.AreEqual(0.0, FPlane.OffsetsAt(0.5)[Motion], 0.0001, 'Between ticks too');
  end;
end;

procedure TFarPlaneTests.TestNoFarPlaneNeverMoves;
begin
  var Plane := TFarPlane.Create(Default(TFarPlaneDef));
  try
    for var i := 1 to 100 do
      Plane.Tick(1);
    Assert.AreEqual(0.0, Plane.Offsets[fmTunnel], 0.0001);
  finally
    Plane.Free;
  end;
end;

// TFarPlaneSunTests

procedure TFarPlaneSunTests.Setup;
begin
  FDef := StandFarPlane;
end;

function TFarPlaneSunTests.DomeInside(AUnits: Single): TFarPlaneOffsets;
begin
  Result := Default(TFarPlaneOffsets);
  Result[fmCity] := ElementById(FDef, 'dome-main').X - FDef.Sun.X + AUnits;
end;

procedure TFarPlaneSunTests.TestWhiteWithNoDomeBeforeIt;
begin
  Assert.AreEqual(0.0, Double(FDef.SunCover(Default(TFarPlaneOffsets))), 0.0001);
end;

procedure TFarPlaneSunTests.TestTintedDeepInsideADome;
begin
  var Cover := FDef.SunCover(DomeInside(ElementById(FDef, 'dome-main').W / 2));
  Assert.AreEqual(1.0, Double(Cover), 0.0001);
end;

procedure TFarPlaneSunTests.TestRampedInAtTheDomesEdge;
begin
  var Cover := FDef.SunCover(DomeInside(FDef.Sun.TintRamp / 2));
  Assert.AreEqual(0.5, Double(Cover), 0.0001);
end;

procedure TFarPlaneSunTests.TestTintedDeepInsideAFrame;
begin
  var Def := ReadFromLayout(DepthLayout(StandCamera + StandFrames));
  var Offsets := Default(TFarPlaneOffsets);
  Offsets[fmCity] := Def.Frames[0].X + Def.Frames[0].W / 2 - Def.Sun.X;
  Assert.AreEqual(1.0, Double(Def.SunCover(Offsets)), 0.0001, 'Deep inside it');
  Assert.AreEqual(0.0, Double(Def.SunCover(Default(TFarPlaneOffsets))), 0.0001,
    'Before it comes');
end;

// TFarPlaneDepthTests

const
  Ride = 50;
  DepthSlack = 0.0001;

procedure TFarPlaneDepthTests.Setup;
begin
  FDef := ReadFromLayout(DepthLayout(StandCamera));
end;

function TFarPlaneDepthTests.LeftAt(const ADef: TFarPlaneDef; const AId: string;
  AOffset: Double): Double;
begin
  var Offsets := Default(TFarPlaneOffsets);
  Offsets[fmCity] := AOffset;
  Offsets[fmTunnel] := AOffset;
  for var Layer in ADef.Layers do
    for var Element in Layer.Elements do
      if Element.Id = AId then
        Exit(ADef.ElementLeft(Layer, Element, Offsets));
  raise Exception.CreateFmt('No element "%s" in the layout', [AId]);
end;

function TFarPlaneDepthTests.Drift(const ADef: TFarPlaneDef; const AId: string;
  ARide: Double): Double;
begin
  Result := LeftAt(ADef, AId, ARide) - LeftAt(ADef, AId, 0);
end;

procedure TFarPlaneDepthTests.TestOnTheBaseLineRidesWithItsLayer;
begin
  Assert.AreEqual(Double(-Ride), Drift(FDef, 'base', Ride), DepthSlack);
end;

procedure TFarPlaneDepthTests.TestHalfwayToTheHorizonRidesAtHalfTheSpeed;
begin
  Assert.AreEqual(Double(-Ride / 2), Drift(FDef, 'half', Ride), DepthSlack);
end;

procedure TFarPlaneDepthTests.TestTheLowerTheFeetTheFaster;
begin
  Assert.IsTrue(Drift(FDef, 'near', Ride) < Drift(FDef, 'base', Ride), 'Below the base line');
  Assert.IsTrue(Drift(FDef, 'base', Ride) < Drift(FDef, 'half', Ride), 'On it');
  Assert.IsTrue(Drift(FDef, 'half', Ride) < Drift(FDef, 'far', Ride), 'Halfway');
end;

procedure TFarPlaneDepthTests.TestOnTheHorizonStillRides;
begin
  Assert.IsTrue(Drift(FDef, 'far', Ride) < 0);
end;

procedure TFarPlaneDepthTests.TestCentreComesToTheMiddleAtAnyDepth;
const
  ElementCentre = 620;
  HalfWidth = 20;
  Depths: array [0..2] of string = ('half', 'near', 'far');
begin
  var Middle: Double := FDef.ScreenWidth / 2;
  var Arrived: Double := ElementCentre - Middle;
  for var Id in Depths do
    Assert.AreEqual(Double(Middle), LeftAt(FDef, Id, Arrived) + HalfWidth, DepthSlack, Id);
end;

procedure TFarPlaneDepthTests.TestHangingThingRidesByWhatItStandsOn;
begin
  Assert.AreEqual(Drift(FDef, 'base', Ride), Drift(FDef, 'beam', Ride), DepthSlack);
end;

procedure TFarPlaneDepthTests.TestWithoutACameraTheCityIsFlat;
begin
  var Flat := ReadFromLayout(DepthLayout(''));
  Assert.AreEqual(Double(-Ride), Drift(Flat, 'half', Ride), DepthSlack, 'Halfway');
  Assert.AreEqual(Double(-Ride), Drift(Flat, 'near', Ride), DepthSlack, 'Below the base line');
end;

procedure TFarPlaneDepthTests.TestOtherLayersRideFlat;
begin
  Assert.AreEqual(Double(-Ride), Drift(FDef, 'rock', Ride), DepthSlack);
end;

// TFarPlaneShadeTests

const
  DarkInTunnel = 0.3;

procedure TFarPlaneShadeTests.Setup;
begin
  FDef := StandFarPlane;
  FBand := FDef.Layers[High(FDef.Layers)].Band;
  FBand.ShadeInTunnel := DarkInTunnel;
end;

function TFarPlaneShadeTests.ShadeWithTunnelAt(AOffset: Double): Single;
begin
  var Offsets := Default(TFarPlaneOffsets);
  Offsets[fmTunnel] := AOffset;
  Result := FDef.BandShade(FBand, Offsets);
end;

procedure TFarPlaneShadeTests.TestDarkWhileTheTunnelIsAllOnTheScreen;
begin
  Assert.AreEqual(Double(DarkInTunnel), Double(ShadeWithTunnelAt(0)), 0.0001);
end;

procedure TFarPlaneShadeTests.TestFullOnceTheTunnelHasLeft;
begin
  Assert.AreEqual(1.0, Double(ShadeWithTunnelAt(FDef.TunnelEnd)), 0.0001, 'As it leaves');
  Assert.AreEqual(1.0, Double(ShadeWithTunnelAt(FDef.TunnelEnd * 3)), 0.0001, 'And after');
end;

procedure TFarPlaneShadeTests.TestBrightensAlongTheWay;
begin
  var Halfway := ShadeWithTunnelAt(FDef.TunnelEnd / 2);
  Assert.AreEqual(Double((DarkInTunnel + 1) / 2), Double(Halfway), 0.0001);
end;

// TFarPlaneReadTests

procedure TFarPlaneReadTests.TestLevelTwoReadsItsFarPlane;
begin
  var Level := TLevel.Create;
  try
    Level.LoadFromFile(TPath.Combine(BinDir, LevelTwoFile));
    var Plane := Level.FarPlane;
    Assert.AreEqual(13, Plane.Screen, 'The boss arena');
    Assert.AreEqual('chase-backdrop', Plane.SetName, 'The set named by the layout');
    Assert.AreEqual(4, Integer(Length(Plane.Layers)), 'Ridge, city, tunnel, ground');
    Assert.AreEqual(2688.0, Double(Plane.CityLength), 0.0001, 'The city layer');
    Assert.AreEqual(628.0, Double(Plane.TunnelEnd), 0.0001, 'The cliff ends it');
    Assert.IsTrue(ElementById(Plane, 'screen13').Backdrop, 'The wall of 13 rides in it');
    var Ground := Plane.Layers[High(Plane.Layers)];
    Assert.IsTrue(Ground.Motion = fmGround, 'The near ground in front');
    Assert.IsTrue(Ground.Band.From < 0, 'It stands from the start of the arena');
    Assert.IsTrue(Ground.Band.ShadeInTunnel < 1, 'Dark in the tunnel');
    Assert.IsFalse(ElementById(Plane, 'land-03').Backdrop, 'The city built of the kit''s buildings');
  finally
    Level.Free;
  end;
end;

procedure TFarPlaneReadTests.TestNoSectionNoFarPlane;
begin
  var Root := TJSONObject.Create;
  try
    Assert.IsFalse(ReadFarPlane(Root, 'test', BinDir).Present);
  finally
    Root.Free;
  end;
end;

procedure TFarPlaneReadTests.TestAMissingLayoutRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      var Root := TJSONObject.ParseJSONValue(
        '{"farPlane": {"screen": 1, "layout": "no-such-layout.json"}}') as TJSONObject;
      try
        ReadFarPlane(Root, 'test', BinDir);
      finally
        Root.Free;
      end;
    end, EFarPlaneError);
end;

procedure TFarPlaneReadTests.TestAnUnknownSpeedRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      ReadFromLayout(StandLayout('{"id": "near", "speed": "warp"}'));
    end, EFarPlaneError);
end;

procedure TFarPlaneReadTests.TestAnElementWithoutWidthRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      ReadFromLayout(StandLayout('{"id": "tunnel", "speed": "tunnel", '
        + '"elements": [{"id": "rock", "x": 0, "y": 384, "w": 0}]}'));
    end, EFarPlaneError);
end;

procedure TFarPlaneReadTests.TestLevelTwoReadsItsCityDepth;
begin
  var Level := TLevel.Create;
  try
    Level.LoadFromFile(TPath.Combine(BinDir, LevelTwoFile));
    var Plane := Level.FarPlane;
    Assert.IsTrue(Plane.Camera.Present, 'A camera');
    Assert.IsTrue(Plane.Camera.BaseY > Plane.Camera.Horizon, 'Its base line below its horizon');
    Assert.IsTrue(Length(Plane.Frames) > 0, 'Dome frames');
    var Tints := False;
    for var Frame in Plane.Frames do
      Tints := Tints or Frame.TintsSun;
    Assert.IsTrue(Tints, 'A frame turns the sun');
    var Hangs := False;
    for var Layer in Plane.Layers do
      for var Element in Layer.Elements do
        Hangs := Hangs or (Element.DepthY > Element.Y);
    Assert.IsTrue(Hangs, 'The monorail''s beam hangs over the feet of its pylons');
  finally
    Level.Free;
  end;
end;

procedure TFarPlaneReadTests.TestACameraWithoutDepthRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      ReadFromLayout(DepthLayout('"camera": {"horizon": 266, "baseY": 266, "focal": 1024},'));
    end, EFarPlaneError);
end;

procedure TFarPlaneReadTests.TestAFrameWithoutSizeRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      ReadFromLayout(DepthLayout(StandCamera
        + '"frames": {"items": [{"id": "dome", "x": 468, "w": 0, "h": 170}]},'));
    end, EFarPlaneError);
end;

procedure TFarPlaneReadTests.TestFramesWithoutACameraRaise;
begin
  Assert.WillRaise(
    procedure
    begin
      ReadFromLayout(DepthLayout(StandFrames));
    end, EFarPlaneError);
end;

initialization
  TDUnitX.RegisterTestFixture(TFarPlaneTests);
  TDUnitX.RegisterTestFixture(TFarPlaneSunTests);
  TDUnitX.RegisterTestFixture(TFarPlaneDepthTests);
  TDUnitX.RegisterTestFixture(TFarPlaneShadeTests);
  TDUnitX.RegisterTestFixture(TFarPlaneReadTests);

end.
