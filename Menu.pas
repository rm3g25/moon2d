{
  Menu - the main menu: moon drifting over a starfield (MenuPic.pas of
  2008) plus the menu state machine that lived as a stringly-typed
  if-forest inside WindowProc (moon.dpr 1211-1616).

  The 2008 machine keyed everything off MenuText[0] string literals and
  hit-tested the mouse against magic pixel bands (with a +16 mouse-Y
  offset thrown in for flavor). Here the screens are an enum, the items
  are records with typed actions, and the hit rectangles are computed
  from the same font metrics that draw the captions - what you see is
  what you click.

  The scenery is verbatim: 350 stars in eight speed classes crawling
  right, the full moon drifting left on a random diagonal, the logo
  ghosted at 130/255 alpha. All 2008 NDC geometry is converted once into
  512x384 game units (1 NDC-x = 256 units, 1 NDC-y = 192 units) and
  frozen as constants - including the 4:3 stretch that made the moon
  slightly wider than tall. That IS the moon this game always had.

  The menu produces TMenuResult commands; it never touches the game -
  the composition root (Moon2D.dpr) decides what starting a level means.

  Moon 2D remake. Requires Delphi 12+.
}
unit Menu;

interface

uses
  System.SysUtils, Sdl2.Core, Render.Sprites, Render.Font, Game.Config,
  Localization;

type
  EMenuError = class(Exception);

  // One entry of the level-select screen; discovered by the composition
  // root (it owns the file system), displayed here.
  TLevelChoice = record
    FileName: string;
    Title: TLocalizedText; // re-read per language on every list build
  end;

  // What the click asked the game to do. mcNone covers both a miss and
  // a navigation click that the menu resolved internally.
  TMenuCommand = (mcNone, mcStartLevel, mcResume, mcToggleFullscreen,
    mcSetDifficulty, mcSetLanguage, mcQuit);

  TMenuResult = record
    Command: TMenuCommand;
    LevelFile: string;        // meaningful for mcStartLevel only
    Difficulty: TDifficulty;  // meaningful for mcSetDifficulty only
    Language: TLanguage;      // meaningful for mcSetLanguage only
  end;

  TMenuScreen = (msMain, msLevelSelect, msDifficulty, msCredits,
    msQuitConfirm);

  // Trailer frames: the live sky rig alone, with or without the logo.
  // Entered by the host's debug keys, left by any key or click.
  TShowcaseKind = (skNone, skLogo, skSky);

  // Menu-internal item actions; navigation ones resolve inside the menu,
  // the rest surface as TMenuCommand.
  TItemAction = (iaNewGame, iaResume, iaFullscreen, iaDifficulty,
    iaSetDifficulty, iaCredits, iaAskQuit, iaBack, iaStartLevel,
    iaConfirmQuit);

  TMenuItem = record
    Caption: string;
    Action: TItemAction;
    LevelFile: string;
    Difficulty: TDifficulty; // meaningful for iaSetDifficulty only
  end;

  // One background star, verbatim TStar of MenuPic.pas converted to game
  // units. Kind 0 stars stand still - the 2008 parallax at its cheapest.
  // The texture is resolved once at init: 350 stars at render rate would
  // otherwise burn a string format + dictionary lookup per star per frame.
  TStar = record
    Kind: Integer;      // 0..7: speed class AND sprite index - 1
    X, Y: Double;       // game units
    Speed: Double;      // units per logic tick, rightward
    Width, Height: Double;
    Texture: PSdlTexture;
  end;

  // The drifting moon. Lives in the 2008 "sdvig" space (+-500 = one
  // half-screen) because the respawn thresholds are calibrated in it;
  // converted to units only at draw time.
  TMoonDrift = record
    DriftX, DriftY: Double;
    DeltaY: Double; // vertical drift per tick, random diagonal
    procedure Respawn;
    procedure Tick;
  end;

  TMoonMenu = class
  private
    FRenderer: PSdlRenderer;
    FSprites: TSpriteRenderer;
    FFont: TMoonFont;
    FCache: TSpriteCache; // color-keyed: star sprites + cursor frames
    FSkyTexture: PSdlTexture;
    FMoonTexture: PSdlTexture;
    FLogoTexture: PSdlTexture;
    FStars: TArray<TStar>;
    FMoon: TMoonDrift;
    FLevels: TArray<TLevelChoice>;
    FScreen: TMenuScreen;
    FTitle: string;
    FItems: TArray<TMenuItem>;
    FMouseX, FMouseY: Integer;
    FHasActiveGame: Boolean;
    FDifficulty: TDifficulty; // display copy: caption + hint follow it
    // Owned flag textures per language; the yellow box marks FLanguage
    FFlagTextures: array [TLanguage] of PSdlTexture;
    FLanguage: TLanguage;
    FShowcase: TShowcaseKind;
    procedure SetHasActiveGame(AValue: Boolean);
    procedure SetDifficulty(AValue: TDifficulty);
    procedure SetLanguage(AValue: TLanguage);
    function LoadOpaqueTexture(const AFileName: string): PSdlTexture;
    function LoadThresholdTexture(const AFileName: string;
      AThreshold, AOpaqueAlpha: Byte): PSdlTexture;
    procedure InitStars;
    procedure ShowScreen(AScreen: TMenuScreen);
    procedure AddItem(const ACaption: string; AAction: TItemAction;
      const ALevelFile: string = '');
    procedure AddDifficultyItem(const ACaption: string;
      AValue: TDifficulty);
    function ItemTop(AIndex: Integer): Double;
    function HoveredIndex: Integer;
    // One geometry for drawing AND hit-testing a flag - what you see
    // is what you click, same principle as the caption rectangles
    function FlagRect(ALanguage: TLanguage): TSdlFRect;
    function TryHoveredFlag(out ALanguage: TLanguage): Boolean;
    function ExecuteItem(const AItem: TMenuItem): TMenuResult;
    procedure DrawLogo;
    procedure DrawShowcaseLogo;
    procedure DrawItems;
    procedure DrawFlags;
    procedure DrawCredits;
    procedure DrawDifficultyHint;
    procedure DrawCursor;
  public
    constructor Create(const ARenderer: PSdlRenderer;
      const ASprites: TSpriteRenderer; const AFont: TMoonFont;
      const ALevels: TArray<TLevelChoice>);
    destructor Destroy; override;

    procedure ShowMain;
    procedure Tick;
    // Sky + stars + moon, no logo and no items: the story screen reuses
    // it as scenery - in 2008 the text was typed right over the live menu
    procedure DrawSky(AAlpha: Double);
    procedure Draw(AAlpha: Double);
    procedure MouseMove(AX, AY: Integer);
    // Left click at the last known mouse position.
    function Click: TMenuResult;
    // Escape pressed while the menu is up. True = the menu consumed it
    // (stepped back from a sub-screen); False = main screen, the caller
    // decides (resume the game or ignore).
    function HandleEscape: Boolean;
    // While a showcase is active the host must feed every key to
    // EndShowcase instead of running its own menu shortcuts.
    procedure ShowShowcase(AKind: TShowcaseKind);
    function ShowcaseActive: Boolean;
    procedure EndShowcase;

    property HasActiveGame: Boolean read FHasActiveGame
      write SetHasActiveGame;
    property Difficulty: TDifficulty read FDifficulty
      write SetDifficulty;
    // Set by the composition root AFTER it swapped the dictionary -
    // the setter rebuilds the current screen's captions through Tr
    property Language: TLanguage read FLanguage write SetLanguage;
  end;

