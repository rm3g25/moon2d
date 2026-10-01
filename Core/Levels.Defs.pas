{
  Levels.Defs - level data loaded from level JSON (output of
  convert_level.py, which folds the 2008 six-file format into one).

  A level is: a tile grid (screens of 16x12 cells), a tile palette
  (BMP names), background changes, free-form objects over the backdrop
  (art of any shape, no collision), dynamic objects living beside them
  (Levels.Dynamics), music, and entity placements with
  optional per-placement overrides (speed, lives, shooting) and triggers
  (location titles, music changes) - faithfully carrying over the
  component system the 2008 .mon format invented by accident.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Levels.Defs;
{$I ..\Moon2D.inc}

interface

uses
  System.SysUtils, System.Classes, System.IOUtils,
  System.Generics.Collections, System.JSON, Game.Config,
  Localization, Levels.Events, Levels.Tint, Levels.Dynamics;

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
    // Names the placement for the level's events ("allDead" waits for
    // every body carrying the tag). JSON: "tag": "labGuard"; '' = none.
    Tag: string;
  end;

  TBackgroundChange = record
    FromScreen: Integer;
    Image: string;
    Tint: TColorTint;
  end;

  // Free-form art over the backdrop: a picture of any shape at any point
  // of one screen. No collision - the grid alone decides where the hero
  // stands, so a ship on the floor is scenery the floor tiles hold up.
  TLevelObject = record
    Sprite: string; // in <assetsDir>-objects.mset
    Screen: Integer; // 1-based, as the placements count
    // Top-left corner and width in screen units; the height follows the
    // art's aspect, so a picture is never stretched
    X: Integer;
    Y: Integer;
    Width: Integer;
    Tint: TColorTint;
    // Names the object for the dynamic objects hung on it: "tag": "ship";
    // '' = none. One picture drawn on several screens carries the same
    // tag on each.
    Tag: string;
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
    FObjects: TArray<TLevelObject>;
    FEntities: TArray<TEntityPlacement>;
    FEvents: TArray<TLevelEvent>;
    FDynamics: TDynamicObjects;
    procedure ParseRoot(const ARoot: TJSONObject);
    procedure ParseTiles(const ATiles: TJSONObject);
    procedure ParseEntities(const AArr: TJSONArray);
    procedure ParseBackgrounds(const AArr: TJSONArray);
    procedure ParseObjects(const AArr: TJSONArray);
    procedure CheckEvents;
    procedure CheckEventTargets(const AEvent: TLevelEvent);
    procedure CheckEventTarget(const AEventId: string;
      const AAction: TEventAction);
    procedure CheckDynamics;
    procedure CheckDynamicScreens(const APlacement: TDynamicPlacement);
    procedure CheckDynamicParent(const ATag: string);
    procedure CheckMonsterParent(const ATag: string);
  public
    destructor Destroy; override;
    procedure LoadFromFile(const AFileName: string);

    // Tile palette index at a cell; EmptyTile when nothing is there.
    // AScreen is 1-based, AX/AY are 0-based within the screen.
    function TileAt(AScreen, AX, AY: Integer): Integer;
    // Collision layer: True = solid wall (the .msv first byte of a pair).
    function SolidAt(AScreen, AX, AY: Integer): Boolean;
    // Backdrop active on a given screen (last change wins); Image = ''
    // when the level defines none.
    function BackgroundFor(AScreen: Integer): TBackgroundChange;

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
    // Every screen's objects, in file order - later ones draw over
    // earlier ones
    property Objects: TArray<TLevelObject> read FObjects;
    property Entities: TArray<TEntityPlacement> read FEntities;
    // The level's events, in file order (Levels.Events); the game runs
    // them through Events.Director
    property Events: TArray<TLevelEvent> read FEvents;
    // Owned by the level and kept through a restart: a lamp keeps its
    // rhythm; only what a re-armed event changed goes back
    property Dynamics: TDynamicObjects read FDynamics;
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
  SLevelEventBadScreen = 'Level "%s": event "%s" sits on screen %d of %d';
  SLevelEventTagUnknown = 'Level "%s": event "%s" waits for tag "%s", '
    + 'which no entity carries';
  SLevelObjectBadScreen = 'Level "%s": object "%s" sits on screen %d of %d';
  SLevelObjectBadWidth = 'Level "%s": object "%s" is %d units wide';
  SLevelDynamicBadScreen = 'Level "%s": a dynamic object stands on screens '
    + '%d..%d of %d';
  SLevelEventTargetUnknown = 'Level "%s": event "%s" turns "%s", '
    + 'which no dynamic object carries';
  SLevelEventSunUnknown = 'Level "%s": event "%s" turns the sun of "%s", '
    + 'which no globe carries';
  SLevelDynamicNoParent = 'Level "%s": a dynamic object hangs on "%s", '
    + 'a tag no object and no entity carries';
  SLevelDynamicTwoKinds = 'Level "%s": tag "%s" is carried by an object '
    + 'and an entity - a dynamic object hung on it cannot tell which';
  SLevelDynamicTwoMonsters = 'Level "%s": two monsters tagged "%s" live '
    + 'on one difficulty - a dynamic object hung on it cannot tell which';
  SLevelDynamicTwoParents = 'Level "%s": two objects tagged "%s" stand '
    + 'on screen %d - a dynamic object hung on it cannot tell which';

class function TDifficultyValue.Uniform(AValue: Integer): TDifficultyValue;
begin
  for var Grade := Low(TDifficulty) to High(TDifficulty) do
    Result.Values[Grade] := AValue;
end;

function TDifficultyValue.ForGrade(AGrade: TDifficulty): Integer;
begin
  Result := Values[AGrade];
end;

destructor TLevel.Destroy;
begin
  FDynamics.Free;
  inherited;
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

function TLevel.BackgroundFor(AScreen: Integer): TBackgroundChange;
begin
  Result := Default(TBackgroundChange);
  for var Change in FBackgrounds do
    if Change.FromScreen <= AScreen then
      Result := Change;
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
  ParseObjects(ARoot.GetValue<TJSONArray>('objects', nil));
  ParseEntities(ARoot.GetValue<TJSONArray>('entities'));
  // Dynamics first: an event may name a dynamic object's tag
  FDynamics := ParseDynamics(ARoot, FId);
  CheckDynamics;
  FEvents := ParseLevelEvents(ARoot, FId);
  CheckEvents;
end;

function AnyPlacementTagged(const AEntities: TArray<TEntityPlacement>;
  const ATag: string): Boolean;
begin
  for var Entity in AEntities do
    if Entity.Tag = ATag then
      Exit(True);
  Result := False;
end;

// An event off the screen list never fires; one watching a tag no
// entity carries fires at once or never; one turning a tag no dynamic
// object carries turns nothing. Typos all - they die at load, not
// mid-level.
procedure TLevel.CheckEvents;
begin
  for var Event in FEvents do
  begin
    if (Event.Screen < 1) or (Event.Screen > FScreenCount) then
      raise ELevelError.CreateFmt(SLevelEventBadScreen,
        [FId, Event.Id, Event.Screen, FScreenCount]);
    if (Event.Condition in TaggedConditions) and
      not AnyPlacementTagged(FEntities, Event.Tag) then
      raise ELevelError.CreateFmt(SLevelEventTagUnknown,
        [FId, Event.Id, Event.Tag]);
    CheckEventTargets(Event);
  end;
end;

procedure TLevel.CheckEventTargets(const AEvent: TLevelEvent);
begin
  for var Action in AEvent.Actions do
    CheckEventTarget(AEvent.Id, Action);
end;

procedure TLevel.CheckEventTarget(const AEventId: string;
  const AAction: TEventAction);
begin
  case AAction.Kind of
    eaIntensity:
      if not FDynamics.AnyTagged(AAction.Target) then
        raise ELevelError.CreateFmt(SLevelEventTargetUnknown,
          [FId, AEventId, AAction.Target]);
    eaSun:
      if not FDynamics.AnyTagged(AAction.Target, TSkyGlobe) then
        raise ELevelError.CreateFmt(SLevelEventSunUnknown,
          [FId, AEventId, AAction.Target]);
  end;
end;

// A nailed object off the screen list never shows; a parent tag no
// object and no monster carries leaves its child nowhere. Typos both -
// they die at load, as the events' do.
procedure TLevel.CheckDynamics;
begin
  for var DynamicObject in FDynamics do
  begin
    var Placement := DynamicObject.Placement;
    if Placement.Parent <> '' then
      CheckDynamicParent(Placement.Parent)
    else
      CheckDynamicScreens(Placement);
  end;
end;

procedure TLevel.CheckDynamicScreens(const APlacement: TDynamicPlacement);
begin
  var Starts := (APlacement.Screen >= 1) and
    (APlacement.Screen <= APlacement.LastScreen);
  if Starts and (APlacement.LastScreen <= FScreenCount) then
    Exit;
  raise ELevelError.CreateFmt(SLevelDynamicBadScreen,
    [FId, APlacement.Screen, APlacement.LastScreen, FScreenCount]);
end;

procedure TLevel.CheckDynamicParent(const ATag: string);
var
  Carried: TArray<Boolean>; // per screen, 0-based
begin
  SetLength(Carried, FScreenCount);
  var Found := False;
  for var Placed in FObjects do
  begin
    if Placed.Tag <> ATag then
      Continue;
    if Carried[Placed.Screen - 1] then
      raise ELevelError.CreateFmt(SLevelDynamicTwoParents,
        [FId, ATag, Placed.Screen]);
    Carried[Placed.Screen - 1] := True;
    Found := True;
  end;

  var OnEntity := AnyPlacementTagged(FEntities, ATag);
  if Found and OnEntity then
    raise ELevelError.CreateFmt(SLevelDynamicTwoKinds, [FId, ATag]);
  if not (Found or OnEntity) then
    raise ELevelError.CreateFmt(SLevelDynamicNoParent, [FId, ATag]);
  if OnEntity then
    CheckMonsterParent(ATag);
end;

// Placements with one tag on disjoint grades are one monster per
// difficulty; on a shared grade they live together, and a dynamic
// object hung on the tag would follow whichever the field lists first
procedure TLevel.CheckMonsterParent(const ATag: string);
begin
  var Seen: TDifficultyGrades := [];
  for var Entity in FEntities do
  begin
    if Entity.Tag <> ATag then
      Continue;
    if Seen * Entity.Grades <> [] then
      raise ELevelError.CreateFmt(SLevelDynamicTwoMonsters, [FId, ATag]);
    Seen := Seen + Entity.Grades;
  end;
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
    FBackgrounds[i].Tint := ReadTint(Obj, FBackgrounds[i].Image);
  end;
end;

// Absent section = a level of tiles alone. An object off the screen
// list would never show and a width of zero would draw nothing - both
// are typos, and they die at load.
procedure TLevel.ParseObjects(const AArr: TJSONArray);
begin
  FObjects := [];
  if AArr = nil then
    Exit;

  for var Item in AArr do
  begin
    var Obj := Item as TJSONObject;
    var Placed: TLevelObject;
    Placed.Sprite := Obj.GetValue<string>('sprite');
    Placed.Screen := Obj.GetValue<Integer>('screen');
    Placed.X := Obj.GetValue<Integer>('x');
    Placed.Y := Obj.GetValue<Integer>('y');
    Placed.Width := Obj.GetValue<Integer>('width');
    Placed.Tint := ReadTint(Obj, Placed.Sprite);
    Placed.Tag := Obj.GetValue<string>('tag', '');

    if (Placed.Screen < 1) or (Placed.Screen > FScreenCount) then
      raise ELevelError.CreateFmt(SLevelObjectBadScreen,
        [FId, Placed.Sprite, Placed.Screen, FScreenCount]);
    if Placed.Width <= 0 then
      raise ELevelError.CreateFmt(SLevelObjectBadWidth,
        [FId, Placed.Sprite, Placed.Width]);

    FObjects := FObjects + [Placed];
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
    FEntities[i].Tag := Obj.GetValue<string>('tag', '');
  end;
end;

end.
