{
  Tests.Rooms - a room to stand monsters in, without a window.

  RoomFromRows takes the twelve rows of a screen ('#' solid, '.' open) and
  builds what a monster needs to be alive: a one-screen level (through a
  temporary JSON file, TLevel has no other way in), a pad world over it
  and the registry of monsters.json, which lies beside the executable.
  The level has no pads, so the pad world never asks the renderer or the
  sprite cache and both are nil, as the jump reach is.

  No animation set, no disc art, no bursts: what is placed here can be
  moved, shoved and ticked, never drawn, and never made to die (a death
  fans bullets into a burst, and a burst needs a renderer).

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
  end;

function RoomFromRows(const ARows: array of string): TRoom;

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
  if Length(ARows) <> RoomRows then
    raise Exception.CreateFmt('A room is %d rows, not %d',
      [RoomRows, Length(ARows)]);
  for var Row in ARows do
    if Length(Row) <> RoomCols then
      raise Exception.CreateFmt('A room row is %d cells, not %d: "%s"',
        [RoomCols, Length(Row), Row]);

  var Json := '{"id":"room","grid":{"width":16,"height":12},'
    + '"tilePalette":[],"backgrounds":[],"entities":[],'
    + '"tiles":{"screens":[{"screen":1,"rows":[' + TileRowsJson
    + '],"collision":[' + CollisionJson(ARows) + ']}]}}';

  var FileName := TPath.Combine(TPath.GetTempPath,
    'moon2d-room-' + TGUID.NewGuid.ToString + '.json');
  TFile.WriteAllText(FileName, Json, TEncoding.ASCII);
  try
    FLevel := TLevel.Create;
    FLevel.LoadFromFile(FileName);
  finally
    TFile.Delete(FileName);
  end;
end;

function TRoom.Place(const AMonsterId: string; ACol, ARow: Integer): TMonster;
begin
  var Placement := Default(TEntityPlacement);
  Placement.MonsterId := AMonsterId;
  Placement.Screen := 1;
  Placement.X := ACol;
  Placement.Y := ARow;

  Result := TMonster.Create(FRegistry.Find(AMonsterId), Default(TAnimSet),
    nil, nil, FLevel, FPads, Placement, 1.0);
  FMonsters.Add(Result);
end;

function RoomFromRows(const ARows: array of string): TRoom;
begin
  Result := TRoom.Create(ARows);
end;

end.