implementation

// Every caption a player reads lives in lang\*.json now (part 6): the
// S-keys moved to Localization, sites fetch them through Tr(). The
// archaeology notes (verbatim colons, hint deviations) moved with them.
resourcestring
  // Developer-facing, never localized
  SMenuTextureFailed = 'Cannot load menu texture "%s": %s';

const
  // 2008 drew the menu in GL normalized device coords over the whole
  // window; the conversion is the same one Render.Font froze:
  UnitsPerNdcX = 256.0; // 2.0 NDC = 512 game units
  UnitsPerNdcY = 192.0; // 2.0 NDC = 384 game units
  // Full 2.0-NDC span of every 2008 quad, in game units
  ScreenWidthUnits = 2 * UnitsPerNdcX;
  ScreenHeightUnits = 2 * UnitsPerNdcY;

  SkyFile = 'sky.bmp';           // 512x512, opaque backdrop
  MoonFile = 'fullmoon.bmp';     // 256x256, black threshold < 33
  LogoFile = 'logo.bmp';         // 256x256, threshold < 15, alpha 130
  MoonAlphaThreshold = 33;
  LogoAlphaThreshold = 15;
  MoonAlpha = 255;   // fully solid disc
  LogoAlpha = 130;   // the 2008 logo is a ghost over the sky - verbatim
  StarFileFmt = 'Stars\%d.bmp';  // 1..10 on disk

  StarCount = 350;
  // Random(8) of 2008: star sprites 9 and 10 are loaded but never fly.
  // Kept verbatim - they are the two understudies of this theater.
  StarKindCount = 8;
  StarSpriteCount = 10;
  // StarSpeed = StarType/7000 NDC/tick (MenuPic.StarsTimer)
  StarSpeedPerKind = UnitsPerNdcX / 7000;
  StarBaseSizeNdc = 0.03;        // PutStars quad: x .. x+0.03+razmer
  // LoadStars rolled positions on a permille grid: Random(1000)/1000
  StarPositionSteps = 1000;
  // ...and size jitter as Random(100)/3000 - up to 0.033 NDC on top of
  // the base. Kept as the exact same rolls, not a rescaled equivalent.
  StarSizeJitterSteps = 100;
  StarSizeJitterScale = 3000;

  // TMoonDrift passport, verbatim MoonTimer / LoadMoonTexture:
  MoonDriftSpeed = 1;        // drift units per tick, leftward
  MoonDriftLimit = 650;      // respawn X and the out-of-bounds edge
  MoonFirstEntryX = 500;     // the very first moon enters half-visible
  MoonRespawnYSpread = 350;  // DriftY = Random(350) - 175
  MoonDeltaYSteps = 40;      // DeltaY = (Random(40) - 20) / 50
  MoonDeltaYScale = 50;

  // PutMoonTexture quad: 0.6 NDC on both axes. Horizontally that is
  // 153.6 units, vertically 115.2 - the moon of 2008 was a 4:3-stretched
  // disc on every resolution it ever ran at. The house moon stays wide.
  MoonWidth = 0.6 * UnitsPerNdcX;
  MoonHeight = 0.6 * UnitsPerNdcY;
  // Drift space: +-500 "sdvig" = one half-screen on the respective axis
  MoonUnitsPerDriftX = UnitsPerNdcX / 500;
  MoonUnitsPerDriftY = UnitsPerNdcY / 500;

  // PutLogoTexture quad (-0.9, 1) .. (0, 0.4) in units:
  LogoLeft = 0.1 * UnitsPerNdcX;   // 25.6
  LogoTop = 0.0;
  LogoWidth = 0.9 * UnitsPerNdcX;  // 230.4
  LogoHeight = 0.6 * UnitsPerNdcY; // 115.2

  // Same 2:1 logo, half again larger and centered.
  ShowcaseLogoScale = 1.5;
  ShowcaseLogoWidth = ShowcaseLogoScale * LogoWidth;   // 345.6
  ShowcaseLogoHeight = ShowcaseLogoScale * LogoHeight; // 172.8

  // line2() rows step 12.5 units (the same 'row 12 = Y 150' anchor the
  // message board uses); its x argument steps one big glyph.
  BigRowStep = 12.5;
  // Menu geometry verbatim: title line(...,24,1) small, items
  // line2(...,17,2+i*2) big (moon.dpr 348-351)
  TitleX = 24 * LegacyColumnWidth;   // 307.2
  TitleY = 1 * SmallLineStep;        // 9.6
  // Deliberate deviation: 2008 drew items at column 17 (line2 348-351),
  // but the English DIFFICULTY:NORMAL grew to 17 glyphs and pressed the
  // longest line against the right edge. Two columns left buys a margin
  // (Ilya, 2026-07-21); the hover hitbox follows this constant for free.
  ItemColumnX = 15 * BigGlyphWidth;  // 249.6
  LogoCaptionX = 1 * BigGlyphWidth;
  LogoCaptionY = 28 * BigRowStep;    // line2(...,1,28)

  // Hovered caption is double-drawn with this offset - a faux bold.
  // 2008 signalled hover through the cursor sprite alone.
  HoverBoldOffset = 0.7;

  // The language flags (part 6.2): top-right corner of the main screen,
  // rightmost = highest TLanguage id. Files follow LanguageIds - a
  // third language later is one BMP plus one enum entry.
  FlagFileFmt = 'flag_%s.bmp';   // 60x40 px art drawn into 30x20 units
  FlagWidth = 30.0;
  FlagHeight = 20.0;
  FlagGap = 8.0;                 // air between the two flags
  FlagMargin = 8.0;              // air to the right screen edge
  FlagTop = 8.0;
  // The active language wears a yellow box: a filled quad under the
  // flag showing this many units on every side
  FlagBorder = 2.0;
  FlagBoxRed = 255;
  FlagBoxGreen = 255;
  FlagBoxBlue = 0;

  // Cursor frames, same art the gameplay crosshair uses (target.pas):
  // 1 idle, 2 over an item, 4 over anything that quits (VidKursora).
  // Frame 3 (the wounded-target yellow) rides along unused here - the
  // menu has nothing half-dead to point at; gameplay employs it.
  CursorFrameFiles: array [1..4] of string =
    ('weapon\target.bmp', 'weapon\target1.bmp', 'weapon\target2.bmp',
     'weapon\target3.bmp');
  CursorIdleFrame = 1;
  CursorHoverFrame = 2;
  CursorQuitFrame = 4;
  // The crosshair art sits off-center in its bitmap; these are the
  // player-calibrated offsets of Hero (NumPad tuner, 2026-07-12)
  CursorOffsetX = 9;
  CursorOffsetY = 10;

