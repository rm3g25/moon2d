{
  Tests.Levels.Grid - the collision grid as the game may change it: a row
  erased is air, at the cells and at the points of the screen; an erase of
  the same row again changes nothing; a row off the grid is nothing to
  erase; a restore gives every erased row back as the file has it, and a
  restore with nothing erased changes nothing.

  The level is a one-screen room with a floor and a wall.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Levels.Grid;

interface

uses
  DUnitX.TestFramework,
  Levels.Defs;

type
  [TestFixture]
  TLevelGridTests = class
  private
    FLevel: TLevel;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestErasedRowIsAir;
    [Test]
    procedure TestErasingTheRowAgainChangesNothing;
    [Test]
    procedure TestRowOffTheGridIsNothingToErase;
    [Test]
    procedure TestRestoreGivesTheRowsBack;
    [Test]
    procedure TestRestoreWithNothingErasedChangesNothing;
  end;

implementation

uses
  System.SysUtils,
  Render.Sprites,
  Tests.Rooms;

const
  Screen = 1;
  // The room: the floor on the last row, a wall up the fifth column
  WallCol = 5;
  FloorRow = RoomRows - 1;

procedure TLevelGridTests.Setup;
begin
  FLevel := LevelFromRows(RoomRowsOf(WallCol, 0, 0, 0), '');
end;

procedure TLevelGridTests.TearDown;
begin
  FreeAndNil(FLevel);
end;

procedure TLevelGridTests.TestErasedRowIsAir;
begin
  Assert.IsTrue(FLevel.SolidAt(Screen, 0, FloorRow), 'The floor is there');

  FLevel.EraseRow(Screen, FloorRow);

  for var Col := 0 to RoomCols - 1 do
    Assert.IsFalse(FLevel.SolidAt(Screen, Col, FloorRow),
      'Cell ' + Col.ToString + ' of the erased row');
  Assert.IsFalse(FLevel.SolidAtPoint(Screen, 100, FloorRow * TileSize + 10),
    'A point of the erased row');
  Assert.IsTrue(FLevel.SolidAt(Screen, WallCol - 1, FloorRow - 1),
    'The wall stands above it');
end;

procedure TLevelGridTests.TestErasingTheRowAgainChangesNothing;
begin
  FLevel.EraseRow(Screen, FloorRow);
  FLevel.EraseRow(Screen, FloorRow);
  FLevel.RestoreRows;
  Assert.IsTrue(FLevel.SolidAt(Screen, 0, FloorRow),
    'The floor as the file has it, not as the second erase found it');
end;

procedure TLevelGridTests.TestRowOffTheGridIsNothingToErase;
begin
  FLevel.EraseRow(Screen, -1);
  FLevel.EraseRow(Screen, RoomRows);
  Assert.IsTrue(FLevel.SolidAt(Screen, 0, FloorRow), 'The floor is there');
  Assert.WillRaise(
    procedure
    begin
      FLevel.EraseRow(Screen + 1, FloorRow);
    end, ELevelError, 'A screen off the level');
end;

procedure TLevelGridTests.TestRestoreGivesTheRowsBack;
begin
  FLevel.EraseRow(Screen, FloorRow);
  FLevel.EraseRow(Screen, FloorRow - 1);
  Assert.IsFalse(FLevel.SolidAt(Screen, WallCol - 1, FloorRow - 1),
    'The wall''s cell of the erased row is air');

  FLevel.RestoreRows;

  for var Col := 0 to RoomCols - 1 do
    Assert.IsTrue(FLevel.SolidAt(Screen, Col, FloorRow),
      'Cell ' + Col.ToString + ' of the floor');
  Assert.IsTrue(FLevel.SolidAt(Screen, WallCol - 1, FloorRow - 1),
    'The wall''s cell is back');
  Assert.IsFalse(FLevel.SolidAt(Screen, 0, FloorRow - 1),
    'And the air beside it is air still');
end;

procedure TLevelGridTests.TestRestoreWithNothingErasedChangesNothing;
begin
  FLevel.RestoreRows;
  Assert.IsTrue(FLevel.SolidAt(Screen, 0, FloorRow), 'The floor is there');
  Assert.IsFalse(FLevel.SolidAt(Screen, 0, 0), 'The air is air');
end;

initialization
  TDUnitX.RegisterTestFixture(TLevelGridTests);

end.
