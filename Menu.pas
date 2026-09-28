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

  The moon drifting left on a random diagonal is verbatim 2008; the
  moon itself is a spinning globe (Menu.Globe), the stars are drawn
  (Menu.Starfield), the logo sheds its own light (Menu.Logo). The 2008 NDC
  geometry is converted once into 512x384 game units (1 NDC-x = 256
  units, 1 NDC-y = 192 units) and frozen as constants.

  The menu produces TMenuResult commands; it never touches the game -
  the composition root (Moon2D.dpr) decides what starting a level means.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Menu;
{$I Moon2D.inc}

interface

uses
  System.SysUtils, Sdl2.Core, Render.Sprites, Sprites.Sets, Render.Font,
  Game.Config, Game.Space,
  Localization, Game.Version, Menu.Starfield, Menu.Globe, Menu.Logo,
  Hud.Draw;

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

  TMenuScreen = (msMain, msLevelSelect, msCredits, msQuitConfirm);

  // Trailer frames: the live sky rig alone, with or without the logo.
  // Entered by the host's debug keys, left by any key or click - so
  // with DEBUGKEYS off nothing can enter one and the state stays skNone.
  TShowcaseKind = (skNone, skLogo, skSky);

  // Menu-internal item actions; navigation ones resolve inside the menu,
  // the rest surface as TMenuCommand.
  TItemAction = (iaNewGame, iaResume, iaFullscreen, iaDifficulty,
    iaCredits, iaAskQuit, iaBack, iaStartLevel, iaConfirmQuit);

  TMenuItem = record
    Caption: string;
    Action: TItemAction;
    LevelFile: string;
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
    FCache: TSpriteCache; // color-keyed: cursor frames
    FSpriteSet: TSpriteSet; // attached, not owned; nil = folder era
    FSkyTexture: PSdlTexture;
    FSkySource: TSdlRect; // the part of the sky art the frame shows
    FGlobe: TMoonGlobe;
    FLogo: TMenuLogo;
    FStarfield: TStarfield;
    FBrush: THudBrush;
    FMoon: TMoonDrift;
    FLevels: TArray<TLevelChoice>;
    FScreen: TMenuScreen;
    FTitle: string;
    FItems: TArray<TMenuItem>;
    FMouseX, FMouseY: Integer;
    FHasActiveGame: Boolean;
    FDifficulty: TDifficulty; // display copy: the cells and the note follow it
    // Owned flag textures per language; the yellow box marks FLanguage
    FFlagTextures: array [TLanguage] of PSdlTexture;
    FLanguage: TLanguage;
    FShowcase: TShowcaseKind;
    procedure SetHasActiveGame(AValue: Boolean);
    procedure SetLanguage(AValue: TLanguage);
    function LoadTexture(const AFileName: string): PSdlTexture;
    procedure ShowScreen(AScreen: TMenuScreen);
    procedure AddItem(const ACaption: string; AAction: TItemAction;
      const ALevelFile: string = '');
    function ItemTop(AIndex: Integer): Double;
    function ItemWidth(const AItem: TMenuItem): Double;
    function HoveredIndex: Integer;
    // One geometry for drawing AND hit-testing a flag - what you see
    // is what you click, same principle as the caption rectangles
    function FlagRect(ALanguage: TLanguage): TSdlFRect;
    function TryHoveredFlag(out ALanguage: TLanguage): Boolean;
    function ExecuteItem(const AItem: TMenuItem): TMenuResult;
    procedure DrawLogo(AAlpha: Double);
    procedure DrawShowcaseLogo(AAlpha: Double);
    procedure DrawItems;
    procedure DrawDifficultyCells(AX, AY: Double);
    procedure DrawFlags;
    procedure DrawCredits;
    procedure DrawDifficultyNote;
    procedure DrawCursor;
    procedure DrawVersion;
  public
    constructor Create(const ARenderer: PSdlRenderer;
      const ASprites: TSpriteRenderer; const AFont: TMoonFont;
      const ALevels: TArray<TLevelChoice>; const ASpriteSet: TSpriteSet;
      const AWeaponSet: TSpriteSet);
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
    property Difficulty: TDifficulty read FDifficulty write FDifficulty;
    // Set by the composition root AFTER it swapped the dictionary -
    // the setter rebuilds the current screen's captions through Tr
    property Language: TLanguage read FLanguage write SetLanguage;
  end;

