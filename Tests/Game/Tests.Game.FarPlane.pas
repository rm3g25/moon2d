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
  it, then takes the dome's tint - a frame drawn by code as well. Its glare
  is whole without a farm, and gives way to the farm's glass as the farm's
  dome takes the disc, by the tint's ramp. A band
  dark in the tunnel brightens to the full as the tunnel leaves. The city
  has a depth by the feet: a building on the domes' base line rides with
  its layer, one halfway to the horizon at half its speed, the lower the
  feet the faster; every one comes to the middle of the screen when its
  layer has ridden its centre there; a thing hanging in the air rides by
  what it stands on; without a camera the city is flat, and the other
  layers are flat always. The city's clock stands until the road first
  moves, counts its ticks from there, runs on when the road stops, and a
  clear sets it back; between ticks it lies between them, as the offsets
  do. Level 2 reads its far plane, its camera and frames among it, the
  life of its city, its train on a line with a run and its searchlights
  in the main dome, and rides on to stand with the emblem's spire over the
  middle of the screen, as a restart past the bunker asks - where the
  middles of the buildings on the screen are the points the rite of the
  eclipse calls its orbs out of, the spire's among them and none off the
  screen; a layout that does not make sense raises, and so does
  a city's life that cannot play - a train and the searchlights among
  them. Level 2 reads its farm under a capsule; a frame of an unknown kind,
  a capsule of odd rows or deeper than long, and a farm under a dome raise.

  Under the titles' eye the layers have a depth by their speeds - the city
  1, the ridge its share, the near ground and the fangs theirs over the
  city's cruise, the tunnel none, the play layer the road's - and the
  eye's ride carries each by it; no ride, and the offsets are the same to
  the bit. The crater floor is cut into slabs from its band's top to its
  foot; unridden, every slab stands where the band stood; ridden, a slab
  goes by the nearness of its middle and none slower than the ridge;
  without a camera the floor is one sheet. The floor's far edge sharpens
  over the flight's first seconds, and one sharper than that stays.

  Lifted and pushed, the eye sees every layer nearer, as the stand has it
  16 s into the flight, and one it has passed not at all; at its rest it
  carries nothing, to the bit. A carried place stands where the stand has
  it. The floor's band melts as the stand's does, grows down from the
  horizon, its slabs start where the stand's rows do, and behind the eye
  it has none. A dome takes less of the sun for an eye pushed toward it; a
  frame's point stands where the stand projects it, and one at the eye is
  not seen. Level 2 reads its plane; a plane is read as written, and one
  without a camera, with a floor that melts over nothing or is cut into
  no slabs raises. Till the titles' path is flown to, no frame of level 2
  comes so near the eye that a rib would be dropped.

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
    [Test]
    procedure TestTheClockStandsBeforeTheRoad;
    [Test]
    procedure TestTheClockCountsFromTheRoadsFirstTick;
    [Test]
    procedure TestTheClockRunsOnWhenTheRoadStops;
    [Test]
    procedure TestClearSetsTheClockBack;
    [Test]
    procedure TestTheClockBetweenTicksLiesBetweenThem;
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
    [Test]
    procedure TestGlareWholeWithoutAFarm;
    [Test]
    procedure TestGlareGivesWayToTheFarmsDome;
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
  TFarPlaneEyeTests = class
  private
    FDef: TFarPlaneDef;
    FFloor: TFarPlaneBand;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure TestALayerStandsAsNearAsItsSpeedSays;
    [Test]
    procedure TestWithoutARoadThePlayLayerHasNoDepth;
    [Test]
    procedure TestNoRideAndTheOffsetsAreTheSame;
    [Test]
    procedure TestTheRideCarriesEachLayerByItsNearness;
    [Test]
    procedure TestTheFloorIsCutIntoSlabsToItsFoot;
    [Test]
    procedure TestUnriddenEverySlabStandsWhereTheBandStood;
    [Test]
    procedure TestASlabRidesByTheNearnessOfItsMiddle;
    [Test]
    procedure TestNoSlabRidesSlowerThanTheRidge;
    [Test]
    procedure TestWithoutACameraTheFloorIsOneSheet;
    [Test]
    procedure TestTheFloorsEdgeSharpensOverTheFirstSeconds;
    [Test]
    procedure TestAnEdgeSharperThanTheLineStays;
    [Test]
    procedure TestAtItsRestTheEyeCarriesNothing;
    [Test]
    procedure TestThePushBringsEveryLayerNearer;
    [Test]
    procedure TestALayerTheEyeHasPassedIsNotSeen;
    [Test]
    procedure TestACarriedPlaceStandsWhereTheStandHasIt;
    [Test]
    procedure TestTheFloorMeltsAsTheEyeLeavesItsRest;
    [Test]
    procedure TestTheFloorGrowsDownFromTheHorizon;
    [Test]
    procedure TestUnderTheEyeTheSlabsStartWhereTheStandsDo;
    [Test]
    procedure TestBehindTheEyeTheFloorHasNoSlabs;
    [Test]
    procedure TestThePushedEyeSeesADomeTakeLessOfTheSun;
    [Test]
    procedure TestTheEyeSeesAFramesPointWhereTheStandHasIt;
    [Test]
    procedure TestAFramesPointAtTheEyeIsNotSeen;
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
    [Test]
    procedure TestLevelTwoReadsItsCityLife;
    [Test]
    procedure TestRidesToTheEmblemOverTheMiddle;
    [Test]
    procedure TestUnderTheEmblemTheCityGivesItsPointsOnTheScreen;
    [Test]
    procedure TestALightOfAnUnknownKindRaises;
    [Test]
    procedure TestALightWithoutABoxRaises;
    [Test]
    procedure TestASpanOfNoTicksRaises;
    [Test]
    procedure TestAPaintWithoutWidthRaises;
    [Test]
    procedure TestAnEmblemWithoutPartsRaises;
    [Test]
    procedure TestAnEmblemWithAHaloShortRaises;
    [Test]
    procedure TestLampsWithoutBeaconsRaise;
    [Test]
    procedure TestFrameBeaconsWithoutBeaconsRaise;
    [Test]
    procedure TestAnEmblemWithoutCityLightsRaises;
    [Test]
    procedure TestLevelTwoReadsItsTrain;
    [Test]
    procedure TestATrainWithoutTwoStationsRaises;
    [Test]
    procedure TestATrainWithoutACruiseRaises;
    [Test]
    procedure TestADwellOfNoTicksRaises;
    [Test]
    procedure TestLevelTwoReadsItsSearchlights;
    [Test]
    procedure TestSearchlightsReadTheirLamps;
    [Test]
    procedure TestSearchlightsWithoutATailRaise;
    [Test]
    procedure TestSearchlightsWithoutAnEaseRaise;
    [Test]
    procedure TestASearchlightWithOneSweepRaises;
    [Test]
    procedure TestLevelTwoReadsItsFarm;
    [Test]
    procedure TestACapsuleAndItsFarmRead;
    [Test]
    procedure TestAFrameOfAnUnknownKindRaises;
    [Test]
    procedure TestACapsuleOfOddRowsRaises;
    [Test]
    procedure TestACapsuleDeeperThanLongRaises;
    [Test]
    procedure TestAFarmUnderADomeRaises;
    [Test]
    procedure TestLevelTwoReadsItsPlane;
    [Test]
    procedure TestThePlaneIsReadAsWritten;
    [Test]
    procedure TestAPlaneWithoutACameraRaises;
    [Test]
    procedure TestAFloorThatMeltsOverNothingRaises;
    [Test]
    procedure TestAFloorCutIntoNoSlabsRaises;
    [Test]
    procedure TestTillItIsFlownNoFrameStandsAtTheEye;
  end;

