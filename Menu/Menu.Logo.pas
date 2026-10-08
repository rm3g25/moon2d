{
  Menu.Logo - the title logo and the light it sheds.

  The art is plain letters on a transparent background; the halo around
  them is computed at startup from the art itself, so a redrawn logo
  brings its own glow. The alpha of the letters is shrunk, blurred wide
  and normalized into a glow texture (Render.Glow) that is added onto
  the sky beneath the letters; its tint is the letters' own hue at full
  brightness. The halo breathes: a slow sine on its level. Sparks
  (Menu.Embers) drift off the outline of the letters.

  The halo reaches past the logo quad, as light does: Draw takes the
  letters' rectangle and spreads the halo around it by the same scale.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Menu.Logo;
{$I ..\Moon2D.inc}

interface

uses
  System.SysUtils, Sdl2.Core, Sprites.Sets, Render.Brush, Menu.Embers;

type
  ELogoError = class(Exception);

  TMenuLogo = class
  private
    FRenderer: PSdlRenderer;
    FLetters: PSdlTexture;
    FHalo: PSdlTexture;
    FHaloTint: TRgb;
    FEmbers: TEmbers;
    FLettersWidth, FLettersHeight: Integer; // texels
    FPhase: Single; // radians of the breathing
    procedure BuildHalo(ASurface: PSdlSurface);
  public
    constructor Create(ARenderer: PSdlRenderer; const ASpriteSet: TSpriteSet;
      const AFileName: string);
    destructor Destroy; override;
    procedure Tick;
    // Letters into ADest, the halo beneath them and around, the
    // embers over everything
    procedure Draw(const ADest: TSdlFRect; AAlpha: Double);
  end;

implementation

uses
  System.Math, Render.Sprites, Render.Glow;

resourcestring
  SLogoLoadFailed = 'Cannot load the logo "%s": %s';

type
  PPixelBytes = ^TPixelBytes;
  TPixelBytes = array [0..3] of Byte; // R,G,B,A of SdlPixelFormatAbgr8888

const
  // The halo is built at a quarter of the letters' resolution: it is
  // blur, and finer texels would only cost time at startup
  HaloScale = 4;
  // Three box passes of this radius make a near-Gaussian bloom; the
  // apron is where the third pass still reaches
  HaloBlurRadius = 5;
  HaloBlurPasses = 3;
  HaloApron = HaloBlurRadius * HaloBlurPasses;
  // Letter texels that count as ink when the tint is averaged
  InkAlpha = 128;
  // The breathing: level = Base + Swing * sin, one breath in 16 seconds
  HaloBaseLevel = 0.55;
  HaloSwing = 0.2;
  HaloBreathTicks = 528;

// The letters' hue at full brightness: the mean color of the ink,
// scaled so its strongest channel is 255
function InkTint(ASurface: PSdlSurface): TRgb;
var
  Sum: array [0..2] of Int64;
begin
  Sum[0] := 0;
  Sum[1] := 0;
  Sum[2] := 0;
  var Count: Int64 := 0;
  for var Row := 0 to ASurface.H - 1 do
  begin
    var Pixel := PPixelBytes(PByte(ASurface.Pixels) + Row * ASurface.Pitch);
    for var Col := 0 to ASurface.W - 1 do
    begin
      if Pixel[3] >= InkAlpha then
      begin
        Inc(Sum[0], Pixel[0]);
        Inc(Sum[1], Pixel[1]);
        Inc(Sum[2], Pixel[2]);
        Inc(Count);
      end;
      Inc(Pixel);
    end;
  end;

  Result := White;
  if Count = 0 then
    Exit;
  var Peak := Max(Max(Sum[0], Sum[1]), Max(Sum[2], 1));
  Result.R := Round(255 * Sum[0] / Peak);
  Result.G := Round(255 * Sum[1] / Peak);
  Result.B := Round(255 * Sum[2] / Peak);
end;

// ---------------------------------------------------------------------------
// TMenuLogo
// ---------------------------------------------------------------------------

constructor TMenuLogo.Create(ARenderer: PSdlRenderer;
  const ASpriteSet: TSpriteSet; const AFileName: string);
var
  Loaded, Surface: PSdlSurface;
begin
  inherited Create;
  FRenderer := ARenderer;

  Loaded := LoadImageSurface(ASpriteSet, AFileName);
  if Loaded = nil then
    raise ELogoError.CreateFmt(SLogoLoadFailed, [AFileName, SdlErrorText]);
  Surface := SDL_ConvertSurfaceFormat(Loaded, SdlPixelFormatAbgr8888, 0);
  SDL_FreeSurface(Loaded);
  if Surface = nil then
    raise ELogoError.CreateFmt(SLogoLoadFailed, [AFileName, SdlErrorText]);
  try
    FLettersWidth := Surface.W;
    FLettersHeight := Surface.H;
    FLetters := SDL_CreateTextureFromSurface(FRenderer, Surface);
    if FLetters = nil then
      raise ELogoError.CreateFmt(SLogoLoadFailed, [AFileName, SdlErrorText]);
    // Scaled to the window: nearest-neighbor would stair-step the letters
    SDL_SetTextureScaleMode(FLetters, SdlScaleModeLinear);

    SDL_LockSurface(Surface);
    try
      FHaloTint := InkTint(Surface);
      BuildHalo(Surface);
      FEmbers := TEmbers.Create(ARenderer, Surface);
    finally
      SDL_UnlockSurface(Surface);
    end;
  finally
    SDL_FreeSurface(Surface);
  end;
end;

destructor TMenuLogo.Destroy;
begin
  FEmbers.Free;
  if Assigned(FHalo) then
    SDL_DestroyTexture(FHalo);
  if Assigned(FLetters) then
    SDL_DestroyTexture(FLetters);
  inherited;
end;

// Alpha shrunk by HaloScale into the middle of an apron-padded image;
// Render.Glow blurs it and makes the glow texture
procedure TMenuLogo.BuildHalo(ASurface: PSdlSurface);
var
  Image: TArray<Single>;
begin
  var Width := (ASurface.W + HaloScale - 1) div HaloScale + 2 * HaloApron;
  var Height := (ASurface.H + HaloScale - 1) div HaloScale + 2 * HaloApron;
  SetLength(Image, Width * Height);

  var BlockArea := HaloScale * HaloScale * 255;
  for var Row := 0 to ASurface.H - 1 do
  begin
    var Pixel := PPixelBytes(PByte(ASurface.Pixels) + Row * ASurface.Pitch);
    var Target := (Row div HaloScale + HaloApron) * Width + HaloApron;
    for var Col := 0 to ASurface.W - 1 do
    begin
      var Cell := Target + Col div HaloScale;
      Image[Cell] := Image[Cell] + Pixel[3] / BlockArea;
      Inc(Pixel);
    end;
  end;

  BlurImage(Image, Width, Height, HaloBlurRadius, HaloBlurPasses);
  FHalo := CreateGlowFromImage(FRenderer, Image, Width, Height);
end;

procedure TMenuLogo.Tick;
begin
  FPhase := FPhase + 2 * Pi / HaloBreathTicks;
  if FPhase > 2 * Pi then
    FPhase := FPhase - 2 * Pi;
  FEmbers.Tick;
end;

procedure TMenuLogo.Draw(const ADest: TSdlFRect; AAlpha: Double);
var
  HaloDest: TSdlFRect;
begin
  // Units per halo texel on each axis, from the letters' scale
  var UnitsX := ADest.W / FLettersWidth * HaloScale;
  var UnitsY := ADest.H / FLettersHeight * HaloScale;
  HaloDest.X := ADest.X - HaloApron * UnitsX;
  HaloDest.Y := ADest.Y - HaloApron * UnitsY;
  HaloDest.W := ADest.W + 2 * HaloApron * UnitsX;
  HaloDest.H := ADest.H + 2 * HaloApron * UnitsY;

  var Phase := FPhase + 2 * Pi / HaloBreathTicks * AAlpha;
  var Level: Single := HaloBaseLevel + HaloSwing * Sin(Phase);
  DrawGlowRect(FRenderer, FHalo, HaloDest, FHaloTint, Level);

  SDL_RenderCopyF(FRenderer, FLetters, nil, @ADest);
  FEmbers.Draw(ADest, AAlpha, FLettersWidth, FLettersHeight);
end;

end.
