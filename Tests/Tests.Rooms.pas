{
  Tests.Rooms - a room to stand monsters in, without a window.

  RoomFromRows takes the twelve rows of a screen ('#' solid, '.' open) and
  builds what a monster needs to be alive: a one-screen level (through a
  temporary JSON file, TLevel has no other way in), a pad world over it
  and the registry of monsters.json, which lies beside the executable.
  The level has no pads, so the pad world never asks the renderer or the
  sprite cache and both are nil, as the jump reach is.

  No animation set, no disc art, no bursts: what is placed here can be
  moved, shoved and ticked, never drawn. A body that explodes is never
  made to die (its death fans bullets into a burst, and a burst needs a
  renderer); a gravel carries none and can die into a nil one.

  LevelFromRows is the same level with more in its root - the pads and
  the respawn points of a test - and with nothing around it: no pad
  world, no registry. It is for what the level's own load says.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Rooms;

interface

uses
  System.Generics.Collections,
  Levels.Defs,
  Monsters,
  Monsters.Defs,
  Pads.World;

const
  RoomCols = 16;
  RoomRows = 12;

type
  TRoom = class
  private
    FLevel: TLevel;
    FPads: TPadWorld;
    FRegistry: TMonsterRegistry;
    FMonsters: TObjectList<TMonster>;
    procedure LoadLevel(const ARows: array of string);
  public
    constructor Create(const ARows: array of string);
    destructor Destroy; override;

    // A monster on the cell (counted from 1, as the level file counts)
    // with its feet on the bottom line of it. The room owns it.
    function Place(const AMonsterId: string; ACol, ARow: Integer): TMonster;
      overload;
    // The same for a placement with more said: its overrides. The room
    // fills in the screen (the room has one).
    function Place(const APlacement: TEntityPlacement): TMonster; overload;
  end;

function RoomFromRows(const ARows: array of string): TRoom;

// The level of a room with more members in its root. ASections is JSON
// members as they stand in a file, '"pads":[...],"respawns":[...]'; ''
// adds none; a section of "entities" stands in place of the empty one.
// A level the load turns down raises what LoadFromFile raises,
// and nothing is left behind. The caller frees the level.
function LevelFromRows(const ARows: array of string;
  const ASections: string): TLevel;

// A room of twelve rows: the last is the floor. AWallCol (from 1, 0 = none)
// is a solid column over it; ALedgeRow (from 1, 0 = none) is solid between
// the columns AFrom and ATo.
function RoomRowsOf(AWallCol, ALedgeRow, AFrom, ATo: Integer): TArray<string>;

implementation

uses
  System.IOUtils,
  System.StrUtils,
  System.SysUtils,
  Render.Sprites;

function CollisionJson(const ARows: array of string): string;
begin
  var Lines := TStringBuilder.Create;
  try
    for var i := 0 to High(ARows) do
    begin
      if i > 0 then
        Lines.Append(',');
      Lines.Append('"').Append(ARows[i].Replace('#', '1').Replace('.', '0'))
        .Append('"');
    end;
    Result := Lines.ToString;
  finally
    Lines.Free;
  end;
end;

function TileRowsJson: string;
begin
  var Row := '"' + DupeString('0,', RoomCols - 1) + '0"';
  var Rows := TStringBuilder.Create;
  try
    for var i := 1 to RoomRows do
    begin
      if i > 1 then
        Rows.Append(',');
      Rows.Append(Row);
    end;
    Result := Rows.ToString;
  finally
    Rows.Free;
  end;
end;

function BuildLevel(const ARows: array of string;
  const ASections: string): TLevel;
begin
  if Length(ARows) <> RoomRows then
    raise Exception.CreateFmt('A room is %d rows, not %d',
      [RoomRows, Length(ARows)]);
  for var Row in ARows do
    if Length(Row) <> RoomCols then
      raise Exception.CreateFmt('A room row is %d cells, not %d: "%s"',
        [RoomCols, Length(Row), Row]);

  var Members := '';
  if ASections <> '' then
    Members := ASections + ',';
  var Entities := '"entities":[],';
  if ASections.Contains('"entities"') then
    Entities := '';
  var Json := '{"id":"room","grid":{"width":16,"height":12},'
    + '"tilePalette":[],"backgrounds":[],' + Entities + Members
    + '"tiles":{"screens":[{"screen":1,"rows":[' + TileRowsJson
    + '],"collision":[' + CollisionJson(ARows) + ']}]}}';

  var FileName := TPath.Combine(TPath.GetTempPath,
    'moon2d-room-' + TGUID.NewGuid.ToString + '.json');
  TFile.WriteAllText(FileName, Json, TEncoding.ASCII);

  Result := TLevel.Create;
  var IsLoaded := False;
  try
    Result.LoadFromFile(FileName);
    IsLoaded := True;
  finally
    TFile.Delete(FileName);
    if not IsLoaded then
      FreeAndNil(Result);
  end;
end;

constructor TRoom.Create(const ARows: array of string);
begin
  inherited Create;
  FMonsters := TObjectList<TMonster>.Create(True);
  LoadLevel(ARows);

  FRegistry := TMonsterRegistry.Create;
  FRegistry.LoadFromFile(
    TPath.Combine(ExtractFilePath(ParamStr(0)), 'monsters.json'));

  FPads := TPadWorld.Create(nil, nil, FLevel, nil, 1);
end;

destructor TRoom.Destroy;
begin
  // The bodies hold the level and the pads: they go first
  FMonsters.Free;
  FPads.Free;
  FRegistry.Free;
  FLevel.Free;
  inherited;
end;

procedure TRoom.LoadLevel(const ARows: array of string);
begin
  FLevel := BuildLevel(ARows, '');
end;

function TRoom.Place(const AMonsterId: string; ACol, ARow: Integer): TMonster;
begin
  var Placement := Default(TEntityPlacement);
  Placement.MonsterId := AMonsterId;
  Placement.X := ACol;
  Placement.Y := ARow;
  Result := Place(Placement);
end;

function TRoom.Place(const APlacement: TEntityPlacement): TMonster;
begin
  var Placement := APlacement;
  Placement.Screen := 1;

  Result := TMonster.Create(FRegistry.Find(Placement.MonsterId),
    Default(TAnimSet), nil, nil, FLevel, FPads, Placement, 1.0);
  FMonsters.Add(Result);
end;

function RoomFromRows(const ARows: array of string): TRoom;
begin
  Result := TRoom.Create(ARows);
end;

function LevelFromRows(const ARows: array of string;
  const ASections: string): TLevel;
begin
  Result := BuildLevel(ARows, ASections);
end;

function RoomRowsOf(AWallCol, ALedgeRow, AFrom, ATo: Integer): TArray<string>;
begin
  SetLength(Result, RoomRows);
  for var i := 0 to RoomRows - 1 do
  begin
    Result[i] := StringOfChar('.', RoomCols);
    if i = RoomRows - 1 then
      Result[i] := StringOfChar('#', RoomCols)
    else if AWallCol > 0 then
      Result[i][AWallCol] := '#';
  end;
  if ALedgeRow > 0 then
    for var Col := AFrom to ATo do
      Result[ALedgeRow - 1][Col] := '#';
end;

end.