implementation

uses
  System.IOUtils, System.JSON, System.Math, Sdl2.Core,
  Levels.Defs, Levels.Monorail, Levels.Searchlights;

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

// The titles' eye at its rest: the chase's own
function RestEye: TFarPlaneEye;
begin
  Result := Default(TFarPlaneEye);
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

// The layout's farm of the day the tests were written, under its capsule;
// its one greenhouse is the depth layout's "base"
const
  CapsuleFrames = '"frames": {"items": [{"id": "dome-farm", "kind": "capsule",'
    + ' "x": 2290, "w": 640, "d": 220, "h": 90, "rows": 12, "cells": 16,'
    + ' "beltEvery": 4, "capCells": 5, "rib": 0.85, "tintsSun": true}]},';
  FarmSection = '"farm": {"frame": "dome-farm", "glareKeep": 0.3,'
    + ' "glow": {"level": 1, "spanTicks": [900, 2400], "onShare": 0.85, "warmTicks": 90,'
    + ' "flickerTicks": 12},'
    + ' "air": {"reach": 40, "level": 0.07, "ribLevel": 0.1},'
    + ' "apron": {"length": 160, "level": 0.2, "gap": 1.2},'
    + ' "glass": {"base": {"color": [255, 105, 176], "at": [0.5, 0.5], "share": 0.4}}},';
  FarmGlareKeep = 0.3;

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

procedure TFarPlaneTests.TestTheClockStandsBeforeTheRoad;
begin
  for var i := 1 to 100 do
    TickBoth;
  Assert.AreEqual(0, FPlane.Clock);
end;

procedure TFarPlaneTests.TestTheClockCountsFromTheRoadsFirstTick;
const
  Waited = 50;
  Ridden = 100;
begin
  for var i := 1 to Waited do
    TickBoth;
  FBelt.Start;
  for var i := 1 to Ridden do
    TickBoth;
  Assert.AreEqual(Ridden + 1, FPlane.Clock,
    'The ticks before the road do not count; the stand''s standing first one does');
end;

procedure TFarPlaneTests.TestTheClockRunsOnWhenTheRoadStops;
const
  Stood = 100;
begin
  FBelt.Start;
  RunSeconds(10);
  FBelt.Stop;
  for var i := 1 to BeltRampTicks do
    TickBoth;
  var Before := FPlane.Clock;
  for var i := 1 to Stood do
    TickBoth;
  Assert.AreEqual(Before + Stood, FPlane.Clock, 'The city lives on');
end;

procedure TFarPlaneTests.TestTheClockBetweenTicksLiesBetweenThem;
begin
  Assert.AreEqual(0.0, FPlane.ClockAt(0.5), 1E-9, 'Nothing before the road');
  FBelt.Start;
  RunSeconds(2);
  var Clock: Double := FPlane.Clock;
  Assert.AreEqual(Clock - 1, FPlane.ClockAt(0), 1E-9, 'The last tick, as OffsetsAt(0)');
  Assert.AreEqual(Clock - 0.5, FPlane.ClockAt(0.5), 1E-9, 'Halfway');
  Assert.AreEqual(Clock, FPlane.ClockAt(1), 1E-9, 'This tick, as OffsetsAt(1)');
end;

procedure TFarPlaneTests.TestClearSetsTheClockBack;
begin
  FBelt.Start;
  RunSeconds(10);
  FPlane.Clear;
  Assert.AreEqual(0, FPlane.Clock, 'Back to the start');
  for var i := 1 to 10 do
    FPlane.Tick(0);
  Assert.AreEqual(0, FPlane.Clock, 'Standing until the road moves again');
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
  Assert.AreEqual(0.0, Double(FDef.SunCover(Default(TFarPlaneOffsets), RestEye)), 0.0001);
end;

procedure TFarPlaneSunTests.TestTintedDeepInsideADome;
begin
  var Cover := FDef.SunCover(DomeInside(ElementById(FDef, 'dome-main').W / 2), RestEye);
  Assert.AreEqual(1.0, Double(Cover), 0.0001);
end;

procedure TFarPlaneSunTests.TestRampedInAtTheDomesEdge;
begin
  var Cover := FDef.SunCover(DomeInside(FDef.Sun.TintRamp / 2), RestEye);
  Assert.AreEqual(0.5, Double(Cover), 0.0001);
end;

procedure TFarPlaneSunTests.TestTintedDeepInsideAFrame;
begin
  var Def := ReadFromLayout(DepthLayout(StandCamera + StandFrames));
  var Offsets := Default(TFarPlaneOffsets);
  Offsets[fmCity] := Def.Frames[0].X + Def.Frames[0].W / 2 - Def.Sun.X;
  Assert.AreEqual(1.0, Double(Def.SunCover(Offsets, RestEye)), 0.0001, 'Deep inside it');
  Assert.AreEqual(0.0, Double(Def.SunCover(Default(TFarPlaneOffsets), RestEye)), 0.0001,
    'Before it comes');
end;

procedure TFarPlaneSunTests.TestGlareWholeWithoutAFarm;
begin
  var Inside := DomeInside(ElementById(FDef, 'dome-main').W / 2);
  Assert.AreEqual(1.0, Double(FDef.GlareLevel(Inside, RestEye)), 0.0001);
end;

procedure TFarPlaneSunTests.TestGlareGivesWayToTheFarmsDome;
begin
  var Def := ReadFromLayout(DepthLayout(StandCamera + CapsuleFrames + FarmSection));
  var Offsets := Default(TFarPlaneOffsets);
  Assert.AreEqual(1.0, Double(Def.GlareLevel(Offsets, RestEye)), 0.0001, 'Before it comes');
  Offsets[fmCity] := Def.Frames[0].X + Def.Frames[0].W / 2 - Def.Sun.X;
  Assert.AreEqual(FarmGlareKeep, Double(Def.GlareLevel(Offsets, RestEye)), 0.0001,
    'Deep inside it');
  Offsets[fmCity] := Def.Frames[0].X - Def.Sun.X + Def.Sun.TintRamp / 2;
  Assert.AreEqual(1 - (1 - FarmGlareKeep) / 2, Double(Def.GlareLevel(Offsets, RestEye)), 0.0001,
    'Halfway up the ramp');
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

// TFarPlaneEyeTests

