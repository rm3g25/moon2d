{
  Localization - the language dictionaries (part 6).

  Every string a PLAYER reads lives in lang\<id>.json (en, ru), one flat
  key-value object per language. The keys below are protocol vocabulary:
  the constants keep the S-names of the resourcestrings they replaced,
  so a call site reads exactly as before, only wrapped in Tr().

  Loading philosophy is TSoundBank's: strict on arrival. LoadLanguage
  validates the file against the full key roster and dies loudly at
  startup on the first missing key - a typo in a dictionary must never
  survive until the boss fight. Extra keys are ignored (a file may
  already carry entries for a future chapter).

  What does NOT live here: developer-facing error messages (asset
  loaders, SDL failures). Those stay English resourcestrings in their
  units - they surface in crash boxes and logs, must stay greppable,
  and can fire before any dictionary exists.

  The Russian values are the 2008 originals, verbatim where the
  archaeology says so; per-key notes sit at the key constants because
  JSON has no comments.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Localization;
{$I Moon2D.inc}

interface

uses
  System.SysUtils, System.JSON, Game.Config;

type
  ELocalizationError = class(Exception);

  // One piece of CONTENT text (level titles, intro stories, screen
  // messages, monster texts) in every language - as opposed to the UI
  // strings keyed below, which live in lang\*.json. The base JSON field
  // is Russian (the 2008 mother tongue); siblings carry a language
  // suffix ('titleEn') - the monsters.json convention. A missing
  // sibling falls back to the base at parse time, so Current never
  // returns a hole.
  TLocalizedText = record
    Values: array [TLanguage] of string;
    // The value for the language of the active dictionary
    function Current: string;
  end;

const
  // --- In-game texts (composition root / HUD / cinematics) ---
  SFellIntoPit = 'fellIntoPit';
  // The campaign-end screen (part 5.4); the author line matches the
  // LinkedIn profile name and stays Latin in both languages
  SEndingLine1 = 'endingLine1';
  SEndingLine2 = 'endingLine2';
  SEndingLine3 = 'endingLine3';
  SEndingLine4 = 'endingLine4';
  SEndingLine5 = 'endingLine5';
  SEndingAuthor = 'endingAuthor';
  SEndingMenu = 'endingMenu';
  SHitByBullet = 'hitByBullet';
  SHurtByMonster = 'hurtByMonster';
  SStreakBigTen = 'streakBigTen';
  SStreakSmallTen = 'streakSmallTen';
  SStreakBigInvincible = 'streakBigInvincible';
  SStreakSmallInvincible = 'streakSmallInvincible';
  SStreakBigWarGod = 'streakBigWarGod';
  SStreakSmallWarGod = 'streakSmallWarGod';
  SScoreFmt = 'scoreFmt';
  SPressAnyKey = 'pressAnyKey';
  SEvolution = 'evolution';
  SIceForm = 'iceForm';
  SIceFormPerk = 'iceFormPerk';
  // 2008 tick-20 wave said 'регенерировало' - typo unified in ru,
  // deviation logged (part 3)
  SIceRegen = 'iceRegen';
  SBonusHealth = 'bonusHealth';
  SBonusFireRain = 'bonusFireRain';
  SBonusAura = 'bonusAura';
  SBonusExplosion = 'bonusExplosion';
  SBonusAwardFmt = 'bonusAwardFmt';
  SBrokeThrough = 'brokeThrough';
  SBonusHudFmt = 'bonusHudFmt';
  SBonusHudHint = 'bonusHudHint';

  // --- Menu texts ---
  SMainTitle = 'mainTitle';
  SNewGame = 'newGame';
  SResume = 'resume';
  SFullscreen = 'fullscreen';
  SCredits = 'credits';
  SQuit = 'quit';
  SLevelSelectTitle = 'levelSelectTitle';
  SBack = 'back';
  // No space after the colon in ru - verbatim 'Сложность:'+cfg[5]
  // (1291); en mirrors the shape and its longest grade still fits the
  // item column (the last glyph kisses the right edge - playtest)
  SDifficultyFmt = 'difficultyFmt';
  SDifficultyTitle = 'difficultyTitle';
  SDiffNormal = 'diffNormal';
  SDiffHard = 'diffHard';
  SDiffWild = 'diffWild';
  // The idle ru line is verbatim moon.dpr 356. The in-game line is
  // ours: 2008 promised the change 'on the next screen' because its
  // monsters were reborn per screen - ours live per level (deviation)
  SDiffHintLive = 'diffHintLive';
  SDiffHintIdle = 'diffHintIdle';
  SCreditsTitle = 'creditsTitle';
  SCreditsDone = 'creditsDone';
  SQuitTitle = 'quitTitle';
  SYes = 'yes';
  SNo = 'no';
  SLogoCaption = 'logoCaption';
  // The credits block, ru verbatim moon.dpr 361-365 EXCEPT line 4:
  // the co-author renamed himself since - 'Фриз'/'Friz' by his 2026
  // spelling, not the 2008 'Фризе' (deviation, requested by Ilya)
  SCreditsLine1 = 'creditsLine1';
  SCreditsLine2 = 'creditsLine2';
  SCreditsLine3 = 'creditsLine3';
  SCreditsLine4 = 'creditsLine4';

// Reads lang\<id>.json for ALanguage, validates it against the full
// key roster and replaces the active dictionary. Raises
// ELocalizationError on a missing file, broken JSON or missing keys -
// a language file is a game asset, not a preference.
procedure LoadLanguage(ALanguage: TLanguage);

// The active dictionary lookup. Raises on an unknown key or when no
// dictionary is loaded - both are programming errors, not user input.
function Tr(const AKey: string): string;

// The language of the active dictionary - whoever shows a language
// indicator (the menu flags) asks here instead of carrying a copy
// through constructors. lgEnglish before the first LoadLanguage,
// but nothing that draws text can exist that early anyway.
function CurrentLanguage: TLanguage;

// The single reader of localized content fields (the
// TryReadDifficultyValue pattern: one reader, many callers): fills
// every language from AKey plus its suffixed siblings ('title' +
// 'titleEn'). Absent base field -> ADefault; absent sibling -> base.
function ReadLocalizedText(const AObj: TJSONObject; const AKey: string;
  const ADefault: string = ''): TLocalizedText;

// The same text in every language - for fallbacks born outside JSON
// (a file name standing in for a missing title).
function MakeLocalizedText(const AText: string): TLocalizedText;

implementation

uses
  System.IOUtils, System.Generics.Collections;

resourcestring
  // Developer-facing, never localized (see the unit header)
  SLangFileNotFound = 'Language file not found: %s';
  SLangParseFailed = 'Language file "%s": not a valid JSON object';
  SLangValueNotString = 'Language file "%s": value of "%s" is not a string';
  SLangMissingKeys = 'Language file "%s" is missing keys: %s';
  SLangNotLoaded = 'Tr("%s") called before LoadLanguage';
  SLangUnknownKey = 'Text key "%s" is not in the roster of "%s"';

const
  LangFilePattern = 'lang\%s.json';

  // JSON content-field suffix per language; '' = the base field.
  // Internal to ReadLocalizedText - the rest of the world speaks
  // TLocalizedText, not suffixes.
  LanguageFieldSuffixes: array [TLanguage] of string = ('En', '');

  // The full roster every dictionary must cover. Self-assembled from
  // the key constants above - there is no second hand-written list
  // (the PreloadSounds pattern).
  AllTextKeys: TArray<string> = [
    SFellIntoPit, SEndingLine1, SEndingLine2, SEndingLine3, SEndingLine4,
    SEndingLine5, SEndingAuthor, SEndingMenu, SHitByBullet, SHurtByMonster,
    SStreakBigTen, SStreakSmallTen, SStreakBigInvincible,
    SStreakSmallInvincible, SStreakBigWarGod, SStreakSmallWarGod,
    SScoreFmt, SPressAnyKey, SEvolution, SIceForm, SIceFormPerk, SIceRegen,
    SBonusHealth, SBonusFireRain, SBonusAura, SBonusExplosion,
    SBonusAwardFmt, SBrokeThrough, SBonusHudFmt, SBonusHudHint,
    SMainTitle, SNewGame, SResume, SFullscreen, SCredits, SQuit,
    SLevelSelectTitle, SBack, SDifficultyFmt, SDifficultyTitle,
    SDiffNormal, SDiffHard, SDiffWild, SDiffHintLive, SDiffHintIdle,
    SCreditsTitle, SCreditsDone, SQuitTitle, SYes, SNo, SLogoCaption,
    SCreditsLine1, SCreditsLine2, SCreditsLine3, SCreditsLine4];

var
  Texts: TDictionary<string, string>;
  TextsFileName: string; // for the unknown-key error message only
  ActiveLanguage: TLanguage = lgEnglish;

function ParseLanguageFile(
  const AFileName: string): TDictionary<string, string>;
begin
  if not FileExists(AFileName) then
    raise ELocalizationError.CreateFmt(SLangFileNotFound, [AFileName]);

  var RootValue := TJSONObject.ParseJSONValue(
    TFile.ReadAllText(AFileName, TEncoding.UTF8));
  if not (RootValue is TJSONObject) then
  begin
    RootValue.Free; // nil-safe: broken JSON and a non-object root land here
    raise ELocalizationError.CreateFmt(SLangParseFailed, [AFileName]);
  end;

  var Root := TJSONObject(RootValue);
  try
    Result := TDictionary<string, string>.Create;
    try
      for var Pair in Root do
      begin
        // Strict on arrival: a nested object or a bare number would
        // otherwise degrade to '' and show as silent blank text in-game
        if not (Pair.JsonValue is TJSONString) then
          raise ELocalizationError.CreateFmt(SLangValueNotString,
            [AFileName, Pair.JsonString.Value]);
        Result.AddOrSetValue(Pair.JsonString.Value, Pair.JsonValue.Value);
      end;
    except
      Result.Free;
      raise;
    end;
  finally
    Root.Free;
  end;
end;

// Returns a comma-joined list of roster keys absent from ALoaded;
// '' = the dictionary is complete.
function MissingKeyList(ALoaded: TDictionary<string, string>): string;
begin
  Result := '';
  for var Key in AllTextKeys do
    if not ALoaded.ContainsKey(Key) then
    begin
      if Result <> '' then
        Result := Result + ', ';
      Result := Result + Key;
    end;
end;

procedure LoadLanguage(ALanguage: TLanguage);
var
  FileName: string;
  Loaded: TDictionary<string, string>;
begin
  FileName := Format(LangFilePattern, [LanguageIds[ALanguage]]);
  Loaded := ParseLanguageFile(FileName);

  var Missing := MissingKeyList(Loaded);
  if Missing <> '' then
  begin
    Loaded.Free;
    raise ELocalizationError.CreateFmt(SLangMissingKeys,
      [FileName, Missing]);
  end;

  Texts.Free;
  Texts := Loaded;
  TextsFileName := FileName;
  ActiveLanguage := ALanguage;
end;

function Tr(const AKey: string): string;
begin
  if Texts = nil then
    raise ELocalizationError.CreateFmt(SLangNotLoaded, [AKey]);
  if not Texts.TryGetValue(AKey, Result) then
    raise ELocalizationError.CreateFmt(SLangUnknownKey,
      [AKey, TextsFileName]);
end;

function CurrentLanguage: TLanguage;
begin
  Result := ActiveLanguage;
end;

function TLocalizedText.Current: string;
begin
  Result := Values[ActiveLanguage];
end;

function ReadLocalizedText(const AObj: TJSONObject; const AKey: string;
  const ADefault: string): TLocalizedText;
begin
  // The empty suffix of the base language re-reads AKey itself - one
  // loop covers everyone
  var Base := AObj.GetValue<string>(AKey, ADefault);
  for var Language := Low(TLanguage) to High(TLanguage) do
    Result.Values[Language] :=
      AObj.GetValue<string>(AKey + LanguageFieldSuffixes[Language], Base);
end;

function MakeLocalizedText(const AText: string): TLocalizedText;
begin
  for var Language := Low(TLanguage) to High(TLanguage) do
    Result.Values[Language] := AText;
end;

initialization
  // Empty on purpose: the language allows a finalization section only
  // in a unit that has an initialization section.

finalization
  Texts.Free;

end.
