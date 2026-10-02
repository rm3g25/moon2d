{
  Monsters.Disc - a monster drawn as a spinning disc out of layers: the
  level-1 boss, TEK-R1. The armor ring turns, the hub stands still, the
  eye in it slides toward the hero, a still gloss lies over everything,
  and a worn copy of ring and hub shows through as the lives run out.
  The red sensor glows and swells before every shot.

  The disc keeps its pose of the last two ticks and draws between them:
  the logic runs at 33 Hz, the screen as fast as it can. What hangs on
  the disc (Render.Dynamics) asks for the same two poses and rides along.

  Not here: the death - a dying disc monster plays the death frames of
  its own set, as every monster does.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Monsters.Disc;
{$I ..\Moon2D.inc}

interface

uses
  Sdl2.Core, Render.Sprites, Sprites.Sets, Monsters.Defs;

type
  // The layers of one disc set, through a cache of its own: painted with
  // soft edges, so no color key; drawn at every size and angle, so
  // linear filtering
  TDiscArt = class
  private
    FRenderer: PSdlRenderer;
    FSpriteSet: TSpriteSet;
    FCache: TSpriteCache;
    FRim: PSdlTexture;
    FRimWorn: PSdlTexture;
    FCore: PSdlTexture;
    FCoreWorn: PSdlTexture;
    FIris: PSdlTexture;
    FGloss: PSdlTexture;
    FSensorGlow: PSdlTexture;
  public
    // ASetName - the set's file in the sprites folder, no extension
    constructor Create(ARenderer: PSdlRenderer; const ASetName: string);
    destructor Destroy; override;
  end;

  // What the monster tells its disc every tick
  TDiscDrive = record
    Center: TSdlFPoint; // where the disc stands
    Hero: TSdlFPoint; // what the eye follows
    SpinScale: Single; // 1 at the base step, more as the step grows
    Wear: Single; // 0..1, how battered
    Charge: Single; // 0..1, how close the next shot is
  end;

  // The disc at one tick
  TDiscPose = record
    Center: TSdlFPoint;
    // Degrees clockwise; the two poses of a pair are never wrapped apart
    Angle: Single;
    Iris: TSdlFPoint; // the eye's slide from the center
    Sensor: Single; // 0..1
  end;

  TDisc = class
  private
    FDef: TDiscDef;
    FArt: TDiscArt;
    FPose: TDiscPose;
    FLastPose: TDiscPose;
    FSpinRate: Single; // degrees a tick, clockwise
    FWear: Single;
    procedure TurnRim(ASpinScale: Single);
    procedure FollowHero(const AHero: TSdlFPoint);
    function PoseAt(AAlpha: Single): TDiscPose;
  public
    // AArt belongs to the caller and must outlive the disc. ACenter is
    // where it stands before the first tick - the screen may be drawn
    // before the disc is ever ticked.
    constructor Create(const ADef: TDiscDef; AArt: TDiscArt;
      const ACenter: TSdlFPoint);
    procedure Tick(const ADrive: TDiscDrive);
    procedure Draw(const ASprites: TSpriteRenderer; AAlpha: Single);
    property Pose: TDiscPose read FPose;
    property LastPose: TDiscPose read FLastPose;
  end;

implementation

uses
  Render.Brush, Render.Glow;

const
  // A tick of spin closes this share of the gap to the wanted rate: the
  // disc spins up from a standstill and into its rage in about a second
  SpinEase = 0.06;
  IrisEase = 0.2;
  // Closer than this the eye has no direction to look in
  IrisDeadZone = 0.5;
  // The sensor dims by this share a tick after a shot
  SensorFade = 0.85;
  // At rest the sensor still shows: the red dot is two pixels of the art
  SensorRestLevel = 0.45;
  SensorRestSize = 3.0;
  SensorChargedSize = 6.0;
  SensorColor: TRgb = (R: 255; G: 36; B: 20);
  SensorGlowSide = 64;
  WrapDegrees = 3600;
  Upright = 0.0;

function Lerp(AFrom, ATo, AAmount: Single): Single;
begin
  Result := AFrom + (ATo - AFrom) * AAmount;
end;

function LerpPoint(const AFrom, ATo: TSdlFPoint; AAmount: Single): TSdlFPoint;
begin
  Result.X := Lerp(AFrom.X, ATo.X, AAmount);
  Result.Y := Lerp(AFrom.Y, ATo.Y, AAmount);
end;

function Shifted(const APoint, AShift: TSdlFPoint): TSdlFPoint;
begin
  Result.X := APoint.X + AShift.X;
  Result.Y := APoint.Y + AShift.Y;
end;

// ---------------------------------------------------------------------------
// TDiscArt
// ---------------------------------------------------------------------------

constructor TDiscArt.Create(ARenderer: PSdlRenderer; const ASetName: string);
begin
  inherited Create;
  FRenderer := ARenderer;
  FSpriteSet := TSpriteSet.Create(SpriteSetsDir + ASetName + '.mset');
  FCache := TSpriteCache.Create(ARenderer);
  FCache.DisableColorKey;
  FCache.EnableLinearFilter;
  FCache.AttachSpriteSet(FSpriteSet);

  FRim := FCache.Get('rim');
  FRimWorn := FCache.Get('rimDamaged');
  FCore := FCache.Get('core');
  FCoreWorn := FCache.Get('coreDamaged');
  FIris := FCache.Get('iris');
  FGloss := FCache.Get('gloss');
  FSensorGlow := CreateGlowShape(ARenderer, gsPoint, SensorGlowSide);
end;

// The cache before the set: it reads from the set, never the reverse
destructor TDiscArt.Destroy;
begin
  if Assigned(FSensorGlow) then
    SDL_DestroyTexture(FSensorGlow);
  FCache.Free;
  FSpriteSet.Free;
  inherited;
end;

// ---------------------------------------------------------------------------
// TDisc
// ---------------------------------------------------------------------------

constructor TDisc.Create(const ADef: TDiscDef; AArt: TDiscArt;
  const ACenter: TSdlFPoint);
begin
  inherited Create;
  FDef := ADef;
  FArt := AArt;
  FPose.Center := ACenter;
  FLastPose := FPose;
end;

procedure TDisc.Tick(const ADrive: TDiscDrive);
begin
  FLastPose := FPose;
  FPose.Center := ADrive.Center;
  TurnRim(ADrive.SpinScale);
  FollowHero(ADrive.Hero);
  FWear := ADrive.Wear;

  FPose.Sensor := ADrive.Charge;
  if FLastPose.Sensor * SensorFade > FPose.Sensor then
    FPose.Sensor := FLastPose.Sensor * SensorFade;
end;

// JSON spin runs counterclockwise, SDL turns clockwise
procedure TDisc.TurnRim(ASpinScale: Single);
begin
  var WantedRate: Single := -FDef.Spin * ASpinScale;
  FSpinRate := FSpinRate + (WantedRate - FSpinRate) * SpinEase;
  FPose.Angle := FPose.Angle + FSpinRate;
  if Abs(FPose.Angle) > WrapDegrees then
  begin
    var WholeTurnDegrees: Single := 360 * Trunc(FPose.Angle / 360);
    FPose.Angle := FPose.Angle - WholeTurnDegrees;
    FLastPose.Angle := FLastPose.Angle - WholeTurnDegrees;
  end;
end;

procedure TDisc.FollowHero(const AHero: TSdlFPoint);
var
  Wanted: TSdlFPoint;
begin
  Wanted := Default(TSdlFPoint);
  var DeltaX := AHero.X - FPose.Center.X;
  var DeltaY := AHero.Y - FPose.Center.Y;
  var Distance := Sqrt(DeltaX * DeltaX + DeltaY * DeltaY);
  if Distance > IrisDeadZone then
  begin
    Wanted.X := DeltaX / Distance * FDef.IrisReach;
    Wanted.Y := DeltaY / Distance * FDef.IrisReach;
  end;
  FPose.Iris := LerpPoint(FPose.Iris, Wanted, IrisEase);
end;

function TDisc.PoseAt(AAlpha: Single): TDiscPose;
begin
  Result.Center := LerpPoint(FLastPose.Center, FPose.Center, AAlpha);
  Result.Angle := Lerp(FLastPose.Angle, FPose.Angle, AAlpha);
  Result.Iris := LerpPoint(FLastPose.Iris, FPose.Iris, AAlpha);
  Result.Sensor := Lerp(FLastPose.Sensor, FPose.Sensor, AAlpha);
end;

procedure TDisc.Draw(const ASprites: TSpriteRenderer; AAlpha: Single);
begin
  var Shown := PoseAt(AAlpha);
  var Side: Single := FDef.Side;
  ASprites.DrawTurned(FArt.FRim, Shown.Center, Side, Shown.Angle);
  if FWear > 0 then
    ASprites.DrawTurned(FArt.FRimWorn, Shown.Center, Side, Shown.Angle,
      FWear);
  ASprites.DrawTurned(FArt.FCore, Shown.Center, Side, Upright);
  if FWear > 0 then
    ASprites.DrawTurned(FArt.FCoreWorn, Shown.Center, Side, Upright, FWear);

  var Eye := Shifted(Shown.Center, Shown.Iris);
  ASprites.DrawTurned(FArt.FIris, Eye, Side, Upright);
  ASprites.DrawTurned(FArt.FGloss, Shown.Center, Side, Upright);

  DrawGlow(FArt.FRenderer, FArt.FSensorGlow, Eye.X + ASprites.Origin.X,
    Eye.Y + ASprites.Origin.Y,
    Lerp(SensorRestSize, SensorChargedSize, Shown.Sensor), SensorColor,
    Lerp(SensorRestLevel, 1, Shown.Sensor));
end;

end.