const
  // The shipped layout's speeds and floor of the day the tests were written
  EyeSpeeds = '"speeds": {"road": 33, "tunnelPeak": 6, "tunnelCruise": 6, "easeSec": 3,'
    + ' "cityShareInTunnel": 0.5, "cityCruise": 3, "cityBrakeZone": 512,'
    + ' "cityLeast": 0.3, "ridgeShareOfCity": 0.35, "ground": 14, "fangs": 20},';
  EyeFloor = '"band": {"texture": "floor-tex", "fadeTop": 16, "top": 238, "bottom": 320}';
  // And its plane, with its comma
  EyePlane = '"plane": {"tile": "ground-top", "tileUnits": 448, "gain": 1.25, "levels": 8,'
    + ' "wideLevels": 2, "far": [1500, 3000], "farShade": 0.45, "mean": [38, 36, 36],'
    + ' "floor": {"meltLift": [2, 14], "meltPush": [30, 200], "slabDeep": 6,'
    + ' "slabFeather": 2, "sharpSeconds": 4, "sharpFade": 1.5, "foot": [20, 21, 25]}},';
  FloorSlabDeep = 6;
  FloorSharpSeconds = 4;
  FloorSharpFade = 1.5;
  FloorDeep = 82;
  FloorSlabCount = 14;
  FloorOwnFade = 16;
  RidgeShare = 0.35;
  GroundNearness = 14 / 3;
  FangNearness = 20 / 3;
  RoadNearness = 11;
  // The camera's eye over the floor: its base line under its horizon
  EyeHeight = 28;
  // The shares are a Single's
  ShareSlack = 0.00001;
  RideSlack = 0.001;
  Horizon = 238;
  FloorFoot = 320;
  Focal = 1024;
  // The city's offset where the world stood after a fight of 220 s, the
  // eye at 2412 along the strip
  StandCity = 2156;
  // The eye of the stand 16 s into the flight from there: its ride, its
  // lift, its push
  StandRide = -1374.124500353776;
  StandLift = 5.987421179872983;
  StandPush = 93.15872323809313;
  // How near the stand has the layers under that eye
  StandCityNearness = 1.100080137789078;
  StandRidgeNearness = 0.36151100213717574;
  StandGroundNearness = 8.109616148863141;
  StandFangNearness = 16.942064345096302;
  // Where it has the place 600, 200 of the domes' base line and the place
  // 100, 300 of the near ground
  StandBaseX = 634.4275673994429;
  StandBaseY = 202.78359788057094;
  StandGroundX = -15.09288269056782;
  StandGroundY = 394.2977306109534;
  // How much of itself the floor's band keeps there, and half a second
  // earlier (lifted 3.77, pushed 54.26)
  StandKeep = 0.5109434647847241;
  EarlierLift = 3.767485695286531;
  EarlierPush = 54.260257434837584;
  EarlierKeep = 0.8892684565329658;
  // How far the band is stretched down from the horizon, where its foot
  // lies, and where the slabs 0, 2 and 10 start on the screen
  StandStretch = 1.3353173919517893;
  StandFoot = 347.4960261400467;
  StandSlabStarts: array [0..2] of Double = (-1900.6321671631167, -1587.5823621569723,
    1003.8126144519365);
  StandSlabs: array [0..2] of Integer = (0, 2, 10);
  // Where the stand has the point 30, 80, -120 of the main dome under
  // that eye, and how near
  StandFrameX = -102.50236041090227;
  StandFrameY = 179.89136386843649;
  StandFrameNearness = 1.2628858808093022;

// ACamera - that section with its comma, or none
function EyeLayout(const ACamera: string): string;
begin
  Result := '{"screen": {"w": 512, "h": 384},'
    + '"sun": {"x": 288, "y": 208, "disc": 7, "halo": 120,'
    + ' "white": [255, 250, 240], "tint": [255, 128, 112], "tintRamp": 48},'
    + EyeSpeeds + ACamera
    + '"layers": [{"id": "city", "speed": "city", "length": 2688, ' + EyeFloor + '}]}';
end;

// The far plane at a stand with the city ridden ACity
function StandingAt(ACity: Double): TFarPlaneOffsets;
begin
  Result[fmRidge] := ACity * RidgeShare;
  Result[fmCity] := ACity;
  Result[fmTunnel] := 4000;
  Result[fmGround] := 9000;
  Result[fmFangs] := 12000;
end;

// The eye at its rest, flown ARide along the strip
function Riding(ARide: Double): TFarPlaneEye;
begin
  Result := Default(TFarPlaneEye);
  Result.Flying := True;
  Result.Ride := ARide;
end;

function Lifted(ALift, APush: Double): TFarPlaneEye;
begin
  Result := Riding(StandRide);
  Result.Lift := ALift;
  Result.Push := APush;
end;

function StandEye: TFarPlaneEye;
begin
  Result := Lifted(StandLift, StandPush);
end;

procedure TFarPlaneEyeTests.Setup;
begin
  FDef := ReadFromLayout(EyeLayout(StandCamera + EyePlane));
  FFloor := FDef.Layers[0].Band;
end;

procedure TFarPlaneEyeTests.TestALayerStandsAsNearAsItsSpeedSays;
begin
  Assert.IsTrue(Abs(FDef.MotionNearness(fmCity) - 1) < ShareSlack, 'The city');
  Assert.IsTrue(Abs(FDef.MotionNearness(fmRidge) - RidgeShare) < ShareSlack, 'The ridge');
  Assert.IsTrue(Abs(FDef.MotionNearness(fmGround) - GroundNearness) < ShareSlack,
    'The near ground');
  Assert.IsTrue(Abs(FDef.MotionNearness(fmFangs) - FangNearness) < ShareSlack, 'The fangs');
  Assert.IsTrue(Abs(FDef.MotionNearness(fmTunnel)) < ShareSlack, 'The tunnel: long gone');
  Assert.IsTrue(Abs(FDef.PlayNearness - RoadNearness) < ShareSlack, 'The play layer');
end;

procedure TFarPlaneEyeTests.TestWithoutARoadThePlayLayerHasNoDepth;
begin
  var Def := ReadFromLayout(DepthLayout(StandCamera));
  Assert.IsTrue(Abs(Def.PlayNearness) < ShareSlack, 'The eye does not carry it');
end;

procedure TFarPlaneEyeTests.TestNoRideAndTheOffsetsAreTheSame;
begin
  var Stands := StandingAt(2156.25);
  var Carried := FDef.Ridden(Stands, 0);
  for var Motion := Low(TFarPlaneMotion) to High(TFarPlaneMotion) do
    Assert.IsTrue(Carried[Motion] = Stands[Motion], 'To the bit');
end;

procedure TFarPlaneEyeTests.TestTheRideCarriesEachLayerByItsNearness;
const
  Way = -300;
begin
  var Stands := StandingAt(2156);
  var Carried := FDef.Ridden(Stands, Way);
  var City: Double := Carried[fmCity] - Stands[fmCity];
  var Ridge: Double := Carried[fmRidge] - Stands[fmRidge];
  var Ground: Double := Carried[fmGround] - Stands[fmGround];
  var Fangs: Double := Carried[fmFangs] - Stands[fmFangs];
  Assert.IsTrue(Abs(City - Way) < RideSlack, 'The city: the ride');
  Assert.IsTrue(Abs(Ridge - Way * RidgeShare) < RideSlack, 'The ridge: its share');
  Assert.IsTrue(Abs(Ground - Way * GroundNearness) < RideSlack, 'The near ground');
  Assert.IsTrue(Abs(Fangs - Way * FangNearness) < RideSlack, 'The fangs');
  Assert.IsTrue(Carried[fmTunnel] = Stands[fmTunnel], 'The tunnel stands');
end;

