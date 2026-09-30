{
  Levels.Dynamics - the dynamic objects of a level, the "dynamics"
  section of level JSON: things placed like the static objects of
  Levels.Defs, but alive - they change from tick to tick.

  Every kind descends from TDynamicObject and lives in this unit. The
  ancestor holds and reads what every kind shares - where it stands,
  its tint, its parent; a kind adds its own properties, its tick and
  its drawing. A new kind is a class here, a word in DynamicKindIds
  and a branch in CreateDynamic.

  The parent works as in the VCL, for coordinates only: without one an
  object is nailed to a point of its screen; with one, x and y count
  from the parent's top-left corner and the object shows wherever the
  parent does. The parent is named by tag; finding it is the business
  of Render.Dynamics.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Levels.Dynamics;
{$I ..\Moon2D.inc}

interface

uses
  System.SysUtils, System.JSON, System.Generics.Collections, Sdl2.Core,
  Levels.Tint;

type
  EDynamicError = class(Exception);

  // What every kind draws with; the renderer makes the textures at
  // level load and frees them with itself, before the level
  TDynamicCanvas = record
    Renderer: PSdlRenderer;
    PointGlow: PSdlTexture;
    FlareGlow: PSdlTexture;
    StarburstGlow: PSdlTexture;
  end;

  // Shared by every kind. JSON: "screen" or "parent" - one of the two -
  // then "x", "y" and an optional "tint", as the static objects have.
  TDynamicPlacement = record
    Screen: Integer; // 1-based; 0 under a parent, which decides it
    Parent: string; // a static object's tag; '' = nailed to the screen
    X, Y: Single; // screen units; from the parent's top-left under one
    Tint: TColorTint;
  end;

  TDynamicObject = class abstract
  private
    FPlacement: TDynamicPlacement;
  protected
    procedure DrawAt(const ACanvas: TDynamicCanvas; AX, AY: Single;
      AAlpha: Single); virtual; abstract;
  public
    constructor Create(const APlacement: TDynamicPlacement);
    procedure Tick; virtual; abstract;
    // AOriginX/AOriginY - the corner the placement counts from: the
    // parent's top-left or the screen's, shake included. AAlpha is the
    // timestep's, for motion between ticks.
    procedure Draw(const ACanvas: TDynamicCanvas;
      AOriginX, AOriginY: Single; AAlpha: Single);
    property Placement: TDynamicPlacement read FPlacement;
  end;

  TDynamicObjects = TObjectList<TDynamicObject>;

  TBlinkPattern = (bpSteady, bpPulse, bpFlash, bpDouble, bpFaulty, bpDying);

  // A signal lamp: a hot core, a colored halo, a spill of light on what
  // is around it, on the peak of a flash a four-spike glint, and if
  // asked a starburst - long thin rays up, down, left and right that
  // stretch with the flash. The tint is the color of the light.
  // Frequency is in blinks per second; intensity, glint and
  // rayIntensity are percentages; size is the halo across and rays the
  // reach of a ray from the center, in screen units (0 = no starburst).
  // JSON:
  //   {"kind": "beacon", "parent": "ship", "x": 16.1, "y": 1.2,
  //    "tint": [25, 55, 100], "blink": "double", "frequency": 0.75,
  //    "intensity": 100, "size": 14, "glint": 50,
  //    "rays": 36, "rayIntensity": 70}
  TBeacon = class(TDynamicObject)
  private
    FBlink: TBlinkPattern;
    FFrequency: Single;
    FIntensity: Single; // 0..1
    FSize: Single;
    FGlint: Single; // 0..1
    FRays: Single;
    FRayIntensity: Single; // 0..1
    FSeed: Cardinal; // lamps at different points fail out of step
    FTicks: Integer;
    function BlinkLevel(AAlpha: Single): Single;
  protected
    procedure DrawAt(const ACanvas: TDynamicCanvas; AX, AY: Single;
      AAlpha: Single); override;
  public
    constructor Create(const APlacement: TDynamicPlacement;
      AObj: TJSONObject; const AOwner: string);
    procedure Tick; override;
  end;

// Reads the "dynamics" array of a level; an absent section is an empty
// list. The caller owns the result. ALevelId names the level in errors.
function ParseDynamics(ARoot: TJSONObject;
  const ALevelId: string): TDynamicObjects;

implementation

uses
  System.Math, Render.Sprites, Render.Brush, Render.Glow;

type
  TDynamicKind = (dkBeacon);

const
  // The JSON vocabulary of "kind" and "blink"
  DynamicKindIds: array [TDynamicKind] of string = ('beacon');
  BlinkPatternIds: array [TBlinkPattern] of string = (
    'steady', 'pulse', 'flash', 'double', 'faulty', 'dying');

  // Frequency is per second of game time; the logic runs 33 ticks a
  // second (tickRate of Game.Config)
  LogicTicksPerSecond = 33;

resourcestring
  SDynamicBadKind = 'Level "%s": dynamic object #%d: unknown kind "%s"';
  SDynamicKindUnbuilt = 'Dynamic kind "%s" has no constructor';
  SDynamicNoPlace = 'Level "%s": %s names neither a screen nor a parent';
  SDynamicTwoPlaces = 'Level "%s": %s names both a screen and a parent - '
    + 'the parent decides the screen';
  SBeaconBadBlink = '%s: unknown blink "%s"';
  SBeaconBadNumber = '%s: "%s" must be above zero';
  SBeaconBadPercent = '%s: "%s" takes a percentage, 0..100';
  SBeaconBadReach = '%s: "%s" cannot be below zero';

const
  // Beacon light, in shares of the halo size
  SpillScale = 3.0;
  CoreScale = 0.3;
  GlintScale = 2.5;
  // A starburst at rest keeps this share of its reach; the flash
  // stretches it the rest of the way
  RayRestReach = 0.6;
  // Beacon light, in shares of the intensity
  SpillLevel = 0.25;
  // The lamp glass keeps a glow between flashes: a lamp, not a hole
  EmberLevel = 0.08;
  CoreWhiteness = 0.6;
  // Flash shape, in shares of one blink cycle
  FlashAttack = 0.04;
  FlashDecay = 0.12;
  DoubleDecay = 0.05;
  SecondFlashAt = 0.2;
  SecondFlashShare = 0.8;
  // A faulty lamp: a cycle cut into slots, each holds, sags or drops out
  FaultySlots = 8;
  FaultyDropChance = 0.2;
  FaultySagChance = 0.15;
  FaultySagLevel = 0.45;
  // A dying battery: every blink cycle a new level, never a bright one
  DyingFloor = 0.05;
  DyingCeiling = 0.4;
  // Neighboring slot numbers make neighboring seeds; a few draws apart
  // them
  NoiseWarmUp = 3;

  // The seed is the position in tenths of a unit, x in the high half
  SeedPrecision = 10;

  DefaultFrequency = 1.0;
  DefaultBeaconSize = 12.0;
  DefaultRayIntensity = 60;

function TintColor(const ATint: TColorTint): TRgb;
begin
  Result.R := PercentToColorMod(ATint.R);
  Result.G := PercentToColorMod(ATint.G);
  Result.B := PercentToColorMod(ATint.B);
end;

// ---------------------------------------------------------------------------
// TDynamicObject
// ---------------------------------------------------------------------------

constructor TDynamicObject.Create(const APlacement: TDynamicPlacement);
begin
  inherited Create;
  FPlacement := APlacement;
end;

procedure TDynamicObject.Draw(const ACanvas: TDynamicCanvas;
  AOriginX, AOriginY: Single; AAlpha: Single);
begin
  DrawAt(ACanvas, AOriginX + FPlacement.X, AOriginY + FPlacement.Y, AAlpha);
end;

// ---------------------------------------------------------------------------
// TBeacon
// ---------------------------------------------------------------------------

// Sharp rise, exponential fall; APhase below zero is the dark before it
function FlashLevel(APhase, ADecay: Single): Single;
begin
  if APhase < 0 then
    Exit(0);
  if APhase < FlashAttack then
    Exit(APhase / FlashAttack);
  Result := Exp(-(APhase - FlashAttack) / ADecay);
end;

// 0..1 for a numbered slot of time. It follows from the number alone,
// so a frame drawn between two ticks never disagrees with either of them
function SlotRoll(ASlot: Integer; ASeed: Cardinal): Single;
var
  Noise: TXorShift;
begin
  Noise.Seed := (Cardinal(ASlot) xor ASeed) or 1;
  for var i := 1 to NoiseWarmUp do
    Noise.NextUnit;
  Result := Noise.NextUnit;
end;

function FaultyLevel(ACycle: Integer; APhase: Single; ASeed: Cardinal): Single;
begin
  var Slot: Integer := Trunc(APhase * FaultySlots);
  var Roll := SlotRoll(ACycle * FaultySlots + Slot, ASeed);
  if Roll < FaultyDropChance then
    Result := 0
  else if Roll < FaultyDropChance + FaultySagChance then
    Result := FaultySagLevel
  else
    Result := 1;
end;

function BlinkOf(const AId, AOwner: string): TBlinkPattern;
begin
  for var Pattern := Low(TBlinkPattern) to High(TBlinkPattern) do
    if SameText(AId, BlinkPatternIds[Pattern]) then
      Exit(Pattern);
  raise EDynamicError.CreateFmt(SBeaconBadBlink, [AOwner, AId]);
end;

function ReadPositive(AObj: TJSONObject; const AKey: string;
  ADefault: Single; const AOwner: string): Single;
begin
  Result := AObj.GetValue<Double>(AKey, ADefault);
  if Result <= 0 then
    raise EDynamicError.CreateFmt(SBeaconBadNumber, [AOwner, AKey]);
end;

// A length where zero means "none"
function ReadReach(AObj: TJSONObject; const AKey, AOwner: string): Single;
begin
  Result := AObj.GetValue<Double>(AKey, 0);
  if Result < 0 then
    raise EDynamicError.CreateFmt(SBeaconBadReach, [AOwner, AKey]);
end;

// A percentage in JSON, a share in the code
function ReadShare(AObj: TJSONObject; const AKey: string;
  ADefault: Integer; const AOwner: string): Single;
begin
  var Percent := AObj.GetValue<Integer>(AKey, ADefault);
  if (Percent < 0) or (Percent > 100) then
    raise EDynamicError.CreateFmt(SBeaconBadPercent, [AOwner, AKey]);
  Result := Percent / 100;
end;

constructor TBeacon.Create(const APlacement: TDynamicPlacement;
  AObj: TJSONObject; const AOwner: string);
begin
  inherited Create(APlacement);
  FBlink := BlinkOf(AObj.GetValue<string>('blink',
    BlinkPatternIds[bpFlash]), AOwner);
  FFrequency := ReadPositive(AObj, 'frequency', DefaultFrequency, AOwner);
  FIntensity := ReadShare(AObj, 'intensity', 100, AOwner);
  FSize := ReadPositive(AObj, 'size', DefaultBeaconSize, AOwner);
  FGlint := ReadShare(AObj, 'glint', 0, AOwner);
  FRays := ReadReach(AObj, 'rays', AOwner);
  FRayIntensity := ReadShare(AObj, 'rayIntensity', DefaultRayIntensity,
    AOwner);
  FSeed := (Cardinal(Round(APlacement.X * SeedPrecision)) shl 16) xor
    Cardinal(Round(APlacement.Y * SeedPrecision));
end;

procedure TBeacon.Tick;
begin
  Inc(FTicks);
end;

// 0..1 - how far the lamp is into its flash at this moment
function TBeacon.BlinkLevel(AAlpha: Single): Single;
begin
  var Cycles: Double := (FTicks + AAlpha) * FFrequency / LogicTicksPerSecond;
  var Cycle: Integer := Trunc(Cycles);
  var Phase: Single := Cycles - Cycle;
  case FBlink of
    bpSteady:
      Result := 1;
    bpPulse:
      Result := Sqr(Sin(Pi * Phase));
    bpFlash:
      Result := FlashLevel(Phase, FlashDecay);
    bpDouble:
      begin
        var First := FlashLevel(Phase, DoubleDecay);
        var Second: Single := SecondFlashShare *
          FlashLevel(Phase - SecondFlashAt, DoubleDecay);
        Result := Max(First, Second);
      end;
    bpFaulty:
      Result := FaultyLevel(Cycle, Phase, FSeed);
  else
    Result := DyingFloor + (DyingCeiling - DyingFloor) * SlotRoll(Cycle, FSeed);
  end;
end;

procedure TBeacon.DrawAt(const ACanvas: TDynamicCanvas; AX, AY: Single;
  AAlpha: Single);
begin
  var Flash := BlinkLevel(AAlpha);
  var Lit := EmberLevel + (1 - EmberLevel) * Flash;
  var Color := TintColor(Placement.Tint);

  DrawGlow(ACanvas.Renderer, ACanvas.PointGlow, AX, AY, FSize * SpillScale,
    Color, FIntensity * SpillLevel * Flash);
  DrawGlow(ACanvas.Renderer, ACanvas.PointGlow, AX, AY, FSize,
    Color, FIntensity * Lit);
  DrawGlow(ACanvas.Renderer, ACanvas.PointGlow, AX, AY, FSize * CoreScale,
    Mix(Color, White, CoreWhiteness), FIntensity * Lit);
  if FGlint > 0 then
    DrawGlow(ACanvas.Renderer, ACanvas.FlareGlow, AX, AY,
      FSize * GlintScale, Color, FIntensity * FGlint * Flash * Flash * Flash);
  if FRays > 0 then
  begin
    var Reach := FRays * (RayRestReach + (1 - RayRestReach) * Flash);
    DrawGlow(ACanvas.Renderer, ACanvas.StarburstGlow, AX, AY, 2 * Reach,
      Color, FIntensity * FRayIntensity * Flash);
  end;
end;

// ---------------------------------------------------------------------------
// Parsing
// ---------------------------------------------------------------------------

function KindOf(const AId, ALevelId: string; AIndex: Integer): TDynamicKind;
begin
  for var Kind := Low(TDynamicKind) to High(TDynamicKind) do
    if SameText(AId, DynamicKindIds[Kind]) then
      Exit(Kind);
  raise EDynamicError.CreateFmt(SDynamicBadKind, [ALevelId, AIndex + 1, AId]);
end;

function ReadPlacement(AObj: TJSONObject;
  const ALevelId, AOwner: string): TDynamicPlacement;
begin
  Result := Default(TDynamicPlacement);
  Result.Parent := AObj.GetValue<string>('parent', '');
  var HasScreen := AObj.TryGetValue<Integer>('screen', Result.Screen);
  if (Result.Parent = '') and not HasScreen then
    raise EDynamicError.CreateFmt(SDynamicNoPlace, [ALevelId, AOwner]);
  if (Result.Parent <> '') and HasScreen then
    raise EDynamicError.CreateFmt(SDynamicTwoPlaces, [ALevelId, AOwner]);

  Result.X := AObj.GetValue<Double>('x');
  Result.Y := AObj.GetValue<Double>('y');
  Result.Tint := ReadTint(AObj, AOwner);
end;

function CreateDynamic(AKind: TDynamicKind;
  const APlacement: TDynamicPlacement; AObj: TJSONObject;
  const AOwner: string): TDynamicObject;
begin
  case AKind of
    dkBeacon:
      Result := TBeacon.Create(APlacement, AObj, AOwner);
  else
    raise EDynamicError.CreateFmt(SDynamicKindUnbuilt,
      [DynamicKindIds[AKind]]);
  end;
end;

function ParseDynamics(ARoot: TJSONObject;
  const ALevelId: string): TDynamicObjects;
begin
  Result := TDynamicObjects.Create(True);
  try
    var DynamicsArr := ARoot.GetValue<TJSONArray>('dynamics', nil);
    if DynamicsArr = nil then
      Exit;

    for var i := 0 to DynamicsArr.Count - 1 do
    begin
      var Obj := DynamicsArr.Items[i] as TJSONObject;
      var Kind := KindOf(Obj.GetValue<string>('kind', ''), ALevelId, i);
      // "beacon #2" - dynamic objects carry no id of their own
      var Owner := Format('%s #%d', [DynamicKindIds[Kind], i + 1]);
      var Placement := ReadPlacement(Obj, ALevelId, Owner);
      Result.Add(CreateDynamic(Kind, Placement, Obj, Owner));
    end;
  except
    Result.Free;
    raise;
  end;
end;

end.
