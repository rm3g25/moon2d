{
  Render.Font - bitmap font renderer, the SDL2 heir of moonfont1.pas (2008).

  The atlas is a single 448x448 BMP holding a 16x16 grid of glyph cells
  (28x28 px each). A glyph is found by its CP1251 byte code MINUS ONE -
  the 2008 atlas is shifted one cell ("зачем -1 непомню хоть убейте",
  as the original author documented). Transparency follows the original
  threshold, not a plain color key: everything darker than (43,33,23)
  is background - the atlas has dark dirt around the glyphs.

  Two text sizes survive from 2008: line() (small, HUD and messages)
  and line2() (big, titles). Their glyph metrics were normalized GL
  coordinates over the whole window; here they are converted once into
  the 512x384 game units and frozen as constants below.

  ORIENTATION TRAP: the 2008 GL loader uploaded the bitmap transposed
  (TexA[i,j] with the slow index along x) and sampled with a vertical
  flip. Net effect: the file it displayed correctly stores the glyphs
  rotated 90 degrees clockwise. fontx.bmp / fonty.bmp are almost surely
  the two orientations of the same atlas. Press F in a DEBUGKEYS build
  to see the raw atlas and pick the right TFontAtlasOrientation.

  Moon 2D remake. Requires Delphi 12+.
}
unit Render.Font;
{$I Moon2D.inc}

interface

uses
  System.SysUtils, Sdl2.Core, Sprites.Sets;

const
  FontAtlasSize = 448; // atlas side in pixels (TexSizeX/TexSizeY of 2008)
  FontGridCells = 16;  // glyphs per atlas row/column (q = 1/16 of 2008)
  FontCellPx = FontAtlasSize div FontGridCells; // 28 px per glyph cell

  // 2008 drew text in GL normalized device coords (-1..1 over the whole
  // window) while the game logic ran in 512x384 units. Conversion:
  // 2.0 NDC = 512 units horizontally (1 NDC-x = 256 units) and
  // 2.0 NDC = 384 units vertically (1 NDC-y = 192 units).
  // line() of 2008 took its x argument in 0.05-NDC steps - a coordinate
  // grid COARSER than the glyphs themselves (12.8 units vs 7.68 per
  // glyph). The message board still thinks in these columns.
  LegacyColumnWidth = 0.05 * 256; // 12.8

  SmallGlyphWidth = 0.03 * 256;  // 7.68 - line(): quad -1 .. -0.97
  SmallGlyphHeight = 0.05 * 192; // 9.6  - line(): quad 0.95 .. 1
  SmallAdvance = SmallGlyphWidth;   // line() stepped exactly one glyph
  SmallLineStep = SmallGlyphHeight; // line() y arguments stepped 0.05 NDC

  BigGlyphWidth = 0.065 * 256;  // 16.64 - line2(): w
  BigGlyphHeight = 0.065 * 192; // 12.48 - line2(): h
  BigAdvanceRatio = 0.8;        // line2() step w-0.2*w: 20% overlap
  BigAdvance = BigAdvanceRatio * BigGlyphWidth;
  // Width-to-height of a big glyph (4:3); DrawScaled keeps this shape
  // at any size so every overlay still reads as the game's typeface
  BigGlyphAspect = BigGlyphWidth / BigGlyphHeight;

type
  EFontError = class(Exception);

  // How the glyphs are stored in the atlas FILE (see the unit header).
  // faRotatedCw = the GL-era file: content rotated 90 degrees clockwise,
  // un-rotated once at load. faUpright = a normally drawn atlas.
  TFontAtlasOrientation = (faUpright, faRotatedCw);

  TMoonFont = class
  private
    FRenderer: PSdlRenderer;
    FSpriteSet: TSpriteSet; // attached, not owned; nil = plain file
    FAtlas: PSdlTexture;
    procedure LoadAtlas(const AFileName: string;
      AOrientation: TFontAtlasOrientation);
    procedure DrawTextLine(const AText: string;
      AX, AY, AGlyphW, AGlyphH, AAdvance: Double; AAlpha: UInt8);
  public
    constructor Create(const ARenderer: PSdlRenderer;
      const AFileName: string; AOrientation: TFontAtlasOrientation;
      const ASpriteSet: TSpriteSet = nil);
    destructor Destroy; override;

    // line() of 2008: small text. AX/AY are game units of the top-left.
    // AAlpha 255 = opaque; the fade-out of expiring notices lives here.
    procedure DrawSmall(const AText: string; AX, AY: Double;
      AAlpha: UInt8 = 255);
    // line2() of 2008: big text for titles and location names.
    procedure DrawBig(const AText: string; AX, AY: Double;
      AAlpha: UInt8 = 255);
    // Multi-line small text: splits on LF, one SmallLineStep per line
    // (2008 stepped intro lines by whole y positions - zero leading;
    // the glyph cells carry their own margins).
    procedure DrawSmallBlock(const AText: string; AX, AY: Double);

    // Widths in game units - for centering text on screen.
    function SmallTextWidth(const AText: string): Double;
    function BigTextWidth(const AText: string): Double;

    // Arbitrary-height text for cinematic overlays (henshin countdown).
    // Width and advance keep the DrawBig proportions (4:3 glyph, 20%
    // overlap), so any size still reads as the game's own typeface.
    procedure DrawScaled(const AText: string; AX, AY, AGlyphHeight: Double;
      AAlpha: UInt8 = 255);
    function ScaledTextWidth(const AText: string;
      AGlyphHeight: Double): Double;

    // Debug: the raw atlas, scaled into a square - the one-glance test
    // for the orientation trap described in the unit header.
    procedure DrawAtlas(AX, AY, ASize: Integer);
  end;