procedure TFarPlaneEyeTests.TestTheFloorIsCutIntoSlabsToItsFoot;
begin
  var Slabs := FDef.FloorSlabs(FFloor, 2156, Riding(-100));
  Assert.AreEqual(FloorSlabCount, Integer(Length(Slabs)), 'As many as the band is deep');
  var Top: Double := Slabs[0].Top;
  Assert.IsTrue(Abs(Top) < ShareSlack, 'From the band''s top');
  for var i := 0 to High(Slabs) - 1 do
  begin
    var Deep: Double := Slabs[i].Bottom - Slabs[i].Top;
    var Gap: Double := Slabs[i + 1].Top - Slabs[i].Bottom;
    Assert.IsTrue(Abs(Deep - FloorSlabDeep) < ShareSlack, 'A slab deep');
    Assert.IsTrue(Abs(Gap) < ShareSlack, 'One where the other ends');
  end;
  var Foot: Double := Slabs[High(Slabs)].Bottom;
  Assert.IsTrue(Abs(Foot - FloorDeep) < ShareSlack, 'The last cut at the band''s foot');
end;

procedure TFarPlaneEyeTests.TestUnriddenEverySlabStandsWhereTheBandStood;
const
  City = 2156.25;
begin
  for var Slab in FDef.FloorSlabs(FFloor, City, Riding(0)) do
    Assert.IsTrue(Slab.Offset = City, 'To the bit');
end;

// A ride of one eye's height: a slab goes the depth of its middle under
// the horizon
procedure TFarPlaneEyeTests.TestASlabRidesByTheNearnessOfItsMiddle;
const
  City = 2156;
  Third = 2;
  ThirdMiddle = 15;
  LastMiddle = 81;
begin
  var Slabs := FDef.FloorSlabs(FFloor, City, Riding(-EyeHeight));
  Assert.IsTrue(Abs(Slabs[Third].Offset - (City - ThirdMiddle)) < RideSlack, 'The third');
  Assert.IsTrue(Abs(Slabs[High(Slabs)].Offset - (City - LastMiddle)) < RideSlack,
    'The last, by the middle it would have whole');
  for var i := Third to High(Slabs) - 1 do
    Assert.IsTrue(Slabs[i + 1].Offset < Slabs[i].Offset, 'The nearer overtakes the farther');
end;

procedure TFarPlaneEyeTests.TestNoSlabRidesSlowerThanTheRidge;
const
  City = 2156;
  Way = -280;
begin
  var Slabs := FDef.FloorSlabs(FFloor, City, Riding(Way));
  var WithTheRidge: Double := City + Way * RidgeShare;
  Assert.IsTrue(Abs(Slabs[0].Offset - WithTheRidge) < RideSlack, 'The first: as the ridge');
  Assert.IsTrue(Abs(Slabs[1].Offset - WithTheRidge) < RideSlack, 'The second: as the ridge');
  Assert.IsTrue(Slabs[2].Offset < WithTheRidge - 1, 'The third: by its own depth');
end;

procedure TFarPlaneEyeTests.TestWithoutACameraTheFloorIsOneSheet;
const
  City = 2156;
  Way = -280;
begin
  var Def := ReadFromLayout(EyeLayout(''));
  var Slabs := Def.FloorSlabs(Def.Layers[0].Band, City, Riding(Way));
  Assert.AreEqual(1, Integer(Length(Slabs)), 'One');
  var Foot: Double := Slabs[0].Bottom;
  Assert.IsTrue(Abs(Foot - FloorDeep) < ShareSlack, 'All of the band');
  Assert.IsTrue(Abs(Slabs[0].Offset - (City + Way)) < RideSlack, 'Riding with the city');
end;

procedure TFarPlaneEyeTests.TestTheFloorsEdgeSharpensOverTheFirstSeconds;
begin
  var AtFirst: Double := FDef.FloorFadeAt(FFloor, 0);
  var Halfway: Double := FDef.FloorFadeAt(FFloor, FloorSharpSeconds / 2);
  var Sharp: Double := FDef.FloorFadeAt(FFloor, FloorSharpSeconds);
  var Later: Double := FDef.FloorFadeAt(FFloor, FloorSharpSeconds * 3);
  Assert.IsTrue(Abs(AtFirst - FloorOwnFade) < ShareSlack, 'The band''s own at the first tick');
  Assert.IsTrue(Abs(Halfway - (FloorOwnFade + FloorSharpFade) / 2) < ShareSlack,
    'Halfway there halfway through');
  Assert.IsTrue(Abs(Sharp - FloorSharpFade) < ShareSlack, 'A soft line');
  Assert.IsTrue(Abs(Later - FloorSharpFade) < ShareSlack, 'And no sharper');
end;

procedure TFarPlaneEyeTests.TestAnEdgeSharperThanTheLineStays;
begin
  var Band := FFloor;
  Band.FadeTop := 1;
  var Sharp: Double := FDef.FloorFadeAt(Band, FloorSharpSeconds);
  Assert.IsTrue(Abs(Sharp - 1) < ShareSlack, 'As it was');
end;

procedure TFarPlaneEyeTests.TestAtItsRestTheEyeCarriesNothing;
const
  Rests: array [0..3] of Double = (1, RidgeShare, GroundNearness, FangNearness);
begin
  var Eye := Riding(StandRide);
  for var Rest in Rests do
  begin
    Assert.IsTrue(FDef.EyeNearness(Eye, Rest) = Rest, 'As near as it stood, to the bit');
    var Carried := FDef.Carry(Eye, Rest);
    var Still := Carried.Seen and (Carried.ScaleX = 1) and (Carried.ScaleY = 1) and
      (Carried.ShiftX = 0) and (Carried.ShiftY = 0);
    Assert.IsTrue(Still, 'Where it stood');
  end;
  var Band := FDef.FloorCarry(Eye);
  Assert.IsTrue(Band.Seen and (Band.ScaleX = 1) and (Band.ScaleY = 1), 'The floor too');
  Assert.IsTrue(FDef.FloorKeep(Eye) = 1, 'All of its band kept');
end;

procedure TFarPlaneEyeTests.TestThePushBringsEveryLayerNearer;
begin
  var Eye := StandEye;
  var City: Double := FDef.EyeNearness(Eye, 1);
  var Ridge: Double := FDef.EyeNearness(Eye, FDef.MotionNearness(fmRidge));
  var Ground: Double := FDef.EyeNearness(Eye, FDef.MotionNearness(fmGround));
  var Fangs: Double := FDef.EyeNearness(Eye, FDef.MotionNearness(fmFangs));
  Assert.IsTrue(Abs(City - StandCityNearness) < ShareSlack, 'The domes'' base line');
  Assert.IsTrue(Abs(Ridge - StandRidgeNearness) < ShareSlack, 'The ridge, barely');
  Assert.IsTrue(Abs(Ground - StandGroundNearness) < ShareSlack, 'The near ground');
  Assert.IsTrue(Abs(Fangs - StandFangNearness) < ShareSlack, 'The fangs most of all');
end;

// The fangs stand 153.6 from the eye at rest
procedure TFarPlaneEyeTests.TestALayerTheEyeHasPassedIsNotSeen;
const
  FangDepth = Focal / FangNearness;
begin
  var Rest: Double := FangNearness;
  var Before := Lifted(0, FangDepth - EyeNearest - 1);
  var Past := Lifted(0, FangDepth - EyeNearest + 1);
  Assert.IsTrue(FDef.Carry(Before, Rest).Seen, 'A little over the nearest: seen');
  Assert.IsFalse(FDef.Carry(Past, Rest).Seen, 'Nearer than that: behind the eye');
  Assert.IsTrue(FDef.EyeNearness(Past, Rest) = 0, 'No nearness to it');
  Assert.IsTrue(FDef.Carry(Past, 1).Seen, 'The city is still ahead');
end;

