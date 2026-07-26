{
  Game.Config - game configuration loaded from config.json.

  Replaces startcfg.txt (2008), a positional file where line 1 was width,
  line 2 was height, and reordering lines silently broke the game. Missing
  file, missing keys or broken values fall back to defaults - the game
  must always start.

  Moon 2D remake. Requires Delphi 12+.
}
unit Game.Config;

interface

type
  // The difficulty grade of 2008 ('Обычная'/'Сложная'/'Дикая', cfg[5]
  // of startcfg.txt). What each grade MEANS - hero hearts, monster
  // lives - is the game's business; this unit only stores the choice.
  TDifficulty = (dfNormal, dfHard, dfWild);
  TDifficultyGrades = set of TDifficulty;

  // The UI language (part 6). English is the release default; Russian
  // is the mother tongue of the 2008 original. What each language MEANS
  // - which dictionary file to read - is Localization's business.
  TLanguage = (lgEnglish, lgRussian);

  TGameConfig = record
    WindowWidth: Integer;
    WindowHeight: Integer;
    Fullscreen: Boolean;
    Vsync: Boolean;
    FpsCap: Integer; // frame cap for the no-vsync path; 0 = uncapped
    TickRate: Integer; // fixed logic updates per second
    Difficulty: TDifficulty;
    Language: TLanguage;
    class function Defaults: TGameConfig; static;
  end;

const
  // Protocol ids for the "difficulty" key of config.json - machine
  // vocabulary, hence const and English (captions live in the menu)
  DifficultyIds: array [TDifficulty] of string = ('normal', 'hard', 'wild');
  AllDifficultyGrades: TDifficultyGrades =
    [Low(TDifficulty)..High(TDifficulty)];
  // Protocol ids for the "language" key of config.json AND the names of
  // the dictionary files (lang\en.json) - one vocabulary, two readers
  LanguageIds: array [TLanguage] of string = ('en', 'ru');

// Reads AFileName; on any problem (absent file, broken JSON, unreadable
// content, values of the wrong type) returns Defaults - configuration
// is a preference, never a reason to crash.
function LoadGameConfig(const AFileName: string): TGameConfig;

// Writes the difficulty back into AFileName, keeping every other key.
// The 2008 menu saved startcfg.txt on every difficulty click (1448) -
// same behavior. A locked or read-only file is swallowed silently: the
// choice still applies for the session, only the memory of it is lost.
procedure SaveGameDifficulty(const AFileName: string; AValue: TDifficulty);

// Same contract as SaveGameDifficulty, for the "language" key: the menu
// click persists, a locked file loses only the memory of the choice.
procedure SaveGameLanguage(const AFileName: string; AValue: TLanguage);

implementation

uses
  System.SysUtils, System.IOUtils, System.JSON;

const
  // config.json keys read by both the loader and a saver - protocol
  // vocabulary shared by two places, hence constants (guide sect. 7)
  GameSectionKey = 'game';
  DifficultyKey = 'difficulty';
  LanguageKey = 'language';

class function TGameConfig.Defaults: TGameConfig;
begin
  Result.WindowWidth := 1024;
  Result.WindowHeight := 768;
  Result.Fullscreen := False;
  Result.Vsync := True;
  Result.FpsCap := 120; // comfortable ceiling, far below furnace mode
  // 33 Hz = the real cadence of the 2008 WM_Timer(20ms) on Windows
  // (~31 ms actual granularity); the whole game counts seconds in 33s
  // (CountdownTicksPerDigit). A lost config.json must not nearly
  // double the game speed.
  Result.TickRate := 33;
  Result.Difficulty := dfNormal;
  Result.Language := lgEnglish; // the release speaks English first
end;

// Deliberately lenient, in contrast to ParseGrades/GradeOf in
// Levels.Defs, which raises on an unknown id: a config is a preference,
// a level file is an asset. Do not merge the two loops.
function DifficultyFromId(const AId: string): TDifficulty;
begin
  for var Grade := Low(TDifficulty) to High(TDifficulty) do
    if SameText(AId, DifficultyIds[Grade]) then
      Exit(Grade);
  Result := dfNormal; // unknown or absent id - the safe default
