{
  Menu.Starfield - the stars of the menu sky, drawn instead of loaded.

  Two textures are generated at startup: a soft point for the ordinary
  star and a four-spike flare for the rare bright one. Every star is one
  of them, tinted and dimmed at draw time and added onto the sky, so the
  art has no pixels to show at any resolution.

  Three depth layers crawl right, each at its own speed. The star count
  of a layer is a density times the frame area: a wider frame gets more
  stars, not stretched ones.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Menu.Starfield;
{$I Moon2D.inc}

interface

uses
  System.SysUtils, Sdl2.Core, Hud.Draw;

type
  EStarfieldError = class(Exception);

  // Depth = 0 is a steady star
  TTwinkle = record
    Phase: Single; // radians
    Step: Single; // radians per tick
    Depth: Single; // share of the brightness a twinkle takes away
  end;

  TStar = record
    X, Y: Single; // center, game units
    Speed: Single; // game units per tick, rightward
    Size: Single; // quad side, game units
    Brightness: Single; // 0..1
    Tint: TRgb;
    IsFlare: Boolean;
    Twinkle: TTwinkle;
  end;

  TStarfield = class
  private
    FRenderer: PSdlRenderer;
    FPointTexture: PSdlTexture;
    FFlareTexture: PSdlTexture;
    FStars: TArray<TStar>;
    FWidth: Single;
    procedure DrawStar(const AStar: TStar; AAlpha: Double);
  public
    constructor Create(ARenderer: PSdlRenderer; AWidth, AHeight: Single);
    destructor Destroy; override;
    procedure Tick;
    procedure Draw(AAlpha: Double);
  end;

implementation

uses
  System.Math;

resourcestring
  SStarTextureFailed = 'Cannot create a star texture: %s';

type
  TSpan = record
    Min, Max: Single;
    function At(AFraction: Single): Single;
  end;

  TStarShape = (ssPoint, ssFlare);

  TStarLayer = record
    Density: Single; // stars per DensityArea of frame
    Speed: Single;
    Size: TSpan;
    Brightness: TSpan;
    FlareShare: Single;
  end;

  TStarTint = record
    Weight: Integer;
    Color: TRgb;
  end;

const
  // "Moon" in ASCII: a fixed seed gives the same sky on every run, which
  // the trailer frames rely on. Anything but zero - xorshift never
  // leaves zero.
  StarfieldSeed = $4D6F6F6E;
  DensityArea = 10000.0; // square game units

  StarLayers: array [0..2] of TStarLayer = (
    (Density: 14.0; Speed: 0.02; Size: (Min: 1.8; Max: 2.6);
      Brightness: (Min: 0.35; Max: 0.8); FlareShare: 0.0),
    (Density: 5.0; Speed: 0.06; Size: (Min: 2.6; Max: 3.8);
      Brightness: (Min: 0.6; Max: 1.0); FlareShare: 0.0),
    (Density: 1.4; Speed: 0.14; Size: (Min: 3.6; Max: 5.0);
      Brightness: (Min: 0.9; Max: 1.0); FlareShare: 0.25));
  FlareSize: TSpan = (Min: 12.0; Max: 17.0);
  // Raises the brightness roll: most stars of a layer sit near its dim
  // end, a few reach the bright one. Typed: Power has three overloads.
  BrightnessSkew: Single = 1.6;

  // Star colors by temperature, hot blue to cool orange. The weights
  // keep the sky mostly white, as a real one is to the eye.
  StarTints: array [0..5] of TStarTint = (
    (Weight: 2; Color: (R: 170; G: 191; B: 255)),
    (Weight: 4; Color: (R: 202; G: 216; B: 255)),
    (Weight: 8; Color: (R: 255; G: 255; B: 255)),
    (Weight: 5; Color: (R: 255; G: 244; B: 232)),
    (Weight: 3; Color: (R: 255; G: 226; B: 184)),
    (Weight: 1; Color: (R: 255; G: 196; B: 140)));

  TwinkleShare = 0.35;
  TwinkleDepth: TSpan = (Min: 0.2; Max: 0.45);
  TwinklePeriodTicks: TSpan = (Min: 50.0; Max: 130.0); // 1.5..4 s

  // Texture sides in pixels, close to the drawn size in window pixels:
  // linear filtering without mipmaps shimmers on a moving star when it
  // shrinks a texture more than about twice
  StarTextureSides: array [TStarShape] of Integer = (8, 48);
  // Shape metrics in half-sides: 1.0 = from the center to the edge
  PointSigma = 0.3;
  FlareCoreRadius = 0.07;
  FlareHaloRadius = 0.28;
  FlareHaloLevel = 0.22;
  FlareSpikeWidth = 0.03;
  FlareSpikeLevel = 0.55;

// ---------------------------------------------------------------------------
// Shapes
// ---------------------------------------------------------------------------

function TSpan.At(AFraction: Single): Single;
begin
  Result := Min + AFraction * (Max - Min);
end;

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

function ShapeAlpha(AShape: TStarShape; ADX, ADY: Single): Single;
begin
  case AShape of
    ssPoint:
      Result := PointAlpha(ADX, ADY);
  else
    Result := FlareAlpha(ADX, ADY);
  end;
end;

// White pixels, the shape in alpha: the tint arrives per star as a
// color mod, the brightness as an alpha mod
procedure FillShape(ASurface: PSdlSurface; AShape: TStarShape);
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

function CreateStarTexture(ARenderer: PSdlRenderer;
  AShape: TStarShape): PSdlTexture;
begin
  var Side := StarTextureSides[AShape];
  var Surface := SDL_CreateRGBSurfaceWithFormat(0, Side, Side, 32,
    SdlPixelFormatAbgr8888);
  if Surface = nil then
    raise EStarfieldError.CreateFmt(SStarTextureFailed, [SdlErrorText]);
  try
    FillShape(Surface, AShape);
    Result := SDL_CreateTextureFromSurface(ARenderer, Surface);
    if Result = nil then
      raise EStarfieldError.CreateFmt(SStarTextureFailed, [SdlErrorText]);
  finally
    SDL_FreeSurface(Surface);
  end;
  SDL_SetTextureBlendMode(Result, SdlBlendModeAdd);
  // The game renders nearest-neighbor; a star must not turn into a
  // square when it is scaled up to the window
  SDL_SetTextureScaleMode(Result, SdlScaleModeLinear);
end;

function PickTint(var ARandom: TXorShift): TRgb;
begin
  var TotalWeight := 0;
  for var Tint in StarTints do
    Inc(TotalWeight, Tint.Weight);

  var Roll := ARandom.NextUnit * TotalWeight;
  for var Tint in StarTints do
  begin
    if Roll < Tint.Weight then
      Exit(Tint.Color);
    Roll := Roll - Tint.Weight;
  end;
  Result := StarTints[High(StarTints)].Color;
end;

function RollTwinkle(var ARandom: TXorShift): TTwinkle;
begin
  Result := Default(TTwinkle);
  if ARandom.NextUnit >= TwinkleShare then
    Exit;
  Result.Phase := ARandom.NextUnit * 2 * Pi;
  Result.Step := 2 * Pi / TwinklePeriodTicks.At(ARandom.NextUnit);
  Result.Depth := TwinkleDepth.At(ARandom.NextUnit);
end;

function RollStar(const ALayer: TStarLayer; AWidth, AHeight: Single;
  var ARandom: TXorShift): TStar;
begin
  Result.X := ARandom.NextUnit * AWidth;
  Result.Y := ARandom.NextUnit * AHeight;
  Result.Speed := ALayer.Speed;
  Result.Size := ALayer.Size.At(ARandom.NextUnit);
  var BrightnessRoll: Single := ARandom.NextUnit;
  Result.Brightness :=
    ALayer.Brightness.At(Power(BrightnessRoll, BrightnessSkew));
  Result.Tint := PickTint(ARandom);
  Result.IsFlare := ARandom.NextUnit < ALayer.FlareShare;
  if Result.IsFlare then
    Result.Size := FlareSize.At(ARandom.NextUnit);
  Result.Twinkle := RollTwinkle(ARandom);
end;

procedure AdvanceStar(var AStar: TStar; AFrameWidth: Single);
begin
  AStar.X := AStar.X + AStar.Speed;
  // Leaves fully past the right edge, re-enters fully hidden on the
  // left - no star pops in or out in view
  if AStar.X - AStar.Size / 2 > AFrameWidth then
    AStar.X := AStar.X - AFrameWidth - AStar.Size;

  AStar.Twinkle.Phase := AStar.Twinkle.Phase + AStar.Twinkle.Step;
  if AStar.Twinkle.Phase > 2 * Pi then
    AStar.Twinkle.Phase := AStar.Twinkle.Phase - 2 * Pi;
end;

// ---------------------------------------------------------------------------
// TStarfield
// ---------------------------------------------------------------------------

constructor TStarfield.Create(ARenderer: PSdlRenderer;
  AWidth, AHeight: Single);
var
  StarRandom: TXorShift;
begin
  inherited Create;
  FRenderer := ARenderer;
  FWidth := AWidth;
  FPointTexture := CreateStarTexture(ARenderer, ssPoint);
  FFlareTexture := CreateStarTexture(ARenderer, ssFlare);

  StarRandom.Seed := StarfieldSeed;
  var Area := AWidth * AHeight / DensityArea;
  for var Layer in StarLayers do
    for var i := 1 to Round(Layer.Density * Area) do
      FStars := FStars + [RollStar(Layer, AWidth, AHeight, StarRandom)];
end;

destructor TStarfield.Destroy;
begin
  if Assigned(FFlareTexture) then
    SDL_DestroyTexture(FFlareTexture);
  if Assigned(FPointTexture) then
    SDL_DestroyTexture(FPointTexture);
  inherited;
end;

procedure TStarfield.Tick;
begin
  for var i := 0 to High(FStars) do
    AdvanceStar(FStars[i], FWidth);
end;

procedure TStarfield.Draw(AAlpha: Double);
begin
  for var Star in FStars do
    DrawStar(Star, AAlpha);
end;

// Interpolated with the timestep alpha: the far layer moves a fiftieth
// of a unit per tick and would shimmer otherwise
procedure TStarfield.DrawStar(const AStar: TStar; AAlpha: Double);
var
  Dest: TSdlFRect;
begin
  var Texture := FPointTexture;
  if AStar.IsFlare then
    Texture := FFlareTexture;

  var Phase := AStar.Twinkle.Phase + AStar.Twinkle.Step * AAlpha;
  var Dip := AStar.Twinkle.Depth * (0.5 + 0.5 * Sin(Phase));
  var Level := AStar.Brightness * (1 - Dip);
  SDL_SetTextureColorMod(Texture, AStar.Tint.R, AStar.Tint.G, AStar.Tint.B);
  SDL_SetTextureAlphaMod(Texture, Round(255 * Level));

  Dest.X := AStar.X + AStar.Speed * AAlpha - AStar.Size / 2;
  Dest.Y := AStar.Y - AStar.Size / 2;
  Dest.W := AStar.Size;
  Dest.H := AStar.Size;
  SDL_RenderCopyF(FRenderer, Texture, nil, @Dest);
end;

end.
