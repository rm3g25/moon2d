{
  Game.Config - game configuration in two layers.

  config.json sits next to the exe and ships with every release; the
  game only reads it. settings.json lives in the user profile and holds
  what the player chose in the game; it overrides config.json key by
  key. A release unpacked over the old one keeps the player's choices,
  and those choices never reach the repository or an archive.

  Replaces startcfg.txt (2008), a positional file where line 1 was width,
  line 2 was height, and reordering lines silently broke the game. Missing
  file, missing keys or broken values fall back to the layer below - the
  game must always start.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.Config;
{$I ..\Moon2D.inc}

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
  // Protocol ids for the "difficulty" key of the config files - machine
  // vocabulary, hence const and English (captions live in the menu)
  DifficultyIds: array [TDifficulty] of string = ('normal', 'hard', 'wild');
  AllDifficultyGrades: TDifficultyGrades =
    [Low(TDifficulty)..High(TDifficulty)];
  // Protocol ids for the "language" key of the config files AND the names of
  // the dictionary files (lang\en.json) - one vocabulary, two readers
  LanguageIds: array [TLanguage] of string = ('en', 'ru');

// %APPDATA%\Moon2D\settings.json - the player's layer.
function UserSettingsFileName: string;

// Defaults, then AShippedFileName over them, then ASettingsFileName over
// that; each file overrides only the keys it holds. A file with any
// problem (absent, broken JSON, unreadable content, values of the wrong
// type) is skipped whole and the layers below stay - configuration is a
// preference, never a reason to crash.
function LoadGameConfig(const AShippedFileName, ASettingsFileName: string): TGameConfig;

// Writes the difficulty back into AFileName, keeping every other key.
// The 2008 menu saved startcfg.txt on every difficulty click (1448) -
// same behavior. A locked or read-only file is swallowed silently: the
// choice still applies for the session, only the memory of it is lost.
procedure SaveGameDifficulty(const AFileName: string; AValue: TDifficulty);

// Same contract as SaveGameDifficulty, for the "language" key: the menu
// click persists, a locked file loses only the memory of the choice.
procedure SaveGameLanguage(const AFileName: string; AValue: TLanguage);

// Same contract as SaveGameDifficulty, for the "fullscreen" key of the
// "window" section.
procedure SaveWindowFullscreen(const AFileName: string; AValue: Boolean);

implementation

uses
  System.SysUtils, System.IOUtils, System.JSON;

const
  // config.json keys read by both the loader and a saver - protocol
  // vocabulary shared by two places, hence constants (guide sect. 7)
  GameSectionKey = 'game';
  WindowSectionKey = 'window';
  FullscreenKey = 'fullscreen';
  DifficultyKey = 'difficulty';
  LanguageKey = 'language';

  SettingsFolderName = 'Moon2D';
  SettingsFileName = 'settings.json';

class function TGameConfig.Defaults: TGameConfig;
begin
  Result.WindowWidth := 1024;
  Result.WindowHeight := 768;
  // Players expect fullscreen on launch, and config.json ships with
  // the same value. This default only decides what happens when
  // config.json is missing or unreadable.
  Result.Fullscreen := True;
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

function UserSettingsFileName: string;
begin
  // GetHomePath is CSIDL_APPDATA on Windows: per user and writable
  // without elevation, unlike a Program Files folder the game may be
  // unpacked into
  Result := TPath.Combine(TPath.Combine(TPath.GetHomePath,
    SettingsFolderName), SettingsFileName);
end;

// Reads the keys AFileName holds over ABase; a key the file lacks keeps
// the value ABase had. A layer applies whole or not at all, never as a
// half-applied mixture.
function OverlayConfigFile(const ABase: TGameConfig;
  const AFileName: string): TGameConfig;
begin
  Result := ABase;
  try
    var Root := TryParseJsonObjectFile(AFileName);
    if Root = nil then
      Exit;
    try
      var Window := Root.GetValue<TJSONObject>(WindowSectionKey, nil);
      if Assigned(Window) then
      begin
        Result.WindowWidth := Window.GetValue<Integer>('width',
          Result.WindowWidth);
        Result.WindowHeight := Window.GetValue<Integer>('height',
          Result.WindowHeight);
        Result.Fullscreen := Window.GetValue<Boolean>(FullscreenKey,
          Result.Fullscreen);
        Result.Vsync := Window.GetValue<Boolean>('vsync', Result.Vsync);
        Result.FpsCap := Window.GetValue<Integer>('fpsCap', Result.FpsCap);
      end;

      var Game := Root.GetValue<TJSONObject>(GameSectionKey, nil);
      if Assigned(Game) then
      begin
        Result.TickRate := Game.GetValue<Integer>('tickRate',
          Result.TickRate);
        // The current id as the fallback: an absent key must keep the
        // value of the layer below, not reset it
        var DifficultyId := Game.GetValue<string>(DifficultyKey,
          DifficultyIds[Result.Difficulty]);
        Result.Difficulty := DifficultyFromId(DifficultyId);
        var LanguageId := Game.GetValue<string>(LanguageKey,
          LanguageIds[Result.Language]);
        Result.Language := LanguageFromId(LanguageId);
      end;
    finally
      Root.Free;
    end;
  except
    // A locked file, garbage encoding or a value of the wrong type:
    // the contract says the layers below, not a crash
    Result := ABase;
  end;
end;

function LoadGameConfig(const AShippedFileName, ASettingsFileName: string): TGameConfig;
begin
  Result := OverlayConfigFile(TGameConfig.Defaults, AShippedFileName);
  Result := OverlayConfigFile(Result, ASettingsFileName);

  if Result.TickRate < 1 then
    Result.TickRate := TGameConfig.Defaults.TickRate;
  // Negative is nonsense; 0 stays legal (= uncapped)
  if Result.FpsCap < 0 then
    Result.FpsCap := TGameConfig.Defaults.FpsCap;
end;

// The shared body of every "write one key" saver. Owns AValue on every
// path, the early exits included. Swallows any failure silently: see
// the SaveGameDifficulty interface comment.
procedure SaveKey(const AFileName, ASection, AKey: string; AValue: TJSONValue);
begin
  try
    try
      var Root := TryParseJsonObjectFile(AFileName);
      if Root = nil then
      begin
        // nil means three things here - absent file, broken JSON,
        // non-object root - and only the first is safe to act on. A
        // file that exists but will not parse still holds the player's
        // settings; overwriting it trades an unreadable config for an
        // empty one. Losing the menu click is the cheaper failure.
        if FileExists(AFileName) then
          Exit;
        Root := TJSONObject.Create; // genuinely absent - start fresh
      end;
      try
        var Section := Root.GetValue<TJSONObject>(ASection, nil);
        if Section = nil then
        begin
          Section := TJSONObject.Create;
          Root.AddPair(ASection, Section);
        end;
        Section.RemovePair(AKey).Free; // Free on a nil pair is a no-op
        Section.AddPair(AKey, AValue);
        AValue := nil; // Root owns it now and frees it below

        // The first save of a fresh profile has no folder to write into
        ForceDirectories(ExtractFileDir(AFileName));
        TFile.WriteAllText(AFileName, Root.Format(2), TEncoding.UTF8);
      finally
        Root.Free;
      end;
    finally
      AValue.Free; // nil once Root took it
    end;
  except
    // Deliberately silent: see the interface comment
  end;
end;

procedure SaveGameDifficulty(const AFileName: string; AValue: TDifficulty);
begin
  SaveKey(AFileName, GameSectionKey, DifficultyKey,
    TJSONString.Create(DifficultyIds[AValue]));
end;

procedure SaveGameLanguage(const AFileName: string; AValue: TLanguage);
begin
  SaveKey(AFileName, GameSectionKey, LanguageKey,
    TJSONString.Create(LanguageIds[AValue]));
end;

procedure SaveWindowFullscreen(const AFileName: string; AValue: Boolean);
begin
  SaveKey(AFileName, WindowSectionKey, FullscreenKey, TJSONBool.Create(AValue));
end;

end.
