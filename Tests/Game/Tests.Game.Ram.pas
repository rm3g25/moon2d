{
  Tests.Game.Ram - TeK-R13, the Ram: the whole entrance waits out the
  silence, drives in and stops at its mark, breathes, lights its eye and
  locks its head; a second start after a death begins at the stop; a new
  level sees the whole entrance again; after the lock it drives legs of
  its own between the walls, now and then to a wall. The eye blinks while
  the head rises and breathes after; the lens winks once the head locks.
  A touch on the floor wounds and throws away from the middle, straight
  up at a wall; a thrown hero is out of its way until he comes down; a
  hero on a pad is out of its way, in the air over it too, until he comes
  down onto the floor; a fall onto it from above wounds. The shield takes
  a bullet, an absent machine nothing. And the shield over a body, and
  the ram action of a level's events, and the Ram of level 2's boss
  arena.

  The hunter: its lives follow the grade; only its eye takes a hit, and
  the last life blows the head up, the eye blinks through the change and
  the sweeper rises. A hero low on the road is pressed to the wall on his
  side and not shot at; one on a pad is not pressed but shot at, the lens
  burning red before every burst and a rest between bursts; the first
  shots fly at him, a hero past the vertical turns the head, and the last
  third fires a hose of six. The head's row of lives: none before the
  lock; it comes up a cell at a time after it, the lens burning white,
  before the first shot; it follows the lives; a dead head's row fades.
  Either head shorts out from half its lives, harder as they go, and a
  blown-up head no more. The sweeper's last life overloads it first: it
  holds its fire, the eye blinks, the machine stands, and it bursts with
  a shock, a flash and a heavier jolt; the hunter bursts with none. The
  shock wave runs out over the screen in about a second and is gone, a
  death takes it away; it throws the hero once, away from the hull, or
  from over it toward the side with more road; it reaches a point near
  the blast before one far from it.

  The Ram only counts, so the tests tick it with a body of their own: the
  hull's whole box solid. The arena is read from level2.json beside the
  executable.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Game.Ram;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  Levels.Events,
  Game.Shield,
  Game.Ram;

type
  [TestFixture]
  TRamTests = class
  private
    FRam: TRam;
    function TicksUntil(ALimit: Integer;
      const AHeard: TFunc<TRamCue, Boolean>): Integer;
    procedure StandAtTheStop;
    procedure StandAt(AStop: Single);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestWholeEntranceWaitsOutTheSilence;
    [Test]
    procedure TestDrivesInAndStopsAtItsMark;
    [Test]
    procedure TestHeadLocksAfterTheBreath;
    [Test]
    procedure TestDeathReplaysFromTheStop;
    [Test]
    procedure TestNewLevelSeesTheWholeEntranceAgain;
    [Test]
    procedure TestAfterTheLockItDrivesLegsBetweenTheWalls;
    [Test]
    procedure TestSomeLegsEndAtAWall;
    [Test]
    procedure TestEyeBlinksWhileTheHeadRises;
    [Test]
    procedure TestEyeBreathesAtRest;
    [Test]
    procedure TestLensWinksOnceTheHeadLocks;
    [Test]
    procedure TestTouchOnTheFloorWounds;
    [Test]
    procedure TestHeroOnAPadIsOutOfItsWay;
    [Test]
    procedure TestFallOntoItWounds;
    [Test]
    procedure TestThrownAwayFromTheMiddle;
    [Test]
    procedure TestPinnedAtAWallThrownStraightUp;
    [Test]
    procedure TestThrownHeroIsOutOfItsWayTillHeLands;
    [Test]
    procedure TestTheWayOutOfTheHullCloses;
    [Test]
    procedure TestShieldTakesABullet;
    [Test]
    procedure TestAbsentMeetsNothing;
  end;

  [TestFixture]
  TBodyShieldTests = class
  public
    [Test]
    procedure TestHoldsTheBodyAndAMarginPastIt;
    [Test]
    procedure TestAStripHoldsItsRow;
  end;

  [TestFixture]
  TRamLevelTests = class
  public
    [Test]
    procedure TestRamIsRead;
    [Test]
    procedure TestBadRamRaises;
    [Test]
    procedure TestLevelTwoArenaBringsTheRam;
  end;

  [TestFixture]
  TRamHunterTests = class
  private
    FRam: TRam;
    procedure LockWith(const ATarget: TRamTarget; ALivesShare: Single = 1);
    procedure StrikeTheEye(ATimes: Integer);
    function ShotTicks(const ATarget: TRamTarget; ATicks: Integer): TArray<Integer>;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestLivesFollowTheGrade;
    [Test]
    procedure TestOnlyTheEyeTakesAHit;
    [Test]
    procedure TestTheLastLifeBlowsTheHeadUp;
    [Test]
    procedure TestHeroLowIsPressedToHisWall;
    [Test]
    procedure TestHeroOnAPadIsNotPressed;
    [Test]
    procedure TestAPressHoldsTheFire;
    [Test]
    procedure TestTheLensBurnsBeforeABurst;
    [Test]
    procedure TestBurstsAreSeparatedByARest;
    [Test]
    procedure TestTheFirstShotsFlyAtTheHero;
    [Test]
    procedure TestHeadTurnsToAHeroPastTheVertical;
    [Test]
    procedure TestTheLastThirdFiresAHose;
    [Test]
    procedure TestNoRowBeforeTheLock;
    [Test]
    procedure TestTheRowComesUpAfterTheLock;
    [Test]
    procedure TestTheRowFollowsTheLives;
    [Test]
    procedure TestADeadHeadsRowFades;
    [Test]
    procedure TestShortsOutFromHalfItsLives;
  end;

  [TestFixture]
  TRamSweeperTests = class
  private type
    TFired = record
      Tick: Integer;
      Cue: TRamCue;
    end;
    TBurstRow = record
      FirstTick, LastTick: Integer;
      LowestY, HighestY: Single;
    end;
  private
    FRam: TRam;
    procedure ArmTheSweeper(const ATarget: TRamTarget; ALivesShare: Single = 1);
    procedure StrikeThePack(ATimes: Integer);
    function Shots(const ATarget: TRamTarget; ATicks: Integer): TArray<TFired>;
    function Bursts(const AShots: TArray<TFired>): TArray<TBurstRow>;
    function BlastWithin(const ATarget: TRamTarget; ALimit: Integer): Integer;
    procedure BlowTheSweeper(const ATarget: TRamTarget);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestLivesFollowTheGrade;
    [Test]
    procedure TestRidesToTheHerosRow;
    [Test]
    procedure TestHeroLowClosesTheCeiling;
    [Test]
    procedure TestTheBarrelsBurnBeforeASweep;
    [Test]
    procedure TestASweepIsLevelAlongHisRow;
    [Test]
    procedure TestTheWholePackTakesAHit;
    [Test]
    procedure TestThePlatesTakeABulletFromBelow;
    [Test]
    procedure TestTheMiddleThirdForks;
    [Test]
    procedure TestTheLastThirdClimbsALadder;
    [Test]
    procedure TestTurnsToAHeroOnItsOtherSide;
    [Test]
    procedure TestTheLastLifeLeavesTheMastEmpty;
    [Test]
    procedure TestShortsOutFromHalfItsLives;
    [Test]
    procedure TestTheLastLifeOverloadsBeforeTheBlast;
    [Test]
    procedure TestBacksToTheRightWallBeforeTheOverload;
    [Test]
    procedure TestTheWaveLeavesHimInFrontTillHeIsClear;
    [Test]
    procedure TestTheBlastSendsAWave;
    [Test]
    procedure TestTheWaveThrowsTheHeroOnceAwayFromTheHull;
    [Test]
    procedure TestTheWaveThrowsFromOverTheHullTowardMoreRoad;
    [Test]
    procedure TestTheWaveReachesTheNearFirst;
  end;

implementation

uses
  System.IOUtils,
  System.JSON,
  System.Math,
  Sdl2.Core,
  Game.Space,
  Levels.Defs;

const
  Seed = 1;
  Stop = 260.0;
  SilenceSeconds = 1.0;
  TicksPerSecond = 33;
  // Enough for anything the entrance or a leg does
  ManyTicks = 1000;
  LevelTwoFile = 'level2.json';
  LevelTwoArenaScreen = 13;
  // The hero's height
  HeroSide = 32;

function SolidBody(AWidth, AHeight: Integer): TShieldMask;
begin
  Result.Width := AWidth;
  Result.Height := AHeight;
  Result.Middle.X := AWidth / 2;
  Result.Middle.Y := AHeight / 2;
  SetLength(Result.Solid, AWidth * AHeight);
  for var i := 0 to High(Result.Solid) do
    Result.Solid[i] := True;
end;

function OrdersAt(AStop: Single): TRamOrders;
begin
  Result.Stop := AStop;
  Result.Track := 'boss.ogg';
  Result.SilenceSeconds := SilenceSeconds;
end;

function Orders: TRamOrders;
begin
  Result := OrdersAt(Stop);
end;

function Box(AX, AY, AW, AH: Single): TSdlFRect;
begin
  Result.X := AX;
  Result.Y := AY;
  Result.W := AW;
  Result.H := AH;
end;

function At(AX, AY: Single): TSdlFPoint;
begin
  Result.X := AX;
  Result.Y := AY;
end;

// A hero's body, his feet on the road, his left edge at AX
function OnTheRoad(AX: Single): TSdlFRect;
begin
  Result := Box(AX, RamFloorY - HeroSide, 16, HeroSide);
end;

procedure TRamTests.Setup;
begin
  FRam := TRam.Create(SolidBody(Round(RamWidth), Round(RamHeight)), Seed);
end;

procedure TRamTests.TearDown;
begin
  FRam.Free;
end;

// Ticks until a cue AHeard picks out, that cue's tick counted; -1 when
// none comes within ALimit
function TRamTests.TicksUntil(ALimit: Integer;
  const AHeard: TFunc<TRamCue, Boolean>): Integer;
begin
  for var i := 1 to ALimit do
    if AHeard(FRam.Tick) then
      Exit(i);
  Result := -1;
end;

// The whole entrance seen, then a death: the Ram stands at its mark
procedure TRamTests.StandAtTheStop;
begin
  StandAt(Stop);
end;

procedure TRamTests.StandAt(AStop: Single);
begin
  FRam.Start(OrdersAt(AStop));
  FRam.Clear;
  FRam.Start(OrdersAt(AStop));
end;

function HeardRumble(ACue: TRamCue): Boolean;
begin
  Result := ACue.Rumble;
end;

function HeardHiss(ACue: TRamCue): Boolean;
begin
  Result := ACue.Hiss;
end;

function HeardWhine(ACue: TRamCue): Boolean;
begin
  Result := ACue.Whine;
end;

function HeardLock(ACue: TRamCue): Boolean;
begin
  Result := ACue.Locked;
end;

procedure TRamTests.TestWholeEntranceWaitsOutTheSilence;
begin
  Assert.IsTrue(FRam.Start(Orders), 'The first start is the whole entrance');
  Assert.IsFalse(FRam.Present, 'Not on the screen while the music fades');
  var Ticks := TicksUntil(ManyTicks, HeardRumble);
  Assert.IsTrue(Ticks > Round(SilenceSeconds * TicksPerSecond),
    Format('The rumble after the fade-out, not at tick %d', [Ticks]));
  Assert.IsTrue(Ticks < 2 * Round(SilenceSeconds * TicksPerSecond),
    Format('A beat of silence, not more: tick %d', [Ticks]));
  Assert.IsTrue(FRam.Left > ScreenWidth, 'It comes from beyond the right edge');
end;

procedure TRamTests.TestDrivesInAndStopsAtItsMark;
begin
  FRam.Start(Orders);
  TicksUntil(ManyTicks, HeardRumble);
  var Ticks := TicksUntil(ManyTicks, HeardHiss);
  Assert.AreEqual(Stop, FRam.Left, 0.001, 'The ram stops at its mark');
  Assert.IsTrue((Ticks >= 2.5 * TicksPerSecond) and
    (Ticks <= 4 * TicksPerSecond),
    Format('About 3 s from the rumble to the stop, not %d ticks', [Ticks]));
  Assert.IsFalse(FRam.EyeLit, 'The eye is dark at the stop');
end;

procedure TRamTests.TestHeadLocksAfterTheBreath;
begin
  FRam.Start(Orders);
  TicksUntil(ManyTicks, HeardHiss);
  var MastAtStop := FRam.Mast;
  var Breath := TicksUntil(ManyTicks, HeardWhine);
  Assert.IsTrue((Breath > 0) and (Breath <= TicksPerSecond),
    Format('A breath before the mast, not %d ticks', [Breath]));
  Assert.IsTrue(FRam.EyeLit, 'The eye lights as the mast starts');
  var Rise := TicksUntil(ManyTicks, HeardLock);
  Assert.IsTrue((Rise >= TicksPerSecond) and (Rise <= 2 * TicksPerSecond),
    Format('About 1.5 s of the mast, not %d ticks', [Rise]));
  Assert.IsTrue(FRam.Mast > MastAtStop + HeroSide,
    'The head has come up out of the well');
end;

procedure TRamTests.TestDeathReplaysFromTheStop;
begin
  FRam.Start(Orders);
  FRam.Clear;
  Assert.IsFalse(FRam.Present, 'Gone on a death');
  Assert.IsFalse(FRam.Start(Orders), 'The second start is not the whole one');
  Assert.IsTrue(FRam.Present, 'On the screen at once');
  Assert.AreEqual(Stop, FRam.Left, 0.001, 'At its mark');

  var Drove := False;
  for var i := 1 to ManyTicks do
  begin
    var Cue := FRam.Tick;
    Drove := Drove or Cue.Rumble or Cue.Hiss;
    if Cue.Locked then
      Break;
  end;
  Assert.IsFalse(Drove, 'No drive-in before the lock');
end;

procedure TRamTests.TestNewLevelSeesTheWholeEntranceAgain;
begin
  FRam.Start(Orders);
  FRam.Reset;
  Assert.IsTrue(FRam.Start(Orders), 'A new level: the whole entrance again');
end;

procedure TRamTests.TestAfterTheLockItDrivesLegsBetweenTheWalls;
const
  Legs = 6;
begin
  StandAtTheStop;
  TicksUntil(ManyTicks, HeardLock);
  var Last := FRam.Left;
  for var Leg := 1 to Legs do
  begin
    Assert.IsTrue(TicksUntil(ManyTicks, HeardRumble) > 0,
      Format('Leg %d starts', [Leg]));
    for var i := 1 to ManyTicks do
    begin
      var Cue := FRam.Tick;
      Assert.IsTrue((FRam.Left >= 0) and (FRam.Left + RamWidth <= ScreenWidth),
        Format('Leg %d stays between the walls', [Leg]));
      if Cue.Hiss then
        Break;
    end;
    Assert.IsTrue(Abs(FRam.Left - Last) >= HeroSide,
      Format('Leg %d goes somewhere', [Leg]));
    Last := FRam.Left;
  end;
end;

procedure TRamTests.TestSomeLegsEndAtAWall;
const
  Legs = 6;
begin
  StandAtTheStop;
  TicksUntil(ManyTicks, HeardLock);
  var AtAWall := 0;
  for var Leg := 1 to Legs do
  begin
    TicksUntil(ManyTicks, HeardHiss);
    if (FRam.Left = 0) or (FRam.Left + RamWidth = ScreenWidth) then
      Inc(AtAWall);
  end;
  Assert.IsTrue(AtAWall > 0, 'No floor by a wall is safe from it');
  Assert.IsTrue(AtAWall < Legs, 'Not every leg goes to a wall');
end;

procedure TRamTests.TestEyeBlinksWhileTheHeadRises;
const
  Watched = 30;
begin
  StandAtTheStop;
  TicksUntil(ManyTicks, HeardWhine);
  var Brightest: Single := 0;
  var Dimmest: Single := 1;
  for var i := 1 to Watched do
  begin
    FRam.Tick;
    Brightest := Max(Brightest, FRam.Eye);
    Dimmest := Min(Dimmest, FRam.Eye);
  end;
  Assert.IsTrue(Brightest >= 0.9, 'Flashes');
  Assert.IsTrue(Dimmest <= 0.2, 'And all but goes out between');
end;

procedure TRamTests.TestEyeBreathesAtRest;
const
  Watched = 100;
begin
  StandAtTheStop;
  Assert.AreEqual(0.0, FRam.Eye, 0.001, 'Dark before it wakes');
  TicksUntil(ManyTicks, HeardLock);
  var Brightest: Single := 0;
  var Dimmest: Single := 1;
  for var i := 1 to Watched do
  begin
    FRam.Tick;
    Brightest := Max(Brightest, FRam.Eye);
    Dimmest := Min(Dimmest, FRam.Eye);
  end;
  Assert.IsTrue(Dimmest > 0, 'Lit all the time');
  Assert.IsTrue(Brightest < 0.9, 'No flash: a blink is a warning');
  Assert.IsTrue(Brightest - Dimmest > 0.1, 'It breathes');
end;

procedure TRamTests.TestLensWinksOnceTheHeadLocks;
const
  Watched = 40;
begin
  StandAtTheStop;
  for var i := 1 to ManyTicks do
  begin
    if FRam.Tick.Locked then
      Break;
    Assert.AreEqual(0.0, FRam.Lens, 0.001, 'Dark until the head locks');
  end;
  var Winks := 0;
  var Dimmest: Single := 1;
  for var i := 1 to Watched do
  begin
    if FRam.Lens >= 1 then
      Inc(Winks);
    Dimmest := Min(Dimmest, FRam.Lens);
    FRam.Tick;
  end;
  Assert.IsTrue(Winks > 0, 'Winks');
  Assert.IsTrue((Dimmest > 0) and (Dimmest < 0.5), 'Over a faint ember');
  FRam.Clear;
  Assert.AreEqual(0.0, FRam.Lens, 0.001, 'Out when the machine is gone');
end;

procedure TRamTests.TestTouchOnTheFloorWounds;
begin
  StandAtTheStop;
  var Away: Integer;
  Assert.IsTrue(FRam.Contact(OnTheRoad(Stop + 10), False, False, Away),
    'The ram drives into a hero on the road');
  Assert.IsFalse(FRam.Contact(OnTheRoad(Stop - 40), False, False, Away),
    'A hero clear of it is not touched');
end;

procedure TRamTests.TestHeroOnAPadIsOutOfItsWay;
begin
  StandAtTheStop;
  var Away: Integer;
  var OverIt := OnTheRoad(Stop + 10);
  OverIt.Y := OverIt.Y - 72;
  Assert.IsFalse(FRam.Contact(OverIt, True, False, Away),
    'On a pad in front of it');
  Assert.IsFalse(FRam.Contact(OverIt, False, True, Away),
    'In the air off the pad, still in front of it');
  Assert.IsTrue(FRam.Contact(OnTheRoad(Stop + 10), False, False, Away),
    'Down on the road, in its way again');
end;

procedure TRamTests.TestFallOntoItWounds;
begin
  StandAtTheStop;
  var Away: Integer;
  var Above := Box(Stop + 60, RamTop - 2 * HeroSide, 16, HeroSide);
  Assert.IsFalse(FRam.Contact(Above, False, True, Away), 'Over the roof');
  Above.Y := RamTop - HeroSide / 2;
  Assert.IsTrue(FRam.Contact(Above, False, True, Away),
    'Dropped onto the roof from a pad above it');
end;

procedure TRamTests.TestThrownAwayFromTheMiddle;
begin
  StandAtTheStop;
  var Away: Integer;
  FRam.Contact(OnTheRoad(Stop + 10), False, False, Away);
  Assert.AreEqual(-1, Away, 'Left of the middle - to the left');
  // Out of the hull, so the next touch is a touch
  FRam.Contact(OnTheRoad(Stop - 40), False, False, Away);
  FRam.Contact(OnTheRoad(Stop + RamWidth - 26), False, False, Away);
  Assert.AreEqual(1, Away, 'Right of the middle - to the right');
end;

// A machine at the right wall and one at the left: a hero between it and
// the wall has no room to be thrown to
procedure TRamTests.TestPinnedAtAWallThrownStraightUp;
begin
  var Away: Integer;
  StandAt(ScreenWidth - RamWidth);
  Assert.IsTrue(FRam.Contact(OnTheRoad(ScreenWidth - 24), False, False, Away),
    'Touched at the right wall');
  Assert.AreEqual(0, Away, 'Straight up at the right wall');

  FRam.Reset;
  StandAt(0);
  Assert.IsTrue(FRam.Contact(OnTheRoad(8), False, False, Away),
    'Touched at the left wall');
  Assert.AreEqual(0, Away, 'Straight up at the left wall');
end;

procedure TRamTests.TestThrownHeroIsOutOfItsWayTillHeLands;
begin
  StandAtTheStop;
  var Away: Integer;
  var Hero := OnTheRoad(Stop + 10);
  Assert.IsTrue(FRam.Contact(Hero, False, False, Away), 'Touched');
  Assert.IsFalse(FRam.Contact(Hero, False, True, Away),
    'Flying from the throw, still over the hull');
  Assert.IsFalse(FRam.Contact(Hero, False, False, Away),
    'Down inside the hull: walking out of it');
  Assert.IsFalse(FRam.Contact(OnTheRoad(Stop - 40), False, False, Away),
    'Clear of it');
  Assert.IsTrue(FRam.Contact(Hero, False, False, Away),
    'Back into it: a touch again');
end;

// Down inside the hull he walks out unhurt, but not for ever: the hull is
// no shelter
procedure TRamTests.TestTheWayOutOfTheHullCloses;
const
  WayOutTicks = 45;
  ShelterTicks = 90;
begin
  StandAtTheStop;
  var Away: Integer;
  Assert.IsTrue(FRam.Contact(OnTheRoad(FRam.Left + 10), False, False, Away),
    'Touched');
  var Inside := 0;
  for var i := 1 to ShelterTicks do
  begin
    FRam.Tick;
    if FRam.Contact(OnTheRoad(FRam.Left + RamWidth / 2), False, False, Away) then
      Break;
    Inc(Inside);
  end;
  Assert.IsTrue(Inside >= WayOutTicks,
    Format('Unhurt inside for %d ticks', [Inside]));
  Assert.IsTrue(Inside < ShelterTicks, 'Then a touch again');
end;

procedure TRamTests.TestShieldTakesABullet;
begin
  StandAtTheStop;
  var Struck: TSdlFPoint;
  Assert.IsTrue(FRam.Block(At(Stop - 20, 300), At(Stop + 10, 300), Struck),
    'A bullet into the hull meets the shield');
  Assert.IsTrue((Struck.X < Stop) and (Struck.X > Stop - 4),
    Format('Just past the outline, not at %g', [Struck.X]));
  Assert.IsFalse(FRam.Block(At(Stop - 20, 100), At(Stop + 10, 100), Struck),
    'A bullet over the machine flies on');
end;

procedure TRamTests.TestAbsentMeetsNothing;
begin
  var Away: Integer;
  var Struck: TSdlFPoint;
  Assert.IsFalse(FRam.Contact(OnTheRoad(Stop + 10), False, False, Away),
    'Nothing to touch before it comes');
  Assert.IsFalse(FRam.Block(At(Stop - 20, 300), At(Stop + 10, 300), Struck),
    'Nothing to shoot');
  FRam.Start(Orders);
  Assert.IsFalse(FRam.Contact(OnTheRoad(ScreenWidth - 20), False, False, Away),
    'Nothing while the music fades');
end;

// A body of ten by ten units, its middle in the middle: the shield holds
// it and two units past its sides and its top, nothing under its foot
procedure TBodyShieldTests.TestHoldsTheBodyAndAMarginPastIt;
begin
  var Shield := TTekShield.CreateOver(SolidBody(10, 10));
  try
    Shield.Rise;
    Assert.IsTrue(Shield.Holds(At(0, 0)), 'The middle');
    Assert.IsTrue(Shield.Holds(At(6.5, 0)), 'A unit and a half past the side');
    Assert.IsFalse(Shield.Holds(At(8, 0)), 'Past the margin');
    Assert.IsTrue(Shield.Holds(At(0, -6.5)), 'Over the top');
    Assert.IsFalse(Shield.Holds(At(0, 5.5)), 'Under the foot: the floor');
  finally
    Shield.Free;
  end;
end;

procedure TBodyShieldTests.TestAStripHoldsItsRow;
begin
  // Two cells at 0.6: about 7 units long, 4 high
  var Shield := TTekShield.CreateStrip(2, 0.6);
  try
    Shield.Rise;
    Assert.IsTrue(Shield.Holds(At(0, 0)), 'The middle');
    Assert.IsTrue(Shield.Holds(At(3.4, 0)), 'Near an end');
    Assert.IsFalse(Shield.Holds(At(4, 0)), 'Past an end');
    Assert.IsFalse(Shield.Holds(At(0, 2.5)), 'Under it');
  finally
    Shield.Free;
  end;
end;

function RamEvents(const AMembers: string): TArray<TLevelEvent>;
begin
  var Json := Format('{"events":[{"id":"ram","screen":1,"when":"enterScreen",' +
    '"then":[{"action":"ram"%s}]}]}', [AMembers]);
  var Root := TJSONObject.ParseJSONValue(Json) as TJSONObject;
  try
    Result := ParseLevelEvents(Root, 'test');
  finally
    Root.Free;
  end;
end;

// By value, not const: an anonymous method captures it
procedure ExpectRamRefused(AMembers: string; AWhy: string);
begin
  Assert.WillRaise(
    procedure
    begin
      RamEvents(AMembers);
    end, ELevelEventError, AWhy);
end;

procedure TRamLevelTests.TestRamIsRead;
begin
  var Action := RamEvents(',"stop":260,"file":"b.ogg","fadeOut":2.5')[0].
    Actions[0];
  Assert.AreEqual<TEventActionKind>(eaRam, Action.Kind, 'The action');
  Assert.AreEqual(260.0, Action.Ram.Stop, 0.001, 'Its stop');
  Assert.AreEqual('b.ogg', Action.Ram.Track, 'Its track');
  Assert.AreEqual(2.5, Action.Ram.SilenceSeconds, 0.001,
    'The fade-out to silence');
end;

procedure TRamLevelTests.TestBadRamRaises;
begin
  ExpectRamRefused(',"file":"b.ogg"', 'No stop');
  ExpectRamRefused(',"stop":-1,"file":"b.ogg"', 'A stop off the left edge');
  ExpectRamRefused(',"stop":512,"file":"b.ogg"', 'A stop off the right edge');
  ExpectRamRefused(',"stop":260', 'No track');
end;

// The arena of level 2 brings the Ram, its ram stopping at 260, clear of
// the pads on the right; the Ram starts the boss track, no event of the
// screen does
procedure TRamLevelTests.TestLevelTwoArenaBringsTheRam;
begin
  var Level := TLevel.Create;
  try
    Level.LoadFromFile(TPath.Combine(ExtractFilePath(ParamStr(0)),
      LevelTwoFile));
    var Rams := 0;
    for var Event in Level.Events do
      for var Action in Event.Actions do
      begin
        if Event.Screen <> LevelTwoArenaScreen then
          Continue;
        Assert.AreNotEqual<TEventActionKind>(eaMusic, Action.Kind,
          'No music action on the arena');
        if Action.Kind <> eaRam then
          Continue;
        Inc(Rams);
        Assert.AreEqual<TEventCondition>(ecEnterScreen, Event.Condition,
          'On arrival');
        Assert.AreEqual(260.0, Action.Ram.Stop, 0.001, 'Its stop');
        Assert.AreEqual('boss3.ogg', Action.Ram.Track, 'The boss track');
      end;
    Assert.AreEqual(1, Rams, 'One Ram');
  finally
    Level.Free;
  end;
end;

// ---------------------------------------------------------------------------
// The hunter
// ---------------------------------------------------------------------------

const
  // The middle city pad of the arena: its deck, and a hero standing on it
  MiddleDeckY = 160.0;
  MiddleHeroX = 220.0;
  // The long pad right of the gate, over the right part of the floor
  RightDeckY = 200.0;
  RightHeroX = 380.0;
  // A burst's shots stand at most this far apart
  BurstGapTicks = 6;
  // The shortest the lens burns, and the shortest rest after a burst
  ShortestFlareTicks = 14;
  ShortestRestTicks = 40;
  AimToleranceDegrees = 8.0;

function HeroOnAPad(AX, ADeckY: Single): TRamTarget;
begin
  Result := Default(TRamTarget);
  Result.Alive := True;
  Result.OnDeck := True;
  Result.Body := Box(AX, ADeckY - HeroSide, 16, HeroSide);
end;

function HeroOnTheRoad(AX: Single): TRamTarget;
begin
  Result := Default(TRamTarget);
  Result.Alive := True;
  Result.Body := OnTheRoad(AX);
end;

function CenterOf(const ATarget: TRamTarget): TSdlFPoint;
begin
  Result := At(ATarget.Body.X + ATarget.Body.W / 2,
    ATarget.Body.Y + ATarget.Body.H / 2);
end;

// Degrees counter-clockwise from the right, from AFrom toward ATo
function BearingOf(const AFrom, ATo: TSdlFPoint): Single;
begin
  Result := RadToDeg(ArcTan2(AFrom.Y - ATo.Y, ATo.X - AFrom.X));
end;

function AngleGap(A, B: Single): Single;
begin
  Result := Abs(A - B);
  while Result > 180 do
    Result := Abs(Result - 360);
end;

procedure TRamHunterTests.Setup;
begin
  FRam := TRam.Create(SolidBody(Round(RamWidth), Round(RamHeight)), Seed);
end;

procedure TRamHunterTests.TearDown;
begin
  FRam.Free;
end;

// From the stop after a death, watching ATarget, until the head locks
procedure TRamHunterTests.LockWith(const ATarget: TRamTarget;
  ALivesShare: Single);
begin
  FRam.Start(Orders, ALivesShare);
  FRam.Clear;
  FRam.Start(Orders, ALivesShare);
  for var i := 1 to ManyTicks do
    if FRam.Tick(ATarget).Locked then
      Exit;
  Assert.Fail('The head never locked');
end;

// Straight through the lens, left to right
procedure TRamHunterTests.StrikeTheEye(ATimes: Integer);
begin
  for var i := 1 to ATimes do
  begin
    var Lens := FRam.LensPoint;
    var Struck: TSdlFPoint;
    Assert.IsTrue(FRam.StrikeEye(At(Lens.X - 20, Lens.Y), At(Lens.X + 20, Lens.Y),
      Struck), Format('Strike %d meets the eye', [i]));
  end;
end;

// The ticks of ATicks on which the hunter fired, ATarget watched
function TRamHunterTests.ShotTicks(const ATarget: TRamTarget;
  ATicks: Integer): TArray<Integer>;
begin
  Result := [];
  for var i := 1 to ATicks do
    if FRam.Tick(ATarget).Shot then
      Result := Result + [i];
end;

procedure TRamHunterTests.TestLivesFollowTheGrade;
begin
  FRam.Start(Orders);
  Assert.AreEqual(HunterLives, FRam.FullLives, 'The first grade');
  FRam.Reset;
  FRam.Start(Orders, 1.5);
  Assert.AreEqual(150, FRam.FullLives, 'Half as many again');
  Assert.AreEqual(FRam.FullLives, FRam.Lives, 'All of them to start with');
end;

procedure TRamHunterTests.TestOnlyTheEyeTakesAHit;
begin
  LockWith(HeroOnAPad(MiddleHeroX, MiddleDeckY));
  var Lens := FRam.LensPoint;
  var Struck: TSdlFPoint;
  Assert.IsFalse(FRam.StrikeEye(At(Lens.X - 12, Lens.Y - 15),
    At(Lens.X - 12, Lens.Y + 15), Struck), 'Through the head beside the eye');
  Assert.IsFalse(FRam.StrikeEye(At(Lens.X - 20, Lens.Y + 30),
    At(Lens.X + 20, Lens.Y + 30), Struck), 'Through the mast under the head');
  Assert.AreEqual(FRam.FullLives, FRam.Lives, 'Nothing lost yet');
  Assert.IsTrue(FRam.StrikeEye(At(Lens.X - 20, Lens.Y), At(Lens.X + 20, Lens.Y),
    Struck), 'Through the eye');
  Assert.IsTrue(Struck.X < Lens.X, 'Met on its near side');
  Assert.AreEqual(FRam.FullLives - 1, FRam.Lives, 'A life gone');
end;

procedure TRamHunterTests.TestTheLastLifeBlowsTheHeadUp;
const
  LivesShare = 0.02;
begin
  var Hero := HeroOnAPad(MiddleHeroX, MiddleDeckY);
  LockWith(Hero, LivesShare);
  StrikeTheEye(FRam.Lives);
  var Cue := FRam.Tick(Hero);
  Assert.IsTrue(Cue.Blast, 'The head blows up');
  Assert.IsFalse(Cue.Shock, 'With no shock wave: only the sweeper sends one');
  Assert.IsTrue(FRam.Head = rhNone, 'Gone off the mast');
  var Struck: TSdlFPoint;
  Assert.IsFalse(FRam.StrikeEye(At(Cue.BlastAt.X - 20, Cue.BlastAt.Y),
    At(Cue.BlastAt.X + 20, Cue.BlastAt.Y), Struck), 'No eye left to hit');

  var Brightest: Single := 0;
  var Rose := False;
  for var i := 1 to ManyTicks do
  begin
    Cue := FRam.Tick(Hero);
    Brightest := Max(Brightest, FRam.Eye);
    Assert.IsFalse(Cue.Shot, 'Nothing fires through the change');
    if Cue.Whine then
    begin
      Rose := True;
      Break;
    end;
  end;
  Assert.IsTrue(Rose, 'The next head comes up');
  Assert.IsTrue(FRam.Head = rhSweeper, 'The sweeper');
  Assert.IsTrue(Brightest >= 0.9, 'The eye blinks through the change');
end;

procedure TRamHunterTests.TestHeroLowIsPressedToHisWall;
begin
  var Hero := HeroOnTheRoad(20);
  LockWith(Hero);
  Assert.IsTrue(FRam.Pressing, 'A hero on the road is pressed');
  for var i := 1 to ManyTicks do
    if FRam.Tick(Hero).Hiss then
      Break;
  Assert.AreEqual(0.0, FRam.Left, 0.001, 'All the way to the wall on his side');
end;

procedure TRamHunterTests.TestHeroOnAPadIsNotPressed;
const
  Watched = 300;
begin
  var Hero := HeroOnAPad(16, 280);
  LockWith(Hero);
  for var i := 1 to Watched do
  begin
    FRam.Tick(Hero);
    Assert.IsFalse(FRam.Pressing, Format('Not pressed on a low pad, tick %d', [i]));
  end;
end;

procedure TRamHunterTests.TestAPressHoldsTheFire;
const
  Watched = 300;
begin
  LockWith(HeroOnTheRoad(20));
  Assert.AreEqual(0, Length(ShotTicks(HeroOnTheRoad(20), Watched)),
    'No shot while it presses');
end;

procedure TRamHunterTests.TestTheLensBurnsBeforeABurst;
begin
  var Hero := HeroOnAPad(MiddleHeroX, MiddleDeckY);
  LockWith(Hero);
  var Burning := 0;
  for var i := 1 to ManyTicks do
  begin
    var Cue := FRam.Tick(Hero);
    if Cue.Shot then
      Break;
    if FRam.LensHot then
      Inc(Burning)
    else
      Burning := 0;
  end;
  Assert.IsTrue(Burning >= ShortestFlareTicks - 1,
    Format('The lens burned red %d ticks before the first shot', [Burning]));
end;

procedure TRamHunterTests.TestBurstsAreSeparatedByARest;
const
  Watched = 600;
begin
  var Hero := HeroOnAPad(MiddleHeroX, MiddleDeckY);
  LockWith(Hero);
  var Shots := ShotTicks(Hero, Watched);
  var Bursts := 0;
  for var i := 0 to High(Shots) do
  begin
    if (i > 0) and (Shots[i] - Shots[i - 1] <= BurstGapTicks) then
      Continue;
    Inc(Bursts);
    if i > 0 then
      Assert.IsTrue(Shots[i] - Shots[i - 1] >= ShortestRestTicks,
        Format('A rest of %d ticks before burst %d', [Shots[i] - Shots[i - 1],
        Bursts]));
  end;
  Assert.IsTrue(Bursts >= 3, Format('It keeps firing: %d bursts', [Bursts]));
end;

procedure TRamHunterTests.TestTheFirstShotsFlyAtTheHero;
begin
  var Hero := HeroOnAPad(MiddleHeroX, MiddleDeckY);
  LockWith(Hero);
  for var i := 1 to ManyTicks do
  begin
    var Cue := FRam.Tick(Hero);
    if not Cue.Shot then
      Continue;
    var Toward := BearingOf(Cue.ShotFrom, CenterOf(Hero));
    Assert.IsTrue(AngleGap(Toward, Cue.ShotAngle) <= AimToleranceDegrees,
      Format('Fired along %d, the hero lies along %g', [Cue.ShotAngle, Toward]));
    Exit;
  end;
  Assert.Fail('Never fired');
end;

procedure TRamHunterTests.TestHeadTurnsToAHeroPastTheVertical;
begin
  var Hero := HeroOnAPad(RightHeroX, RightDeckY);
  LockWith(Hero);
  Assert.AreEqual(-1, FRam.Facing, 'Locks facing left');
  for var i := 1 to ManyTicks do
  begin
    FRam.Tick(Hero);
    if FRam.Facing > 0 then
      Exit;
  end;
  Assert.Fail('Never turned to the hero on its right');
end;

procedure TRamHunterTests.TestTheLastThirdFiresAHose;
const
  Watched = 600;
  HoseShots = 6;
begin
  var Hero := HeroOnAPad(MiddleHeroX, MiddleDeckY);
  LockWith(Hero);
  StrikeTheEye(FRam.FullLives - FRam.FullLives div 3);
  Assert.IsTrue(FRam.Wounded, 'At the last third');
  var Shots := ShotTicks(Hero, Watched);
  var Longest := 0;
  var Run := 0;
  for var i := 0 to High(Shots) do
  begin
    if (i > 0) and (Shots[i] - Shots[i - 1] <= BurstGapTicks) then
      Inc(Run)
    else
      Run := 1;
    Longest := Max(Longest, Run);
  end;
  Assert.AreEqual(HoseShots, Longest, 'A burst of six');
end;

procedure TRamHunterTests.TestNoRowBeforeTheLock;
begin
  var Hero := HeroOnAPad(MiddleHeroX, MiddleDeckY);
  FRam.Start(Orders);
  FRam.Clear;
  FRam.Start(Orders);
  for var i := 1 to ManyTicks do
  begin
    Assert.IsFalse(FRam.Row.Shown, Format('No row before the lock, tick %d', [i]));
    if FRam.Tick(Hero).Locked then
      Exit;
  end;
end;

procedure TRamHunterTests.TestTheRowComesUpAfterTheLock;
const
  // Under a second and a half: the row is up before the first burst
  Watched = 50;
begin
  var Hero := HeroOnAPad(MiddleHeroX, MiddleDeckY);
  LockWith(Hero);
  Assert.IsTrue(FRam.Row.Shown, 'The row shows with the lock');
  Assert.AreEqual(0, FRam.Row.Lit, 'Not a cell lit yet');
  var Cells := 0;
  for var i := 1 to Watched do
  begin
    if FRam.Row.Lit < HeadRowCells then
      Assert.IsTrue(FRam.Lens >= 1, 'The eye burns white while the row comes up');
    var Cue := FRam.Tick(Hero);
    if Cue.RowCell then
      Inc(Cells);
    Assert.IsFalse(Cue.Shot and (FRam.Row.Lit < HeadRowCells),
      'No shot before the row is up');
  end;
  Assert.AreEqual(HeadRowCells, Cells, 'A cue for every cell');
  Assert.AreEqual(HeadRowCells, FRam.Row.Lit, 'The row is up');
  Assert.AreEqual(1.0, FRam.Row.Share, 0.001, 'Full');
end;

procedure TRamHunterTests.TestTheRowFollowsTheLives;
begin
  LockWith(HeroOnAPad(MiddleHeroX, MiddleDeckY));
  StrikeTheEye(FRam.FullLives div 2);
  Assert.AreEqual(0.5, FRam.Row.Share, 0.01, 'Half the lives, half the row');
  Assert.AreEqual(0, FRam.Row.HitTicks, 'Struck this moment');
end;

procedure TRamHunterTests.TestADeadHeadsRowFades;
const
  LivesShare = 0.02;
  Faded = 25;
begin
  var Hero := HeroOnAPad(MiddleHeroX, MiddleDeckY);
  LockWith(Hero, LivesShare);
  StrikeTheEye(FRam.Lives);
  FRam.Tick(Hero);
  Assert.IsTrue(FRam.Row.Shown, 'The dead head''s row still shows');
  Assert.AreEqual(0.0, FRam.Row.Share, 0.001, 'Empty');
  Assert.IsTrue(FRam.Row.Fade < 1, 'And fades');
  for var i := 1 to Faded do
    FRam.Tick(Hero);
  Assert.IsFalse(FRam.Row.Shown, 'Gone');
end;

procedure TRamHunterTests.TestShortsOutFromHalfItsLives;
begin
  var Hero := HeroOnAPad(MiddleHeroX, MiddleDeckY);
  LockWith(Hero);
  Assert.AreEqual(0.0, FRam.ShortLevel, 0.001, 'Whole: no bolts');
  StrikeTheEye(FRam.FullLives div 2 - 1);
  Assert.AreEqual(0.0, FRam.ShortLevel, 0.001, 'Over half: none yet');
  StrikeTheEye(1);
  var AtHalf := FRam.ShortLevel;
  Assert.IsTrue(AtHalf > 0, 'Half its lives: it shorts out');
  StrikeTheEye(FRam.Lives - 1);
  Assert.IsTrue(FRam.ShortLevel > AtHalf, 'Its last life: harder');
  StrikeTheEye(1);
  FRam.Tick(Hero);
  Assert.AreEqual(0.0, FRam.ShortLevel, 0.001, 'Blown up: nothing to short');
end;

// ---------------------------------------------------------------------------
// The sweeper
// ---------------------------------------------------------------------------

const
  // The high pad left of the gate, its deck, and a hero standing on it
  LeftDeckY = 188.0;
  LeftHeroX = 80.0;
  // A burst's shots stand this far apart at most
  SweepGapTicks = 5;
  // The row, the four barrels about it and the sway: this near the hero
  RowTolerance = 12.0;
  // The fork's second sweep comes sooner than a rest, a cell away
  ForkWithinTicks = 45;
  ForkCell = 32.0;
  ForkTolerance = 8.0;
  // A ladder rides this far at least through its sweep
  LadderClimb = 20.0;
  ShortestHeatTicks = 15;
  // The sweeper's end - a stand, the drive to the right wall from as far
  // as the left one, the overload of about 0.6 s: the blast within this
  // many ticks
  EndLimit = 300;
  // The stand before it backs off
  ShortestStandTicks = 10;
  // The wave crosses the screen in about a second
  ShortestWaveTicks = 25;
  LongestWaveTicks = 40;
  ShortestOverloadTicks = 15;
  HunterBlastJolt = 0.5;

procedure TRamSweeperTests.Setup;
begin
  FRam := TRam.Create(SolidBody(Round(RamWidth), Round(RamHeight)), Seed);
end;

procedure TRamSweeperTests.TearDown;
begin
  FRam.Free;
end;

// From the stop after a death the hunter locks; its eye shot out, the
// sweeper rises and locks with its row coming up
procedure TRamSweeperTests.ArmTheSweeper(const ATarget: TRamTarget;
  ALivesShare: Single);
begin
  FRam.Start(Orders, ALivesShare);
  FRam.Clear;
  FRam.Start(Orders, ALivesShare);
  var Locked := False;
  for var i := 1 to ManyTicks do
    if FRam.Tick(ATarget).Locked then
    begin
      Locked := True;
      Break;
    end;
  Assert.IsTrue(Locked, 'The hunter locks');
  for var i := 1 to FRam.Lives do
  begin
    var Lens := FRam.LensPoint;
    var Struck: TSdlFPoint;
    FRam.StrikeEye(At(Lens.X - 20, Lens.Y), At(Lens.X + 20, Lens.Y), Struck);
  end;
  for var i := 1 to ManyTicks do
  begin
    FRam.Tick(ATarget);
    if (FRam.Head = rhSweeper) and FRam.Row.Shown then
      Exit;
  end;
  Assert.Fail('The sweeper never locked');
end;

// Level, left to right through the middle of the pack
procedure TRamSweeperTests.StrikeThePack(ATimes: Integer);
begin
  for var i := 1 to ATimes do
  begin
    var Pack := FRam.BarrelsPoint;
    var Struck: TSdlFPoint;
    var Guarded: Boolean;
    Assert.IsTrue(FRam.StrikeBarrels(At(Pack.X - 30, Pack.Y), At(Pack.X + 30, Pack.Y),
      Struck, Guarded) and not Guarded, Format('Strike %d meets the pack', [i]));
  end;
end;

function TRamSweeperTests.Shots(const ATarget: TRamTarget;
  ATicks: Integer): TArray<TFired>;
begin
  Result := [];
  for var i := 1 to ATicks do
  begin
    var Fired: TFired;
    Fired.Cue := FRam.Tick(ATarget);
    Fired.Tick := i;
    if Fired.Cue.Shot then
      Result := Result + [Fired];
  end;
end;

// The shots gathered into sweeps: their first and last tick, the rows
// they flew along
function TRamSweeperTests.Bursts(const AShots: TArray<TFired>): TArray<TBurstRow>;
begin
  Result := [];
  for var i := 0 to High(AShots) do
  begin
    var Y := AShots[i].Cue.ShotFrom.Y;
    if (i = 0) or (AShots[i].Tick - AShots[i - 1].Tick > SweepGapTicks) then
    begin
      var Burst: TBurstRow;
      Burst.FirstTick := AShots[i].Tick;
      Burst.LowestY := Y;
      Burst.HighestY := Y;
      Result := Result + [Burst];
    end;
    var Last := High(Result);
    Result[Last].LastTick := AShots[i].Tick;
    Result[Last].LowestY := Max(Result[Last].LowestY, Y);
    Result[Last].HighestY := Min(Result[Last].HighestY, Y);
  end;
end;

// The tick of ALimit on which the head blew up, ATarget watched; -1 when
// it did not
function TRamSweeperTests.BlastWithin(const ATarget: TRamTarget;
  ALimit: Integer): Integer;
begin
  for var i := 1 to ALimit do
    if FRam.Tick(ATarget).Blast then
      Exit(i);
  Result := -1;
end;

// Its last life gone and the overload over: the tick of the blast is
// behind
procedure TRamSweeperTests.BlowTheSweeper(const ATarget: TRamTarget);
const
  LivesShare = 0.02;
begin
  ArmTheSweeper(ATarget, LivesShare);
  StrikeThePack(FRam.Lives);
  Assert.IsTrue(BlastWithin(ATarget, EndLimit) > 0, 'The head blows up');
end;

// A hero's body of the usual size, its middle at AX, AY
function BodyAround(AX, AY: Single): TSdlFRect;
begin
  Result := Box(AX - 8, AY - HeroSide / 2, 16, HeroSide);
end;

function MiddleOf(const ABurst: TRamSweeperTests.TBurstRow): Single;
begin
  Result := (ABurst.LowestY + ABurst.HighestY) / 2;
end;

procedure TRamSweeperTests.TestLivesFollowTheGrade;
begin
  ArmTheSweeper(HeroOnAPad(LeftHeroX, LeftDeckY), 1.5);
  Assert.AreEqual(210, FRam.FullLives, 'Half as many again');
  Assert.AreEqual(FRam.FullLives, FRam.Lives, 'All of them to start with');
end;

procedure TRamSweeperTests.TestRidesToTheHerosRow;
const
  Watched = 100;
begin
  var Hero := HeroOnAPad(MiddleHeroX, MiddleDeckY);
  ArmTheSweeper(Hero);
  for var i := 1 to Watched do
    FRam.Tick(Hero);
  Assert.AreEqual(CenterOf(Hero).Y, FRam.BarrelsPoint.Y, RowTolerance,
    'The barrels stand on his row');
end;

procedure TRamSweeperTests.TestHeroLowClosesTheCeiling;
const
  Watched = 150;
begin
  var Hero := HeroOnTheRoad(20);
  ArmTheSweeper(Hero);
  for var i := 1 to Watched do
    FRam.Tick(Hero);
  Assert.IsTrue(FRam.Pressing, 'The ram presses him');
  var Pack := FRam.BarrelsPoint;
  Assert.IsTrue(Pack.Y < RamTop, 'Never under its roof');
  Assert.IsTrue(Pack.Y > RamTop - RowTolerance - 6,
    Format('At the bottom of its mast, over his jump: %g', [Pack.Y]));
end;

procedure TRamSweeperTests.TestTheBarrelsBurnBeforeASweep;
begin
  var Hero := HeroOnAPad(LeftHeroX, LeftDeckY);
  ArmTheSweeper(Hero);
  var Burning := 0;
  for var i := 1 to ManyTicks do
  begin
    if FRam.Tick(Hero).Shot then
      Break;
    if FRam.HeatAt(1) > 0 then
      Inc(Burning)
    else
      Burning := 0;
  end;
  Assert.IsTrue(Burning >= ShortestHeatTicks,
    Format('The barrels burned %d ticks before the first shot', [Burning]));
end;

procedure TRamSweeperTests.TestASweepIsLevelAlongHisRow;
const
  Watched = 300;
begin
  var Hero := HeroOnAPad(LeftHeroX, LeftDeckY);
  ArmTheSweeper(Hero);
  var Fired := Shots(Hero, Watched);
  Assert.IsTrue(Length(Fired) > 0, 'It sweeps');
  var First := Fired[0].Cue;
  var Toward := 0;
  if CenterOf(Hero).X < First.ShotFrom.X then
    Toward := 180;
  Assert.AreEqual(Toward, First.ShotAngle, 'Toward him');
  for var Shot in Fired do
  begin
    Assert.IsTrue(Shot.Cue.ShotAngle mod 180 = 0, 'Level');
    Assert.AreEqual(SweeperBulletSpeed, Shot.Cue.ShotSpeed, 'The sweeper''s pace');
    Assert.AreEqual(CenterOf(Hero).Y, Shot.Cue.ShotFrom.Y, RowTolerance,
      'Along his row');
  end;
end;

procedure TRamSweeperTests.TestTheWholePackTakesAHit;
begin
  ArmTheSweeper(HeroOnAPad(LeftHeroX, LeftDeckY));
  var Pack := FRam.BarrelsPoint;
  var Struck: TSdlFPoint;
  var Guarded: Boolean;
  Assert.IsTrue(FRam.StrikeBarrels(At(Pack.X - 7, Pack.Y - 30),
    At(Pack.X - 7, Pack.Y), Struck, Guarded) and not Guarded,
    'From above, near the muzzles');
  Assert.IsTrue(FRam.StrikeBarrels(At(Pack.X - 30, Pack.Y + 3),
    At(Pack.X + 30, Pack.Y + 3), Struck, Guarded) and not Guarded, 'Level');
  Assert.AreEqual(FRam.FullLives - 2, FRam.Lives, 'Two lives gone');
  Assert.IsFalse(FRam.StrikeBarrels(At(Pack.X - 30, Pack.Y - 20),
    At(Pack.X + 30, Pack.Y - 20), Struck, Guarded), 'Over the pack');
end;

procedure TRamSweeperTests.TestThePlatesTakeABulletFromBelow;
begin
  ArmTheSweeper(HeroOnAPad(LeftHeroX, LeftDeckY));
  var Pack := FRam.BarrelsPoint;
  var Struck: TSdlFPoint;
  var Guarded: Boolean;
  Assert.IsTrue(FRam.StrikeBarrels(At(Pack.X, Pack.Y + 40), At(Pack.X, Pack.Y - 10),
    Struck, Guarded) and Guarded, 'Straight up: a plate');
  Assert.IsTrue(Struck.Y > Pack.Y, 'Met under the barrels');
  Assert.IsTrue(FRam.StrikeBarrels(At(Pack.X - 40, Pack.Y + 10), At(Pack.X, Pack.Y),
    Struck, Guarded) and Guarded, 'Climbing into the muzzles: a plate');
  Assert.AreEqual(FRam.FullLives, FRam.Lives, 'Nothing lost');
end;

procedure TRamSweeperTests.TestTheMiddleThirdForks;
const
  Watched = 400;
begin
  var Hero := HeroOnAPad(LeftHeroX, LeftDeckY);
  ArmTheSweeper(Hero);
  StrikeThePack(FRam.FullLives - 2 * FRam.FullLives div 3);
  var Sweeps := Bursts(Shots(Hero, Watched));
  for var i := 1 to High(Sweeps) do
  begin
    if Sweeps[i].FirstTick - Sweeps[i - 1].LastTick >= ForkWithinTicks then
      Continue;
    Assert.AreEqual(ForkCell, Abs(MiddleOf(Sweeps[i]) - MiddleOf(Sweeps[i - 1])),
      ForkTolerance, 'The second sweep a row away');
    Exit;
  end;
  Assert.Fail('No sweep followed another at once');
end;

procedure TRamSweeperTests.TestTheLastThirdClimbsALadder;
const
  Watched = 300;
begin
  var Hero := HeroOnAPad(MiddleHeroX, MiddleDeckY);
  ArmTheSweeper(Hero);
  StrikeThePack(FRam.FullLives - FRam.FullLives div 3);
  var Sweeps := Bursts(Shots(Hero, Watched));
  Assert.IsTrue(Length(Sweeps) > 0, 'It sweeps');
  Assert.IsTrue(Sweeps[0].LowestY - Sweeps[0].HighestY >= LadderClimb,
    Format('The row rode %g through the sweep',
    [Sweeps[0].LowestY - Sweeps[0].HighestY]));
end;

procedure TRamSweeperTests.TestTurnsToAHeroOnItsOtherSide;
begin
  var Hero := HeroOnAPad(RightHeroX, RightDeckY);
  ArmTheSweeper(Hero);
  for var i := 1 to ManyTicks do
  begin
    FRam.Tick(Hero);
    if FRam.Facing > 0 then
      Exit;
  end;
  Assert.Fail('Never turned to the hero on its right');
end;

procedure TRamSweeperTests.TestTheLastLifeLeavesTheMastEmpty;
const
  LivesShare = 0.02;
begin
  var Hero := HeroOnAPad(LeftHeroX, LeftDeckY);
  ArmTheSweeper(Hero, LivesShare);
  StrikeThePack(FRam.Lives);
  Assert.IsTrue(BlastWithin(Hero, EndLimit) > 0, 'The head blows up');
  for var i := 1 to ManyTicks do
  begin
    var Cue := FRam.Tick(Hero);
    Assert.IsFalse(Cue.Whine or Cue.Shot, 'No head comes up, nothing fires');
    Assert.AreEqual(0.0, Double(FRam.Rolled), 0.001, 'It stands');
  end;
  Assert.IsTrue(FRam.Head = rhNone, 'The mast stays empty');
  Assert.IsTrue(FRam.Mast < 0, 'Down in the well');
  Assert.AreEqual(Double(ScreenWidth - RamWidth), Double(FRam.Left), 0.001,
    'At the right wall, where the chase begins');
end;

procedure TRamSweeperTests.TestShortsOutFromHalfItsLives;
begin
  ArmTheSweeper(HeroOnAPad(LeftHeroX, LeftDeckY));
  Assert.AreEqual(0.0, FRam.ShortLevel, 0.001, 'Whole: no bolts');
  StrikeThePack(FRam.FullLives div 2 - 1);
  Assert.AreEqual(0.0, FRam.ShortLevel, 0.001, 'Over half: none yet');
  StrikeThePack(1);
  var AtHalf := FRam.ShortLevel;
  Assert.IsTrue(AtHalf > 0, 'Half its lives: it shorts out');
  StrikeThePack(FRam.Lives - 1);
  Assert.IsTrue(FRam.ShortLevel > AtHalf, 'Its last life: harder');
end;

procedure TRamSweeperTests.TestTheLastLifeOverloadsBeforeTheBlast;
const
  LivesShare = 0.02;
begin
  var Hero := HeroOnAPad(LeftHeroX, LeftDeckY);
  ArmTheSweeper(Hero, LivesShare);
  StrikeThePack(FRam.Lives);
  var Overloaded := 0;
  var Brightest: Single := 0;
  var Last: Single := 0;
  for var i := 1 to EndLimit do
  begin
    var Cue := FRam.Tick(Hero);
    if FRam.Retreating then
    begin
      Assert.IsFalse(Cue.Shot, 'No fire as it backs off');
      Assert.IsFalse(FRam.Overloading, 'No overload before the wall');
      Continue;
    end;
    if Cue.Blast then
    begin
      Assert.IsTrue(Overloaded >= ShortestOverloadTicks,
        Format('An overload of %d ticks before the blast', [Overloaded]));
      Assert.IsTrue(Cue.Shock, 'A shock wave goes out');
      Assert.IsTrue(Cue.Jolt > HunterBlastJolt, 'Heavier than the hunter''s');
      Assert.AreEqual(1.0, FRam.FlashAt(1), 0.001, 'The white of the blast');
      Assert.IsTrue(Brightest >= 0.9, 'The eye blinked through it');
      Assert.IsFalse(FRam.Overloading, 'Over');
      Exit;
    end;
    Assert.IsFalse(Cue.Shot, 'No fire through the overload');
    Assert.IsTrue(FRam.Overloading, Format('Overloading, tick %d', [i]));
    Assert.IsTrue(FRam.Overload > Last, 'Heating up');
    Last := FRam.Overload;
    Brightest := Max(Brightest, FRam.Eye);
    Inc(Overloaded);
  end;
  Assert.Fail('Never burst');
end;

procedure TRamSweeperTests.TestTheBlastSendsAWave;
begin
  var Hero := HeroOnAPad(LeftHeroX, LeftDeckY);
  BlowTheSweeper(Hero);
  Assert.IsTrue(FRam.WaveFrontAt(1) > 0, 'The wave leaves the blast');
  var Farthest := Max(Hypot(FRam.BlastAt.X, FRam.BlastAt.Y),
    Hypot(ScreenWidth - FRam.BlastAt.X, FRam.BlastAt.Y));
  Assert.IsTrue(FRam.WaveReach >= Farthest, 'It runs past every corner');
  var Last := FRam.WaveFrontAt(1);
  var Ran := 1;
  while FRam.WaveFrontAt(1) >= 0 do
  begin
    FRam.Tick(Hero);
    if FRam.WaveFrontAt(1) < 0 then
      Break;
    Assert.IsTrue(FRam.WaveFrontAt(1) > Last, 'Running out');
    Last := FRam.WaveFrontAt(1);
    Inc(Ran);
    Assert.IsTrue(Ran <= LongestWaveTicks, 'Gone in about a second');
  end;
  Assert.IsTrue(Ran >= ShortestWaveTicks, Format('Ran %d ticks', [Ran]));

  BlowTheSweeper(Hero);
  FRam.Clear;
  Assert.IsTrue(FRam.WaveFrontAt(1) < 0, 'A death takes it away');
end;

procedure TRamSweeperTests.TestTheWaveThrowsTheHeroOnceAwayFromTheHull;
begin
  var Hero := HeroOnAPad(LeftHeroX, LeftDeckY);
  BlowTheSweeper(Hero);
  // Away from the hull when he is clear of it; over it, toward more road
  var Middle := CenterOf(Hero).X;
  var Expected := 1;
  if Middle < FRam.Left then
    Expected := -1
  else if (Middle <= FRam.Left + RamWidth) and
    (FRam.Left > ScreenWidth - (FRam.Left + RamWidth)) then
    Expected := -1;
  var Away: Integer;
  for var i := 1 to LongestWaveTicks do
  begin
    if FRam.WaveStrikes(Hero.Body, Away) then
    begin
      Assert.AreEqual(Expected, Away, 'Away from the hull');
      Assert.IsFalse(FRam.WaveStrikes(Hero.Body, Away), 'Once a wave');
      Exit;
    end;
    FRam.Tick(Hero);
  end;
  Assert.Fail('The wave never reached him');
end;

procedure TRamSweeperTests.TestTheWaveThrowsFromOverTheHullTowardMoreRoad;
begin
  var Hero := HeroOnAPad(MiddleHeroX, MiddleDeckY);
  BlowTheSweeper(Hero);
  var OverIt := BodyAround(FRam.Left + RamWidth / 2, RamTop - HeroSide);
  var Expected := 1;
  if FRam.Left > ScreenWidth - (FRam.Left + RamWidth) then
    Expected := -1;
  var Away: Integer;
  for var i := 1 to LongestWaveTicks do
  begin
    if FRam.WaveStrikes(OverIt, Away) then
    begin
      Assert.AreEqual(Expected, Away, 'Toward the side with more road');
      Exit;
    end;
    FRam.Tick(Hero);
  end;
  Assert.Fail('The wave never reached him');
end;

procedure TRamSweeperTests.TestTheWaveReachesTheNearFirst;
const
  Near = 20.0;
begin
  var Hero := HeroOnAPad(LeftHeroX, LeftDeckY);
  BlowTheSweeper(Hero);
  var Blast := FRam.BlastAt;
  var NearPoint := At(Blast.X, Blast.Y - Near);
  var FarPoint := At(Blast.X, Blast.Y - FRam.WaveReach + 1);
  var NearTick := -1;
  var FarTick := -1;
  for var i := 0 to LongestWaveTicks do
  begin
    if (NearTick < 0) and FRam.WaveReaches(NearPoint) then
      NearTick := i;
    if (FarTick < 0) and FRam.WaveReaches(FarPoint) then
      FarTick := i;
    FRam.Tick(Hero);
  end;
  Assert.IsTrue(NearTick >= 0, 'The near point is reached');
  Assert.IsTrue(FarTick > NearTick, 'The far one later');
  FRam.Clear;
  Assert.IsFalse(FRam.WaveReaches(NearPoint), 'No wave, nothing reached');
end;

procedure TRamSweeperTests.TestBacksToTheRightWallBeforeTheOverload;
const
  LivesShare = 0.02;
begin
  var Hero := HeroOnTheRoad(20);
  ArmTheSweeper(Hero, LivesShare);
  // Pressing him: under way to his wall, the left, when the last life goes
  var UnderWay := False;
  for var i := 1 to ManyTicks do
  begin
    FRam.Tick(Hero);
    UnderWay := (FRam.Phase = rpDriving) and (FRam.Rolled < -1);
    if UnderWay then
      Break;
  end;
  Assert.IsTrue(UnderWay, 'It drives at him');
  StrikeThePack(FRam.Lives);
  var Wall: Double := ScreenWidth - RamWidth;
  var Alarmed := False;
  var Stood := 0;
  var Backing := False;
  var Reddest: Single := 0;
  for var i := 1 to EndLimit do
  begin
    var Cue := FRam.Tick(Hero);
    Assert.IsFalse(Cue.Shot, 'No fire');
    Alarmed := Alarmed or Cue.Alarm;
    if FRam.Retreating then
    begin
      Assert.IsFalse(FRam.Overloading, 'No overload on the way');
      Assert.IsFalse(FRam.Pressing, 'Nobody pressed');
      Reddest := Max(Reddest, FRam.HeatAt(1));
      if FRam.Rolled > 0 then
        Backing := True
      else if Backing then
        Assert.IsTrue(FRam.Rolled >= 0, 'Never forward once it backs')
      else if FRam.Rolled = 0 then
        Inc(Stood);
      Continue;
    end;
    Assert.AreEqual(Wall, Double(FRam.Left), 0.001, 'Overloads at the wall');
    if Cue.Blast then
    begin
      Assert.IsTrue(Alarmed, 'The alarm sounded');
      Assert.IsTrue(Stood >= ShortestStandTicks,
        Format('Stood %d ticks before it backed', [Stood]));
      Assert.IsTrue(Backing, 'It backed off to the right');
      Assert.IsTrue(Reddest >= 0.9, 'Its barrels burned red');
      Assert.AreEqual(0.0, Double(FRam.Rolled), 0.001, 'Standing');
      Exit;
    end;
    Assert.IsFalse(Cue.Rumble, 'No new drive through the overload');
  end;
  Assert.Fail('Never burst');
end;

procedure TRamSweeperTests.TestTheWaveLeavesHimInFrontTillHeIsClear;
begin
  var Hero := HeroOnAPad(LeftHeroX, LeftDeckY);
  BlowTheSweeper(Hero);
  var InFront := OnTheRoad(FRam.Left + RamWidth / 2);
  var Away: Integer;
  var Struck := False;
  for var i := 1 to LongestWaveTicks do
  begin
    Struck := FRam.WaveStrikes(InFront, Away);
    if Struck then
      Break;
    FRam.Tick(Hero);
  end;
  Assert.IsTrue(Struck, 'The wave reaches him');
  Assert.AreEqual(-1, Away, 'Thrown left, the only road');
  Assert.IsFalse(FRam.Contact(InFront, False, False, Away),
    'Down inside the hull: still in front of it');
  Assert.IsFalse(FRam.Contact(OnTheRoad(FRam.Left - 40), False, False, Away),
    'Clear of it');
  Assert.IsTrue(FRam.Contact(InFront, False, False, Away),
    'Back into it: a touch as ever');
end;

initialization
  TDUnitX.RegisterTestFixture(TRamTests);
  TDUnitX.RegisterTestFixture(TRamHunterTests);
  TDUnitX.RegisterTestFixture(TRamSweeperTests);
  TDUnitX.RegisterTestFixture(TBodyShieldTests);
  TDUnitX.RegisterTestFixture(TRamLevelTests);

end.