procedure TFarPlaneEyeTests.TestACarriedPlaceStandsWhereTheStandHasIt;
begin
  var Eye := StandEye;
  var Base := FDef.Carry(Eye, 1);
  var Ground := FDef.Carry(Eye, FDef.MotionNearness(fmGround));
  Assert.IsTrue(Abs(Base.ScreenX(600) - StandBaseX) < RideSlack, 'The base line, across');
  Assert.IsTrue(Abs(Base.ScreenY(200) - StandBaseY) < RideSlack, 'The base line, down');
  Assert.IsTrue(Abs(Ground.ScreenX(100) - StandGroundX) < RideSlack, 'The near ground, across');
  Assert.IsTrue(Abs(Ground.ScreenY(300) - StandGroundY) < RideSlack, 'The near ground, down');
  Assert.IsTrue(Abs(Base.RestX(StandBaseX) - 600) < RideSlack, 'And back to its rest');
end;

procedure TFarPlaneEyeTests.TestTheFloorMeltsAsTheEyeLeavesItsRest;
begin
  var Barely: Double := FDef.FloorKeep(Lifted(2, 30));
  var Earlier: Double := FDef.FloorKeep(Lifted(EarlierLift, EarlierPush));
  var Later: Double := FDef.FloorKeep(StandEye);
  var LiftedOff: Double := FDef.FloorKeep(Lifted(14, 0));
  var PushedOff: Double := FDef.FloorKeep(Lifted(0, 200));
  Assert.IsTrue(Abs(Barely - 1) < ShareSlack, 'All of it up to the first of each pair');
  Assert.IsTrue(Abs(Earlier - EarlierKeep) < ShareSlack, 'As the stand has it at 15.5 s');
  Assert.IsTrue(Abs(Later - StandKeep) < ShareSlack, 'And at 16 s');
  Assert.IsTrue(Abs(LiftedOff) < ShareSlack, 'None past the lift''s second');
  Assert.IsTrue(Abs(PushedOff) < ShareSlack, 'None past the push''s second');
end;

procedure TFarPlaneEyeTests.TestTheFloorGrowsDownFromTheHorizon;
begin
  var Band := FDef.FloorCarry(StandEye);
  Assert.IsTrue(Abs(Band.ScaleX - StandCityNearness) < ShareSlack, 'Across: as the base line');
  Assert.IsTrue(Abs(Band.ScaleY - StandStretch) < ShareSlack, 'Down: as a plane under the eye');
  Assert.IsTrue(Abs(Band.ScreenY(Horizon) - Horizon) < RideSlack, 'Its top stays on the horizon');
  Assert.IsTrue(Abs(Band.ScreenY(FloorFoot) - StandFoot) < RideSlack, 'Its foot as the stand''s');
end;

procedure TFarPlaneEyeTests.TestUnderTheEyeTheSlabsStartWhereTheStandsDo;
begin
  var Eye := StandEye;
  var Band := FDef.FloorCarry(Eye);
  var Slabs := FDef.FloorSlabs(FFloor, StandCity, Eye);
  Assert.AreEqual(FloorSlabCount, Integer(Length(Slabs)), 'As many as at rest');
  for var i := 0 to High(StandSlabs) do
  begin
    var Start: Double := Band.ScreenX(-Slabs[StandSlabs[i]].Offset);
    Assert.IsTrue(Abs(Start - StandSlabStarts[i]) < RideSlack, 'A slab''s picture');
  end;
end;

procedure TFarPlaneEyeTests.TestBehindTheEyeTheFloorHasNoSlabs;
begin
  var Eye := Lifted(0, Focal);
  Assert.AreEqual(0, Integer(Length(FDef.FloorSlabs(FFloor, StandCity, Eye))), 'None');
  Assert.IsFalse(FDef.FloorCarry(Eye).Seen, 'Its band behind the eye');
end;

// The dome's left edge stands 24 units left of the sun, half the ramp:
// pushed half the way to the base line the eye sees it twice as far from
// the middle of the screen, 16 left of the sun
procedure TFarPlaneEyeTests.TestThePushedEyeSeesADomeTakeLessOfTheSun;
const
  DomeLeft = 468;
  SunX = 288;
  HalfRamp = 24;
begin
  var Def := ReadFromLayout(DepthLayout(StandCamera + StandFrames));
  var Offsets := Default(TFarPlaneOffsets);
  Offsets[fmCity] := DomeLeft - (SunX - HalfRamp);
  var AtRest: Double := Def.SunCover(Offsets, RestEye);
  var Pushed: Double := Def.SunCover(Offsets, Lifted(0, Focal / 2));
  var Passed: Double := Def.SunCover(Offsets, Lifted(0, Focal));
  Assert.IsTrue(Abs(AtRest - 1 / 2) < ShareSlack, 'Half the ramp at rest');
  Assert.IsTrue(Abs(Pushed - 1 / 3) < ShareSlack, 'A third of it pushed');
  Assert.IsTrue(Abs(Passed) < ShareSlack, 'None of it once the eye is past');
end;

procedure TFarPlaneEyeTests.TestTheEyeSeesAFramesPointWhereTheStandHasIt;
var
  At: TFramePoint;
  Screen: TSdlFPoint;
  Nearness: Single;
begin
  var Def := ReadFromLayout(DepthLayout(StandCamera + StandFrames));
  At.X := 30;
  At.Y := 80;
  At.Z := -120;
  var Seen := Def.FramePoint(Def.Frames[0], StandCity + StandRide, StandEye, At, Screen,
    Nearness);
  Assert.IsTrue(Seen, 'Before the eye');
  Assert.IsTrue(Abs(Screen.X - StandFrameX) < RideSlack, 'Across');
  Assert.IsTrue(Abs(Screen.Y - StandFrameY) < RideSlack, 'Down');
  Assert.IsTrue(Abs(Nearness - StandFrameNearness) < ShareSlack, 'As near');
end;

// The dome's near foot stands 768 from the eye at rest
procedure TFarPlaneEyeTests.TestAFramesPointAtTheEyeIsNotSeen;
var
  At: TFramePoint;
  Screen: TSdlFPoint;
  Nearness: Single;
begin
  var Def := ReadFromLayout(DepthLayout(StandCamera + StandFrames));
  var Dome := Def.Frames[0];
  At.X := 0;
  At.Y := 0;
  At.Z := -Dome.W / 2;
  Assert.IsTrue(Def.FramePoint(Dome, StandCity, Lifted(0, 500), At, Screen, Nearness),
    'Still before the eye');
  Assert.IsFalse(Def.FramePoint(Dome, StandCity, Lifted(0, 700), At, Screen, Nearness),
    'Too near it: behind');
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

type
  TLightKinds = set of TCityLightKind;

// A city with each part of its life, ALife put in its place: what goes
// before the layers. AElements - the city's elements
function LifeLayout(const ALife, AElements: string): string;
begin
  Result := '{' + StandScreenSunSpeeds + StandCamera + ALife
    + '"layers": [{"id": "city", "speed": "city", "length": 2688, "elements": ['
    + AElements + ']}]}';
end;