// ---------------------------------------------------------------------------
// TMoonDrift - verbatim MoonTimer / LoadMoonTexture tail of MenuPic.pas
// ---------------------------------------------------------------------------

procedure TMoonDrift.Respawn;
begin
  DriftX := MoonDriftLimit; // just off the right edge
  DriftY := Random(MoonRespawnYSpread) - MoonRespawnYSpread div 2;
  DeltaY := (Random(MoonDeltaYSteps) - MoonDeltaYSteps div 2) /
    MoonDeltaYScale;
end;

procedure TMoonDrift.Tick;
begin
  DriftX := DriftX - MoonDriftSpeed;
  DriftY := DriftY + DeltaY;
  if (DriftY < -MoonDriftLimit) or (DriftY > MoonDriftLimit) or
     (DriftX < -MoonDriftLimit) then
    Respawn;
end;

// ---------------------------------------------------------------------------
// TMoonMenu
// ---------------------------------------------------------------------------

constructor TMoonMenu.Create(const ARenderer: PSdlRenderer;
  const ASprites: TSpriteRenderer; const AFont: TMoonFont;
  const ALevels: TArray<TLevelChoice>);
begin
  inherited Create;
  FRenderer := ARenderer;
  FSprites := ASprites;
  FFont := AFont;
  FLevels := ALevels;

  // Base '.' so star and cursor paths keep their subfolders in the key
  FCache := TSpriteCache.Create(ARenderer, '.');
  // Warm the star sprites - all ten, as 2008 loaded them (see
  // StarKindCount for why two of them never take the stage)
  for var i := 1 to StarSpriteCount do
    FCache.Get(Format(StarFileFmt, [i]));

  FSkyTexture := LoadOpaqueTexture(SkyFile);
  FMoonTexture := LoadThresholdTexture(MoonFile, MoonAlphaThreshold,
    MoonAlpha);
  FLogoTexture := LoadThresholdTexture(LogoFile, LogoAlphaThreshold,
    LogoAlpha);
  // Flags are plain rectangles - no transparency, the color-key
  // machinery stays out (the Union Jack navy would survive the
  // threshold anyway, but why even ask)
  for var Language := Low(TLanguage) to High(TLanguage) do
    FFlagTextures[Language] :=
      LoadOpaqueTexture(Format(FlagFileFmt, [LanguageIds[Language]]));
  // The dictionary is already loaded by the composition root; the
  // yellow box must agree with it from the very first frame
  FLanguage := CurrentLanguage;

  InitStars;
  FMoon.Respawn;
  FMoon.DriftX := MoonFirstEntryX;

  ShowMain;
