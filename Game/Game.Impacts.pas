{
  Game.Impacts - what a bullet throws off the armor it strikes: a flash
  at the point, a fan of sparks the way the bullet glances off, and now
  and then a tracer - what is left of the bullet, ringing away off the
  walls. For the monsters made of metal ("material" in monsters.json).
  Armor struck again within a moment answers thinner: a few sparks, a
  dimmer flash, no tracer - a burst of fire must not bury the fight.

  The look only: the wound, the knockback and the sound are the game's.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.Impacts;
{$I ..\Moon2D.inc}

interface

uses
  System.Generics.Collections, Sdl2.Core, Render.Brush, Effects.Sparks,
  Levels.Dynamics;

type
  // A bullet meeting armor, in screen units and units per tick. The
  // normal is the way the armor faces at the point, a unit vector.
  TStrike = record
    X, Y: Single;
    SpeedX, SpeedY: Single;
    NormalX, NormalY: Single;
    Rapid: Boolean; // the armor was struck a moment ago
    // Sparks on top of a bullet's fan: a heavier blow throws more
    ExtraSparks: Integer;
  end;

  TImpacts = class
  private type
    TFlash = record
      X, Y: Single;
      Level: Single;
      Age: Integer;
    end;
  private
    FSparks: TSparkField;
    FTracers: TSparkField;
    FFlashes: TList<TFlash>;
    FFlashedThisTick: Boolean;
    // Own stream, not Random: that one feeds the boss spawn table
    FRandom: TXorShift;
    procedure ThrowFan(const AStrike: TStrike; const AGlance: TSdlFPoint);
    procedure ThrowTracer(const AStrike: TStrike; const AGlance: TSdlFPoint);
    procedure AddFlash(const AStrike: TStrike);
    procedure DrawFlash(const ACanvas: TDynamicCanvas; const AFlash: TFlash;
      AOrigin: TSdlPoint; AAlpha: Single);
  public
    // ASolid answers in screen units
    constructor Create(const ASolid: TSolidProbe);
    destructor Destroy; override;
    // True when a tracer flew off
    function Land(const AStrike: TStrike): Boolean;
    procedure Tick;
    // AOrigin - the shake of what was struck
    procedure Draw(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
      AAlpha: Single);
    // A door or a death: nothing follows the hero to the next screen
    procedure Clear;
  end;

// The bullet is inside the box it struck: moves the strike back along
// the bullet's path to the edge it came in through and turns the normal
// the way that edge faces
procedure TraceEntry(var AStrike: TStrike; const ABox: TSdlFRect);
// For round armor: the normal from the center through the point
procedure FaceFromCenter(var AStrike: TStrike; const ACenter: TSdlFPoint);

implementation

uses
  System.Math, Render.Glow;

const
  // The fan off a hit: light, quick to slow, most of it slow
  HitSparkLook: TSparkLook = (
    Gravity: 0.18;
    AirKeep: 0.93;
    LifeMin: 6;
    LifeMax: 20;
    Width: 2.6;
    ThinShare: 0.55;
    StreakTicks: 1.6;
    SpeedCurve: 2;
    Level: 1;
    Heat: (Hot: (R: 255; G: 246; B: 220); Warm: (R: 255; G: 168; B: 70);
      Cool: (R: 176; G: 36; B: 16); WarmAt: 0.35);
    Wall: swBounce;
    Bounce: (Keep: 0.42; Grip: 0.7; LifeLost: 0.35);
    ForkChance: 0.3);
  // What is left of the bullet: fast, flat, bright to the end
  TracerSparkLook: TSparkLook = (
    Gravity: 0.03;
    AirKeep: 0.99;
    LifeMin: 14;
    LifeMax: 18;
    Width: 3;
    ThinShare: 1;
    StreakTicks: 2.4;
    SpeedCurve: 1;
    Level: 1;
    Heat: (Hot: (R: 255; G: 246; B: 220); Warm: (R: 255; G: 206; B: 96);
      Cool: (R: 255; G: 128; B: 40); WarmAt: 0.5);
    Wall: swBounce;
    Bounce: (Keep: 0.7; Grip: 1; LifeLost: 0.2);
    ForkChance: 0);

  MaxSparks = 512;
  MaxTracers = 16;
  MaxFlashes = 16;
  SparkSeed = $48697421; // "Hit!"
  TracerSeed = $50696E67; // "Ping"
  DiceSeed = $44696365; // "Dice"

  FanSparks = 9;
  RapidFanSparks = 4;
  FanCone = 86; // degrees wide
  FanSlowSpeed = 2.5;
  FanFastSpeed = 9.5;
  // The fan leans this far from the armor's normal toward the glance
  GlanceShare = 0.6;
  TracerChance = 0.3;
  TracerCone = 14;
  TracerSpeed = 13;

  FlashTicks = 3;
  FlashSize = 24; // units across
  FlashGrowth = 0.4; // the flash swells by this share as it dies
  FlashCoreShare = 0.4;
  RapidFlashLevel = 0.5;
  FlashColor: TRgb = (R: 255; G: 236; B: 200);

  // Shorter than this a vector has no direction
  MinDirection = 0.001;

procedure TraceEntry(var AStrike: TStrike; const ABox: TSdlFRect);
const
  // In ticks back: an edge the bullet never crossed
  Never = 1E9;
begin
  AStrike.NormalX := 0;
  AStrike.NormalY := -1;
  // A bullet hanging still came in through no edge: the armor walked
  // onto it, and the sparks go up
  if (AStrike.SpeedX = 0) and (AStrike.SpeedY = 0) then
    Exit;

  // It never crossed the edges of an axis it does not move along
  var TicksBackX: Single := Never;
  if AStrike.SpeedX > 0 then
    TicksBackX := (AStrike.X - ABox.X) / AStrike.SpeedX
  else if AStrike.SpeedX < 0 then
    TicksBackX := (AStrike.X - (ABox.X + ABox.W)) / AStrike.SpeedX;
  var TicksBackY: Single := Never;
  if AStrike.SpeedY > 0 then
    TicksBackY := (AStrike.Y - ABox.Y) / AStrike.SpeedY
  else if AStrike.SpeedY < 0 then
    TicksBackY := (AStrike.Y - (ABox.Y + ABox.H)) / AStrike.SpeedY;

  if TicksBackX <= TicksBackY then
  begin
    AStrike.NormalX := -Sign(AStrike.SpeedX);
    AStrike.NormalY := 0;
  end
  else
    AStrike.NormalY := -Sign(AStrike.SpeedY);

  // No further than the tick the bullet has just flown: a monster may
  // have walked onto it
  var TicksBack: Single := EnsureRange(Min(TicksBackX, TicksBackY), 0, 1);
  AStrike.X := AStrike.X - AStrike.SpeedX * TicksBack;
  AStrike.Y := AStrike.Y - AStrike.SpeedY * TicksBack;
end;

procedure FaceFromCenter(var AStrike: TStrike; const ACenter: TSdlFPoint);
begin
  var OutX: Single := AStrike.X - ACenter.X;
  var OutY: Single := AStrike.Y - ACenter.Y;
  var Reach: Single := Hypot(OutX, OutY);
  if Reach < MinDirection then
    Exit;
  AStrike.NormalX := OutX / Reach;
  AStrike.NormalY := OutY / Reach;
end;

// The bullet glances off as light off a mirror; one coming out of the
// armor, or with no speed at all, leaves along the normal
function GlanceOf(const AStrike: TStrike): TSdlFPoint;
begin
  Result.X := AStrike.NormalX;
  Result.Y := AStrike.NormalY;
  var Speed: Single := Hypot(AStrike.SpeedX, AStrike.SpeedY);
  var SpeedAlongNormal: Single := AStrike.SpeedX * AStrike.NormalX +
    AStrike.SpeedY * AStrike.NormalY;
  if (SpeedAlongNormal >= 0) or (Speed < MinDirection) then
    Exit;
  Result.X := (AStrike.SpeedX - 2 * SpeedAlongNormal * AStrike.NormalX) / Speed;
  Result.Y := (AStrike.SpeedY - 2 * SpeedAlongNormal * AStrike.NormalY) / Speed;
end;

// Degrees counterclockwise from the right, of a vector in screen units,
// whose Y runs down
function HeadingOf(AX, AY: Single): Single;
begin
  Result := RadToDeg(ArcTan2(-AY, AX));
end;

// ---------------------------------------------------------------------------
// TImpacts
// ---------------------------------------------------------------------------

constructor TImpacts.Create(const ASolid: TSolidProbe);
begin
  inherited Create;
  FSparks := TSparkField.Create(HitSparkLook, ASolid, MaxSparks, SparkSeed);
  FTracers := TSparkField.Create(TracerSparkLook, ASolid, MaxTracers,
    TracerSeed);
  FFlashes := TList<TFlash>.Create;
  FRandom.Seed := DiceSeed;
end;

destructor TImpacts.Destroy;
begin
  FFlashes.Free;
  FTracers.Free;
  FSparks.Free;
  inherited;
end;

procedure TImpacts.ThrowFan(const AStrike: TStrike;
  const AGlance: TSdlFPoint);
var
  Fan: TSparkSpray;
begin
  Fan.Count := FanSparks;
  if AStrike.Rapid then
    Fan.Count := RapidFanSparks;
  Inc(Fan.Count, AStrike.ExtraSparks);
  Fan.Heading := HeadingOf(
    AGlance.X * GlanceShare + AStrike.NormalX * (1 - GlanceShare),
    AGlance.Y * GlanceShare + AStrike.NormalY * (1 - GlanceShare));
  Fan.Cone := FanCone;
  Fan.SlowSpeed := FanSlowSpeed;
  Fan.FastSpeed := FanFastSpeed;
  FSparks.Spray(AStrike.X, AStrike.Y, Fan);
end;

procedure TImpacts.ThrowTracer(const AStrike: TStrike;
  const AGlance: TSdlFPoint);
var
  Tracer: TSparkSpray;
begin
  Tracer.Count := 1;
  Tracer.Heading := HeadingOf(AGlance.X, AGlance.Y);
  Tracer.Cone := TracerCone;
  Tracer.SlowSpeed := TracerSpeed;
  Tracer.FastSpeed := TracerSpeed;
  FTracers.Spray(AStrike.X, AStrike.Y, Tracer);
end;

// Hits that crowd one armor share one flash a tick: additive light piles
// up, and a volley would burn a white hole in the screen
procedure TImpacts.AddFlash(const AStrike: TStrike);
var
  Flash: TFlash;
begin
  if AStrike.Rapid and FFlashedThisTick then
    Exit;
  if FFlashes.Count = MaxFlashes then
    Exit;
  FFlashedThisTick := True;

  Flash.X := AStrike.X;
  Flash.Y := AStrike.Y;
  Flash.Level := 1;
  if AStrike.Rapid then
    Flash.Level := RapidFlashLevel;
  Flash.Age := 0;
  FFlashes.Add(Flash);
end;

function TImpacts.Land(const AStrike: TStrike): Boolean;
begin
  var Glance := GlanceOf(AStrike);
  ThrowFan(AStrike, Glance);
  AddFlash(AStrike);

  // A bullet that hung still leaves nothing to fly off
  var Moving := Hypot(AStrike.SpeedX, AStrike.SpeedY) >= MinDirection;
  Result := Moving and not AStrike.Rapid and
    (FRandom.NextUnit < TracerChance);
  if Result then
    ThrowTracer(AStrike, Glance);
end;

procedure TImpacts.Tick;
begin
  FFlashedThisTick := False;
  for var i := FFlashes.Count - 1 downto 0 do
  begin
    var Flash := FFlashes[i];
    Inc(Flash.Age);
    if Flash.Age >= FlashTicks then
      FFlashes.Delete(i)
    else
      FFlashes[i] := Flash;
  end;
  FSparks.Tick;
  FTracers.Tick;
end;

procedure TImpacts.DrawFlash(const ACanvas: TDynamicCanvas;
  const AFlash: TFlash; AOrigin: TSdlPoint; AAlpha: Single);
begin
  var Share: Single := (AFlash.Age + AAlpha) / FlashTicks;
  if Share > 1 then
    Share := 1;
  var Level: Single := AFlash.Level * Sqr(1 - Share);
  var CenterX: Single := AOrigin.X + AFlash.X;
  var CenterY: Single := AOrigin.Y + AFlash.Y;
  var Across: Single := FlashSize * (1 + FlashGrowth * Share);
  DrawGlow(ACanvas.Renderer, ACanvas.PointGlow, CenterX, CenterY, Across,
    FlashColor, Level);
  DrawGlow(ACanvas.Renderer, ACanvas.PointGlow, CenterX, CenterY,
    Across * FlashCoreShare, White, Level);
end;

procedure TImpacts.Draw(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
  AAlpha: Single);
var
  SparkOrigin: TSdlFPoint;
begin
  for var Flash in FFlashes do
    DrawFlash(ACanvas, Flash, AOrigin, AAlpha);

  var Brush := SparkBrush(ACanvas.Renderer, ACanvas.StreakGlow);
  SparkOrigin.X := AOrigin.X;
  SparkOrigin.Y := AOrigin.Y;
  FSparks.Draw(Brush, SparkOrigin, AAlpha);
  FTracers.Draw(Brush, SparkOrigin, AAlpha);
end;

procedure TImpacts.Clear;
begin
  FFlashes.Clear;
  FSparks.Clear;
  FTracers.Clear;
end;

end.
