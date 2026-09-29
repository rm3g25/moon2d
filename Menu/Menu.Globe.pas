{
  Menu.Globe - the moon of the menu as a slowly spinning globe.

  A map of the lunar surface (equirectangular, in the ui set) is wrapped
  onto a sphere on the CPU: at startup every pixel of the disc gets its
  map row, its longitude, a detail level for the compressed limb and its
  sunlight, and from then on a frame is one walk over that table with
  the spin added to the longitude. The sun stands still in front of the
  viewer, a little up and to the left; the surface turns under it, so
  the terminator stays and the ground slides into the night. The night
  side keeps a trace of earthshine.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Menu.Globe;
{$I ..\Moon2D.inc}
// A 33 Hz walk over a quarter million texels lives here: optimized and
// unchecked whatever the build configuration says. The wraparound of
// Turn + Phase in Paint is the arithmetic, not an accident.
{$O+,R-,Q-}

interface

uses
  System.SysUtils, Sdl2.Core, Sprites.Sets;

type
  EGlobeError = class(Exception);

  // One texel of the globe texture that lies on the disc (or in the
  // one-texel apron around it that keeps the linear filter clean)
  TGlobePixel = record
    Turn: Cardinal; // longitude as a fraction of a turn: 2^32 = 360 degrees
    Row: Word; // map row, at Level
    Level: Byte; // map pyramid level: finer at the center, coarser at the limb
    Shade: Byte; // sunlight 0..255 before the tone curve
    Alpha: Byte; // disc coverage
  end;
  PGlobePixel = ^TGlobePixel;

  TMapLevel = record
    Width, Height: Integer;
    Shift: Byte; // 32 - log2(Width): a Turn shifted right lands on a column
    Texels: TArray<Cardinal>; // R,G,B,A bytes in memory (SdlPixelFormatAbgr8888)
  end;
  PMapLevel = ^TMapLevel;

  TRowSpan = record
    First, Last: Integer; // texture columns the table covers; Last < First = none
  end;

  TMoonGlobe = class
  private
    FRenderer: PSdlRenderer;
    FTexture: PSdlTexture; // streaming, repainted once per tick
    FLevels: TArray<TMapLevel>;
    FPixels: TArray<TGlobePixel>; // the disc, row by row, left to right
    FRows: TArray<TRowSpan>; // one per texture row
    FGain: array [Byte, 0..2] of Integer; // shade -> per-channel gain, x256
    FTone: array [0..1023] of Byte; // lit value x256 -> display value
    FPhase: Cardinal; // the spin, in Turn units
    FSpinStep: Cardinal;
    FDirty: Boolean;
    procedure LoadMap(const ASpriteSet: TSpriteSet; const AMapName: string);
    procedure BuildPyramid;
    procedure BuildTables;
    procedure BuildCurves;
    procedure Paint;
  public
    constructor Create(ARenderer: PSdlRenderer; const ASpriteSet: TSpriteSet;
      const AMapName: string);
    destructor Destroy; override;
    procedure Tick;
    // ADest is a square in game units; the disc fills it
    procedure Draw(const ADest: TSdlFRect);
  end;

implementation

uses
  System.Math, Render.Sprites;

resourcestring
  SGlobeMapFailed = 'Cannot load the moon map "%s": %s';
  SGlobeMapShape = 'The moon map "%s" must be a power-of-two width twice ' +
    'its height, not %dx%d';
  SGlobeTextureFailed = 'Cannot create the globe texture: %s';

const
  GlobeSide = 512; // texture side in texels; the disc fills it
  // Texels outside the disc that still carry a surface color under alpha
  // zero: the linear filter blends them into the edge and a black apron
  // would ring the moon
  ApronTexels = 2;
  LevelCount = 4;

  // One turn in this many logic ticks (80 s at the 2008 timer rate)
  SpinTicksPerTurn = 2640;

  // The axis: its top leans left across the screen and tips toward the
  // viewer, so a little of the north pole shows and the spin reads as
  // a globe and not as a scrolling picture
  AxisRollDegrees = 18.0;
  AxisTipDegrees = 12.0;

  // The sun in view space (x right, y up, z toward the viewer), before
  // normalization: mostly frontal, up and to the left, so the terminator
  // sits on the lower right and the disc reads as nearly full
  SunX = -0.50;
  SunY = 0.32;
  SunZ = 0.80;

  // Lunar regolith reflects almost equally to the limb (Lommel-Seeliger);
  // this power fades the outermost limb a touch so the ball reads round
  LimbFade = 0.12;
  // The night side under earthshine, per channel, slightly blue
  AmbientR = 0.035;
  AmbientG = 0.042;
  AmbientB = 0.056;
  Exposure = 1.7;
  // The cool tone of the 2008 moon, gently
  TintR = 0.93;
  TintG = 0.99;
  TintB = 1.08;
  // Soft shoulder for the brightest rays instead of a hard clip
  ToneKnee = 1.25;
  // Detail level = log2 of map texels per globe texel, biased toward the
  // finer level; the footprint grows radially at the limb (1 / nz)
  LevelBias = 0.3;

  BytesPerTexel = 4;
  TurnUnits = 4294967296.0; // 2^32

// ---------------------------------------------------------------------------
// Construction
// ---------------------------------------------------------------------------

constructor TMoonGlobe.Create(ARenderer: PSdlRenderer;
  const ASpriteSet: TSpriteSet; const AMapName: string);
begin
  inherited Create;
  FRenderer := ARenderer;
  LoadMap(ASpriteSet, AMapName);
  BuildPyramid;
  BuildTables;
  BuildCurves;

  FTexture := SDL_CreateTexture(ARenderer, SdlPixelFormatAbgr8888,
    SdlTextureAccessStreaming, GlobeSide, GlobeSide);
  if FTexture = nil then
    raise EGlobeError.CreateFmt(SGlobeTextureFailed, [SdlErrorText]);
  SDL_SetTextureBlendMode(FTexture, SdlBlendModeBlend);
  SDL_SetTextureScaleMode(FTexture, SdlScaleModeLinear);

  FSpinStep := Round(TurnUnits / SpinTicksPerTurn);
  FDirty := True;
end;

destructor TMoonGlobe.Destroy;
begin
  if Assigned(FTexture) then
    SDL_DestroyTexture(FTexture);
  inherited;
end;

procedure TMoonGlobe.LoadMap(const ASpriteSet: TSpriteSet;
  const AMapName: string);
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

    SetLength(FLevels, LevelCount);
    var Base := Default(TMapLevel);
    Base.Width := Surface.W;
    Base.Height := Surface.H;
    SetLength(Base.Texels, Base.Width * Base.Height);
    SDL_LockSurface(Surface);
    for var Row := 0 to Base.Height - 1 do
      Move((PByte(Surface.Pixels) + Row * Surface.Pitch)^,
        Base.Texels[Row * Base.Width], Base.Width * BytesPerTexel);
    SDL_UnlockSurface(Surface);
    FLevels[0] := Base;
  finally
    SDL_FreeSurface(Surface);
  end;
end;

// Each level is the previous one halved by averaging 2x2 texels: the
// limb samples from a coarser level instead of skipping map texels
procedure TMoonGlobe.BuildPyramid;
type
  PTexelBytes = ^TTexelBytes;
  TTexelBytes = array [0..3] of Byte;
begin
  for var Level := 1 to LevelCount - 1 do
  begin
    var Fine := FLevels[Level - 1];
    var Coarse := Default(TMapLevel);
    Coarse.Width := Fine.Width div 2;
    Coarse.Height := Fine.Height div 2;
    SetLength(Coarse.Texels, Coarse.Width * Coarse.Height);
    for var Row := 0 to Coarse.Height - 1 do
      for var Col := 0 to Coarse.Width - 1 do
      begin
        var TopLeft := PTexelBytes(@Fine.Texels[2 * Row * Fine.Width + 2 * Col]);
        var TopRight := PTexelBytes(PByte(TopLeft) + BytesPerTexel);
        var BottomLeft := PTexelBytes(PByte(TopLeft) + Fine.Width * BytesPerTexel);
        var BottomRight := PTexelBytes(PByte(BottomLeft) + BytesPerTexel);
        var Sum := PTexelBytes(@Coarse.Texels[Row * Coarse.Width + Col]);
        for var Channel := 0 to 3 do
          Sum[Channel] := (TopLeft[Channel] + TopRight[Channel] +
            BottomLeft[Channel] + BottomRight[Channel] + 2) div 4;
      end;
    FLevels[Level] := Coarse;
  end;

  for var Level := 0 to LevelCount - 1 do
    FLevels[Level].Shift := 32 - Round(Log2(FLevels[Level].Width));
end;

// The geometry of every texel, computed once. View space: x right, y up,
// z toward the viewer; the body frame is the view frame with the axis
// roll and tip undone, and the spin is a plain shift of longitude.
procedure TMoonGlobe.BuildTables;
var
  Sun: array [0..2] of Double;
begin
  var SunLength := Sqrt(SunX * SunX + SunY * SunY + SunZ * SunZ);
  Sun[0] := SunX / SunLength;
  Sun[1] := SunY / SunLength;
  Sun[2] := SunZ / SunLength;
  var CosRoll := Cos(DegToRad(AxisRollDegrees));
  var SinRoll := Sin(DegToRad(AxisRollDegrees));
  var CosTip := Cos(DegToRad(AxisTipDegrees));
  var SinTip := Sin(DegToRad(AxisTipDegrees));

  var Radius := GlobeSide / 2 - ApronTexels - 0.5;
  var Center := GlobeSide / 2;
  // Map texels per globe texel at the center of the disc
  var CenterFootprint := FLevels[0].Width / (Pi * 2 * Radius);

  SetLength(FRows, GlobeSide);
  SetLength(FPixels, GlobeSide * GlobeSide);
  var Count := 0;
  for var TexRow := 0 to GlobeSide - 1 do
  begin
    FRows[TexRow].First := 0;
    FRows[TexRow].Last := -1;
    for var TexCol := 0 to GlobeSide - 1 do
    begin
      var DX := TexCol + 0.5 - Center;
      var DY := TexRow + 0.5 - Center;
      var Distance := Sqrt(DX * DX + DY * DY);
      if Distance > Radius + ApronTexels then
        Continue;
      if FRows[TexRow].Last < FRows[TexRow].First then
        FRows[TexRow].First := TexCol;
      FRows[TexRow].Last := TexCol;

      // The unit normal; the apron is pinned to the rim
      var X := DX / Radius;
      var Y := -DY / Radius;
      var Reach := Sqrt(X * X + Y * Y);
      if Reach > 0.9995 then
      begin
        X := X * 0.9995 / Reach;
        Y := Y * 0.9995 / Reach;
      end;
      var Z := Sqrt(Max(1 - X * X - Y * Y, 0.0));

      // Body frame: undo the roll about z, then the tip about x
      var BodyX := CosRoll * X + SinRoll * Y;
      var RolledY := -SinRoll * X + CosRoll * Y;
      var BodyY := CosTip * RolledY + SinTip * Z;
      var BodyZ := -SinTip * RolledY + CosTip * Z;
      var Latitude := ArcSin(EnsureRange(BodyY, -1.0, 1.0));
      var Longitude := ArcTan2(BodyX, BodyZ); // 0 faces the viewer at rest
      var TurnFraction := Longitude / (2 * Pi) + 0.5;
      if TurnFraction >= 1 then
        TurnFraction := TurnFraction - 1;

      var Level: Integer := EnsureRange(Round(Log2(CenterFootprint) +
        0.5 * Log2(1 / Max(Z, 0.001)) - LevelBias), 0, LevelCount - 1);
      var Height := FLevels[Level].Height;

      // Lommel-Seeliger: bright to the limb, dark only at the terminator
      var CosSun := Max(X * Sun[0] + Y * Sun[1] + Z * Sun[2], 0.0);
      var Shade := 0.0;
      if CosSun > 0 then
        Shade := CosSun / (CosSun + Z) * (1 + Z) * Power(Max(Z, 0.001), LimbFade);

      var Pixel: TGlobePixel;
      Pixel.Turn := Trunc(TurnFraction * TurnUnits);
      Pixel.Row := EnsureRange(Trunc((0.5 - Latitude / Pi) * Height), 0,
        Height - 1);
      Pixel.Level := Level;
      Pixel.Shade := Round(255 * Min(Shade, 1.0));
      Pixel.Alpha := Round(255 * EnsureRange(Radius + 0.5 - Distance, 0.0, 1.0));
      FPixels[Count] := Pixel;
      Inc(Count);
    end;
  end;
  SetLength(FPixels, Count);
end;

// Shade -> gain per channel (earthshine floor, exposure, tint), and the
// tone curve that rolls the brightest rays off instead of clipping them
procedure TMoonGlobe.BuildCurves;
const
  Ambient: array [0..2] of Double = (AmbientR, AmbientG, AmbientB);
  Tint: array [0..2] of Double = (TintR, TintG, TintB);
begin
  for var Shade := 0 to 255 do
    for var Channel := 0 to 2 do
    begin
      var Sunlit := Ambient[Channel] + Shade / 255 * (1 - Ambient[Channel]);
      FGain[Shade, Channel] := Round(256 * Sunlit * Exposure * Tint[Channel]);
    end;
  for var Lit := 0 to High(FTone) do
    FTone[Lit] := Round(255 * (1 - Exp(-ToneKnee * Lit / 256)));
end;

// ---------------------------------------------------------------------------
// Frames
// ---------------------------------------------------------------------------

procedure TMoonGlobe.Tick;
begin
  // Longitude runs the other way from the spin so that the surface
  // travels left to right across the face, as a prograde globe does
  FPhase := FPhase - FSpinStep;
  FDirty := True;
end;

procedure TMoonGlobe.Paint;
type
  PTexelBytes = ^TTexelBytes;
  TTexelBytes = array [0..3] of Byte;
var
  Pixels: Pointer;
  Pitch: Integer;
begin
  if SDL_LockTexture(FTexture, nil, Pixels, Pitch) <> 0 then
    Exit;
  var Next := 0;
  for var TexRow := 0 to GlobeSide - 1 do
  begin
    var Line := PByte(Pixels) + TexRow * Pitch;
    FillChar(Line^, GlobeSide * BytesPerTexel, 0);
    var Span := FRows[TexRow];
    var Dest := PTexelBytes(Line + Span.First * BytesPerTexel);
    for var TexCol := Span.First to Span.Last do
    begin
      var Pixel: PGlobePixel := @FPixels[Next];
      var Level: PMapLevel := @FLevels[Pixel.Level];
      var Turn: Cardinal := Pixel.Turn + FPhase;
      var Col0: Cardinal := Turn shr Level.Shift;
      var Col1: Cardinal := (Col0 + 1) and Cardinal(Level.Width - 1);
      var Blend: Integer := (Turn shr (Level.Shift - 8)) and $FF; // 0..255 toward Col1
      var RowStart: Cardinal := Cardinal(Pixel.Row) * Cardinal(Level.Width);
      var Left := PTexelBytes(@Level.Texels[RowStart + Col0]);
      var Right := PTexelBytes(@Level.Texels[RowStart + Col1]);
      for var Channel := 0 to 2 do
      begin
        var Mixed := (Left[Channel] * (256 - Blend) + Right[Channel] * Blend) shr 8;
        var Lit := (Mixed * FGain[Pixel.Shade, Channel]) shr 8;
        if Lit > High(FTone) then
          Lit := High(FTone);
        Dest[Channel] := FTone[Lit];
      end;
      Dest[3] := Pixel.Alpha;
      Inc(Dest);
      Inc(Next);
    end;
  end;
  SDL_UnlockTexture(FTexture);
  FDirty := False;
end;

procedure TMoonGlobe.Draw(const ADest: TSdlFRect);
begin
  if FDirty then
    Paint;
  SDL_RenderCopyF(FRenderer, FTexture, nil, @ADest);
end;

end.
