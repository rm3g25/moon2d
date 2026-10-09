{
  Monsters.Hull - a monster drawn as a hull out of layers: the TeK
  platform, the TeK tank, the TeK mount. A whole hull, and a worn copy of
  it over it that shows through as the lives run out. The red eye in the
  sensor housing glows and swells before every shot.

  A hull that drives stands on wheels: one picture at every axle, turned
  by the way the body has rolled, in front of the dark of the wheel wells
  and behind the hull, whose fenders shade it.

  The hull stands on whole units like a frame; only the eye and the wheels
  draw between ticks. The platform and the mount are never mirrored: their
  art is symmetric, and the torn panel of the worn layer would jump from
  side to side at every turn. The tank faces left and is mirrored whole
  while it heads right.

  Not here: where the hull stands - the monster says; the death - a dying
  hull monster plays the death frames of its own set, as every monster
  does.

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
    FChassis: PSdlTexture; // a hull on wheels only, nil for the rest
    FWheel: PSdlTexture; // a hull on wheels only, nil for the rest
    FEyeGlow: PSdlTexture;
  public
    // ADef names the set - its file in the sprites folder, no extension -
    // and says whether the set holds wheels
    constructor Create(ARenderer: PSdlRenderer; const ADef: THullDef);
    destructor Destroy; override;
  end;

  // Where a hull stands and which way it heads
  THullStand = record
    Center: TSdlFPoint; // the middle of the hull, screen units
    Mirrored: Boolean; // the left-facing art heads right
  end;

  THull = class
  private
    FDef: THullDef;
    FArt: THullArt;
    FWear: Single;
    FEye: Single; // 0..1, how lit
    FLastEye: Single;
    FTurn: Single; // the wheels, degrees clockwise
    FLastTurn: Single;
    procedure TurnWheels(ARolled: Single);
    procedure DrawWheels(const ASprites: TSpriteRenderer;
      const AStand: THullStand; AAlpha: Single);
  public
    // AArt belongs to the caller and must outlive the hull
    constructor Create(const ADef: THullDef; AArt: THullArt);
    // AWear, ACharge: 0..1 - how battered, how close the next shot is.
    // ARolled - units the body has rolled along the floor since the last
    // tick, to the right above zero.
    procedure Tick(AWear, ACharge, ARolled: Single);
    // AAlpha - how far toward the next tick, which the eye and the wheels
    // are drawn between
    procedure Draw(const ASprites: TSpriteRenderer;
      const AStand: THullStand; AAlpha: Single);
    // Where a point of the art falls on the screen
    function Spot(const AStand: THullStand;
      const AHullPoint: THullPoint): TSdlFPoint;
  end;

implementation

uses
  System.Math, Render.Brush, Render.Glow;

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

constructor THullArt.Create(ARenderer: PSdlRenderer; const ADef: THullDef);
begin
  inherited Create;
  FRenderer := ARenderer;
  FSpriteSet := TSpriteSet.Create(SpriteSetsDir + ADef.SetName + '.mset');
  FCache := TSpriteCache.Create(ARenderer);
  FCache.DisableColorKey;
  FCache.EnableLinearFilter;
  FCache.AttachSpriteSet(FSpriteSet);

  FWhole := FCache.Get('hull');
  FWorn := FCache.Get('hullDamaged');
  if ADef.Wheels.Enabled then
  begin
    FChassis := FCache.Get('chassis');
    FWheel := FCache.Get('wheel');
  end;
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

procedure THull.Tick(AWear, ACharge, ARolled: Single);
begin
  FWear := AWear;

  FLastEye := FEye;
  FEye := ACharge;
  if FLastEye * EyeFade > FEye then
    FEye := FLastEye * EyeFade;

  if FDef.Wheels.Enabled then
    TurnWheels(ARolled);
end;

// A wheel rolling to the right turns clockwise, the way SDL counts
procedure THull.TurnWheels(ARolled: Single);
const
  WrapDegrees = 3600;
begin
  FLastTurn := FTurn;
  FTurn := FTurn + RadToDeg(ARolled / FDef.Wheels.Radius);
  if Abs(FTurn) > WrapDegrees then
  begin
    var WholeTurnDegrees: Single := 360 * Trunc(FTurn / 360);
    FTurn := FTurn - WholeTurnDegrees;
    FLastTurn := FLastTurn - WholeTurnDegrees;
  end;
end;

function THull.Spot(const AStand: THullStand;
  const AHullPoint: THullPoint): TSdlFPoint;
begin
  var Across := AHullPoint.X;
  if AStand.Mirrored then
    Across := FDef.Width - Across;
  Result.X := AStand.Center.X - FDef.Width / 2 + Across;
  Result.Y := AStand.Center.Y - FDef.Height / 2 + AHullPoint.Y;
end;

// A wheel is not mirrored with the hull: it is painted in flat light, and
// a mirror would only jerk the mark on its hub to the other side every
// time the body turns round
procedure THull.DrawWheels(const ASprites: TSpriteRenderer;
  const AStand: THullStand; AAlpha: Single);
begin
  var Side: Single := FDef.Wheels.Side;
  var Turn := Lerp(FLastTurn, FTurn, AAlpha);
  for var Axle in FDef.Wheels.Axles do
    ASprites.DrawTurned(FArt.FWheel, Spot(AStand, Axle), Side, Turn);
end;

procedure THull.Draw(const ASprites: TSpriteRenderer;
  const AStand: THullStand; AAlpha: Single);
const
  Opaque = 1.0;
begin
  var Width: Single := FDef.Width;
  var Height: Single := FDef.Height;
  if FDef.Wheels.Enabled then
  begin
    ASprites.DrawSized(FArt.FChassis, AStand.Center, Width, Height, Opaque,
      AStand.Mirrored);
    DrawWheels(ASprites, AStand, AAlpha);
  end;
  ASprites.DrawSized(FArt.FWhole, AStand.Center, Width, Height, Opaque,
    AStand.Mirrored);
  if FWear > 0 then
    ASprites.DrawSized(FArt.FWorn, AStand.Center, Width, Height, FWear,
      AStand.Mirrored);

  var Eye := Spot(AStand, FDef.Eye);
  var EyeLevel := Lerp(FLastEye, FEye, AAlpha);
  DrawGlow(FArt.FRenderer, FArt.FEyeGlow, Eye.X + ASprites.Origin.X,
    Eye.Y + ASprites.Origin.Y + ASprites.FineY,
    Lerp(EyeRestSize, EyeChargedSize, EyeLevel), EyeColor,
    Lerp(EyeRestLevel, 1, EyeLevel));
end;

end.
