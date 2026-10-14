{
  Tests.Levels.Entities - what a level makes of the overrides of a
  placement: each word lands in its own field, a word left out is not
  set, and the fire offset of the mount is among them. And what it makes
  of a body an event spawns, which has no placement: its tag, and the
  rigs the level hangs on that tag.

  The level is loaded from a one-screen room with the entities and the
  events of the test in its root. The other members of a placement
  (triggers, rigs, grades) are not tried here.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Levels.Entities;

interface

uses
  DUnitX.TestFramework,
  Levels.Defs;

type
  [TestFixture]
  TLevelEntitiesTests = class
  private
    FLevel: TLevel;
    function OverridesOfMount(const AOverrides: string): TEntityOverrides;
  public
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestFireOffsetIsReadAsWritten;
    [Test]
    procedure TestFireOffsetLeftOutIsNotSet;
    [Test]
    procedure TestOverridesLandEachInItsOwnField;
    [Test]
    procedure TestSpawnedBodyWearsTheRigsOfItsTag;
    [Test]
    procedure TestSpawnedBodyWithoutATagWearsNoRig;
    [Test]
    procedure TestSpawnedBodyTakesNoTagOfAPlacement;
  end;

implementation

uses
  System.SysUtils,
  Levels.Events,
  Levels.Rigs,
  Tests.Rooms;

const
  GuestTag = 'guest';
  // A rig of one lamp for the spawned body
  LampRig = '"rigs":{"lamp":[{"kind":"beacon","x":1,"y":1}]}';

// The entities section of one mount; AOverrides is the members of its
// overrides object as they stand in a file, '' for a placement with none
function EntitiesJson(const AOverrides: string): string;
begin
  var Overrides := '';
  if AOverrides <> '' then
    Overrides := ',"overrides":{' + AOverrides + '}';
  Result := '"entities":[{"monsterId":"mount","screen":1,"x":12,"y":3'
    + Overrides + '}]';
end;

// The events section of one platform spawned along row 2; AMembers is more
// members of the spawn as they stand in a file
function SpawnJson(const AMembers: string): string;
begin
  Result := '"events":[{"id":"guestIn","screen":1,"when":"actReached",' +
    '"act":1,"then":[{"action":"spawn","monster":"platform","row":2,' +
    '"from":"left"' + AMembers + '}]}]';
end;

// By value, not const: an anonymous method captures them
procedure ExpectRaises(AClass: ExceptClass; ASections, AWhat: string);
begin
  Assert.WillRaise(
    procedure
    begin
      LevelFromRows(RoomRowsOf(0, 0, 0, 0), ASections).Free;
    end, AClass, AWhat);
end;

procedure TLevelEntitiesTests.TearDown;
begin
  FreeAndNil(FLevel);
end;

function TLevelEntitiesTests.OverridesOfMount(
  const AOverrides: string): TEntityOverrides;
begin
  FreeAndNil(FLevel);
  FLevel := LevelFromRows(RoomRowsOf(0, 0, 0, 0), EntitiesJson(AOverrides));
  Assert.AreEqual(1, Integer(Length(FLevel.Entities)),
    'The level holds one placement');
  Result := FLevel.Entities[0].Overrides;
end;

procedure TLevelEntitiesTests.TestFireOffsetIsReadAsWritten;
begin
  var Overrides := OverridesOfMount('"fireOffset":22');
  Assert.IsTrue(Overrides.HasFireOffset, 'The word is set');
  Assert.AreEqual(22, Overrides.FireOffset, 'and carries what was written');
end;

procedure TLevelEntitiesTests.TestFireOffsetLeftOutIsNotSet;
begin
  var Overrides := OverridesOfMount('"direction":1');
  Assert.IsFalse(Overrides.HasFireOffset,
    'Overrides without the word leave the offset alone');
  Assert.IsFalse(OverridesOfMount('').HasFireOffset,
    'A placement with no overrides at all too');
end;

procedure TLevelEntitiesTests.TestOverridesLandEachInItsOwnField;
begin
  var Overrides := OverridesOfMount('"direction":1,"speed":3,"lives":9,'
    + '"canShoot":false,"fireOffset":7');
  Assert.AreEqual(1, Overrides.Direction, 'direction');
  Assert.AreEqual(3, Overrides.Speed, 'speed');
  Assert.AreEqual(9, Overrides.Lives, 'lives');
  Assert.IsTrue(Overrides.HasCanShoot, 'canShoot is set');
  Assert.IsFalse(Overrides.CanShoot, 'and false');
  Assert.AreEqual(7, Overrides.FireOffset, 'fireOffset');
end;

procedure TLevelEntitiesTests.TestSpawnedBodyWearsTheRigsOfItsTag;
begin
  FreeAndNil(FLevel);
  FLevel := LevelFromRows(RoomRowsOf(0, 0, 0, 0), LampRig + ',' +
    SpawnJson(Format(',"tag":"%s","rig":["lamp"]', [GuestTag])));

  var Spawn := FLevel.Events[0].Actions[0].Spawn;
  Assert.AreEqual(GuestTag, Spawn.Tag, 'The tag of the body');
  Assert.AreEqual(1, Integer(Length(Spawn.Rigs)), 'The rigs it wears');
  var Hung := 0;
  for var DynamicObject in FLevel.Dynamics do
    if DynamicObject.Placement.Parent = GuestTag then
      Inc(Hung);
  Assert.AreEqual(1, Hung, 'The lamp hangs on its tag before it is let in');
end;

procedure TLevelEntitiesTests.TestSpawnedBodyWithoutATagWearsNoRig;
begin
  FreeAndNil(FLevel);
  FLevel := LevelFromRows(RoomRowsOf(0, 0, 0, 0), SpawnJson(''));
  var Spawn := FLevel.Events[0].Actions[0].Spawn;
  Assert.AreEqual('', Spawn.Tag, 'A body spawned with no tag carries none');
  Assert.AreEqual(0, Integer(Length(Spawn.Rigs)), 'and wears nothing');

  ExpectRaises(ERigError, LampRig + ',' + SpawnJson(',"rig":["lamp"]'),
    'A rig on a body with no tag');
end;

// A lamp finds its parent by the tag: one of the placement's and the
// body's, it would hang on whichever the game finds first
procedure TLevelEntitiesTests.TestSpawnedBodyTakesNoTagOfAPlacement;
begin
  var Mount := Format('"entities":[{"monsterId":"mount","screen":1,"x":12,' +
    '"y":3,"tag":"%s"}]', [GuestTag]);
  ExpectRaises(ELevelError, Mount + ',' + LampRig + ',' +
    SpawnJson(Format(',"tag":"%s","rig":["lamp"]', [GuestTag])),
    'A rigged body under the tag of a placement');
end;

initialization
  TDUnitX.RegisterTestFixture(TLevelEntitiesTests);

end.
