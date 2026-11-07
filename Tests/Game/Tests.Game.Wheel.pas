{
  Tests.Game.Wheel - the wheel off the Ram's axle: nothing till it is
  off; it hops off the road and strikes it, bounces lower each time and
  strikes softer, told at every strike and only then, and rolls on along
  it, never into it; one dropped from over the road falls onto the road
  line it was given, strikes harder and bounces higher than a hopped one.
  To the right at an even pace, turning clockwise by the way it rolls;
  gone once past the right edge and not before. It touches a body in its
  way and not one over it; it throws away from its middle - straight up
  against the edge of the screen. A stop takes it.
  A bullet meets its rim where it comes to it, the rim's way out there; a
  bullet past it, or one at a wheel not off, meets nothing.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Game.Wheel;

interface

uses
  DUnitX.TestFramework,
  Game.Wheel;

type
  [TestFixture]
  TLooseWheelTests = class
  private
    FWheel: TLooseWheel;
    // Rolled till gone: the speed of each strike, and the top of the flight
    // before each, from the road
    procedure Strikes(out ASpeeds, ATops: TArray<Single>);
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure TestNothingTillItIsOff;
    [Test]
    procedure TestBouncesLowerAndSofterThenRollsOnTheRoad;
    [Test]
    procedure TestToldAtEveryStrikeOnlyThen;
    [Test]
    procedure TestADroppedOneFallsOntoItsRoadAndBouncesHigher;
    [Test]
    procedure TestRollsRightAtAnEvenPace;
    [Test]
    procedure TestTurnsClockwiseByTheWayItRolls;
    [Test]
    procedure TestGoneOncePastTheRightEdge;
    [Test]
    procedure TestTouchesABodyInItsWayNotOneOverIt;
    [Test]
    procedure TestThrowsAwayFromItsMiddle;
    [Test]
    procedure TestAStopTakesIt;
    [Test]
    procedure TestABulletMeetsItsRimFacingIt;
    [Test]
    procedure TestABulletOverItMeetsNothing;
    [Test]
    procedure TestNoWheelOffNothingMeetsABullet;
  end;

implementation

uses
  System.Math,
  System.SysUtils,
  Sdl2.Core,
  Game.Space;

const
  Slop = 0.001;
  Radius = 20.5;
  Road = 352.0;
  // Enough ticks for it to roll off any screen
  ManyTicks = 400;
  HeroWidth = 16.0;
  HeroHeight = 32.0;

function At(AX, AY: Single): TSdlFPoint;
begin
  Result.X := AX;
  Result.Y := AY;
end;

function HeroOnTheRoad(AX: Single): TSdlFRect;
begin
  Result.X := AX;
  Result.Y := Road - HeroHeight;
  Result.W := HeroWidth;
  Result.H := HeroHeight;
end;

function OnItsAxle: TSdlFPoint;
begin
  Result := At(140, Road - Radius);
end;

{ TLooseWheelTests }

procedure TLooseWheelTests.Setup;
begin
  FWheel := Default(TLooseWheel);
end;

procedure TLooseWheelTests.TestNothingTillItIsOff;
begin
  Assert.IsFalse(FWheel.Running, 'Not running');
  for var i := 1 to ManyTicks do
    Assert.IsFalse(FWheel.Tick, Format('Came down at tick %d', [Integer(i)]));
  Assert.IsFalse(FWheel.Touches(HeroOnTheRoad(OnItsAxle.X)), 'Touches nothing');
end;

procedure TLooseWheelTests.Strikes(out ASpeeds, ATops: TArray<Single>);
begin
  ASpeeds := nil;
  ATops := nil;
  var Top: Single := Road - FWheel.Contact.Y;
  while FWheel.Running do
  begin
    var Struck := FWheel.Tick;
    Top := Max(Top, Road - FWheel.Contact.Y);
    if not Struck then
      Continue;
    ASpeeds := ASpeeds + [FWheel.Struck];
    ATops := ATops + [Top];
    Top := 0;
  end;
end;

procedure TLooseWheelTests.TestBouncesLowerAndSofterThenRollsOnTheRoad;
var
  Speeds, Tops: TArray<Single>;
begin
  FWheel.Start(OnItsAxle, Radius);
  Strikes(Speeds, Tops);
  Assert.IsTrue(Length(Speeds) >= 2, 'It bounces');
  Assert.IsTrue(Tops[0] > 10, 'Off the road');
  for var i := 1 to High(Speeds) do
  begin
    Assert.IsTrue(Speeds[i] < Speeds[i - 1], Format('Softer at strike %d', [i]));
    Assert.IsTrue(Tops[i] < Tops[i - 1], Format('Lower before strike %d', [i]));
  end;

  FWheel.Start(OnItsAxle, Radius);
  var Heights: TArray<Single> := nil;
  var LastStrike := -1;
  while FWheel.Running do
  begin
    if FWheel.Tick then
      LastStrike := Length(Heights);
    Heights := Heights + [FWheel.CenterAt(1).Y];
    Assert.IsTrue(FWheel.CenterAt(1).Y <= OnItsAxle.Y + Slop, 'Never into the road');
  end;
  Assert.IsTrue(LastStrike < High(Heights), 'It rolls after its last strike');
  for var i := LastStrike to High(Heights) do
    Assert.AreEqual(Double(OnItsAxle.Y), Double(Heights[i]), Slop,
      Format('On the road at tick %d after the last strike', [i - LastStrike]));
end;

procedure TLooseWheelTests.TestToldAtEveryStrikeOnlyThen;
begin
  FWheel.Start(OnItsAxle, Radius);
  var Told := 0;
  while FWheel.Running do
  begin
    var Struck := FWheel.Tick;
    Assert.IsTrue(Struck = (FWheel.Struck > 0), 'Struck only on the tick told');
    if not Struck then
      Continue;
    Inc(Told);
    Assert.AreEqual(Double(Road), Double(FWheel.Contact.Y), Slop,
      'Its rim on the road');
  end;
  Assert.IsTrue(Told >= 2, 'More than once');
  Assert.AreEqual(0.0, Double(FWheel.Struck), Slop, 'Nothing once gone');
end;

procedure TLooseWheelTests.TestADroppedOneFallsOntoItsRoadAndBouncesHigher;
const
  Over = 48.0;
var
  Speeds, Tops, Dropped, DroppedTops: TArray<Single>;
begin
  FWheel.Start(OnItsAxle, Radius);
  Strikes(Speeds, Tops);
  var OverTheRoad := At(OnItsAxle.X, OnItsAxle.Y - Over);
  FWheel.Drop(OverTheRoad, Radius, OnItsAxle.Y);
  var Fell := False;
  while FWheel.Running and not Fell do
  begin
    Fell := FWheel.Tick;
    if Fell then
      Assert.AreEqual(Double(Road), Double(FWheel.Contact.Y), Slop,
        'Onto the road it was given');
    Assert.IsTrue(FWheel.Contact.Y <= Road + Slop, 'Never into the road');
  end;
  Assert.IsTrue(Fell, 'Never came down');

  FWheel.Drop(OverTheRoad, Radius, OnItsAxle.Y);
  Strikes(Dropped, DroppedTops);
  Assert.IsTrue(Dropped[0] > Speeds[0] + 1, 'A harder first strike');
  Assert.IsTrue(DroppedTops[1] > Tops[0] + 10, 'Its bounce over the hopped one''s hop');
end;

procedure TLooseWheelTests.TestRollsRightAtAnEvenPace;
begin
  FWheel.Start(OnItsAxle, Radius);
  for var i := 1 to 50 do
  begin
    FWheel.Tick;
    Assert.AreEqual(Double(WheelRollPace),
      Double(FWheel.CenterAt(1).X - FWheel.CenterAt(0).X), Slop,
      Format('Tick %d', [Integer(i)]));
  end;
end;

// Under a whole turn a tick, so no wrap in between
procedure TLooseWheelTests.TestTurnsClockwiseByTheWayItRolls;
begin
  FWheel.Start(OnItsAxle, Radius);
  for var i := 1 to 20 do
  begin
    FWheel.Tick;
    Assert.AreEqual(Double(RadToDeg(WheelRollPace / Radius)),
      Double(FWheel.TurnAt(1) - FWheel.TurnAt(0)), Slop,
      Format('Tick %d', [Integer(i)]));
  end;
end;

procedure TLooseWheelTests.TestGoneOncePastTheRightEdge;
begin
  FWheel.Start(OnItsAxle, Radius);
  var Ticks := 0;
  while FWheel.Running and (Ticks < ManyTicks) do
  begin
    var Before := FWheel.CenterAt(1).X;
    FWheel.Tick;
    Inc(Ticks);
    if not FWheel.Running then
      Assert.IsTrue(Before + WheelRollPace - Radius > ScreenWidth,
        'Gone with a part of it on the screen');
  end;
  Assert.IsFalse(FWheel.Running, 'Never gone');
end;

procedure TLooseWheelTests.TestTouchesABodyInItsWayNotOneOverIt;
const
  HighOver = 120.0;
begin
  var InItsWay := HeroOnTheRoad(400);
  var OverIt := InItsWay;
  OverIt.Y := OverIt.Y - HighOver;
  FWheel.Start(OnItsAxle, Radius);
  var Touched := False;
  while FWheel.Running do
  begin
    FWheel.Tick;
    Touched := Touched or FWheel.Touches(InItsWay);
    Assert.IsFalse(FWheel.Touches(OverIt), 'Touched one over it');
  end;
  Assert.IsTrue(Touched, 'Never reached the one in its way');
end;

procedure TLooseWheelTests.TestThrowsAwayFromItsMiddle;
begin
  FWheel.Start(OnItsAxle, Radius);
  Assert.AreEqual(1, FWheel.AwaySide(HeroOnTheRoad(OnItsAxle.X + 10)),
    'From its right, to the right');
  Assert.AreEqual(-1, FWheel.AwaySide(HeroOnTheRoad(OnItsAxle.X - 20)),
    'From its left, to the left');
  var NearTheEdge := At(ScreenWidth - Radius - HeroWidth / 2, OnItsAxle.Y);
  FWheel.Start(NearTheEdge, Radius);
  Assert.AreEqual(0, FWheel.AwaySide(HeroOnTheRoad(NearTheEdge.X + 2)),
    'Against the edge, straight up');
end;

procedure TLooseWheelTests.TestAStopTakesIt;
begin
  FWheel.Start(OnItsAxle, Radius);
  FWheel.Tick;
  FWheel.Stop;
  Assert.IsFalse(FWheel.Running, 'Gone');
  Assert.IsFalse(FWheel.Tick, 'Nothing more');
  Assert.IsFalse(FWheel.Touches(HeroOnTheRoad(OnItsAxle.X)), 'Touches nothing');
end;

// From the left at the height of its middle: its leftmost point, the rim
// looking left
procedure TLooseWheelTests.TestABulletMeetsItsRimFacingIt;
const
  Flight = 12.0;
begin
  var Middle := OnItsAxle;
  FWheel.Start(Middle, Radius);
  var Where, Normal: TSdlFPoint;
  Assert.IsTrue(FWheel.Strike(At(Middle.X - Radius - Flight / 2, Middle.Y),
    At(Middle.X - Radius + Flight / 2, Middle.Y), Where, Normal), 'Met');
  Assert.AreEqual(Double(Middle.X - Radius), Double(Where.X), Slop, 'On its rim');
  Assert.AreEqual(Double(Middle.Y), Double(Where.Y), Slop,
    'At its middle''s height');
  Assert.AreEqual(-1.0, Double(Normal.X), Slop, 'Looking left');
  Assert.AreEqual(0.0, Double(Normal.Y), Slop, 'Level');
end;

procedure TLooseWheelTests.TestABulletOverItMeetsNothing;
const
  Over = 4.0;
begin
  var Middle := OnItsAxle;
  FWheel.Start(Middle, Radius);
  var Top: Single := Middle.Y - Radius - Over;
  var Where, Normal: TSdlFPoint;
  Assert.IsFalse(FWheel.Strike(At(Middle.X - 2 * Radius, Top),
    At(Middle.X + 2 * Radius, Top), Where, Normal), 'Over it');
  Assert.IsFalse(FWheel.Strike(At(Middle.X - 3 * Radius, Middle.Y),
    At(Middle.X - 2 * Radius, Middle.Y), Where, Normal), 'Short of it');
end;

procedure TLooseWheelTests.TestNoWheelOffNothingMeetsABullet;
begin
  var Middle := OnItsAxle;
  var Where, Normal: TSdlFPoint;
  Assert.IsFalse(FWheel.Strike(At(Middle.X - 2 * Radius, Middle.Y),
    At(Middle.X + 2 * Radius, Middle.Y), Where, Normal), 'Not off');
end;

initialization
  TDUnitX.RegisterTestFixture(TLooseWheelTests);

end.
