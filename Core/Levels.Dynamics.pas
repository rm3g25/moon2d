{
  Levels.Dynamics - the dynamic objects of a level, the "dynamics"
  section of level JSON: things placed like the static objects of
  Levels.Defs, but alive - they change from tick to tick.

  Every kind descends from TDynamicObject and lives in this unit. The
  ancestor holds and reads what every kind shares - where it stands,
  its tint, its parent, its tag, its layer and its intensity; a kind
  adds its own properties, its tick and its drawing. A new kind is a
  class here, a word in DynamicKindIds and a branch in CreateDynamic.

  The parent works as in the VCL, for coordinates only: without one an
  object is nailed to a point of its screen; with one, x and y count
  from the parent's top-left corner and the object shows wherever the
  parent does. The parent is named by tag - a static object or a
  monster; finding it is the business of Render.Dynamics.

  Intensity is the one property the level's events may change while it
  runs: an event names the tag and the new level, and the object fades
  there.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Levels.Dynamics;
{$I ..\Moon2D.inc}

interface

uses
  System.SysUtils, System.JSON, System.Generics.Collections, Sdl2.Core,
  Render.Brush, Render.Puff, Effects.Emitter, Levels.Tint;

type
  EDynamicError = class(Exception);

  // What every kind draws with; the renderer makes the textures at
  // level load and frees them with itself, before the level
  TDynamicCanvas = record
    Renderer: PSdlRenderer;
    PointGlow: PSdlTexture;
    FlareGlow: PSdlTexture;
    StarburstGlow: PSdlTexture;
    Puffs: TPuffTextures;
  end;

  // Back: with the static objects, behind the tiles. Front: over the
  // monsters, under the hero.
  TDynamicLayer = (dlBack, dlFront);

  // Shared by every kind. JSON: "screen" or "parent" - one of the two -
  // then "x", "y" and optional "tint", "tag" (the name events use) and
  // "layer" ("back" or "front", back by default).
  TDynamicPlacement = record
    Screen: Integer; // 1-based; 0 under a parent, which decides it
    Parent: string; // a static object's or a monster's tag; '' = nailed
    X, Y: Single; // screen units; from the parent's top-left under one
    Tint: TColorTint;
    Tag: string;
    Layer: TDynamicLayer;
  end;

  // Intensity 0..1 and where the events are taking it
  TIntensityFade = record
    Initial: Single; // as the level file gave it
    Current: Single;
    Target: Single;
    Step: Single; // per tick, toward Target
    procedure Tick;
  end;

  TDynamicObject = class abstract
  private
    FPlacement: TDynamicPlacement;
    FIntensity: TIntensityFade;
    FOrigin: TSdlFPoint;
    FOriginKnown: Boolean;
  protected
    // AMotionX/AMotionY - how far the origin moved since the last tick
    procedure Advance(AMotionX, AMotionY: Single; AParentAlive: Boolean);
      virtual; abstract;
    procedure DrawAt(const ACanvas: TDynamicCanvas; AX, AY: Single;
      AAlpha: Single); virtual; abstract;
    property Intensity: Single read FIntensity.Current;
  public
    // AIntensity 0..1
    constructor Create(const APlacement: TDynamicPlacement;
      AIntensity: Single); overload;
    // JSON: "intensity", a percentage, 100 by default
    constructor Create(const APlacement: TDynamicPlacement;
      AObj: TJSONObject; const AOwner: string); overload;
    // AOriginX/AOriginY - the corner the placement counts from, shake
    // left out. AParentAlive is False while a parent monster is dead or
    // nowhere to be found.
    procedure Tick(AOriginX, AOriginY: Single; AParentAlive: Boolean);
    // Heads for ALevel (0..1) over ATicks; 0 ticks = at once
    procedure FadeTo(ALevel: Single; ATicks: Integer);
    // Back to the intensity of the level file, at once; the next tick
    // starts from wherever the origin is then
    procedure Rewind; virtual;
    // The origin jumps rather than moves: the next tick starts from it
    procedure ForgetOrigin;
    // AOriginX/AOriginY - the corner the placement counts from, shake
    // included. AAlpha is the timestep's, for motion between ticks.
    procedure Draw(const ACanvas: TDynamicCanvas;
      AOriginX, AOriginY: Single; AAlpha: Single);
    property Placement: TDynamicPlacement read FPlacement;
    // Where the last tick counted from, shake left out
    property Origin: TSdlFPoint read FOrigin;
  end;

  TDynamicObjects = class(TObjectList<TDynamicObject>)
  public
    // Every object carrying ATag heads for ALevel (0..1) over ATicks
    procedure FadeTagged(const ATag: string; ALevel: Single; ATicks: Integer);
    procedure RewindTagged(const ATag: string);
    function AnyTagged(const ATag: string): Boolean;
  end;

  TBlinkPattern = (bpSteady, bpPulse, bpFlash, bpDouble, bpFaulty, bpDying);

  // A signal lamp: a hot core, a colored halo, a spill of light on what
  // is around it, on the peak of a flash a four-spike glint, and if
  // asked a starburst - long thin rays up, down, left and right that
  // stretch with the flash. The tint is the color of the light.
  // Frequency is in blinks per second; glint and rayIntensity are
  // percentages; size is the halo across and rays the reach of a ray
  // from the center, in screen units (0 = no starburst).
  // JSON:
  //   {"kind": "beacon", "parent": "ship", "x": 16.1, "y": 1.2,
  //    "tint": [25, 55, 100], "blink": "double", "frequency": 0.75,
  //    "intensity": 100, "size": 14, "glint": 50,
  //    "rays": 36, "rayIntensity": 70}
  TBeacon = class(TDynamicObject)
  private
    FBlink: TBlinkPattern;
    FFrequency: Single;
    FSize: Single;
    FGlint: Single; // 0..1
    FRays: Single;
    FRayIntensity: Single; // 0..1
    FSeed: Cardinal;
    FTicks: Integer;
    function BlinkLevel(AAlpha: Single): Single;
  protected
    procedure Advance(AMotionX, AMotionY: Single;
      AParentAlive: Boolean); override;
    procedure DrawAt(const ACanvas: TDynamicCanvas; AX, AY: Single;
      AAlpha: Single); override;
  public
    constructor Create(const APlacement: TDynamicPlacement;
      AObj: TJSONObject; const AOwner: string);
  end;

  // Steady - an even stream; gusty - the stream swells and sags;
  // puffs - separate clouds, frequency a second
  TSmokeFlow = (sfSteady, sfGusty, sfPuffs);

  // A smoke's look in the words of level JSON - seconds, units a
  // second, degrees - with the percentages as shares, 0..1
  TSmokeLook = record
    Rate, Life, Size, EndSize, Opacity: Single;
    Angle, Cone, Speed, Drag, Lift, Wind, Turbulence, Spin: Single;
    Flow: TSmokeFlow;
    Frequency, Heat: Single;
    EndTint: TColorTint;
  end;

  // Smoke, gas, steam: ragged puffs born at the point, thrown out along
  // the angle within the cone, growing and fading as they go. Once out,
  // a puff stays where it is on the screen - a moving parent leaves a
  // trail. The tint is the color at birth, endTint at death. Heat makes
  // a fresh puff glow with fire and cool to the tint.
  // Units: rate in puffs a second, life in seconds, size and endSize in
  // screen units across, speed in units a second, lift and wind in
  // units a second per second, spin in degrees a second, frequency in
  // gusts or puffs a second. Turbulence is the swirl's speed in units a
  // second; an older puff lets more of it into its own speed every
  // tick. Angle is in degrees counterclockwise from the right (90 =
  // up), cone its full width. Opacity, drag (speed lost per second) and
  // heat are percentages. Intensity scales the rate and, softer, the
  // density.
  // JSON:
  //   {"kind": "smoke", "parent": "satellite", "x": 36.9, "y": 31.2,
  //    "tint": [88, 92, 100], "endTint": [66, 70, 78], "rate": 26,
  //    "life": 2.2, "size": 2.5, "endSize": 24, "opacity": 38,
  //    "angle": -15, "cone": 32, "speed": 26, "drag": 8, "lift": 0,
  //    "wind": 0, "turbulence": 1, "spin": 40, "flow": "gusty",
  //    "frequency": 0.8, "heat": 0}
  TSmoke = class(TDynamicObject)
  private
    FRate: Single; // puffs per tick at full intensity
    FLife: Single; // ticks
    FSize, FEndSize: Single;
    FOpacity: Single; // 0..1
    FAngle, FCone: Single; // radians
    FSpeed: Single; // units per tick
    FDrag: Single; // speed kept per tick
    FLift, FWind: Single; // units per tick per tick
    FTurbulence: Single; // units per tick
    FSpin: Single; // degrees per tick
    FFlow: TSmokeFlow;
    FFrequency: Single; // per tick
    FHeat: Single; // 0..1
    FEndTint: TColorTint;
    FSwarm: TParticleSwarm;
    FRandom: TXorShift;
    FSeed: Cardinal;
    FOwed: Single; // puffs due but not yet born
    FTicks: Integer;
    function FlowLevel: Single;
    procedure Emit(AMotionX, AMotionY: Single);
    procedure Spawn(AMotionX, AMotionY: Single);
    procedure Stir;
    procedure DrawPuffOf(const ACanvas: TDynamicCanvas; AX, AY: Single;
      AAlpha: Single; const AParticle: TParticle);
    procedure TakeLook(const ALook: TSmokeLook; ASeed: Cardinal);
  protected
    procedure Advance(AMotionX, AMotionY: Single;
      AParentAlive: Boolean); override;
    procedure DrawAt(const ACanvas: TDynamicCanvas; AX, AY: Single;
      AAlpha: Single); override;
  public
    constructor Create(const APlacement: TDynamicPlacement;
      AObj: TJSONObject; const AOwner: string);
    // A smoke the game makes itself, not the level file. ASeed sets the
    // puffs' dice: smokes seeded alike puff alike.
    constructor CreateLook(const APlacement: TDynamicPlacement;
      const ALook: TSmokeLook; AIntensity: Single; ASeed: Cardinal);
    destructor Destroy; override;
    // What was in the air goes too: the world restarts in full
    procedure Rewind; override;
  end;

// Reads the "dynamics" array of a level; an absent section is an empty
// list. The caller owns the result. ALevelId names the level in errors.
function ParseDynamics(ARoot: TJSONObject;
  const ALevelId: string): TDynamicObjects;

implementation

uses
  System.Math, Render.Sprites, Render.Glow;

type
  TDynamicKind = (dkBeacon, dkSmoke);

const
  // The JSON vocabulary of "kind", "layer", "blink" and "flow"
  DynamicKindIds: array [TDynamicKind] of string = ('beacon', 'smoke');
  DynamicLayerIds: array [TDynamicLayer] of string = ('back', 'front');
  BlinkPatternIds: array [TBlinkPattern] of string = (
    'steady', 'pulse', 'flash', 'double', 'faulty', 'dying');
  SmokeFlowIds: array [TSmokeFlow] of string = ('steady', 'gusty', 'puffs');

  // Seconds and percentages in JSON, ticks and shares in the code; the
  // logic runs 33 ticks a second (tickRate of Game.Config)
  LogicTicksPerSecond = 33;

resourcestring
  SDynamicBadKind = 'Level "%s": dynamic object #%d: unknown kind "%s"';
  SDynamicKindUnbuilt = 'Dynamic kind "%s" has no constructor';
  SDynamicNoPlace = 'Level "%s": %s names neither a screen nor a parent';
  SDynamicTwoPlaces = 'Level "%s": %s names both a screen and a parent - '
    + 'the parent decides the screen';
  SDynamicBadWord = '%s: unknown %s "%s"';
  SDynamicBadNumber = '%s: "%s" must be above zero';
  SDynamicBadPercent = '%s: "%s" takes a percentage, 0..100';
  SDynamicBadReach = '%s: "%s" cannot be below zero';

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

  SeedPrecision = 10;

  DefaultFrequency = 1.0;
  DefaultBeaconSize = 12.0;
  DefaultRayIntensity = 60;

  // Smoke: every puff differs from the pattern by up to these shares
  SpawnJitter = 0.25; // of the birth size, around the point
  SpeedJitter = 0.35;
  LifeJitter = 0.25;
  PuffJitter = 0.4; // of the puffs in one cloud
  ScaleMin = 0.75;
  ScaleMax = 1.25;
  // Density over a life: in over the first share, then out along a
  // curve that follows the growth - the same gas over a wider cloud
  FadeInShare = 0.08;
  // Typed: Power has three overloads
  FadeOutPower: Single = 1.6;
  // A hot puff cools to the tint over this share of its life
  HeatShare = 0.3;
  HeatGlowScale = 0.9;
  HeatGlowLevel = 0.8;
  FireColor: TRgb = (R: 255; G: 150; B: 60);
  // A gust never quite dies away
  GustFloor = 0.15;
  // Swirl: a flow field of two waves drifting through each other, in
  // radians per unit and per tick. A fresh puff flies straight; the
  // swirl takes an old one, up to TurbulenceGrip of its speed a tick.
  SwirlWave = 0.09;
  SwirlRipple = 0.23;
  SwirlRippleShare = 0.5;
  SwirlTempo = 0.035;
  TurbulenceGrip = 0.12;
  // Below this a puff would draw as nothing
  VisibleLevel = 1 / 255;

  DefaultRate = 20;
  DefaultLife = 2.0;
  DefaultSmokeSize = 4.0;
  EndSizeFactor = 4;
  DefaultOpacity = 50;
  DefaultAngle = 90;
  DefaultCone = 30;
  DefaultSpeed = 10;
  DefaultDrag = 30;
  DefaultTurbulence = 3;
  // A share kept per second becomes a share kept per tick
  TickExponent: Single = 1 / LogicTicksPerSecond;
  DefaultSpin = 30;

function TintColor(const ATint: TColorTint): TRgb;
begin
  Result.R := PercentToColorMod(ATint.R);
  Result.G := PercentToColorMod(ATint.G);
  Result.B := PercentToColorMod(ATint.B);
end;

// Objects at different points go out of step: the seed is the position
// in tenths of a unit, x in the high half
function PlacementSeed(const APlacement: TDynamicPlacement): Cardinal;
begin
  Result := (Cardinal(Round(APlacement.X * SeedPrecision)) shl 16) xor
    Cardinal(Round(APlacement.Y * SeedPrecision));
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

// ---------------------------------------------------------------------------
// Reading
// ---------------------------------------------------------------------------

function ReadPositive(AObj: TJSONObject; const AKey: string;
  ADefault: Single; const AOwner: string): Single;
begin
  Result := AObj.GetValue<Double>(AKey, ADefault);
  if Result <= 0 then
    raise EDynamicError.CreateFmt(SDynamicBadNumber, [AOwner, AKey]);
end;

// A length or a rate where zero means "none"
function ReadReach(AObj: TJSONObject; const AKey: string;
  ADefault: Single; const AOwner: string): Single;
begin
  Result := AObj.GetValue<Double>(AKey, ADefault);
  if Result < 0 then
    raise EDynamicError.CreateFmt(SDynamicBadReach, [AOwner, AKey]);
end;

// A percentage in JSON, a share in the code
function ReadShare(AObj: TJSONObject; const AKey: string;
  ADefault: Integer; const AOwner: string): Single;
begin
  var Percent := AObj.GetValue<Integer>(AKey, ADefault);
  if (Percent < 0) or (Percent > 100) then
    raise EDynamicError.CreateFmt(SDynamicBadPercent, [AOwner, AKey]);
  Result := Percent / 100;
end;

// One of AIds, spelled in any case; AWhat names the field in errors.
// The index of the word found.
function ReadWord(AObj: TJSONObject; const AKey, ADefault: string;
  const AIds: array of string; const AWhat, AOwner: string): Integer;
begin
  var Id := AObj.GetValue<string>(AKey, ADefault);
  for var i := 0 to High(AIds) do
    if SameText(Id, AIds[i]) then
      Exit(i);
  raise EDynamicError.CreateFmt(SDynamicBadWord, [AOwner, AWhat, Id]);
end;

// ---------------------------------------------------------------------------
// TIntensityFade
// ---------------------------------------------------------------------------

procedure TIntensityFade.Tick;
begin
  if Current < Target then
  begin
    Current := Current + Step;
    if Current > Target then
      Current := Target;
  end
  else if Current > Target then
  begin
    Current := Current - Step;
    if Current < Target then
      Current := Target;
  end;
end;

// ---------------------------------------------------------------------------
// TDynamicObject
// ---------------------------------------------------------------------------

constructor TDynamicObject.Create(const APlacement: TDynamicPlacement;
  AIntensity: Single);
begin
  inherited Create;
  FPlacement := APlacement;
  FIntensity.Initial := AIntensity;
  FIntensity.Current := AIntensity;
  FIntensity.Target := AIntensity;
end;

constructor TDynamicObject.Create(const APlacement: TDynamicPlacement;
  AObj: TJSONObject; const AOwner: string);
begin
  Create(APlacement, ReadShare(AObj, 'intensity', 100, AOwner));
end;

procedure TDynamicObject.Tick(AOriginX, AOriginY: Single;
  AParentAlive: Boolean);
begin
  var MotionX: Single := 0;
  var MotionY: Single := 0;
  if FOriginKnown then
  begin
    MotionX := AOriginX - FOrigin.X;
    MotionY := AOriginY - FOrigin.Y;
  end;
  FOrigin.X := AOriginX;
  FOrigin.Y := AOriginY;
  FOriginKnown := True;

  FIntensity.Tick;
  Advance(MotionX, MotionY, AParentAlive);
end;

procedure TDynamicObject.FadeTo(ALevel: Single; ATicks: Integer);
begin
  FIntensity.Target := ALevel;
  if ATicks <= 0 then
  begin
    FIntensity.Current := ALevel;
    Exit;
  end;
  FIntensity.Step := Abs(ALevel - FIntensity.Current) / ATicks;
end;

procedure TDynamicObject.Rewind;
begin
  FIntensity.Current := FIntensity.Initial;
  FIntensity.Target := FIntensity.Initial;
  FIntensity.Step := 0;
  ForgetOrigin;
end;

procedure TDynamicObject.ForgetOrigin;
begin
  FOriginKnown := False;
end;

procedure TDynamicObject.Draw(const ACanvas: TDynamicCanvas;
  AOriginX, AOriginY: Single; AAlpha: Single);
begin
  DrawAt(ACanvas, AOriginX + FPlacement.X, AOriginY + FPlacement.Y, AAlpha);
end;

// ---------------------------------------------------------------------------
// TDynamicObjects
// ---------------------------------------------------------------------------

procedure TDynamicObjects.FadeTagged(const ATag: string; ALevel: Single;
  ATicks: Integer);
begin
  for var DynamicObject in Self do
    if DynamicObject.Placement.Tag = ATag then
      DynamicObject.FadeTo(ALevel, ATicks);
end;

procedure TDynamicObjects.RewindTagged(const ATag: string);
begin
  for var DynamicObject in Self do
    if DynamicObject.Placement.Tag = ATag then
      DynamicObject.Rewind;
end;

function TDynamicObjects.AnyTagged(const ATag: string): Boolean;
begin
  for var DynamicObject in Self do
    if DynamicObject.Placement.Tag = ATag then
      Exit(True);
  Result := False;
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

constructor TBeacon.Create(const APlacement: TDynamicPlacement;
  AObj: TJSONObject; const AOwner: string);
begin
  inherited Create(APlacement, AObj, AOwner);
  FBlink := TBlinkPattern(ReadWord(AObj, 'blink', BlinkPatternIds[bpFlash],
    BlinkPatternIds, 'blink', AOwner));
  FFrequency := ReadPositive(AObj, 'frequency', DefaultFrequency, AOwner);
  FSize := ReadPositive(AObj, 'size', DefaultBeaconSize, AOwner);
  FGlint := ReadShare(AObj, 'glint', 0, AOwner);
  FRays := ReadReach(AObj, 'rays', 0, AOwner);
  FRayIntensity := ReadShare(AObj, 'rayIntensity', DefaultRayIntensity,
    AOwner);
  FSeed := PlacementSeed(APlacement);
end;

procedure TBeacon.Advance(AMotionX, AMotionY: Single; AParentAlive: Boolean);
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
    Color, Intensity * SpillLevel * Flash);
  DrawGlow(ACanvas.Renderer, ACanvas.PointGlow, AX, AY, FSize,
    Color, Intensity * Lit);
  DrawGlow(ACanvas.Renderer, ACanvas.PointGlow, AX, AY, FSize * CoreScale,
    Mix(Color, White, CoreWhiteness), Intensity * Lit);
  if FGlint > 0 then
    DrawGlow(ACanvas.Renderer, ACanvas.FlareGlow, AX, AY,
      FSize * GlintScale, Color, Intensity * FGlint * Flash * Flash * Flash);
  if FRays > 0 then
  begin
    var Reach := FRays * (RayRestReach + (1 - RayRestReach) * Flash);
    DrawGlow(ACanvas.Renderer, ACanvas.StarburstGlow, AX, AY, 2 * Reach,
      Color, Intensity * FRayIntensity * Flash);
  end;
