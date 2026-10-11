{
  Tests.Game.Uptake - a pickup taken in, counted without a window: how a
  picture is cut into crumbs, when the crumbs leave it, where they fly,
  what light they bring the body, and what a door, a death and a restart
  do to a scene on its way.

  The pictures are painted by hand, texel by texel. The hero is a pose
  with no texture and a few points of his frame, the matter is a function,
  the dice are seeded, and the light a scene gives is caught by the
  fixture. One test wires the uptake to a shroud as the game does. What
  TUptakePainter draws has no test here: that is for the eye.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Game.Uptake;

interface

uses
  DUnitX.TestFramework, Render.Brush, Render.Silhouette, Hero, Game.Shroud,
  Game.Uptake;

type
  // One feed of light the fixture caught on its way to the body
  TCaughtFeed = record
    Tint: TRgb;
    Share, Keep: Single;
  end;

  [TestFixture]
  TUptakeTests = class
  private
    FUptake: TUptake;
    // A second uptake, for the tests that run two side by side; it feeds
    // no one
    FTwin: TUptake;
    FShroud: THeroShroud;
    // What FUptake has fed, the oldest first
    FFeeds: TArray<TCaughtFeed>;
    procedure CatchFeed(ATint: TRgb; AShare, AKeep: Single);
    // A new FUptake over no matter, with nothing fed yet
    procedure UseUptake(ASeed: Cardinal);
    // A scene at the picture's place, the hero beside it
    procedure StartScene(const ALook: TUptakeLook; const AShape: TUptakeShape);
    // Ticks with the hero standing beside the pickup
    procedure Run(ACount: Integer);
    // Ticks until no scene is left, and how many it took; past ALimit the
    // test fails
    function RunOut(ALimit: Integer): Integer;
    // Runs the first scene out with the hero at APose. The crumbs seen
    // going out, each as it was on its last tick; those of the scene's last
    // tick go with the scene and are not seen
    function GoneOverTheRun(const APose: THeroPose;
      const APoints: TSeedList): TArray<TCrumb>;
    function Fed: Double;
    function FedOf(const ATint: TRgb): Double;
    procedure ExpectTakeOffFromThePaint(AMirrored: Boolean);
  public
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestSolidPictureIsCutIntoAFullGrid;
    [Test]
    procedure TestPictureWithNoPaintGivesNoCrumbs;
    [Test]
    procedure TestSpeckOfPaintIsNoCrumb;
    [Test]
    procedure TestCrumbMiddleIsTheMiddleOfItsPaint;
    [Test]
    procedure TestCrumbsTileThePictureAtAnyStep;
    [Test]
    procedure TestShortAlphaIsRefused;
    [Test]
    procedure TestStartSeatsEveryCrumbInAStillPicture;
    [Test]
    procedure TestPictureWithNoPaintStartsNoScene;
    [Test]
    procedure TestFullerCellGivesBiggerCrumb;
    [Test]
    procedure TestSceneCenterIsTheMiddleOfThePaint;
    [Test]
    procedure TestMirroredSceneIsTheSameCrumbsReflected;
    [Test]
    procedure TestPictureIsWholeWhileItFills;
    [Test]
    procedure TestEveryCrumbHasLeftWhenTheCrumblingIsOver;
    [Test]
    procedure TestTopDownEmptiesThePictureFromTheTop;
    [Test]
    procedure TestNearFirstEmptiesThePictureFromTheHerosSide;
    [Test]
    procedure TestZeroSeedStillScattersTheLeaving;
    [Test]
    procedure TestCrumbTakesOffFromTheMiddleOfItsPaint;
    [Test]
    procedure TestMirroredPictureCrumblesFromItsReflection;
    [Test]
    procedure TestCrumbGoesForAPointOfTheHerosFrame;
    [Test]
    procedure TestWithNoPointsCrumbsGoForTheMiddleOfTheFrame;
    [Test]
    procedure TestHerosLookDoesNotChangeTheScatter;
    [Test]
    procedure TestStandingHeroTakesInEveryCrumb;
    [Test]
    procedure TestSceneGivesTwiceItsPulseWhateverTickTheDoorComes;
    [Test]
    procedure TestCrumbsCatchAHeroWhoRunsAway;
    [Test]
    procedure TestCrumbGoesOutOnItsPointOfTheBody;
    [Test]
    procedure TestMirroredPoseTurnsThePointAboutTheFrame;
    [Test]
    procedure TestCrumbsFollowAHeroWhoLeaps;
    [Test]
    procedure TestSpotLivesItsTicksOnTheBody;
    [Test]
    procedure TestWreckFeedsNoOneAndLeavesNoSpots;
    [Test]
    procedure TestWreckCrumbsFallAndStopAtAFloor;
    [Test]
    procedure TestDoorGivesTheLightOfWhatWasTakenAndNoneOfAWreck;
    [Test]
    procedure TestDroppedSceneEndsWhateverTickTheHeroDies;
    [Test]
    procedure TestDroppedCrumbsFallInsteadOfVanishing;
    [Test]
    procedure TestDropChangesNothingForAWreck;
    [Test]
    procedure TestClearTakesScenesAndSpots;
    [Test]
    procedure TestClockCountsEveryTick;
    [Test]
    procedure TestScenesRunSideBySide;
    [Test]
    procedure TestRunsWithNoFeedAndNoProbe;
    [Test]
    procedure TestSameSeedGivesTheSameRun;
    [Test]
    procedure TestOtherSeedGivesAnotherRun;
    [Test]
    procedure TestTakenMedkitLightsTheBodyAndTheLightDies;
  end;

implementation

uses
  System.SysUtils, Sdl2.Core, Effects.Sparks;

const
  DefaultSeed = 7;
  OtherSeed = 1234567;
  // Seeds 1..SeedsTried, where a test must hold for any dice
  SeedsTried = 20;
  // The frame of a pickup, as of the hero
  FrameSide = 32; // units
  // The texels to a side of a 2008 frame
  FrameTexels = 64;
  // The side of a crumb the pictures below are painted for: sixteen
  // texels of a 2008 frame to a cell
  GridStep = 2; // units
  Opaque = 255;
  // Well under what counts as paint
  Faint = 40;
  // The corner of the picture on the screen, and the line it stands on
  PictureLeft = 200;
  PictureTop = 300;
  FloorLine = PictureTop + FrameSide;
  // The corner of the hero's frame as he stands beside the pickup
  NearLeft = 260;
  NearTop = 300;
  HalfFrame = HeroSize / 2;
  RunStep = 10; // units a tick: the pace of a jump in the ice suit
  LeapStep = 200; // units
  ThreeSeconds = 99; // ticks
  FiveSeconds = 165;
  PlaceSlack = 0.001; // units
  CenterSlack = 0.01;
  LightSlack = 0.0001;
  // A crumb put back over a floor may stand on its very line
  FloorSlack = 0.01; // units
  // The least number of ticks a picture takes to crumble
  MinLeavingTicks = 3;

// ---------------------------------------------------------------------------
// Pictures: FrameTexels to a side over a frame of FrameSide, unless said
// ---------------------------------------------------------------------------

function ClearPicture(ATexW, ATexH: Integer; AWidth, AHeight: Single): TUptakeShape;
begin
  Result := Default(TUptakeShape);
  Result.TexW := ATexW;
  Result.TexH := ATexH;
  Result.Width := AWidth;
  Result.Height := AHeight;
  SetLength(Result.Alpha, ATexW * ATexH);
end;

function ClearFrame: TUptakeShape;
begin
  Result := ClearPicture(FrameTexels, FrameTexels, FrameSide, FrameSide);
end;

function Texels(AX, AY, AWidth, AHeight: Integer): TSdlRect;
begin
  Result.X := AX;
  Result.Y := AY;
  Result.W := AWidth;
  Result.H := AHeight;
end;

procedure Paint(var AShape: TUptakeShape; const ATexels: TSdlRect; AAlpha: Byte);
begin
  for var Row := ATexels.Y to ATexels.Y + ATexels.H - 1 do
    for var Col := ATexels.X to ATexels.X + ATexels.W - 1 do
      AShape.Alpha[Row * AShape.TexW + Col] := AAlpha;
end;

// A frame painted all over, ATexels to a side
function SolidPicture(ATexels: Integer): TUptakeShape;
begin
  Result := ClearPicture(ATexels, ATexels, FrameSide, FrameSide);
  Paint(Result, Texels(0, 0, ATexels, ATexels), Opaque);
end;

// The case of a medkit: 20 by 16 units, standing on the bottom of the frame
function CasePicture: TUptakeShape;
begin
  Result := ClearFrame;
  Paint(Result, Texels(12, 32, 40, 32), Opaque);
end;

// One whole cell of the grid, and so one crumb
function DotPicture: TUptakeShape;
begin
  Result := ClearFrame;
  Paint(Result, Texels(28, 28, 4, 4), Opaque);
end;

// Four units wide over the whole height
function ColumnPicture: TUptakeShape;
begin
  Result := ClearFrame;
  Paint(Result, Texels(28, 0, 8, FrameTexels), Opaque);
end;

// Four units tall over the whole width
function BeamPicture: TUptakeShape;
begin
  Result := ClearFrame;
  Paint(Result, Texels(0, 28, FrameTexels, 8), Opaque);
end;

// An L with no mirror in it: a leg on the left, a foot to the right
function BootPicture: TUptakeShape;
begin
  Result := ClearFrame;
  Paint(Result, Texels(8, 8, 12, 48), Opaque);
  Paint(Result, Texels(20, 44, 30, 12), Opaque);
end;

// The middle of the opaque texels, in units from the picture's corner
function PaintMiddle(const AShape: TUptakeShape): TSdlFPoint;
begin
  var Count := 0;
  var SumX: Double := 0;
  var SumY: Double := 0;
  for var Row := 0 to AShape.TexH - 1 do
    for var Col := 0 to AShape.TexW - 1 do
    begin
      if AShape.Alpha[Row * AShape.TexW + Col] <> Opaque then
        Continue;
      Inc(Count);
      SumX := SumX + Col + 0.5;
      SumY := SumY + Row + 0.5;
    end;
  Result.X := SumX / Count * AShape.Width / AShape.TexW;
  Result.Y := SumY / Count * AShape.Height / AShape.TexH;
end;

// ---------------------------------------------------------------------------
// Looks of the tests' own: the medkit's, but for what a test is about
// ---------------------------------------------------------------------------

// Crumbs that leave without a push and stand where they left until every
// one of them has
function StillLook: TUptakeLook;
begin
  Result := MedkitUptake;
  Result.Scatter := 0;
  Result.Burst := Result.Fill + Result.Crumble;
end;

// A long crumbling in the order asked: the ends of a picture leave far apart
function OrderedLook(AOrder: TUptakeOrder): TUptakeLook;
begin
  Result := MedkitUptake;
  Result.Order := AOrder;
  Result.Crumble := 20;
end;

// Crumbs that are never pulled: they only scatter
function FreeLook: TUptakeLook;
begin
  Result := MedkitUptake;
  Result.Burst := 1000;
end;

// ---------------------------------------------------------------------------
// The hero: a pose and the points of his frame
// ---------------------------------------------------------------------------

function PointAt(AX, AY: Single): TSdlFPoint;
begin
  Result.X := AX;
  Result.Y := AY;
end;

function PoseAt(ALeft, ATop: Integer): THeroPose;
begin
  Result := Default(THeroPose);
  Result.Frame := 1;
  Result.Left := ALeft;
  Result.Top := ATop;
end;

function NearPose: THeroPose;
begin
  Result := PoseAt(NearLeft, NearTop);
end;

function MirroredNearPose: THeroPose;
begin
  Result := NearPose;
  Result.Mirrored := True;
end;

// The hero's frame right over the picture's
function OnPickupPose: THeroPose;
begin
  Result := PoseAt(PictureLeft, PictureTop);
end;

function MiddleOf(const APose: THeroPose): TSdlFPoint;
begin
  Result := PointAt(APose.Left + HalfFrame, APose.Top + HalfFrame);
end;

function BodyPoints: TSeedList;
begin
  Result := [PointAt(4, 6), PointAt(28, 26), PointAt(16, 12)];
end;

// Points by the left edge of the frame: their reflections are by the right
function LeftEdgePoints: TSeedList;
begin
  Result := [PointAt(2, 8), PointAt(2, 24)];
end;

function NoPoints: TSeedList;
begin
  Result := nil;
end;

function HoldsPoint(const APoints: TSeedList; const APoint: TSdlFPoint): Boolean;
begin
  Result := False;
  for var Point in APoints do
    if (Point.X = APoint.X) and (Point.Y = APoint.Y) then
      Exit(True);
end;

function UnderTheFloor(AX, AY: Single): Boolean;
begin
  Result := AY >= FloorLine;
end;

// ---------------------------------------------------------------------------
// Reading an uptake. Scenes and their Crumbs are the arrays the uptake
// works in, and a tick writes into them in place: what a test compares
// across a tick is copied before it.
// ---------------------------------------------------------------------------

procedure ExpectNear(AExpected, AActual: Single; const AWhat: string);
begin
  Assert.IsTrue(Abs(AExpected - AActual) < PlaceSlack,
    Format('%s: %g, not %g', [AWhat, AActual, AExpected]));
end;

procedure ExpectLight(AExpected, AActual: Double; const AWhat: string);
begin
  Assert.IsTrue(Abs(AExpected - AActual) < LightSlack,
    Format('%s: %g, not %g', [AWhat, AActual, AExpected]));
end;

function SameTint(const ALeft, ARight: TRgb): Boolean;
begin
  Result := (ALeft.R = ARight.R) and (ALeft.G = ARight.G) and (ALeft.B = ARight.B);
end;

function CountIn(const AScene: TUptakeScene; AState: TCrumbState): Integer;
begin
  Result := 0;
  for var Crumb in AScene.Crumbs do
    if Crumb.State = AState then
      Inc(Result);
end;

function CrumbsOf(const AScene: TUptakeScene): TArray<TCrumb>;
begin
  Result := Copy(AScene.Crumbs, 0, Length(AScene.Crumbs));
end;

// The crumbs in flight over every scene
function InFlight(const AUptake: TUptake): Integer;
begin
  Result := 0;
  for var Scene in AUptake.Scenes do
    Inc(Result, CountIn(Scene, csFlying));
end;

// A spot is of age 0 on the tick it appears
function Newborn(const ASpots: TArray<TBodySpot>): Integer;
begin
  Result := 0;
  for var Spot in ASpots do
    if Spot.Age = 0 then
      Inc(Result);
end;

// How far the crumb is from its point of the pose; AMirrored - the point
// turned about the middle of the frame
function Away(const ACrumb: TCrumb; const APose: THeroPose;
  AMirrored: Boolean): Single;
begin
  var PointX := ACrumb.Seed.X;
  if AMirrored then
    PointX := HeroSize - PointX;
  var OffX: Single := APose.Left + PointX - ACrumb.X;
  var OffY: Single := APose.Top + ACrumb.Seed.Y - ACrumb.Y;
  Result := Sqrt(OffX * OffX + OffY * OffY);
end;

// The tick each crumb of the first scene stopped sitting on, over ATicks
// ticks with the hero at APose; 0 for one that sits yet
function LeavingTicks(const AUptake: TUptake; ATicks: Integer;
  const APose: THeroPose): TArray<Integer>;
begin
  // Anew: a result array may come in with the ticks of the call before
  Result := nil;
  SetLength(Result, Length(AUptake.Scenes[0].Crumbs));
  for var Tick := 1 to ATicks do
  begin
    AUptake.Tick(APose, BodyPoints);
    if Length(AUptake.Scenes) = 0 then
      Exit;
    var Crumbs := AUptake.Scenes[0].Crumbs;
    for var i := 0 to High(Crumbs) do
      if (Result[i] = 0) and (Crumbs[i].State <> csSitting) then
        Result[i] := Tick;
  end;
end;

function Earliest(const ATicks: TArray<Integer>): Integer;
begin
  Result := ATicks[0];
  for var Tick in ATicks do
    if Tick < Result then
      Result := Tick;
end;

function Latest(const ATicks: TArray<Integer>): Integer;
begin
  Result := ATicks[0];
  for var Tick in ATicks do
    if Tick > Result then
      Result := Tick;
end;

// How many different ticks there are among them
function DifferentTicks(const ATicks: TArray<Integer>): Integer;
begin
  Result := 0;
  for var i := 0 to High(ATicks) do
  begin
    var IsNew := True;
    for var j := 0 to i - 1 do
      if ATicks[j] = ATicks[i] then
        IsNew := False;
    if IsNew then
      Inc(Result);
  end;
end;

function SameCrumbs(const ALeft, ARight: TUptakeScene): Boolean;
begin
  if Length(ALeft.Crumbs) <> Length(ARight.Crumbs) then
    Exit(False);
  Result := True;
  for var i := 0 to High(ALeft.Crumbs) do
    if (ALeft.Crumbs[i].State <> ARight.Crumbs[i].State) or
      (ALeft.Crumbs[i].X <> ARight.Crumbs[i].X) or
      (ALeft.Crumbs[i].Y <> ARight.Crumbs[i].Y) then
      Result := False;
end;

// Whether two uptakes are in the same state: scenes, crumbs and spots
function SameRun(const ALeft, ARight: TUptake): Boolean;
begin
  if (Length(ALeft.Scenes) <> Length(ARight.Scenes)) or
    (Length(ALeft.Spots) <> Length(ARight.Spots)) then
    Exit(False);
  Result := True;
  for var i := 0 to High(ALeft.Scenes) do
    if not SameCrumbs(ALeft.Scenes[i], ARight.Scenes[i]) then
      Result := False;
end;

// The lowest a crumb of a wreck is seen at over its whole scene, with the
// matter given
function LowestCrumbOfAWreck(ASeed: Cardinal; const ASolid: TSolidProbe): Single;
begin
  var Uptake := TUptake.Create(ASolid, nil, ASeed);
  try
    Uptake.Start(PickupBurst, 1, CasePicture, PictureLeft, PictureTop, False,
      MiddleOf(NearPose));
    Result := PictureTop;
    var Ticks := 0;
    while Length(Uptake.Scenes) > 0 do
    begin
      if Ticks = ThreeSeconds then
        Assert.Fail(Format('A wreck is still falling %d ticks on', [Ticks]));
      Uptake.Tick(NearPose, BodyPoints);
      Inc(Ticks);
      if Length(Uptake.Scenes) = 0 then
        Break;
      for var Crumb in Uptake.Scenes[0].Crumbs do
        if (Crumb.State = csFlying) and (Crumb.Y > Result) then
          Result := Crumb.Y;
    end;
  finally
    Uptake.Free;
  end;
end;

// Every texel of the source is counted once more
procedure CountTexels(var ATaken: TArray<Integer>; const ASource: TSdlRect;
  ASide: Integer);
begin
  for var Row := ASource.Y to ASource.Y + ASource.H - 1 do
    for var Col := ASource.X to ASource.X + ASource.W - 1 do
      Inc(ATaken[Row * ASide + Col]);
end;

// A solid picture of ASide texels cut with AStep: the cells lie in the
// picture and take every texel once
procedure ExpectTiling(ASide: Integer; AStep: Single);
begin
  var What := Format('A step of %g over %d texels', [AStep, ASide]);
  var Taken: TArray<Integer>;
  SetLength(Taken, ASide * ASide);
  var Cells := CutCrumbs(SolidPicture(ASide), AStep);
  Assert.IsTrue(Length(Cells) > 0, What + ' cuts nothing');

  for var Cell in Cells do
  begin
    var Source := Cell.Source;
    Assert.IsTrue((Source.W > 0) and (Source.H > 0), What + ': an empty cell');
    var IsInside := (Source.X >= 0) and (Source.Y >= 0) and
      (Source.X + Source.W <= ASide) and (Source.Y + Source.H <= ASide);
    Assert.IsTrue(IsInside, What + ': a cell reaches past the texels');
    Assert.IsTrue((Cell.X > -PlaceSlack) and (Cell.Y > -PlaceSlack),
      What + ': a cell starts before the picture');
    Assert.IsTrue((Cell.X + Cell.W < FrameSide + PlaceSlack) and
      (Cell.Y + Cell.H < FrameSide + PlaceSlack),
      What + ': a cell ends past the picture');
    CountTexels(Taken, Source, ASide);
  end;

  var Lost := 0;
  var Doubled := 0;
  for var Times in Taken do
    if Times = 0 then
      Inc(Lost)
    else if Times > 1 then
      Inc(Doubled);
  Assert.AreEqual(0, Lost, What + ': texels no cell took');
  Assert.AreEqual(0, Doubled, What + ': texels two cells took');
end;

// By value, not const: an anonymous method captures it
procedure ExpectRefused(AShape: TUptakeShape);
begin
  Assert.WillRaise(
    procedure
    begin
      CutCrumbs(AShape, GridStep);
    end, EUptakeError, 'A picture with too little alpha was cut');
end;

// ---------------------------------------------------------------------------
// The fixture's bench
// ---------------------------------------------------------------------------

procedure TUptakeTests.TearDown;
begin
  // The uptakes before the shroud: one of them may feed it
  FreeAndNil(FTwin);
  FreeAndNil(FUptake);
  FreeAndNil(FShroud);
  FFeeds := nil;
end;

procedure TUptakeTests.CatchFeed(ATint: TRgb; AShare, AKeep: Single);
begin
  var Light: TCaughtFeed;
  Light.Tint := ATint;
  Light.Share := AShare;
  Light.Keep := AKeep;
  FFeeds := FFeeds + [Light];
end;

procedure TUptakeTests.UseUptake(ASeed: Cardinal);
begin
  FreeAndNil(FUptake);
  FFeeds := nil;
  FUptake := TUptake.Create(nil, CatchFeed, ASeed);
end;

procedure TUptakeTests.StartScene(const ALook: TUptakeLook;
  const AShape: TUptakeShape);
begin
  FUptake.Start(ALook, 1, AShape, PictureLeft, PictureTop, False,
    MiddleOf(NearPose));
end;

procedure TUptakeTests.Run(ACount: Integer);
begin
  for var i := 1 to ACount do
    FUptake.Tick(NearPose, BodyPoints);
end;

function TUptakeTests.RunOut(ALimit: Integer): Integer;
begin
  Result := 0;
  while Length(FUptake.Scenes) > 0 do
  begin
    if Result = ALimit then
      Assert.Fail(Format('A scene is still going %d ticks on', [Result]));
    FUptake.Tick(NearPose, BodyPoints);
    Inc(Result);
  end;
end;

function TUptakeTests.GoneOverTheRun(const APose: THeroPose;
  const APoints: TSeedList): TArray<TCrumb>;
begin
  Result := nil;
  var Ticks := 0;
  while Length(FUptake.Scenes) > 0 do
  begin
    if Ticks = ThreeSeconds then
      Assert.Fail(Format('A scene is still going %d ticks on', [Ticks]));
    Inc(Ticks);
    var Before := CrumbsOf(FUptake.Scenes[0]);
    FUptake.Tick(APose, APoints);
    if Length(FUptake.Scenes) = 0 then
      Break;

    var After := FUptake.Scenes[0].Crumbs;
    for var i := 0 to High(After) do
      if (Before[i].State = csFlying) and (After[i].State = csGone) then
        Result := Result + [After[i]];
  end;
end;

function TUptakeTests.Fed: Double;
begin
  Result := 0;
  for var Light in FFeeds do
    Result := Result + Light.Share;
end;

function TUptakeTests.FedOf(const ATint: TRgb): Double;
begin
  Result := 0;
  for var Light in FFeeds do
    if SameTint(Light.Tint, ATint) then
      Result := Result + Light.Share;
end;

// ---------------------------------------------------------------------------
// Cutting a picture
// ---------------------------------------------------------------------------

procedure TUptakeTests.TestSolidPictureIsCutIntoAFullGrid;
const
  CellsToASide = FrameSide div GridStep;
begin
  var Cells := CutCrumbs(SolidPicture(FrameTexels), GridStep);

  Assert.AreEqual(CellsToASide * CellsToASide, Length(Cells),
    'A solid picture gives a crumb to every cell of the grid');
  for var i := 0 to High(Cells) do
  begin
    var Left: Single := (i mod CellsToASide) * GridStep;
    var Top: Single := (i div CellsToASide) * GridStep;
    ExpectNear(Left, Cells[i].X, 'A cell stands in its column, in rows from the top');
    ExpectNear(Top, Cells[i].Y, 'A cell stands in its row');
    ExpectNear(GridStep, Cells[i].W, 'The width of a cell');
    ExpectNear(GridStep, Cells[i].H, 'The height of a cell');
    ExpectNear(1, Cells[i].Cover, 'The cover of a cell painted all over');
    ExpectNear(Left + GridStep / 2, Cells[i].MidX, 'The middle of a whole cell');
    ExpectNear(Top + GridStep / 2, Cells[i].MidY, 'The middle of a whole cell');
  end;
end;

procedure TUptakeTests.TestPictureWithNoPaintGivesNoCrumbs;
begin
  Assert.AreEqual(0, Length(CutCrumbs(ClearFrame, GridStep)),
    'A clear picture has nothing to crumble');

  var Veil := ClearFrame;
  Paint(Veil, Texels(0, 0, FrameTexels, FrameTexels), Faint);
  Assert.AreEqual(0, Length(CutCrumbs(Veil, GridStep)),
    'A faint veil over the whole frame is no paint');
end;

procedure TUptakeTests.TestSpeckOfPaintIsNoCrumb;
const
  CellTexels = 16;
begin
  // One texel in the first cell of the top row, two in the third
  var Shape := ClearFrame;
  Paint(Shape, Texels(0, 0, 1, 1), Opaque);
  Paint(Shape, Texels(8, 0, 2, 1), Opaque);

  var Cells := CutCrumbs(Shape, GridStep);

  Assert.AreEqual(1, Length(Cells), 'One texel of sixteen is no crumb, two are');
  ExpectNear(2 * GridStep, Cells[0].X, 'The crumb is the cell with two texels');
  ExpectNear(2 / CellTexels, Cells[0].Cover, 'and its cover is their share of it');
end;

procedure TUptakeTests.TestCrumbMiddleIsTheMiddleOfItsPaint;
const
  Step = 4; // units
begin
  // 16 by 8 units in 16 by 4 texels: a texel is a unit wide and two tall.
  // The paint is the fourth column of the first cell, top to bottom
  var Shape := ClearPicture(16, 4, 16, 8);
  Paint(Shape, Texels(3, 0, 1, 2), Opaque);

  var Cells := CutCrumbs(Shape, Step);

  Assert.AreEqual(1, Length(Cells), 'The paint lies in one cell');
  ExpectNear(0, Cells[0].X, 'The cell is the first of its row');
  ExpectNear(0, Cells[0].Y, 'in the first row');
  ExpectNear(Step, Cells[0].W, 'A cell is a step wide whatever a texel is');
  ExpectNear(Step, Cells[0].H, 'and a step tall');
  ExpectNear(2 / 8, Cells[0].Cover, 'Two texels of its eight are painted');
  ExpectNear(3.5, Cells[0].MidX, 'The middle is the paint''s, not the cell''s');
  ExpectNear(2, Cells[0].MidY, 'on both axes');
end;

procedure TUptakeTests.TestCrumbsTileThePictureAtAnyStep;
const
  // A 2008 frame, the HD medkit, and a side no step divides
  Sides: array [0..2] of Integer = (64, 192, 50);
  // Steps that divide the frame, that do not, under a texel and over the frame
  Steps: array [0..7] of Single = (2, 3, 1.5, 2.5, 0.7, 5, 32, 40);
begin
  for var Side in Sides do
    for var Step in Steps do
      ExpectTiling(Side, Step);
end;

procedure TUptakeTests.TestShortAlphaIsRefused;
begin
  var Shape := SolidPicture(FrameTexels);
  SetLength(Shape.Alpha, Length(Shape.Alpha) - 1);

  ExpectRefused(Shape);
end;

// ---------------------------------------------------------------------------
// A scene begins
// ---------------------------------------------------------------------------

procedure TUptakeTests.TestStartSeatsEveryCrumbInAStillPicture;
const
  PictureNumber = 5;
  Left = 40;
  Top = 70;
begin
  UseUptake(DefaultSeed);

  FUptake.Start(WeaponUptake, PictureNumber, CasePicture, Left, Top, True,
    MiddleOf(NearPose));

  Assert.AreEqual(1, Length(FUptake.Scenes), 'A start makes one scene');
  var Scene := FUptake.Scenes[0];
  Assert.AreEqual(PictureNumber, Scene.Picture, 'The scene carries the painter''s picture');
  ExpectNear(Left, Scene.Left, 'and the corner it was started at');
  ExpectNear(Top, Scene.Top, 'and the corner it was started at');
  Assert.IsTrue(Scene.Mirrored, 'and the way the picture is turned');
  Assert.IsTrue(SameTint(WeaponUptake.Tint, Scene.Look.Tint), 'and its look');
  Assert.AreEqual(0, Scene.Age, 'A new scene is of age 0');
  Assert.AreEqual(Length(CutCrumbs(CasePicture, WeaponUptake.Crumb)),
    Length(Scene.Crumbs), 'It has the crumbs the picture is cut into');
  Assert.AreEqual(Length(Scene.Crumbs), CountIn(Scene, csSitting),
    'and every one of them sits');
  Assert.AreEqual(0, Length(FFeeds), 'A start feeds no one');
  Assert.AreEqual(0, Length(FUptake.Spots), 'and lights no spot');
end;

procedure TUptakeTests.TestPictureWithNoPaintStartsNoScene;
begin
  UseUptake(DefaultSeed);

  StartScene(MedkitUptake, ClearFrame);
  Run(10);

  Assert.AreEqual(0, Length(FUptake.Scenes), 'A clear picture starts no scene');
  Assert.AreEqual(0, Length(FFeeds), 'and gives no light');
end;

procedure TUptakeTests.TestFullerCellGivesBiggerCrumb;
begin
  // A whole cell, and after it in the row a cell a quarter painted
  var Shape := ClearFrame;
  Paint(Shape, Texels(0, 0, 4, 4), Opaque);
  Paint(Shape, Texels(8, 0, 2, 2), Opaque);
  UseUptake(DefaultSeed);

  StartScene(MedkitUptake, Shape);

  var Crumbs := FUptake.Scenes[0].Crumbs;
  Assert.AreEqual(2, Length(Crumbs), 'Two cells hold paint');
  Assert.IsTrue(Crumbs[1].Size > 0, 'A crumb of little paint still has a size');
  Assert.IsTrue(Crumbs[0].Size > Crumbs[1].Size, 'and a fuller cell gives a bigger one');
end;

procedure TUptakeTests.TestSceneCenterIsTheMiddleOfThePaint;
begin
  // The boot, and a cell half painted at its toe
  var Shape := BootPicture;
  Paint(Shape, Texels(52, 52, 2, 4), Opaque);
  var Middle := PaintMiddle(Shape);
  UseUptake(DefaultSeed);

  StartScene(MedkitUptake, Shape);
  FUptake.Start(MedkitUptake, 2, Shape, PictureLeft, PictureTop, True,
    MiddleOf(NearPose));

  var Plain := FUptake.Scenes[0];
  var Turned := FUptake.Scenes[1];
  Assert.IsTrue(Abs(Plain.CenterX - Middle.X) < CenterSlack,
    Format('The center is at x = %g, the paint''s middle at %g', [Plain.CenterX, Middle.X]));
  Assert.IsTrue(Abs(Plain.CenterY - Middle.Y) < CenterSlack,
    Format('The center is at y = %g, the paint''s middle at %g', [Plain.CenterY, Middle.Y]));
  Assert.IsTrue(Abs(Turned.CenterX - (FrameSide - Middle.X)) < CenterSlack,
    'A mirrored picture has its center reflected');
  Assert.IsTrue(Abs(Turned.CenterY - Middle.Y) < CenterSlack,
    'and at the same height');
end;

procedure TUptakeTests.TestMirroredSceneIsTheSameCrumbsReflected;
begin
  // A step that does not divide the frame: the last column is a narrow one
  var Look := MedkitUptake;
  Look.Crumb := 3;
  UseUptake(DefaultSeed);

  StartScene(Look, BootPicture);
  FUptake.Start(Look, 2, BootPicture, PictureLeft, PictureTop, True,
    MiddleOf(NearPose));

  var Plain := FUptake.Scenes[0].Crumbs;
  var Turned := FUptake.Scenes[1].Crumbs;
  Assert.IsTrue(Length(Plain) > 0, 'The boot has crumbs');
  Assert.AreEqual(Length(Plain), Length(Turned), 'The mirror changes no count');
  for var i := 0 to High(Plain) do
  begin
    ExpectNear(FrameSide - Plain[i].Cell.X - Plain[i].Cell.W, Turned[i].Cell.X,
      'A cell is reflected in the frame');
    ExpectNear(FrameSide - Plain[i].Cell.MidX, Turned[i].Cell.MidX,
      'and the middle of its paint with it');
    ExpectNear(Plain[i].Cell.Y, Turned[i].Cell.Y, 'The mirror moves nothing up or down');
    ExpectNear(Plain[i].Cell.MidY, Turned[i].Cell.MidY,
      'The mirror moves nothing up or down');
    ExpectNear(Plain[i].Cell.W, Turned[i].Cell.W, 'A cell keeps its width');
    ExpectNear(Plain[i].Cell.Cover, Turned[i].Cell.Cover, 'and its paint');
  end;
end;

// ---------------------------------------------------------------------------
// The order of leaving
// ---------------------------------------------------------------------------

procedure TUptakeTests.TestPictureIsWholeWhileItFills;
begin
  UseUptake(DefaultSeed);
  FUptake.Start(MedkitUptake, 1, CasePicture, PictureLeft, PictureTop, False,
    MiddleOf(OnPickupPose));

  for var Tick := 1 to MedkitUptake.Fill - 1 do
  begin
    FUptake.Tick(OnPickupPose, BodyPoints);
    var Scene := FUptake.Scenes[0];
    Assert.AreEqual(Tick, Scene.Age, 'A scene is a tick older every tick');
    Assert.AreEqual(Length(Scene.Crumbs), CountIn(Scene, csSitting),
      Format('A crumb left on tick %d, while the picture fills', [Tick]));
  end;

  Assert.AreEqual(0, Length(FFeeds), 'No light comes before the picture is full');
  Assert.AreEqual(0, Length(FUptake.Spots), 'and no spot');
end;

procedure TUptakeTests.TestEveryCrumbHasLeftWhenTheCrumblingIsOver;
begin
  UseUptake(DefaultSeed);
  StartScene(MedkitUptake, CasePicture);

  var LeftOn := LeavingTicks(FUptake, MedkitUptake.Fill + MedkitUptake.Crumble,
    NearPose);

  Assert.IsTrue(Earliest(LeftOn) > 0, 'A crumb sits on after the crumbling');
  Assert.IsTrue(DifferentTicks(LeftOn) >= MinLeavingTicks,
    Format('The crumbs left on %d ticks: the picture vanished',
      [DifferentTicks(LeftOn)]));
end;

procedure TUptakeTests.TestTopDownEmptiesThePictureFromTheTop;
begin
  var Look := OrderedLook(uoTopDown);
  UseUptake(DefaultSeed);
  StartScene(Look, ColumnPicture);
  var Seated := CrumbsOf(FUptake.Scenes[0]);

  var LeftOn := LeavingTicks(FUptake, Look.Fill + Look.Crumble, NearPose);

  var TopRow: TArray<Integer> := nil;
  var BottomRow: TArray<Integer> := nil;
  for var i := 0 to High(Seated) do
    if Seated[i].Cell.Y < GridStep then
      TopRow := TopRow + [LeftOn[i]]
    else if Seated[i].Cell.Y >= FrameSide - GridStep then
      BottomRow := BottomRow + [LeftOn[i]];
  Assert.IsTrue((Length(TopRow) > 0) and (Length(BottomRow) > 0),
    'The column reaches the top and the bottom of the frame');
  Assert.IsTrue(Earliest(LeftOn) > 0, 'Every crumb has left');
  Assert.IsTrue(Latest(TopRow) < Earliest(BottomRow),
    Format('The top row was there until tick %d, the bottom left from tick %d',
      [Latest(TopRow), Earliest(BottomRow)]));
end;

// The ticks the left end and the right end of a beam left on, with the
// hero's frame AHeroLeft units along the screen
procedure LeaveBeamEnds(const AUptake: TUptake; AHeroLeft: Integer;
  out ALeftEnd, ARightEnd: TArray<Integer>);
begin
  var Look := OrderedLook(uoNearFirst);
  var Pose := PoseAt(AHeroLeft, PictureTop);
  AUptake.Start(Look, 1, BeamPicture, PictureLeft, PictureTop, False,
    MiddleOf(Pose));
  var Seated := CrumbsOf(AUptake.Scenes[0]);

  var LeftOn := LeavingTicks(AUptake, Look.Fill + Look.Crumble, Pose);

  ALeftEnd := nil;
  ARightEnd := nil;
  for var i := 0 to High(Seated) do
    if Seated[i].Cell.X < GridStep then
      ALeftEnd := ALeftEnd + [LeftOn[i]]
    else if Seated[i].Cell.X >= FrameSide - GridStep then
      ARightEnd := ARightEnd + [LeftOn[i]];
  Assert.IsTrue((Length(ALeftEnd) > 0) and (Length(ARightEnd) > 0),
    'The beam reaches both sides of the frame');
  Assert.IsTrue(Earliest(LeftOn) > 0, 'Every crumb has left');
end;

procedure TUptakeTests.TestNearFirstEmptiesThePictureFromTheHerosSide;
const
  Aside = 100; // units
var
  LeftEnd, RightEnd: TArray<Integer>;
begin
  UseUptake(DefaultSeed);
  LeaveBeamEnds(FUptake, PictureLeft - Aside, LeftEnd, RightEnd);
  Assert.IsTrue(Latest(LeftEnd) < Earliest(RightEnd),
    'With the hero on the left the left end leaves first');

  UseUptake(DefaultSeed);
  LeaveBeamEnds(FUptake, PictureLeft + Aside, LeftEnd, RightEnd);
  Assert.IsTrue(Latest(RightEnd) < Earliest(LeftEnd),
    'With the hero on the right the right end leaves first');
end;

procedure TUptakeTests.TestZeroSeedStillScattersTheLeaving;
begin
  UseUptake(0);
  StartScene(MedkitUptake, CasePicture);

  var LeftOn := LeavingTicks(FUptake, MedkitUptake.Fill + MedkitUptake.Crumble,
    NearPose);

  Assert.IsTrue(DifferentTicks(LeftOn) >= MinLeavingTicks,
    Format('With a zero seed the crumbs left on %d ticks', [DifferentTicks(LeftOn)]));
end;

// ---------------------------------------------------------------------------
// Leaving the picture
// ---------------------------------------------------------------------------

procedure TUptakeTests.ExpectTakeOffFromThePaint(AMirrored: Boolean);
begin
  var Look := StillLook;
  var Cut := CutCrumbs(BootPicture, Look.Crumb);
  UseUptake(DefaultSeed);
  FUptake.Start(Look, 1, BootPicture, PictureLeft, PictureTop, AMirrored,
    MiddleOf(NearPose));

  var Seen := 0;
  for var i := 1 to Look.Fill + Look.Crumble do
  begin
    Run(1);
    var Crumbs := FUptake.Scenes[0].Crumbs;
    for var j := 0 to High(Crumbs) do
    begin
      if Crumbs[j].State <> csFlying then
        Continue;
      var MidX := Cut[j].MidX;
      if AMirrored then
        MidX := FrameSide - MidX;
      ExpectNear(PictureLeft + MidX, Crumbs[j].X, 'A crumb takes off from its paint');
      ExpectNear(PictureTop + Cut[j].MidY, Crumbs[j].Y, 'A crumb takes off from its paint');
      Inc(Seen);
    end;
  end;
  Assert.IsTrue(Seen > 0, 'Crumbs did leave the picture');
end;

procedure TUptakeTests.TestCrumbTakesOffFromTheMiddleOfItsPaint;
begin
  ExpectTakeOffFromThePaint(False);
end;

procedure TUptakeTests.TestMirroredPictureCrumblesFromItsReflection;
begin
  ExpectTakeOffFromThePaint(True);
end;

procedure TUptakeTests.TestCrumbGoesForAPointOfTheHerosFrame;
begin
  var Points := BodyPoints;
  var Used: TSeedList := nil;
  UseUptake(DefaultSeed);
  StartScene(MedkitUptake, CasePicture);

  for var i := 1 to MedkitUptake.Fill + MedkitUptake.Crumble do
  begin
    Run(1);
    for var Crumb in FUptake.Scenes[0].Crumbs do
    begin
      if Crumb.State = csSitting then
        Continue;
      Assert.IsTrue(HoldsPoint(Points, Crumb.Seed),
        Format('A crumb goes for (%g, %g), no point of the frame',
          [Crumb.Seed.X, Crumb.Seed.Y]));
      if not HoldsPoint(Used, Crumb.Seed) then
        Used := Used + [Crumb.Seed];
    end;
  end;

  Assert.AreEqual(Length(Points), Length(Used), 'Every point of the frame gets its crumbs');
end;

procedure TUptakeTests.TestWithNoPointsCrumbsGoForTheMiddleOfTheFrame;
begin
  UseUptake(DefaultSeed);
  StartScene(MedkitUptake, CasePicture);

  for var i := 1 to MedkitUptake.Fill + MedkitUptake.Crumble do
  begin
    FUptake.Tick(NearPose, NoPoints);
    for var Crumb in FUptake.Scenes[0].Crumbs do
    begin
      if Crumb.State = csSitting then
        Continue;
      ExpectNear(HalfFrame, Crumb.Seed.X, 'With no points a crumb goes for the middle');
      ExpectNear(HalfFrame, Crumb.Seed.Y, 'With no points a crumb goes for the middle');
    end;
  end;

  RunOut(ThreeSeconds);
  ExpectLight(2 * MedkitUptake.Pulse, Fed, 'The light of the scene');
end;

procedure TUptakeTests.TestHerosLookDoesNotChangeTheScatter;
begin
  UseUptake(DefaultSeed);
  FTwin := TUptake.Create(nil, nil, DefaultSeed);
  StartScene(FreeLook, CasePicture);
  FTwin.Start(FreeLook, 1, CasePicture, PictureLeft, PictureTop, False,
    MiddleOf(NearPose));

  var Flying := 0;
  var Diverged := 0;
  for var i := 1 to MedkitUptake.Fill + MedkitUptake.Crumble + 5 do
  begin
    FUptake.Tick(NearPose, BodyPoints);
    FTwin.Tick(NearPose, NoPoints);
    if not SameRun(FUptake, FTwin) then
      Inc(Diverged);
    Inc(Flying, InFlight(FUptake));
  end;

  Assert.AreEqual(0, Diverged, 'The picture crumbles by what the hero looks like');
  Assert.IsTrue(Flying > 0, 'There were crumbs in flight to compare');
end;

// ---------------------------------------------------------------------------
// Into the body
// ---------------------------------------------------------------------------

procedure TUptakeTests.TestStandingHeroTakesInEveryCrumb;
begin
  UseUptake(DefaultSeed);
  StartScene(MedkitUptake, CasePicture);
  var Count := Length(FUptake.Scenes[0].Crumbs);

  var Spots := 0;
  var Ticks := 0;
  while Length(FUptake.Scenes) > 0 do
  begin
    if Ticks = ThreeSeconds then
      Assert.Fail(Format('The scene is still going %d ticks on', [Ticks]));
    Run(1);
    Inc(Ticks);
    Inc(Spots, Newborn(FUptake.Spots));
  end;

  Assert.AreEqual(Count, Length(FFeeds), 'Every crumb feeds the body once');
  Assert.AreEqual(Count, Spots, 'and lights one spot on it');
  for var Light in FFeeds do
  begin
    Assert.IsTrue(SameTint(MedkitUptake.Tint, Light.Tint), 'The light is the look''s');
    Assert.IsTrue(Abs(Light.Share - FFeeds[0].Share) < LightSlack / 100,
      'Every crumb brings the same share');
    Assert.IsTrue((Light.Keep > 0) and (Light.Keep < 1), 'The light is fed to fade');
  end;
end;

procedure TUptakeTests.TestSceneGivesTwiceItsPulseWhateverTickTheDoorComes;
begin
  UseUptake(DefaultSeed);
  StartScene(MedkitUptake, CasePicture);
  var SceneTicks := RunOut(ThreeSeconds);

  // From a door at once to a door after the scene is over
  for var Door := 0 to SceneTicks + 2 do
  begin
    UseUptake(DefaultSeed);
    StartScene(MedkitUptake, CasePicture);
    Run(Door);

    FUptake.Settle;

    ExpectLight(2 * MedkitUptake.Pulse, Fed,
      Format('The light of a scene with a door on tick %d', [Door]));
    Assert.AreEqual(0, Length(FUptake.Scenes), 'A door leaves no scene');
    Assert.AreEqual(0, Length(FUptake.Spots), 'and no spot');
    var Given := Length(FFeeds);
    Run(20);
    Assert.AreEqual(Given, Length(FFeeds), 'Nothing is fed behind the door');
  end;
end;

procedure TUptakeTests.TestCrumbsCatchAHeroWhoRunsAway;
begin
  for var Seed := 1 to SeedsTried do
  begin
    UseUptake(Seed);
    StartScene(MedkitUptake, CasePicture);

    var Ticks := 0;
    while Length(FUptake.Scenes) > 0 do
    begin
      if Ticks = FiveSeconds then
        Assert.Fail(Format('Seed %d: the hero outruns the crumbs', [Seed]));
      Inc(Ticks);
      FUptake.Tick(PoseAt(NearLeft + RunStep * Ticks, NearTop), BodyPoints);
    end;

    ExpectLight(2 * MedkitUptake.Pulse, Fed, Format('Seed %d: the light', [Seed]));
  end;
end;

procedure TUptakeTests.TestCrumbGoesOutOnItsPointOfTheBody;
begin
  var Seen := 0;
  for var Seed := 1 to SeedsTried do
  begin
    UseUptake(Seed);
    StartScene(MedkitUptake, CasePicture);
    for var Crumb in GoneOverTheRun(NearPose, BodyPoints) do
    begin
      var Off := Away(Crumb, NearPose, False);
      Assert.IsTrue(Off < HalfFrame,
        Format('Seed %d: a crumb went out %g units from its point', [Seed, Off]));
      Inc(Seen);
    end;
  end;
  Assert.IsTrue(Seen > 0, 'Crumbs were seen going out');
end;

procedure TUptakeTests.TestMirroredPoseTurnsThePointAboutTheFrame;
begin
  var Pose := MirroredNearPose;
  var Seen := 0;
  for var Seed := 1 to SeedsTried do
  begin
    UseUptake(Seed);
    StartScene(MedkitUptake, CasePicture);
    for var Crumb in GoneOverTheRun(Pose, LeftEdgePoints) do
    begin
      var Off := Away(Crumb, Pose, True);
      Assert.IsTrue(Off < Away(Crumb, Pose, False),
        Format('Seed %d: a crumb went out by the point as painted', [Seed]));
      Assert.IsTrue(Off < HalfFrame,
        Format('Seed %d: a crumb went out %g units from its point', [Seed, Off]));
      Inc(Seen);
    end;
  end;
  Assert.IsTrue(Seen > 0, 'Crumbs were seen going out');
end;

procedure TUptakeTests.TestCrumbsFollowAHeroWhoLeaps;
begin
  var There := PoseAt(NearLeft + LeapStep, NearTop - LeapStep);
  UseUptake(DefaultSeed);
  StartScene(MedkitUptake, CasePicture);
  // The first crumbs are in the air and none is home
  Run(MedkitUptake.Fill + 1);
  Assert.AreEqual(0, Length(FFeeds), 'No crumb is home before the leap');

  var Seen := 0;
  for var Crumb in GoneOverTheRun(There, BodyPoints) do
  begin
    var Off := Away(Crumb, There, False);
    Assert.IsTrue(Off < FrameSide,
      Format('A crumb went out %g units from where the hero is', [Off]));
    Inc(Seen);
  end;
  Assert.IsTrue(Seen > 0, 'Crumbs were seen going out');
end;

procedure TUptakeTests.TestSpotLivesItsTicksOnTheBody;
begin
  UseUptake(DefaultSeed);
  StartScene(MedkitUptake, DotPicture);
  Assert.AreEqual(1, Length(FUptake.Scenes[0].Crumbs), 'The dot is one crumb');
  var Size := FUptake.Scenes[0].Crumbs[0].Size;

  var Waited := 0;
  while Length(FUptake.Spots) = 0 do
  begin
    if Waited = ThreeSeconds then
      Assert.Fail('The crumb left no spot');
    Run(1);
    Inc(Waited);
  end;

  Assert.AreEqual(0, Length(FUptake.Scenes), 'The scene is over with its last crumb');
  Assert.AreEqual(1, Length(FUptake.Spots), 'One crumb lights one spot');
  var Spot := FUptake.Spots[0];
  Assert.IsTrue(HoldsPoint(BodyPoints, Spot.Seed), 'The spot is on a point of the frame');
  Assert.IsTrue(SameTint(MedkitUptake.Tint, Spot.Tint), 'in the color of the look');
  Assert.IsTrue(Size > 0, 'The crumb had a size');
  ExpectNear(Size, Spot.Size, 'and the spot is of the size of its crumb');

  var Shown := 0;
  while Length(FUptake.Spots) > 0 do
  begin
    if Shown > SpotTicks then
      Assert.Fail('The spot never goes out');
    Assert.AreEqual(Shown, FUptake.Spots[0].Age, 'A spot is a tick older every tick');
    Inc(Shown);
    Run(1);
  end;
  Assert.AreEqual(SpotTicks, Shown, 'The ticks a spot is seen on');
end;

// ---------------------------------------------------------------------------
// A wreck: the pickup was destroyed, not taken
// ---------------------------------------------------------------------------

procedure TUptakeTests.TestWreckFeedsNoOneAndLeavesNoSpots;
begin
  UseUptake(DefaultSeed);
  FUptake.Start(PickupBurst, 1, CasePicture, PictureLeft, PictureTop, False,
    MiddleOf(OnPickupPose));

  var Flew := 0;
  var Ticks := 0;
  while Length(FUptake.Scenes) > 0 do
  begin
    if Ticks = ThreeSeconds then
      Assert.Fail(Format('The wreck is still falling %d ticks on', [Ticks]));
    FUptake.Tick(OnPickupPose, BodyPoints);
    Inc(Ticks);
    Inc(Flew, InFlight(FUptake));
    Assert.AreEqual(0, Length(FUptake.Spots), 'A wreck lights no spot on the hero');
  end;

  Assert.IsTrue(Flew > 0, 'The wreck did crumble');
  Assert.AreEqual(0, Length(FFeeds), 'A wreck feeds no one, though the hero stands in it');
end;

procedure TUptakeTests.TestWreckCrumbsFallAndStopAtAFloor;
begin
  for var Seed := 1 to SeedsTried do
  begin
    var OverFloor := LowestCrumbOfAWreck(Seed, UnderTheFloor);
    Assert.IsTrue(OverFloor < FloorLine + FloorSlack,
      Format('Seed %d: a crumb is at y = %g, under the floor', [Seed, OverFloor]));

    var InTheOpen := LowestCrumbOfAWreck(Seed, nil);
    Assert.IsTrue(InTheOpen > FloorLine + FrameSide,
      Format('Seed %d: with no floor the crumbs fell only to y = %g', [Seed, InTheOpen]));
  end;
end;

procedure TUptakeTests.TestDoorGivesTheLightOfWhatWasTakenAndNoneOfAWreck;
begin
  UseUptake(DefaultSeed);
  StartScene(MedkitUptake, CasePicture);
  StartScene(PickupBurst, CasePicture);
  Run(3);

  FUptake.Settle;

  Assert.IsTrue(Length(FFeeds) > 0, 'The door gives light');
  for var Light in FFeeds do
    Assert.IsTrue(SameTint(MedkitUptake.Tint, Light.Tint),
      'A wreck gives the hero no light at a door');
  ExpectLight(2 * MedkitUptake.Pulse, Fed, 'The light of the medkit alone');
  Assert.AreEqual(0, Length(FUptake.Scenes), 'A door ends the wreck too');
end;

// ---------------------------------------------------------------------------
// The hero dies
// ---------------------------------------------------------------------------

procedure TUptakeTests.TestDroppedSceneEndsWhateverTickTheHeroDies;
begin
  UseUptake(DefaultSeed);
  StartScene(MedkitUptake, CasePicture);
  var SceneTicks := RunOut(ThreeSeconds);

  for var Death := 0 to SceneTicks - 1 do
  begin
    UseUptake(DefaultSeed);
    StartScene(MedkitUptake, CasePicture);
    Run(Death);
    var Given := Length(FFeeds);

    FUptake.Drop;

    Assert.AreEqual(0, Length(FUptake.Spots), 'A death puts the spots out');
    var Ticks := 0;
    while Length(FUptake.Scenes) > 0 do
    begin
      if Ticks = ThreeSeconds then
        Assert.Fail(Format('A death on tick %d: the scene never ends', [Death]));
      Run(1);
      Inc(Ticks);
      Assert.AreEqual(0, Length(FUptake.Spots),
        Format('A death on tick %d: a crumb went into the body', [Death]));
    end;
    Assert.AreEqual(Given, Length(FFeeds),
      Format('A death on tick %d: the dead hero was fed', [Death]));
  end;
end;

procedure TUptakeTests.TestDroppedCrumbsFallInsteadOfVanishing;
const
  FallTicks = 10;
begin
  UseUptake(DefaultSeed);
  StartScene(MedkitUptake, CasePicture);
  Run(MedkitUptake.Fill + MedkitUptake.Crumble);
  var AtDeath := CrumbsOf(FUptake.Scenes[0]);

  FUptake.Drop;
  Run(FallTicks);

  Assert.AreEqual(1, Length(FUptake.Scenes), 'The scene goes on after the death');
  var Crumbs := FUptake.Scenes[0].Crumbs;
  var Falling := 0;
  for var i := 0 to High(Crumbs) do
  begin
    if AtDeath[i].State <> csFlying then
      Continue;
    Assert.AreEqual<TCrumbState>(csFlying, Crumbs[i].State,
      'A crumb in flight at the death is still in flight');
    Assert.IsTrue(Crumbs[i].SpeedY > AtDeath[i].SpeedY, 'and it has been falling');
    Inc(Falling);
  end;
  Assert.IsTrue(Falling > 0, 'There were crumbs in flight at the death');
end;

procedure TUptakeTests.TestDropChangesNothingForAWreck;
begin
  UseUptake(DefaultSeed);
  FTwin := TUptake.Create(nil, nil, DefaultSeed);
  StartScene(PickupBurst, CasePicture);
  FTwin.Start(PickupBurst, 1, CasePicture, PictureLeft, PictureTop, False,
    MiddleOf(NearPose));
  for var i := 1 to PickupBurst.Fill + PickupBurst.Crumble do
  begin
    FUptake.Tick(NearPose, BodyPoints);
    FTwin.Tick(NearPose, BodyPoints);
  end;
  Assert.IsTrue(InFlight(FUptake) > 0, 'The wreck is in the air');

  FTwin.Drop;

  var Diverged := 0;
  var Ticks := 0;
  while (Length(FUptake.Scenes) > 0) or (Length(FTwin.Scenes) > 0) do
  begin
    if Ticks = ThreeSeconds then
      Assert.Fail(Format('A wreck is still falling %d ticks on', [Ticks]));
    FUptake.Tick(NearPose, BodyPoints);
    FTwin.Tick(NearPose, BodyPoints);
    Inc(Ticks);
    if not SameRun(FUptake, FTwin) then
      Inc(Diverged);
  end;
  Assert.AreEqual(0, Diverged, 'The hero''s death changed the fall of a wreck');
end;

// ---------------------------------------------------------------------------
// A restart, the clock, scenes side by side
// ---------------------------------------------------------------------------

procedure TUptakeTests.TestClearTakesScenesAndSpots;
begin
  UseUptake(DefaultSeed);
  StartScene(MedkitUptake, CasePicture);
  var Waited := 0;
  while Length(FUptake.Spots) = 0 do
  begin
    if Waited = ThreeSeconds then
      Assert.Fail('No crumb came home');
    Run(1);
    Inc(Waited);
  end;
  Assert.AreEqual(1, Length(FUptake.Scenes), 'The scene is on its way');
  var Given := Length(FFeeds);

  FUptake.Clear;

  Assert.AreEqual(0, Length(FUptake.Scenes), 'A restart leaves no scene');
  Assert.AreEqual(0, Length(FUptake.Spots), 'and no spot');
  Run(ThreeSeconds);
  Assert.AreEqual(Given, Length(FFeeds), 'and nothing is fed after it');
  Assert.AreEqual(0, Length(FUptake.Spots), 'nor lit');
end;

procedure TUptakeTests.TestClockCountsEveryTick;
begin
  UseUptake(DefaultSeed);
  Assert.AreEqual(0, FUptake.Clock, 'A new uptake has counted nothing');

  Run(5);
  Assert.AreEqual(5, FUptake.Clock, 'The clock runs with no scene');

  StartScene(MedkitUptake, CasePicture);
  Run(7);
  FUptake.Clear;
  Assert.AreEqual(12, FUptake.Clock, 'A restart leaves the clock as it was');

  Run(3);
  Assert.AreEqual(15, FUptake.Clock, 'and it runs on');
end;

procedure TUptakeTests.TestScenesRunSideBySide;
const
  // The early scenes are crumbling by then
  Late = 8; // ticks
  DotNumber = 1;
  WeaponNumber = 2;
  LateNumber = 3;
var
  Began: array [DotNumber..LateNumber] of Integer;
begin
  UseUptake(DefaultSeed);
  StartScene(MedkitUptake, DotPicture);
  FUptake.Start(WeaponUptake, WeaponNumber, CasePicture, PictureLeft, PictureTop,
    False, MiddleOf(NearPose));
  Run(Late);
  FUptake.Start(MedkitUptake, LateNumber, CasePicture, PictureLeft, PictureTop,
    False, MiddleOf(NearPose));
  Assert.AreEqual(3, Length(FUptake.Scenes), 'Three scenes are going at once');
  for var Scene in FUptake.Scenes do
    Began[Scene.Picture] := Length(Scene.Crumbs);

  for var i := 1 to MedkitUptake.Fill - 1 do
  begin
    Run(1);
    var LateScene := FUptake.Scenes[High(FUptake.Scenes)];
    Assert.AreEqual(LateNumber, LateScene.Picture, 'The late scene is the last');
    Assert.AreEqual(Length(LateScene.Crumbs), CountIn(LateScene, csSitting),
      'The late picture crumbles by the clock of another');
  end;

  var Ticks := 0;
  while Length(FUptake.Scenes) > 0 do
  begin
    if Ticks = ThreeSeconds then
      Assert.Fail(Format('The scenes are still going %d ticks on', [Ticks]));
    Run(1);
    Inc(Ticks);
    var LastNumber := 0;
    for var Scene in FUptake.Scenes do
    begin
      Assert.IsTrue(Scene.Picture > LastNumber, 'A scene is there twice or out of its order');
      LastNumber := Scene.Picture;
      Assert.AreEqual(Began[Scene.Picture], Length(Scene.Crumbs),
        'A scene has the crumbs of another');
    end;
  end;

  ExpectLight(4 * MedkitUptake.Pulse, FedOf(MedkitUptake.Tint),
    'The light of the two medkits');
  ExpectLight(2 * WeaponUptake.Pulse, FedOf(WeaponUptake.Tint),
    'The light of the weapon');
end;

procedure TUptakeTests.TestRunsWithNoFeedAndNoProbe;
begin
  FUptake := TUptake.Create(nil, nil, DefaultSeed);
  StartScene(MedkitUptake, CasePicture);
  var Count := Length(FUptake.Scenes[0].Crumbs);

  var Spots := 0;
  var Ticks := 0;
  while Length(FUptake.Scenes) > 0 do
  begin
    if Ticks = ThreeSeconds then
      Assert.Fail(Format('The scene is still going %d ticks on', [Ticks]));
    Run(1);
    Inc(Ticks);
    Inc(Spots, Newborn(FUptake.Spots));
  end;
  Assert.AreEqual(Count, Spots, 'With no one to feed, every crumb still lights its spot');

  StartScene(PickupBurst, CasePicture);
  Assert.IsTrue(RunOut(ThreeSeconds) > 0, 'With no matter to ask, a wreck falls and ends');
end;

// ---------------------------------------------------------------------------
// The dice
// ---------------------------------------------------------------------------

procedure TUptakeTests.TestSameSeedGivesTheSameRun;
begin
  UseUptake(DefaultSeed);
  FTwin := TUptake.Create(nil, nil, DefaultSeed);
  StartScene(MedkitUptake, CasePicture);
  StartScene(PickupBurst, CasePicture);
  FTwin.Start(MedkitUptake, 1, CasePicture, PictureLeft, PictureTop, False,
    MiddleOf(NearPose));
  FTwin.Start(PickupBurst, 1, CasePicture, PictureLeft, PictureTop, False,
    MiddleOf(NearPose));

  var Diverged := 0;
  var Flying := 0;
  for var i := 1 to 30 do
  begin
    FUptake.Tick(NearPose, BodyPoints);
    FTwin.Tick(NearPose, BodyPoints);
    if not SameRun(FUptake, FTwin) then
      Inc(Diverged);
    Inc(Flying, InFlight(FUptake));
  end;

  Assert.AreEqual(0, Diverged, 'Two uptakes of one seed part ways');
  Assert.IsTrue(Flying > 0, 'There were crumbs in flight to compare');
  Assert.IsTrue(Length(FFeeds) > 0, 'and crumbs that came home');
end;

procedure TUptakeTests.TestOtherSeedGivesAnotherRun;
begin
  UseUptake(DefaultSeed);
  FTwin := TUptake.Create(nil, nil, OtherSeed);
  StartScene(MedkitUptake, CasePicture);
  FTwin.Start(MedkitUptake, 1, CasePicture, PictureLeft, PictureTop, False,
    MiddleOf(NearPose));

  var Diverged := 0;
  for var i := 1 to 20 do
  begin
    FUptake.Tick(NearPose, BodyPoints);
    FTwin.Tick(NearPose, BodyPoints);
    if not SameRun(FUptake, FTwin) then
      Inc(Diverged);
  end;

  Assert.IsTrue(Diverged > 0, 'The seed makes no difference to the run');
end;

// ---------------------------------------------------------------------------
// With the shroud, wired as the game wires it
// ---------------------------------------------------------------------------

procedure TUptakeTests.TestTakenMedkitLightsTheBodyAndTheLightDies;
begin
  FShroud := THeroShroud.Create(nil, DefaultSeed);
  FUptake := TUptake.Create(nil, FShroud.Feed, DefaultSeed);
  StartScene(MedkitUptake, CasePicture);

  // The game's order: what comes in feeds the light, then the light fades
  var Peak: Single := 0;
  var Ticks := 0;
  while Length(FUptake.Scenes) > 0 do
  begin
    if Ticks = ThreeSeconds then
      Assert.Fail(Format('The scene is still going %d ticks on', [Ticks]));
    FUptake.Tick(NearPose, BodyPoints);
    FShroud.Tick(NearPose, BodyPoints);
    Inc(Ticks);
    if FShroud.Fed > Peak then
      Peak := FShroud.Fed;
    Assert.IsFalse(FShroud.Active, 'Taking a medkit starts no shroud');
  end;

  Assert.IsTrue(Peak > 0, 'The medkit lights the body');
  Assert.IsTrue(Peak < 2 * MedkitUptake.Pulse, 'by less than all it gave: it fades as it comes');
  Assert.IsTrue(SameTint(MedkitUptake.Tint, FShroud.FedTint), 'in its own color');
  Assert.IsTrue(FShroud.Fed > 0, 'The light outlives the last crumb');

  for var i := 1 to 3 * MedkitUptake.PulseTicks do
  begin
    FUptake.Tick(NearPose, BodyPoints);
    FShroud.Tick(NearPose, BodyPoints);
  end;
  Assert.IsTrue(FShroud.Fed = 0,
    Format('and is out soon after: it is at %g still', [FShroud.Fed]));
end;

initialization
  TDUnitX.RegisterTestFixture(TUptakeTests);

end.
