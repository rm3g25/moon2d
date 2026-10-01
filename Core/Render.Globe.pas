{
  Render.Globe - a body of the sky as a lit sphere: an equirectangular
  map wrapped onto a disc on the CPU, under a sun that may stand
  anywhere and move.

  At creation every texel of the disc gets its map row, its longitude,
  a detail level for the compressed limb and its normal. Lighting the
  globe turns the normals into sunlight once; a frame is one walk over
  that table with the spin added to the longitude, and only a globe
  that turned or was lit again is walked.

  The ground answers the sun one of two ways: regolith (Lommel-Seeliger)
  stays bright to the limb and darkens only at the terminator - the
  Moon; matte (Lambert) dims toward the terminator - the Earth. A night
  map, if given, shows where the sun has gone - city lights. An
  atmosphere thickens to a haze at the limb and spills past it in a
  thin halo, on the sunlit side and a little beyond the terminator,
  where the air still catches the light.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Render.Globe;
{$I ..\Moon2D.inc}
// A 33 Hz walk over a quarter million texels lives here: optimized and
// unchecked whatever the build configuration says. The wraparound of
// Turn + Phase in PaintGround is the arithmetic, not an accident.
{$O+,R-,Q-}

interface

uses
  System.SysUtils, Sdl2.Core, Sprites.Sets, Render.Brush;

type
  EGlobeError = class(Exception);

  TGlobeSurface = (gsRegolith, gsMatte);

  // Red, green, blue
  TGlobeChannels = array [0..2] of Double;

  TGlobeLook = record
    Side: Integer; // texture side in texels; the disc and its halo fill it
    Surface: TGlobeSurface;
    // The axis: its top leans AxisRoll degrees left across the screen
    // and tips AxisTip degrees toward the viewer
    AxisRoll, AxisTip: Double;
    Ambient: TGlobeChannels; // the night side, before the exposure
    Tint: TGlobeChannels;
    Exposure: Double;
    LimbFade: Double; // regolith: a power that fades the outermost limb
    Atmosphere: Double; // 0..1; 0 = airless, no haze and no halo
    AirColor: TGlobeChannels;
    NightGain: Double; // the night map's brightness; unused without one
  end;

  // One texel of the globe texture that lies on the disc, in its halo,
  // or in the one-texel apron that keeps the linear filter clean
  TGlobePixel = record
    Turn: Cardinal; // longitude as a fraction of a turn: 2^32 = 360 degrees
    Row: Word; // map row, at Level
    Level: Byte; // map pyramid level: finer at the center, coarser at the limb
    Shade: Byte; // sunlight 0..255 before the tone curve
    Alpha: Byte; // disc coverage, or the halo's density
    Night: Byte; // how far the night map shows, 0..255
    Clear: Word; // how much ground shows through the air, 256 = all
    Haze: array [0..2] of Word; // light of the air, in lit units
  end;
  PGlobePixel = ^TGlobePixel;

  // Where the ground of a texel faces, kept for lighting it again
  TGlobeNormal = record
    X, Y, Z: Single; // view space: x right, y up, z toward the viewer
    LimbWeight: Single; // the regolith limb fade at this texel
    AirDepth: Single; // 0..1: the limb haze on the disc, the halo past it
  end;

  TMapLevel = record
    Width, Height: Integer;
    Shift: Byte; // 32 - log2(Width): a Turn shifted right lands on a column
    Texels: TArray<Cardinal>; // R,G,B,A bytes in memory (SdlPixelFormatAbgr8888)
  end;
  PMapLevel = ^TMapLevel;

  TRowSpan = record
    First, Last: Integer; // texture columns the table covers; Last < First = none
  end;

  // One texel of a map or of the globe texture: R, G, B, A
  TGlobeTexel = array [0..3] of Byte;
  PGlobeTexel = ^TGlobeTexel;

  TGlobe = class
  private type
    // What every texel of the table is built against
    TTableFrame = record
      CosRoll, SinRoll, CosTip, SinTip: Double;
      Radius: Double; // of the disc, in texels
      HaloShare: Double; // the halo's width in disc radii; 0 without air
      CenterFootprint: Double; // map texels per globe texel at the center
    end;

    // A unit vector toward the sun, view space
    TSunVector = record
      X, Y, Z: Double;
    end;
  private
    FRenderer: PSdlRenderer;
    FTexture: PSdlTexture; // streaming, repainted after a change
    FLook: TGlobeLook;
    FLevels: TArray<TMapLevel>;
    FNightLevels: TArray<TMapLevel>; // empty without a night map
    FPixels: TArray<TGlobePixel>; // the disc, row by row, left to right
    FNormals: TArray<TGlobeNormal>; // in step with FPixels
    FRows: TArray<TRowSpan>; // one per texture row
    FRadius: Double; // of the disc, in texels
    FGain: array [Byte, 0..2] of Integer; // shade -> per-channel gain, x256
    FTone: array [0..1023] of Byte; // lit value x256 -> display value
    FNightGain: Integer; // x256
    FPhase: Cardinal; // the spin, in Turn units
    FDirty: Boolean;
    procedure BuildTables;
    // Fills entry AIndex of the table
    procedure PlaceTexel(const AFrame: TTableFrame; ADX, ADY: Double;
      AIndex: Integer);
    function AirDepthAt(const AFrame: TTableFrame; ADistance, AZ: Double;
      AOnGround: Boolean): Double;
    procedure BuildCurves;
    procedure LightTexel(var APixel: TGlobePixel; const ANormal: TGlobeNormal;
      const ASun: TSunVector);
    procedure PaintGround(var ADest: TGlobeTexel; const APixel: TGlobePixel);
      inline;
    procedure PaintAir(var ADest: TGlobeTexel; const APixel: TGlobePixel);
      inline;
    function PaintRow(ALine: PByte; const ASpan: TRowSpan;
      AFirst: Integer): Integer;
    procedure Paint;
  public
    // ANightMapName '' = no night map; a night map matches the day
    // map's size. The globe is dark until lit.
    constructor Create(ARenderer: PSdlRenderer; const ASpriteSet: TSpriteSet;
      const AMapName, ANightMapName: string; const ALook: TGlobeLook);
    destructor Destroy; override;
    // The sun in view space (x right, y up, z toward the viewer), any length
    procedure LightFrom(AX, AY, AZ: Double);
    // Turns the ground under the sun; 2^32 units make a turn
    procedure Spin(ATurnUnits: Integer);
    // Brings ALongitude (degrees east) to the middle of the disc
    procedure Face(ALongitude: Double);
    // The square that puts the disc, ADiameter across, around the point
    function DestFor(ACenterX, ACenterY, ADiameter: Single): TSdlFRect;
    // ADest is a square in game units; the disc and its halo fill it
    procedure Draw(const ADest: TSdlFRect; ATint: TRgb; ALevel: Single);
  end;

implementation

uses
  System.Math, Render.Sprites;

resourcestring
  SGlobeMapFailed = 'Cannot load the globe map "%s": %s';
  SGlobeMapShape = 'The globe map "%s" must be a power-of-two width twice ' +
    'its height, not %dx%d';
  SGlobeNightShape = 'The night map "%s" must match the day map, %dx%d';
  SGlobeTextureFailed = 'Cannot create the globe texture: %s';

const
  // Texels outside the disc that still carry a surface color under alpha
  // zero: the linear filter blends them into the edge and a black apron
  // would ring the globe
  ApronTexels = 2;
  LevelCount = 4;
  // The pyramid level of a texel past the ground: air alone, no map
  AirOnly = High(Byte);

  // Soft shoulder for the brightest rays instead of a hard clip
  ToneKnee = 1.25;
  ToneTop = 1023;
  // One unit of light in the lit scale the tone curve reads
  LitUnit = 256;
  // Detail level = log2 of map texels per globe texel, biased toward the
  // finer level; the footprint grows radially at the limb (1 / nz)
  LevelBias = 0.3;

  // The night map shows once the sun is a little below the horizon and
  // fully a few degrees further on - cities switch on in the dusk
  NightOnset = -0.02;
  NightSpan = 0.12;

  // Air. The halo reaches this share of the radius past the limb.
  AirHaloShare = 0.07;
  HaloFalloff = 3.2;
  HaloDensity = 0.9;
  HaloBrightness = 1.2;
  // The air keeps catching the sun past the terminator: lit sunward of
  // a plane this far behind the edge of the day
  AirWrap = 0.2;
  // Haze across the whole day side, the rest of it gathered at the limb
  AirVeil = 0.1;
  // Typed: Power has three overloads
  AirRimPower: Double = 2.2;
  AirLevel = 0.75;
  // The thick air at the limb hides a share of the ground
  AirDimming = 0.25;

  // Keeps the limb's footprint finite where the disc turns edge-on
  MinFacing = 0.001;

  BytesPerTexel = 4;
  TurnUnits = 4294967296.0; // 2^32

// Max, Min and EnsureRange have an overload per float type, and an
// untyped literal next to a Double can match two of them
function Confine(AValue, ALow, AHigh: Double): Double;
begin
  if AValue < ALow then
    Exit(ALow);
  if AValue > AHigh then
    Exit(AHigh);
  Result := AValue;
end;

// ---------------------------------------------------------------------------
// Maps
// ---------------------------------------------------------------------------

function LoadMap(const ASpriteSet: TSpriteSet;
  const AMapName: string): TMapLevel;
var
  Loaded, Surface: PSdlSurface;
begin
  Loaded := LoadImageSurface(ASpriteSet, AMapName);
  if Loaded = nil then
    raise EGlobeError.CreateFmt(SGlobeMapFailed, [AMapName, SdlErrorText]);
  Surface := SDL_ConvertSurfaceFormat(Loaded, SdlPixelFormatAbgr8888, 0);
  SDL_FreeSurface(Loaded);
  if Surface = nil then
    raise EGlobeError.CreateFmt(SGlobeMapFailed, [AMapName, SdlErrorText]);
  try
    var IsPowerOfTwo := (Surface.W and (Surface.W - 1)) = 0;
    if (not IsPowerOfTwo) or (Surface.W <> 2 * Surface.H) then
      raise EGlobeError.CreateFmt(SGlobeMapShape,
        [AMapName, Surface.W, Surface.H]);

    Result := Default(TMapLevel);
    Result.Width := Surface.W;
    Result.Height := Surface.H;
    SetLength(Result.Texels, Result.Width * Result.Height);
    SDL_LockSurface(Surface);
    for var Row := 0 to Result.Height - 1 do
      Move((PByte(Surface.Pixels) + Row * Surface.Pitch)^,
        Result.Texels[Row * Result.Width], Result.Width * BytesPerTexel);
    SDL_UnlockSurface(Surface);
  finally
    SDL_FreeSurface(Surface);
  end;
end;

// The level halved by averaging 2x2 texels
function HalveLevel(const AFine: TMapLevel): TMapLevel;
begin
  Result := Default(TMapLevel);
  Result.Width := AFine.Width div 2;
  Result.Height := AFine.Height div 2;
  SetLength(Result.Texels, Result.Width * Result.Height);
  for var Row := 0 to Result.Height - 1 do
    for var Col := 0 to Result.Width - 1 do
    begin
      var TopLeft := PGlobeTexel(@AFine.Texels[2 * Row * AFine.Width + 2 * Col]);
      var TopRight := PGlobeTexel(PByte(TopLeft) + BytesPerTexel);
      var BottomLeft := PGlobeTexel(PByte(TopLeft) + AFine.Width * BytesPerTexel);
      var BottomRight := PGlobeTexel(PByte(BottomLeft) + BytesPerTexel);
      var Sum := PGlobeTexel(@Result.Texels[Row * Result.Width + Col]);
      for var Channel := 0 to 3 do
        Sum[Channel] := (TopLeft[Channel] + TopRight[Channel] +
          BottomLeft[Channel] + BottomRight[Channel] + 2) div 4;
    end;
end;

// Each level is the previous one halved: the limb samples from a
// coarser level instead of skipping map texels
function BuildPyramid(const ABase: TMapLevel): TArray<TMapLevel>;
begin
  SetLength(Result, LevelCount);
  Result[0] := ABase;
  for var Level := 1 to LevelCount - 1 do
    Result[Level] := HalveLevel(Result[Level - 1]);

  for var Level := 0 to LevelCount - 1 do
    Result[Level].Shift := 32 - Round(Log2(Result[Level].Width));
end;

// A value in units of light, clamped to what the tone curve reads
function ToLit(AValue: Double): Word;
begin
  Result := EnsureRange(Round(AValue * LitUnit), 0, ToneTop);
end;

// ---------------------------------------------------------------------------
// Construction
// ---------------------------------------------------------------------------

constructor TGlobe.Create(ARenderer: PSdlRenderer;
  const ASpriteSet: TSpriteSet; const AMapName, ANightMapName: string;
  const ALook: TGlobeLook);
begin
  inherited Create;
  FRenderer := ARenderer;
  FLook := ALook;
  var Day := LoadMap(ASpriteSet, AMapName);
  FLevels := BuildPyramid(Day);
  if ANightMapName <> '' then
  begin
    var Night := LoadMap(ASpriteSet, ANightMapName);
    if (Night.Width <> Day.Width) or (Night.Height <> Day.Height) then
      raise EGlobeError.CreateFmt(SGlobeNightShape,
        [ANightMapName, Day.Width, Day.Height]);
    FNightLevels := BuildPyramid(Night);
  end;
  BuildTables;
  BuildCurves;

  FTexture := SDL_CreateTexture(ARenderer, SdlPixelFormatAbgr8888,
    SdlTextureAccessStreaming, FLook.Side, FLook.Side);
  if FTexture = nil then
    raise EGlobeError.CreateFmt(SGlobeTextureFailed, [SdlErrorText]);
  SDL_SetTextureBlendMode(FTexture, SdlBlendModeBlend);
  SDL_SetTextureScaleMode(FTexture, SdlScaleModeLinear);
  FDirty := True;
end;

destructor TGlobe.Destroy;
begin
  if Assigned(FTexture) then
    SDL_DestroyTexture(FTexture);
  inherited;
end;

// The geometry of every texel, computed once. View space: x right, y up,
// z toward the viewer; the body frame is the view frame with the axis
// roll and tip undone, and the spin is a plain shift of longitude.
procedure TGlobe.BuildTables;
var
  Frame: TTableFrame;
begin
  Frame.CosRoll := Cos(DegToRad(FLook.AxisRoll));
  Frame.SinRoll := Sin(DegToRad(FLook.AxisRoll));
  Frame.CosTip := Cos(DegToRad(FLook.AxisTip));
  Frame.SinTip := Sin(DegToRad(FLook.AxisTip));
  Frame.HaloShare := 0;
  if FLook.Atmosphere > 0 then
    Frame.HaloShare := AirHaloShare;
  // The disc, or the halo around it, stops short of the apron
  var Outer: Double := FLook.Side / 2 - ApronTexels - 0.5;
  Frame.Radius := Outer / (1 + Frame.HaloShare);
  Frame.CenterFootprint := FLevels[0].Width / (Pi * 2 * Frame.Radius);
  FRadius := Frame.Radius;

  var Center: Double := FLook.Side / 2;
  SetLength(FRows, FLook.Side);
  SetLength(FPixels, FLook.Side * FLook.Side);
  SetLength(FNormals, FLook.Side * FLook.Side);
  var Count := 0;
  for var TexRow := 0 to FLook.Side - 1 do
  begin
    FRows[TexRow].First := 0;
    FRows[TexRow].Last := -1;
    for var TexCol := 0 to FLook.Side - 1 do
    begin
      var DX: Double := TexCol + 0.5 - Center;
      var DY: Double := TexRow + 0.5 - Center;
      if Sqrt(DX * DX + DY * DY) > Outer + ApronTexels then
        Continue;
      if FRows[TexRow].Last < FRows[TexRow].First then
        FRows[TexRow].First := TexCol;
      FRows[TexRow].Last := TexCol;
      PlaceTexel(Frame, DX, DY, Count);
      Inc(Count);
    end;
  end;
  SetLength(FPixels, Count);
  SetLength(FNormals, Count);
end;

// ADX/ADY - the texel center from the texture center, in texels
procedure TGlobe.PlaceTexel(const AFrame: TTableFrame; ADX, ADY: Double;
  AIndex: Integer);
var
  Pixel: TGlobePixel;
  Normal: TGlobeNormal;
begin
  Pixel := Default(TGlobePixel);
  Normal := Default(TGlobeNormal);
  var Distance: Double := Sqrt(ADX * ADX + ADY * ADY);

  // The unit normal; the apron and the halo are pinned to the rim
  var X: Double := ADX / AFrame.Radius;
  var Y: Double := -ADY / AFrame.Radius;
  var Reach: Double := Sqrt(X * X + Y * Y);
  if Reach > 0.9995 then
  begin
    X := X * 0.9995 / Reach;
    Y := Y * 0.9995 / Reach;
  end;
  var Z: Double := Sqrt(Confine(1 - X * X - Y * Y, 0, 1));
  var Facing: Double := Confine(Z, MinFacing, 1);

  // Body frame: undo the roll about z, then the tip about x
  var BodyX: Double := AFrame.CosRoll * X + AFrame.SinRoll * Y;
  var RolledY: Double := -AFrame.SinRoll * X + AFrame.CosRoll * Y;
  var BodyY: Double := AFrame.CosTip * RolledY + AFrame.SinTip * Z;
  var BodyZ: Double := -AFrame.SinTip * RolledY + AFrame.CosTip * Z;
  var Latitude: Double := ArcSin(Confine(BodyY, -1, 1));
  var Longitude: Double := ArcTan2(BodyX, BodyZ); // 0 faces the viewer at rest
  var TurnFraction: Double := Longitude / (2 * Pi) + 0.5;
  if TurnFraction >= 1 then
    TurnFraction := TurnFraction - 1;

  var Footprint: Double := 1 / Facing;
  var Level: Integer := EnsureRange(Round(Log2(AFrame.CenterFootprint) +
    0.5 * Log2(Footprint) - LevelBias), 0, LevelCount - 1);
  var Height := FLevels[Level].Height;

  Pixel.Turn := Trunc(TurnFraction * TurnUnits);
  Pixel.Row := EnsureRange(Trunc((0.5 - Latitude / Pi) * Height), 0,
    Height - 1);
  Pixel.Level := Level;
  Pixel.Alpha := Round(255 * Confine(AFrame.Radius + 0.5 - Distance, 0, 1));
  Pixel.Clear := LitUnit;

  Normal.X := X;
  Normal.Y := Y;
  Normal.Z := Z;
  Normal.LimbWeight := Power(Facing, FLook.LimbFade);
  if AFrame.HaloShare > 0 then
  begin
    var OnGround := Distance <= AFrame.Radius + 0.5;
    if not OnGround then
      Pixel.Level := AirOnly;
    Normal.AirDepth := AirDepthAt(AFrame, Distance, Z, OnGround);
  end;

  FPixels[AIndex] := Pixel;
  FNormals[AIndex] := Normal;
end;

// On the ground: the depth of the limb haze. Past it: the halo, fading
// outward.
function TGlobe.AirDepthAt(const AFrame: TTableFrame; ADistance, AZ: Double;
  AOnGround: Boolean): Double;
begin
  if AOnGround then
  begin
    var Slant: Double := 1 - AZ;
    Exit(Power(Slant, AirRimPower));
  end;
  var Beyond: Double := (ADistance - AFrame.Radius) /
    (AFrame.HaloShare * AFrame.Radius);
  Result := Exp(-HaloFalloff * Beyond) * Confine(1 - Beyond, 0, 1);
end;

// Shade -> gain per channel (night floor, exposure, tint), and the tone
// curve that rolls the brightest rays off instead of clipping them
procedure TGlobe.BuildCurves;
begin
  for var Shade := 0 to 255 do
    for var Channel := 0 to 2 do
    begin
      var Ambient: Double := FLook.Ambient[Channel];
      var Sunlit: Double := Ambient + Shade / 255 * (1 - Ambient);
      FGain[Shade, Channel] := Round(256 * Sunlit * FLook.Exposure *
        FLook.Tint[Channel]);
    end;
  for var Lit := 0 to ToneTop do
    FTone[Lit] := Round(255 * (1 - Exp(-ToneKnee * Lit / 256)));
  FNightGain := Round(LitUnit * FLook.NightGain);
end;

// ---------------------------------------------------------------------------
// Light
// ---------------------------------------------------------------------------

procedure TGlobe.LightFrom(AX, AY, AZ: Double);
var
  Sun: TSunVector;
begin
  var SunLength: Double := Sqrt(AX * AX + AY * AY + AZ * AZ);
  if SunLength = 0 then
    Exit;
  Sun.X := AX / SunLength;
  Sun.Y := AY / SunLength;
  Sun.Z := AZ / SunLength;
  for var i := 0 to High(FPixels) do
    LightTexel(FPixels[i], FNormals[i], Sun);
  FDirty := True;
end;

procedure TGlobe.LightTexel(var APixel: TGlobePixel;
  const ANormal: TGlobeNormal; const ASun: TSunVector);
begin
  var CosSun: Double := ANormal.X * ASun.X + ANormal.Y * ASun.Y +
    ANormal.Z * ASun.Z;
  var Shade: Double := 0;
  if CosSun > 0 then
    case FLook.Surface of
      gsRegolith:
        Shade := CosSun / (CosSun + ANormal.Z) * (1 + ANormal.Z) *
          ANormal.LimbWeight;
      gsMatte:
        Shade := CosSun;
    end;
  APixel.Shade := Round(255 * Confine(Shade, 0, 1));
  if Length(FNightLevels) > 0 then
    APixel.Night := Round(255 * Confine((NightOnset - CosSun) / NightSpan,
      0, 1));
  if FLook.Atmosphere <= 0 then
    Exit;

  var Twilight: Double := Confine((CosSun + AirWrap) / (1 + AirWrap), 0, 1);
  var Air: Double := FLook.Atmosphere * Twilight;
  if APixel.Level = AirOnly then
  begin
    APixel.Alpha := Round(255 * Confine(Air * ANormal.AirDepth * HaloDensity,
      0, 1));
    for var Channel := 0 to 2 do
      APixel.Haze[Channel] := ToLit(HaloBrightness * FLook.AirColor[Channel]);
    Exit;
  end;

  APixel.Clear := ToLit(1 - AirDimming * FLook.Atmosphere * ANormal.AirDepth);
  var Glow: Double := Air * (AirVeil + (1 - AirVeil) * ANormal.AirDepth) * AirLevel;
  for var Channel := 0 to 2 do
    APixel.Haze[Channel] := ToLit(Glow * FLook.AirColor[Channel]);
end;

// ---------------------------------------------------------------------------
// Frames
// ---------------------------------------------------------------------------

procedure TGlobe.Spin(ATurnUnits: Integer);
begin
  FPhase := FPhase + Cardinal(ATurnUnits);
  FDirty := True;
end;

procedure TGlobe.Face(ALongitude: Double);
begin
  var Turns: Double := ALongitude / 360;
  FPhase := Cardinal(Round((Turns - Floor(Turns)) * TurnUnits) and $FFFFFFFF);
  FDirty := True;
end;

function TGlobe.DestFor(ACenterX, ACenterY, ADiameter: Single): TSdlFRect;
begin
  var Side: Single := ADiameter * FLook.Side / (2 * FRadius);
  Result.X := ACenterX - Side / 2;
  Result.Y := ACenterY - Side / 2;
  Result.W := Side;
  Result.H := Side;
end;

procedure TGlobe.PaintGround(var ADest: TGlobeTexel;
  const APixel: TGlobePixel);
begin
  var Level: PMapLevel := @FLevels[APixel.Level];
  var Turn: Cardinal := APixel.Turn + FPhase;
  var Col0: Cardinal := Turn shr Level.Shift;
  var Col1: Cardinal := (Col0 + 1) and Cardinal(Level.Width - 1);
  var Blend: Integer := (Turn shr (Level.Shift - 8)) and $FF; // 0..255 toward Col1
  var RowStart: Cardinal := Cardinal(APixel.Row) * Cardinal(Level.Width);
  var Left := PGlobeTexel(@Level.Texels[RowStart + Col0]);
  var Right := PGlobeTexel(@Level.Texels[RowStart + Col1]);
  // The night map shares the day map's size: the same texels
  var NightLeft: PGlobeTexel := nil;
  var NightRight: PGlobeTexel := nil;
  if APixel.Night > 0 then
  begin
    NightLeft := PGlobeTexel(@FNightLevels[APixel.Level].Texels[RowStart + Col0]);
    NightRight := PGlobeTexel(@FNightLevels[APixel.Level].Texels[RowStart + Col1]);
  end;

  for var Channel := 0 to 2 do
  begin
    var Mixed := (Left[Channel] * (256 - Blend) + Right[Channel] * Blend) shr 8;
    var Lit := (Mixed * FGain[APixel.Shade, Channel]) shr 8;
    Lit := (Lit * APixel.Clear) shr 8 + APixel.Haze[Channel];
    if NightLeft <> nil then
    begin
      var NightMixed := (NightLeft[Channel] * (256 - Blend) +
        NightRight[Channel] * Blend) shr 8;
      Lit := Lit + (NightMixed * APixel.Night * FNightGain) shr 16;
    end;
    if Lit > ToneTop then
      Lit := ToneTop;
    ADest[Channel] := FTone[Lit];
  end;
end;

procedure TGlobe.PaintAir(var ADest: TGlobeTexel; const APixel: TGlobePixel);
begin
  for var Channel := 0 to 2 do
    ADest[Channel] := FTone[APixel.Haze[Channel]];
end;

// AFirst - the table entry of the row's first texel; the next row's
// first comes back
function TGlobe.PaintRow(ALine: PByte; const ASpan: TRowSpan;
  AFirst: Integer): Integer;
begin
  Result := AFirst;
  var Dest := PGlobeTexel(ALine + ASpan.First * BytesPerTexel);
  for var TexCol := ASpan.First to ASpan.Last do
  begin
    var Pixel: PGlobePixel := @FPixels[Result];
    if Pixel.Level = AirOnly then
      PaintAir(Dest^, Pixel^)
    else
      PaintGround(Dest^, Pixel^);
    Dest[3] := Pixel.Alpha;
    Inc(Dest);
    Inc(Result);
  end;
end;

procedure TGlobe.Paint;
var
  Pixels: Pointer;
  Pitch: Integer;
begin
  if SDL_LockTexture(FTexture, nil, Pixels, Pitch) <> 0 then
    Exit;
  var Next := 0;
  for var TexRow := 0 to FLook.Side - 1 do
  begin
    var Line := PByte(Pixels) + TexRow * Pitch;
    FillChar(Line^, FLook.Side * BytesPerTexel, 0);
    Next := PaintRow(Line, FRows[TexRow], Next);
  end;
  SDL_UnlockTexture(FTexture);
  FDirty := False;
end;

procedure TGlobe.Draw(const ADest: TSdlFRect; ATint: TRgb; ALevel: Single);
begin
  if FDirty then
    Paint;
  SDL_SetTextureColorMod(FTexture, ATint.R, ATint.G, ATint.B);
  SDL_SetTextureAlphaMod(FTexture, Round(255 * Confine(ALevel, 0, 1)));
  SDL_RenderCopyF(FRenderer, FTexture, nil, @ADest);
end;

end.