end;

// ---------------------------------------------------------------------------
// TSmoke
// ---------------------------------------------------------------------------

function Lerp(AFrom, ATo, AAmount: Single): Single;
begin
  Result := AFrom + (ATo - AFrom) * AAmount;
end;

// ATint is the placement's: the end tint follows it unless named
function ReadSmokeLook(AObj: TJSONObject; const ATint: TColorTint;
  const AOwner: string): TSmokeLook;
begin
  Result.Rate := ReadPositive(AObj, 'rate', DefaultRate, AOwner);
  Result.Life := ReadPositive(AObj, 'life', DefaultLife, AOwner);
  Result.Size := ReadPositive(AObj, 'size', DefaultSmokeSize, AOwner);
  Result.EndSize := ReadReach(AObj, 'endSize', Result.Size * EndSizeFactor,
    AOwner);
  Result.Opacity := ReadShare(AObj, 'opacity', DefaultOpacity, AOwner);
  Result.Angle := AObj.GetValue<Double>('angle', DefaultAngle);
  Result.Cone := ReadReach(AObj, 'cone', DefaultCone, AOwner);
  Result.Speed := ReadReach(AObj, 'speed', DefaultSpeed, AOwner);
  Result.Drag := ReadShare(AObj, 'drag', DefaultDrag, AOwner);
  Result.Lift := AObj.GetValue<Double>('lift', 0);
  Result.Wind := AObj.GetValue<Double>('wind', 0);
  Result.Turbulence := ReadReach(AObj, 'turbulence', DefaultTurbulence,
    AOwner);
  Result.Spin := ReadReach(AObj, 'spin', DefaultSpin, AOwner);
  Result.Flow := TSmokeFlow(ReadWord(AObj, 'flow', SmokeFlowIds[sfSteady],
    SmokeFlowIds, 'flow', AOwner));
  Result.Frequency := ReadPositive(AObj, 'frequency', DefaultFrequency,
    AOwner);
  Result.Heat := ReadShare(AObj, 'heat', 0, AOwner);
  if AObj.GetValue('endTint') = nil then
    Result.EndTint := ATint
  else
    Result.EndTint := ReadTint(AObj, AOwner, 'endTint');