implementation

uses
  Sdl2.Image;

// Every caption a player reads lives in lang\*.json now (part 6): the
// S-keys moved to Localization, sites fetch them through Tr(). The
// archaeology notes (verbatim colons, hint deviations) moved with them.
resourcestring
  // Developer-facing, never localized
  SMenuTextureFailed = 'Cannot load menu texture "%s": %s';

const
  // 2008 drew the menu in GL normalized device coords over the whole
  // window; the conversion is the same one Render.Font froze. These
  // size the 2008 quads (moon, logo); positions and spans go by
  // the frame, which the wide screen will grow past the 2008 window.
  UnitsPerNdcX = 256.0; // 2.0 NDC = 512 game units
  UnitsPerNdcY = 192.0; // 2.0 NDC = 384 game units

  SkyFile = 'sky.png';           // 16:9 nebula, cropped to the frame
  // The art is stored brighter than it is shown: the shade is the live
  // tuning knob, and the stored pixels keep their dither
  SkyShade = 170;
  MoonMapFile = 'moonmap.png';   // 2048x1024 equirectangular surface
  LogoFile = 'logo.png';         // 2:1, letters alone, transparent around

  // TMoonDrift passport, verbatim MoonTimer / LoadMoonTexture:
  MoonDriftSpeed = 1;        // drift units per tick, leftward
  MoonDriftLimit = 650;      // respawn X and the out-of-bounds edge
  MoonFirstEntryX = 500;     // the very first moon enters half-visible
  MoonRespawnYSpread = 350;  // DriftY = Random(350) - 175
  MoonDeltaYSteps = 40;      // DeltaY = (Random(40) - 20) / 50
  MoonDeltaYScale = 50;

  // The globe is round and sized by the frame's height, so it keeps its
  // share of the picture when the frame grows wide. The 2008 quad was
  // 0.6 NDC on both axes - 153.6 x 115.2 units, a 4:3-stretched disc.
  MoonDiameter = 0.35 * FrameHeight; // 134.4
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
  // Items stand at the 2008 column 17: the gap to the logo then equals
  // the logo's own left margin. The hover hitbox follows this constant.
  ItemColumnX = 17 * BigGlyphWidth; // 282.9
  LogoCaptionX = 1 * BigGlyphWidth;
  LogoCaptionY = 28 * BigRowStep;    // line2(...,1,28)

  // Hovered caption is double-drawn with this offset - a faux bold.
  // 2008 signalled hover through the cursor sprite alone.
  HoverBoldOffset = 0.7;

  // The difficulty grade as a row of health cells - the instrument that
  // shows monster vitality in play, and vitality is what the grade sets.
  // Fonty glyphs keep their ink in pixels 4..22 of the 28-pixel cell;
  // the cells sit in that band, as tall as a capital.
  DifficultyGrades = Ord(High(TDifficulty)) + 1;
  DifficultyCellTop = 4 / FontCellPx * BigGlyphHeight;
  DifficultyCellSize = 18 / FontCellPx * BigGlyphHeight;
  DifficultyCellGap = 2.0;
  DifficultyCellsIndent = 0.5 * BigGlyphWidth; // air after the caption
  DifficultyCellsWidth = DifficultyGrades * DifficultyCellSize +
    (DifficultyGrades - 1) * DifficultyCellGap;
  // The glyph color of the fonty atlas
  MenuInkColor: TRgb = (R: 188; G: 255; B: 0);

  // The language flags (part 6.2): top-right corner of the main screen,
  // rightmost = highest TLanguage id. Files follow LanguageIds - a
  // third language later is one PNG plus one enum entry.
  FlagFileFmt = 'flag_%s.png';   // 240x160 px art drawn into 30x20 units
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
  // Deviation from 2008 (column 24, row 1): the title opens the item
  // column and sits centered on the flags, one top line for both
  TitleX = ItemColumnX;
  TitleY = FlagTop + (FlagHeight - SmallGlyphHeight) / 2; // 13.2
  // The version tag sits in the bottom-right corner, the one spot no
  // screen of the menu ever draws into
  VersionMargin = 6.0;

  // Cursor frames, same art the gameplay crosshair uses (target.pas):
  // 1 idle, 2 over an item, 4 over anything that quits (VidKursora).
  // Frame 3 (the wounded-target yellow) rides along unused here - the
  // menu has nothing half-dead to point at; gameplay employs it.
  CursorFrameFiles: array [1..4] of string =
    ('weapon\target.png', 'weapon\target1.png', 'weapon\target2.png',
     'weapon\target3.png');
  CursorIdleFrame = 1;
  CursorHoverFrame = 2;
  CursorQuitFrame = 4;
  // The crosshair art sits off-center in its bitmap; these are the
  // player-calibrated offsets of Hero (NumPad tuner, 2026-07-12)
  CursorOffsetX = 9;
  CursorOffsetY = 10;

