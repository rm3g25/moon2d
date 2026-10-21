{
  Tests.Monsters.Bodies - what the floor does to a body, alive and dead:
  the walk along a ledge and between walls, the fall and the landing, and
  the corpse, which lies where it died and falls when nothing is under it.

  The bodies are gravels (a patrol walker that turns at the end of a
  ledge) and gravel females (a walker that does not look for one), in
  rooms of a few solid cells. A gravel carries no smoke and fans no
  fragments, so it can die into a nil burst; so can a barrel, whose blast
  is the game's to send out. A medkit is the pickup the hero takes: the one
  body that is dead with no dying. The sky barrel is weather: it bursts
  where it lands, and the pit takes it without a blast; the barrel of the
  levels lands and stands.

  A scene lays hands on a body too: it keeps it asleep, holds its fire,
  strikes it down, takes it away and stands it where it says. Holding the
  fire is seen through the nil burst: a shot into it stops the run with an
  access violation, so a betoner that fires is a raise, and one held is
  none. The deck a body stands on is a pad of no picture in the room.

  The moon stone is anchored: blows, throws and a deck flying up from
  under it leave it where it lies - set against a medkit, which a blow
  moves. And it is invulnerable: struck for all its lives, it lives.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Monsters.Bodies;

interface

uses
  DUnitX.TestFramework,
  Monsters,
  Tests.Rooms;

type
  [TestFixture]
  TMonsterBodyTests = class
  private
    FRoom: TRoom;
    procedure UseRoom(const ARows: array of string);
    function LayCorpse(ACol, ARow: Integer): TMonster;
    procedure TickBody(const ABody: TMonster; ATicks: Integer);
  public
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestLethalHitStartsDyingAndTellsTheGameOnce;
    [Test]
    procedure TestHitThatLeavesLivesKillsNobody;
    [Test]
    procedure TestDyingBodyBecomesACorpseThatLiesStill;
    [Test]
    procedure TestCorpseIsNotKilledAgain;
    [Test]
    procedure TestCorpseOnALedgeStaysOnIt;
    [Test]
    procedure TestCorpseKnockedOffALedgeFallsToTheFloor;
    [Test]
    procedure TestBodyKilledInTheAirLandsAndLiesStill;
    [Test]
    procedure TestPatrolTurnsBackAtTheEndOfALedge;
    [Test]
    procedure TestPatrolTurnsBackAtWalls;
    [Test]
    procedure TestWalkerWithNoEdgeCheckWalksOffALedge;
    [Test]
    procedure TestWalkerDroppedAboveALedgeLandsOnIt;
    [Test]
    procedure TestCollectedPickupIsGoneAtOnceAndTellsTheGameOnce;
    [Test]
    procedure TestCollectedPickupIsNotKilledByALaterBlow;
    [Test]
    procedure TestWeatherBurstsWhereItLands;
    [Test]
    procedure TestWeatherBurstsOnALedge;
    [Test]
    procedure TestWeatherThePitTakesIsGoneWithoutABlast;
    [Test]
    procedure TestWeatherBurstsOnce;
    [Test]
    procedure TestBarrelOfTheLevelsLandsAndStands;
    [Test]
    procedure TestDormantBodyStandsStillAndSleeps;
    [Test]
    procedure TestDormantBodyStillFalls;
    [Test]
    procedure TestHeldBodyWalksAndHoldsItsFire;
    [Test]
    procedure TestSmittenBodyDiesTellingOnlyItsDeath;
    [Test]
    procedure TestRemovedBodyIsGoneWithNoDeath;
    [Test]
    procedure TestStoodBodyIsPutAtRest;
    [Test]
    procedure TestBodyStoodOnADeckHasItUnderItsFeet;
    [Test]
    procedure TestAnchoredStoneIsMovedByNothing;
    [Test]
    procedure TestInvulnerableStoneOutlivesAnyBlow;
  end;

implementation

uses
  System.Math,
  System.SysUtils,
  Pads.World;

const
  // The feet of a body that stands on the floor row of a room
  FloorY: Integer = 352;
  // The top of the ledge room's ledge: the feet of a body standing on it
  LedgeTopY: Integer = 256;
  // A body takes about 120 ticks to fall the height of the screen
  FallTicks = 150;
  // A dying body is down in well under this
  DeathTicks = 100;
  // A blow of this size moves a body half of it
  Blow = 8;
  // Blows that carry a body from the right end of the ledge clear off it
  BlowsOffTheLedge = 10;
  // The margin of the art in the 32-unit sprite (the game's hit inset)
  ArtMargin = 8;
  ArtRightOffset = 24;
  // The probes of a walker let the art into a wall by a unit before they
  // turn it round
  WallSliver = 2;
  // Ticks enough for a walker to cross its room and come back
  PatrolTicks = 900;
  // A betoner fires every 51 ticks (monsters.json): 60 ticks hold one
  // shot, 300 hold five
  FiringTicks = 60;
  HeldTicks = 300;
  // Ticks a body that sleeps is watched for
  SleepTicks = 200;
  // A run of a deck at x = 224, its line at y = 224, in an open room
  DeckSections = '"pads":[{"sprite":"","screen":1,"x":224,"y":224,' +
    '"width":32,"tag":"deck"}]';
  DeckLeft = 224;
  DeckTop = 224;
  // A throw as a blast deals one, and the deck's flight up from under a
  // body
  ThrowWay = 40;
  DeckRise = 64;
  DeckRiseTicks = 10;

function PlaceX(const AMonster: TMonster): Integer;
begin
  Result := Round(AMonster.X);
end;

function PlaceY(const AMonster: TMonster): Integer;
begin
  Result := Round(AMonster.Y);
end;

function LeftArtEdge(const AMonster: TMonster): Integer;
begin
  Result := PlaceX(AMonster) + ArtMargin;
end;

function RightArtEdge(const AMonster: TMonster): Integer;
begin
  Result := PlaceX(AMonster) + ArtRightOffset;
end;

// The floor, the left wall column over it and the right one
function CorridorRows(ALeftWallCol, ARightWallCol: Integer): TArray<string>;
begin
  Result := RoomRowsOf(ALeftWallCol, 0, 0, 0);
  for var i := 0 to RoomRows - 2 do
    Result[i][ARightWallCol] := '#';
end;

procedure TMonsterBodyTests.TearDown;
begin
  FreeAndNil(FRoom);
end;

procedure TMonsterBodyTests.UseRoom(const ARows: array of string);
begin
  FreeAndNil(FRoom);
  FRoom := RoomFromRows(ARows);
end;

procedure TMonsterBodyTests.TickBody(const ABody: TMonster; ATicks: Integer);
begin
  for var i := 1 to ATicks do
    ABody.Tick(0, 0, nil);
end;

// A gravel on the cell, struck for all its lives and ticked until it lies
// dead
function TMonsterBodyTests.LayCorpse(ACol, ARow: Integer): TMonster;
begin
  Result := FRoom.Place('gravel', ACol, ARow);
  Result.TakeDamage(0, Result.Lives, nil);

  var Ticks := 0;
  while (Result.Life <> mlDead) and (Ticks < DeathTicks) do
  begin
    Result.Tick(0, 0, nil);
    Inc(Ticks);
  end;
  Assert.AreEqual<TMonsterLife>(mlDead, Result.Life, 'the body did not die');
end;

procedure TMonsterBodyTests.TestLethalHitStartsDyingAndTellsTheGameOnce;
begin
  UseRoom(RoomRowsOf(0, 0, 0, 0));
  var Body := FRoom.Place('gravel', 8, 11);

  Body.TakeDamage(0, Body.Lives, nil);

  Assert.AreEqual<TMonsterLife>(mlDying, Body.Life);
  Assert.AreEqual<TMonsterEvent>(meDied, Body.DrainEvent, 'the first event');
  Assert.AreEqual<TMonsterEvent>(meNone, Body.DrainEvent, 'the second event');
end;

procedure TMonsterBodyTests.TestHitThatLeavesLivesKillsNobody;
begin
  UseRoom(RoomRowsOf(0, 0, 0, 0));
  var Body := FRoom.Place('gravel', 8, 11);

  Body.TakeDamage(0, Body.Lives - 1, nil);

  Assert.AreEqual<TMonsterLife>(mlAlive, Body.Life);
  Assert.AreEqual<TMonsterEvent>(meNone, Body.DrainEvent);
end;

procedure TMonsterBodyTests.TestDyingBodyBecomesACorpseThatLiesStill;
begin
  UseRoom(RoomRowsOf(0, 0, 0, 0));
  var Body := LayCorpse(8, 11);
  var DeadX := PlaceX(Body);
  var DeadY := PlaceY(Body);

  TickBody(Body, FallTicks);

  Assert.AreEqual<TMonsterLife>(mlDead, Body.Life, 'the corpse stirred');
  Assert.AreEqual(DeadX, PlaceX(Body), 'the corpse walked on');
  Assert.AreEqual(DeadY, PlaceY(Body), 'the corpse sank or rose');
  Assert.AreEqual(FloorY, DeadY, 'the body did not die on the floor');
end;

procedure TMonsterBodyTests.TestCorpseIsNotKilledAgain;
begin
  UseRoom(RoomRowsOf(0, 0, 0, 0));
  var Body := LayCorpse(8, 11);
  Assert.AreEqual<TMonsterEvent>(meDied, Body.DrainEvent, 'the death');

  Body.TakeDamage(0, 1, nil);
  Body.TakeDamage(0, 1, nil);

  Assert.AreEqual<TMonsterLife>(mlDead, Body.Life);
  Assert.AreEqual<TMonsterEvent>(meNone, Body.DrainEvent,
    'a corpse died a second time');
end;

procedure TMonsterBodyTests.TestCorpseOnALedgeStaysOnIt;
begin
  // The ledge is row 9, columns 4 to 6: its top at y = 256
  UseRoom(RoomRowsOf(0, 9, 4, 6));
  var Body := LayCorpse(5, 8);
  Assert.AreEqual(LedgeTopY, PlaceY(Body), 'the corpse is not on the ledge');

  TickBody(Body, FallTicks);

  Assert.AreEqual(LedgeTopY, PlaceY(Body), 'the corpse fell through the ledge');
end;

procedure TMonsterBodyTests.TestCorpseKnockedOffALedgeFallsToTheFloor;
begin
  // The corpse lies on the right end of the ledge, which ends at x = 192
  UseRoom(RoomRowsOf(0, 9, 4, 6));
  var Body := LayCorpse(6, 8);
  Assert.AreEqual(LedgeTopY, PlaceY(Body), 'the corpse is not on the ledge');

  for var i := 1 to BlowsOffTheLedge do
    Body.TakeDamage(Blow, 0, nil);
  TickBody(Body, FallTicks);

  Assert.AreEqual(FloorY, PlaceY(Body), 'the corpse hangs in the air');
  Assert.AreEqual<TMonsterLife>(mlDead, Body.Life, 'the corpse came to life');
end;

procedure TMonsterBodyTests.TestBodyKilledInTheAirLandsAndLiesStill;
begin
  UseRoom(RoomRowsOf(0, 0, 0, 0));
  var Body := FRoom.Place('gravel', 9, 2);
  // The first tick finds nothing under the feet and starts the fall
  Body.Tick(0, 0, nil);
  var FallX := PlaceX(Body);

  Body.TakeDamage(0, Body.Lives, nil);
  TickBody(Body, FallTicks);

  Assert.AreEqual(FloorY, PlaceY(Body), 'the body hangs in the air');
  Assert.AreEqual<TMonsterLife>(mlDead, Body.Life, 'the body is not dead');
  Assert.AreEqual(FallX, PlaceX(Body), 'the body slid on the way down');
end;

procedure TMonsterBodyTests.TestPatrolTurnsBackAtTheEndOfALedge;
begin
  UseRoom(RoomRowsOf(0, 9, 4, 6));
  var Body := FRoom.Place('gravel', 5, 8);
  var StartX := PlaceX(Body);
  var MostLeft := StartX;
  var MostRight := StartX;

  for var i := 1 to PatrolTicks do
  begin
    Body.Tick(0, 0, nil);
    MostLeft := Min(MostLeft, PlaceX(Body));
    MostRight := Max(MostRight, PlaceX(Body));
    Assert.AreEqual(LedgeTopY, PlaceY(Body),
      Format('The body left the ledge at tick %d', [i]));
  end;

  Assert.IsTrue(MostLeft < StartX, 'the body never went left');
  Assert.IsTrue(MostRight > StartX, 'the body never came back to the right');
end;

procedure TMonsterBodyTests.TestPatrolTurnsBackAtWalls;
const
  // The walls are columns 5 and 12: the faces are at x = 160 and x = 352
  LeftFace = 160;
  RightFace = 352;
begin
  UseRoom(CorridorRows(5, 12));
  var Body := FRoom.Place('gravel', 8, 11);
  var StartLeft := LeftArtEdge(Body);
  var StartRight := RightArtEdge(Body);
  var MostLeft := StartLeft;
  var MostRight := StartRight;

  for var i := 1 to PatrolTicks do
  begin
    Body.Tick(0, 0, nil);
    MostLeft := Min(MostLeft, LeftArtEdge(Body));
    MostRight := Max(MostRight, RightArtEdge(Body));
  end;

  Assert.IsTrue(MostLeft >= LeftFace - WallSliver,
    Format('The art went to x = %d, into the left wall', [MostLeft]));
  Assert.IsTrue(MostRight <= RightFace + WallSliver,
    Format('The art went to x = %d, into the right wall', [MostRight]));
  Assert.IsTrue(MostLeft < StartLeft, 'the body never went left');
  Assert.IsTrue(MostRight > StartRight, 'the body never went right');
end;

procedure TMonsterBodyTests.TestWalkerWithNoEdgeCheckWalksOffALedge;
begin
  UseRoom(RoomRowsOf(0, 9, 4, 6));
  var Body := FRoom.Place('gravelFemale', 5, 8);
  Assert.AreEqual(LedgeTopY, PlaceY(Body), 'the body is not on the ledge');

  TickBody(Body, FallTicks * 2);

  Assert.AreEqual(FloorY, PlaceY(Body), 'the body stayed on the ledge');
end;

procedure TMonsterBodyTests.TestWalkerDroppedAboveALedgeLandsOnIt;
begin
  UseRoom(RoomRowsOf(0, 9, 4, 6));
  var Body := FRoom.Place('gravel', 5, 2);

  TickBody(Body, FallTicks);

  Assert.AreEqual(LedgeTopY, PlaceY(Body), 'the body did not land on the ledge');
end;

procedure TMonsterBodyTests.TestCollectedPickupIsGoneAtOnceAndTellsTheGameOnce;
begin
  UseRoom(RoomRowsOf(0, 0, 0, 0));
  var Body := FRoom.Place('medkit', 8, 11);
  Assert.AreEqual<TMonsterLife>(mlAlive, Body.Life, 'a medkit lies alive');

  Body.Collect;

  Assert.AreEqual<TMonsterLife>(mlDead, Body.Life,
    'a taken pickup is gone at once, with no dying');
  Assert.AreEqual<TMonsterEvent>(meDied, Body.DrainEvent, 'the first event');
  Assert.AreEqual<TMonsterEvent>(meNone, Body.DrainEvent, 'the second event');
end;

procedure TMonsterBodyTests.TestCollectedPickupIsNotKilledByALaterBlow;
begin
  UseRoom(RoomRowsOf(0, 0, 0, 0));
  var Body := FRoom.Place('medkit', 8, 11);
  Body.Collect;
  Assert.AreEqual<TMonsterEvent>(meDied, Body.DrainEvent, 'the taking');

  Body.TakeDamage(0, Body.Lives, nil);

  // A body found dying after a blow is one the game rewards as killed
  Assert.AreEqual<TMonsterLife>(mlDead, Body.Life,
    'a blow set a taken pickup dying');
  Assert.AreEqual<TMonsterEvent>(meNone, Body.DrainEvent,
    'a taken pickup died a second time');
end;

// The floor row of a room with a hole three cells wide, columns AFrom to
// AFrom + 2
function HoledRows(AFrom: Integer): TArray<string>;
begin
  Result := RoomRowsOf(0, 0, 0, 0);
  for var Col := AFrom to AFrom + 2 do
    Result[RoomRows - 1][Col] := '.';
end;

// Ticks the body until it is no longer alive, FallTicks at most
procedure TickWhileAlive(const ABody: TMonster);
begin
  var Ticks := 0;
  while (ABody.Life = mlAlive) and (Ticks < FallTicks) do
  begin
    ABody.Tick(0, 0, nil);
    Inc(Ticks);
  end;
end;

procedure TMonsterBodyTests.TestWeatherBurstsWhereItLands;
begin
  UseRoom(RoomRowsOf(0, 0, 0, 0));
  var Body := FRoom.Place('skyBarrel', 8, 2);

  TickWhileAlive(Body);

  Assert.AreEqual<TMonsterLife>(mlDying, Body.Life, 'It did not burst');
  Assert.AreEqual(FloorY, PlaceY(Body), 'It burst off the floor');
  Assert.AreEqual<TMonsterEvent>(meDied, Body.DrainEvent, 'the first event');
  Assert.AreEqual<TMonsterEvent>(meBurst, Body.DrainEvent,
    'the second: the game has its blast to send out');
  Assert.AreEqual<TMonsterEvent>(meNone, Body.DrainEvent, 'the third');
end;

procedure TMonsterBodyTests.TestWeatherBurstsOnALedge;
begin
  UseRoom(RoomRowsOf(0, 9, 4, 6));
  var Body := FRoom.Place('skyBarrel', 5, 2);

  TickWhileAlive(Body);

  Assert.AreEqual<TMonsterLife>(mlDying, Body.Life, 'It did not burst');
  Assert.AreEqual(LedgeTopY, PlaceY(Body), 'It did not burst on the ledge');
end;

procedure TMonsterBodyTests.TestWeatherThePitTakesIsGoneWithoutABlast;
begin
  UseRoom(HoledRows(7));
  var Body := FRoom.Place('skyBarrel', 8, 2);

  TickBody(Body, FallTicks * 2);

  Assert.AreEqual<TMonsterLife>(mlDead, Body.Life, 'The pit did not take it');
  Assert.AreEqual<TMonsterEvent>(meNone, Body.DrainEvent,
    'It died or burst in the pit');
  var GoneY := PlaceY(Body);
  TickBody(Body, FallTicks);
  Assert.AreEqual(GoneY, PlaceY(Body), 'It is still falling');
end;

procedure TMonsterBodyTests.TestWeatherBurstsOnce;
begin
  UseRoom(RoomRowsOf(0, 0, 0, 0));
  var Body := FRoom.Place('skyBarrel', 8, 2);

  Body.Burst(nil);
  Body.Burst(nil);
  TickBody(Body, FallTicks);

  Assert.AreEqual<TMonsterEvent>(meDied, Body.DrainEvent, 'the death');
  Assert.AreEqual<TMonsterEvent>(meBurst, Body.DrainEvent, 'the burst');
  Assert.AreEqual<TMonsterEvent>(meNone, Body.DrainEvent,
    'It burst a second time, or again on landing');
end;

procedure TMonsterBodyTests.TestBarrelOfTheLevelsLandsAndStands;
begin
  UseRoom(RoomRowsOf(0, 0, 0, 0));
  var Body := FRoom.Place('barrel', 8, 2);

  TickBody(Body, FallTicks);

  Assert.AreEqual<TMonsterLife>(mlAlive, Body.Life, 'The barrel burst');
  Assert.AreEqual(FloorY, PlaceY(Body), 'The barrel hangs in the air');
  Assert.AreEqual<TMonsterEvent>(meNone, Body.DrainEvent, 'An event');
end;

// Ticks the body and says whether it ever stood off where it started:
// a patrol comes back past its start, so its last place proves nothing
function WalksWithin(const ABody: TMonster; ATicks: Integer): Boolean;
begin
  var StartX := Round(ABody.X);
  Result := False;
  for var i := 1 to ATicks do
  begin
    ABody.Tick(0, 0, nil);
    if Round(ABody.X) <> StartX then
      Result := True;
  end;
end;

procedure TMonsterBodyTests.TestDormantBodyStandsStillAndSleeps;
begin
  UseRoom(RoomRowsOf(0, 0, 0, 0));
  var Body := FRoom.Place('gravel', 8, 11);

  Body.Dormant := True;
  Assert.IsFalse(WalksWithin(Body, SleepTicks), 'A sleeper walked');
  Assert.IsTrue(Body.Asleep, 'A sleeper is not asleep');

  Body.Dormant := False;
  Assert.IsTrue(WalksWithin(Body, SleepTicks),
    'Woken, it does not walk again');
end;

procedure TMonsterBodyTests.TestDormantBodyStillFalls;
begin
  UseRoom(RoomRowsOf(0, 0, 0, 0));
  var Body := FRoom.Place('gravel', 8, 4);

  Body.Dormant := True;
  TickBody(Body, FallTicks);

  Assert.AreEqual(FloorY, PlaceY(Body), 'A sleeper hangs in the air');
end;

procedure TMonsterBodyTests.TestHeldBodyWalksAndHoldsItsFire;
begin
  UseRoom(RoomRowsOf(0, 0, 0, 0));
  var Loose: TMonster := FRoom.Place('betoner', 4, 11);
  Assert.WillRaise(
    procedure
    begin
      TickBody(Loose, FiringTicks);
    end, EAccessViolation, 'A betoner not held never fired: the room sees ' +
    'no shot, and the held one below proves nothing');

  UseRoom(RoomRowsOf(0, 0, 0, 0));
  var Holding: TMonster := FRoom.Place('betoner', 8, 11);
  Holding.Held := True;
  var Walked := False;
  Assert.WillNotRaise(
    procedure
    begin
      Walked := WalksWithin(Holding, HeldTicks);
    end, EAccessViolation, 'A held betoner fired');
  Assert.IsTrue(Walked, 'A held body stands: the hold is of its fire, not ' +
    'of its feet');
end;

procedure TMonsterBodyTests.TestSmittenBodyDiesTellingOnlyItsDeath;
begin
  UseRoom(RoomRowsOf(0, 0, 0, 0));
  var Body := FRoom.Place('gravel', 8, 11);

  Body.Smite(nil);

  Assert.AreEqual<TMonsterLife>(mlDying, Body.Life);
  Assert.AreEqual<TMonsterEvent>(meDied, Body.DrainEvent, 'the death');
  Assert.AreEqual<TMonsterEvent>(meNone, Body.DrainEvent,
    'A burst, or a second death: the game would blow it up or pay twice');
  Body.Smite(nil);
  Assert.AreEqual<TMonsterEvent>(meNone, Body.DrainEvent,
    'A dying body is struck down again');
end;

procedure TMonsterBodyTests.TestRemovedBodyIsGoneWithNoDeath;
begin
  UseRoom(RoomRowsOf(0, 0, 0, 0));
  var Body := FRoom.Place('gravel', 8, 4);
  var StartY := PlaceY(Body);

  Body.Vanish;
  TickBody(Body, FallTicks);

  Assert.AreEqual<TMonsterLife>(mlDead, Body.Life, 'A removed body lives');
  Assert.AreEqual<TMonsterEvent>(meNone, Body.DrainEvent,
    'A removed body tells a death: its sound plays, its score is paid');
  Assert.AreEqual(StartY, PlaceY(Body), 'A removed body is still in the ' +
    'world: it fell');
end;

procedure TMonsterBodyTests.TestStoodBodyIsPutAtRest;
begin
  UseRoom(RoomRowsOf(0, 0, 0, 0));
  var Body := FRoom.Place('gravel', 8, 4);
  Body.Throw(40);
  TickBody(Body, 1);

  Body.Stand(160, FloorY, True);

  Assert.AreEqual(160, PlaceX(Body), 'Across');
  Assert.AreEqual(FloorY, PlaceY(Body), 'Its feet');
  Assert.IsTrue(Body.Direction, 'It faces right as told');
  Assert.IsFalse(Body.InFlight, 'Stood, it is still thrown or falling');
  TickBody(Body, 1);
  Assert.IsTrue(PlaceX(Body) > 160, 'It walks off the way it faces');
end;

procedure TMonsterBodyTests.TestBodyStoodOnADeckHasItUnderItsFeet;
begin
  FreeAndNil(FRoom);
  FRoom := RoomFromRows(RoomRowsOf(0, 0, 0, 0), DeckSections);
  var Deck := FRoom.Pads.FindTagged('deck');
  var Body := FRoom.Place('gravel', 2, 11);

  Body.Stand(DeckLeft, DeckTop, False);
  Assert.IsTrue(Body.DeckUnderFeet = Deck, 'Stood on the deck');

  Body.Stand(64, FloorY, False);
  Assert.IsNull(Body.DeckUnderFeet, 'Stood on the floor');
end;

procedure TMonsterBodyTests.TestAnchoredStoneIsMovedByNothing;
begin
  FreeAndNil(FRoom);
  FRoom := RoomFromRows(RoomRowsOf(0, 0, 0, 0), DeckSections);
  var Medkit := FRoom.Place('medkit', 4, 11);
  var MedkitX := PlaceX(Medkit);
  Medkit.TakeDamage(Blow, 0, nil);
  Assert.AreNotEqual(MedkitX, PlaceX(Medkit), 'A blow moves a pickup');

  var Stone := FRoom.Place('moonStone', 2, 11);
  var StoneX := PlaceX(Stone);
  Stone.TakeDamage(Blow, 0, nil);
  Stone.Throw(ThrowWay);
  TickBody(Stone, DeckRiseTicks);
  Assert.AreEqual(StoneX, PlaceX(Stone), 'A blow or a throw moved the stone');

  var Deck := FRoom.Pads.FindTagged('deck');
  Stone.Stand(DeckLeft, DeckTop, False);
  Deck.FlyTo(DeckLeft, DeckTop - DeckRise, DeckRiseTicks);
  for var i := 1 to 2 * DeckRiseTicks do
  begin
    FRoom.Pads.Tick(1, nil);
    Stone.Tick(0, 0, nil);
  end;
  Assert.IsTrue(PlaceY(Stone) >= DeckTop, 'The deck carried the stone up');
end;

procedure TMonsterBodyTests.TestInvulnerableStoneOutlivesAnyBlow;
begin
  UseRoom(RoomRowsOf(0, 0, 0, 0));
  var Stone := FRoom.Place('moonStone', 8, 11);
  var Lives := Stone.Lives;

  Stone.TakeDamage(0, Lives, nil);
  Stone.TakeDamage(0, Lives, nil);

  Assert.AreEqual<TMonsterLife>(mlAlive, Stone.Life, 'The stone was shot dead');
  Assert.AreEqual(Lives, Stone.Lives, 'A blow took a life of it');
  Assert.AreEqual<TMonsterEvent>(meNone, Stone.DrainEvent, 'It told a death');
end;

initialization
  TDUnitX.RegisterTestFixture(TMonsterBodyTests);

end.
