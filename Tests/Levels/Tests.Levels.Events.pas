{
  Tests.Levels.Events - what the parser of the events (Levels.Events) and
  the level's load (Levels.Defs) make of the condition heroStands: the
  cell it waits on, a cell missing or under 1, a cell off the grid. And of
  the action respawn: the cell it moves the checkpoint to, held to the
  rules of a respawn point - on the grid, out of a wall, over a floor.

  The parser is tried over a root of JSON with the events of the test and
  nothing else; the grid is the load's, tried through a one-screen room
  (LevelFromRows). Whether the hero stands in the cell, and where a fall
  brings him back, are the game's (Game.Moon) and are seen live.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Levels.Events;

interface

uses
  DUnitX.TestFramework,
  Levels.Events;

type
  [TestFixture]
  TLevelEventsTests = class
  public
    [Test]
    procedure TestHeroStandsReadsItsCell;
    [Test]
    procedure TestHeroStandsWithoutACellRaises;
    [Test]
    procedure TestHeroStandsOffTheGridFailsToLoad;
    [Test]
    procedure TestRespawnActionReadsItsCell;
    [Test]
    procedure TestRespawnActionWithoutACellRaises;
    [Test]
    procedure TestRespawnActionOnAFloorLoads;
    [Test]
    procedure TestRespawnActionOffTheGridFailsToLoad;
    [Test]
    procedure TestRespawnActionInAWallFailsToLoad;
    [Test]
    procedure TestRespawnActionOverAPitFailsToLoad;
  end;

implementation

uses
  System.JSON,
  System.SysUtils,
  Levels.Defs,
  Tests.Rooms;

const
  LevelId = 'test';
  // One event that waits for the hero; the format puts its cell
  StandsJson = '"events":[{"id":"wake","screen":1,"when":"heroStands"%s,' +
    '"then":[{"action":"bigMessage","text":"!"}]}]';
  // One event that moves the checkpoint; the format puts its cell
  RespawnJson = '"events":[{"id":"safe","screen":1,"when":"enterScreen",' +
    '"then":[{"action":"respawn"%s}]}]';
  PitCol = 5;

function EventsOf(const ASection: string): TArray<TLevelEvent>;
begin
  var Root := TJSONObject.ParseJSONValue('{' + ASection + '}') as TJSONObject;
  try
    Result := ParseLevelEvents(Root, LevelId);
  finally
    Root.Free;
  end;
end;

// By value, not const: an anonymous method captures it
procedure ExpectParseRaises(ACell, AWhat: string);
begin
  Assert.WillRaise(
    procedure
    begin
      EventsOf(Format(StandsJson, [ACell]));
    end, ELevelEventError, AWhat);
end;

// By value, not const: an anonymous method captures it
procedure ExpectRespawnParseRaises(ACell, AWhat: string);
begin
  Assert.WillRaise(
    procedure
    begin
      EventsOf(Format(RespawnJson, [ACell]));
    end, ELevelEventError, AWhat);
end;

// By value, not const: an anonymous method captures it
procedure ExpectRespawnLoadFails(ARows: TArray<string>; ACell, AWhat: string);
begin
  Assert.WillRaise(
    procedure
    begin
      LevelFromRows(ARows, Format(RespawnJson, [ACell])).Free;
    end, ELevelError, AWhat);
end;

function RoomWithPit: TArray<string>;
begin
  Result := RoomRowsOf(0, 0, 0, 0);
  Result[RoomRows - 1][PitCol] := '.';
end;

procedure TLevelEventsTests.TestHeroStandsReadsItsCell;
begin
  var Events := EventsOf(Format(StandsJson, [',"x":8,"y":8']));
  Assert.AreEqual<TEventCondition>(ecHeroStands, Events[0].Condition);
  Assert.AreEqual(8, Events[0].CellX, 'x, from 1');
  Assert.AreEqual(8, Events[0].CellY, 'y, from 1');
end;

procedure TLevelEventsTests.TestHeroStandsWithoutACellRaises;
begin
  ExpectParseRaises('', 'No cell');
  ExpectParseRaises(',"x":8', 'No y');
  ExpectParseRaises(',"x":0,"y":8', 'A column under 1');
end;

procedure TLevelEventsTests.TestHeroStandsOffTheGridFailsToLoad;
begin
  Assert.WillRaise(
    procedure
    begin
      LevelFromRows(RoomRowsOf(0, 0, 0, 0),
        Format(StandsJson, [',"x":17,"y":8'])).Free;
    end, ELevelError, 'A column past the sixteenth');
end;

procedure TLevelEventsTests.TestRespawnActionReadsItsCell;
begin
  var Events := EventsOf(Format(RespawnJson, [',"x":13,"y":6']));
  Assert.AreEqual<TEventActionKind>(eaRespawn, Events[0].Actions[0].Kind);
  Assert.AreEqual(13, Events[0].Actions[0].CellX, 'x, from 1');
  Assert.AreEqual(6, Events[0].Actions[0].CellY, 'y, from 1');
end;

procedure TLevelEventsTests.TestRespawnActionWithoutACellRaises;
begin
  ExpectRespawnParseRaises('', 'No cell');
  ExpectRespawnParseRaises(',"x":8', 'No y');
  ExpectRespawnParseRaises(',"x":0,"y":8', 'A column under 1');
end;

procedure TLevelEventsTests.TestRespawnActionOnAFloorLoads;
begin
  var Level := LevelFromRows(RoomRowsOf(0, 0, 0, 0),
    Format(RespawnJson, [',"x":3,"y":11']));
  try
    Assert.AreEqual<TEventActionKind>(eaRespawn, Level.Events[0].Actions[0].Kind,
      'A cell standing on the floor is let through');
  finally
    Level.Free;
  end;
end;

procedure TLevelEventsTests.TestRespawnActionOffTheGridFailsToLoad;
begin
  ExpectRespawnLoadFails(RoomRowsOf(0, 0, 0, 0), ',"x":17,"y":11',
    'A column past the sixteenth');
  ExpectRespawnLoadFails(RoomRowsOf(0, 0, 0, 0), ',"x":3,"y":13',
    'A row past the twelfth');
end;

procedure TLevelEventsTests.TestRespawnActionInAWallFailsToLoad;
begin
  ExpectRespawnLoadFails(RoomRowsOf(0, 0, 0, 0), ',"x":3,"y":12',
    'A cell in the floor');
end;

procedure TLevelEventsTests.TestRespawnActionOverAPitFailsToLoad;
begin
  ExpectRespawnLoadFails(RoomWithPit, Format(',"x":%d,"y":11', [PitCol]),
    'A cell over a hole in the floor');
end;

initialization
  TDUnitX.RegisterTestFixture(TLevelEventsTests);

end.