// The largest centered window of the texture with the frame's
// proportions: the backdrop is cropped to the frame, never squeezed
function CoverSource(ATexture: PSdlTexture; AAspect: Single): TSdlRect;
var
  Width, Height: Integer;
begin
  SDL_QueryTexture(ATexture, nil, nil, @Width, @Height);
  Result.W := Width;
  Result.H := Height;
  if Width / Height > AAspect then
    Result.W := Round(Height * AAspect)
  else
    Result.H := Round(Width / AAspect);
  Result.X := (Width - Result.W) div 2;
  Result.Y := (Height - Result.H) div 2;
end;

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
  const ALevels: TArray<TLevelChoice>; const ASpriteSet: TSpriteSet;
  const AWeaponSet: TSpriteSet);
begin
  inherited Create;
  FSpriteSet := ASpriteSet;
  FRenderer := ARenderer;
  FSprites := ASprites;
  FFont := AFont;
  FLevels := ALevels;

  FCache := TSpriteCache.Create(ARenderer);
  if ASpriteSet <> nil then
    FCache.AttachSpriteSet(ASpriteSet);
  if AWeaponSet <> nil then
    FCache.AttachSpriteSet(AWeaponSet);

  FSkyTexture := LoadTexture(SkyFile);
  // Shrunk from the art's own size: nearest-neighbor would sparkle
  SDL_SetTextureScaleMode(FSkyTexture, SdlScaleModeLinear);
  SDL_SetTextureColorMod(FSkyTexture, SkyShade, SkyShade, SkyShade);
  FSkySource := CoverSource(FSkyTexture, FrameWidth / FrameHeight);
  FGlobe := TMoonGlobe.Create(ARenderer, ASpriteSet, MoonMapFile);
  FLogo := TMenuLogo.Create(ARenderer, ASpriteSet, LogoFile);
  // Flags are plain rectangles - no transparency, the color-key
  // machinery stays out (the Union Jack navy would survive the
  // threshold anyway, but why even ask)
  for var Language := Low(TLanguage) to High(TLanguage) do
  begin
    FFlagTextures[Language] :=
      LoadTexture(Format(FlagFileFmt, [LanguageIds[Language]]));
    // Shrunk to the window: nearest-neighbor would saw the diagonals
    SDL_SetTextureScaleMode(FFlagTextures[Language], SdlScaleModeLinear);
  end;
  // The dictionary is already loaded by the composition root; the
  // yellow box must agree with it from the very first frame
  FLanguage := CurrentLanguage;

  FStarfield := TStarfield.Create(ARenderer, FrameWidth, FrameHeight);
  FBrush := THudBrush.Create(ARenderer);
  FMoon.Respawn;
  FMoon.DriftX := MoonFirstEntryX;

  ShowMain;
end;

destructor TMoonMenu.Destroy;
begin
  for var Language := Low(TLanguage) to High(TLanguage) do
    if Assigned(FFlagTextures[Language]) then
      SDL_DestroyTexture(FFlagTextures[Language]);
  FLogo.Free;
  FGlobe.Free;
  if Assigned(FSkyTexture) then
    SDL_DestroyTexture(FSkyTexture);
  FBrush.Free;
  FStarfield.Free;
  FCache.Free;
  inherited;
