{
  Render.Glow - light drawn instead of loaded: soft shapes generated
  at startup and added onto whatever is beneath them.

  A glow texture is white with the shape in its alpha, so one texture
  serves every color and brightness: the tint arrives at draw time as
  a color mod, the level as an alpha mod. Additive blending makes two
  glows over each other brighter, never muddier, which is how light
  behaves and how a menu star, a spark and a halo all want to look.

  The shapes here are analytic (a Gaussian point, a spiked flare, the
  long thin cross of a starburst, the streak of a spark, the band a
  bolt of lightning is drawn on); a shape computed elsewhere - a
  blurred logo, say - comes in as a surface through CreateGlowTexture
  and leaves with the same blend and filter settings.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Render.Glow;
{$I ..\Moon2D.inc}

interface

uses
  System.SysUtils, Sdl2.Core, Render.Brush;

type
  EGlowError = class(Exception);

  // gsStreak lies along X: the hot end at the right edge, the tail
  // thinning out to the left. gsBeam is a Gaussian across Y and flat
  // along X: a strip of triangles laid along a path shows its middle
  // bright and its edges clear.
  TGlowShape = (gsPoint, gsFlare, gsStarburst, gsStreak, gsBeam);

// A square texture of ASide pixels with the shape in its alpha
function CreateGlowShape(ARenderer: PSdlRenderer; AShape: TGlowShape;
  ASide: Integer): PSdlTexture;
// A texture from a surface the caller filled (ABGR8888, white pixels,
// the shape in alpha): additive, linear-filtered. The surface stays
// the caller's to free.
function CreateGlowTexture(ARenderer: PSdlRenderer;
  ASurface: PSdlSurface): PSdlTexture;
// APasses box blurs of ARadius: three make a near-Gaussian bloom.
// Outside the image counts as dark.
procedure BlurImage(var AImage: TArray<Single>; AWidth, AHeight, ARadius,
  APasses: Integer);
// A glow out of an image of levels: scaled so its peak is one, white
// with the levels in alpha
function CreateGlowFromImage(ARenderer: PSdlRenderer;
  const AImage: TArray<Single>; AWidth, AHeight: Integer): PSdlTexture;
// The texture centered on the point, ASize units on a side
procedure DrawGlow(ARenderer: PSdlRenderer; ATexture: PSdlTexture;
  ACenterX, ACenterY, ASize: Single; ATint: TRgb; ALevel: Single);
procedure DrawGlowRect(ARenderer: PSdlRenderer; ATexture: PSdlTexture;
  const ADest: TSdlFRect; ATint: TRgb; ALevel: Single);

implementation

uses
  System.Math;

resourcestring
  SGlowTextureFailed = 'Cannot create a glow texture: %s';

const
  // Shape metrics in half-sides: 1.0 = from the center to the edge
  PointSigma = 0.3;
  FlareCoreRadius = 0.07;
  FlareHaloRadius = 0.28;
  FlareHaloLevel = 0.22;
  FlareSpikeWidth = 0.03;
  FlareSpikeLevel = 0.55;
  // Thinner than a flare spike and slower to fade: a ray, not a spark
  StarburstRayWidth = 0.012;
  StreakSigma = 0.45;
  // Small enough that the band is clear at its edges
  BeamSigma = 0.4;
  // Typed: Power has three overloads
  StreakTailPower: Single = 1.5;
  // The hot end rounds off over this share of the length, so a streak
  // stretched long does not end in a cut
  StreakCapShare = 0.12;

function PointAlpha(ADX, ADY: Single): Single;
begin
  Result := Exp(-(ADX * ADX + ADY * ADY) / (2 * PointSigma * PointSigma));
end;

// One spike along the X axis: thin across, fading toward the edge
function SpikeAlpha(AAlong, AAcross: Single): Single;
begin
  var Reach: Single := 1 - Abs(AAlong);
  if Reach <= 0 then
    Exit(0);
  var Fade := Reach * Reach * Reach;
  Result := Exp(-Sqr(AAcross / FlareSpikeWidth)) * Fade;
end;

function StarburstRayAlpha(AAlong, AAcross: Single): Single;
begin
  var Reach: Single := 1 - Abs(AAlong);
  if Reach <= 0 then
    Exit(0);
  Result := Exp(-Sqr(AAcross / StarburstRayWidth)) * Reach * Reach;
end;

// Up, down, left, right - the cross a star filter draws over a lamp
function StarburstAlpha(ADX, ADY: Single): Single;
begin
  Result := Max(StarburstRayAlpha(ADX, ADY), StarburstRayAlpha(ADY, ADX));
end;

function StreakAlpha(ADX, ADY: Single): Single;
begin
  var Along: Single := (ADX + 1) / 2;
  var Body: Single := Along / (1 - StreakCapShare);
  if Body > 1 then
    Body := 1;
  var Cap: Single := (1 - Along) / StreakCapShare;
  if Cap > 1 then
    Cap := 1;
  Result := Power(Body, StreakTailPower) * Cap *
    Exp(-Sqr(ADY / StreakSigma));
end;

function BeamAlpha(ADY: Single): Single;
begin
  Result := Exp(-Sqr(ADY / BeamSigma));
end;

function FlareAlpha(ADX, ADY: Single): Single;
begin
  var Radius: Single := Sqrt(ADX * ADX + ADY * ADY);
  Result := Exp(-Sqr(Radius / FlareCoreRadius)) + FlareSpikeLevel *
    (SpikeAlpha(ADX, ADY) + SpikeAlpha(ADY, ADX));
  if Radius < 1 then
    Result := Result + FlareHaloLevel *
      Exp(-Sqr(Radius / FlareHaloRadius)) * (1 - Radius);
  if Result > 1 then
    Result := 1;
end;

function ShapeAlpha(AShape: TGlowShape; ADX, ADY: Single): Single;
begin
  case AShape of
    gsPoint:
      Result := PointAlpha(ADX, ADY);
    gsStarburst:
      Result := StarburstAlpha(ADX, ADY);
    gsStreak:
      Result := StreakAlpha(ADX, ADY);
    gsBeam:
      Result := BeamAlpha(ADY);
  else
    Result := FlareAlpha(ADX, ADY);
  end;
end;

procedure FillShape(ASurface: PSdlSurface; AShape: TGlowShape);
type
  PPixelBytes = ^TPixelBytes;
  TPixelBytes = array [0..3] of Byte; // R,G,B,A of SdlPixelFormatAbgr8888
begin
  var Half := ASurface.W / 2;
  SDL_LockSurface(ASurface);
  for var Row := 0 to ASurface.H - 1 do
  begin
    var Pixel := PPixelBytes(PByte(ASurface.Pixels) + Row * ASurface.Pitch);
    for var Col := 0 to ASurface.W - 1 do
    begin
      var DX := (Col + 0.5 - Half) / Half;
      var DY := (Row + 0.5 - Half) / Half;
      Pixel[0] := 255;
      Pixel[1] := 255;
      Pixel[2] := 255;
      Pixel[3] := Round(255 * ShapeAlpha(AShape, DX, DY));
      Inc(Pixel);
    end;
  end;
  SDL_UnlockSurface(ASurface);
end;

function CreateGlowShape(ARenderer: PSdlRenderer; AShape: TGlowShape;
  ASide: Integer): PSdlTexture;
begin
  var Surface := SDL_CreateRGBSurfaceWithFormat(0, ASide, ASide, 32,
    SdlPixelFormatAbgr8888);
  if Surface = nil then
    raise EGlowError.CreateFmt(SGlowTextureFailed, [SdlErrorText]);
  try
    FillShape(Surface, AShape);
    Result := CreateGlowTexture(ARenderer, Surface);
  finally
    SDL_FreeSurface(Surface);
  end;
end;

function CreateGlowTexture(ARenderer: PSdlRenderer;
  ASurface: PSdlSurface): PSdlTexture;
begin
  Result := SDL_CreateTextureFromSurface(ARenderer, ASurface);
  if Result = nil then
    raise EGlowError.CreateFmt(SGlowTextureFailed, [SdlErrorText]);
  SDL_SetTextureBlendMode(Result, SdlBlendModeAdd);
  // The game renders nearest-neighbor; a glow must not turn into a
  // square when it is scaled up to the window
  SDL_SetTextureScaleMode(Result, SdlScaleModeLinear);
end;

// One box blur along a line of the image: AStart is the first texel,
// AStep the distance to the next (1 along a row, the width down a
// column). Outside the line counts as dark.
procedure BlurLine(var AImage: TArray<Single>; AStart, AStep, ACount,
  ARadius: Integer);
var
  Line: TArray<Single>;
begin
  SetLength(Line, ACount);
  for var i := 0 to ACount - 1 do
    Line[i] := AImage[AStart + i * AStep];

  var Window := 2 * ARadius + 1;
  var Sum: Single := 0;
  for var i := 0 to Min(ARadius - 1, ACount - 1) do
    Sum := Sum + Line[i];
  for var i := 0 to ACount - 1 do
  begin
    var Entering := i + ARadius;
    if Entering < ACount then
      Sum := Sum + Line[Entering];
    var Leaving := i - ARadius - 1;
    if Leaving >= 0 then
      Sum := Sum - Line[Leaving];
    AImage[AStart + i * AStep] := Sum / Window;
  end;
end;

procedure BoxBlur(var AImage: TArray<Single>; AWidth, AHeight,
  ARadius: Integer);
begin
  for var Row := 0 to AHeight - 1 do
    BlurLine(AImage, Row * AWidth, 1, AWidth, ARadius);
  for var Col := 0 to AWidth - 1 do
    BlurLine(AImage, Col, AWidth, AHeight, ARadius);
end;

procedure BlurImage(var AImage: TArray<Single>; AWidth, AHeight, ARadius,
  APasses: Integer);
begin
  for var i := 1 to APasses do
    BoxBlur(AImage, AWidth, AHeight, ARadius);
end;

function CreateGlowFromImage(ARenderer: PSdlRenderer;
  const AImage: TArray<Single>; AWidth, AHeight: Integer): PSdlTexture;
type
  PPixelBytes = ^TPixelBytes;
  TPixelBytes = array [0..3] of Byte; // R,G,B,A of SdlPixelFormatAbgr8888
begin
  var Peak: Single := 0;
  for var Value in AImage do
    if Value > Peak then
      Peak := Value;
  if Peak <= 0 then
    Peak := 1;

  var Surface := SDL_CreateRGBSurfaceWithFormat(0, AWidth, AHeight, 32,
    SdlPixelFormatAbgr8888);
  if Surface = nil then
    raise EGlowError.CreateFmt(SGlowTextureFailed, [SdlErrorText]);
  try
    SDL_LockSurface(Surface);
    for var Row := 0 to AHeight - 1 do
    begin
      var Pixel := PPixelBytes(PByte(Surface.Pixels) + Row * Surface.Pitch);
      for var Col := 0 to AWidth - 1 do
      begin
        Pixel[0] := 255;
        Pixel[1] := 255;
        Pixel[2] := 255;
        Pixel[3] := Round(255 * AImage[Row * AWidth + Col] / Peak);
        Inc(Pixel);
      end;
    end;
    SDL_UnlockSurface(Surface);
    Result := CreateGlowTexture(ARenderer, Surface);
  finally
    SDL_FreeSurface(Surface);
  end;
end;

procedure DrawGlow(ARenderer: PSdlRenderer; ATexture: PSdlTexture;
  ACenterX, ACenterY, ASize: Single; ATint: TRgb; ALevel: Single);
var
  Dest: TSdlFRect;
begin
  Dest.X := ACenterX - ASize / 2;
  Dest.Y := ACenterY - ASize / 2;
  Dest.W := ASize;
  Dest.H := ASize;
  DrawGlowRect(ARenderer, ATexture, Dest, ATint, ALevel);
end;

procedure DrawGlowRect(ARenderer: PSdlRenderer; ATexture: PSdlTexture;
  const ADest: TSdlFRect; ATint: TRgb; ALevel: Single);
begin
  SDL_SetTextureColorMod(ATexture, ATint.R, ATint.G, ATint.B);
  SDL_SetTextureAlphaMod(ATexture, Round(255 * ALevel));
  SDL_RenderCopyF(ARenderer, ATexture, nil, @ADest);
end;

end.
