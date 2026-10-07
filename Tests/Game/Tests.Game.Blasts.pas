{
  Tests.Game.Blasts - the wave of an explosion: when it reaches a body,
  that it strikes it once, what shelters from it, and what it takes and
  how hard it shoves by the distance.

  The blast is the barrel's of monsters.json in numbers, 100 lives over
  80 units, with its heart at the origin; bodies are points on the X
  axis and plain objects to tell them apart. Walls are functions. One
  test reads the real barrel from monsters.json, which lies beside the
  executable, and holds its numbers to the scene they were set for.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Game.Blasts;

interface

uses
  DUnitX.TestFramework,
  Game.Blasts;

type
  [TestFixture]
  TBlastTests = class
  private
    FBlast: TBlast;
    FNearBody, FFarBody: TObject;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestWaveReachesANearBodyBeforeAFarOne;
    [Test]
    procedure TestBodyIsStruckOnce;
    [Test]
    procedure TestBodyBeyondTheRadiusIsNeverStruck;
    [Test]
    procedure TestWallSheltersTheBodyBehindIt;
    [Test]
    procedure TestSightDoesNotAskTheFarEnd;
    [Test]
    procedure TestBlastIsSpentWhenTheWaveHasGoneItsRadius;
    [Test]
    procedure TestLivesFallWithTheDistance;
    [Test]
    procedure TestLivesGrowWithTheGrade;
    [Test]
    procedure TestKnockShovesAwayFromTheHeart;
    [Test]
    procedure TestNearestPointLiesOnTheBody;
    [Test]
    procedure TestBarrelKillsFiftyLivesNextDoorOnEveryGrade;
  end;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  Sdl2.Core,
  Monsters.Defs;

const
  Radius = 80;
  HeartLives = 100;
  // The wave goes 8 units a tick: ten ticks to the radius
  TicksToRadius = 10;
  // Where a body in the next cell begins, from the middle of this one:
  // half a cell and the hit inset
  NextDoor = 24;
  FarOff = 56;
  // The wall of the sheltered tests: solid from here, 8 units thick
  WallNear = 40;
  WallFar = 48;

function PointAt(AX, AY: Single): TSdlFPoint;
begin
  Result.X := AX;
  Result.Y := AY;
end;

function OpenAir(AX, AY: Single): Boolean;
begin
  Result := False;
end;

function ThinWall(AX, AY: Single): Boolean;
begin
  Result := (AX >= WallNear) and (AX < WallFar);
end;

function SolidFromFarOff(AX, AY: Single): Boolean;
begin
  Result := AX >= FarOff;
end;

function SamePoint(const APoint: TSdlFPoint; AX, AY: Single): Boolean;
begin
  Result := (APoint.X = AX) and (APoint.Y = AY);
end;

procedure TBlastTests.Setup;
begin
  var Def := Default(TBlastDef);
  Def.Radius := Radius;
  Def.Lives := HeartLives;
  FBlast := TBlast.Create(PointAt(0, 0), Def);
  FNearBody := TObject.Create;
  FFarBody := TObject.Create;
end;

procedure TBlastTests.TearDown;
begin
  FreeAndNil(FFarBody);
  FreeAndNil(FNearBody);
  FreeAndNil(FBlast);
end;

procedure TBlastTests.TestWaveReachesANearBodyBeforeAFarOne;
begin
  var NearTick := 0;
  var FarTick := 0;
  for var i := 1 to TicksToRadius do
  begin
    FBlast.Spread;
    if FBlast.Strikes(FNearBody, PointAt(NextDoor, 0), OpenAir) then
      NearTick := i;
    if FBlast.Strikes(FFarBody, PointAt(FarOff, 0), OpenAir) then
      FarTick := i;
  end;

  Assert.AreEqual(3, NearTick, 'the body 24 units off');
  Assert.AreEqual(7, FarTick, 'the body 56 units off');
end;

procedure TBlastTests.TestBodyIsStruckOnce;
begin
  var Strikes := 0;
  for var i := 1 to TicksToRadius do
  begin
    FBlast.Spread;
    if FBlast.Strikes(FNearBody, PointAt(NextDoor, 0), OpenAir) then
      Inc(Strikes);
  end;

  Assert.AreEqual(1, Strikes);
end;

procedure TBlastTests.TestBodyBeyondTheRadiusIsNeverStruck;
begin
  var Strikes := 0;
  for var i := 1 to TicksToRadius + 2 do
  begin
    FBlast.Spread;
    if FBlast.Strikes(FFarBody, PointAt(Radius + 1, 0), OpenAir) then
      Inc(Strikes);
  end;

  Assert.AreEqual(0, Strikes);
end;

procedure TBlastTests.TestWallSheltersTheBodyBehindIt;
begin
  var BeforeWall := 0;
  var BehindWall := 0;
  for var i := 1 to TicksToRadius do
  begin
    FBlast.Spread;
    if FBlast.Strikes(FNearBody, PointAt(NextDoor, 0), ThinWall) then
      Inc(BeforeWall);
    if FBlast.Strikes(FFarBody, PointAt(FarOff, 0), ThinWall) then
      Inc(BehindWall);
  end;

  Assert.AreEqual(1, BeforeWall, 'the body this side of the wall');
  Assert.AreEqual(0, BehindWall, 'the body behind the wall');
end;

procedure TBlastTests.TestSightDoesNotAskTheFarEnd;
begin
  Assert.IsTrue(SightClear(PointAt(0, 0), PointAt(FarOff, 0),
    SolidFromFarOff), 'a body flush against matter is hidden by it');
  Assert.IsFalse(SightClear(PointAt(0, 0), PointAt(FarOff + 8, 0),
    SolidFromFarOff), 'a body inside matter is seen');
end;

procedure TBlastTests.TestBlastIsSpentWhenTheWaveHasGoneItsRadius;
begin
  for var i := 1 to TicksToRadius - 1 do
    FBlast.Spread;
  Assert.IsFalse(FBlast.Spent, 'a tick short of the radius');

  FBlast.Spread;
  Assert.IsTrue(FBlast.Spent, 'at the radius');
end;

procedure TBlastTests.TestLivesFallWithTheDistance;
begin
  Assert.AreEqual(100, FBlast.Lives(PointAt(0, 0), 1), 'at the heart');
  Assert.AreEqual(70, FBlast.Lives(PointAt(NextDoor, 0), 1), '24 units off');
  Assert.AreEqual(30, FBlast.Lives(PointAt(0, FarOff), 1), '56 units up');
  Assert.AreEqual(1, FBlast.Lives(PointAt(Radius, 0), 1), 'at the radius');
end;

procedure TBlastTests.TestLivesGrowWithTheGrade;
begin
  Assert.AreEqual(105, FBlast.Lives(PointAt(NextDoor, 0), 1.5));
  Assert.AreEqual(140, FBlast.Lives(PointAt(NextDoor, 0), 2));
end;

procedure TBlastTests.TestKnockShovesAwayFromTheHeart;
begin
  var Near := PointAt(NextDoor, 0);

  Assert.AreEqual(22, FBlast.Knock(Near, NextDoor + 8), 'a body to the right');
  Assert.AreEqual(-22, FBlast.Knock(Near, -NextDoor - 8), 'a body to the left');
  Assert.AreEqual(0, FBlast.Knock(Near, 0), 'a body over the heart');
end;

procedure TBlastTests.TestNearestPointLiesOnTheBody;
var
  Body: TSdlFRect;
begin
  Body.X := 24;
  Body.Y := -16;
  Body.W := 16;
  Body.H := 32;

  Assert.IsTrue(SamePoint(NearestPoint(Body, PointAt(0, 0)), 24, 0),
    'from the left: the left edge');
  Assert.IsTrue(SamePoint(NearestPoint(Body, PointAt(100, 100)), 40, 16),
    'from below right: the corner');
  Assert.IsTrue(SamePoint(NearestPoint(Body, PointAt(30, 5)), 30, 5),
    'from inside: the point itself');
end;

procedure TBlastTests.TestBarrelKillsFiftyLivesNextDoorOnEveryGrade;
const
  // The gunner of level 2, screen 4, shut in a dead end with a barrel
  GunnerLives = 50;
  Grades: array [0..2] of Double = (1.0, 1.5, 2.0);
begin
  var Registry := TMonsterRegistry.Create;
  try
    Registry.LoadFromFile(
      TPath.Combine(ExtractFilePath(ParamStr(0)), 'monsters.json'));
    var Barrel := TBlast.Create(PointAt(0, 0), Registry.Find('barrel').Blast);
    try
      for var Grade in Grades do
        Assert.IsTrue(
          Barrel.Lives(PointAt(NextDoor, 0), Grade) >= GunnerLives * Grade,
          Format('The barrel leaves the gunner alive on the grade x%g',
            [Grade]));
    finally
      Barrel.Free;
    end;
  finally
    Registry.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TBlastTests);

end.