end;

destructor TMoonMenu.Destroy;
begin
  for var Language := Low(TLanguage) to High(TLanguage) do
    if Assigned(FFlagTextures[Language]) then
      SDL_DestroyTexture(FFlagTextures[Language]);
  if Assigned(FLogoTexture) then
    SDL_DestroyTexture(FLogoTexture);
  if Assigned(FMoonTexture) then
    SDL_DestroyTexture(FMoonTexture);
  if Assigned(FSkyTexture) then
    SDL_DestroyTexture(FSkyTexture);
  FCache.Free;
  inherited;
end;

function TMoonMenu.LoadOpaqueTexture(const AFileName: string): PSdlTexture;
var
  Surface: PSdlSurface;
begin
  Surface := SDL_LoadBMP_RW(
    SDL_RWFromFile(PAnsiChar(SdlText(AFileName)), 'rb'), 1);
  if Surface = nil then
    raise EMenuError.CreateFmt(SMenuTextureFailed,
      [AFileName, SdlErrorText]);
  try
    Result := SDL_CreateTextureFromSurface(FRenderer, Surface);
    if Result = nil then
      raise EMenuError.CreateFmt(SMenuTextureFailed,
        [AFileName, SdlErrorText]);
  finally
    SDL_FreeSurface(Surface);
  end;
end;

// The 2008 loaders keyed out "black" by a per-channel THRESHOLD, not by
// exact zero - the art has near-black dirt around the shapes, and an
// exact color key would leave a dark halo. Same trick the font atlas
// loader uses; AOpaqueAlpha < 255 reproduces the ghosted logo.
function TMoonMenu.LoadThresholdTexture(const AFileName: string;
  AThreshold, AOpaqueAlpha: Byte): PSdlTexture;
type
  PPixelBytes = ^TPixelBytes;
  TPixelBytes = array [0..3] of Byte; // R,G,B,A of SdlPixelFormatAbgr8888
var
  Loaded, Surface: PSdlSurface;
