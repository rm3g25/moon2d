{
  Tests.Monsters.Mount - the TeK mount under the ceiling: the tick its
  count starts from (the fireOffset of a placement) and when it watches
  (the sentry: asleep until the hero stands in the strip under it).

  The mount stands in an open room and the hero is two numbers handed to
  Tick. A mount fires when its count reaches its interval, and the room
  has no burst to take the volley, so no test here ticks a mount for
  anything near an interval. What a volley is and when it comes is left
  to the eye.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Monsters.Mount;

interface

uses
  DUnitX.TestFramework,
  Monsters,
  Tests.Rooms;

type
  [TestFixture]
  TMountTests = class
  private
    FRoom: TRoom;
    function Mount: TMonster;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestMountIsBornAsleep;
    [Test]
    procedure TestHeroUnderTheMountWakesIt;
    [Test]
    procedure TestHeroFarToEitherSideLeavesItAsleep;
    [Test]
    procedure TestStripEdgeIsInAndOneUnitBeyondIsOut;
    [Test]
    procedure TestHeroLevelWithTheMountIsNotInTheStrip;
    [Test]
    procedure TestHeroAboveTheMountIsNotInTheStrip;
    [Test]
    procedure TestMountFollowsTheHeroInAndOut;
    [Test]
    procedure TestMountThatCannotShootStaysAsleep;
    [Test]
    procedure TestBodiesWithoutASentryNeverSleep;
    [Test]
    procedure TestFireOffsetFromZeroToBelowTheIntervalLoads;
    [Test]
    procedure TestFireOffsetOutsideTheIntervalRaises;
  end;

implementation

uses
  System.SysUtils,
  Levels.Defs,
  Monsters.Defs;

const
  MountCol = 8;
  MountRow = 3;
  // The feet of a hero on the floor row of the room
  HeroFeetY = 352;
  // A body on the floor row, for the bodies that are no mounts
  BodyRow = 11;
  // The left edge of a hero far from any strip a body here could watch
  HeroFarX = 480;
  // A handful, far short of the interval of any body tried here
  FewTicks = 3;

function ReachOf(const AMount: TMonster): Integer;
begin
  Result := AMount.Def.Attack.Sentry.Reach;
end;

function IntervalOf(const AMount: TMonster): Integer;
begin
  Result := AMount.Def.Attack.FireEveryTicks;
end;

function FeetOf(const AMount: TMonster): Integer;
begin
  Result := Round(AMount.Y);
end;

// A body's X is its left edge and so is the hero's: the same X stands the
// hero under the middle of the mount
function HeroAcross(const AMount: TMonster; AAcross: Integer): Integer;
begin
  Result := Round(AMount.X) + AAcross;
end;

// One tick with the hero on the floor, AAcross units off the middle of
// the mount
procedure HeroStandsAcross(const AMount: TMonster; AAcross: Integer);
begin
  AMount.Tick(HeroAcross(AMount, AAcross), HeroFeetY, nil);
end;

function OffsetOverride(AOffset: Integer): TEntityOverrides;
begin
  Result := Default(TEntityOverrides);
  Result.HasFireOffset := True;
  Result.FireOffset := AOffset;
end;

function MuteOverride: TEntityOverrides;
begin
  Result := Default(TEntityOverrides);
  Result.HasCanShoot := True;
  Result.CanShoot := False;
end;

function MountWith(const ARoom: TRoom;
  const AOverrides: TEntityOverrides): TMonster;
begin
  var Placement := Default(TEntityPlacement);
  Placement.MonsterId := 'mount';
  Placement.X := MountCol;
  Placement.Y := MountRow;
  Placement.Overrides := AOverrides;
  Result := ARoom.Place(Placement);
end;

// By value, not const: an anonymous method captures them
procedure ExpectOffsetRefused(ARoom: TRoom; AOffset: Integer);
begin
  Assert.WillRaise(
    procedure
    begin
      MountWith(ARoom, OffsetOverride(AOffset));
    end, ELevelError, Format('A fire offset of %d', [AOffset]));
end;

procedure ExpectOffsetLoads(ARoom: TRoom; AOffset: Integer);
begin
  Assert.WillNotRaise(
    procedure
    begin
      MountWith(ARoom, OffsetOverride(AOffset));
    end, ELevelError, Format('A fire offset of %d', [AOffset]));
end;

procedure ExpectNeverSleeps(const ABody: TMonster);
begin
  var Id := ABody.Def.Id;
  Assert.IsFalse(ABody.Asleep, 'Before the first tick: ' + Id);
  for var i := 1 to FewTicks do
    ABody.Tick(HeroFarX, HeroFeetY, nil);
  Assert.IsFalse(ABody.Asleep, 'With the hero far off: ' + Id);
end;

procedure ExpectEdgeOfStrip(const AMount: TMonster; ASide: Integer);
begin
  var Reach := ReachOf(AMount);
  HeroStandsAcross(AMount, ASide * Reach);
  Assert.IsFalse(AMount.Asleep,
    Format('A hero %d units off the middle is in the strip', [ASide * Reach]));
  HeroStandsAcross(AMount, ASide * (Reach + 1));
  Assert.IsTrue(AMount.Asleep,
    Format('A hero %d units off the middle is out of it',
      [ASide * (Reach + 1)]));
end;

procedure TMountTests.Setup;
begin
  FRoom := RoomFromRows(RoomRowsOf(0, 0, 0, 0));
end;

procedure TMountTests.TearDown;
begin
  FreeAndNil(FRoom);
end;

function TMountTests.Mount: TMonster;
begin
  Result := FRoom.Place('mount', MountCol, MountRow);
end;

procedure TMountTests.TestMountIsBornAsleep;
begin
  Assert.IsTrue(Mount.Asleep, 'A mount that has seen no hero');
end;

procedure TMountTests.TestHeroUnderTheMountWakesIt;
begin
  var Sentry := Mount;
  HeroStandsAcross(Sentry, 0);
  Assert.IsFalse(Sentry.Asleep, 'A hero right under the mount');
end;

procedure TMountTests.TestHeroFarToEitherSideLeavesItAsleep;
begin
  var Sentry := Mount;
  var Far := ReachOf(Sentry) * 3;
  HeroStandsAcross(Sentry, Far);
  Assert.IsTrue(Sentry.Asleep, 'A hero far to the right');
  HeroStandsAcross(Sentry, -Far);
  Assert.IsTrue(Sentry.Asleep, 'A hero far to the left');
end;

procedure TMountTests.TestStripEdgeIsInAndOneUnitBeyondIsOut;
begin
  var Sentry := Mount;
  ExpectEdgeOfStrip(Sentry, 1);
  ExpectEdgeOfStrip(Sentry, -1);
end;

procedure TMountTests.TestHeroLevelWithTheMountIsNotInTheStrip;
begin
  var Sentry := Mount;
  Sentry.Tick(HeroAcross(Sentry, 0), FeetOf(Sentry), nil);
  Assert.IsTrue(Sentry.Asleep, 'A hero whose feet are on the mount''s line');

  Sentry.Tick(HeroAcross(Sentry, 0), FeetOf(Sentry) + 1, nil);
  Assert.IsFalse(Sentry.Asleep, 'A hero one unit lower');
end;

procedure TMountTests.TestHeroAboveTheMountIsNotInTheStrip;
const
  Above = 64;
begin
  var Sentry := Mount;
  Sentry.Tick(HeroAcross(Sentry, 0), FeetOf(Sentry) - Above, nil);
  Assert.IsTrue(Sentry.Asleep, 'A hero over the mount, in line with it');
end;

procedure TMountTests.TestMountFollowsTheHeroInAndOut;
begin
  var Sentry := Mount;
  var Far := ReachOf(Sentry) * 3;

  HeroStandsAcross(Sentry, 0);
  Assert.IsFalse(Sentry.Asleep, 'The hero steps under it');
  HeroStandsAcross(Sentry, Far);
  Assert.IsTrue(Sentry.Asleep, 'The hero walks away');
  HeroStandsAcross(Sentry, 0);
  Assert.IsFalse(Sentry.Asleep, 'The hero comes back');
end;

procedure TMountTests.TestMountThatCannotShootStaysAsleep;
begin
  var Sentry := MountWith(FRoom, MuteOverride);
  for var i := 1 to FewTicks do
    HeroStandsAcross(Sentry, 0);
  Assert.IsTrue(Sentry.Asleep, 'A mute mount with the hero right under it');
end;

procedure TMountTests.TestBodiesWithoutASentryNeverSleep;
begin
  ExpectNeverSleeps(FRoom.Place('medkit', MountCol, BodyRow));
  ExpectNeverSleeps(FRoom.Place('gravel', MountCol, BodyRow));
end;

procedure TMountTests.TestFireOffsetFromZeroToBelowTheIntervalLoads;
begin
  ExpectOffsetLoads(FRoom, 0);
  ExpectOffsetLoads(FRoom, IntervalOf(Mount) - 1);
end;

procedure TMountTests.TestFireOffsetOutsideTheIntervalRaises;
begin
  ExpectOffsetRefused(FRoom, -1);
  ExpectOffsetRefused(FRoom, IntervalOf(Mount));
  ExpectOffsetRefused(FRoom, IntervalOf(Mount) + 1);
end;

initialization
  TDUnitX.RegisterTestFixture(TMountTests);

end.