end;

constructor TSmoke.Create(const APlacement: TDynamicPlacement;
  AObj: TJSONObject; const AOwner: string);
begin
  inherited Create(APlacement, AObj, AOwner);
  TakeLook(ReadSmokeLook(AObj, APlacement.Tint, AOwner),
    PlacementSeed(APlacement));
end;

constructor TSmoke.CreateLook(const APlacement: TDynamicPlacement;
  const ALook: TSmokeLook; AIntensity: Single; ASeed: Cardinal);
begin
  inherited Create(APlacement, AIntensity);
  TakeLook(ALook, ASeed);
end;

// Seconds and shares in, ticks out
procedure TSmoke.TakeLook(const ALook: TSmokeLook; ASeed: Cardinal);
begin
  FRate := ALook.Rate / LogicTicksPerSecond;
  FLife := ALook.Life * LogicTicksPerSecond;
  FSize := ALook.Size;
  FEndSize := ALook.EndSize;
  FOpacity := ALook.Opacity;
  FAngle := DegToRad(ALook.Angle);
  FCone := DegToRad(ALook.Cone);
  FSpeed := ALook.Speed / LogicTicksPerSecond;
  var Kept: Single := 1 - ALook.Drag;
  FDrag := Power(Kept, TickExponent);
  FLift := ALook.Lift / Sqr(LogicTicksPerSecond);
  FWind := ALook.Wind / Sqr(LogicTicksPerSecond);
  FTurbulence := ALook.Turbulence / LogicTicksPerSecond;
  FSpin := ALook.Spin / LogicTicksPerSecond;
  FFlow := ALook.Flow;
  FFrequency := ALook.Frequency / LogicTicksPerSecond;
  FHeat := ALook.Heat;
  FEndTint := ALook.EndTint;

  FSeed := ASeed;
  FRandom.Seed := FSeed or 1;
  FSwarm := TParticleSwarm.Create;