implementation

uses
  Sdl2.Image, Render.Sprites;

resourcestring
  SFontFileLoadFailed = 'Cannot load font atlas "%s": %s';
  SFontSurfaceFailed = 'Cannot prepare font atlas "%s": %s';
  SFontTextureFailed = 'Cannot create font texture for "%s": %s';

type
  // The 2008 glyph index is the CP1251 byte of the character; modern
  // Delphi strings are UTF-16, so every draw converts through this.
  TCp1251String = type AnsiString(1251);

  PPixelBytes = ^TPixelBytes;
  TPixelBytes = array [0..3] of Byte; // R,G,B,A memory order of
                                      // SdlPixelFormatAbgr8888 (LE)

// Verbatim 2008 transparency: not a color key but a darkness threshold -
// the atlas background is black-ish with dark dirt around the glyphs.
procedure ApplyAlphaThreshold(const ASurface: PSdlSurface);
const
  KeyMaxRed = 43;   // moonfont1.pas: TexA[i,j,0] < 43
  KeyMaxGreen = 33; // TexA[i,j,1] < 33
  KeyMaxBlue = 23;  // TexA[i,j,2] < 23
begin
  SDL_LockSurface(ASurface);
  try
    for var i := 0 to ASurface.H - 1 do
    begin
      var Pixel := PPixelBytes(PByte(ASurface.Pixels) + i * ASurface.Pitch);
      for var j := 0 to ASurface.W - 1 do
      begin
        if (Pixel[0] < KeyMaxRed) and (Pixel[1] < KeyMaxGreen) and
           (Pixel[2] < KeyMaxBlue) then
          Pixel[3] := 0
        else
          Pixel[3] := 255;
        Inc(Pixel);
      end;
    end;
  finally
    SDL_UnlockSurface(ASurface);
  end;
end;

// Un-rotates a GL-era atlas (see the unit header). Derived from the 2008
// sampling math: upright pixel (x, y) lives in the file at (W-1-y, x).
// Caller owns both surfaces.
function RebuildUpright(const ASource: PSdlSurface): PSdlSurface;
begin
  Result := SDL_CreateRGBSurfaceWithFormat(0, ASource.W, ASource.H,
    32, SdlPixelFormatAbgr8888);
  if Result = nil then
    raise EFontError.Create(SdlErrorText);

  SDL_LockSurface(ASource);
  SDL_LockSurface(Result);
  try
    for var i := 0 to Result.H - 1 do // upright row
    begin
      var Dest := PUInt32(PByte(Result.Pixels) + i * Result.Pitch);
      for var j := 0 to Result.W - 1 do // upright column
      begin
        Dest^ := PUInt32(PByte(ASource.Pixels) +
          j * ASource.Pitch + (ASource.W - 1 - i) * SizeOf(UInt32))^;
        Inc(Dest);
      end;
    end;
  finally
    SDL_UnlockSurface(Result);
    SDL_UnlockSurface(ASource);
  end;
end;

// ---------------------------------------------------------------------------
// TMoonFont
// ---------------------------------------------------------------------------

constructor TMoonFont.Create(const ARenderer: PSdlRenderer;
  const AFileName: string; AOrientation: TFontAtlasOrientation;
  const ASpriteSet: TSpriteSet);
begin
  inherited Create;
  FRenderer := ARenderer;
  FSpriteSet := ASpriteSet;
  LoadAtlas(AFileName, AOrientation);
end;

destructor TMoonFont.Destroy;
begin
  if Assigned(FAtlas) then
    SDL_DestroyTexture(FAtlas);
  inherited;
end;

procedure TMoonFont.LoadAtlas(const AFileName: string;
  AOrientation: TFontAtlasOrientation);
var
  Loaded: PSdlSurface;
  Atlas: PSdlSurface;
