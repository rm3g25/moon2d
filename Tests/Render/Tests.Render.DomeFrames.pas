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

  How the ribs look - the dark, the rim's colour, the smoothing of their
  edges, the glare - has no test here: none of it shows without drawing.

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
  end;

implementation

uses
  System.Math, Sdl2.Core;

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

initialization
  TDUnitX.RegisterTestFixture(TDomeFramesTests);

end.