end;

destructor TSmoke.Destroy;
begin
  FSwarm.Free;
  inherited;
end;

procedure TSmoke.Rewind;
begin
  inherited;
  FSwarm.Clear;
  FOwed := 0;
end;

// The rate multiplier of this tick for the continuous flows: a gust is
// value noise over time, its knots FFrequency apart, averaging 1
function TSmoke.FlowLevel: Single;
begin
  if FFlow <> sfGusty then
    Exit(1);
  var Knots: Double := FTicks * FFrequency;
  var Knot: Integer := Trunc(Knots);
  var Along: Single := Knots - Knot;
  Along := Along * Along * (3 - 2 * Along);
  var Noise := Lerp(SlotRoll(Knot, FSeed), SlotRoll(Knot + 1, FSeed), Along);
  Result := GustFloor + (2 - 2 * GustFloor) * Noise;
end;

procedure TSmoke.Emit(AMotionX, AMotionY: Single);
begin
  if FFlow = sfPuffs then
  begin
    var PuffNow := Trunc(FTicks * FFrequency) <> Trunc((FTicks - 1) * FFrequency);
    if PuffNow then
      FOwed := FOwed + FRate / FFrequency * Intensity *
        (1 - PuffJitter + 2 * PuffJitter * FRandom.NextUnit);
  end
  else
    FOwed := FOwed + FRate * Intensity * FlowLevel;

  while FOwed >= 1 do
  begin
    Spawn(AMotionX, AMotionY);
    FOwed := FOwed - 1;
  end;