const
  LifeLooks = '"window": {"core": [1, 1.4], "coreLevel": 0.35, "halo": [1.1, 3],'
    + ' "haloLevel": 0.1},'
    + '"neon": {"core": [1.5, 2.6], "coreLevel": 0.85, "halo": [1.3, 1.3], "haloLevel": 0.28},'
    + '"strip": {"core": [1.05, 3], "coreLevel": 0.5, "halo": [1.05, 9], "haloLevel": 0.14},'
    + '"flicker": {"breathDepth": 0.12, "breathTicks": [90, 200], "windowTicks": [200, 660],'
    + ' "faultShare": 0.6, "flips": [2, 6], "flipTicks": [2, 5], "faultLow": 0.12},';
  LifeBuilding = '{"id": "tower", "x": 600, "y": 266, "w": 40}';
  LifeBeacons = '"beacons": {"color": [255, 46, 30], "size": 2.6, "halo": 12, "glowLevel": 0.3,'
    + ' "flashLevel": 0.85, "flashTicks": 3, "periodTicks": [56, 96]},';
  LifeEmblemHead = '"emblem": {"on": "tower", "at": [0.5, 0], "w": 43, "aspect": 1,'
    + ' "color": [255, 196, 80], "coreLevel": 1, "haloLevel": 0.8, "faultShare": 0.25,'
    + ' "relightTicks": [2400, 4800], "darkTicks": [25, 45], "partTicks": [8, 20],';

// The lights with ASpans for the windows' span and APieces for the pieces
function LifeLights(const ASpans, APieces: string): string;
begin
  Result := '"cityLights": {' + LifeLooks
    + '"windows": {"onShare": 0.25, "spanTicks": ' + ASpans + '},'
    + '"pieces": {' + APieces + '}},';
end;

function LightOfKind(const AKind, ABox: string): string;
begin
  Result := '"tower": [{"kind": "' + AKind + '", "box": ' + ABox
    + ', "color": [72, 232, 255]}]';
end;

procedure AssertLifeRaises(const ALife: string; const AElements: string = LifeBuilding);
begin
  Assert.WillRaise(
    procedure
    begin
      ReadFromLayout(LifeLayout(ALife, AElements));
    end, EFarPlaneError);
end;

procedure TFarPlaneReadTests.TestRidesToTheEmblemOverTheMiddle;
const
  // One tick of the city at its cruise and a little more
  Slop = 0.2;
begin
  var Level := TLevel.Create;
  try
    Level.LoadFromFile(TPath.Combine(BinDir, LevelTwoFile));
    var Def := Level.FarPlane;
    var Plane := TFarPlane.Create(Def);
    try
      Plane.RideToEmblem;
      var Spire := Def.CityElements(Def.Emblem.Piece)[0];
      var Layer := Def.Layers[0];
      for var Each in Def.Layers do
        if Each.Motion = fmCity then
          Layer := Each;
      var Left := Def.ElementLeft(Layer, Spire, Plane.Offsets);
      Assert.AreEqual(Double(Def.ScreenWidth / 2), Left + Spire.W / 2, Slop,
        'The emblem''s spire over the middle');
      Assert.IsTrue(Plane.TunnelGone, 'Out of the tunnel');
      Assert.IsTrue(Plane.Clock > 0, 'The city''s clock has run');
      Assert.AreEqual(Plane.Offsets[fmCity], Plane.OffsetsAt(0.5)[fmCity], 0.0001,
        'Standing there');
      Assert.AreEqual(0.0, Double(Plane.CitySpeed), 0.0001, 'Till the road runs');
    finally
      Plane.Free;
    end;
  finally
    Level.Free;
  end;
end;

procedure TFarPlaneReadTests.TestUnderTheEmblemTheCityGivesItsPointsOnTheScreen;
const
  // One tick of the city at its cruise and a little more
  Slop = 0.2;
begin
  var Level := TLevel.Create;
  try
    Level.LoadFromFile(TPath.Combine(BinDir, LevelTwoFile));
    var Def := Level.FarPlane;
    var Plane := TFarPlane.Create(Def);
    try
      Plane.RideToEmblem;
      var Points := Def.CityPoints(Plane.Offsets);
      var Spire := Def.CityElements(Def.Emblem.Piece)[0];
      var Buildings := 0;
      for var Layer in Def.Layers do
        if Layer.Motion = fmCity then
          Inc(Buildings, Length(Layer.Elements));

      Assert.IsTrue(Length(Points) > 0, 'None on the screen');
      Assert.IsTrue(Length(Points) < Buildings, 'All of the city on the screen');
      var SpireSeen := False;
      for var Point in Points do
      begin
        var OnScreen := (Point.X >= 0) and (Point.X < Def.ScreenWidth) and
          (Point.Y > 0) and (Point.Y < Def.ScreenHeight);
        Assert.IsTrue(OnScreen, Format('A point at %g, %g', [Point.X, Point.Y]));
        var AtSpire := (Abs(Point.X - Def.ScreenWidth / 2) < Slop) and
          (Abs(Point.Y - (Spire.Y - Spire.H / 2)) < Slop);
        if AtSpire then
          SpireSeen := True;
      end;
      Assert.IsTrue(SpireSeen, 'The spire over the middle gives none');
    finally
      Plane.Free;
    end;
  finally
    Level.Free;
  end;
end;

procedure TFarPlaneReadTests.TestLevelTwoReadsItsCityLife;
begin
  var Level := TLevel.Create;
  try
    Level.LoadFromFile(TPath.Combine(BinDir, LevelTwoFile));
    var Plane := Level.FarPlane;
    Assert.IsTrue(Plane.Lights.Present, 'Lights');
    var Kinds: TLightKinds := [];
    for var Own in Plane.Lights.Pieces do
      for var Light in Own.Lights do
        Include(Kinds, Light.Kind);
    Assert.IsTrue(Kinds = [lkWindow, lkNeon, lkStrip, lkLamp], 'Every kind of light');
    Assert.IsTrue(Plane.Beacons.Present, 'Beacons to blink the lamps by');
    Assert.IsTrue(Plane.Emblem.Present, 'The emblem');
    Assert.AreEqual(Integer(Length(Plane.Emblem.Parts)), Integer(Length(Plane.Emblem.Halos)),
      'A halo to a part');
    var Stands := False;
    var Painted := False;
    for var Layer in Plane.Layers do
      for var Element in Layer.Elements do
      begin
        Stands := Stands or (Element.Id = Plane.Emblem.Piece);
        Painted := Painted or Element.Paint.Present;
      end;
    Assert.IsTrue(Stands, 'The emblem''s building is in the city');
    Assert.IsTrue(Painted, 'The emblem as paint on a wall');
    var Beaconed := False;
    for var Frame in Plane.Frames do
      Beaconed := Beaconed or Frame.Beacons;
    Assert.IsTrue(Beaconed, 'A frame carries beacons');
  finally
    Level.Free;
  end;
end;

procedure TFarPlaneReadTests.TestALightOfAnUnknownKindRaises;
begin
  AssertLifeRaises(LifeLights('[600, 3000]', LightOfKind('laser', '[0.1, 0.1, 0.2, 0.1]')));
end;

procedure TFarPlaneReadTests.TestALightWithoutABoxRaises;
begin
  AssertLifeRaises(LifeLights('[600, 3000]', LightOfKind('neon', '[0.1, 0.1, 0.2]')));
end;

procedure TFarPlaneReadTests.TestASpanOfNoTicksRaises;
begin
  AssertLifeRaises(LifeLights('[0, 3000]', LightOfKind('window', '[0.1, 0.1, 0.2, 0.1]')));
end;

procedure TFarPlaneReadTests.TestAPaintWithoutWidthRaises;
begin
  AssertLifeRaises('',
    '{"id": "tower", "x": 600, "y": 266, "w": 40, "paint": [0.2, 0.3, 0, 0.9]}');
