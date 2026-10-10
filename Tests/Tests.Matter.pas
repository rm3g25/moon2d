{
  Tests.Matter - the matter of a screen made by hand, for the orbs that are
  drawn out of it.

  MatterFromRows takes the twelve rows of a screen ('#' solid, '.' open),
  as the rooms of the monsters do. It makes no bodies: a test that wants a
  pad puts its box into Bodies itself. SolidAt answers for a point as the
  harvest sees matter: a solid cell or a body, and nothing off the screen.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Matter;

interface

uses
  System.SysUtils, Orbs.Harvest;

type
  EMatterRowsError = class(Exception);

// The matter of twelve rows of sixteen cells: '#' solid, '.' open
function MatterFromRows(const ARows: array of string): TMatter;
// A room shut on every side: the floor, the ceiling and both walls, each
// a cell thick
function WalledMatter: TMatter;
function EmptyMatter: TMatter;
// The point, in screen units, lies in a solid cell or in a body
function SolidAt(const AMatter: TMatter; AX, AY: Single): Boolean;

implementation

uses
  Sdl2.Core, Game.Space, Render.Sprites;

const
  SolidCell = '#';

resourcestring
  SWrongRowCount = 'A screen is %d rows, not %d';
  SWrongRowLength = 'A row of a screen is %d cells, not %d: "%s"';

function MatterFromRows(const ARows: array of string): TMatter;
begin
  if Length(ARows) <> ScreenRows then
    raise EMatterRowsError.CreateFmt(SWrongRowCount,
      [ScreenRows, Length(ARows)]);

  Result := Default(TMatter);
  for var Row := 0 to ScreenRows - 1 do
  begin
    if Length(ARows[Row]) <> ScreenCols then
      raise EMatterRowsError.CreateFmt(SWrongRowLength,
        [ScreenCols, Length(ARows[Row]), ARows[Row]]);
    for var Col := 0 to ScreenCols - 1 do
      Result.Cells[Row, Col] := ARows[Row][Col + 1] = SolidCell;
  end;
end;

function WalledMatter: TMatter;
begin
  Result := Default(TMatter);
  for var Row := 0 to ScreenRows - 1 do
    for var Col := 0 to ScreenCols - 1 do
    begin
      var IsFloorOrCeiling := (Row = 0) or (Row = ScreenRows - 1);
      var IsWall := (Col = 0) or (Col = ScreenCols - 1);
      Result.Cells[Row, Col] := IsFloorOrCeiling or IsWall;
    end;
end;

function EmptyMatter: TMatter;
begin
  Result := Default(TMatter);
end;

function BodyHolds(const ABody: TSdlFRect; AX, AY: Single): Boolean;
begin
  Result := (AX >= ABody.X) and (AX < ABody.X + ABody.W) and
    (AY >= ABody.Y) and (AY < ABody.Y + ABody.H);
end;

function SolidAt(const AMatter: TMatter; AX, AY: Single): Boolean;
begin
  var IsOnScreen := (AX >= 0) and (AX < ScreenWidth) and (AY >= 0) and
    (AY < ScreenHeight);
  if not IsOnScreen then
    Exit(False);
  if AMatter.Cells[Trunc(AY / TileSize), Trunc(AX / TileSize)] then
    Exit(True);

  for var Body in AMatter.Bodies do
    if BodyHolds(Body, AX, AY) then
      Exit(True);
  Result := False;
end;

end.
