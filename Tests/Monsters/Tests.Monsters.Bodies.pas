{
  Tests.Monsters.Bodies - what the floor does to a body, alive and dead:
  the walk along a ledge and between walls, the fall and the landing, and
  the corpse, which lies where it died and falls when nothing is under it.

  The bodies are gravels (a patrol walker that turns at the end of a
  ledge) and gravel females (a walker that does not look for one), in
  rooms of a few solid cells. A gravel carries no smoke and fans no
  fragments, so it can die into a nil burst; a body that explodes cannot,
  and none is used here.

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
  end;

implementation

uses
  System.Math,
  System.SysUtils;

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

initialization
  TDUnitX.RegisterTestFixture(TMonsterBodyTests);

end.