end;

procedure TFarPlaneReadTests.TestAnEmblemWithoutPartsRaises;
begin
  AssertLifeRaises(LifeLights('[600, 3000]', '') + LifeEmblemHead
    + ' "parts": [], "halos": []},');
end;

procedure TFarPlaneReadTests.TestAnEmblemWithAHaloShortRaises;
begin
  AssertLifeRaises(LifeLights('[600, 3000]', '') + LifeEmblemHead
    + ' "parts": [[0, 0, 1, 1], [0.2, 0.2, 0.2, 0.2]], "halos": [[0, 0, 1, 1]]},');
end;

procedure TFarPlaneReadTests.TestLampsWithoutBeaconsRaise;
begin
  AssertLifeRaises(LifeLights('[600, 3000]', LightOfKind('lamp', '[0.5, 0.1, 0, 0]')));
end;

procedure TFarPlaneReadTests.TestFrameBeaconsWithoutBeaconsRaise;
begin
  AssertLifeRaises('"frames": {"items": [{"id": "dome", "x": 468, "w": 512, "h": 170,'
    + ' "beaconsAbove": 0.8}]},');
end;

procedure TFarPlaneReadTests.TestAnEmblemWithoutCityLightsRaises;
begin
  AssertLifeRaises(LifeBeacons + LifeEmblemHead
    + ' "parts": [[0, 0, 1, 1]], "halos": [[0, 0, 1, 1]]},');
end;

const
  TrainHead = '"train": {"piece": "car", "station": "stop", "mouth": 0.25, "y": 244,'
    + ' "inside": 30, "accelTicks": 132,';
  TrainStations = '{"id": "stop", "x": 100, "y": 266, "w": 80, "mirror": true},'
    + ' {"id": "stop", "x": 400, "y": 266, "w": 80}';

procedure TFarPlaneReadTests.TestLevelTwoReadsItsTrain;
begin
  var Level := TLevel.Create;
  try
    Level.LoadFromFile(TPath.Combine(BinDir, LevelTwoFile));
    var Plane := Level.FarPlane;
    Assert.IsTrue(Plane.Train.Present, 'A train');
    Assert.AreEqual(2, Integer(Length(Plane.CityElements(Plane.Train.Station))),
      'Two stations in the city');
    Assert.IsTrue(Length(Plane.Lights.LightsOf(Plane.Train.Piece)) > 0, 'Its lights');
    var Line := MonorailLine(Plane);
    Assert.IsTrue(Line.RightStop - Line.LeftStop > Plane.Train.W, 'A run longer than the train');
  finally
    Level.Free;
  end;
end;

procedure TFarPlaneReadTests.TestATrainWithoutTwoStationsRaises;
begin
  AssertLifeRaises(TrainHead + ' "w": 60, "cruise": 16, "dwellTicks": [300, 600]},',
    '{"id": "stop", "x": 100, "y": 266, "w": 80}');
end;

procedure TFarPlaneReadTests.TestATrainWithoutACruiseRaises;
begin
  AssertLifeRaises(TrainHead + ' "w": 60, "cruise": 0, "dwellTicks": [300, 600]},',
    TrainStations);
end;

procedure TFarPlaneReadTests.TestADwellOfNoTicksRaises;
begin
  AssertLifeRaises(TrainHead + ' "w": 60, "cruise": 16, "dwellTicks": [0, 600]},',
    TrainStations);
end;

const
  SearchlightsHead = '"searchlights": {"color": [255, 214, 150], "level": 0.42,'
    + ' "glassLevel": 0.26, "tailShare": 0.25, "rootHalf": 1.5, "spotSize": 22,'
    + ' "spotLevel": 0.55, "glintSize": 6, "glintLevel": 0.6,';
  SearchlightsPause = '"pause": {"windowTicks": [200, 330], "share": 0.45, "easeTicks": 20,'
    + ' "holdTicks": [40, 90]},';
  SearchlightLamp = '"items": [{"x": 676, "y": 266, "lift": 10, "aim": -105,'
    + ' "sweep": [28, 8], "periodTicks": [760, 270]}]},';

procedure TFarPlaneReadTests.TestLevelTwoReadsItsSearchlights;
begin
  var Level := TLevel.Create;
  try
    Level.LoadFromFile(TPath.Combine(BinDir, LevelTwoFile));
    var Plane := Level.FarPlane;
    Assert.IsTrue(Plane.Searchlights.Present, 'Searchlights');
    Assert.IsTrue(Length(Plane.Searchlights.Lamps) >= 2, 'Two lamps at the least');
    for var i := 0 to High(Plane.Searchlights.Lamps) do
      Assert.IsTrue(SearchlightBeam(Plane, i, 0, 0).Glass > 0,
        Format('Lamp %d stands in a dome', [i]));
  finally
    Level.Free;
  end;
end;

procedure TFarPlaneReadTests.TestSearchlightsReadTheirLamps;
begin
  var Plane := ReadFromLayout(LifeLayout(SearchlightsHead + ' "tail": 150, "spread": 0.15,'
    + SearchlightsPause + SearchlightLamp, LifeBuilding));
  var Lights := Plane.Searchlights;
  Assert.AreEqual(1, Integer(Length(Lights.Lamps)), 'One lamp');
  Assert.AreEqual(10.0, Double(Lights.Lamps[0].Lift), 0.0001, 'Its lift');
  Assert.AreEqual(8.0, Lights.Lamps[0].Waves[1].Degrees, 0.0001, 'Its second sweep');
  Assert.AreEqual(270.0, Lights.Lamps[0].Waves[1].PeriodTicks, 0.0001, 'Its second period');
  Assert.AreEqual(90, Lights.Pause.HoldMost, 'The longest hold');
  Assert.AreEqual(150.0, Double(Lights.Tail), 0.0001, 'The tail');
end;

procedure TFarPlaneReadTests.TestSearchlightsWithoutATailRaise;
begin
  AssertLifeRaises(SearchlightsHead + ' "tail": 0, "spread": 0.15,' + SearchlightsPause
    + SearchlightLamp);
end;

procedure TFarPlaneReadTests.TestSearchlightsWithoutAnEaseRaise;
begin
  AssertLifeRaises(SearchlightsHead + ' "tail": 150, "spread": 0.15,'
    + StringReplace(SearchlightsPause, '"easeTicks": 20', '"easeTicks": 0', [])
    + SearchlightLamp);
end;

procedure TFarPlaneReadTests.TestASearchlightWithOneSweepRaises;
begin
  AssertLifeRaises(SearchlightsHead + ' "tail": 150, "spread": 0.15,' + SearchlightsPause
    + StringReplace(SearchlightLamp, '"sweep": [28, 8]', '"sweep": [28]', []));
end;

procedure TFarPlaneReadTests.TestLevelTwoReadsItsFarm;
begin
  var Level := TLevel.Create;
  try
    Level.LoadFromFile(TPath.Combine(BinDir, LevelTwoFile));
    var Farm := Level.FarPlane.Farm;
    Assert.IsTrue(Farm.Present, 'A farm');
    Assert.IsTrue(Level.FarPlane.Frames[Farm.Frame].Kind = fkCapsule, 'Under a capsule');
    Assert.IsTrue(Length(Farm.Glass) > 0, 'Greenhouses with glass');
    Assert.IsTrue(Farm.GlareKeep < 1, 'The glare gives way to it');
  finally
    Level.Free;
  end;
