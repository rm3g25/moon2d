{
  Monsters.Hull - a monster drawn as a hull out of two layers: the TeK
  platform. A whole hull, and a worn copy of it over it that shows through
  as the lives run out. The red eye in the sensor housing glows and swells
  before every shot.

  The hull stands in the middle of the monster's cell, on whole units like
  a frame, and is never mirrored: the art is symmetric, and the torn panel
  of the worn layer would jump from side to side at every turn. Only the
  eye draws between ticks.

  Not here: the death - a dying hull monster plays the death frames of
  its own set, as every monster does.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Monsters.Hull;
{$I ..\Moon2D.inc}

interface

uses
  Sdl2.Core, Render.Sprites, Sprites.Sets, Monsters.Defs;

type
  // The layers of one hull set, through a cache of its own: painted with
  // soft edges, so no color key; drawn at a size of their own, so linear
  // filtering
  THullArt = class
  private
    FRenderer: PSdlRenderer;
    FSpriteSet: TSpriteSet;
    FCache: TSpriteCache;
    FWhole: PSdlTexture;
    FWorn: PSdlTexture;
    FEyeGlow: PSdlTexture;
  public
    // ASetName - the set's file in the sprites folder, no extension
    constructor Create(ARenderer: PSdlRenderer; const ASetName: string);
    destructor Destroy; override;
  end;

  THull = class
  private
    FDef: THullDef;
    FArt: THullArt;
    FWear: Single;
    FEye: Single; // 0..1, how lit
    FLastEye: Single;
  public
    // AArt belongs to the caller and must outlive the hull
    constructor Create(const ADef: THullDef; AArt: THullArt);
    // AWear, ACharge: 0..1 - how battered, how close the next shot is
    procedure Tick(AWear, ACharge: Single);
    // ACenter - the middle of the hull, screen units. AAlpha - how far
    // toward the next tick, which the eye is drawn between.
    procedure Draw(const ASprites: TSpriteRenderer;
      const ACenter: TSdlFPoint; AAlpha: Single);
    // Where a point of the art falls on the screen, the hull standing at
    // ACenter
    function Spot(const ACenter: TSdlFPoint;
      const AHullPoint: THullPoint): TSdlFPoint;
  end;

implementation

uses
  Render.Brush, Render.Glow;

const
  // The eye dims by this share a tick after a shot
  EyeFade = 0.85;
  EyeRestLevel = 0.3;
  EyeRestSize = 4.0;
  EyeChargedSize = 9.0;
  EyeColor: TRgb = (R: 255; G: 36; B: 20);
  EyeGlowSide = 64;

function Lerp(AFrom, ATo, AAmount: Single): Single;
begin
  Result := AFrom + (ATo - AFrom) * AAmount;
end;

// ---------------------------------------------------------------------------
// THullArt
// ---------------------------------------------------------------------------

constructor THullArt.Create(ARenderer: PSdlRenderer; const ASetName: string);
begin
  inherited Create;
  FRenderer := ARenderer;
  FSpriteSet := TSpriteSet.Create(SpriteSetsDir + ASetName + '.mset');
  FCache := TSpriteCache.Create(ARenderer);
  FCache.DisableColorKey;
  FCache.EnableLinearFilter;
  FCache.AttachSpriteSet(FSpriteSet);

  FWhole := FCache.Get('hull');
  FWorn := FCache.Get('hullDamaged');
  FEyeGlow := CreateGlowShape(ARenderer, gsPoint, EyeGlowSide);
end;

// The cache before the set: it reads from the set, never the reverse
destructor THullArt.Destroy;
begin
  if Assigned(FEyeGlow) then
    SDL_DestroyTexture(FEyeGlow);
  FCache.Free;
  FSpriteSet.Free;
  inherited;
end;

// ---------------------------------------------------------------------------
// THull
// ---------------------------------------------------------------------------

constructor THull.Create(const ADef: THullDef; AArt: THullArt);
begin
  inherited Create;
  FDef := ADef;
  FArt := AArt;
end;

procedure THull.Tick(AWear, ACharge: Single);
begin
  FWear := AWear;

  FLastEye := FEye;
  FEye := ACharge;
  if FLastEye * EyeFade > FEye then
    FEye := FLastEye * EyeFade;
end;

function THull.Spot(const ACenter: TSdlFPoint;
  const AHullPoint: THullPoint): TSdlFPoint;
begin
  Result.X := ACenter.X - FDef.Width / 2 + AHullPoint.X;
  Result.Y := ACenter.Y - FDef.Height / 2 + AHullPoint.Y;
end;

procedure THull.Draw(const ASprites: TSpriteRenderer;
  const ACenter: TSdlFPoint; AAlpha: Single);
begin
  var Width: Single := FDef.Width;
  var Height: Single := FDef.Height;
  ASprites.DrawSized(FArt.FWhole, ACenter, Width, Height);
  if FWear > 0 then
    ASprites.DrawSized(FArt.FWorn, ACenter, Width, Height, FWear);

  var Eye := Spot(ACenter, FDef.Eye);
  var EyeLevel := Lerp(FLastEye, FEye, AAlpha);
  DrawGlow(FArt.FRenderer, FArt.FEyeGlow, Eye.X + ASprites.Origin.X,
    Eye.Y + ASprites.Origin.Y + ASprites.FineY,
    Lerp(EyeRestSize, EyeChargedSize, EyeLevel), EyeColor,
    Lerp(EyeRestLevel, 1, EyeLevel));
end;

end.
