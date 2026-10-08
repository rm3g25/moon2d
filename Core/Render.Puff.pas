{
  Render.Puff - smoke drawn instead of loaded: ragged puffs generated at
  level load, several shapes so a plume never repeats one picture.

  A puff is a soft blob eaten into by fractal value noise, its outline
  bent by the same noise so it is not a circle. The pixels are white
  with a mottled brightness, the shape in alpha: the tint arrives at
  draw time as a color mod, the density as an alpha mod. Unlike the
  glows of Render.Glow a puff is alpha blended - smoke hides what is
  behind it, light only adds.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Render.Puff;
{$I ..\Moon2D.inc}

interface

uses
  System.SysUtils, Sdl2.Core, Render.Brush;

const
  PuffShapes = 4;

type
  EPuffError = class(Exception);

  TPuffTextures = array [0..PuffShapes - 1] of PSdlTexture;

// PuffShapes textures of ASide pixels; the caller frees them with
// FreePuffTextures
function CreatePuffTextures(ARenderer: PSdlRenderer;
  ASide: Integer): TPuffTextures;
procedure FreePuffTextures(var ATextures: TPuffTextures);
// The puff centered on the point, ASize units across, turned AAngle
// degrees; ALevel is its density, 0..1
procedure DrawPuff(ARenderer: PSdlRenderer; ATexture: PSdlTexture;
  ACenterX, ACenterY, ASize, AAngle: Single; AColor: TRgb; ALevel: Single);
// The puff stretched into ADest, unturned
procedure DrawPuffRect(ARenderer: PSdlRenderer; ATexture: PSdlTexture;
  const ADest: TSdlFRect; AColor: TRgb; ALevel: Single);

implementation

uses
  System.Math;

resourcestring
  SPuffTextureFailed = 'Cannot create a smoke puff texture: %s';

const
  // Shape metrics in half-sides: 1.0 = from the center to the edge
  NoiseCells = 2.5; // lattice cells across the half-side, coarsest octave
  DetailCells = 4.0; // the brightness mottle
  WarpCells = 1.5;
  WarpReach = 0.35; // how far the outline bends
  NoiseOctaves = 4;
  // Density is the falloff times DensityBase..DensityBase+DensitySpread
  // of the noise: thin wisps where the noise is low
  DensityBase = 0.35;
  DensitySpread = 1.3;
  // The bent outline may reach the texture edge; this ramp keeps the
  // square border out of the picture
  EdgeRamp = 4.0;
  // Brightness from DarkestShade to white across the mottle
  DarkestShade = 0.72;
  // Lattice coordinates run negative a little; the offset keeps them
  // positive for the hash
  LatticeOffset = 1024;
  NoiseWarmUp = 3;
  // Seeds apart for the octaves and the two warp fields
  OctaveSeedStep = 101;
  WarpSeedX = 50;
  WarpSeedY = 60;
  DetailSeed = 200;

type
  PPixelBytes = ^TPixelBytes;
  TPixelBytes = array [0..3] of Byte; // R,G,B,A of SdlPixelFormatAbgr8888

// 0..1 for one lattice point; the same point always rolls the same
function LatticeRoll(ACol, ARow: Integer; ASeed: Cardinal): Single;
var
  Noise: TXorShift;
begin
  Noise.Seed := (Cardinal(ACol + LatticeOffset) shl 16) xor
    Cardinal(ARow + LatticeOffset) xor (ASeed shl 11) or 1;
  for var i := 1 to NoiseWarmUp do
    Noise.NextUnit;
  Result := Noise.NextUnit;
end;

function SmoothStep(AValue: Single): Single;
begin
  Result := AValue * AValue * (3 - 2 * AValue);
end;

function ValueNoise(AX, AY: Single; ASeed: Cardinal): Single;
begin
  var Col := Floor(AX);
  var Row := Floor(AY);
  var AlongX := SmoothStep(AX - Col);
  var AlongY := SmoothStep(AY - Row);
  var Top := LatticeRoll(Col, Row, ASeed) +
    (LatticeRoll(Col + 1, Row, ASeed) - LatticeRoll(Col, Row, ASeed)) * AlongX;
  var Bottom := LatticeRoll(Col, Row + 1, ASeed) +
    (LatticeRoll(Col + 1, Row + 1, ASeed) - LatticeRoll(Col, Row + 1, ASeed)) *
    AlongX;
  Result := Top + (Bottom - Top) * AlongY;
end;

// Octaves of value noise, each twice as fine and half as strong; 0..1
function FractalNoise(AX, AY: Single; ASeed: Cardinal): Single;
begin
  var Sum: Single := 0;
  var Weight: Single := 0;
  var Amplitude: Single := 0.5;
  var Frequency: Single := 1;
  for var Octave := 0 to NoiseOctaves - 1 do
  begin
    Sum := Sum + Amplitude * ValueNoise(AX * Frequency, AY * Frequency,
      ASeed + Cardinal(Octave * OctaveSeedStep));
    Weight := Weight + Amplitude;
    Amplitude := Amplitude / 2;
    Frequency := Frequency * 2;
  end;
  Result := Sum / Weight;
end;

function PuffAlpha(ADX, ADY: Single; ASeed: Cardinal): Single;
begin
  var WarpX: Single := ADX + WarpReach * 2 *
    (FractalNoise(ADX * WarpCells + 7, ADY * WarpCells, ASeed + WarpSeedX) - 0.5);
  var WarpY: Single := ADY + WarpReach * 2 *
    (FractalNoise(ADX * WarpCells, ADY * WarpCells + 3, ASeed + WarpSeedY) - 0.5);
  var Reach: Single := 1 - (WarpX * WarpX + WarpY * WarpY);
  if Reach < 0 then
    Reach := 0;
  var Falloff := Sqr(Reach);
  var Edge := EnsureRange((1 - Sqrt(ADX * ADX + ADY * ADY)) * EdgeRamp, 0.0, 1.0);
  var Noise := FractalNoise(ADX * NoiseCells + ASeed * 3.1, ADY * NoiseCells,
    ASeed);
  Result := EnsureRange(Falloff * Edge * (DensityBase + DensitySpread * Noise),
    0.0, 1.0);
end;

function PuffShade(ADX, ADY: Single; ASeed: Cardinal): Single;
begin
  Result := DarkestShade + (1 - DarkestShade) *
    FractalNoise(ADX * DetailCells, ADY * DetailCells, ASeed + DetailSeed);
end;

procedure FillPuff(ASurface: PSdlSurface; ASeed: Cardinal);
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
      var Shade: Byte := Round(255 * PuffShade(DX, DY, ASeed));
      Pixel[0] := Shade;
      Pixel[1] := Shade;
      Pixel[2] := Shade;
      Pixel[3] := Round(255 * PuffAlpha(DX, DY, ASeed));
      Inc(Pixel);
    end;
  end;
  SDL_UnlockSurface(ASurface);
end;

function CreatePuffTexture(ARenderer: PSdlRenderer; ASide: Integer;
  ASeed: Cardinal): PSdlTexture;
begin
  var Surface := SDL_CreateRGBSurfaceWithFormat(0, ASide, ASide, 32,
    SdlPixelFormatAbgr8888);
  if Surface = nil then
    raise EPuffError.CreateFmt(SPuffTextureFailed, [SdlErrorText]);
  try
    FillPuff(Surface, ASeed);
    Result := SDL_CreateTextureFromSurface(ARenderer, Surface);
  finally
    SDL_FreeSurface(Surface);
  end;
  if Result = nil then
    raise EPuffError.CreateFmt(SPuffTextureFailed, [SdlErrorText]);
  SDL_SetTextureBlendMode(Result, SdlBlendModeBlend);
  // The game renders nearest-neighbor; smoke scaled up to the window
  // must stay soft
  SDL_SetTextureScaleMode(Result, SdlScaleModeLinear);
end;

function CreatePuffTextures(ARenderer: PSdlRenderer;
  ASide: Integer): TPuffTextures;
begin
  Result := Default(TPuffTextures);
  try
    for var i := 0 to PuffShapes - 1 do
      Result[i] := CreatePuffTexture(ARenderer, ASide, i + 1);
  except
    FreePuffTextures(Result);
    raise;
  end;
end;

procedure FreePuffTextures(var ATextures: TPuffTextures);
begin
  for var i := 0 to PuffShapes - 1 do
  begin
    if Assigned(ATextures[i]) then
      SDL_DestroyTexture(ATextures[i]);
    ATextures[i] := nil;
  end;
end;

procedure DrawPuff(ARenderer: PSdlRenderer; ATexture: PSdlTexture;
  ACenterX, ACenterY, ASize, AAngle: Single; AColor: TRgb; ALevel: Single);
var
  Dest: TSdlFRect;
begin
  Dest.X := ACenterX - ASize / 2;
  Dest.Y := ACenterY - ASize / 2;
  Dest.W := ASize;
  Dest.H := ASize;
  SDL_SetTextureColorMod(ATexture, AColor.R, AColor.G, AColor.B);
  SDL_SetTextureAlphaMod(ATexture, Round(255 * ALevel));
  SDL_RenderCopyExF(ARenderer, ATexture, nil, @Dest, AAngle, nil, SdlFlipNone);
end;

procedure DrawPuffRect(ARenderer: PSdlRenderer; ATexture: PSdlTexture;
  const ADest: TSdlFRect; AColor: TRgb; ALevel: Single);
begin
  SDL_SetTextureColorMod(ATexture, AColor.R, AColor.G, AColor.B);
  SDL_SetTextureAlphaMod(ATexture, Round(255 * ALevel));
  SDL_RenderCopyF(ARenderer, ATexture, nil, @ADest);
end;

end.
