{
  Tests.Render.DomeFrames - the geometry of the dome frames, over a far
  plane of the tests' own: the stand's camera and sun, one frame.

  A frame stands on the base line as wide as its width there, its top its
  height over its centre; one in the middle of the screen reaches as far
  left as right; it rides with the city. Its far half is behind its centre
  and its near half in front, each far to near, the near ribs thicker; a
  finer frame has more ribs; one off the screen shows none. The shadows
  lie below the horizon and in front of the eye, a tall frame's as a low
  one's: the sun is low, a lifted rib throws its shadow past the eye, and
  the shadow is cut there - the stand cuts it so, and so does the game. They
  run to the eye. A shadow is a stroke: soft at its edges, fully dark at a
  dome's foot and fading toward the eye; a sun under the horizon throws
  none. The rim faces the sun and is brightest by it.

  A frame's beacons stand on the nodes the stand puts them on, above their
  share of its height - their seeds, the stand's own for both frames, say
  so - none on a frame without a share; the far ones behind its centre, the
  near ones in front; they ride with the city.

  A capsule - the farm's long dome of the layout - is the stand's rib for
  rib: as many far and near, the crown in front with the near half, as many
  shadows - its feet throw none - and as many beacons behind and in front,
  each with a seed of its own. Its ribs are the farm's when the farm stands
  under it, and every rib carries the frames' dark till the farm lights it.

  How the ribs look - the rim's colour, the smoothing of their edges, the
  glare - has no test here: none of it shows without drawing.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Render.DomeFrames;

interface

uses
  DUnitX.TestFramework, Levels.FarPlane, Render.DomeFrames;

type
  [TestFixture]
  TDomeFramesTests = class
  private
    FDef: TFarPlaneDef;
    // The city's offset that brings the frame's centre to the middle of
    // the screen
    function Centred: Double;
    function ViewOf(const ADef: TFarPlaneDef; AOffset: Double): TFrameView;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure TestNoFramesShowNothing;
    [Test]
    procedure TestFrameStandsOnTheBaseLine;
    [Test]
    procedure TestFrameTopIsItsHeightOverItsCentre;
    [Test]
    procedure TestFrameInTheMiddleReachesAsFarLeftAsRight;
    [Test]
    procedure TestFrameRidesWithTheCity;
    [Test]
    procedure TestFrameFarHalfBehindNearHalfInFront;
    [Test]
    procedure TestFrameRibsComeFarToNear;
    [Test]
    procedure TestFrameNearRibsAreThicker;
    [Test]
    procedure TestFrameFinerHasMoreRibs;
    [Test]
    procedure TestFrameOffTheScreenShowsNothing;
    [Test]
    procedure TestShadowsLieBetweenTheHorizonAndTheEye;
    [Test]
    procedure TestShadowsOfATallFrameLieBetweenTheHorizonAndTheEye;
    [Test]
    procedure TestShadowsRunToTheEye;
    [Test]
    procedure TestShadowsAreSoftEdged;
    [Test]
    procedure TestShadowsFullyDarkAtTheFoot;
    [Test]
    procedure TestShadowsFadeTowardTheEye;
    [Test]
    procedure TestShadowsNoneUnderASunBelowTheHorizon;
    [Test]
    procedure TestRimFacesTheSun;
    [Test]
    procedure TestRimBrightestByTheSun;
    [Test]
    procedure TestBeaconsNoneWithoutTheirShare;
    [Test]
    procedure TestBeaconsSitOnTheStandsNodes;
    [Test]
    procedure TestBeaconsFarBehindNearInFront;
    [Test]
    procedure TestBeaconsRideWithTheCity;
  end;

  [TestFixture]
  TCapsuleFrameTests = class
  private
    FDef: TFarPlaneDef;
    function Centred: Double;
    function View: TFrameView;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure TestRibsAreTheStands;
    [Test]
    procedure TestCrownStandsWithTheNearHalf;
    [Test]
    procedure TestShadowsAreTheStands;
    [Test]
    procedure TestBeaconsAreTheStandsEachItsOwnSeed;
    [Test]
    procedure TestRibsAreTheFarmsUnderTheFarm;
    [Test]
    procedure TestRibsCarryTheFramesDark;
  end;

implementation

uses
  System.Math, System.Generics.Collections, Sdl2.Core;

const
  ScreenWidth = 512;
  ScreenHeight = 384;
  Middle = ScreenWidth / 2;
  Horizon = 238;
  BaseY = 266;
  Focal = 1024;
  FloorBottom = 320;
  SunX = 288;
  SunY = 208;
  FrameX = 600;
  FrameWidth = 512;
  FrameHeight = 170;
  FrameFrequency = 4;
  FrameRib = 2.2;
  LowFrameHeight = 30;
  // The share of the focal length where a point stands at the eye
  // (Render.DomeFrames): the floor there lies this far down the screen
  EyeShare = 0.15;
  EyeY = Horizon + (BaseY - Horizon) / EyeShare;
  Slack = 0.01;
  BeaconsAbove = 0.8;
  SatelliteWidth = 360;
  SatelliteHeight = 115;
  SatelliteFrequency = 3;
  SatelliteBeaconsAbove = 0.9;
  // The stand's beaconSeed of the nodes above the shares: the frame above
  // and a satellite after it, the second frame
  StandBeaconSeeds: array [0..21] of Cardinal = (
    22849282, 130681901, 184482304, 216005431, 376524091, 470226707, 508778340, 882786705,
    1150238390, 1441563046, 1540583311, 1668231194, 1689678975, 1693691114, 2237285661,
    3185708816, 3533269019, 3546826322, 3798457710, 3937259466, 3983871065, 4132272264);

function StandDef: TFarPlaneDef;
var
  City: TFarPlaneLayer;
  Frame: TDomeFrame;
begin
  Result := Default(TFarPlaneDef);
  Result.Screen := 1;
  Result.ScreenWidth := ScreenWidth;
  Result.ScreenHeight := ScreenHeight;
  Result.Sun.X := SunX;
  Result.Sun.Y := SunY;
  Result.Camera.Present := True;
  Result.Camera.Horizon := Horizon;
  Result.Camera.BaseY := BaseY;
  Result.Camera.Focal := Focal;

  Frame := Default(TDomeFrame);
  Frame.Id := 'dome';
  Frame.X := FrameX;
  Frame.W := FrameWidth;
  Frame.H := FrameHeight;
  Frame.Frequency := FrameFrequency;
  Frame.Rib := FrameRib;
  Result.Frames := [Frame];

  City := Default(TFarPlaneLayer);
  City.Id := 'city';
  City.Motion := fmCity;
  City.Length := 2688;
  City.Band.Present := True;
  City.Band.Top := Horizon;
  City.Band.Bottom := FloorBottom;
  Result.Layers := [City];
end;

function RibCount(const AView: TFrameView): Integer;
begin
  Result := Length(AView.Far) + Length(AView.Near);
end;

function AllRibs(const AView: TFrameView): TArray<TFrameRib>;
begin
  Result := AView.Far + AView.Near;
end;

function NearPoint(const APoint: TSdlFPoint; AX, AY: Single): Boolean;
begin
  Result := (Abs(APoint.X - AX) < Slack) and (Abs(APoint.Y - AY) < Slack);
end;

function HasEndAt(const AView: TFrameView; AX, AY: Single): Boolean;
begin
  for var Rib in AllRibs(AView) do
    if NearPoint(Rib.A, AX, AY) or NearPoint(Rib.B, AX, AY) then
      Exit(True);
  Result := False;
end;

function MiddleOf(const ARib: TFrameRib): TSdlFPoint;
begin
  Result.X := (ARib.A.X + ARib.B.X) / 2;
  Result.Y := (ARib.A.Y + ARib.B.Y) / 2;
end;

function SunDistance(const ARib: TFrameRib): Single;
begin
  var Centre := MiddleOf(ARib);
  Result := Sqrt(Sqr(SunX - Centre.X) + Sqr(SunY - Centre.Y));
end;

// TDomeFramesTests

procedure TDomeFramesTests.Setup;
begin
  FDef := StandDef;
end;

procedure AssertBetweenTheHorizonAndTheEye(const AView: TFrameView);
begin
  Assert.IsTrue(Length(AView.Shadows) > 0, 'The ribs throw shadows');
  for var Shadow in AView.Shadows do
    for var Sample in Shadow.Samples do
    begin
      Assert.IsTrue(Sample.At.Y > Horizon, 'Below the horizon');
      Assert.IsTrue(Sample.At.Y <= EyeY + Slack, 'In front of the eye');
    end;
end;

// The sample of a shadow nearest the eye: the lowest on the screen
function NearestSample(const AShadow: TRibShadow): TShadowSample;
begin
  Result := AShadow.Samples[0];
  for var Sample in AShadow.Samples do
    if Sample.At.Y > Result.At.Y then
      Result := Sample;
end;

function FarthestSample(const AShadow: TRibShadow): TShadowSample;
begin
  Result := AShadow.Samples[0];
  for var Sample in AShadow.Samples do
    if Sample.At.Y < Result.At.Y then
      Result := Sample;
end;

function TDomeFramesTests.Centred: Double;
begin
  Result := FrameX + FrameWidth / 2 - Middle;
end;

function TDomeFramesTests.ViewOf(const ADef: TFarPlaneDef; AOffset: Double): TFrameView;
begin
  var Frames := TDomeFrames.Create(ADef);
  try
    Result := Frames.View(AOffset);
  finally
    Frames.Free;
  end;
end;

procedure TDomeFramesTests.TestNoFramesShowNothing;
begin
  FDef.Frames := [];
  var Frames := TDomeFrames.Create(FDef);
  try
    Assert.IsFalse(Frames.Present, 'No frame to show');
    var View := Frames.View(Centred);
    Assert.AreEqual(0, RibCount(View), 'No ribs');
    Assert.AreEqual(0, Integer(Length(View.Shadows)), 'No shadows');
  finally
    Frames.Free;
  end;
end;

procedure TDomeFramesTests.TestFrameStandsOnTheBaseLine;
begin
  var View := ViewOf(FDef, Centred);
  Assert.IsTrue(HasEndAt(View, Middle - FrameWidth / 2, BaseY), 'Its left foot');
  Assert.IsTrue(HasEndAt(View, Middle + FrameWidth / 2, BaseY), 'Its right foot');
end;

procedure TDomeFramesTests.TestFrameTopIsItsHeightOverItsCentre;
begin
  var View := ViewOf(FDef, Centred);
  Assert.IsTrue(HasEndAt(View, Middle, BaseY - FrameHeight));
end;

procedure TDomeFramesTests.TestFrameInTheMiddleReachesAsFarLeftAsRight;
begin
  var Leftmost: Single := MaxInt;
  var Rightmost: Single := -MaxInt;
  for var Rib in AllRibs(ViewOf(FDef, Centred)) do
  begin
    Leftmost := Min(Leftmost, Min(Rib.A.X, Rib.B.X));
    Rightmost := Max(Rightmost, Max(Rib.A.X, Rib.B.X));
  end;
  Assert.AreEqual(Double(Middle - Leftmost), Double(Rightmost - Middle), Slack);
end;

procedure TDomeFramesTests.TestFrameRidesWithTheCity;
const
  Ride = 10;
begin
  var View := ViewOf(FDef, Centred + Ride);
  Assert.IsTrue(HasEndAt(View, Middle + FrameWidth / 2 - Ride, BaseY));
end;

procedure TDomeFramesTests.TestFrameFarHalfBehindNearHalfInFront;
begin
  var View := ViewOf(FDef, Centred);
  Assert.IsTrue(Length(View.Far) > 0, 'A far half');
  Assert.IsTrue(Length(View.Near) > 0, 'A near half');
  for var Rib in View.Far do
    Assert.IsTrue(Rib.Z > 0, 'Far behind the centre');
  for var Rib in View.Near do
    Assert.IsTrue(Rib.Z <= 0, 'Near in front of it');
end;

procedure TDomeFramesTests.TestFrameRibsComeFarToNear;
begin
  var View := ViewOf(FDef, Centred);
  for var i := 1 to High(View.Far) do
    Assert.IsTrue(View.Far[i - 1].Z >= View.Far[i].Z, 'The far half');
  for var i := 1 to High(View.Near) do
    Assert.IsTrue(View.Near[i - 1].Z >= View.Near[i].Z, 'The near half');
end;

procedure TDomeFramesTests.TestFrameNearRibsAreThicker;
begin
  var View := ViewOf(FDef, Centred);
  var Deepest := View.Far[0];
  var Nearest := View.Near[High(View.Near)];
  Assert.IsTrue(Nearest.W > Deepest.W);
end;

procedure TDomeFramesTests.TestFrameFinerHasMoreRibs;
begin
  var Coarse := FDef;
  Coarse.Frames := Copy(FDef.Frames);
  Coarse.Frames[0].Frequency := FrameFrequency - 1;
  Assert.IsTrue(RibCount(ViewOf(FDef, Centred)) > RibCount(ViewOf(Coarse, Centred)));
end;

procedure TDomeFramesTests.TestFrameOffTheScreenShowsNothing;
begin
  // The city ridden back: the frame waits far past the right edge
  var View := ViewOf(FDef, -2 * ScreenWidth);
  Assert.AreEqual(0, RibCount(View), 'No ribs');
  Assert.AreEqual(0, Integer(Length(View.Shadows)), 'No shadows');
end;

procedure TDomeFramesTests.TestShadowsLieBetweenTheHorizonAndTheEye;
begin
  FDef.Frames[0].H := LowFrameHeight;
  AssertBetweenTheHorizonAndTheEye(ViewOf(FDef, Centred));
end;

procedure TDomeFramesTests.TestShadowsOfATallFrameLieBetweenTheHorizonAndTheEye;
begin
  AssertBetweenTheHorizonAndTheEye(ViewOf(FDef, Centred));
end;

procedure TDomeFramesTests.TestShadowsRunToTheEye;
begin
  var Reached := False;
  for var Shadow in ViewOf(FDef, Centred).Shadows do
    if Abs(NearestSample(Shadow).At.Y - EyeY) < Slack then
      Reached := True;
  Assert.IsTrue(Reached, 'A shadow runs to the eye');
end;

procedure TDomeFramesTests.TestShadowsAreSoftEdged;
begin
  var View := ViewOf(FDef, Centred);
  Assert.IsTrue(Length(View.Shadows) > 0, 'The ribs throw shadows');
  for var Shadow in View.Shadows do
    for var Sample in Shadow.Samples do
    begin
      Assert.IsTrue(Sample.OuterHalf >= Sample.CoreHalf, 'Its edge past its plateau');
      Assert.IsTrue((Sample.Peak > 0) and (Sample.Peak <= 1), 'A share of the dark');
    end;
end;

// Where a rib stands on the ring, the light runs nowhere: the whole disc is
// hidden
procedure TDomeFramesTests.TestShadowsFullyDarkAtTheFoot;
begin
  var Full := False;
  for var Shadow in ViewOf(FDef, Centred).Shadows do
    if FarthestSample(Shadow).Peak > 1 - Slack then
      Full := True;
  Assert.IsTrue(Full, 'A shadow fully dark at the foot of its rib');
end;

procedure TDomeFramesTests.TestShadowsFadeTowardTheEye;
begin
  var View := ViewOf(FDef, Centred);
  Assert.IsTrue(Length(View.Shadows) > 0, 'The ribs throw shadows');
  for var Shadow in View.Shadows do
    Assert.IsTrue(NearestSample(Shadow).Peak <= FarthestSample(Shadow).Peak + Slack,
      'Fainter at its nearer end');
end;

procedure TDomeFramesTests.TestShadowsNoneUnderASunBelowTheHorizon;
begin
  FDef.Frames[0].H := LowFrameHeight;
  FDef.Sun.Y := Horizon + 10;
  var View := ViewOf(FDef, Centred);
  Assert.IsTrue(RibCount(View) > 0, 'The frame stands');
  Assert.AreEqual(0, Integer(Length(View.Shadows)), 'No shadow');
end;

procedure TDomeFramesTests.TestRimFacesTheSun;
begin
  for var Rib in AllRibs(ViewOf(FDef, Centred)) do
  begin
    var Centre := MiddleOf(Rib);
    var Toward := Rib.Normal.X * (SunX - Centre.X) + Rib.Normal.Y * (SunY - Centre.Y);
    Assert.IsTrue(Toward >= -Slack);
  end;
end;

procedure TDomeFramesTests.TestRimBrightestByTheSun;
begin
  var Ribs := AllRibs(ViewOf(FDef, Centred));
  var Nearest := Ribs[0];
  var Farthest := Ribs[0];
  for var Rib in Ribs do
  begin
    Assert.IsTrue((Rib.Light >= 0) and (Rib.Light <= 1), 'Light within 0..1');
    if SunDistance(Rib) < SunDistance(Nearest) then
      Nearest := Rib;
    if SunDistance(Rib) > SunDistance(Farthest) then
      Farthest := Rib;
  end;
  Assert.IsTrue(Nearest.Light > Farthest.Light);
end;

// The frame with beacons above their share, and a satellite after it
function BeaconDef: TFarPlaneDef;
begin
  Result := StandDef;
  Result.Frames[0].Beacons := True;
  Result.Frames[0].BeaconsAbove := BeaconsAbove;
  var Satellite := Result.Frames[0];
  Satellite.Id := 'satellite';
  Satellite.W := SatelliteWidth;
  Satellite.H := SatelliteHeight;
  Satellite.Frequency := SatelliteFrequency;
  Satellite.BeaconsAbove := SatelliteBeaconsAbove;
  Result.Frames := Result.Frames + [Satellite];
end;

function AllBeacons(const AView: TFrameView): TArray<TFrameBeacon>;
begin
  Result := AView.FarBeacons + AView.NearBeacons;
end;

procedure TDomeFramesTests.TestBeaconsNoneWithoutTheirShare;
begin
  var View := ViewOf(FDef, Centred);
  Assert.AreEqual(0, Integer(Length(AllBeacons(View))));
end;

procedure TDomeFramesTests.TestBeaconsSitOnTheStandsNodes;
begin
  var Seeds: TArray<Cardinal> := [];
  for var Beacon in AllBeacons(ViewOf(BeaconDef, Centred)) do
    Seeds := Seeds + [Beacon.Seed];
  TArray.Sort<Cardinal>(Seeds);
  Assert.AreEqual(Integer(Length(StandBeaconSeeds)), Integer(Length(Seeds)), 'As many');
  for var i := 0 to High(Seeds) do
    Assert.AreEqual<Cardinal>(StandBeaconSeeds[i], Seeds[i], 'The same nodes');
end;

procedure TDomeFramesTests.TestBeaconsFarBehindNearInFront;
begin
  var View := ViewOf(BeaconDef, Centred);
  Assert.IsTrue(Length(View.FarBeacons) > 0, 'Some behind');
  Assert.IsTrue(Length(View.NearBeacons) > 0, 'Some in front');
  for var Beacon in View.FarBeacons do
    Assert.IsTrue(Beacon.Nearness < 1, 'Behind the centre: smaller');
  for var Beacon in View.NearBeacons do
    Assert.IsTrue(Beacon.Nearness >= 1, 'In front of it: larger');
end;

procedure TDomeFramesTests.TestBeaconsRideWithTheCity;
const
  Ride = 40;
begin
  var Before := AllBeacons(ViewOf(BeaconDef, Centred));
  var After := AllBeacons(ViewOf(BeaconDef, Centred + Ride));
  Assert.AreEqual(Integer(Length(Before)), Integer(Length(After)), 'All still in sight');
  for var i := 0 to High(Before) do
  begin
    Assert.AreEqual<Cardinal>(Before[i].Seed, After[i].Seed, 'The same beacon');
    Assert.AreEqual(Double(-Ride * Before[i].Nearness), Double(After[i].At.X - Before[i].At.X),
      Slack, 'Left by its nearness');
    Assert.AreEqual(Double(Before[i].At.Y), Double(After[i].At.Y), Slack, 'At its height');
  end;
end;

// TCapsuleFrameTests

const
  // The layout's dome-farm of the day the tests were written
  CapsuleX = 2290;
  CapsuleLength = 640;
  CapsuleDepth = 220;
  CapsuleHeight = 90;
  CapsuleRows = 12;
  CapsuleCells = 16;
  CapsuleBeltEvery = 4;
  CapsuleCapCells = 5;
  CapsuleRib = 0.85;
  CapsuleBeaconsAbove = 0.9;
  // The stand's frameRibs over it, centred
  StandCapsuleFar = 623;
  StandCapsuleNear = 649;
  StandCapsuleCrown = 26;
  StandCapsuleShadows = 320;
  StandCapsuleFarBeacons = 18;
  StandCapsuleNearBeacons = 37;
  FrameDark: TSdlColor = (R: 26; G: 23; B: 21; A: 255);

procedure TCapsuleFrameTests.Setup;
begin
  FDef := StandDef;
  var Capsule := Default(TDomeFrame);
  Capsule.Id := 'dome-farm';
  Capsule.Kind := fkCapsule;
  Capsule.X := CapsuleX;
  Capsule.W := CapsuleLength;
  Capsule.D := CapsuleDepth;
  Capsule.H := CapsuleHeight;
  Capsule.Rows := CapsuleRows;
  Capsule.Cells := CapsuleCells;
  Capsule.BeltEvery := CapsuleBeltEvery;
  Capsule.CapCells := CapsuleCapCells;
  Capsule.Rib := CapsuleRib;
  Capsule.Beacons := True;
  Capsule.BeaconsAbove := CapsuleBeaconsAbove;
  FDef.Frames := [Capsule];
end;

function TCapsuleFrameTests.Centred: Double;
begin
  Result := CapsuleX + CapsuleLength / 2 - Middle;
end;

function TCapsuleFrameTests.View: TFrameView;
begin
  var Frames := TDomeFrames.Create(FDef);
  try
    Result := Frames.View(Centred);
  finally
    Frames.Free;
  end;
end;

procedure TCapsuleFrameTests.TestRibsAreTheStands;
begin
  var Shown := View;
  Assert.AreEqual(StandCapsuleFar, Integer(Length(Shown.Far)), 'Far');
  Assert.AreEqual(StandCapsuleNear, Integer(Length(Shown.Near)), 'Near');
  for var Rib in Shown.Far do
    Assert.IsTrue(Rib.Z > 0, 'Behind its centre');
end;

procedure TCapsuleFrameTests.TestCrownStandsWithTheNearHalf;
begin
  var Crown := 0;
  for var Rib in View.Near do
    if Rib.Z = 0 then
      Inc(Crown);
  Assert.AreEqual(StandCapsuleCrown, Crown, 'The crown''s purlins, exactly between');
end;

procedure TCapsuleFrameTests.TestShadowsAreTheStands;
begin
  Assert.AreEqual(StandCapsuleShadows, Integer(Length(View.Shadows)));
end;

procedure TCapsuleFrameTests.TestBeaconsAreTheStandsEachItsOwnSeed;
begin
  var Shown := View;
  Assert.AreEqual(StandCapsuleFarBeacons, Integer(Length(Shown.FarBeacons)), 'Behind');
  Assert.AreEqual(StandCapsuleNearBeacons, Integer(Length(Shown.NearBeacons)), 'In front');
  var Seeds := TList<Cardinal>.Create;
  try
    for var Beacon in AllBeacons(Shown) do
    begin
      Assert.IsFalse(Seeds.Contains(Beacon.Seed), 'A seed of its own');
      Seeds.Add(Beacon.Seed);
    end;
  finally
    Seeds.Free;
  end;
end;

procedure TCapsuleFrameTests.TestRibsAreTheFarmsUnderTheFarm;
begin
  for var Rib in AllRibs(View) do
    Assert.IsFalse(Rib.Farm, 'No farm, no farm''s rib');
  FDef.Farm.Present := True;
  FDef.Farm.Frame := 0;
  for var Rib in AllRibs(View) do
    Assert.IsTrue(Rib.Farm, 'The farm''s');
end;

procedure TCapsuleFrameTests.TestRibsCarryTheFramesDark;
begin
  for var Rib in AllRibs(View) do
  begin
    Assert.AreEqual(Integer(FrameDark.R), Integer(Rib.Dark.R), 'Red');
    Assert.AreEqual(Integer(FrameDark.G), Integer(Rib.Dark.G), 'Green');
    Assert.AreEqual(Integer(FrameDark.B), Integer(Rib.Dark.B), 'Blue');
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TDomeFramesTests);
  TDUnitX.RegisterTestFixture(TCapsuleFrameTests);

end.