end;

// The art as stored: opaque art stays opaque, art with an alpha channel
// comes out alpha-blended - SDL sets the blend mode for it
function TMoonMenu.LoadTexture(const AFileName: string): PSdlTexture;
var
  Surface: PSdlSurface;
begin
  Surface := LoadImageSurface(FSpriteSet, AFileName);
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

procedure TMoonMenu.SetHasActiveGame(AValue: Boolean);
begin
  if FHasActiveGame = AValue then
    Exit;
  FHasActiveGame := AValue;
  if FScreen = msMain then
    ShowMain; // the 'Продолжить игру' line appears/disappears
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

procedure TMoonMenu.AddItem(const ACaption: string; AAction: TItemAction;
  const ALevelFile: string);
begin
  var Item := Default(TMenuItem);
  Item.Caption := ACaption;
  Item.Action := AAction;
  Item.LevelFile := ALevelFile;
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
        // The survivor of the 2008 'Опции' screen and its grade
        // submenu: a click cycles the grade in place, the cells show it
        AddItem(Tr(SDifficultyTitle), iaDifficulty);
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
       (FMouseX < ItemColumnX + ItemWidth(FItems[i])) then
      Exit(i);
  end;
  Result := -1;
end;

// The caption plus whatever rides after it
function TMoonMenu.ItemWidth(const AItem: TMenuItem): Double;
begin
  Result := FFont.BigTextWidth(AItem.Caption);
  if AItem.Action = iaDifficulty then
    Result := Result + DifficultyCellsIndent + DifficultyCellsWidth;
end;

function TMoonMenu.FlagRect(ALanguage: TLanguage): TSdlFRect;
begin
  // Rightmost slot belongs to the highest language id; earlier ids
  // stack leftward, one flag plus one gap per slot
  var SlotsFromRight := Ord(High(TLanguage)) - Ord(ALanguage);
  Result.X := FrameWidth - FlagMargin - FlagWidth
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

// Wild wraps around to normal
function NextDifficulty(AValue: TDifficulty): TDifficulty;
begin
  if AValue = High(TDifficulty) then
    Result := Low(TDifficulty)
  else
    Result := Succ(AValue);
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
      begin
        FDifficulty := NextDifficulty(FDifficulty);
        Result.Command := mcSetDifficulty;
        Result.Difficulty := FDifficulty;
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
  FGlobe.Tick;
  FStarfield.Tick;
  FLogo.Tick;
end;

procedure TMoonMenu.DrawSky(AAlpha: Double);
var
  Dest: TSdlFRect;
begin
  // Sky fills the frame edge to edge (PutSkyTexture quad -1..1)
  Dest.X := 0;
  Dest.Y := 0;
  Dest.W := FrameWidth;
  Dest.H := FrameHeight;
  SDL_RenderCopyF(FRenderer, FSkyTexture, @FSkySource, @Dest);

  FStarfield.Draw(AAlpha);

  // The moon slides MoonDriftSpeed per tick; the interpolation must use
  // the same constant or the two would silently disagree
  var DriftX := FMoon.DriftX - MoonDriftSpeed * AAlpha;
  var DriftY := FMoon.DriftY + FMoon.DeltaY * AAlpha;
  var CenterX := FrameWidth / 2 + DriftX * MoonUnitsPerDriftX;
  var CenterY := FrameHeight / 2 - DriftY * MoonUnitsPerDriftY;
  Dest.X := CenterX - MoonDiameter / 2;
  Dest.Y := CenterY - MoonDiameter / 2;
  Dest.W := MoonDiameter;
  Dest.H := MoonDiameter;
  FGlobe.Draw(Dest);
end;

// The logo greets fresh visitors; over a running game the menu keeps
// the scenery but drops the marquee sign (LogoView of 2008). The story
// screen never shows it - text and logo shared no frame in the original.
procedure TMoonMenu.DrawLogo(AAlpha: Double);
var
  Dest: TSdlFRect;
