{
  Monsters.Hull - a monster drawn as a hull out of layers: the TEK
  platform, the TEK tank, the TEK mount. A whole hull, and a worn copy of
  it over it that shows through as the lives run out. The red eye in the
  sensor housing glows and swells before every shot, and goes dark while
  the monster says the hull sleeps.

  A hull that drives stands on wheels: one picture at every axle, turned
  by the way the body has rolled, in front of the dark of the wheel wells
  and behind the hull, whose fenders shade it. A wheel it has lost is
  left off, and the picture of one off its axle is drawn where its owner
  says. The whole hull may lean about a point of the screen - every layer,
  every wheel and the eye turned about it as one.

  The hull stands on whole units like a frame; only the eye and the wheels
  draw between ticks. A machine that puts something between its wheels and
  its body - the mast of the Ram - draws the two halves itself, in turn;
  one that puts something between the dark of its wells and its wheels -
  the Ram's engine bays - draws those apart too. The platform and the
  mount are never mirrored: their art is symmetric, and the torn panel of
  the worn layer would jump from side to side at every turn. The tank
  faces left and is mirrored whole while it heads right.

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

  // The axles of a hull on wheels, by their order in its def
  THullAxles = set of Byte;

  // Where a hull stands, which way it heads, how it leans and which of its
  // wheels it has lost
  THullStand = record
    Center: TSdlFPoint; // the middle of the hull, screen units
    Mirrored: Boolean; // the left-facing art heads right
    // Degrees clockwise the whole hull is turned about Pivot, a point of
    // the screen
    Lean: Single;
    Pivot: TSdlFPoint;
    Shed: THullAxles;
    // APoint of the screen turned with the hull
    function Turned(const APoint: TSdlFPoint): TSdlFPoint;
    function TurnedCenter: TSdlFPoint;
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
    FAwake: Boolean;
    FWake: Single; // 0..1, how far the eye has come up from dark
    FLastWake: Single;
    procedure TurnWheels(ARolled: Single);
  public
    // AArt belongs to the caller and must outlive the hull
    constructor Create(const ADef: THullDef; AArt: THullArt);
    // A sleeping hull rests with its eye dark; an awake one with the eye
    // smoldering, which it comes up to over WakeTicks. Born awake.
    property Awake: Boolean read FAwake write FAwake;
    // Asleep and dark at once, without the ramp down
    procedure Doze;
    // 0 dark to 1 smoldering: how far the eye has come up
    property Wake: Single read FWake;
    // AWear, ACharge: 0..1 - how battered, how close the next shot is.
    // ARolled - units the body has rolled along the floor since the last
    // tick, to the right above zero.
    procedure Tick(AWear, ACharge, ARolled: Single);
    // AAlpha - how far toward the next tick, which the eye and the wheels
    // are drawn between. DrawUnder and then DrawBody.
    procedure Draw(const ASprites: TSpriteRenderer;
      const AStand: THullStand; AAlpha: Single);
    // The dark of the wheel wells and the wheels; nothing for a hull
    // without wheels. DrawChassis and then DrawWheels.
    procedure DrawUnder(const ASprites: TSpriteRenderer;
      const AStand: THullStand; AAlpha: Single);
    procedure DrawChassis(const ASprites: TSpriteRenderer;
      const AStand: THullStand);
    procedure DrawWheels(const ASprites: TSpriteRenderer;
      const AStand: THullStand; AAlpha: Single);
    // The hull, its worn copy and the eye
    procedure DrawBody(const ASprites: TSpriteRenderer;
      const AStand: THullStand; AAlpha: Single);
    // A wheel of the set off its axle: its middle at ACenter, turned ATurn
    // degrees clockwise
    procedure DrawWheel(const ASprites: TSpriteRenderer;
      const ACenter: TSdlFPoint; ATurn: Single);
    // Where a point of the art falls on the screen
    function Spot(const AStand: THullStand;
      const AHullPoint: THullPoint): TSdlFPoint;
  end;

implementation

uses
  System.Math, Render.Brush, Render.Glow;

const
  Opaque = 1.0;
  // The eye dims by this share a tick after a shot
  EyeFade = 0.85;
  EyeRestLevel = 0.3;
  EyeRestSize = 4.0;
  WakeTicks = 8;
  EyeChargedSize = 9.0;
  EyeColor: TRgb = (R: 255; G: 36; B: 20);
  EyeGlowSide = 64;

function Lerp(AFrom, ATo, AAmount: Single): Single;
begin
  Result := AFrom + (ATo - AFrom) * AAmount;
end;

// ---------------------------------------------------------------------------
// THullStand
// ---------------------------------------------------------------------------

function THullStand.Turned(const APoint: TSdlFPoint): TSdlFPoint;
begin
  if Lean = 0 then
    Exit(APoint);
  var Angle := DegToRad(Lean);
  var AcrossX := APoint.X - Pivot.X;
  var DownY := APoint.Y - Pivot.Y;
  Result.X := Pivot.X + AcrossX * Cos(Angle) - DownY * Sin(Angle);
  Result.Y := Pivot.Y + AcrossX * Sin(Angle) + DownY * Cos(Angle);
end;

function THullStand.TurnedCenter: TSdlFPoint;
begin
  Result := Turned(Center);
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
  FAwake := True;
  FWake := 1;
  FLastWake := 1;
end;

procedure THull.Doze;
begin
  FAwake := False;
  FWake := 0;
  FLastWake := 0;
end;

procedure THull.Tick(AWear, ACharge, ARolled: Single);
begin
  FWear := AWear;

  FLastEye := FEye;
  FEye := ACharge;
  if FLastEye * EyeFade > FEye then
    FEye := FLastEye * EyeFade;

  FLastWake := FWake;
  var WakeStep: Single := 1 / WakeTicks;
  if not FAwake then
    WakeStep := -WakeStep;
  FWake := EnsureRange(FWake + WakeStep, 0.0, 1.0);

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
  var Upright: TSdlFPoint;
  Upright.X := AStand.Center.X - FDef.Width / 2 + Across;
  Upright.Y := AStand.Center.Y - FDef.Height / 2 + AHullPoint.Y;
  Result := AStand.Turned(Upright);
end;

// A wheel is not mirrored with the hull: it is painted in flat light, and
// a mirror would only jerk the mark on its hub to the other side every
// time the body turns round
procedure THull.DrawWheels(const ASprites: TSpriteRenderer;
  const AStand: THullStand; AAlpha: Single);
begin
  if not FDef.Wheels.Enabled then
    Exit;
  var Turn := Lerp(FLastTurn, FTurn, AAlpha) + AStand.Lean;
  var Axles := FDef.Wheels.Axles;
  for var i := 0 to High(Axles) do
    if not (i in AStand.Shed) then
      DrawWheel(ASprites, Spot(AStand, Axles[i]), Turn);
end;

procedure THull.DrawWheel(const ASprites: TSpriteRenderer;
  const ACenter: TSdlFPoint; ATurn: Single);
begin
  ASprites.DrawTurned(FArt.FWheel, ACenter, FDef.Wheels.Side, ATurn);
end;

procedure THull.Draw(const ASprites: TSpriteRenderer;
  const AStand: THullStand; AAlpha: Single);
begin
  DrawUnder(ASprites, AStand, AAlpha);
  DrawBody(ASprites, AStand, AAlpha);
end;

procedure THull.DrawUnder(const ASprites: TSpriteRenderer;
  const AStand: THullStand; AAlpha: Single);
begin
  DrawChassis(ASprites, AStand);
  DrawWheels(ASprites, AStand, AAlpha);
end;

procedure THull.DrawChassis(const ASprites: TSpriteRenderer;
  const AStand: THullStand);
begin
  if not FDef.Wheels.Enabled then
    Exit;
  ASprites.DrawSized(FArt.FChassis, AStand.TurnedCenter, FDef.Width,
    FDef.Height, Opaque, AStand.Mirrored, AStand.Lean);
end;

procedure THull.DrawBody(const ASprites: TSpriteRenderer;
  const AStand: THullStand; AAlpha: Single);
begin
  var Width: Single := FDef.Width;
  var Height: Single := FDef.Height;
  var Center := AStand.TurnedCenter;
  ASprites.DrawSized(FArt.FWhole, Center, Width, Height, Opaque,
    AStand.Mirrored, AStand.Lean);
  if FWear > 0 then
    ASprites.DrawSized(FArt.FWorn, Center, Width, Height, FWear,
      AStand.Mirrored, AStand.Lean);

  var Eye := Spot(AStand, FDef.Eye);
  var EyeLevel := Lerp(FLastEye, FEye, AAlpha);
  var RestLevel := EyeRestLevel * Lerp(FLastWake, FWake, AAlpha);
  DrawGlow(FArt.FRenderer, FArt.FEyeGlow, Eye.X + ASprites.Origin.X,
    Eye.Y + ASprites.Origin.Y + ASprites.FineY,
    Lerp(EyeRestSize, EyeChargedSize, EyeLevel), EyeColor,
    Lerp(RestLevel, 1, EyeLevel));
end;

end.