begin
  Loaded := SDL_LoadBMP_RW(
    SDL_RWFromFile(PAnsiChar(SdlText(AFileName)), 'rb'), 1);
  if Loaded = nil then
    raise EMenuError.CreateFmt(SMenuTextureFailed,
      [AFileName, SdlErrorText]);

  Surface := SDL_ConvertSurfaceFormat(Loaded, SdlPixelFormatAbgr8888, 0);
  SDL_FreeSurface(Loaded);
  if Surface = nil then
    raise EMenuError.CreateFmt(SMenuTextureFailed,
      [AFileName, SdlErrorText]);
  try
    SDL_LockSurface(Surface);
    for var Row := 0 to Surface.H - 1 do
    begin
      var Pixel := PPixelBytes(PByte(Surface.Pixels) + Row * Surface.Pitch);
      for var Col := 0 to Surface.W - 1 do
      begin
        if (Pixel[0] < AThreshold) and (Pixel[1] < AThreshold) and
           (Pixel[2] < AThreshold) then
          Pixel[3] := 0
        else
          Pixel[3] := AOpaqueAlpha;
        Inc(Pixel);
      end;
    end;
    SDL_UnlockSurface(Surface);

    Result := SDL_CreateTextureFromSurface(FRenderer, Surface);
    if Result = nil then
      raise EMenuError.CreateFmt(SMenuTextureFailed,
        [AFileName, SdlErrorText]);
    SDL_SetTextureBlendMode(Result, SdlBlendModeBlend);
  finally
    SDL_FreeSurface(Surface);
  end;
end;

// Verbatim LoadStars tail: position uniform over the screen, speed
// proportional to the kind, size 0.03 NDC plus up to 0.033 of jitter.
// The NDC quads were stretched 4:3 exactly like the moon - preserved.
procedure TMoonMenu.InitStars;
begin
  SetLength(FStars, StarCount);
  for var i := 0 to High(FStars) do
  begin
    var Star: TStar;
    Star.Kind := Random(StarKindCount);
    Star.X := Random(StarPositionSteps) / StarPositionSteps *
      ScreenWidthUnits;
    Star.Y := Random(StarPositionSteps) / StarPositionSteps *
      ScreenHeightUnits;
    Star.Speed := Star.Kind * StarSpeedPerKind;
    var SizeNdc := StarBaseSizeNdc +
      Random(StarSizeJitterSteps) / StarSizeJitterScale;
    Star.Width := SizeNdc * UnitsPerNdcX;
    Star.Height := SizeNdc * UnitsPerNdcY;
    Star.Texture := FCache.Get(Format(StarFileFmt, [Star.Kind + 1]));
    FStars[i] := Star;
  end;
end;

procedure TMoonMenu.SetHasActiveGame(AValue: Boolean);
begin
  if FHasActiveGame = AValue then
    Exit;
  FHasActiveGame := AValue;
  if FScreen = msMain then
    ShowMain; // the 'Продолжить игру' line appears/disappears
end;

procedure TMoonMenu.SetDifficulty(AValue: TDifficulty);
begin
  if FDifficulty = AValue then
    Exit;
  FDifficulty := AValue;
  if FScreen = msMain then
    ShowMain; // the 'Сложность: ...' caption follows the value
end;

procedure TMoonMenu.SetLanguage(AValue: TLanguage);
begin
  if FLanguage = AValue then
    Exit;
  FLanguage := AValue;
  // Every caption on every screen flows from Tr - rebuild whatever is
  // up. The composition root has already swapped the dictionary.
  ShowScreen(FScreen);
end;

// Maps the grade to its 2008 caption. About captions, not about the
// menu class - a free function per the codestyle.
function DifficultyName(AValue: TDifficulty): string;
begin
  case AValue of
    dfHard: Result := Tr(SDiffHard);
    dfWild: Result := Tr(SDiffWild);
  else
    Result := Tr(SDiffNormal);
  end;
end;

procedure TMoonMenu.AddItem(const ACaption: string; AAction: TItemAction;
  const ALevelFile: string);
begin
  var Item := Default(TMenuItem);
  Item.Caption := ACaption;
  Item.Action := AAction;
  Item.LevelFile := ALevelFile;
  FItems := FItems + [Item];
end;

procedure TMoonMenu.AddDifficultyItem(const ACaption: string;
  AValue: TDifficulty);
begin
  var Item := Default(TMenuItem);
  Item.Caption := ACaption;
  Item.Action := iaSetDifficulty;
  Item.Difficulty := AValue;
  FItems := FItems + [Item];
end;

// Turns 'Уровень 3 - Гравий' into 'Гравий'. About strings, not about the
// menu class - a free function per the codestyle. Titles without the
// separator pass through untouched.
function ShortLevelName(const ATitle: string): string;
const
  Separator = ' - ';
begin
  var SepPos := Pos(Separator, ATitle);
  if SepPos > 0 then
    Result := Copy(ATitle, SepPos + Length(Separator), MaxInt)
  else
    Result := ATitle;
end;