begin
  Dest.X := LogoLeft;
  Dest.Y := LogoTop;
  Dest.W := LogoWidth;
  Dest.H := LogoHeight;
  FLogo.Draw(Dest, AAlpha);
  FFont.DrawBig(Tr(SLogoCaption), LogoCaptionX, LogoCaptionY);
end;

procedure TMoonMenu.DrawItems;
begin
  FFont.DrawSmall(FTitle, TitleX, TitleY);

  var Hovered := HoveredIndex;
  for var i := 0 to High(FItems) do
  begin
    FFont.DrawBig(FItems[i].Caption, ItemColumnX, ItemTop(i));
    if FItems[i].Action = iaDifficulty then
      DrawDifficultyCells(ItemColumnX + FFont.BigTextWidth(FItems[i].Caption) +
        DifficultyCellsIndent, ItemTop(i));
    // Faux bold on hover: the same caption a hair to the right fattens
    // every stroke (2008 signalled hover only through the cursor)
    if i = Hovered then
      FFont.DrawBig(FItems[i].Caption, ItemColumnX + HoverBoldOffset,
        ItemTop(i));
  end;
end;

// Grades fill from the left: normal lights one cell, wild all of them
procedure TMoonMenu.DrawDifficultyCells(AX, AY: Double);
begin
  var RowY := AY + DifficultyCellTop;
  FBrush.BeginDraw;
  for var i := 0 to DifficultyGrades - 1 do
  begin
    var CellX := AX + i * (DifficultyCellSize + DifficultyCellGap);
    if i <= Ord(FDifficulty) then
      FBrush.FullCell(CellX, RowY, DifficultyCellSize, DifficultyCellSize,
        MenuInkColor, 1)
    else
      FBrush.EmptyCell(CellX, RowY, DifficultyCellSize, DifficultyCellSize,
        MenuInkColor, 1);
  end;
  FBrush.EndDraw;
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

function DifficultyNote(AValue: TDifficulty): string;
begin
  case AValue of
    dfHard: Result := Tr(SDiffHard);
    dfWild: Result := Tr(SDiffWild);
  else
    Result := Tr(SDiffNormal);
  end;
end;

// While the cursor rests on Difficulty, the slot of a would-be next item
// names the grade; over a running game a second line says when it bites
procedure TMoonMenu.DrawDifficultyNote;
begin
  var Hovered := HoveredIndex;
  if (Hovered < 0) or (FItems[Hovered].Action <> iaDifficulty) then
    Exit;
  var NoteY := ItemTop(Length(FItems));
  FFont.DrawSmall(DifficultyNote(FDifficulty), ItemColumnX, NoteY);
  if FHasActiveGame then
    FFont.DrawSmall(Tr(SDiffHintLive), ItemColumnX, NoteY + SmallLineStep);
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

procedure TMoonMenu.DrawVersion;
begin
  var Text := 'v' + GameVersion;
  FFont.DrawSmall(Text,
    FrameWidth - FFont.SmallTextWidth(Text) - VersionMargin,
    FrameHeight - SmallLineStep - VersionMargin);
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
procedure TMoonMenu.DrawShowcaseLogo(AAlpha: Double);
var
  Dest: TSdlFRect;
begin
  Dest.W := ShowcaseLogoWidth;
  Dest.H := ShowcaseLogoHeight;
  Dest.X := (FrameWidth - Dest.W) / 2;
  Dest.Y := (FrameHeight - Dest.H) / 2;
  FLogo.Draw(Dest, AAlpha);
end;

procedure TMoonMenu.Draw(AAlpha: Double);
begin
  DrawSky(AAlpha);
  // Showcase frames draw no items, flags or cursor
  if FShowcase <> skNone then
  begin
    if FShowcase = skLogo then
      DrawShowcaseLogo(AAlpha);
    Exit;
  end;
  if not FHasActiveGame then
    DrawLogo(AAlpha);
  if FScreen = msCredits then
    DrawCredits;
  DrawItems;
  DrawDifficultyNote;
  if FScreen = msMain then
    DrawFlags;
  DrawVersion;
  DrawCursor;
end;

end.