end;

// Born somewhere on the stretch the point covered this tick - a fast
// parent leaves a trail, not a string of beads
procedure TSmoke.Spawn(AMotionX, AMotionY: Single);
var
  Particle: TParticle;
begin
  var Behind := FRandom.NextUnit;
  var Heading: Single := FAngle + (FRandom.NextUnit - 0.5) * FCone;
  var Speed: Single := FSpeed *
    (1 - SpeedJitter + 2 * SpeedJitter * FRandom.NextUnit);
  Particle.X := (2 * FRandom.NextUnit - 1) * FSize * SpawnJitter -
    AMotionX * Behind;
  Particle.Y := (2 * FRandom.NextUnit - 1) * FSize * SpawnJitter -
    AMotionY * Behind;
  // Counterclockwise on paper, and the screen's Y runs down
  Particle.SpeedX := Cos(Heading) * Speed;
  Particle.SpeedY := -Sin(Heading) * Speed;
  Particle.Angle := 360 * FRandom.NextUnit;
  Particle.Spin := (2 * FRandom.NextUnit - 1) * FSpin;
  Particle.Age := 0;
  Particle.Life := Max(1, Round(FLife *
    (1 - LifeJitter + 2 * LifeJitter * FRandom.NextUnit)));
  Particle.Shape := Min(PuffShapes - 1, Trunc(FRandom.NextUnit * PuffShapes));
  Particle.Scale := Lerp(ScaleMin, ScaleMax, FRandom.NextUnit);
  Particle.Weight := Sqrt(Intensity);
  FSwarm.Add(Particle);
