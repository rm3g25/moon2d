{
  Tests.Levels.Events - what the parser of the events (Levels.Events) and
  the level's load (Levels.Defs) make of the condition heroStands: the
  cell it waits on, a cell missing or under 1, a cell off the grid.

  The parser is tried over a root of JSON with the events of the test and
  nothing else; the grid is the load's, tried through a one-screen room
  (LevelFromRows). Whether the hero stands in the cell is the game's
  (Moon2D.dpr) and is seen live.

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

initialization
  TDUnitX.RegisterTestFixture(TLevelEventsTests);

end.