procedure TMoonMenu.ShowScreen(AScreen: TMenuScreen);
begin
  FScreen := AScreen;
  FItems := nil;
  case AScreen of
    msMain:
      begin
        FTitle := Tr(SMainTitle);
        AddItem(Tr(SNewGame), iaNewGame);
        if FHasActiveGame then
          AddItem(Tr(SResume), iaResume);
        // Replaces the whole 2008 resolution submenu: the window is the
        // resolution now, this line (and Alt/Ctrl+Enter) is the only knob.
        // No on/off suffix - the screen itself shows which mode you are in.
        AddItem(Tr(SFullscreen), iaFullscreen);
        // The survivor of the 2008 'Опции' screen: the caption carries
        // the current grade the way 'Сложность:Обычная' did (1291)
        AddItem(Format(Tr(SDifficultyFmt), [DifficultyName(FDifficulty)]),
          iaDifficulty);
        AddItem(Tr(SCredits), iaCredits);
        AddItem(Tr(SQuit), iaAskQuit);
      end;
    msLevelSelect:
      begin
        FTitle := Tr(SLevelSelectTitle);
        // 2008 listed levels as '1.Космопорт' - short names fit the column.
        // Manifest titles carry the full 'Уровень N - ...' for the intro
        // screen, so the redundant prefix is stripped here, not in JSON.
        for var i := 0 to High(FLevels) do
          AddItem(Format('%d. %s',
            [i + 1, ShortLevelName(FLevels[i].Title.Current)]),
            iaStartLevel, FLevels[i].FileName);
        AddItem(Tr(SBack), iaBack);
      end;
    msDifficulty:
      begin
        // The 2008 submenu verbatim (1360-1363): title + three grades
        FTitle := Tr(SDifficultyTitle);
        AddDifficultyItem(Tr(SDiffNormal), dfNormal);
        AddDifficultyItem(Tr(SDiffHard), dfHard);
        AddDifficultyItem(Tr(SDiffWild), dfWild);
        AddItem(Tr(SBack), iaBack);
      end;
    msCredits:
      begin
        FTitle := Tr(SCreditsTitle);
        AddItem(Tr(SCreditsDone), iaBack);
      end;
    msQuitConfirm:
      begin
        FTitle := Tr(SQuitTitle);
        AddItem(Tr(SYes), iaConfirmQuit);
        AddItem(Tr(SNo), iaBack);
      end;
  end;
end;

procedure TMoonMenu.ShowMain;
begin
  ShowScreen(msMain);
end;

// Verbatim vertical rhythm of 2008: item i (1-based) sat at big row
// 2 + i*2 - one caption, one row of air.
function TMoonMenu.ItemTop(AIndex: Integer): Double;
begin
  Result := (2 + (AIndex + 1) * 2) * BigRowStep;
end;

// Honest hit test: the rectangle IS the drawn caption. The 2008 bands
// (25-px rows plus a +16 mouse offset) landed half a row below the
// glyphs; that jank is a bug, not charm - deviation logged.
function TMoonMenu.HoveredIndex: Integer;
begin
  for var i := 0 to High(FItems) do
  begin
    var Top := ItemTop(i);
    if (FMouseY >= Top) and (FMouseY < Top + BigGlyphHeight) and
       (FMouseX >= ItemColumnX) and
       (FMouseX < ItemColumnX + FFont.BigTextWidth(FItems[i].Caption)) then
      Exit(i);
  end;
  Result := -1;
end;

function TMoonMenu.FlagRect(ALanguage: TLanguage): TSdlFRect;
begin
  // Rightmost slot belongs to the highest language id; earlier ids
  // stack leftward, one flag plus one gap per slot
  var SlotsFromRight := Ord(High(TLanguage)) - Ord(ALanguage);
  Result.X := ScreenWidthUnits - FlagMargin - FlagWidth
    - SlotsFromRight * (FlagWidth + FlagGap);
  Result.Y := FlagTop;
  Result.W := FlagWidth;
  Result.H := FlagHeight;
end;

// The flags live on the main screen only - sub-screens keep the mouse
// for their own items.
function TMoonMenu.TryHoveredFlag(out ALanguage: TLanguage): Boolean;
begin
  Result := False;
  if FScreen <> msMain then
    Exit;
  for var Language := Low(TLanguage) to High(TLanguage) do
  begin
    var Rect := FlagRect(Language);
    if (FMouseX >= Rect.X) and (FMouseX < Rect.X + Rect.W) and
       (FMouseY >= Rect.Y) and (FMouseY < Rect.Y + Rect.H) then
    begin
      ALanguage := Language;
      Exit(True);
    end;
  end;
end;

procedure TMoonMenu.MouseMove(AX, AY: Integer);
begin
  FMouseX := AX;
  FMouseY := AY;
end;

