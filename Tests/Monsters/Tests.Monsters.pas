{
  Tests.Monsters - what a blow does to the body it strikes. The recoil
  stays (it is a mechanic: a medkit is knocked off a ledge to reach a
  secret), and the recoil must never leave a body in a wall, nor hanging
  in the air on a sliver of its own art that the wall holds.

  The bodies are a medkit (a static pickup) and a gravel (a patrol
  walker), in rooms of a few solid cells. Blows are struck with no losses
  and into a nil burst, so nothing here dies.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Monsters;

interface

uses
  DUnitX.TestFramework,
  Monsters,
  Tests.Rooms;

type
  [TestFixture]
  TMonsterTests = class
  private
    FRoom: TRoom;
    procedure UseRoom(const ARows: array of string);
    function Medkit(ACol, ARow: Integer): TMonster;
    procedure Knock(const AMonster: TMonster; ABlow: Integer;
      ATimes: Integer = 1);
    procedure KnockAndTick(const AMonster: TMonster; ABlow: Integer;
      ATimes: Integer);
  public
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestKnockMovesBodyAwayByHalfTheBlow;
    [Test]
    procedure TestKnockMovesWalkerToo;
    [Test]
    procedure TestKnockStopsFlushAgainstRightWall;
    [Test]
    procedure TestKnockStopsFlushAgainstLeftWall;
    [Test]
    procedure TestKnocksDoNotSinkBodyDeeper;
    [Test]
    procedure TestFallingBodyKnockedAlongWallStillLands;
    [Test]
    procedure TestKnockOffLedgeDropsBodyToTheFloor;
    [Test]
    procedure TestKnockKeepsBodyOnTheScreen;
    [Test]
    procedure TestHitCostsTheLosses;
  end;

implementation

uses
  System.SysUtils;

const
  // The feet of a body that stands on the floor row of a room
  FloorY: Integer = 352;
  // The top of the ledge room's ledge: the feet of a body standing on it
  LedgeTopY: Integer = 256;
  // A blow of this size moves a body half of it
  Blow = 8;
  // The margin of the art in the 32-unit sprite (the game's hit inset)
  ArtMargin = 8;
  ArtRightOffset = 24;
  // A body takes about 120 ticks to fall the height of the screen
  FallTicks = 150;
  // The most blows any test below strikes before it looks
  Plenty = 50;

// Round gives an Int64, and AreEqual takes two of one type: the places
// of a body are read as Integer
function PlaceX(const AMonster: TMonster): Integer;
begin
  Result := Round(AMonster.X);
end;

function PlaceY(const AMonster: TMonster): Integer;
begin
  Result := Round(AMonster.Y);
end;

function RightArtEdge(const AMonster: TMonster): Integer;
begin
  Result := PlaceX(AMonster) + ArtRightOffset;
end;

function LeftArtEdge(const AMonster: TMonster): Integer;
begin
  Result := PlaceX(AMonster) + ArtMargin;
end;

// Flush: within one unit of the face of the wall and not inside it
procedure ExpectFlushRight(const AMonster: TMonster; AFace: Integer);
begin
  var Edge := RightArtEdge(AMonster);
  Assert.IsTrue((Edge >= AFace - 1) and (Edge <= AFace),
    Format('The art ends at x = %d, the wall face is at %d', [Edge, AFace]));
end;

procedure ExpectFlushLeft(const AMonster: TMonster; AFace: Integer);
begin
  var Edge := LeftArtEdge(AMonster);
  Assert.IsTrue((Edge >= AFace) and (Edge <= AFace + 1),
    Format('The art starts at x = %d, the wall face is at %d', [Edge, AFace]));
end;

procedure TMonsterTests.TearDown;
begin
  FreeAndNil(FRoom);
end;

procedure TMonsterTests.UseRoom(const ARows: array of string);
begin
  FreeAndNil(FRoom);
  FRoom := RoomFromRows(ARows);
end;

function TMonsterTests.Medkit(ACol, ARow: Integer): TMonster;
begin
  Result := FRoom.Place('medkit', ACol, ARow);
end;

procedure TMonsterTests.Knock(const AMonster: TMonster; ABlow: Integer;
  ATimes: Integer);
begin
  for var i := 1 to ATimes do
    AMonster.TakeDamage(ABlow, 0, nil);
end;

procedure TMonsterTests.KnockAndTick(const AMonster: TMonster; ABlow: Integer;
  ATimes: Integer);
begin
  for var i := 1 to ATimes do
  begin
    AMonster.TakeDamage(ABlow, 0, nil);
    AMonster.Tick(0, 0, nil);
  end;
end;

procedure TMonsterTests.TestKnockMovesBodyAwayByHalfTheBlow;
begin
  UseRoom(RoomRowsOf(0, 0, 0, 0));
  var Body := Medkit(8, 11);
  var Start := PlaceX(Body);

  Knock(Body, Blow);
  Assert.AreEqual(Start + Blow div 2, PlaceX(Body), 'a blow to the right');

  Knock(Body, -Blow);
  Assert.AreEqual(Start, PlaceX(Body), 'a blow to the left');
end;

procedure TMonsterTests.TestKnockMovesWalkerToo;
begin
  UseRoom(RoomRowsOf(0, 0, 0, 0));
  var Body := FRoom.Place('gravel', 8, 11);
  var Start := PlaceX(Body);

  Knock(Body, Blow);
  Assert.AreEqual(Start + Blow div 2, PlaceX(Body), 'a blow to the right');

  Knock(Body, -Blow);
  Assert.AreEqual(Start, PlaceX(Body), 'a blow to the left');
end;

procedure TMonsterTests.TestKnockStopsFlushAgainstRightWall;
begin
  // The wall is column 14: its face is at x = 13 * 32
  UseRoom(RoomRowsOf(14, 0, 0, 0));
  var Body := Medkit(8, 11);

  Knock(Body, Blow, Plenty);

  ExpectFlushRight(Body, 416);
end;

procedure TMonsterTests.TestKnockStopsFlushAgainstLeftWall;
begin
  // The wall is column 3: its face is at x = 3 * 32
  UseRoom(RoomRowsOf(3, 0, 0, 0));
  var Body := Medkit(8, 11);

  Knock(Body, -Blow, Plenty);

  ExpectFlushLeft(Body, 96);
end;

procedure TMonsterTests.TestKnocksDoNotSinkBodyDeeper;
begin
  UseRoom(RoomRowsOf(14, 0, 0, 0));
  var Body := Medkit(8, 11);

  Knock(Body, Blow, Plenty);
  var Placed := PlaceX(Body);
  Knock(Body, Blow, Plenty * 5);

  Assert.AreEqual(Placed, PlaceX(Body), 'the body went on into the wall');
end;

procedure TMonsterTests.TestFallingBodyKnockedAlongWallStillLands;
begin
  // The wall is column 10 (its face at x = 288); the body is put in the
  // air beside it, in column 9, row 2
  UseRoom(RoomRowsOf(10, 0, 0, 0));
  var Body := Medkit(9, 2);

  Body.Tick(0, 0, nil);
  KnockAndTick(Body, Blow, FallTicks);

  Assert.AreEqual(FloorY, PlaceY(Body), 'the body hangs in the air');
  Assert.IsTrue(RightArtEdge(Body) <= 288,
    Format('The art ends at x = %d, inside the wall', [RightArtEdge(Body)]));
end;

procedure TMonsterTests.TestKnockOffLedgeDropsBodyToTheFloor;
begin
  // The ledge is row 9, columns 4 to 6: its top at y = 256, its right
  // end at x = 192. The body stands on that end
  UseRoom(RoomRowsOf(0, 9, 4, 6));
  var Body := Medkit(6, 8);
  Assert.AreEqual(LedgeTopY, PlaceY(Body), 'the body is not on the ledge');

  KnockAndTick(Body, Blow, FallTicks);

  Assert.AreEqual(FloorY, PlaceY(Body), 'the body did not fall to the floor');
  Assert.IsTrue(PlaceX(Body) >= 192,
    Format('The body is at x = %d, still over the ledge', [PlaceX(Body)]));
end;

procedure TMonsterTests.TestKnockKeepsBodyOnTheScreen;
begin
  UseRoom(RoomRowsOf(0, 0, 0, 0));
  var Body := Medkit(8, 11);

  Knock(Body, Blow, 300);
  Assert.IsTrue(PlaceX(Body) <= 482,
    Format('Knocked off the right of the screen, x = %d', [PlaceX(Body)]));

  Knock(Body, -Blow, 300);
  Assert.IsTrue(PlaceX(Body) >= 0,
    Format('Knocked off the left of the screen, x = %d', [PlaceX(Body)]));
end;

procedure TMonsterTests.TestHitCostsTheLosses;
begin
  UseRoom(RoomRowsOf(0, 0, 0, 0));
  var Body := Medkit(8, 11);
  var Before := Body.Lives;

  Body.TakeDamage(0, 1, nil);

  Assert.AreEqual(Before - 1, Body.Lives);
end;

initialization
  TDUnitX.RegisterTestFixture(TMonsterTests);

end.
