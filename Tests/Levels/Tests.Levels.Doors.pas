{
  Tests.Levels.Doors - what a level makes of the doors it shuts: a screen
  named in "shutDoors" is shut and no other is, the openDoor action is
  read, and the load turns down a door that nothing opens, an opening on
  a screen whose door is not shut and a list that names a screen twice
  or off the level.

  The level is loaded from a one-screen room with the doors and the events
  of the test in its root. What the game does with a shut door (the hero
  held at the threshold, the arrow on the opening) is the game's and is
  seen live.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Levels.Doors;

interface

uses
  DUnitX.TestFramework,
  Levels.Defs;

type
  [TestFixture]
  TLevelDoorsTests = class
  private
    FLevel: TLevel;
  public
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestShutDoorIsShutOnItsScreenAlone;
    [Test]
    procedure TestLevelWithoutShutDoorsShutsNone;
    [Test]
    procedure TestOpenDoorIsReadAsItsAction;
    [Test]
    procedure TestShutDoorThatNothingOpensFailsToLoad;
    [Test]
    procedure TestOpeningOnAnOpenScreenFailsToLoad;
    [Test]
    procedure TestShutDoorOffTheLevelFailsToLoad;
    [Test]
    procedure TestScreenShutTwiceFailsToLoad;
  end;

implementation

uses
  System.SysUtils,
  Levels.Events,
  Tests.Rooms;

const
  // The pickup the door waits for, and the event that opens the door
  // once it is taken
  PickupJson = '"entities":[{"monsterId":"medkit","screen":1,"x":4,"y":11,'
    + '"tag":"key"}]';
  OpenOnTakingJson = '"events":[{"id":"door","screen":1,"when":"allDead",'
    + '"tag":"key","then":[{"action":"openDoor"}]}]';

function ShutJson(const AScreens: string): string;
begin
  Result := Format('"shutDoors":[%s]', [AScreens]);
end;

function EmptyRoom: TArray<string>;
begin
  Result := RoomRowsOf(0, 0, 0, 0);
end;

// By value, not const: an anonymous method captures it
procedure ExpectLoadFails(ASections, AWhat: string);
begin
  Assert.WillRaise(
    procedure
    begin
      LevelFromRows(EmptyRoom, ASections).Free;
    end, ELevelError, AWhat);
end;

procedure TLevelDoorsTests.TearDown;
begin
  FreeAndNil(FLevel);
end;

procedure TLevelDoorsTests.TestShutDoorIsShutOnItsScreenAlone;
begin
  FLevel := LevelFromRows(EmptyRoom,
    PickupJson + ',' + OpenOnTakingJson + ',' + ShutJson('1'));
  Assert.IsTrue(FLevel.DoorShutOn(1), 'The screen named is shut');
  Assert.IsFalse(FLevel.DoorShutOn(2), 'A screen not named is not');
end;

procedure TLevelDoorsTests.TestLevelWithoutShutDoorsShutsNone;
begin
  FLevel := LevelFromRows(EmptyRoom, PickupJson);
  Assert.IsFalse(FLevel.DoorShutOn(1),
    'With no "shutDoors" every door is open, as in 2008');
end;

procedure TLevelDoorsTests.TestOpenDoorIsReadAsItsAction;
begin
  FLevel := LevelFromRows(EmptyRoom,
    PickupJson + ',' + OpenOnTakingJson + ',' + ShutJson('1'));
  Assert.AreEqual(Ord(eaOpenDoor), Ord(FLevel.Events[0].Actions[0].Kind),
    'The word "openDoor" is the opening of the door');
end;

procedure TLevelDoorsTests.TestShutDoorThatNothingOpensFailsToLoad;
begin
  ExpectLoadFails(PickupJson + ',' + ShutJson('1'),
    'A shut door with no event to open it');
end;

procedure TLevelDoorsTests.TestOpeningOnAnOpenScreenFailsToLoad;
begin
  ExpectLoadFails(PickupJson + ',' + OpenOnTakingJson,
    'An opening on a screen whose door is not shut');
end;

procedure TLevelDoorsTests.TestShutDoorOffTheLevelFailsToLoad;
begin
  ExpectLoadFails(PickupJson + ',' + OpenOnTakingJson + ',' + ShutJson('1,2'),
    'A shut door on a screen the level has not got');
end;

procedure TLevelDoorsTests.TestScreenShutTwiceFailsToLoad;
begin
  ExpectLoadFails(PickupJson + ',' + OpenOnTakingJson + ',' + ShutJson('1,1'),
    'A screen named twice');
end;

initialization
  TDUnitX.RegisterTestFixture(TLevelDoorsTests);

end.
