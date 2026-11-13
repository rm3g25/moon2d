{
  Tests.Levels.Farm - the light of the farm under its long dome, over a far
  plane of the tests' own: the stand's camera, the layout's dome-farm and
  its grow lights, one greenhouse in the middle of the dome.

  A greenhouse's grow light is the stand's to the tick - its values below
  are the stand's farmGlowLevel over the layout's glow - never past its
  level, lit about its share of the time; switched on after a dark span it
  flickers and warms up to its level, switched off it goes out at once.

  A lit greenhouse is a source at its glass's centre, moved with a mirror;
  one far off the screen is dark, and without a farm nothing is lit. The
  light at the glass is its colour times its power, falls to a share of
  1 / e at its reach and to nothing far off; drawn, it never passes full
  and keeps its hue. The air's mesh covers the dome's near half, corner to
  corner; the apron is lit at the foot and dark toward the eye, and none is
  drawn while the dome is off the screen.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Levels.Farm;

interface

uses
  DUnitX.TestFramework, Levels.FarPlane, Levels.Farm;

type
  [TestFixture]
  TFarmGlowTests = class
  private
    FGlow: TFarmGlow;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure TestGlowMatchesTheStand;
    [Test]
    procedure TestGlowNeverPastItsLevel;
    [Test]
    procedure TestGlowLitAboutItsShare;
    [Test]
    procedure TestGlowSwitchedOnFlickersAndWarmsUp;
    [Test]
    procedure TestGlowSwitchedOffGoesOutAtOnce;
  end;

  [TestFixture]
  TFarmLightTests = class
  private
    FDef: TFarPlaneDef;
    FHeights: TArray<Double>;
    function Offsets(ACityOffset: Double): TFarPlaneOffsets;
    // The city's offset that brings the dome's centre to the middle
    function Centred: Double;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure TestNoFarmLightsNothing;
    [Test]
    procedure TestLitGreenhouseIsASourceAtItsGlass;
    [Test]
    procedure TestMirrorMovesTheSource;
    [Test]
    procedure TestGreenhouseFarOffTheScreenIsDark;
    [Test]
    procedure TestLightAtTheGlassIsItsColourTimesItsPower;
    [Test]
    procedure TestLightFallsToAShareOfOneOverEAtItsReach;
    [Test]
    procedure TestLightFarOffIsNothing;
    [Test]
    procedure TestExposedNeverPastFull;
    [Test]
    procedure TestExposedKeepsTheHue;
    [Test]
    procedure TestAirCoversTheNearHalf;
    [Test]
    procedure TestApronLitAtTheFootDarkTowardTheEye;
    [Test]
    procedure TestApronNoneWithTheDomeOffTheScreen;
  end;

implementation

uses
  System.Math, System.SysUtils, Sdl2.Core, Render.Brush, Levels.Capsule;

const
  // The layout's glow of the day the tests were written
  GlowSpanLeast = 900;
  GlowSpanMost = 2400;
  GlowOnShare = 0.85;
  GlowWarmTicks = 90;
  GlowFlickerTicks = 12;
  // The stand's farmGlowLevel over that glow: the greenhouse, the tick, the
  // level
  StandGlows: array [0..7, 0..2] of Double = (
    (0, 0, 1), (0, 4810, 0), (0, 6584, 0), (0, 6585, 3 / 90), (0, 6586, 4 / 90),
    (0, 6623, 41 / 90), (7, 2923, 16 / 90), (7, 2960, 53 / 90));
  LongTicks = 40000;
  ShareSlack = 0.1;

  ScreenWidth = 512;
  ScreenHeight = 384;
  Horizon = 238;
  BaseY = 266;
  Focal = 1024;
  DomeX = 2290;
  DomeLength = 640;
  DomeDepth = 220;
  DomeHeight = 90;
  // A greenhouse in the middle of the dome, a little behind its centre
  HallX = 2580;
  HallFeet = 262;
  HallWidth = 40;
  HallHeight = 20;
  HallPiece = 'hall-test';
  GlassShare = 0.5;
  GlassAtU = 0.25;
  GlassAtV = 0.5;
  HallArea = 400;
  AirReach = 40;
  FarOff = 5000;
  Slack = 1E-9;
  // Screen points are Single
  PointSlack = 1E-3;

{ TFarmGlowTests }

procedure TFarmGlowTests.Setup;
begin
  FGlow.Level := 1;
  FGlow.SpanLeast := GlowSpanLeast;
  FGlow.SpanMost := GlowSpanMost;
  FGlow.OnShare := GlowOnShare;
  FGlow.WarmTicks := GlowWarmTicks;
  FGlow.FlickerTicks := GlowFlickerTicks;
end;

procedure TFarmGlowTests.TestGlowMatchesTheStand;
begin
  for var i := 0 to High(StandGlows) do
  begin
    var Hall := Round(StandGlows[i, 0]);
    var Tick := Round(StandGlows[i, 1]);
    Assert.AreEqual(StandGlows[i, 2], FarmGlowLevel(FGlow, FarmSeed(Hall), Tick), Slack,
      Format('Greenhouse %d at tick %d', [Hall, Tick]));
  end;
end;

procedure TFarmGlowTests.TestGlowNeverPastItsLevel;
begin
  for var Hall := 0 to 9 do
    for var Tick := 0 to LongTicks div 13 do
    begin
      var Level := FarmGlowLevel(FGlow, FarmSeed(Hall), Tick * 13);
      Assert.IsTrue((Level >= 0) and (Level <= FGlow.Level), 'Within 0..its level');
    end;
end;

procedure TFarmGlowTests.TestGlowLitAboutItsShare;
begin
  var Lit := 0;
  var Seen := 0;
  for var Hall := 0 to 19 do
    for var Tick := 0 to LongTicks div 50 do
    begin
      Inc(Seen);
      if FarmGlowLevel(FGlow, FarmSeed(Hall), Tick * 50) > 0 then
        Inc(Lit);
    end;
  Assert.AreEqual(Double(GlowOnShare), Lit / Seen, ShareSlack, 'About its share of the time');
end;

procedure TFarmGlowTests.TestGlowSwitchedOnFlickersAndWarmsUp;
begin
  var Seed := FarmSeed(0);
  var Tick := 1;
  while (Tick < LongTicks) and not ((FarmGlowLevel(FGlow, Seed, Tick - 1) = 0) and
    (FarmGlowLevel(FGlow, Seed, Tick) > 0)) do
    Inc(Tick);
  Assert.IsTrue(Tick < LongTicks, 'Switched on after a dark span');
  var Dark := 0;
  for var Inside := 0 to GlowFlickerTicks do
    if FarmGlowLevel(FGlow, Seed, Tick + Inside) = 0 then
      Inc(Dark);
  Assert.IsTrue(Dark > 0, 'It flickers');
  var Was: Double := 0;
  for var Inside := GlowFlickerTicks to GlowWarmTicks + 10 do
  begin
    var Level := FarmGlowLevel(FGlow, Seed, Tick + Inside);
    Assert.IsTrue(Level >= Was, 'It warms up, never down');
    Was := Level;
  end;
  Assert.AreEqual(Double(FGlow.Level), Was, Slack, 'Up to its level');
end;

procedure TFarmGlowTests.TestGlowSwitchedOffGoesOutAtOnce;
begin
  var Seed := FarmSeed(0);
  var Switches := 0;
  for var Tick := 0 to LongTicks do
  begin
    var Lit := FarmGlowLevel(FGlow, Seed, Tick) > 0;
    var StaysDark := True;
    for var Next := 1 to GlowFlickerTicks do
      StaysDark := StaysDark and (FarmGlowLevel(FGlow, Seed, Tick + Next) = 0);
    if not Lit or not StaysDark then
      Continue;
    Inc(Switches);
    Assert.AreEqual(Double(FGlow.Level), FarmGlowLevel(FGlow, Seed, Tick), Slack,
      'At its full the tick before');
  end;
  Assert.IsTrue(Switches > 0, 'Switched off at least once');
end;

{ TFarmLightTests }

procedure TFarmLightTests.Setup;
begin
  FDef := Default(TFarPlaneDef);
  FDef.Screen := 1;
  FDef.ScreenWidth := ScreenWidth;
  FDef.ScreenHeight := ScreenHeight;
  FDef.Camera.Present := True;
  FDef.Camera.Horizon := Horizon;
  FDef.Camera.BaseY := BaseY;
  FDef.Camera.Focal := Focal;

  var Dome := Default(TDomeFrame);
  Dome.Id := 'dome-farm';
  Dome.Kind := fkCapsule;
  Dome.X := DomeX;
  Dome.W := DomeLength;
  Dome.D := DomeDepth;
  Dome.H := DomeHeight;
  Dome.Rows := 12;
  Dome.Cells := 16;
  Dome.BeltEvery := 4;
  Dome.CapCells := 5;
  Dome.Rib := 0.85;
  FDef.Frames := [Dome];

  var Hall := Default(TFarPlaneElement);
  Hall.Id := HallPiece;
  Hall.X := HallX;
  Hall.Y := HallFeet;
  Hall.W := HallWidth;
  Hall.DepthY := HallFeet;
  Hall.Shade := 1;
  var City := Default(TFarPlaneLayer);
  City.Id := 'city';
  City.Motion := fmCity;
  City.Length := 2688;
  City.Elements := [Hall];
  FDef.Layers := [City];
  FHeights := [HallHeight];

  var Glass: TFarmGlass;
  Glass.Piece := HallPiece;
  Glass.Color.R := 255;
  Glass.Color.G := 105;
  Glass.Color.B := 176;
  Glass.AtU := GlassAtU;
  Glass.AtV := GlassAtV;
  Glass.Share := GlassShare;
  FDef.Farm := Default(TCityFarm);
  FDef.Farm.Present := True;
  FDef.Farm.Frame := 0;
  FDef.Farm.GlareKeep := 0.3;
  FDef.Farm.Glow.Level := 1;
  FDef.Farm.Glow.SpanLeast := GlowSpanLeast;
  FDef.Farm.Glow.SpanMost := GlowSpanMost;
  FDef.Farm.Glow.OnShare := GlowOnShare;
  FDef.Farm.Glow.WarmTicks := GlowWarmTicks;
  FDef.Farm.Glow.FlickerTicks := GlowFlickerTicks;
  FDef.Farm.AirReach := AirReach;
  FDef.Farm.AirLevel := 0.07;
  FDef.Farm.RibLevel := 0.1;
  FDef.Farm.ApronLength := 160;
  FDef.Farm.ApronLevel := 0.2;
  FDef.Farm.ApronGap := 1.2;
  FDef.Farm.Glass := [Glass];
end;

function TFarmLightTests.Offsets(ACityOffset: Double): TFarPlaneOffsets;
begin
  Result := Default(TFarPlaneOffsets);
  Result[fmCity] := ACityOffset;
end;

function TFarmLightTests.Centred: Double;
begin
  Result := DomeX + DomeLength / 2 - ScreenWidth / 2;
end;

procedure TFarmLightTests.TestNoFarmLightsNothing;
begin
  FDef.Farm.Present := False;
  var View := FarmView(FDef, Offsets(Centred), 0, FHeights);
  Assert.AreEqual(0, Length(View.Sources), 'No source');
end;

// The first greenhouse of the city is lit at tick 0 (the stand's)
procedure TFarmLightTests.TestLitGreenhouseIsASourceAtItsGlass;
begin
  var View := FarmView(FDef, Offsets(Centred), 0, FHeights);
  Assert.AreEqual(1, Length(View.Sources), 'One source');
  Assert.AreEqual(Double(1), View.Glass[0], Slack, 'Its glass at full');
  var Left := FDef.ElementLeft(FDef.Layers[0], FDef.Layers[0].Elements[0], Offsets(Centred));
  var Source := View.Sources[0];
  Assert.AreEqual(Left + GlassAtU * HallWidth, Source.X, Slack, 'Across');
  Assert.AreEqual(Double(HallFeet - HallHeight + GlassAtV * HallHeight), Source.Y, Slack,
    'Down');
  Assert.AreEqual(Double(GlassShare * HallWidth * HallHeight / HallArea), Source.Power, Slack,
    'Its power');
  Assert.AreEqual(Double(FDef.Nearness(HallFeet)), Source.Nearness, Slack, 'Its nearness');
end;

procedure TFarmLightTests.TestMirrorMovesTheSource;
begin
  var Plain := FarmView(FDef, Offsets(Centred), 0, FHeights).Sources[0];
  FDef.Layers[0].Elements[0].Mirror := True;
  var Mirrored := FarmView(FDef, Offsets(Centred), 0, FHeights).Sources[0];
  Assert.AreEqual(Plain.X + (1 - 2 * GlassAtU) * HallWidth, Mirrored.X, Slack,
    'Left for right');
end;

procedure TFarmLightTests.TestGreenhouseFarOffTheScreenIsDark;
begin
  var View := FarmView(FDef, Offsets(Centred + FarOff), 0, FHeights);
  Assert.AreEqual(0, Length(View.Sources), 'No source');
  Assert.AreEqual(Double(0), View.Glass[0], Double(0), 'Its glass dark');
end;

procedure TFarmLightTests.TestLightAtTheGlassIsItsColourTimesItsPower;
begin
  var Source := FarmView(FDef, Offsets(Centred), 0, FHeights).Sources[0];
  var Light := FarmLight(FDef.Farm, [Source], Source.X, Source.Y);
  Assert.AreEqual(Source.Power, Light.R, Slack, 'Red');
  Assert.AreEqual(105 / 255 * Source.Power, Light.G, Slack, 'Green');
  Assert.AreEqual(176 / 255 * Source.Power, Light.B, Slack, 'Blue');
end;

procedure TFarmLightTests.TestLightFallsToAShareOfOneOverEAtItsReach;
begin
  var Source := FarmView(FDef, Offsets(Centred), 0, FHeights).Sources[0];
  var Reach := AirReach * Source.Nearness;
  var Light := FarmLight(FDef.Farm, [Source], Source.X + Reach, Source.Y);
  Assert.AreEqual(Source.Power * Exp(-1), Light.R, Slack, 'One over e');
end;

procedure TFarmLightTests.TestLightFarOffIsNothing;
begin
  var Source := FarmView(FDef, Offsets(Centred), 0, FHeights).Sources[0];
  var Light := FarmLight(FDef.Farm, [Source], Source.X + AirReach * 10, Source.Y);
  Assert.AreEqual(Double(0), Light.R + Light.G + Light.B, Double(0), 'Nothing');
end;

procedure TFarmLightTests.TestExposedNeverPastFull;
begin
  var Light: TFarmLight;
  Light.R := 1000;
  Light.G := 50;
  Light.B := 0;
  var Shown := Exposed(Light, 1);
  Assert.IsTrue(Shown.R <= 1, 'Red at full at the most');
  Assert.IsTrue(Shown.G <= 1, 'Green');
  Assert.AreEqual(Double(0), Shown.B, Double(0), 'No blue stays none');
end;

procedure TFarmLightTests.TestExposedKeepsTheHue;
begin
  var Light: TFarmLight;
  Light.R := 3;
  Light.G := 1;
  Light.B := 2;
  var Shown := Exposed(Light, 0.5);
  Assert.IsTrue((Shown.R > Shown.B) and (Shown.B > Shown.G), 'The channels in their order');
end;

procedure TFarmLightTests.TestAirCoversTheNearHalf;
var
  Crown, NearFoot: TSdlFPoint;
  Nearness: Single;
begin
  var Dome := FDef.Frames[0];
  FDef.FramePoint(Dome, Centred, CapsulePoint(Dome, 0, Dome.Rows / 2), Crown, Nearness);
  FDef.FramePoint(Dome, Centred, CapsulePoint(Dome, 0, Dome.Rows), NearFoot, Nearness);
  var Sources := FarmView(FDef, Offsets(Centred), 0, FHeights).Sources;
  var Mesh := FarmAirMesh(FDef, Sources, Centred);
  Assert.AreEqual((FarmAirAlong + 1) * (FarmAirRound + 1), Length(Mesh.Corners), 'Corners');
  Assert.AreEqual(FarmAirAlong * FarmAirRound * 6, Length(Mesh.Indices), 'Two triangles a cell');
  var Lit := False;
  for var Corner in Mesh.Corners do
  begin
    Assert.IsTrue(Corner.Y >= Crown.Y - PointSlack, 'Not over its crown');
    Assert.IsTrue(Corner.Y <= NearFoot.Y + PointSlack, 'Not under its near foot');
    Lit := Lit or (Corner.Light.R > 0);
  end;
  Assert.IsTrue(Lit, 'The greenhouse lights it');
end;

procedure TFarmLightTests.TestApronLitAtTheFootDarkTowardTheEye;
begin
  var Sources := FarmView(FDef, Offsets(Centred), 0, FHeights).Sources;
  var Mesh := FarmApronMesh(FDef, Sources, Centred);
  Assert.IsTrue(Length(Mesh.Corners) > 0, 'Some of it');
  var Lit := False;
  for var Quad := 0 to Length(Mesh.Corners) div 4 - 1 do
  begin
    var Foot := Mesh.Corners[Quad * 4];
    var Out := Mesh.Corners[Quad * 4 + 3];
    Assert.AreEqual(Double(0), Out.Light.R + Out.Light.G + Out.Light.B, Double(0),
      'Dark toward the eye');
    Assert.IsTrue(Out.Y > Foot.Y, 'Toward the eye is down the screen');
    Lit := Lit or (Foot.Light.R > 0);
  end;
  Assert.IsTrue(Lit, 'Lit at the foot by the greenhouse');
end;

procedure TFarmLightTests.TestApronNoneWithTheDomeOffTheScreen;
begin
  var Sources := FarmView(FDef, Offsets(Centred), 0, FHeights).Sources;
  var Mesh := FarmApronMesh(FDef, Sources, Centred + FarOff);
  Assert.AreEqual(0, Length(Mesh.Indices), 'Nothing drawn');
end;

initialization
  TDUnitX.RegisterTestFixture(TFarmGlowTests);
  TDUnitX.RegisterTestFixture(TFarmLightTests);

end.