begin
  Loaded := LoadImageSurface(FSpriteSet, AFileName);
  if Loaded = nil then
    raise EFontError.CreateFmt(SFontFileLoadFailed,
      [AFileName, SdlErrorText]);

  // The BMP is 24-bit; the threshold needs an alpha channel to write to.
  Atlas := SDL_ConvertSurfaceFormat(Loaded, SdlPixelFormatAbgr8888, 0);
  SDL_FreeSurface(Loaded);
  if Atlas = nil then
    raise EFontError.CreateFmt(SFontSurfaceFailed,
      [AFileName, SdlErrorText]);

  try
    if AOrientation = faRotatedCw then
    begin
      var Upright := RebuildUpright(Atlas);
      SDL_FreeSurface(Atlas);
      Atlas := Upright;
    end;

    ApplyAlphaThreshold(Atlas);

    FAtlas := SDL_CreateTextureFromSurface(FRenderer, Atlas);
    if FAtlas = nil then
      raise EFontError.CreateFmt(SFontTextureFailed,
        [AFileName, SdlErrorText]);
    SDL_SetTextureBlendMode(FAtlas, SdlBlendModeBlend);
  finally
    SDL_FreeSurface(Atlas);
  end;
end;

procedure TMoonFont.DrawTextLine(const AText: string;
  AX, AY, AGlyphW, AGlyphH, AAdvance: Double; AAlpha: UInt8);
var
  Bytes: TCp1251String;
  Src: TSdlRect;
  Dest: TSdlFRect;
begin
  Bytes := TCp1251String(AText);
  SDL_SetTextureAlphaMod(FAtlas, AAlpha);

  Src.W := FontCellPx;
  Src.H := FontCellPx;
  Dest.W := AGlyphW;
  Dest.H := AGlyphH;
  Dest.Y := AY;

  // Float destination rects end the rounding saga: glyph advance is
  // exact, so letters never shiver against each other, and a moving
  // line glides in sub-pixel steps instead of snapping to the coarse
  // logical grid (1 logical pixel = 2 window pixels at 1024x768).
  for var i := 1 to Length(Bytes) do
  begin
    var GlyphIndex := Ord(Bytes[i]) - 1; // the 2008 atlas is shifted a cell
    if GlyphIndex < 0 then
      Continue;

    Src.X := (GlyphIndex mod FontGridCells) * FontCellPx;
    Src.Y := (GlyphIndex div FontGridCells) * FontCellPx;
    Dest.X := AX + (i - 1) * AAdvance;

    SDL_RenderCopyF(FRenderer, FAtlas, @Src, @Dest);
  end;

  // Leave the atlas opaque for whoever draws next (DrawAtlas included).
  if AAlpha <> 255 then
    SDL_SetTextureAlphaMod(FAtlas, 255);
end;

procedure TMoonFont.DrawSmall(const AText: string; AX, AY: Double;
  AAlpha: UInt8);
begin
  DrawTextLine(AText, AX, AY,
    SmallGlyphWidth, SmallGlyphHeight, SmallAdvance, AAlpha);
end;

procedure TMoonFont.DrawBig(const AText: string; AX, AY: Double;
  AAlpha: UInt8);
begin
  DrawTextLine(AText, AX, AY, BigGlyphWidth, BigGlyphHeight, BigAdvance,
    AAlpha);
end;

procedure TMoonFont.DrawSmallBlock(const AText: string; AX, AY: Double);
begin
  var Lines := AText.Replace(#13, '').Split([#10]);
  for var i := 0 to High(Lines) do
    DrawSmall(Lines[i], AX, AY + i * SmallLineStep);
end;

function TMoonFont.SmallTextWidth(const AText: string): Double;
begin
  // Small advance equals the glyph width, so the last glyph adds nothing.
  Result := Length(TCp1251String(AText)) * SmallAdvance;
end;

function TMoonFont.BigTextWidth(const AText: string): Double;
begin
  var GlyphCount := Length(TCp1251String(AText));
  if GlyphCount = 0 then
    Exit(0);
  // Big glyphs overlap by 20%; the last one still shows its full width.
  Result := (GlyphCount - 1) * BigAdvance + BigGlyphWidth;
end;

procedure TMoonFont.DrawScaled(const AText: string;
  AX, AY, AGlyphHeight: Double; AAlpha: UInt8);
begin
  var GlyphW := AGlyphHeight * BigGlyphAspect;
  DrawTextLine(AText, AX, AY, GlyphW, AGlyphHeight,
    BigAdvanceRatio * GlyphW, AAlpha);
end;

function TMoonFont.ScaledTextWidth(const AText: string;
  AGlyphHeight: Double): Double;
begin
  var GlyphCount := Length(TCp1251String(AText));
  if GlyphCount = 0 then
    Exit(0);
  var GlyphW := AGlyphHeight * BigGlyphAspect;
  Result := (GlyphCount - 1) * (BigAdvanceRatio * GlyphW) + GlyphW;
end;

procedure TMoonFont.DrawAtlas(AX, AY, ASize: Integer);
var
  Dest: TSdlRect;
begin
  Dest.X := AX;
  Dest.Y := AY;
  Dest.W := ASize;
  Dest.H := ASize;
  SDL_RenderCopy(FRenderer, FAtlas, nil, @Dest);
end;

end.