function TMoonMenu.ExecuteItem(const AItem: TMenuItem): TMenuResult;
begin
  Result := Default(TMenuResult);
  case AItem.Action of
    iaNewGame:
      ShowScreen(msLevelSelect);
    iaResume:
      Result.Command := mcResume;
    iaFullscreen:
      Result.Command := mcToggleFullscreen;
    iaDifficulty:
      ShowScreen(msDifficulty);
    iaSetDifficulty:
      begin
        FDifficulty := AItem.Difficulty;
        // Back to the parent screen with the updated caption - 2008
        // returned to its options list the same way (1452-1459)
        ShowMain;
        Result.Command := mcSetDifficulty;
        Result.Difficulty := AItem.Difficulty;
      end;
    iaCredits:
      ShowScreen(msCredits);
    iaAskQuit:
      ShowScreen(msQuitConfirm);
    iaBack:
      ShowMain;
    iaStartLevel:
      begin
        Result.Command := mcStartLevel;
        Result.LevelFile := AItem.LevelFile;
      end;
    iaConfirmQuit:
      Result.Command := mcQuit;
  end;
end;

function TMoonMenu.Click: TMenuResult;
var
  Flag: TLanguage;
begin
  Result := Default(TMenuResult);
  if FShowcase <> skNone then
  begin
    FShowcase := skNone;
    Exit;
  end;
  if TryHoveredFlag(Flag) then
  begin
    // The menu only REPORTS the wish: FLanguage follows through the
    // property after the composition root swaps the dictionary -
    // captions must rebuild on the new words, not the old ones.
    // Clicking the language already active is a polite no-op.
    if Flag <> FLanguage then
    begin
      Result.Command := mcSetLanguage;
      Result.Language := Flag;
    end;
    Exit;
  end;
  var Index := HoveredIndex;
  if Index >= 0 then
    Result := ExecuteItem(FItems[Index]);
end;

function TMoonMenu.HandleEscape: Boolean;
begin
  if FShowcase <> skNone then
  begin
    FShowcase := skNone;
    Exit(True);
  end;
  Result := FScreen <> msMain;
  if Result then
    ShowMain;
end;

procedure TMoonMenu.ShowShowcase(AKind: TShowcaseKind);
begin
  FShowcase := AKind;
end;

function TMoonMenu.ShowcaseActive: Boolean;
begin
  Result := FShowcase <> skNone;
end;

procedure TMoonMenu.EndShowcase;
begin
  FShowcase := skNone;
end;

procedure TMoonMenu.Tick;
begin
  // MoonTimer + StarsTimer of 2008, fused: one heartbeat for the sky
  FMoon.Tick;
  for var i := 0 to High(FStars) do
  begin
    FStars[i].X := FStars[i].X + FStars[i].Speed;
    if FStars[i].X > ScreenWidthUnits then
      FStars[i].X := 0; // wrapped to the left edge, as 2008 did
  end;
end;

procedure TMoonMenu.DrawSky(AAlpha: Double);
var
  Dest: TSdlFRect;
begin
  // Sky fills the screen edge to edge (PutSkyTexture quad -1..1)
  Dest.X := 0;
  Dest.Y := 0;
  Dest.W := ScreenWidthUnits;
  Dest.H := ScreenHeightUnits;
  SDL_RenderCopyF(FRenderer, FSkyTexture, nil, @Dest);

  // Stars move fractions of a unit per tick - interpolate with the
  // timestep alpha or the slow ones shimmer (the marquee lesson)
  for var Star in FStars do
  begin
    Dest.X := Star.X + Star.Speed * AAlpha;
    Dest.Y := Star.Y;
    Dest.W := Star.Width;
    Dest.H := Star.Height;
    SDL_RenderCopyF(FRenderer, Star.Texture, nil, @Dest);
  end;

  // The moon slides MoonDriftSpeed per tick; the interpolation must use
  // the same constant or the two would silently disagree
  var DriftX := FMoon.DriftX - MoonDriftSpeed * AAlpha;
  var DriftY := FMoon.DriftY + FMoon.DeltaY * AAlpha;
  var CenterX := UnitsPerNdcX + DriftX * MoonUnitsPerDriftX;
  var CenterY := UnitsPerNdcY - DriftY * MoonUnitsPerDriftY;
  Dest.X := CenterX - MoonWidth / 2;
  Dest.Y := CenterY - MoonHeight / 2;
  Dest.W := MoonWidth;
  Dest.H := MoonHeight;
  SDL_RenderCopyF(FRenderer, FMoonTexture, nil, @Dest);
end;

// The logo greets fresh visitors; over a running game the menu keeps
// the scenery but drops the marquee sign (LogoView of 2008). The story
// screen never shows it - text and logo shared no frame in the original.
procedure TMoonMenu.DrawLogo;
var
  Dest: TSdlFRect;
