{
  Tests.Levels.Dynamics - the craft, the one dynamic object that never
  moves by itself: where it stands until a scene moves it, how each of its
  axes heads where it is sent, and what its file says it may do. And the
  two looks of a beam, as far as the file reads them.

  A craft is made from JSON, as the level reads it, and ticked by the test
  with its origin at the corner of the screen: it hangs on nothing. Its
  corner (CornerAt) is all a test sees of it; the parts that turn and
  slide are drawn, never read.

  The dust: the light of its field and the roll and sway of its bands are
  records a test builds by hand and asks; the field itself is read from
  JSON, and all that is seen of it is that it reads, and on which layer.
  Its drawing is never tried.

  The eclipse: what its file says, as far as it is read. Its dark and its
  wave are drawn, never read.

  The convoy and the searchlight: the gap of the traffic, the line of a
  lane and the figure of eight of a sweep are records a test builds by
  hand and asks; the objects are read from JSON - a searchlight with the
  crafts it catches from a list, as a level reads them. Their columns and
  their spot are drawn, never read.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Levels.Dynamics;

interface

uses
  DUnitX.TestFramework,
  Levels.Dynamics;

type
  [TestFixture]
  TCraftTests = class
  private
    FCraft: TCraft;
    procedure UseCraft;
    procedure TickCraft(ATimes: Integer);
  public
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestCraftStandsWhereTheFileSaysUntilMoved;
    [Test]
    procedure TestCraftMovesEachAxisOnItsOwn;
    [Test]
    procedure TestCraftMovedInNoTicksIsThereAtOnce;
    [Test]
    procedure TestCraftGetsThereByItsTicksAndStays;
    [Test]
    procedure TestEaseShapesTheWayNotTheEnd;
    [Test]
    procedure TestBackEaseRunsPastItsMarkAndSettles;
    [Test]
    procedure TestFallEaseIsFreeFall;
    [Test]
    procedure TestCornerBetweenTicksLiesBetweenThem;
    [Test]
    procedure TestRewindPutsTheCraftBackAtOnce;
    [Test]
    procedure TestCraftKnowsWhichPartsFollow;
    [Test]
    procedure TestBadCraftRaises;
    [Test]
    procedure TestBeamReadsItsLook;
  end;

  [TestFixture]
  TDustTests = class
  public
    [Test]
    procedure TestShaftIsBrightestOnItsAxis;
    [Test]
    procedure TestShaftWidensAsItFalls;
    [Test]
    procedure TestNothingIsLitAboveTheHole;
    [Test]
    procedure TestGlowFadesFromItsMiddleAsAnOval;
    [Test]
    procedure TestAmbientLightsEverywhereAlike;
    [Test]
    procedure TestSeamRollsWithTheSpeed;
    [Test]
    procedure TestSeamStaysInTheArtAfterHours;
    [Test]
    procedure TestSwayStaysWithinItsReach;
    [Test]
    procedure TestDustReadsFromItsFile;
    [Test]
    procedure TestBadDustRaises;
  end;

  [TestFixture]
  TEclipseTests = class
  public
    [Test]
    procedure TestEclipseReadsFromItsFile;
    [Test]
    procedure TestWaveIsTheOtherLook;
    [Test]
    procedure TestBadEclipseRaises;
  end;

  [TestFixture]
  TConvoyTests = class
  public
    [Test]
    procedure TestGapNarrowsOverTheRampAndStays;
    [Test]
    procedure TestLaneRunsFromItsStartToItsFinish;
    [Test]
    procedure TestLightsKeepLessOfThemselvesDownTheLane;
    [Test]
    procedure TestConvoyReadsFromItsFile;
    [Test]
    procedure TestBadConvoyRaises;
  end;

  [TestFixture]
  TSearchlightTests = class
  public
    [Test]
    procedure TestSweepStartsAtItsPhaseAndComesBackInAPeriod;
    [Test]
    procedure TestSweepStaysWithinItsReach;
    [Test]
    procedure TestSweepGoesAcrossOnceAndUpAndDownTwice;
    [Test]
    procedure TestSearchlightReadsFromItsFile;
    [Test]
    procedure TestBadSearchlightRaises;
    [Test]
    procedure TestCatchesAreFoundAmongTheObjects;
    [Test]
    procedure TestCatchesThatStandApartRaise;
  end;

implementation

uses
  System.JSON,
  System.Math,
  System.SysUtils;

const
  LevelId = 'test';
  // Where the file puts the craft's corner
  FileX = 10;
  FileY = -50;
  SingleSlack = 0.001;
  Eases: array [0..3] of TMotionEase = (meLinear, meIn, meOut, meInOut);
  // A beam's look as a file gives it: none, then the two words
  BeamLooks: array [0..2] of string = ('', ',"look":"scan"',
    ',"look":"tractor"');
  CraftJson = '{"kind":"craft","tag":"ship","screen":1,"body":"hull",' +
    '"width":100,"x":10,"y":-50,"parts":[' +
    '{"sprite":"gun","tag":"gun","at":[10,20],"width":8,"anchor":"pivot",' +
    '"pivot":[4,0],"turns":30},' +
    '{"sprite":"iris","tag":"iris","at":[50,20],"width":4,' +
    '"anchor":"center","reach":3},' +
    '{"sprite":"plate","tag":"plate","at":[0,0],"width":20}]}';
  // A field of one band; the format adds members after the bands
  DustJson = '{"kind":"dust","screen":1,"x":0,"y":0,' +
    '"bands":[{"sprite":"band","y":10}]%s}';
  // The black glow of the moon stone; the format adds members
  EclipseJson = '{"kind":"eclipse","screen":1,"x":416,"y":173%s}';
  // A back ease runs past its mark by a few percent of the way, no more
  BackPeakMost = 1.05;
  AmbientPoints: array [0..3] of Integer = (-300, 0, 77, 512);
  HourSpeeds: array [0..1] of Integer = (7, -7);
  // A convoy of one lane; the format adds members after the lanes
  ConvoyJson = '{"kind":"convoy","screen":12,"x":0,"y":0,' +
    '"lanes":[{"from":[-16,216],"to":[458,216]}]%s}';
  // A searchlight; the format adds members
  SearchlightJson = '{"kind":"searchlight","screen":12,"x":0,"y":0,' +
    '"source":[462,216],"sweep":{"center":[190,200],"reach":[150,75]}%s}';
  // A pillar it may catch; the format puts its screen and its layer
  PillarJson = '{"kind":"craft","tag":"pillar","screen":%d,"layer":"%s",' +
    '"body":"needle","width":6,"x":47,"y":175}';
  CatchingJson = '{"kind":"searchlight","screen":12,"layer":"sky","x":0,' +
    '"y":0,"source":[462,216],"sweep":{"center":[190,200],' +
    '"reach":[150,75]},"catches":["pillar"]}';
  // Samples of a sweep over one period
  SweepSamples = 1000;

function IsNear(AValue: Single; AExpected: Double): Boolean;
begin
  Result := Abs(AValue - AExpected) < SingleSlack;
end;

function DynamicOf(const AJson: string): TDynamicObject;
begin
  var Obj := TJSONObject.ParseJSONValue(AJson) as TJSONObject;
  try
    Result := ParseDynamic(Obj, LevelId, '#1');
  finally
    Obj.Free;
  end;
end;

// By value, not const: an anonymous method captures it
procedure ExpectRaises(AJson, AWhat: string);
begin
  Assert.WillRaise(
    procedure
    begin
      DynamicOf(AJson).Free;
    end, EDynamicError, AWhat);
end;

// A "dynamics" section of the objects AItems lists, read as a level reads it
function DynamicsOf(const AItems: string): TDynamicObjects;
begin
  var Root := TJSONObject.ParseJSONValue('{"dynamics":[' + AItems + ']}') as
    TJSONObject;
  try
    Result := ParseDynamics(Root, LevelId);
  finally
    Root.Free;
  end;
end;

// By value, not const: an anonymous method captures it
procedure ExpectListRaises(AItems, AWhat: string);
begin
  Assert.WillRaise(
    procedure
    begin
      DynamicsOf(AItems).Free;
    end, EDynamicError, AWhat);
end;

procedure TCraftTests.TearDown;
begin
  FreeAndNil(FCraft);
end;

procedure TCraftTests.UseCraft;
begin
  FreeAndNil(FCraft);
  FCraft := DynamicOf(CraftJson) as TCraft;
end;

procedure TCraftTests.TickCraft(ATimes: Integer);
begin
  for var i := 1 to ATimes do
    FCraft.Tick(0, 0, True);
end;

procedure TCraftTests.TestCraftStandsWhereTheFileSaysUntilMoved;
begin
  UseCraft;

  for var i := 1 to 50 do
  begin
    TickCraft(1);
    var Corner := FCraft.CornerAt(1);
    Assert.IsTrue(IsNear(Corner.X, FileX) and IsNear(Corner.Y, FileY),
      Format('Tick %d: the craft at %g, %g', [i, Corner.X, Corner.Y]));
  end;
end;

procedure TCraftTests.TestCraftMovesEachAxisOnItsOwn;
begin
  UseCraft;

  FCraft.MoveX(200, 20, meLinear);
  FCraft.MoveY(100, 40, meLinear);
  TickCraft(20);
  var Corner := FCraft.CornerAt(1);
  Assert.IsTrue(IsNear(Corner.X, 200), 'Across: there after its 20 ticks');
  Assert.IsTrue((Corner.Y > FileY) and (Corner.Y < 100),
    Format('Down: on the way after 20 of its 40 ticks, at %g', [Corner.Y]));

  TickCraft(20);
  Corner := FCraft.CornerAt(1);
  Assert.IsTrue(IsNear(Corner.X, 200), 'Across: stays');
  Assert.IsTrue(IsNear(Corner.Y, 100), 'Down: there after its 40 ticks');

  UseCraft;
  FCraft.MoveX(200, 20, meLinear);
  TickCraft(30);
  Assert.IsTrue(IsNear(FCraft.CornerAt(1).Y, FileY),
    'A move across leaves the craft''s height alone');
end;

procedure TCraftTests.TestCraftMovedInNoTicksIsThereAtOnce;
begin
  UseCraft;
  TickCraft(1);

  FCraft.MoveX(300, 0, meOut);
  TickCraft(1);

  Assert.IsTrue(IsNear(FCraft.CornerAt(0).X, 300) and
    IsNear(FCraft.CornerAt(1).X, 300),
    'A move of no ticks jumps: nothing is drawn on the way');
end;

procedure TCraftTests.TestCraftGetsThereByItsTicksAndStays;
const
  Ticks = 30;
  Target = 200;
begin
  for var Ease in Eases do
  begin
    UseCraft;
    FCraft.MoveX(Target, Ticks, Ease);
    var Before: Single := FileX;
    for var i := 1 to 2 * Ticks do
    begin
      TickCraft(1);
      var X := FCraft.CornerAt(1).X;
      Assert.IsTrue((X >= Before - SingleSlack) and (X <= Target + SingleSlack),
        Format('Ease %s, tick %d: %g after %g', [MotionEaseIds[Ease], i, X,
        Before]));
      if i >= Ticks then
        Assert.IsTrue(IsNear(X, Target), Format('Ease %s, tick %d: at %g, ' +
          'not there', [MotionEaseIds[Ease], i, X]));
      Before := X;
    end;
  end;
end;

procedure TCraftTests.TestEaseShapesTheWayNotTheEnd;
const
  Ticks = 40;
var
  HalfWay: array [TMotionEase] of Single;
begin
  for var Ease in Eases do
  begin
    UseCraft;
    FCraft.MoveX(FileX + 100, Ticks, Ease);
    TickCraft(Ticks div 2);
    HalfWay[Ease] := FCraft.CornerAt(1).X;
  end;

  Assert.IsTrue(HalfWay[meOut] > HalfWay[meLinear],
    'Losing speed, the craft has come further by half its time');
  Assert.IsTrue(HalfWay[meIn] < HalfWay[meLinear],
    'Gathering speed, it has come less far');
  Assert.IsTrue(HalfWay[meInOut] < HalfWay[meOut],
    'Both ways, it lags the one that sets off at speed');
end;

procedure TCraftTests.TestBackEaseRunsPastItsMarkAndSettles;
const
  Ticks = 40;
  Way = 100;
begin
  UseCraft;
  FCraft.MoveX(FileX + Way, Ticks, meBack);
  var Furthest: Single := FileX;
  for var Tick := 1 to Ticks do
  begin
    TickCraft(1);
    Furthest := Max(Furthest, FCraft.CornerAt(1).X);
  end;

  Assert.IsTrue(Furthest > FileX + Way,
    Format('It runs past its mark: at most %g', [Furthest]));
  Assert.IsTrue(Furthest < FileX + Way * BackPeakMost,
    Format('A little past it, not a bounce: %g', [Furthest]));
  Assert.IsTrue(IsNear(FCraft.CornerAt(1).X, FileX + Way),
    'It settles onto its mark when its ticks are out');
  TickCraft(10);
  Assert.IsTrue(IsNear(FCraft.CornerAt(1).X, FileX + Way), 'and stays');
end;

// A thing let go is pulled at a steady rate from its first tick: the way
// grows as the square of the time, and the thing sets off at once, where
// the cube of "in" lingers
procedure TCraftTests.TestFallEaseIsFreeFall;
begin
  Assert.IsTrue(IsNear(EasedShare(meFall, 0.5), 0.25),
    'Half the time, a quarter of the way');
  Assert.IsTrue(IsNear(EasedShare(meFall, 1), 1), 'Out of time, there');
  Assert.IsTrue(IsNear(EasedShare(meFall, 0), 0), 'At the start, not off it');
  Assert.IsTrue(EasedShare(meFall, 0.25) > EasedShare(meIn, 0.25),
    'Sooner under way than the cube');
  Assert.AreEqual('fall', MotionEaseIds[meFall], 'The word of the file');
end;

procedure TCraftTests.TestCornerBetweenTicksLiesBetweenThem;
begin
  UseCraft;
  FCraft.MoveX(FileX + 100, 20, meLinear);

  for var i := 1 to 20 do
  begin
    TickCraft(1);
    var Last := FCraft.CornerAt(0).X;
    var Current := FCraft.CornerAt(1).X;
    var Between := FCraft.CornerAt(0.5).X;
    Assert.IsTrue((Between > Last) and (Between < Current),
      Format('Tick %d: %g is not between %g and %g', [i, Between, Last,
      Current]));
  end;
end;

procedure TCraftTests.TestRewindPutsTheCraftBackAtOnce;
begin
  UseCraft;
  FCraft.MoveX(300, 40, meLinear);
  FCraft.MoveY(100, 40, meLinear);
  TickCraft(20);

  FCraft.Rewind;
  var Corner := FCraft.CornerAt(1);
  Assert.IsTrue(IsNear(Corner.X, FileX) and IsNear(Corner.Y, FileY),
    'Back where the file puts it');
  TickCraft(30);
  Corner := FCraft.CornerAt(1);
  Assert.IsTrue(IsNear(Corner.X, FileX) and IsNear(Corner.Y, FileY),
    'And it stays: the move it was in is gone');
end;

procedure TCraftTests.TestCraftKnowsWhichPartsFollow;
begin
  UseCraft;

  Assert.IsTrue(FCraft.HasFollower('gun'), 'A part that turns');
  Assert.IsTrue(FCraft.HasFollower('iris'), 'A part that slides');
  Assert.IsFalse(FCraft.HasFollower('plate'), 'A part that does neither');
  Assert.IsFalse(FCraft.HasFollower('ghost'), 'A tag no part carries');
end;

procedure TCraftTests.TestBadCraftRaises;
const
  Head = '{"kind":"craft","tag":"ship","screen":1,"body":"hull",' +
    '"width":100,"x":0,"y":0,"parts":[%s]}';
begin
  ExpectRaises(Format(Head, ['{"sprite":"gun","at":[1,1],"width":8,' +
    '"anchor":"pivot","pivot":[4,0],"turns":30,"reach":3}']),
    'A part that turns and slides');
  ExpectRaises(Format(Head, ['{"sprite":"gun","at":[1,1],"width":8,' +
    '"turns":30}']), 'A part that turns and hangs by no pivot');
  ExpectRaises(Format(Head, ['{"sprite":"gun","width":8}']),
    'A part with no point to hang on');
  ExpectRaises('{"kind":"craft","tag":"ship","screen":1,"width":100,' +
    '"x":0,"y":0}', 'A craft with no body');
  ExpectRaises('{"kind":"craft","tag":"ship","screen":1,"body":"hull",' +
    '"x":0,"y":0}', 'A craft of no width');
end;

procedure TCraftTests.TestBeamReadsItsLook;
const
  Beam = '{"kind":"beam","tag":"lift","screen":1,"x":0,"y":0%s}';
begin
  for var Look in BeamLooks do
  begin
    var Parsed := DynamicOf(Format(Beam, [Look]));
    try
      Assert.IsTrue(Parsed is TBeam, 'A beam of look "' + Look + '"');
    finally
      Parsed.Free;
    end;
  end;
  ExpectRaises(Format(Beam, [',"look":"spiral"']), 'A look not there');
end;

// A shaft straight down from (100, 0), 4 units wide at its hole and 40 at
// (100, 400); nothing else lit
function DownShaft: TDustLight;
begin
  Result := Default(TDustLight);
  Result.ShaftFrom.X := 100;
  Result.ShaftFrom.Y := 0;
  Result.ShaftTo.X := 100;
  Result.ShaftTo.Y := 400;
  Result.ShaftFromWidth := 4;
  Result.ShaftToWidth := 40;
  Result.ShaftLevel := 1;
end;

// A glow alone: its middle at the corner, its oval twice as wide as tall
function FloorGlow: TDustLight;
begin
  Result := Default(TDustLight);
  Result.GlowReach.X := 100;
  Result.GlowReach.Y := 50;
  Result.GlowLevel := 1;
end;

// 100 units to a turn of the art, rolling 10 units a second; a sway of 5
// each way over 20 seconds
function RollingBand(ASpeed: Single): TDustBand;
begin
  Result := Default(TDustBand);
  Result.Sprite := 'band';
  Result.Y := 200;
  Result.Height := 40;
  Result.Length := 100;
  Result.Speed := ASpeed;
  Result.Sway := 5;
  Result.SwayTime := 20;
  Result.SwayPhase := 0.3;
  Result.Density := 1;
end;

procedure TDustTests.TestShaftIsBrightestOnItsAxis;
begin
  var Light := DownShaft;

  var OnAxis := Light.LevelAt(100, 200);
  var Near := Light.LevelAt(110, 200);
  var Far := Light.LevelAt(160, 200);
  Assert.IsTrue((OnAxis > Near) and (Near > Far),
    Format('On the axis %g, 10 off %g, 60 off %g', [OnAxis, Near, Far]));
  Assert.IsTrue(IsNear(Light.LevelAt(90, 200), Near),
    'The same either side of the axis');
end;

procedure TDustTests.TestShaftWidensAsItFalls;
begin
  var Light := DownShaft;

  var NearTheHole := Light.LevelAt(110, 40);
  var Below := Light.LevelAt(110, 380);
  Assert.IsTrue(Below > NearTheHole,
    Format('10 units off the axis: %g near the hole, %g far below',
    [NearTheHole, Below]));
end;

procedure TDustTests.TestNothingIsLitAboveTheHole;
begin
  var Light := DownShaft;

  Assert.IsTrue(Light.LevelAt(100, 10) > 0.5, 'Just under the hole: lit');
  Assert.IsTrue(IsNear(Light.LevelAt(100, -10), 0),
    'Just over it, on the line of the axis: dark');
end;

procedure TDustTests.TestGlowFadesFromItsMiddleAsAnOval;
begin
  var Light := FloorGlow;

  var Middle := Light.LevelAt(0, 0);
  var Aside := Light.LevelAt(60, 0);
  var Above := Light.LevelAt(0, -60);
  Assert.IsTrue((Middle > Aside) and (Aside > Above),
    Format('In the middle %g, 60 aside %g, 60 above %g', [Middle, Aside,
    Above]));
  Assert.IsTrue(Light.LevelAt(600, 0) < 0.01, 'Far away the glow is gone');
end;

procedure TDustTests.TestAmbientLightsEverywhereAlike;
begin
  var Light := Default(TDustLight);
  Light.Ambient := 0.25;

  for var Point in AmbientPoints do
    Assert.IsTrue(IsNear(Light.LevelAt(Point, 200 - Point), 0.25),
      Format('At %d, %d', [Point, 200 - Point]));
end;

procedure TDustTests.TestSeamRollsWithTheSpeed;
begin
  var Right := RollingBand(10);
  var Left := RollingBand(-10);

  Assert.IsTrue(IsNear(Right.SeamAt(0), 0), 'At the start the seam is at the edge');
  Assert.IsTrue(IsNear(Right.SeamAt(2.5), 25),
    Format('Rolling right: %g after 2.5 seconds', [Right.SeamAt(2.5)]));
  Assert.IsTrue(IsNear(Left.SeamAt(2.5), 75),
    Format('Rolling left: %g after 2.5 seconds', [Left.SeamAt(2.5)]));
  Assert.IsTrue(IsNear(Right.SeamAt(12.5), Right.SeamAt(2.5)),
    'A turn of the art later the seam is where it was');
end;

procedure TDustTests.TestSeamStaysInTheArtAfterHours;
const
  Hour = 3600.0;
begin
  for var Speed in HourSpeeds do
  begin
    var Band := RollingBand(Speed);
    for var Hours := 1 to 6 do
    begin
      var Seconds: Double := Hours * Hour + 0.37;
      var Seam := Band.SeamAt(Seconds);
      Assert.IsTrue((Seam >= 0) and (Seam < Band.Length),
        Format('Speed %d, %d hours on: the seam at %g', [Speed, Hours, Seam]));
      var Later := Band.SeamAt(Seconds + 1);
      var Moved: Single := Later - Seam;
      if Moved * Speed < 0 then
        Moved := Moved + Sign(Speed) * Band.Length;
      Assert.IsTrue(IsNear(Moved, Speed),
        Format('Speed %d, %d hours on: %g in a second', [Speed, Hours, Moved]));
    end;
  end;
end;

procedure TDustTests.TestSwayStaysWithinItsReach;
begin
  var Band := RollingBand(10);

  var Lowest := Band.Y;
  var Highest := Band.Y;
  for var Step := 0 to 200 do
  begin
    var Middle := Band.MiddleAt(Step * Band.SwayTime / 200);
    Assert.IsTrue(Abs(Middle - Band.Y) <= Band.Sway + SingleSlack,
      Format('Step %d: the middle at %g', [Step, Middle]));
    Lowest := Min(Lowest, Middle);
    Highest := Max(Highest, Middle);
  end;
  Assert.IsTrue((Highest - Lowest) > 1.9 * Band.Sway,
    'Over a cycle it goes nearly all the way up and down');
  Assert.IsTrue(IsNear(Band.MiddleAt(3), Band.MiddleAt(3 + Band.SwayTime)),
    'A cycle later the band is where it was');
end;

procedure TDustTests.TestDustReadsFromItsFile;
begin
  var Parsed := DynamicOf(Format(DustJson, ['']));
  try
    Assert.IsTrue(Parsed is TDust, 'A dust field');
    Assert.AreEqual<TDynamicLayer>(dlSky, Parsed.Placement.Layer,
      'In the depth by default');
  finally
    Parsed.Free;
  end;

  Parsed := DynamicOf(Format(DustJson, [',"layer":"aloft"']));
  try
    Assert.AreEqual<TDynamicLayer>(dlAloft, Parsed.Placement.Layer,
      'On the layer its file names');
  finally
    Parsed.Free;
  end;
end;

procedure TDustTests.TestBadDustRaises;
const
  Head = '{"kind":"dust","screen":1,"x":0,"y":0,%s}';
  OneBand = '"bands":[{"sprite":"band","y":10}]';
begin
  ExpectRaises(Format(Head, ['"width":512']), 'No bands');
  ExpectRaises(Format(Head, ['"bands":[]']), 'An empty list of bands');
  ExpectRaises(Format(Head, ['"bands":[{"y":10}]']), 'A band of no sprite');
  ExpectRaises(Format(Head, ['"bands":[{"sprite":"band","y":10,' +
    '"density":120}]']), 'A density past 100');
  ExpectRaises(Format(Head, [OneBand + ',"light":{"shaft":{"from":[5,5],' +
    '"to":[5,5]}}']), 'A shaft from a point to the same point');
  ExpectRaises(Format(Head, [OneBand + ',"light":{"shaft":{"from":[5,5],' +
    '"to":[5,50],"width":[0,10]}}']), 'A shaft of no width at its hole');
  ExpectRaises(Format(Head, [OneBand + ',"light":{"glow":{"at":[5,5],' +
    '"reach":[10,0]}}']), 'A glow of no height');
end;

procedure TEclipseTests.TestEclipseReadsFromItsFile;
begin
  var Parsed := DynamicOf(Format(EclipseJson,
    [',"reach":70,"depth":75,"rim":34']));
  try
    Assert.IsTrue(Parsed is TEclipse, 'An eclipse');
    var Eclipse := TEclipse(Parsed);
    Assert.AreEqual<TEclipseLook>(elVoid, Eclipse.Look, 'The void by default');
    Assert.IsTrue(IsNear(Eclipse.Reach, 70), 'reach');
    Assert.IsTrue(IsNear(Eclipse.Depth, 0.75), 'depth, a percentage');
    Assert.IsTrue(IsNear(Eclipse.Rim, 34), 'rim');
    Assert.AreEqual<TDynamicLayer>(dlBack, Parsed.Placement.Layer,
      'Over the objects and the pads, under the monsters');
  finally
    Parsed.Free;
  end;

  Parsed := DynamicOf(Format(EclipseJson, [',"reach":70']));
  try
    Assert.IsTrue(IsNear(TEclipse(Parsed).Rim, 0), 'No rim unless asked');
    Assert.IsTrue(IsNear(TEclipse(Parsed).Depth, 0.8), 'Depth by default');
  finally
    Parsed.Free;
  end;
end;

procedure TEclipseTests.TestWaveIsTheOtherLook;
begin
  var Parsed := DynamicOf(Format(EclipseJson,
    [',"look":"wave","reach":340,"depth":60']));
  try
    Assert.AreEqual<TEclipseLook>(elWave, TEclipse(Parsed).Look);
    Assert.IsTrue(IsNear(TEclipse(Parsed).Reach, 340), 'reach');
  finally
    Parsed.Free;
  end;
end;

procedure TEclipseTests.TestBadEclipseRaises;
begin
  ExpectRaises(Format(EclipseJson, ['']), 'No reach');
  ExpectRaises(Format(EclipseJson, [',"reach":0']), 'A reach of nothing');
  ExpectRaises(Format(EclipseJson, [',"reach":70,"depth":120']),
    'A depth past 100');
  ExpectRaises(Format(EclipseJson, [',"reach":70,"rim":-1']),
    'A rim under nothing');
  ExpectRaises(Format(EclipseJson, [',"reach":70,"look":"hole"']),
    'An unknown look');
end;

// The traffic of screen 12: half the ledge at the start, dense in 45
// seconds
function ScreenTwelveTraffic: TConvoyTraffic;
begin
  Result := Default(TConvoyTraffic);
  Result.GapFirst := 237;
  Result.GapLast := 44;
  Result.Ramp := 45;
  Result.Jitter := 0.25;
end;

// 100 units to the right along y 10; at its finish a light keeps 70% of
// what it has, and it has 80% all along
function ShortLane: TConvoyLane;
begin
  Result := Default(TConvoyLane);
  Result.Start.X := 0;
  Result.Start.Y := 10;
  Result.Finish.X := 100;
  Result.Finish.Y := 10;
  Result.Speed := 8;
  Result.FarShare := 0.7;
  Result.Scale := 0.8;
  Result.Joins := 1;
end;

// The sweep of screen 12, starting at the right end of the eight
function ScreenTwelveSweep: TSweep;
begin
  Result := Default(TSweep);
  Result.Center.X := 190;
  Result.Center.Y := 200;
  Result.Reach.X := 150;
  Result.Reach.Y := 75;
  Result.Period := 11;
  Result.Phase := 0.25;
end;

// How many times ASide changes sign over the samples of a period
function SignChanges(const ASide: TArray<Single>): Integer;
begin
  Result := 0;
  for var i := 1 to High(ASide) do
    if (ASide[i - 1] < 0) <> (ASide[i] < 0) then
      Inc(Result);
end;

procedure TConvoyTests.TestGapNarrowsOverTheRampAndStays;
begin
  var Traffic := ScreenTwelveTraffic;

  Assert.IsTrue(IsNear(Traffic.GapAt(0), 237), 'Half the ledge at the start');
  Assert.IsTrue(IsNear(Traffic.GapAt(22.5), 140.5),
    Format('Half way through the ramp: %g', [Traffic.GapAt(22.5)]));
  Assert.IsTrue(IsNear(Traffic.GapAt(45), 44), 'Dense at the end of the ramp');
  Assert.IsTrue(IsNear(Traffic.GapAt(600), 44), 'And dense from then on');
  Assert.IsTrue(Traffic.GapAt(10) > Traffic.GapAt(20),
    'Narrower the later it is');
end;

procedure TConvoyTests.TestLaneRunsFromItsStartToItsFinish;
begin
  var Lane := ShortLane;

  Assert.IsTrue(IsNear(Lane.Span, 100), 'From its start to its finish');
  var Middle := Lane.PointAt(50);
  Assert.IsTrue(IsNear(Middle.X, 50) and IsNear(Middle.Y, 10),
    Format('Half way down: %g, %g', [Middle.X, Middle.Y]));
  var Finish := Lane.PointAt(100);
  Assert.IsTrue(IsNear(Finish.X, 100) and IsNear(Finish.Y, 10),
    'All the way down: on the finish');
end;

procedure TConvoyTests.TestLightsKeepLessOfThemselvesDownTheLane;
begin
  var Lane := ShortLane;

  Assert.IsTrue(IsNear(Lane.DepthAt(0), 0.8), 'At the start: the lane''s own');
  Assert.IsTrue(IsNear(Lane.DepthAt(100), 0.56),
    Format('At the finish: 70%% of it, %g', [Lane.DepthAt(100)]));
  Assert.IsTrue((Lane.DepthAt(50) < 0.8) and (Lane.DepthAt(50) > 0.56),
    'Between them on the way');
  Assert.IsTrue(IsNear(Lane.DepthAt(-20), 0.8) and
    IsNear(Lane.DepthAt(130), 0.56), 'Off the lane: as at its ends');
end;

procedure TConvoyTests.TestConvoyReadsFromItsFile;
begin
  var Parsed := DynamicOf(Format(ConvoyJson, ['']));
  try
    Assert.IsTrue(Parsed is TConvoy, 'A convoy');
    Assert.AreEqual<TDynamicLayer>(dlSky, Parsed.Placement.Layer,
      'In the depth by default');
  finally
    Parsed.Free;
  end;

  Parsed := DynamicOf(Format(ConvoyJson, [',"gap":[237,44],"ramp":45,' +
    '"jitter":25,"lights":[3,5],"tail":[100,16,10],"flasher":[100,52,8]']));
  Parsed.Free;
end;

procedure TConvoyTests.TestBadConvoyRaises;
const
  Head = '{"kind":"convoy","screen":12,"x":0,"y":0%s}';
  Lane = '{"from":[0,10],"to":[100,10]}';
begin
  ExpectRaises(Format(Head, ['']), 'No lanes');
  ExpectRaises(Format(Head, [',"lanes":[]']), 'An empty list of lanes');
  ExpectRaises(Format(Head, [',"lanes":[{"from":[5,5],"to":[5,5]}]']),
    'A lane from a point to the same point');
  ExpectRaises(Format(Head, [',"lanes":[{"from":[0,10],"to":[100,10],' +
    '"joins":2}]']), 'A first lane that joins another');
  ExpectRaises(Format(Head, [',"lanes":[' + Lane + ',{"from":[0,8],' +
    '"to":[100,8],"joins":0}]']), 'A lane that joins column 0');
  ExpectRaises(Format(Head, [',"lanes":[{"from":[0,10],"to":[100,10],' +
    '"speed":0}]']), 'A lane that does not move');
  ExpectRaises(Format(ConvoyJson, [',"gap":[0,44]']), 'A gap of nothing');
  ExpectRaises(Format(ConvoyJson, [',"jitter":100']),
    'A jitter of a whole gap');
  ExpectRaises(Format(ConvoyJson, [',"lights":[1,3]']),
    'A column of one light');
  ExpectRaises(Format(ConvoyJson, [',"lights":[5,3]']),
    'The most before the fewest');
  ExpectRaises(Format(ConvoyJson, [',"ramp":0']), 'A ramp of no time');
end;

procedure TSearchlightTests.TestSweepStartsAtItsPhaseAndComesBackInAPeriod;
begin
  var Sweep := ScreenTwelveSweep;

  var First := Sweep.SpotAt(0);
  Assert.IsTrue(IsNear(First.X, 340) and IsNear(First.Y, 200),
    Format('A quarter in: at the right end, %g, %g', [First.X, First.Y]));
  var Again := Sweep.SpotAt(11);
  Assert.IsTrue(IsNear(Again.X, First.X) and IsNear(Again.Y, First.Y),
    'A period later the spot is where it was');
  var Later := Sweep.SpotAt(3 * 3600 + 11);
  var Before := Sweep.SpotAt(3 * 3600);
  Assert.IsTrue(IsNear(Later.X, Before.X) and IsNear(Later.Y, Before.Y),
    'Hours on, still a period to a turn');
end;

procedure TSearchlightTests.TestSweepStaysWithinItsReach;
begin
  var Sweep := ScreenTwelveSweep;

  var Left: Single := Sweep.Center.X;
  var Right: Single := Sweep.Center.X;
  var Top: Single := Sweep.Center.Y;
  var Bottom: Single := Sweep.Center.Y;
  for var i := 0 to SweepSamples do
  begin
    var Spot := Sweep.SpotAt(i * Sweep.Period / SweepSamples);
    Assert.IsTrue((Abs(Spot.X - Sweep.Center.X) <= Sweep.Reach.X +
      SingleSlack) and (Abs(Spot.Y - Sweep.Center.Y) <= Sweep.Reach.Y +
      SingleSlack), Format('Sample %d: the spot at %g, %g', [i, Spot.X,
      Spot.Y]));
    Left := Min(Left, Spot.X);
    Right := Max(Right, Spot.X);
    Top := Min(Top, Spot.Y);
    Bottom := Max(Bottom, Spot.Y);
  end;
  Assert.IsTrue((Right - Left > 1.99 * Sweep.Reach.X) and
    (Bottom - Top > 1.99 * Sweep.Reach.Y),
    'Over a period it goes all the way, across and up and down');
end;

procedure TSearchlightTests.TestSweepGoesAcrossOnceAndUpAndDownTwice;
var
  Across, Down: TArray<Single>;
begin
  var Sweep := ScreenTwelveSweep;
  // Neither side starts on the middle: the first sample is on a side
  Sweep.Phase := 0.1;

  SetLength(Across, SweepSamples);
  SetLength(Down, SweepSamples);
  for var i := 0 to SweepSamples - 1 do
  begin
    var Spot := Sweep.SpotAt(i * Sweep.Period / SweepSamples);
    Across[i] := Spot.X - Sweep.Center.X;
    Down[i] := Spot.Y - Sweep.Center.Y;
  end;
  // Over a period, the ends left out: a swing to each side and back
  Assert.AreEqual(1, SignChanges(Across) div 2,
    'Across: once to each side');
  Assert.AreEqual(2, SignChanges(Down) div 2,
    'Up and down: twice to each side - a figure of eight');
end;

procedure TSearchlightTests.TestSearchlightReadsFromItsFile;
begin
  var Parsed := DynamicOf(Format(SearchlightJson, ['']));
  try
    Assert.IsTrue(Parsed is TSearchlight, 'A searchlight');
    Assert.AreEqual<TDynamicLayer>(dlSky, Parsed.Placement.Layer,
      'In the depth by default');
  finally
    Parsed.Free;
  end;

  Parsed := DynamicOf(Format(SearchlightJson, [',"spot":[90,54],' +
    '"catch":60,"catches":[]']));
  Parsed.Free;
end;

procedure TSearchlightTests.TestBadSearchlightRaises;
const
  NoSweep = '{"kind":"searchlight","screen":12,"x":0,"y":0,' +
    '"source":[462,216]}';
  NoSource = '{"kind":"searchlight","screen":12,"x":0,"y":0,' +
    '"sweep":{"center":[190,200],"reach":[150,75]}}';
  OnTheSource = '{"kind":"searchlight","screen":12,"x":0,"y":0,' +
    '"source":[190,200],"sweep":{"center":[190,200],"reach":[150,75]}}';
  BackwardReach = '{"kind":"searchlight","screen":12,"x":0,"y":0,' +
    '"source":[462,216],"sweep":{"center":[190,200],"reach":[-1,75]}}';
  NoPeriod = '{"kind":"searchlight","screen":12,"x":0,"y":0,' +
    '"source":[462,216],"sweep":{"center":[190,200],"reach":[150,75],' +
    '"period":0}}';
begin
  ExpectRaises(NoSweep, 'No sweep');
  ExpectRaises(NoSource, 'No source');
  ExpectRaises(OnTheSource, 'The middle of the sweep on the source');
  ExpectRaises(BackwardReach, 'A reach under nothing');
  ExpectRaises(NoPeriod, 'A sweep of no time');
  ExpectRaises(Format(SearchlightJson, [',"spot":[0,54]']),
    'A spot of no length');
  ExpectRaises(Format(SearchlightJson, [',"catch":120']),
    'A catch past 100');
  ExpectRaises(Format(SearchlightJson, [',"catches":[1]']),
    'A catch that is no tag');
  ExpectRaises('{"kind":"searchlight","parent":"ship","x":0,"y":0,' +
    '"source":[462,216],"sweep":{"center":[190,200],"reach":[150,75]},' +
    '"catches":["pillar"]}', 'A searchlight that catches, hung on a parent');
end;

procedure TSearchlightTests.TestCatchesAreFoundAmongTheObjects;
begin
  var Objects := DynamicsOf(Format(PillarJson, [12, 'sky']) + ',' +
    CatchingJson);
  try
    Assert.AreEqual(2, Objects.Count, 'The pillar and the searchlight');
    Assert.IsTrue(Objects[1] is TSearchlight, 'The searchlight, after it');
  finally
    Objects.Free;
  end;
end;

procedure TSearchlightTests.TestCatchesThatStandApartRaise;
begin
  ExpectListRaises(CatchingJson, 'A catch no craft carries');
  ExpectListRaises(CatchingJson + ',' + Format(PillarJson, [12, 'sky']),
    'A craft after the searchlight: drawn over its own light');
  ExpectListRaises(Format(PillarJson, [11, 'sky']) + ',' + CatchingJson,
    'A craft on another screen');
  ExpectListRaises(Format(PillarJson, [12, 'aloft']) + ',' + CatchingJson,
    'A craft on another layer');
end;

initialization
  TDUnitX.RegisterTestFixture(TCraftTests);
  TDUnitX.RegisterTestFixture(TDustTests);
  TDUnitX.RegisterTestFixture(TEclipseTests);
  TDUnitX.RegisterTestFixture(TConvoyTests);
  TDUnitX.RegisterTestFixture(TSearchlightTests);

end.
