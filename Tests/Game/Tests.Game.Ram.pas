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
    procedure TestShieldTakesABullet;
    [Test]
    procedure TestAbsentMeetsNothing;
  end;

  [TestFixture]
  TBodyShieldTests = class
  public
    [Test]
    procedure TestHoldsTheBodyAndAMarginPastIt;
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
  Assert.IsTrue(FRam.Contact(Hero, False, False, Away),
    'Down in its way again');
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

initialization
  TDUnitX.RegisterTestFixture(TRamTests);
  TDUnitX.RegisterTestFixture(TBodyShieldTests);
  TDUnitX.RegisterTestFixture(TRamLevelTests);

end.