begin
  Dest.X := LogoLeft;
  Dest.Y := LogoTop;
  Dest.W := LogoWidth;
  Dest.H := LogoHeight;
  SDL_RenderCopyF(FRenderer, FLogoTexture, nil, @Dest);
  FFont.DrawBig(Tr(SLogoCaption), LogoCaptionX, LogoCaptionY);
end;

procedure TMoonMenu.DrawItems;
begin
  FFont.DrawSmall(FTitle, TitleX, TitleY);

  var Hovered := HoveredIndex;
  for var i := 0 to High(FItems) do
  begin
    FFont.DrawBig(FItems[i].Caption, ItemColumnX, ItemTop(i));
    // Faux bold on hover: the same caption a hair to the right fattens
    // every stroke (2008 signalled hover only through the cursor)
    if i = Hovered then
      FFont.DrawBig(FItems[i].Caption, ItemColumnX + HoverBoldOffset,
        ItemTop(i));
  end;
end;

// Verbatim credits block of moon.dpr 361-365
procedure TMoonMenu.DrawCredits;
begin
  FFont.DrawBig(Tr(SCreditsLine1), 1 * BigGlyphWidth, 8 * BigRowStep);
  FFont.DrawBig(Tr(SCreditsLine2), 10 * BigGlyphWidth, 10 * BigRowStep);
  FFont.DrawSmall(Tr(SCreditsLine3), 3 * LegacyColumnWidth,
    16 * SmallLineStep);
  FFont.DrawSmall(Tr(SCreditsLine4), 3 * LegacyColumnWidth,
    18 * SmallLineStep);
end;

// The 2008 submenu explained itself in a small line at column 5, row 18
// (moon.dpr 355-356) - same spot, wording adjusted for the live game
// (see the resourcestring comment).
procedure TMoonMenu.DrawDifficultyHint;
begin
  if FHasActiveGame then
    FFont.DrawSmall(Tr(SDiffHintLive), 5 * LegacyColumnWidth,
      18 * SmallLineStep)
  else
    FFont.DrawSmall(Tr(SDiffHintIdle), 5 * LegacyColumnWidth,
      18 * SmallLineStep);
end;

procedure TMoonMenu.DrawFlags;
begin
  // The yellow box first: a filled quad under the active flag,
  // FlagBorder units of it showing on every side
  var Box := FlagRect(FLanguage);
  Box.X := Box.X - FlagBorder;
  Box.Y := Box.Y - FlagBorder;
  Box.W := Box.W + 2 * FlagBorder;
  Box.H := Box.H + 2 * FlagBorder;
  SDL_SetRenderDrawColor(FRenderer, FlagBoxRed, FlagBoxGreen,
    FlagBoxBlue, 255);
  SDL_RenderFillRectF(FRenderer, @Box);

  for var Language := Low(TLanguage) to High(TLanguage) do
  begin
    var Dest := FlagRect(Language);
    SDL_RenderCopyF(FRenderer, FFlagTextures[Language], nil, @Dest);
  end;
end;

procedure TMoonMenu.DrawCursor;
var
  FlagUnderCursor: TLanguage;
begin
  var Frame := CursorIdleFrame;
  var Hovered := HoveredIndex;
  if Hovered >= 0 then
    if FItems[Hovered].Action in [iaAskQuit, iaConfirmQuit] then
      Frame := CursorQuitFrame // the red frame warns: this door leads out
    else
      Frame := CursorHoverFrame
  else if TryHoveredFlag(FlagUnderCursor) then
    Frame := CursorHoverFrame; // flags are clickable, the cursor agrees

  FSprites.DrawRotated(FCache.Get(CursorFrameFiles[Frame]),
    FMouseX + CursorOffsetX, FMouseY + CursorOffsetY, 0, False);
end;

// No caption line, unlike DrawLogo: the trailer adds its own titles.
procedure TMoonMenu.DrawShowcaseLogo;
var
  Dest: TSdlFRect;
begin
  Dest.W := ShowcaseLogoWidth;
  Dest.H := ShowcaseLogoHeight;
  Dest.X := (ScreenWidthUnits - Dest.W) / 2;
  Dest.Y := (ScreenHeightUnits - Dest.H) / 2;
  SDL_RenderCopyF(FRenderer, FLogoTexture, nil, @Dest);
end;

procedure TMoonMenu.Draw(AAlpha: Double);
begin
  DrawSky(AAlpha);
  // Showcase frames draw no items, flags or cursor
  if FShowcase <> skNone then
  begin
    if FShowcase = skLogo then
      DrawShowcaseLogo;
    Exit;
  end;
  if not FHasActiveGame then
    DrawLogo;
  if FScreen = msCredits then
    DrawCredits;
  if FScreen = msDifficulty then
    DrawDifficultyHint;
  DrawItems;
  if FScreen = msMain then
    DrawFlags;
  DrawCursor;
end;

end.