end;

// The swirl comes from a stream function - two drifting waves,
// psi = sin(kx + t) cos(ky - 0.7t) and a finer ripple of the same shape;
// speed = (dpsi/dy, -dpsi/dx) curls without gathering or tearing the
// smoke
procedure TSmoke.Stir;
begin
  var Time: Single := FTicks * SwirlTempo;
  for var i := 0 to FSwarm.Count - 1 do
  begin
    var Particle := FSwarm[i];
    var WaveX := SwirlWave * Particle.X + Time;
    var WaveY := SwirlWave * Particle.Y - 0.7 * Time;
    var RippleX := SwirlRipple * Particle.X - 1.3 * Time;
    var RippleY := SwirlRipple * Particle.Y + Time;
    var FlowX: Single := -Sin(WaveX) * Sin(WaveY) -
      SwirlRippleShare * Sin(RippleX) * Sin(RippleY);
    var FlowY: Single := -Cos(WaveX) * Cos(WaveY) -
      SwirlRippleShare * Cos(RippleX) * Cos(RippleY);
    var Grip := TurbulenceGrip * Particle.Age / Particle.Life;
    Particle.SpeedX := Particle.SpeedX + FlowX * FTurbulence * Grip;
    Particle.SpeedY := Particle.SpeedY + FlowY * FTurbulence * Grip;
  end;