end;

procedure TFarPlaneReadTests.TestACapsuleAndItsFarmRead;
var
  Glass: TFarmGlass;
begin
  var Def := ReadFromLayout(DepthLayout(StandCamera + CapsuleFrames + FarmSection));
  var Capsule := Def.Frames[0];
  Assert.IsTrue(Capsule.Kind = fkCapsule, 'A capsule');
  Assert.AreEqual(220.0, Double(Capsule.D), 0.0001, 'Its depth');
  Assert.AreEqual(12, Capsule.Rows, 'Its rows');
  Assert.AreEqual(16, Capsule.Cells, 'Its cells');
  Assert.AreEqual(4, Capsule.BeltEvery, 'Its belts');
  Assert.AreEqual(5, Capsule.CapCells, 'Its ends');
  Assert.IsTrue(Def.Farm.Present, 'A farm');
  Assert.AreEqual(0, Def.Farm.Frame, 'Under it');
  Assert.AreEqual(FarmGlareKeep, Double(Def.Farm.GlareKeep), 0.0001, 'Its glare');
  Assert.AreEqual(2400, Def.Farm.Glow.SpanMost, 'Its longest span');
  Assert.IsTrue(Def.Farm.GlassOf('base', Glass), 'The glass of a piece');
  Assert.AreEqual(105, Integer(Glass.Color.G), 'Its colour');
  Assert.IsFalse(Def.Farm.GlassOf('beam', Glass), 'None of another');
end;

procedure TFarPlaneReadTests.TestAFrameOfAnUnknownKindRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      ReadFromLayout(DepthLayout(StandCamera
        + StringReplace(CapsuleFrames, '"capsule"', '"tent"', [])));
    end, EFarPlaneError);
end;

procedure TFarPlaneReadTests.TestACapsuleOfOddRowsRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      ReadFromLayout(DepthLayout(StandCamera
        + StringReplace(CapsuleFrames, '"rows": 12', '"rows": 11', [])));
    end, EFarPlaneError);
end;

procedure TFarPlaneReadTests.TestACapsuleDeeperThanLongRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      ReadFromLayout(DepthLayout(StandCamera
        + StringReplace(CapsuleFrames, '"d": 220', '"d": 700', [])));
    end, EFarPlaneError);
end;

procedure TFarPlaneReadTests.TestAFarmUnderADomeRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      ReadFromLayout(DepthLayout(StandCamera + StandFrames
        + StringReplace(FarmSection, '"dome-farm"', '"dome"', [])));
    end, EFarPlaneError);
end;

procedure TFarPlaneReadTests.TestLevelTwoReadsItsPlane;
begin
  var Level := TLevel.Create;
  try
    Level.LoadFromFile(TPath.Combine(BinDir, LevelTwoFile));
    var Plane := Level.FarPlane.Plane;
    Assert.IsTrue(Plane.Present, 'A plane under the eye');
    Assert.IsTrue(Plane.Tile <> '', 'Its tile named');
    Assert.IsTrue(Plane.Levels >= 1, 'A copy of it at the least');
    Assert.IsTrue(Plane.Floor.SlabDeep > 0, 'A floor cut into slabs');
  finally
    Level.Free;
  end;
end;

procedure TFarPlaneReadTests.TestThePlaneIsReadAsWritten;
begin
  var Plane := ReadFromLayout(EyeLayout(StandCamera + EyePlane)).Plane;
  Assert.IsTrue(Plane.Present, 'Read');
  Assert.AreEqual('ground-top', Plane.Tile, 'Its tile');
  Assert.AreEqual(8, Plane.Levels, 'Its copies');
  Assert.AreEqual(2, Plane.WideLevels, 'The copies of the tile''s width');
  Assert.IsTrue(Abs(Plane.TileUnits - 448) < ShareSlack, 'A turn of the tile');
  Assert.IsTrue(Abs(Plane.FarFrom - 1500) < ShareSlack, 'Where the far ground begins');
  Assert.IsTrue(Abs(Plane.FarTill - 3000) < ShareSlack, 'And where the tile is gone');
  Assert.AreEqual(17, Integer(Plane.FarColor.R), 'The mean at its shade: 38 by 0.45');
  Assert.IsTrue(Abs(Plane.Floor.MeltLiftFrom - 2) < ShareSlack, 'The melt by the lift begins');
  Assert.IsTrue(Abs(Plane.Floor.MeltPushTill - 200) < ShareSlack, 'The melt by the push ends');
  Assert.IsTrue(Abs(Plane.Floor.SlabDeep - FloorSlabDeep) < ShareSlack, 'A slab deep');
  Assert.IsTrue(Abs(Plane.Floor.SharpFade - FloorSharpFade) < ShareSlack, 'The sharp edge');
  Assert.AreEqual(25, Integer(Plane.Floor.Foot.B), 'The colour under the foot');
  Assert.IsFalse(ReadFromLayout(EyeLayout(StandCamera)).Plane.Present,
    'None without the section');
end;

procedure TFarPlaneReadTests.TestAPlaneWithoutACameraRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      ReadFromLayout(EyeLayout(EyePlane));
    end, EFarPlaneError);
end;

procedure TFarPlaneReadTests.TestAFloorThatMeltsOverNothingRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      ReadFromLayout(EyeLayout(StandCamera
        + StringReplace(EyePlane, '"meltLift": [2, 14]', '"meltLift": [2, 2]', [])));
    end, EFarPlaneError);
end;

procedure TFarPlaneReadTests.TestAFloorCutIntoNoSlabsRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      ReadFromLayout(EyeLayout(StandCamera
        + StringReplace(EyePlane, '"slabDeep": 6', '"slabDeep": 0', [])));
    end, EFarPlaneError);
end;

// A rib with an end nearer the eye than FrameNearestShare of the focal
// length is dropped whole: the flight is flown only as far as no frame
// comes that near
procedure TFarPlaneReadTests.TestTillItIsFlownNoFrameStandsAtTheEye;
const
  Step = 0.05;
begin
  var Level := TLevel.Create;
  try
    Level.LoadFromFile(TPath.Combine(BinDir, LevelTwoFile));
    var Plane := Level.FarPlane;
    var Nearest: Double := Plane.Camera.Focal * FrameNearestShare;
    var Stand: Double := Plane.CityLength;
    var Seconds: Double := 0;
    while Seconds <= Level.Titles.FlightTill do
    begin
      var Push := Level.Titles.Path.EyeAt(Seconds, Stand).Push;
      for var Frame in Plane.Frames do
      begin
        var HalfDepth: Double := Frame.W / 2;
        if Frame.Kind = fkCapsule then
          HalfDepth := Frame.D / 2;
        Assert.IsTrue(Plane.Camera.Focal - HalfDepth - Push >= Nearest,
          'Its nearest rib is whole before the eye');
      end;
      Seconds := Seconds + Step;
    end;
  finally
    Level.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TFarPlaneTests);
  TDUnitX.RegisterTestFixture(TFarPlaneSunTests);
  TDUnitX.RegisterTestFixture(TFarPlaneDepthTests);
  TDUnitX.RegisterTestFixture(TFarPlaneEyeTests);
  TDUnitX.RegisterTestFixture(TFarPlaneShadeTests);
  TDUnitX.RegisterTestFixture(TFarPlaneReadTests);

end.
