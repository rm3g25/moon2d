{
  Levels.Defs - level data loaded from level JSON (output of
  convert_level.py, which folds the 2008 six-file format into one).

  A level is: a tile grid (screens of 16x12 cells), a tile palette
  (BMP names), background changes, music, and entity placements with
  optional per-placement overrides (speed, lives, shooting) and triggers
  (location titles, music changes) - faithfully carrying over the
  component system the 2008 .mon format invented by accident.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Levels.Defs;
{$I Moon2D.inc}

interface

uses
  System.SysUtils, System.Classes, System.IOUtils,
  System.Generics.Collections, System.JSON, Game.Config,
  Localization;

const
  EmptyTile = 0; // grid value 0 = nothing; N >= 1 -> TilePalette[N - 1]

type
  ELevelError = class(Exception);

  TEntityOverrides = record
    HasDirection: Boolean;
    Direction: Integer;
    HasSpeed: Boolean;
    Speed: Integer;
    HasLives: Boolean;
    Lives: Integer;
    HasCanShoot: Boolean;
    CanShoot: Boolean;
  end;

  // A level number that may differ per difficulty grade. In JSON either
  // a plain number (one value for all grades) or an object keyed by the
  // config protocol ids:
  //   "gravelBoss": 75
  //   "gravelBoss": {"normal": 75, "hard": 125, "wild": 200}
  // Grades missing from the object inherit the "normal" value. Levels
  // load once and difficulty changes on restart, so all three values
  // are parsed up front and the game picks its grade at use time.
  TDifficultyValue = record
    Values: array [TDifficulty] of Integer;
    class function Uniform(AValue: Integer): TDifficultyValue; static;
    function ForGrade(AGrade: TDifficulty): Integer;
  end;

  TEntityTriggers = record
    // The three player-facing texts are localized content (part 6.3):
    // base JSON field = Russian, 'En' sibling = English, absent
    // sibling falls back to the base (see Localization)
    BigMessage: TLocalizedText;   // location title; '' = none
    SmallMessage: TLocalizedText; // minor caption; '' = none
    HintText: TLocalizedText;     // one-shot hint ('_string:' of .mon)
    ChangeMusic: string;  // music file to switch to; '' = none
    // Hero reposition on screen entry (vertical transitions in tunnels).
    HasHeroX: Boolean;
    HeroX: Integer;
    HasHeroY: Boolean;
    HeroY: Integer;
    // The gravel trial ('Атака грейвелов' of moon.dpr 955-971): the
    // value is the wave quota, per difficulty since part 5.3
    HasGravelBoss: Boolean;
    GravelQuota: TDifficultyValue;
  end;

  TEntityPlacement = record
    MonsterId: string;
    Screen: Integer;    // 1-based, as the 2008 format counted
    X: Integer;         // sprite-grid coordinates within the screen
    Y: Integer;
    SpriteList: string; // .mns file
    // Which difficulty grades this entity exists on (Doom skill-flag
    // idiom). JSON: "difficulty": ["hard", "wild"]; absent = all.
    // A per-grade POSITION is two entities with disjoint grade sets.
    Grades: TDifficultyGrades;
    Overrides: TEntityOverrides;
    Triggers: TEntityTriggers;
  end;

  TBackgroundChange = record
    FromScreen: Integer;
    Image: string;
  end;

  TLevel = class
  private
    FId: string;
    FTitle: TLocalizedText;
    FAssetsDir: string;
    FSpriteSets: TArray<string>;
    FMusic: string;
    FIntroText: TLocalizedText;
    FGridWidth: Integer;
    FGridHeight: Integer;
    FScreenCount: Integer;
    FTiles: TArray<TArray<TArray<Integer>>>; // [screen][row][col], 0-based
    FCollision: TArray<TArray<string>>;       // [screen][row], '1' = solid
    FTilePalette: TArray<string>;
    FBackgrounds: TArray<TBackgroundChange>;
    FEntities: TArray<TEntityPlacement>;
    procedure ParseRoot(const ARoot: TJSONObject);
    procedure ParseTiles(const ATiles: TJSONObject);
    procedure ParseEntities(const AArr: TJSONArray);
    procedure ParseBackgrounds(const AArr: TJSONArray);
  public
    procedure LoadFromFile(const AFileName: string);

    // Tile palette index at a cell; EmptyTile when nothing is there.
    // AScreen is 1-based, AX/AY are 0-based within the screen.
    function TileAt(AScreen, AX, AY: Integer): Integer;
    // Collision layer: True = solid wall (the .msv first byte of a pair).
    function SolidAt(AScreen, AX, AY: Integer): Boolean;
    // Background image active on a given screen (last change wins).
    function BackgroundFor(AScreen: Integer): string;

    property Id: string read FId;
    property Title: TLocalizedText read FTitle;
    property AssetsDir: string read FAssetsDir;
    // Environment sprite sets, in resolution order: the first declared
    // set containing a name wins. Tiles only - screen backdrops follow
    // the <assetsDir>-backdrops convention and never appear here.
    property SpriteSets: TArray<string> read FSpriteSets;
    property Music: string read FMusic;
    // Story text shown before the level starts; '' = jump straight in.
    property IntroText: TLocalizedText read FIntroText;
    property GridWidth: Integer read FGridWidth;
    property GridHeight: Integer read FGridHeight;
    property ScreenCount: Integer read FScreenCount;
    property TilePalette: TArray<string> read FTilePalette;
    property Backgrounds: TArray<TBackgroundChange> read FBackgrounds;
    property Entities: TArray<TEntityPlacement> read FEntities;
  end;

implementation

resourcestring
  SLevelFileNotFound = 'Level file not found: %s';
  SLevelParseFailed = 'Level "%s": invalid JSON';
  SLevelBadRowWidth = 'Level "%s": screen %d row %d has %d cells, '
    + 'expected %d';
  SLevelBadRowCount = 'Level "%s": screen %d has %d %s rows, expected %d';
  SLevelBadCollision = 'Level "%s": screen %d collision row %d is '
    + '%d chars, expected %d';
  SLevelBadScreen = 'TileAt: screen %d out of 1..%d';
  SLevelBadGrade = 'Level entity "%s": unknown difficulty id "%s"';

class function TDifficultyValue.Uniform(AValue: Integer): TDifficultyValue;
begin
  for var Grade := Low(TDifficulty) to High(TDifficulty) do
    Result.Values[Grade] := AValue;
end;

function TDifficultyValue.ForGrade(AGrade: TDifficulty): Integer;
begin
  Result := Values[AGrade];
end;

// The single reader for per-difficulty numbers - every future field
// that wants a difficulty split (override lives, trigger values, ...)
// plugs in here. False = key absent or of a shape we do not speak.
function TryReadDifficultyValue(const AObj: TJSONObject; const AKey: string;
  out AValue: TDifficultyValue): Boolean;
begin
  var Raw := AObj.GetValue(AKey);
  if Raw = nil then
    Exit(False);

  if Raw is TJSONNumber then
  begin
    AValue := TDifficultyValue.Uniform(TJSONNumber(Raw).AsInt);
    Exit(True);
  end;

  if Raw is TJSONObject then
  begin
    // Missing grades inherit "normal" - a level may split only where
    // it cares. The ids are the config protocol vocabulary.
    var Base := TJSONObject(Raw).GetValue<Integer>(DifficultyIds[dfNormal], 0);
    for var Grade := Low(TDifficulty) to High(TDifficulty) do
      AValue.Values[Grade] :=
        TJSONObject(Raw).GetValue<Integer>(DifficultyIds[Grade], Base);
    Exit(True);
  end;

  Result := False; // a string or an array here is a level-file typo
end;

// "difficulty": ["hard", "wild"] -> a grade set; nil array = all grades.
// A typo raises instead of silently thinning a grade: a monster
// mysteriously absent on 'wildd' is a debugging season, not a feature.
function ParseGrades(const AArr: TJSONArray;
  const AEntityId: string): TDifficultyGrades;

  function GradeOf(const AId: string): TDifficulty;
  begin
    for var Grade := Low(TDifficulty) to High(TDifficulty) do
      if SameText(AId, DifficultyIds[Grade]) then
        Exit(Grade);
    raise ELevelError.CreateFmt(SLevelBadGrade, [AEntityId, AId]);
  end;

begin
  if AArr = nil then
    Exit(AllDifficultyGrades);
  Result := [];
  for var Item in AArr do
    Include(Result, GradeOf(Item.Value));
end;

function TLevel.TileAt(AScreen, AX, AY: Integer): Integer;
begin
  if (AScreen < 1) or (AScreen > FScreenCount) then
    raise ELevelError.CreateFmt(SLevelBadScreen, [AScreen, FScreenCount]);
  if (AX < 0) or (AX >= FGridWidth) or (AY < 0) or (AY >= FGridHeight) then
    Exit(EmptyTile); // off-grid is empty, callers need not clamp

  Result := FTiles[AScreen - 1][AY][AX];
end;

function TLevel.BackgroundFor(AScreen: Integer): string;
begin
  Result := '';
  for var Change in FBackgrounds do
    if Change.FromScreen <= AScreen then
      Result := Change.Image;
end;

procedure TLevel.LoadFromFile(const AFileName: string);
var
  Root: TJSONObject;
begin
  if not FileExists(AFileName) then
    raise ELevelError.CreateFmt(SLevelFileNotFound, [AFileName]);

  Root := TJSONObject.ParseJSONValue(
    TFile.ReadAllText(AFileName, TEncoding.UTF8)) as TJSONObject;
  if Root = nil then
    raise ELevelError.CreateFmt(SLevelParseFailed, [AFileName]);
  try
    ParseRoot(Root);
  finally
    Root.Free;
  end;
end;

procedure TLevel.ParseRoot(const ARoot: TJSONObject);
begin
  FId := ARoot.GetValue<string>('id');
  FTitle := ReadLocalizedText(ARoot, 'title', FId);
  FAssetsDir := ARoot.GetValue<string>('assetsDir', '');

  FSpriteSets := [];
  var SetNames: TJSONArray;
  if ARoot.TryGetValue<TJSONArray>('spriteSets', SetNames) then
    for var Name in SetNames do
      FSpriteSets := FSpriteSets + [Name.Value];
  FMusic := ARoot.GetValue<string>('music', '');
  FIntroText := ReadLocalizedText(ARoot, 'introText');

  var Grid := ARoot.GetValue<TJSONObject>('grid');
  FGridWidth := Grid.GetValue<Integer>('width');
  FGridHeight := Grid.GetValue<Integer>('height');

  var PaletteArr := ARoot.GetValue<TJSONArray>('tilePalette');
  SetLength(FTilePalette, PaletteArr.Count);
  for var i := 0 to PaletteArr.Count - 1 do
    FTilePalette[i] := PaletteArr.Items[i].Value;

  ParseTiles(ARoot.GetValue<TJSONObject>('tiles'));
  ParseBackgrounds(ARoot.GetValue<TJSONArray>('backgrounds'));
  ParseEntities(ARoot.GetValue<TJSONArray>('entities'));
end;

function TLevel.SolidAt(AScreen, AX, AY: Integer): Boolean;
begin
  if (AScreen < 1) or (AScreen > FScreenCount) then
    raise ELevelError.CreateFmt(SLevelBadScreen, [AScreen, FScreenCount]);
  if (AX < 0) or (AX >= FGridWidth) or (AY < 0) or (AY >= FGridHeight) then
    Exit(False); // off-grid is air, callers need not clamp

  Result := FCollision[AScreen - 1][AY][AX + 1] = '1'; // string is 1-based
end;

procedure TLevel.ParseTiles(const ATiles: TJSONObject);
var
  ScreensArr: TJSONArray;
begin
  ScreensArr := ATiles.GetValue<TJSONArray>('screens');
  FScreenCount := ScreensArr.Count;
  SetLength(FTiles, FScreenCount);
  SetLength(FCollision, FScreenCount);

  for var s := 0 to FScreenCount - 1 do
  begin
    var ScreenObj := ScreensArr.Items[s] as TJSONObject;
    // The tile rows were always measured; the collision layer sneaked
    // past unweighed - and SolidAt reads it by raw char index in the
    // hot path. With the Phase 2 editor WRITING these files, malformed
    // collision must die here, at load, not garbage-read mid-battle.
    var CollArr := ScreenObj.GetValue<TJSONArray>('collision');
    if CollArr.Count <> FGridHeight then
      raise ELevelError.CreateFmt(SLevelBadRowCount,
        [FId, s + 1, CollArr.Count, 'collision', FGridHeight]);
    SetLength(FCollision[s], CollArr.Count);
    for var c := 0 to CollArr.Count - 1 do
    begin
      FCollision[s][c] := CollArr.Items[c].Value;
      if Length(FCollision[s][c]) <> FGridWidth then
        raise ELevelError.CreateFmt(SLevelBadCollision,
          [FId, s + 1, c + 1, Length(FCollision[s][c]), FGridWidth]);
    end;
    var RowsArr := ScreenObj.GetValue<TJSONArray>('rows');
    if RowsArr.Count <> FGridHeight then
      raise ELevelError.CreateFmt(SLevelBadRowCount,
        [FId, s + 1, RowsArr.Count, 'tile', FGridHeight]);
    SetLength(FTiles[s], RowsArr.Count);

    for var y := 0 to RowsArr.Count - 1 do
    begin
      var Cells := RowsArr.Items[y].Value.Split([',']);
      if Length(Cells) <> FGridWidth then
        raise ELevelError.CreateFmt(SLevelBadRowWidth,
          [FId, s + 1, y + 1, Length(Cells), FGridWidth]);

      SetLength(FTiles[s][y], FGridWidth);
      for var x := 0 to FGridWidth - 1 do
        FTiles[s][y][x] := StrToInt(Cells[x]);
    end;
  end;
end;

procedure TLevel.ParseBackgrounds(const AArr: TJSONArray);
begin
  SetLength(FBackgrounds, AArr.Count);
  for var i := 0 to AArr.Count - 1 do
  begin
    var Obj := AArr.Items[i] as TJSONObject;
    FBackgrounds[i].FromScreen := Obj.GetValue<Integer>('fromScreen');
    FBackgrounds[i].Image := Obj.GetValue<string>('image');
  end;
end;

// Reads one optional 'overrides' object; captures nothing - a free
// function per the canon, keeping ParseEntities a table of contents.
procedure ReadOverrides(const AObj: TJSONObject;
  var AOut: TEntityOverrides);
begin
  AOut := Default(TEntityOverrides);
  var Ov := AObj.GetValue<TJSONObject>('overrides', nil);
  if Ov = nil then
    Exit;

  AOut.HasDirection := Ov.TryGetValue<Integer>('direction', AOut.Direction);
  AOut.HasSpeed := Ov.TryGetValue<Integer>('speed', AOut.Speed);
  AOut.HasLives := Ov.TryGetValue<Integer>('lives', AOut.Lives);
  AOut.HasCanShoot := Ov.TryGetValue<Boolean>('canShoot', AOut.CanShoot);
end;

procedure ReadTriggers(const AObj: TJSONObject; var AOut: TEntityTriggers);
begin
  AOut := Default(TEntityTriggers);
  // Not 'Tr' - that name now belongs to the dictionary lookup of
  // Localization, and a shadow here would be a mine for the reader
  var TriggersObj := AObj.GetValue<TJSONObject>('triggers', nil);
  if TriggersObj = nil then
    Exit;

  AOut.BigMessage := ReadLocalizedText(TriggersObj, 'bigMessage');
  AOut.SmallMessage := ReadLocalizedText(TriggersObj, 'smallMessage');
  AOut.HintText := ReadLocalizedText(TriggersObj, 'hintText');
  AOut.ChangeMusic := TriggersObj.GetValue<string>('changeMusic', '');
  AOut.HasHeroX := TriggersObj.TryGetValue<Integer>('heroX', AOut.HeroX);
  AOut.HasHeroY := TriggersObj.TryGetValue<Integer>('heroY', AOut.HeroY);
  AOut.HasGravelBoss :=
    TryReadDifficultyValue(TriggersObj, 'gravelBoss', AOut.GravelQuota);
end;

procedure TLevel.ParseEntities(const AArr: TJSONArray);
begin
  SetLength(FEntities, AArr.Count);
  for var i := 0 to AArr.Count - 1 do
  begin
    var Obj := AArr.Items[i] as TJSONObject;
    FEntities[i].MonsterId := Obj.GetValue<string>('monsterId');
    FEntities[i].Screen := Obj.GetValue<Integer>('screen');
    FEntities[i].X := Obj.GetValue<Integer>('x');
    FEntities[i].Y := Obj.GetValue<Integer>('y');
    FEntities[i].SpriteList := Obj.GetValue<string>('spriteList', '');
    FEntities[i].Grades := ParseGrades(
      Obj.GetValue<TJSONArray>('difficulty', nil), FEntities[i].MonsterId);
    ReadOverrides(Obj, FEntities[i].Overrides);
    ReadTriggers(Obj, FEntities[i].Triggers);
  end;
end;

end.