end;

procedure TSmoke.Advance(AMotionX, AMotionY: Single; AParentAlive: Boolean);
begin
  Inc(FTicks);
  FSwarm.ShiftFrame(AMotionX, AMotionY);
  if AParentAlive and (Intensity > 0) then
    Emit(AMotionX, AMotionY);
  if FTurbulence > 0 then
    Stir;
  FSwarm.Advance(FDrag, FWind, -FLift);
end;

procedure TSmoke.DrawPuffOf(const ACanvas: TDynamicCanvas; AX, AY: Single;
  AAlpha: Single; const AParticle: TParticle);
begin
  var Share: Single := (AParticle.Age + AAlpha) / AParticle.Life;
  if Share > 1 then
    Share := 1;
  var FadeIn: Single := Share / FadeInShare;
  if FadeIn > 1 then
    FadeIn := 1;
  var Remaining: Single := 1 - Share;
  var Level: Single := FOpacity * AParticle.Weight * FadeIn *
    Power(Remaining, FadeOutPower);
  if Level < VisibleLevel then
    Exit;

  var Growth := 1 - Sqr(1 - Share);
  var Size := Lerp(FSize, FEndSize, Growth) * AParticle.Scale;
  var CenterX := AX + AParticle.X + AParticle.SpeedX * AAlpha;
  var CenterY := AY + AParticle.Y + AParticle.SpeedY * AAlpha;
  var Color := Mix(TintColor(Placement.Tint), TintColor(FEndTint), Share);
  var Glow: Single := 0;
  if Share < HeatShare then
    Glow := FHeat * (1 - Share / HeatShare);

  DrawPuff(ACanvas.Renderer, ACanvas.Puffs[AParticle.Shape], CenterX, CenterY,
    Size, AParticle.Angle + AParticle.Spin * AAlpha, Mix(Color, FireColor, Glow),
    Level);
  if Glow > 0 then
    DrawGlow(ACanvas.Renderer, ACanvas.PointGlow, CenterX, CenterY,
      Size * HeatGlowScale, FireColor, Glow * HeatGlowLevel * AParticle.Weight);
end;

procedure TSmoke.DrawAt(const ACanvas: TDynamicCanvas; AX, AY: Single;
  AAlpha: Single);
begin
  for var i := 0 to FSwarm.Count - 1 do
    DrawPuffOf(ACanvas, AX, AY, AAlpha, FSwarm[i]^);
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
  Result.Tag := AObj.GetValue<string>('tag', '');
  Result.Layer := TDynamicLayer(ReadWord(AObj, 'layer',
    DynamicLayerIds[dlBack], DynamicLayerIds, 'layer', AOwner));
end;

function CreateDynamic(AKind: TDynamicKind;
  const APlacement: TDynamicPlacement; AObj: TJSONObject;
  const AOwner: string): TDynamicObject;
begin
  case AKind of
    dkBeacon:
      Result := TBeacon.Create(APlacement, AObj, AOwner);
    dkSmoke:
      Result := TSmoke.Create(APlacement, AObj, AOwner);
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
