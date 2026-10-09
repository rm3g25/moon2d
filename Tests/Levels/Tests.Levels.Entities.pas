{
  Tests.Levels.Entities - what a level makes of the overrides of a
  placement: each word lands in its own field, a word left out is not
  set, and the fire offset of the mount is among them.

  The level is loaded from a one-screen room with the entities of the
  test in its root. The other members of a placement (triggers, rigs,
  grades) are not tried here.

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
  end;

implementation

uses
  System.SysUtils,
  Tests.Rooms;

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

initialization
  TDUnitX.RegisterTestFixture(TLevelEntitiesTests);

end.