end;

// Same lenient contract as DifficultyFromId.
function LanguageFromId(const AId: string): TLanguage;
begin
  for var Language := Low(TLanguage) to High(TLanguage) do
    if SameText(AId, LanguageIds[Language]) then
      Exit(Language);
  Result := lgEnglish; // unknown or absent id - the safe default
end;

// Parses AFileName as a JSON object. nil on an absent file, broken
// JSON or a non-object root. IO and encoding errors escape - each
// caller swallows them at its own level (both do, per their contracts).
function TryParseJsonObjectFile(const AFileName: string): TJSONObject;
begin
  Result := nil;
  if not FileExists(AFileName) then
    Exit;
  var RootValue := TJSONObject.ParseJSONValue(
    TFile.ReadAllText(AFileName, TEncoding.UTF8));
  if RootValue is TJSONObject then
    Result := TJSONObject(RootValue)
  else
    RootValue.Free; // nil-safe; someone else's JSON is not our config
end;

function LoadGameConfig(const AFileName: string): TGameConfig;
begin
  Result := TGameConfig.Defaults;
  try
    var Root := TryParseJsonObjectFile(AFileName);
    if Root = nil then
      Exit;
    try
      var Window := Root.GetValue<TJSONObject>('window', nil);
      if Assigned(Window) then
      begin
        Result.WindowWidth := Window.GetValue<Integer>('width',
          Result.WindowWidth);
        Result.WindowHeight := Window.GetValue<Integer>('height',
          Result.WindowHeight);
        Result.Fullscreen := Window.GetValue<Boolean>('fullscreen',
          Result.Fullscreen);
        Result.Vsync := Window.GetValue<Boolean>('vsync', Result.Vsync);
        Result.FpsCap := Window.GetValue<Integer>('fpsCap', Result.FpsCap);
      end;

      var Game := Root.GetValue<TJSONObject>(GameSectionKey, nil);
      if Assigned(Game) then
      begin
        Result.TickRate := Game.GetValue<Integer>('tickRate',
          Result.TickRate);
        Result.Difficulty :=
          DifficultyFromId(Game.GetValue<string>(DifficultyKey, ''));
        Result.Language :=
          LanguageFromId(Game.GetValue<string>(LanguageKey, ''));
      end;
    finally
      Root.Free;
    end;
  except
    // A locked file, garbage encoding or a value of the wrong type:
    // the contract says defaults, not a crash - and a clean slate,
    // not a half-applied mixture
    Result := TGameConfig.Defaults;
  end;

  if Result.TickRate < 1 then
    Result.TickRate := TGameConfig.Defaults.TickRate;
  // Negative is nonsense; 0 stays legal (= uncapped)
  if Result.FpsCap < 0 then
    Result.FpsCap := TGameConfig.Defaults.FpsCap;
end;

// The shared body of every "write one game key back" saver. Swallows
// any failure silently: see the SaveGameDifficulty interface comment.
procedure SaveGameKey(const AFileName, AKey, AValue: string);
begin
  try
    var Root := TryParseJsonObjectFile(AFileName);
    if Root = nil then
      Root := TJSONObject.Create; // absent or foreign file - start fresh
    try
      var Game := Root.GetValue<TJSONObject>(GameSectionKey, nil);
      if Game = nil then
      begin
        Game := TJSONObject.Create;
        Root.AddPair(GameSectionKey, Game);
      end;
      Game.RemovePair(AKey).Free; // Free on a nil pair is a no-op
      Game.AddPair(AKey, AValue);
      TFile.WriteAllText(AFileName, Root.Format(2), TEncoding.UTF8);
    finally
      Root.Free;
    end;
  except
    // Deliberately silent: see the interface comment
  end;
end;

procedure SaveGameDifficulty(const AFileName: string; AValue: TDifficulty);
begin
  SaveGameKey(AFileName, DifficultyKey, DifficultyIds[AValue]);
end;

procedure SaveGameLanguage(const AFileName: string; AValue: TLanguage);
begin
  SaveGameKey(AFileName, LanguageKey, LanguageIds[AValue]);
end;

end.
