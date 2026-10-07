{
  Levels.Dynamics - the dynamic objects of a level, the "dynamics"
  section of level JSON: things placed like the static objects of
  Levels.Defs, but alive - they change from tick to tick.

  Every kind descends from TDynamicObject and lives in this unit. The
  ancestor holds and reads what every kind shares - where it stands,
  its tint, its parent, its tag, its layer and its intensity; a kind
  adds its own properties, its tick and its drawing. A new kind is a
  class here, a word in DynamicKindIds, its layer in DefaultLayers and
  a branch in CreateDynamic.

  The parent works as in the VCL, for coordinates only: without one an
  object is nailed to a point of its screen; with one, x and y count
  from the parent's top-left corner and the object shows wherever the
  parent does. The parent is named by tag - a static object, a pad or a
  monster; finding it is the business of Render.Dynamics.

  A rig a pad wears (Levels.Rigs) is made of the same objects:
  ParseDynamic reads one wherever it is written.

  Intensity is the property the level's events change in every kind:
  an event names the tag and the new level, and the object fades there.
  The sun of a globe turns the same way. A parent that works hard - a
  pad flying, or about to leave its place - lifts the intensity of what
  hangs on it toward full, as far as the object's surge says: jets
  flare.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Levels.Dynamics;
{$I ..\Moon2D.inc}

interface

uses
  System.SysUtils, System.JSON, System.Generics.Collections, Sdl2.Core,
  Render.Sprites, Render.Brush, Render.Puff, Render.Globe, Effects.Emitter,
  Effects.Sparks, Effects.Lightning, Levels.Tint;

type
  EDynamicError = class(Exception);

  // The backdrop of the screen being drawn, for a kind that bends it:
  // the picture, its tint and the screen units it is stretched over.
  // Texture nil - the screen has none.
  TBackdropView = record
    Texture: PSdlTexture;
    Tint: TColorTint;
    Width, Height: Single;
  end;

  // What every kind draws with; the renderer makes the textures at
  // level load and frees them with itself, before the level
  TDynamicCanvas = record
    Renderer: PSdlRenderer;
    PointGlow: PSdlTexture;
    FlareGlow: PSdlTexture;
    StarburstGlow: PSdlTexture;
    StreakGlow: PSdlTexture;
    BeamGlow: PSdlTexture;
    Puffs: TPuffTextures;
    // In screen units; an object away from the hero's screen meets no
    // walls
    Solid: TSolidProbe;
    // The level's object art: its own set and the shared ones it
    // declares; maps are named as the static objects name sprites
    Art: TSpriteCache;
    // Set by the renderer before it draws the backdrop layer
    Backdrop: TBackdropView;
    // How much of its size and of its light the object being drawn
    // keeps: 1 in front, less under a parent gone into the depth of the
    // screen - a pad in a rebuild. The renderer sets them for every
    // object. The kinds that hang on pads obey them: a beacon, a haze
    // and a smoke.
    Scale: Single;
    Tone: Single;
  end;

  // Backdrop: the backdrop itself, bent - under everything else. Sky:
  // right over the backdrop, standing still while the world shakes - the
  // far things. Back: with the static objects, behind the tiles. Front:
  // over the monsters, under the hero.
  TDynamicLayer = (dlBackdrop, dlSky, dlBack, dlFront);

  // Shared by every kind. JSON: one of "screen", "screens" ([first,
  // last] - the same object on a run of screens) and "parent", then
  // "x", "y" and optional "tint", "tag" (the name events use),
  // "layer" ("backdrop", "sky", "back" or "front"; each kind has its own
  // default) and "turns" (true: the point turns with a parent that spins
  // - a lamp on the boss's disc). Beside the placement every kind reads
  // "intensity" and "surge", percentages (TDynamicObject).
  TDynamicPlacement = record
    Screen: Integer; // 1-based; 0 under a parent, which decides it
    LastScreen: Integer; // = Screen unless "screens" spans a run
    Parent: string; // a static object's, a pad's or a monster's tag; '' = nailed
    X, Y: Single; // screen units; from the parent's top-left under one
    Tint: TColorTint;
    Tag: string;
    Layer: TDynamicLayer;
    Turns: Boolean;
  end;

  // A value and where the events are taking it
  TValueFade = record
    Initial: Single; // as the level file gave it
    Current: Single;
    Target: Single;
    Step: Single; // per tick, toward Target
    // Stands at AValue and stays there
    procedure Settle(AValue: Single);
    // Heads for ATarget over ATicks; 0 ticks = at once
    procedure HeadFor(ATarget: Single; ATicks: Integer);
    procedure Tick;
  end;

  TDynamicObject = class abstract
  private
    FPlacement: TDynamicPlacement;
    FIntensity: TValueFade; // 0..1
    // How far a parent at full effort lifts the intensity toward 1, 0..1;
    // and the parent's effort as the object has come to feel it
    FSurge: Single;
    FEffort: TValueFade;
    FOrigin: TSdlFPoint;
    FOriginKnown: Boolean;
    function GetIntensity: Single;
  protected
    // AMotionX/AMotionY - how far the origin moved since the last tick
    procedure Advance(AMotionX, AMotionY: Single; AParentAlive: Boolean);
      virtual; abstract;
    procedure DrawAt(const ACanvas: TDynamicCanvas; AX, AY: Single;
      AAlpha: Single); virtual; abstract;
    // What the level file and the events have set, lifted by the surge
    // while the parent works
    property Intensity: Single read GetIntensity;
  public
    // AIntensity 0..1
    constructor Create(const APlacement: TDynamicPlacement;
      AIntensity: Single); overload;
    // JSON: "intensity", a percentage, 100 by default; "surge", a
    // percentage of the way from the intensity to full that a parent at
    // full effort lifts the object, 0 by default
    constructor Create(const APlacement: TDynamicPlacement;
      AObj: TJSONObject; const AOwner: string); overload;
    // How hard the parent works now, 0..1 - the game says when a pad
    // does. Told before the tick; the object eases toward it over a few
    // ticks. An object nobody tells stays at rest.
    procedure FollowEffort(AEffort: Single);
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
    // What a kind makes for itself to draw with: made once the canvas
    // is, freed before it is
    procedure Acquire(const ACanvas: TDynamicCanvas); virtual;
    procedure Release; virtual;
    // AOriginX/AOriginY - the corner the placement counts from, shake
    // included. AAlpha is the timestep's, for motion between ticks.
    procedure Draw(const ACanvas: TDynamicCanvas;
      AOriginX, AOriginY: Single; AAlpha: Single);
    property Placement: TDynamicPlacement read FPlacement;
    // Where the last tick counted from, shake left out
    property Origin: TSdlFPoint read FOrigin;
  end;

  TDynamicObjectClass = class of TDynamicObject;

  TDynamicObjects = class(TObjectList<TDynamicObject>)
  public
    // Every object carrying ATag heads for ALevel (0..1) over ATicks
    procedure FadeTagged(const ATag: string; ALevel: Single; ATicks: Integer);
    procedure RewindTagged(const ATag: string);
    // Every globe carrying ATag turns its sun to ADegrees over ATicks
    procedure TurnSunTagged(const ATag: string; ADegrees: Single;
      ATicks: Integer);
    // AKind nil = any kind
    function AnyTagged(const ATag: string;
      AKind: TDynamicObjectClass = nil): Boolean;
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
  // a fresh puff glow and cool to the tint: with fire, or with heatTint
  // when the level names one - the blue of a jet. In the depth (the
  // canvas' Scale and Tone) the whole plume draws in toward its point,
  // smaller and dimmer.
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
  //    "frequency": 0.8, "heat": 0, "heatTint": [45, 75, 100]}
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
    FHeatColor: TRgb;
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
    // The source is off and the last puff is gone
    function Exhausted: Boolean;
  end;

  // A spark source's look in the words of level JSON - seconds, units a
  // second, degrees - with the percentages as shares, 0..1
  TSparkSourceLook = record
    Rate, Burst, Frequency: Single;
    Spell, Pause: Single;
    Life, Speed, Angle, Cone, Gravity, Drag, Size: Single;
    Opacity, Flash, Fork: Single;
    Wall: TSparkWall;
    MidTint, EndTint: TColorTint;
  end;

  TArcClock = record
    Gap: Single; // ticks between arcs, on average
    WaitTicks: Integer; // to the next arc
    TicksLeft: Integer; // of the arc under way
    Pour: Single; // sparks per tick of it
  end;

  // A source with a pause works in spells and is out between them. The
  // zeroed clock is on the edge of a spell: a fresh source, or one
  // rewound, opens with it.
  TRestClock = record
    Spell, Pause: Single; // ticks, on average; no pause - no rest
    TicksLeft: Integer; // of the spell or the pause under way
    Awake: Boolean;
    // One tick; True on the tick a spell opens. ADice is the owner's.
    function Tick(var ADice: TXorShift): Boolean;
  end;

  // Sparks from torn metal and bare wires (Effects.Sparks): a steady
  // fall of them and, now and then, an arc - a handful at once under a
  // cold flash of light. Once out, a spark stays where it is on the
  // screen - a moving parent leaves a trail. The tint is the color of a
  // fresh spark; it cools through midTint to endTint.
  // Units: rate in sparks a second, burst in sparks an arc (0 = no
  // arcs), frequency in arcs a second, their gaps uneven, life in
  // seconds, speed in units a second - the fastest spark, most are
  // slower - gravity in units a second per second, size the streak
  // across in screen units. Angle is in degrees counterclockwise from
  // the right (-90 = down), cone its full width. Drag (speed lost per
  // second), opacity, flash (the light of an arc) and fork (the chance
  // of a spark to split) are percentages. Collide is what the solid
  // layer does to a spark: "none", "die" or "bounce" - bounce in the
  // front layer by default, none behind it. Intensity scales the rate
  // and, softer, how often and how hard it arcs. Spell and pause are in
  // seconds, both rough: a source with a pause (0 = none) pours for a
  // spell, goes out for a pause, and comes back with an arc.
  // JSON:
  //   {"kind": "sparks", "parent": "satellite", "x": 33.5, "y": 36,
  //    "tint": [100, 96, 86], "midTint": [100, 66, 27],
  //    "endTint": [69, 14, 6], "rate": 12, "burst": 7, "frequency": 0.5,
  //    "life": 2.6, "speed": 46, "angle": -90, "cone": 70, "gravity": 42,
  //    "drag": 50, "size": 1.6, "opacity": 90, "flash": 45, "fork": 18,
  //    "spell": 7, "pause": 3, "collide": "none"}
  TSparks = class(TDynamicObject)
  private
    FRate: Single; // sparks per tick at full intensity
    FBurst: Single; // sparks in an arc of the usual size
    FArc: TArcClock;
    FRest: TRestClock;
    FSpray: TSparkSpray; // one spark
    FSize: Single;
    FFlashPeak: Single; // 0..1
    FFlash: Single; // 0..1 of the peak: the light of the last arc
    FField: TSparkField;
    FSolid: TSolidProbe;
    FPoint: TSdlFPoint; // where the sparks leave, in screen units
    FRandom: TXorShift;
    FOwed: Single; // sparks due but not yet born
    function Blocked(AX, AY: Single): Boolean;
    function FieldLook(const ALook: TSparkSourceLook): TSparkLook;
    procedure TakeLook(const ALook: TSparkSourceLook; ASeed: Cardinal);
    procedure Emit;
    procedure StartArc;
    procedure ThrowOne;
  protected
    procedure Advance(AMotionX, AMotionY: Single;
      AParentAlive: Boolean); override;
    procedure DrawAt(const ACanvas: TDynamicCanvas; AX, AY: Single;
      AAlpha: Single); override;
  public
    constructor Create(const APlacement: TDynamicPlacement;
      AObj: TJSONObject; const AOwner: string);
    // Sparks the game makes itself, not the level file. ASeed sets their
    // dice: sources seeded alike arc alike.
    constructor CreateLook(const APlacement: TDynamicPlacement;
      const ALook: TSparkSourceLook; AIntensity: Single; ASeed: Cardinal);
    destructor Destroy; override;
    procedure Acquire(const ACanvas: TDynamicCanvas); override;
    // What was in the air goes too: the world restarts in full
    procedure Rewind; override;
    // For sparks the game makes: a level's take the solid layer from the
    // canvas
    procedure UseSolid(const ASolid: TSolidProbe);
  end;

  // What a bolt does at its far end: none - it spans the two points; strike
  // - it looks for matter along its way
  TLightningCollide = (lcNone, lcStrike);

  // A lightning source's look in the words of level JSON - seconds, units,
  // degrees - with the percentages as shares, 0..1
  TLightningLook = record
    Reach: Single;
    Spread: TSdlFPoint; // half-sizes of the box the root rolls in
    Angle, Cone: Single;
    Collide: TLightningCollide;
    Size, Jag, Fork: Single;
    Frequency: Single;
    Strokes: Integer;
    Life, Leader: Single;
    Spell, Pause: Single;
    Flash, Jolt: Single;
    Tint: TColorTint;
  end;

  // Lightning (Effects.Lightning): now and then a crooked bolt of light
  // strikes within reach of the point, throws branches and fades - a short
  // in a panel, a wire gone live. Pure decoration: a bolt wounds nobody.
  // The root rolls in a box around the point, the bolt leaves it along the
  // angle within the cone, and is 55-100% of reach long. Collide "none"
  // spans the two points and lights both; "strike" marches along the way
  // through the solid layer and ends where it finds matter, with a flash
  // and a light over the whole room, or, finding none, goes out as a short
  // streamer - strike in the front layer by default, none behind it. The
  // tint is the color of the halo: the core is always white.
  // Units: reach, spread (half-sizes, x and y) and size (the channel's
  // width, 1 = the standard) in screen units, frequency in bolts a second,
  // their gaps uneven, life (the glow of a stroke) and leader (the dim
  // feeler before the first stroke, 0 = none) in seconds, spell and pause
  // as for sparks. Angle is in degrees counterclockwise from the right
  // (-90 = down), cone its full width. Jag (the crookedness, a share of the
  // bolt's length), fork (the chance of a branch), flash (the light) and
  // jolt (the shake of the screen a stroke gives) are percentages. Strokes
  // is how many times one bolt strikes along the same channel. Intensity
  // scales the frequency, the length, the width and the strokes; at zero
  // the source is silent.
  // JSON:
  //   {"kind": "lightning", "parent": "s10-house-b", "x": 42, "y": 194,
  //    "tint": [66, 74, 100], "reach": 30, "spread": [9, 14],
  //    "angle": 90, "cone": 360, "collide": "none", "size": 0.8,
  //    "jag": 24, "fork": 12, "frequency": 1.6, "strokes": 2,
  //    "life": 0.1, "leader": 0, "spell": 1.5, "pause": 3.5,
  //    "flash": 45, "jolt": 0}
  TLightning = class(TDynamicObject)
  private
    FLook: TLightningLook;
    FBolt: TBoltLook; // as the source shoots at full intensity
    FField: TBoltField;
    FRest: TRestClock;
    FSolid: TSolidProbe;
    FPoint: TSdlFPoint; // where the field's zero stands, in screen units
    FRandom: TXorShift;
    FGap: Single; // ticks between bolts, on average
    FWait: Single; // of the full intensity's ticks, to the next bolt
    function Blocked(AX, AY: Single): Boolean;
    function FindMatter(AX, AY, AHeadX, AHeadY, AReach: Single;
      out ADistance: Single): Boolean;
    function BoltLook: TBoltLook;
    procedure TakeLook(const ALook: TLightningLook; ASeed: Cardinal);
    procedure Emit;
    procedure Discharge;
  protected
    procedure Advance(AMotionX, AMotionY: Single;
      AParentAlive: Boolean); override;
    procedure DrawAt(const ACanvas: TDynamicCanvas; AX, AY: Single;
      AAlpha: Single); override;
  public
    constructor Create(const APlacement: TDynamicPlacement;
      AObj: TJSONObject; const AOwner: string);
    // Lightning the game makes itself, not the level file. ASeed sets the
    // dice: sources seeded alike strike alike.
    constructor CreateLook(const APlacement: TDynamicPlacement;
      const ALook: TLightningLook; AIntensity: Single; ASeed: Cardinal);
    destructor Destroy; override;
    procedure Acquire(const ACanvas: TDynamicCanvas); override;
    // What was in the air goes too: the world restarts in full
    procedure Rewind; override;
    // For lightning the game makes: a level's takes the solid layer from
    // the canvas
    procedure UseSolid(const ASolid: TSolidProbe);
  end;

  // A body in the sky - the Earth over the Moon unless the level says
  // otherwise (the dead Earth of Selene, Proxima c): a globe
  // (Render.Globe) under a sun the level moves. The sun travels the arc of the sky over the
  // screen: 0 on the left horizon, 90 overhead, 180 on the right
  // horizon, below zero not yet risen. The globe hangs altitude degrees
  // over the horizon, azimuth degrees right of straight ahead (at 90 it
  // sits on the sun's arc - where an eclipse can happen). Phase and the
  // lean of the terminator follow as in the real sky: a sun low on
  // the left lights the left half, a sun not yet risen leaves more than
  // half lit, a sun climbing toward the globe thins it to a crescent.
  // Events turn the sun (the "sun" action), only onward: a turn back is
  // ignored, so a death cannot undo the morning.
  // Size is the disc across in screen units, x and y its center;
  // brightness a percentage of the standard exposure, past 100 allowed;
  // longitude the meridian facing the Moon, degrees east; tilt how far
  // the top of the axis leans left; map and night name pictures of the
  // level's object art ("sky:earth" names the set), night optional (city
  // lights) and in the same set as the map, nightBrightness
  // a percentage of the standard glow of its lights; atmosphere a
  // percentage, 0 for an airless world; surface "matte" (Earth-like)
  // or "regolith" (Moon-like). In the sky layer by default.
  // JSON:
  //   {"kind": "globe", "screens": [1, 11], "x": 392, "y": 82,
  //    "size": 30, "tint": [78, 80, 86], "brightness": 100,
  //    "sun": -40, "altitude": 50, "azimuth": 0, "longitude": 45,
  //    "tilt": -20,
  //    "map": "earth", "night": "earth-night", "nightBrightness": 100,
  //    "atmosphere": 60,
  //    "surface": "matte", "tag": "earth"}
  TSkyGlobe = class(TDynamicObject)
  private
    FSize: Single;
    FSun: TValueFade; // degrees
    FLitSun: Single; // the sun the globe was last lit by
    FAltitude: Single; // degrees
    FAzimuth: Single; // degrees
    FLongitude: Single;
    FMapName: string;
    FNightMapName: string;
    FLook: TGlobeLook;
    FGlobe: TGlobe;
    procedure Relight;
  protected
    procedure Advance(AMotionX, AMotionY: Single;
      AParentAlive: Boolean); override;
    procedure DrawAt(const ACanvas: TDynamicCanvas; AX, AY: Single;
      AAlpha: Single); override;
  public
    constructor Create(const APlacement: TDynamicPlacement;
      AObj: TJSONObject; const AOwner: string);
    destructor Destroy; override;
    procedure Acquire(const ACanvas: TDynamicCanvas); override;
    procedure Release; override;
    // Heads the sun for ADegrees over ATicks; 0 ticks = at once
    procedure TurnSun(ADegrees: Single; ATicks: Integer);
  end;

  // Steady - an even turn; dying - the motor catches and cuts out, so
  // the rotor surges, drags to a stop and twitches
  TMotorRun = (mrSteady, mrDying);

  // A dying motor works in catches and stalls
  TMotorClock = record
    TicksLeft: Integer; // of the catch or the stall under way
    Running: Boolean;
    Drive: Single; // 0..1 of the full speed; 0 through a stall
  end;

  // One rotor in three states of blur, what stands behind it and what
  // stands over it
  TFanArt = record
    Sharp, Smear, Disc: PSdlTexture;
    Back, Guard: PSdlTexture; // nil = none
  end;

  // A ventilation fan: a rotor the code turns behind a guard that stands
  // still, so the light painted on the guard never spins with the
  // blades. The rotor blurs with its speed - sharp, then smeared along
  // the turn, then a disc: sharp blades turning fast would strobe and
  // seem to crawl backward.
  // Rotor, guard and back are the middles of picture names in the
  // level's object art, every picture a square with the axis at its
  // center: rotor "heavy" is rotor-heavy-N, rotor-heavy-smear-N and
  // rotor-heavy-disc-N, guard "spider" is guard-spider-N, back "shaft"
  // is back-shaft-N, N a side of FanArtSides. A rotor is painted turning
  // counterclockwise; a fan that turns clockwise mirrors it. The back
  // stands behind the rotor: a plate with an opening would show the
  // backdrop through it.
  // Size is the square across in screen units, x and y its center; rpm
  // in turns a minute, counterclockwise above zero and clockwise below;
  // the tint multiplies the art; light is the glow of the shaft behind
  // the blades, three percentages, absent = none; guard and back are
  // optional.
  // Intensity is the share of the full speed, and the rotor follows it
  // with the inertia of a wheel. Fans at different points stand out of
  // step and turn a hair apart.
  // JSON:
  //   {"kind": "fan", "screen": 9, "x": 144, "y": 80, "size": 32,
  //    "tint": [80, 80, 82], "rotor": "turbine", "guard": "bezel",
  //    "back": "shaft", "rpm": 180, "run": "steady",
  //    "light": [75, 10, 6]}
  TFan = class(TDynamicObject)
  private
    FSize: Single;
    FRotorName: string;
    FGuardName: string; // '' = no guard
    FBackName: string; // '' = no back
    FClockwise: Boolean;
    FFullRate: Single; // degrees per tick at full intensity
    FRun: TMotorRun;
    FLit: Boolean;
    FLight: TRgb;
    FSeed: Cardinal;
    FRandom: TXorShift;
    FMotor: TMotorClock;
    FRate: Single; // degrees per tick
    FAngle: Single; // degrees along the turn
    FLastAngle: Single;
    FArt: TFanArt;
    procedure Start;
    procedure TickMotor;
  protected
    procedure Advance(AMotionX, AMotionY: Single;
      AParentAlive: Boolean); override;
    procedure DrawAt(const ACanvas: TDynamicCanvas; AX, AY: Single;
      AAlpha: Single); override;
  public
    constructor Create(const APlacement: TDynamicPlacement;
      AObj: TJSONObject; const AOwner: string);
    procedure Acquire(const ACanvas: TDynamicCanvas); override;
    procedure Release; override;
    // The rotor stands and turns as the level opened
    procedure Rewind; override;
  end;

  // A corner of a haze's mesh in the plume's own frame: units across
  // from the axis and along the flow from the point, and how much of the
  // haze it carries - 0 on the rim, up to 1 in the core
  THazeKnot = record
    Across, Along: Single;
    Grip: Single;
  end;

  // The two pictures a haze lays one over the other
  THazeCopy = (hcSharp, hcBlur);

  // Heat haze: the backdrop seen through hot gas. The picture behind a
  // plume is drawn again on a mesh whose corners noise pushes about, the
  // noise carried along by the flow - two grains of it at two speeds, so
  // no wave shows - hardest in the core of the plume, not at all on its
  // rim. A second, part-clear copy pushed another way blurs it, and the
  // core is a shade darker: hot gas does all three. It bends the
  // backdrop alone and lives on the backdrop layer; with no backdrop on
  // the screen it draws nothing.
  // The plume leaves the point along angle (degrees counterclockwise
  // from the right, 90 = up), length units long, mouth units across at
  // the point and width at its far end. Shift is the farthest a point of
  // the backdrop is moved across the flow, in screen units; grain the
  // size of the larger eddies, speed the flow in units a second; shade a
  // percentage; blur false leaves the second copy out. Intensity scales
  // the shift and the shade. The tint is the backdrop's own: a haze has
  // none.
  // Hazes do not add up: where two overlap, the later in the file paints
  // the backdrop over the earlier one's.
  // In the depth (the canvas' Scale and Tone) the plume is smaller about
  // its point and weaker.
  // JSON:
  //   {"kind": "haze", "parent": "s16-plat-01", "x": 16, "y": 27,
  //    "angle": 270, "length": 64, "mouth": 10, "width": 46,
  //    "shift": 5, "grain": 7, "speed": 84, "shade": 18, "blur": true}
  THaze = class(TDynamicObject)
  private
    FLength: Single;
    FMouth: Single;
    FWidth: Single;
    FShift: Single;
    FGrain: Single;
    FSpeed: Single;
    FShade: Single; // 0..1
    FBlurs: Boolean;
    FFlow: TSdlFPoint; // the way the plume goes on the screen, a unit vector
    FSeed: Cardinal;
    FTicks: Integer;
    FKnots: TArray<THazeKnot>;
    FReach: Single; // the farthest a knot stands from the axis
    // The noise at every knot this frame: across and along, -1..1 each
    FPushes: TArray<TSdlFPoint>;
    FIndices: TArray<Integer>;
    FVertices: TArray<TSdlVertex>;
    procedure BuildMesh;
    procedure RollPushes(ASeconds: Double);
    procedure PlaceVertices(const ACanvas: TDynamicCanvas; AX, AY: Single;
      ACopy: THazeCopy);
  protected
    procedure Advance(AMotionX, AMotionY: Single;
      AParentAlive: Boolean); override;
    procedure DrawAt(const ACanvas: TDynamicCanvas; AX, AY: Single;
      AAlpha: Single); override;
  public
    constructor Create(const APlacement: TDynamicPlacement;
      AObj: TJSONObject; const AOwner: string);
  end;

// Reads the "dynamics" array of a level; an absent section is an empty
// list. The caller owns the result. ALevelId names the level in errors.
function ParseDynamics(ARoot: TJSONObject;
  const ALevelId: string): TDynamicObjects;
// Reads one object, written as an item of that array is. AWhere names
// it in errors after its kind: "#2" makes "beacon #2". The caller owns
// the result.
function ParseDynamic(AObj: TJSONObject;
  const ALevelId, AWhere: string): TDynamicObject;
// 0..1 by a name, the 1 left out: the same at every load, another name -
// another roll
function NameRoll(const AName: string): Single;

implementation

uses
  System.Math, Sprites.Sets, Render.Glow;

type
  TDynamicKind = (dkBeacon, dkSmoke, dkGlobe, dkSparks, dkFan, dkHaze,
    dkLightning);

  // Where and how a fan's layers land in one frame
  TFanPose = record
    Dest: TSdlFRect;
    Angle: Double; // degrees clockwise, as SDL turns
    Flip: Integer;
    Tint: TColorTint;
  end;

const
  // The JSON vocabulary of "kind", "layer", "blink", "flow", "surface",
  // "collide" and "run"
  DynamicKindIds: array [TDynamicKind] of string = ('beacon', 'smoke',
    'globe', 'sparks', 'fan', 'haze', 'lightning');
  DynamicLayerIds: array [TDynamicLayer] of string = ('backdrop', 'sky',
    'back', 'front');
  DefaultLayers: array [TDynamicKind] of TDynamicLayer = (dlBack, dlBack,
    dlSky, dlBack, dlBack, dlBackdrop, dlBack);
  BlinkPatternIds: array [TBlinkPattern] of string = (
    'steady', 'pulse', 'flash', 'double', 'faulty', 'dying');
  SmokeFlowIds: array [TSmokeFlow] of string = ('steady', 'gusty', 'puffs');
  GlobeSurfaceIds: array [TGlobeSurface] of string = ('regolith', 'matte');
  SparkWallIds: array [TSparkWall] of string = ('none', 'die', 'bounce');
  LightningCollideIds: array [TLightningCollide] of string = ('none',
    'strike');
  MotorRunIds: array [TMotorRun] of string = ('steady', 'dying');

  // Seconds and percentages in JSON, ticks and shares in the code; the
  // logic runs 33 ticks a second (tickRate of Game.Config)
  LogicTicksPerSecond = 33;
  // An object comes to feel its parent's effort, and to forget it, over
  // this many ticks: a jet spools up, it does not switch
  EffortEaseTicks = 6;

resourcestring
  SDynamicBadKind = 'Level "%s": dynamic object %s: unknown kind "%s"';
  SDynamicKindUnbuilt = 'Dynamic kind "%s" has no constructor';
  SDynamicNoPlace = 'Level "%s": %s names no screen, no screens and no '
    + 'parent';
  SDynamicTwoPlaces = 'Level "%s": %s names more than one of screen, '
    + 'screens and parent - one of them decides where it stands';
  SDynamicTurnsNailed = 'Level "%s": %s turns, but has no parent to turn '
    + 'with';
  SDynamicBadScreens = '%s: "screens" takes two screen numbers, the first '
    + 'and the last';
  SDynamicBadWord = '%s: unknown %s "%s"';
  SDynamicBadNumber = '%s: "%s" must be above zero';
  SDynamicBadPercent = '%s: "%s" takes a percentage, 0..100';
  SDynamicBadReach = '%s: "%s" cannot be below zero';
  SDynamicBadAltitude = '%s: "altitude" takes degrees over the horizon, '
    + '0..90';
  SDynamicBadAzimuth = '%s: "azimuth" takes degrees right of straight '
    + 'ahead, -90..90';
  SGlobeSplitMaps = 'Globe maps "%s" and "%s" live in different sets - '
    + 'a globe reads both from one';
  SHazeLayer = '%s: a haze bends the backdrop and lives on the layer '
    + '"backdrop" alone';
  SHazeGrain = '%s: the "grain" of a haze is 1 or more';
  SLightningBadSpread = '%s: "spread" takes two half-sizes, x and y, in '
    + 'units, neither below zero';
  SLightningBadStrokes = '%s: "strokes" takes a whole number, 1..%d';

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

  SparkLifeJitter = 0.5; // of the life, either way
  SlowSpeedShare = 0.2; // the slowest spark, of the fastest
  SparkSpeedCurve = 2.0; // the fan of a grinder
  SparkThinShare = 0.55;
  SparkStreakTicks = 2.0;
  SparkSpawnSpread = 1.0; // around the point, in streak widths
  SparkWarmAt = 0.35;
  // Steel off steel and stone
  SparkBounce: TSparkBounce = (Keep: 0.42; Grip: 0.7; LifeLost: 0.35);
  SparksCapacity = 256;
  // The field rolls dice of its own, apart from the source's
  FieldSeedSalt = $4669656C; // "Fiel"
  // An arc pours for this long; its size and the wait for the next one
  // roll around their means, a small arc likelier than a big one
  ArcTicks = 3;
  ArcSizeMin = 0.4;
  ArcSizeSpread = 1.8;
  ArcGapMin = 0.3;
  ArcGapSpread = 1.4;
  // A faint source arcs softer and rarer, but not that much softer
  ArcSizeFloor = 0.4;
  ArcRateFloor = 0.25;
  ArcColor: TRgb = (R: 190; G: 215; B: 255); // colder than the sparks
  // A spell and a pause roll around their means, evenly
  RestSpanMin = 0.5;
  RestSpanSpread = 1.0;
  FlashKeep = 0.62; // of the light, per tick
  FlashScale = 8.0; // the light across, in streak widths
  FlashCoreShare = 0.35;

  // Steel by default: white heat, straw, cherry red
  SteelWarmTint: TColorTint = (R: 100; G: 66; B: 27);
  SteelCoolTint: TColorTint = (R: 69; G: 14; B: 6);
  DefaultSparkRate = 12;
  DefaultBurst = 8;
  DefaultSparkLife = 1.0;
  DefaultSparkSpeed = 90;
  DefaultSparkAngle = -90;
  DefaultSparkCone = 60;
  DefaultSparkGravity = 120;
  DefaultSparkDrag = 60;
  DefaultSparkSize = 2.0;
  DefaultSparkOpacity = 100;
  DefaultFlash = 50;
  DefaultFork = 20;
  DefaultSpell = 6;

  // Lightning. A bolt is BoltLengthMin of the reach long at the least and
  // BoltLengthMin + BoltLengthSpread at the most; the wait for the next one
  // rolls around its mean, evenly
  BoltLengthMin = 0.55;
  BoltLengthSpread = 0.45;
  BoltGapMin = 0.3;
  BoltGapSpread = 1.4;
  // What a faint source keeps of its reach, width and strokes
  FaintReachShare = 0.5;
  FaintWidthShare = 0.7;
  FaintStrokeShare = 0.5;
  // A strike looks for matter along its way this many units at a time
  MarchStep = 2;
  // A bolt that finds none is a streamer this share of the reach long
  StreamerShare = 0.45;
  BoltCapacity = 8;
  BoltSeedSalt = $4C746E67; // "Ltng"
  // Cold blue-violet, the natural color of a discharge
  LightningTint: TColorTint = (R: 66; G: 74; B: 100);

  DefaultReach = 30;
  DefaultSpreadX = 9;
  DefaultSpreadY = 14;
  DefaultBoltAngle = 90;
  DefaultBoltCone = 360;
  DefaultBoltSize = 0.8;
  DefaultJag = 24;
  DefaultBoltFork = 12;
  DefaultBoltFrequency = 1.6;
  DefaultStrokes = 2;
  DefaultBoltLife = 0.1;
  DefaultBoltFlash = 45;

  // A globe looks like the Earth unless the level says otherwise: matte
  // ground under air, the night side black but for a trace of
  // moonlight. Surface, tilt, brightness and air come from the level.
  GlobeLook: TGlobeLook = (
    Side: 256;
    Surface: gsMatte;
    AxisRoll: 0;
    AxisTip: 12.0;
    Ambient: (0.006, 0.007, 0.010);
    Tint: (1, 1, 1);
    Exposure: 1.7;
    LimbFade: 0;
    Atmosphere: 0;
    AirColor: (0.32, 0.55, 1.0);
    // City lights are a few texels across on a sky-sized globe: they
    // need more than the sunlit ground to read at all
    NightGain: 2.5);
  // Below this the terminator moves less than a texel of a sky-sized
  // globe: the sun turns on, the light waits
  RelightStep = 0.05; // degrees

  DefaultGlobeSize = 30.0;
  DefaultSun = 0; // on the horizon: a half-lit globe
  DefaultAltitude = 45;
  DefaultAzimuth = 0;
  DefaultLongitude = 0;
  DefaultGlobeMap = 'earth';
  DefaultBrightness = 100;
  DefaultAtmosphere = 60;

  // Fan art comes in squares of these sides, in pixels; a fan takes the
  // smallest that is still as dense as the HD backdrops - 1440 pixels on
  // 512 screen units
  FanArtSides: array [0..3] of Integer = (64, 128, 256, 512);
  FanArtDensity = 1440 / 512;
  // A fan's pictures: the name, then the side
  RotorSharpArt = 'rotor-%s-%d';
  RotorSmearArt = 'rotor-%s-smear-%d';
  RotorDiscArt = 'rotor-%s-disc-%d';
  GuardArt = 'guard-%s-%d';
  BackArt = 'back-%s-%d';

  FullTurn = 360;
  // Turns a minute in JSON, degrees a tick in the code
  RateOfRpm = FullTurn / (60 * LogicTicksPerSecond);
  // The blur by speed, in turns a minute: sharp up to the first, fully
  // smeared at the second, a disc from the third. At 60 frames a second
  // five sharp blades seem to turn backward past 360 turns a minute,
  // eight past 225: the disc is over them before that.
  SharpUpToRpm = 40;
  SmearedAtRpm = 110;
  DiscFromRpm = 230;
  // A tick closes this share of the gap to the wanted speed. A sound
  // rotor coasts down far longer than it spins up; a dying one drags on
  // its bearing and stops soon.
  SpinUpEase = 0.05;
  CoastEases: array [TMotorRun] of Single = (0.02, 0.07);
  // Unpowered and slower than this, friction stops the rotor
  StandstillRate = 0.05; // degrees per tick
  // Fans turn this share apart in speed, either way
  SpeedDetune = 0.04;
  // The slots a fan rolls its standing angle and its detune in. Even
  // both: SlotRoll sets the lowest bit, so slot 1 would roll as slot 0.
  PhaseSlot = 0;
  DetuneSlot = 2;
  // A dying motor, in seconds; a catch is short far more often than
  // long, and the weakest is CatchFloor of the full speed
  CatchMin = 0.15;
  CatchSpread = 2.6;
  CatchFloor = 0.3;
  StallMin = 0.4;
  StallSpread = 2.4;
  // The shaft's glow across, in fan sizes: spent before the guard's ring
  ShaftLightScale = 1.25;
  FullLevel = 1.0;
  Upright = 0.0;

  DefaultFanSize = 32.0;
  DefaultFanRpm = 20;
  DefaultFanRotor = 'heavy';

  // Haze. The mesh: this many cells across the plume, however wide it is
  // there, and cells this long along it - shorter than the finer eddies
  // of the default grain
  HazeColumns = 16;
  HazeRowLength = 2.0;
  // The plume widens fast at the point and slower farther on: its width
  // follows the way along it to this power. Typed: Power has three
  // overloads.
  HazeFlare: Single = 0.7;
  // The haze sets in over this share of the length and thins out toward
  // the far end along this curve
  HazeOnsetShare = 0.08;
  HazeFadePower: Single = 1.3;
  // Along the flow the backdrop is moved this share of the shift across:
  // gas shears sideways more than it stretches
  HazeAlongShare = 0.6;
  // The second copy, the blur, lies this thick over the first
  HazeBlurOpacity = 0.5;
  DefaultHazeAngle = 90;
  DefaultHazeLength = 48.0;
  DefaultHazeMouth = 8.0;
  DefaultHazeWidth = 32.0;
  DefaultHazeShift = 3.0;
  DefaultHazeGrain = 7.0;
  // Eddies under a unit are finer than the mesh shows, and the lattice a
  // frame rolls grows as the square of the grain shrinks
  MinHazeGrain = 1.0;
  DefaultHazeSpeed = 60.0;
  DefaultHazeShade = 12;

type
  // One of the noises a haze is pushed by: its eddies and its speed as
  // shares of the haze's own grain and speed, its weight in the push,
  // and a salt that sets its lattice apart from the other's
  THazeLayer = record
    GrainShare, SpeedShare, Weight: Single;
    Salt: Cardinal;
  end;

  // The two values a lattice point of the noise holds, -1..1 each
  TNoisePair = record
    First, Second: Single;
  end;

const
  // Large slow eddies and small fast ones: neither repeats in step with
  // the other, so the eye finds no wave
  HazeLayers: array [0..1] of THazeLayer = (
    (GrainShare: 1.0; SpeedShare: 1.0; Weight: 0.62; Salt: $51A7E0D1),
    (GrainShare: 0.43; SpeedShare: 1.5; Weight: 0.38; Salt: $C0A1E5CE));
  // A lattice point is numbered by its column in the low half of a
  // Cardinal and its row in the high one, so the rows repeat after
  // NoiseRows: the flow is counted within them
  HalfBits = 16;
  HalfMask = (1 shl HalfBits) - 1;
  NoiseRows = 1 shl HalfBits;

type
  // The lattice points one noise is read at in a frame, rolled once: a
  // knot reads four of them, and a point is read by many knots
  TNoiseWindow = record
    FirstCol, FirstRow: Integer;
    Cols: Integer;
    Rolls: TArray<TNoisePair>;
    procedure Roll(AReach, ANear, AFar: Double; ASeed: Cardinal);
    function NoiseAt(AX, AY: Double): TNoisePair;
  end;

function TintColor(const ATint: TColorTint): TRgb;
begin
  Result.R := PercentToColorMod(ATint.R);
  Result.G := PercentToColorMod(ATint.G);
  Result.B := PercentToColorMod(ATint.B);
end;

// A tag, or any other name, as a number
function TagSalt(const ATag: string): Cardinal;
const
  EmptyTagSalt = $9E3779B9;
var
  Noise: TXorShift;
begin
  Noise.Seed := EmptyTagSalt;
  for var Letter in ATag do
  begin
    Noise.Seed := Noise.Seed xor Cardinal(Ord(Letter));
    // An xorshift at zero stays at zero
    if Noise.Seed = 0 then
      Noise.Seed := EmptyTagSalt;
    Noise.NextUnit;
  end;
  Result := Noise.Seed;
end;

// Objects at different points go out of step: the seed is the position
// in tenths of a unit, x in the high half. Under a parent its tag is
// mixed in: one object hung at one point of two parents - a part of a
// rig two pads wear - goes out of step as well.
function PlacementSeed(const APlacement: TDynamicPlacement): Cardinal;
begin
  Result := (Cardinal(Round(APlacement.X * SeedPrecision)) shl 16) xor
    Cardinal(Round(APlacement.Y * SeedPrecision));
  if APlacement.Parent <> '' then
    Result := Result xor TagSalt(APlacement.Parent);
end;

// Mixes the bits of AValue. The xorshift of SlotRoll is not enough where
// numbers a bit apart must roll unlike: the neighbours of a lattice, the
// names of two pads.
function Scramble(AValue: Cardinal): Cardinal;
const
  // Odd, and under 2^31: the product stays inside an Int64 whatever is
  // scrambled, so the overflow check has nothing to catch
  ScrambleFactor = $45D9F3B;
begin
  var Folded: Cardinal := AValue xor (AValue shr HalfBits);
  Result := Cardinal((Int64(Folded) * ScrambleFactor) and $FFFFFFFF);
end;

function NameRoll(const AName: string): Single;
begin
  // Twice, as a lattice point: LatticeRoll says why
  var Mixed: Cardinal := Scramble(Scramble(TagSalt(AName)));
  Mixed := Mixed xor (Mixed shr HalfBits);
  Result := (Mixed and HalfMask) / (1 shl HalfBits);
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
// TValueFade
// ---------------------------------------------------------------------------

procedure TValueFade.Settle(AValue: Single);
begin
  Current := AValue;
  Target := AValue;
  Step := 0;
end;

procedure TValueFade.HeadFor(ATarget: Single; ATicks: Integer);
begin
  Target := ATarget;
  if ATicks <= 0 then
  begin
    Current := ATarget;
    Exit;
  end;
  Step := Abs(ATarget - Current) / ATicks;
end;

procedure TValueFade.Tick;
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
// TRestClock
// ---------------------------------------------------------------------------

function TRestClock.Tick(var ADice: TXorShift): Boolean;
begin
  Dec(TicksLeft);
  if TicksLeft > 0 then
    Exit(False);

  Awake := not Awake;
  var MeanTicks := Pause;
  if Awake then
    MeanTicks := Spell;
  var Span: Single := MeanTicks * (RestSpanMin + RestSpanSpread * ADice.NextUnit);
  TicksLeft := Max(1, Round(Span));
  Result := Awake;
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
  FIntensity.Settle(AIntensity);
end;

constructor TDynamicObject.Create(const APlacement: TDynamicPlacement;
  AObj: TJSONObject; const AOwner: string);
begin
  Create(APlacement, ReadShare(AObj, 'intensity', 100, AOwner));
  FSurge := ReadShare(AObj, 'surge', 0, AOwner);
end;

function TDynamicObject.GetIntensity: Single;
begin
  var Level := FIntensity.Current;
  Result := Level + (1 - Level) * FSurge * FEffort.Current;
end;

procedure TDynamicObject.FollowEffort(AEffort: Single);
begin
  if AEffort <> FEffort.Target then
    FEffort.HeadFor(AEffort, EffortEaseTicks);
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
  FEffort.Tick;
  Advance(MotionX, MotionY, AParentAlive);
end;

procedure TDynamicObject.FadeTo(ALevel: Single; ATicks: Integer);
begin
  FIntensity.HeadFor(ALevel, ATicks);
end;

procedure TDynamicObject.Rewind;
begin
  FIntensity.Settle(FIntensity.Initial);
  FEffort.Settle(0);
  ForgetOrigin;
end;

procedure TDynamicObject.ForgetOrigin;
begin
  FOriginKnown := False;
end;

procedure TDynamicObject.Acquire(const ACanvas: TDynamicCanvas);
begin
  // Most kinds draw with the canvas alone
end;

procedure TDynamicObject.Release;
begin
  // Nothing acquired, nothing to release
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

procedure TDynamicObjects.TurnSunTagged(const ATag: string;
  ADegrees: Single; ATicks: Integer);
begin
  for var DynamicObject in Self do
  begin
    if DynamicObject.Placement.Tag <> ATag then
      Continue;
    if DynamicObject is TSkyGlobe then
      TSkyGlobe(DynamicObject).TurnSun(ADegrees, ATicks);
  end;
end;

function TDynamicObjects.AnyTagged(const ATag: string;
  AKind: TDynamicObjectClass): Boolean;
begin
  for var DynamicObject in Self do
  begin
    if DynamicObject.Placement.Tag <> ATag then
      Continue;
    if (AKind = nil) or (DynamicObject is AKind) then
      Exit(True);
  end;
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
  // In the depth the lamp is smaller and dimmer, as its pad is
  var Size: Single := FSize * ACanvas.Scale;
  var Light: Single := Intensity * ACanvas.Tone;

  DrawGlow(ACanvas.Renderer, ACanvas.PointGlow, AX, AY, Size * SpillScale,
    Color, Light * SpillLevel * Flash);
  DrawGlow(ACanvas.Renderer, ACanvas.PointGlow, AX, AY, Size,
    Color, Light * Lit);
  DrawGlow(ACanvas.Renderer, ACanvas.PointGlow, AX, AY, Size * CoreScale,
    Mix(Color, White, CoreWhiteness), Light * Lit);
  if FGlint > 0 then
    DrawGlow(ACanvas.Renderer, ACanvas.FlareGlow, AX, AY,
      Size * GlintScale, Color, Light * FGlint * Flash * Flash * Flash);
  if FRays > 0 then
  begin
    var Reach := FRays * ACanvas.Scale *
      (RayRestReach + (1 - RayRestReach) * Flash);
    DrawGlow(ACanvas.Renderer, ACanvas.StarburstGlow, AX, AY, 2 * Reach,
      Color, Light * FRayIntensity * Flash);
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
  // Not of the look: the smokes the game makes itself all burn with fire
  if AObj.GetValue('heatTint') <> nil then
    FHeatColor := TintColor(ReadTint(AObj, AOwner, 'heatTint'));
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
  FHeatColor := FireColor;
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

function TSmoke.Exhausted: Boolean;
begin
  Result := (Intensity <= 0) and (FSwarm.Count = 0);
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
    Power(Remaining, FadeOutPower) * ACanvas.Tone;
  if Level < VisibleLevel then
    Exit;

  var Growth := 1 - Sqr(1 - Share);
  var Size := Lerp(FSize, FEndSize, Growth) * AParticle.Scale * ACanvas.Scale;
  // AX, AY is the point the smoke leaves: in the depth the plume draws
  // in toward it
  var CenterX := AX + (AParticle.X + AParticle.SpeedX * AAlpha) * ACanvas.Scale;
  var CenterY := AY + (AParticle.Y + AParticle.SpeedY * AAlpha) * ACanvas.Scale;
  var Color := Mix(TintColor(Placement.Tint), TintColor(FEndTint), Share);
  var Glow: Single := 0;
  if Share < HeatShare then
    Glow := FHeat * (1 - Share / HeatShare);

  DrawPuff(ACanvas.Renderer, ACanvas.Puffs[AParticle.Shape], CenterX, CenterY,
    Size, AParticle.Angle + AParticle.Spin * AAlpha,
    Mix(Color, FHeatColor, Glow), Level);
  if Glow > 0 then
    DrawGlow(ACanvas.Renderer, ACanvas.PointGlow, CenterX, CenterY,
      Size * HeatGlowScale, FHeatColor,
      Glow * HeatGlowLevel * AParticle.Weight * ACanvas.Tone);
end;

procedure TSmoke.DrawAt(const ACanvas: TDynamicCanvas; AX, AY: Single;
  AAlpha: Single);
begin
  for var i := 0 to FSwarm.Count - 1 do
    DrawPuffOf(ACanvas, AX, AY, AAlpha, FSwarm[i]^);
end;

// ---------------------------------------------------------------------------
// TSparks
// ---------------------------------------------------------------------------

function ReadTintOrDefault(AObj: TJSONObject; const AKey: string;
  const ADefault: TColorTint; const AOwner: string): TColorTint;
begin
  if AObj.GetValue(AKey) = nil then
    Exit(ADefault);
  Result := ReadTint(AObj, AOwner, AKey);
end;

function ReadSparkSourceLook(AObj: TJSONObject; ALayer: TDynamicLayer;
  const AOwner: string): TSparkSourceLook;
begin
  Result.Rate := ReadReach(AObj, 'rate', DefaultSparkRate, AOwner);
  Result.Burst := ReadReach(AObj, 'burst', DefaultBurst, AOwner);
  Result.Frequency := ReadPositive(AObj, 'frequency', DefaultFrequency,
    AOwner);
  Result.Spell := ReadPositive(AObj, 'spell', DefaultSpell, AOwner);
  Result.Pause := ReadReach(AObj, 'pause', 0, AOwner);
  Result.Life := ReadPositive(AObj, 'life', DefaultSparkLife, AOwner);
  Result.Speed := ReadReach(AObj, 'speed', DefaultSparkSpeed, AOwner);
  Result.Angle := AObj.GetValue<Double>('angle', DefaultSparkAngle);
  Result.Cone := ReadReach(AObj, 'cone', DefaultSparkCone, AOwner);
  Result.Gravity := AObj.GetValue<Double>('gravity', DefaultSparkGravity);
  Result.Drag := ReadShare(AObj, 'drag', DefaultSparkDrag, AOwner);
  Result.Size := ReadPositive(AObj, 'size', DefaultSparkSize, AOwner);
  Result.Opacity := ReadShare(AObj, 'opacity', DefaultSparkOpacity, AOwner);
  Result.Flash := ReadShare(AObj, 'flash', DefaultFlash, AOwner);
  Result.Fork := ReadShare(AObj, 'fork', DefaultFork, AOwner);

  var LayerWall := swPass;
  if ALayer = dlFront then
    LayerWall := swBounce;
  Result.Wall := TSparkWall(ReadWord(AObj, 'collide', SparkWallIds[LayerWall],
    SparkWallIds, 'collide', AOwner));
  Result.MidTint := ReadTintOrDefault(AObj, 'midTint', SteelWarmTint, AOwner);
  Result.EndTint := ReadTintOrDefault(AObj, 'endTint', SteelCoolTint, AOwner);
end;

constructor TSparks.Create(const APlacement: TDynamicPlacement;
  AObj: TJSONObject; const AOwner: string);
begin
  inherited Create(APlacement, AObj, AOwner);
  TakeLook(ReadSparkSourceLook(AObj, APlacement.Layer, AOwner),
    PlacementSeed(APlacement));
end;

constructor TSparks.CreateLook(const APlacement: TDynamicPlacement;
  const ALook: TSparkSourceLook; AIntensity: Single; ASeed: Cardinal);
begin
  inherited Create(APlacement, AIntensity);
  TakeLook(ALook, ASeed);
end;

destructor TSparks.Destroy;
begin
  FField.Free;
  inherited;
end;

// Seconds and shares in, ticks out
function TSparks.FieldLook(const ALook: TSparkSourceLook): TSparkLook;
begin
  Result := Default(TSparkLook);
  Result.Gravity := ALook.Gravity / Sqr(LogicTicksPerSecond);
  var Kept: Single := 1 - ALook.Drag;
  Result.AirKeep := Power(Kept, TickExponent);
  var LifeTicks: Single := ALook.Life * LogicTicksPerSecond;
  Result.LifeMin := LifeTicks * (1 - SparkLifeJitter);
  Result.LifeMax := LifeTicks * (1 + SparkLifeJitter);
  Result.Width := ALook.Size;
  Result.ThinShare := SparkThinShare;
  Result.StreakTicks := SparkStreakTicks;
  Result.SpeedCurve := SparkSpeedCurve;
  Result.Level := ALook.Opacity;
  Result.Heat.Hot := TintColor(Placement.Tint);
  Result.Heat.Warm := TintColor(ALook.MidTint);
  Result.Heat.Cool := TintColor(ALook.EndTint);
  Result.Heat.WarmAt := SparkWarmAt;
  Result.Wall := ALook.Wall;
  Result.Bounce := SparkBounce;
  Result.ForkChance := ALook.Fork;
end;

procedure TSparks.TakeLook(const ALook: TSparkSourceLook; ASeed: Cardinal);
begin
  FRate := ALook.Rate / LogicTicksPerSecond;
  FBurst := ALook.Burst;
  FSize := ALook.Size;
  FFlashPeak := ALook.Flash;

  FSpray.Count := 1;
  FSpray.Heading := ALook.Angle;
  FSpray.Cone := ALook.Cone;
  FSpray.FastSpeed := ALook.Speed / LogicTicksPerSecond;
  FSpray.SlowSpeed := FSpray.FastSpeed * SlowSpeedShare;

  FRandom.Seed := ASeed or 1;
  FField := TSparkField.Create(FieldLook(ALook), Blocked, SparksCapacity,
    ASeed xor FieldSeedSalt);
  FArc.Gap := LogicTicksPerSecond / ALook.Frequency;
  // Sources seeded apart arc apart
  FArc.WaitTicks := Round(FArc.Gap * FRandom.NextUnit);
  FRest.Spell := ALook.Spell * LogicTicksPerSecond;
  FRest.Pause := ALook.Pause * LogicTicksPerSecond;
end;

procedure TSparks.Acquire(const ACanvas: TDynamicCanvas);
begin
  FSolid := ACanvas.Solid;
end;

procedure TSparks.UseSolid(const ASolid: TSolidProbe);
begin
  FSolid := ASolid;
end;

procedure TSparks.Rewind;
begin
  inherited;
  FField.Clear;
  FOwed := 0;
  FArc.TicksLeft := 0;
  FRest.Awake := False;
  FRest.TicksLeft := 0;
  FFlash := 0;
end;

// The field counts from the point the sparks leave, the probe from the
// corner of the screen
function TSparks.Blocked(AX, AY: Single): Boolean;
begin
  Result := Assigned(FSolid) and FSolid(FPoint.X + AX, FPoint.Y + AY);
end;

procedure TSparks.StartArc;
begin
  var SizeScale: Single := ArcSizeFloor + (1 - ArcSizeFloor) * Intensity;
  var RateScale: Single := ArcRateFloor + (1 - ArcRateFloor) * Intensity;
  var Luck := FRandom.NextUnit;
  FArc.Pour := FBurst * SizeScale *
    (ArcSizeMin + ArcSizeSpread * Luck * Luck) / ArcTicks;
  FArc.TicksLeft := ArcTicks;
  var Wait: Single := FArc.Gap *
    (ArcGapMin + ArcGapSpread * FRandom.NextUnit) / RateScale;
  FArc.WaitTicks := Max(ArcTicks, Round(Wait));
end;

procedure TSparks.ThrowOne;
begin
  var Reach: Single := FSize * SparkSpawnSpread;
  var OffX: Single := (2 * FRandom.NextUnit - 1) * Reach;
  var OffY: Single := (2 * FRandom.NextUnit - 1) * Reach;
  FField.Spray(OffX, OffY, FSpray);
end;

procedure TSparks.Emit;
begin
  if FRest.Pause > 0 then
  begin
    // A spell opens with an arc
    if FRest.Tick(FRandom) then
      FArc.WaitTicks := 0;
    if not FRest.Awake then
      Exit;
  end;

  FOwed := FOwed + FRate * Intensity;

  if FBurst > 0 then
  begin
    Dec(FArc.WaitTicks);
    if FArc.WaitTicks <= 0 then
      StartArc;
  end;
  if FArc.TicksLeft > 0 then
  begin
    Dec(FArc.TicksLeft);
    FOwed := FOwed + FArc.Pour;
    FFlash := 1;
  end;

  while FOwed >= 1 do
  begin
    ThrowOne;
    FOwed := FOwed - 1;
  end;
end;

procedure TSparks.Advance(AMotionX, AMotionY: Single; AParentAlive: Boolean);
begin
  FPoint.X := Origin.X + Placement.X;
  FPoint.Y := Origin.Y + Placement.Y;
  FField.ShiftFrame(AMotionX, AMotionY);
  FFlash := FFlash * FlashKeep;
  if AParentAlive and (Intensity > 0) then
    Emit
  else
    // An arc cut short does not wait for the source to come back
    FArc.TicksLeft := 0;
  FField.Tick;
end;

procedure TSparks.DrawAt(const ACanvas: TDynamicCanvas; AX, AY: Single;
  AAlpha: Single);
var
  DrawPoint: TSdlFPoint;
begin
  var Light: Single := FFlash * FFlashPeak;
  if Light >= VisibleLevel then
  begin
    var Across: Single := FSize * FlashScale;
    DrawGlow(ACanvas.Renderer, ACanvas.PointGlow, AX, AY, Across, ArcColor,
      Light);
    DrawGlow(ACanvas.Renderer, ACanvas.PointGlow, AX, AY,
      Across * FlashCoreShare, White, Light);
  end;

  DrawPoint.X := AX;
  DrawPoint.Y := AY;
  FField.Draw(SparkBrush(ACanvas.Renderer, ACanvas.StreakGlow), DrawPoint,
    AAlpha);
end;

// ---------------------------------------------------------------------------
// TLightning
// ---------------------------------------------------------------------------

function ReadSpread(AObj: TJSONObject; const AOwner: string): TSdlFPoint;
begin
  Result.X := DefaultSpreadX;
  Result.Y := DefaultSpreadY;
  var Raw := AObj.GetValue('spread');
  if Raw = nil then
    Exit;

  var Valid := (Raw is TJSONArray) and (TJSONArray(Raw).Count = 2);
  if Valid then
    Valid := (TJSONArray(Raw).Items[0] is TJSONNumber) and
      (TJSONArray(Raw).Items[1] is TJSONNumber);
  if Valid then
  begin
    Result.X := TJSONNumber(TJSONArray(Raw).Items[0]).AsDouble;
    Result.Y := TJSONNumber(TJSONArray(Raw).Items[1]).AsDouble;
    Valid := (Result.X >= 0) and (Result.Y >= 0);
  end;
  if not Valid then
    raise EDynamicError.CreateFmt(SLightningBadSpread, [AOwner]);
end;

function ReadLightningLook(AObj: TJSONObject; ALayer: TDynamicLayer;
  const AOwner: string): TLightningLook;
begin
  Result.Reach := ReadPositive(AObj, 'reach', DefaultReach, AOwner);
  Result.Spread := ReadSpread(AObj, AOwner);
  Result.Angle := AObj.GetValue<Double>('angle', DefaultBoltAngle);
  Result.Cone := ReadReach(AObj, 'cone', DefaultBoltCone, AOwner);

  var LayerCollide := lcNone;
  if ALayer = dlFront then
    LayerCollide := lcStrike;
  Result.Collide := TLightningCollide(ReadWord(AObj, 'collide',
    LightningCollideIds[LayerCollide], LightningCollideIds, 'collide',
    AOwner));

  Result.Size := ReadPositive(AObj, 'size', DefaultBoltSize, AOwner);
  Result.Jag := ReadShare(AObj, 'jag', DefaultJag, AOwner);
  Result.Fork := ReadShare(AObj, 'fork', DefaultBoltFork, AOwner);
  Result.Frequency := ReadPositive(AObj, 'frequency', DefaultBoltFrequency,
    AOwner);
  Result.Strokes := AObj.GetValue<Integer>('strokes', DefaultStrokes);
  if (Result.Strokes < 1) or (Result.Strokes > MaxBoltStrokes) then
    raise EDynamicError.CreateFmt(SLightningBadStrokes,
      [AOwner, MaxBoltStrokes]);
  Result.Life := ReadPositive(AObj, 'life', DefaultBoltLife, AOwner);
  Result.Leader := ReadReach(AObj, 'leader', 0, AOwner);
  Result.Spell := ReadPositive(AObj, 'spell', DefaultSpell, AOwner);
  Result.Pause := ReadReach(AObj, 'pause', 0, AOwner);
  Result.Flash := ReadShare(AObj, 'flash', DefaultBoltFlash, AOwner);
  Result.Jolt := ReadShare(AObj, 'jolt', 0, AOwner);
  Result.Tint := ReadTintOrDefault(AObj, 'tint', LightningTint, AOwner);
end;

constructor TLightning.Create(const APlacement: TDynamicPlacement;
  AObj: TJSONObject; const AOwner: string);
begin
  inherited Create(APlacement, AObj, AOwner);
  TakeLook(ReadLightningLook(AObj, APlacement.Layer, AOwner),
    PlacementSeed(APlacement));
end;

constructor TLightning.CreateLook(const APlacement: TDynamicPlacement;
  const ALook: TLightningLook; AIntensity: Single; ASeed: Cardinal);
begin
  inherited Create(APlacement, AIntensity);
  TakeLook(ALook, ASeed);
end;

destructor TLightning.Destroy;
begin
  FField.Free;
  inherited;
end;

procedure TLightning.TakeLook(const ALook: TLightningLook; ASeed: Cardinal);
begin
  FLook := ALook;
  FBolt.Width := ALook.Size;
  FBolt.Jag := ALook.Jag;
  FBolt.ForkChance := ALook.Fork;
  FBolt.Flash := ALook.Flash;
  FBolt.Jolt := ALook.Jolt;
  FBolt.LifeTicks := Max(1, Round(ALook.Life * LogicTicksPerSecond));
  FBolt.LeaderTicks := Round(ALook.Leader * LogicTicksPerSecond);
  FBolt.Strokes := ALook.Strokes;
  FBolt.Tint := TintColor(ALook.Tint);

  FRandom.Seed := ASeed or 1;
  FField := TBoltField.Create(BoltCapacity, ASeed xor BoltSeedSalt);
  FGap := LogicTicksPerSecond / ALook.Frequency;
  // Sources seeded apart strike apart
  FWait := FGap * FRandom.NextUnit;
  FRest.Spell := ALook.Spell * LogicTicksPerSecond;
  FRest.Pause := ALook.Pause * LogicTicksPerSecond;
end;

procedure TLightning.Acquire(const ACanvas: TDynamicCanvas);
begin
  FSolid := ACanvas.Solid;
end;

procedure TLightning.UseSolid(const ASolid: TSolidProbe);
begin
  FSolid := ASolid;
end;

procedure TLightning.Rewind;
begin
  inherited;
  FField.Clear;
  FRest.Awake := False;
  FRest.TicksLeft := 0;
end;

// The field counts from the point the bolts leave, the probe from the
// corner of the screen
function TLightning.Blocked(AX, AY: Single): Boolean;
begin
  Result := Assigned(FSolid) and FSolid(FPoint.X + AX, FPoint.Y + AY);
end;

// Marches from (AX, AY) of the field along the unit vector (AHeadX,
// AHeadY) and says whether matter stands within AReach, and how far. Where
// it does not, ADistance is the whole of AReach, give or take a step.
function TLightning.FindMatter(AX, AY, AHeadX, AHeadY, AReach: Single;
  out ADistance: Single): Boolean;
begin
  ADistance := 0;
  for var Step := 1 to Trunc(AReach / MarchStep) do
  begin
    ADistance := Step * MarchStep;
    if Blocked(AX + AHeadX * ADistance, AY + AHeadY * ADistance) then
      Exit(True);
  end;
  Result := False;
end;

// The bolt as the intensity of the moment makes it
function TLightning.BoltLook: TBoltLook;
begin
  Result := FBolt;
  Result.Width := FBolt.Width *
    (FaintWidthShare + (1 - FaintWidthShare) * Intensity);
  var StrokeScale: Single :=
    FaintStrokeShare + (1 - FaintStrokeShare) * Intensity;
  Result.Strokes := Max(1, Round(FBolt.Strokes * StrokeScale));
end;

procedure TLightning.Discharge;
var
  Shot: TBoltShot;
begin
  Shot.RootX := (2 * FRandom.NextUnit - 1) * FLook.Spread.X;
  Shot.RootY := (2 * FRandom.NextUnit - 1) * FLook.Spread.Y;
  var Degrees: Single := FLook.Angle + (FRandom.NextUnit - 0.5) * FLook.Cone;
  var Heading: Single := DegToRad(Degrees);
  var HeadX: Single := Cos(Heading);
  var HeadY: Single := -Sin(Heading);
  var Reach: Single := FLook.Reach *
    (FaintReachShare + (1 - FaintReachShare) * Intensity) *
    (BoltLengthMin + BoltLengthSpread * FRandom.NextUnit);

  Shot.Ending := beBridge;
  var Span: Single := Reach;
  if FLook.Collide = lcStrike then
  begin
    Shot.Ending := beStrike;
    if not FindMatter(Shot.RootX, Shot.RootY, HeadX, HeadY, Reach, Span) then
    begin
      Shot.Ending := beStreamer;
      Span := Reach * StreamerShare;
    end;
  end;
  Shot.EndX := Shot.RootX + HeadX * Span;
  Shot.EndY := Shot.RootY + HeadY * Span;
  Shot.Seed := FRandom.Seed;
  FField.Shoot(Shot, BoltLook);
end;

procedure TLightning.Emit;
begin
  if FRest.Pause > 0 then
  begin
    // A spell opens with a bolt
    if FRest.Tick(FRandom) then
      FWait := 0;
    if not FRest.Awake then
      Exit;
  end;

  // The wait counts in ticks of full intensity: a source fading in or out
  // speeds up and slows down with it
  FWait := FWait - Intensity;
  if FWait > 0 then
    Exit;
  Discharge;
  FWait := FGap * (BoltGapMin + BoltGapSpread * FRandom.NextUnit);
end;

procedure TLightning.Advance(AMotionX, AMotionY: Single;
  AParentAlive: Boolean);
begin
  FPoint.X := Origin.X + Placement.X;
  FPoint.Y := Origin.Y + Placement.Y;
  FField.ShiftFrame(AMotionX, AMotionY);
  // Before the new bolt: it is drawn in its first tick, bloom and all
  FField.Tick;
  if AParentAlive and (Intensity > 0) then
    Emit;
end;

procedure TLightning.DrawAt(const ACanvas: TDynamicCanvas; AX, AY: Single;
  AAlpha: Single);
var
  DrawPoint: TSdlFPoint;
begin
  DrawPoint.X := AX;
  DrawPoint.Y := AY;
  FField.Draw(BoltBrush(ACanvas.Renderer, ACanvas.BeamGlow,
    ACanvas.PointGlow), DrawPoint, AAlpha);
end;

// ---------------------------------------------------------------------------
// TSkyGlobe
// ---------------------------------------------------------------------------

constructor TSkyGlobe.Create(const APlacement: TDynamicPlacement;
  AObj: TJSONObject; const AOwner: string);
begin
  inherited Create(APlacement, AObj, AOwner);
  FSize := ReadPositive(AObj, 'size', DefaultGlobeSize, AOwner);
  var Sun: Single := AObj.GetValue<Double>('sun', DefaultSun);
  FSun.Settle(Sun);
  FLitSun := Sun;
  FAltitude := AObj.GetValue<Double>('altitude', DefaultAltitude);
  if (FAltitude < 0) or (FAltitude > 90) then
    raise EDynamicError.CreateFmt(SDynamicBadAltitude, [AOwner]);
  FAzimuth := AObj.GetValue<Double>('azimuth', DefaultAzimuth);
  if (FAzimuth < -90) or (FAzimuth > 90) then
    raise EDynamicError.CreateFmt(SDynamicBadAzimuth, [AOwner]);
  FLongitude := AObj.GetValue<Double>('longitude', DefaultLongitude);
  FMapName := AObj.GetValue<string>('map', DefaultGlobeMap);
  FNightMapName := AObj.GetValue<string>('night', '');

  FLook := GlobeLook;
  FLook.Surface := TGlobeSurface(ReadWord(AObj, 'surface',
    GlobeSurfaceIds[gsMatte], GlobeSurfaceIds, 'surface', AOwner));
  FLook.AxisRoll := AObj.GetValue<Double>('tilt', 0);
  FLook.Exposure := GlobeLook.Exposure *
    ReadPositive(AObj, 'brightness', DefaultBrightness, AOwner) / 100;
  FLook.Atmosphere := ReadShare(AObj, 'atmosphere', DefaultAtmosphere,
    AOwner);
  FLook.NightGain := GlobeLook.NightGain *
    ReadPositive(AObj, 'nightBrightness', DefaultBrightness, AOwner) / 100;
end;

destructor TSkyGlobe.Destroy;
begin
  FGlobe.Free;
  inherited;
end;

procedure TSkyGlobe.Acquire(const ACanvas: TDynamicCanvas);
var
  MapName, NightMapName: string;
begin
  var MapSet := ACanvas.Art.SourceOf(FMapName, MapName);
  NightMapName := '';
  if FNightMapName <> '' then
  begin
    var NightSet := ACanvas.Art.SourceOf(FNightMapName, NightMapName);
    if NightSet <> MapSet then
      raise EDynamicError.CreateFmt(SGlobeSplitMaps,
        [FMapName, FNightMapName]);
  end;
  FGlobe := TGlobe.Create(ACanvas.Renderer, MapSet, MapName, NightMapName,
    FLook);
  FGlobe.Face(FLongitude);
  Relight;
end;

procedure TSkyGlobe.Release;
begin
  FreeAndNil(FGlobe);
end;

// The sun crosses the sky one way, left to right. An event replayed
// after a death - on its own screen or one the hero walked back to -
// asks for a sun already on its way or past: it keeps its course.
procedure TSkyGlobe.TurnSun(ADegrees: Single; ATicks: Integer);
begin
  if ADegrees <= FSun.Target then
    Exit;
  FSun.HeadFor(ADegrees, ATicks);
end;

procedure TSkyGlobe.Advance(AMotionX, AMotionY: Single; AParentAlive: Boolean);
begin
  FSun.Tick;
  if Abs(FSun.Current - FLitSun) >= RelightStep then
    Relight;
end;

// The sky as the screen shows it: x right, y up, w away from the
// viewer. The sun stands on the arc over the screen, (-cos s, sin s, 0);
// the globe at azimuth z and altitude a, (sin z cos a, sin a,
// cos z cos a). Seen from the globe - x right, y up, z back toward the
// viewer - that sun is (-cos s cos z, cos s sin z sin a + sin s cos a,
// cos s sin z cos a - sin s sin a).
procedure TSkyGlobe.Relight;
begin
  FLitSun := FSun.Current;
  if FGlobe = nil then
    Exit;
  var Sun: Double := DegToRad(FLitSun);
  var Altitude: Double := DegToRad(FAltitude);
  var Azimuth: Double := DegToRad(FAzimuth);
  var SunAlongBearing: Double := Cos(Sun) * Sin(Azimuth);
  FGlobe.LightFrom(-Cos(Sun) * Cos(Azimuth),
    SunAlongBearing * Sin(Altitude) + Sin(Sun) * Cos(Altitude),
    SunAlongBearing * Cos(Altitude) - Sin(Sun) * Sin(Altitude));
end;

procedure TSkyGlobe.DrawAt(const ACanvas: TDynamicCanvas; AX, AY: Single;
  AAlpha: Single);
begin
  if FGlobe = nil then
    Exit;
  FGlobe.Draw(FGlobe.DestFor(AX, AY, FSize), TintColor(Placement.Tint),
    Intensity);
end;

// ---------------------------------------------------------------------------
// TFan
// ---------------------------------------------------------------------------

function FanArtSideFor(ASize: Single): Integer;
begin
  for var Side in FanArtSides do
    if Side >= ASize * FanArtDensity then
      Exit(Side);
  Result := FanArtSides[High(FanArtSides)];
end;

// 0 up to AFrom, 1 from ATo, even between
function Ramp(AValue, AFrom, ATo: Single): Single;
begin
  if AValue <= AFrom then
    Exit(0);
  if AValue >= ATo then
    Exit(1);
  Result := (AValue - AFrom) / (ATo - AFrom);
end;

procedure DrawFanLayer(ARenderer: PSdlRenderer; ATexture: PSdlTexture;
  const APose: TFanPose; ALevel: Single);
begin
  if (ATexture = nil) or (ALevel < VisibleLevel) then
    Exit;
  // The pictures are shared: the next fan wears another tint
  TintTexture(ATexture, APose.Tint.R, APose.Tint.G, APose.Tint.B);
  SDL_SetTextureAlphaMod(ATexture, Round(255 * ALevel));
  SDL_RenderCopyExF(ARenderer, ATexture, nil, @APose.Dest, APose.Angle, nil,
    APose.Flip);
  // The static objects draw from the same cache and set no alpha
  SDL_SetTextureAlphaMod(ATexture, 255);
end;

constructor TFan.Create(const APlacement: TDynamicPlacement;
  AObj: TJSONObject; const AOwner: string);
begin
  inherited Create(APlacement, AObj, AOwner);
  FSize := ReadPositive(AObj, 'size', DefaultFanSize, AOwner);
  FRotorName := AObj.GetValue<string>('rotor', DefaultFanRotor);
  FGuardName := AObj.GetValue<string>('guard', '');
  FBackName := AObj.GetValue<string>('back', '');
  FRun := TMotorRun(ReadWord(AObj, 'run', MotorRunIds[mrSteady],
    MotorRunIds, 'run', AOwner));
  FLit := AObj.GetValue('light') <> nil;
  FLight := TintColor(ReadTint(AObj, AOwner, 'light'));

  FSeed := PlacementSeed(APlacement);
  var Rpm: Single := AObj.GetValue<Double>('rpm', DefaultFanRpm);
  FClockwise := Rpm < 0;
  var Detune: Single := 1 +
    SpeedDetune * (2 * SlotRoll(DetuneSlot, FSeed) - 1);
  FFullRate := Abs(Rpm) * RateOfRpm * Detune;
  Start;
end;

// A steady fan is already at speed; a dying one stands, on the edge of
// a catch
procedure TFan.Start;
begin
  FRandom.Seed := FSeed or 1;
  FMotor := Default(TMotorClock);
  FAngle := FullTurn * SlotRoll(PhaseSlot, FSeed);
  FLastAngle := FAngle;
  FRate := 0;
  if FRun = mrSteady then
    FRate := FFullRate * Intensity;
end;

procedure TFan.Rewind;
begin
  inherited;
  Start;
end;

procedure TFan.Acquire(const ACanvas: TDynamicCanvas);
begin
  var Side := FanArtSideFor(FSize);
  FArt.Sharp := ACanvas.Art.Get(Format(RotorSharpArt, [FRotorName, Side]));
  FArt.Smear := ACanvas.Art.Get(Format(RotorSmearArt, [FRotorName, Side]));
  FArt.Disc := ACanvas.Art.Get(Format(RotorDiscArt, [FRotorName, Side]));
  if FGuardName <> '' then
    FArt.Guard := ACanvas.Art.Get(Format(GuardArt, [FGuardName, Side]));
  if FBackName <> '' then
    FArt.Back := ACanvas.Art.Get(Format(BackArt, [FBackName, Side]));
end;

// The cache owns the textures
procedure TFan.Release;
begin
  FArt := Default(TFanArt);
end;

procedure TFan.TickMotor;
begin
  Dec(FMotor.TicksLeft);
  if FMotor.TicksLeft > 0 then
    Exit;

  FMotor.Running := not FMotor.Running;
  var Luck := FRandom.NextUnit;
  var Seconds: Single := StallMin + StallSpread * Luck;
  FMotor.Drive := 0;
  if FMotor.Running then
  begin
    Seconds := CatchMin + CatchSpread * Luck * Luck;
    FMotor.Drive := CatchFloor + (1 - CatchFloor) * FRandom.NextUnit;
  end;
  FMotor.TicksLeft := Max(1, Round(Seconds * LogicTicksPerSecond));
end;

procedure TFan.Advance(AMotionX, AMotionY: Single; AParentAlive: Boolean);
begin
  var Drive: Single := 1;
  if FRun = mrDying then
  begin
    TickMotor;
    Drive := FMotor.Drive;
  end;
  if not AParentAlive then
    Drive := 0;

  var Wanted: Single := FFullRate * Intensity * Drive;
  var Ease: Single := CoastEases[FRun];
  if Wanted > FRate then
    Ease := SpinUpEase;
  FRate := FRate + (Wanted - FRate) * Ease;
  if (Wanted = 0) and (FRate < StandstillRate) then
    FRate := 0;

  FLastAngle := FAngle;
  FAngle := FAngle + FRate;
  if FAngle >= FullTurn then
  begin
    var WholeTurns: Single := FullTurn * Trunc(FAngle / FullTurn);
    FAngle := FAngle - WholeTurns;
    FLastAngle := FLastAngle - WholeTurns;
  end;
end;

procedure TFan.DrawAt(const ACanvas: TDynamicCanvas; AX, AY: Single;
  AAlpha: Single);
var
  Standing, Turning: TFanPose;
begin
  Standing.Dest.X := AX - FSize / 2;
  Standing.Dest.Y := AY - FSize / 2;
  Standing.Dest.W := FSize;
  Standing.Dest.H := FSize;
  Standing.Tint := Placement.Tint;
  Standing.Angle := Upright;
  Standing.Flip := SdlFlipNone;

  Turning := Standing;
  var Angle := Lerp(FLastAngle, FAngle, AAlpha);
  // The art turns counterclockwise, SDL clockwise
  Turning.Angle := -Angle;
  if FClockwise then
  begin
    Turning.Angle := Angle;
    Turning.Flip := SdlFlipHorizontal;
  end;

  DrawFanLayer(ACanvas.Renderer, FArt.Back, Standing, FullLevel);
  if FLit then
    DrawGlow(ACanvas.Renderer, ACanvas.PointGlow, AX, AY,
      FSize * ShaftLightScale, FLight, FullLevel);

  var Rpm: Single := FRate / RateOfRpm;
  var SharpShare: Single := 1 - Ramp(Rpm, SharpUpToRpm, SmearedAtRpm);
  var DiscShare := Ramp(Rpm, SmearedAtRpm, DiscFromRpm);
  DrawFanLayer(ACanvas.Renderer, FArt.Disc, Turning, DiscShare);
  DrawFanLayer(ACanvas.Renderer, FArt.Smear, Turning,
    1 - SharpShare - DiscShare);
  DrawFanLayer(ACanvas.Renderer, FArt.Sharp, Turning, SharpShare);

  DrawFanLayer(ACanvas.Renderer, FArt.Guard, Standing, FullLevel);
end;

// ---------------------------------------------------------------------------
// THaze
// ---------------------------------------------------------------------------

// It follows from the point alone, as SlotRoll from its slot
function LatticeRoll(ACol, ARow: Integer; ASeed: Cardinal): TNoisePair;
const
  HalfRange = 1 shl (HalfBits - 1); // a half of the number over it runs 0..2
begin
  var Point: Cardinal := (Cardinal(ACol) and HalfMask) or
    (Cardinal(ARow) shl HalfBits);
  // Twice: after one pass points a bit apart still roll alike
  var Mixed: Cardinal := Scramble(Scramble(Point xor ASeed));
  Mixed := Mixed xor (Mixed shr HalfBits);
  Result.First := (Mixed and HalfMask) / HalfRange - 1;
  Result.Second := (Mixed shr HalfBits) / HalfRange - 1;
end;

function MixPairs(const AFrom, ATo: TNoisePair; AAmount: Single): TNoisePair;
begin
  Result.First := Lerp(AFrom.First, ATo.First, AAmount);
  Result.Second := Lerp(AFrom.Second, ATo.Second, AAmount);
end;

// Eased in and out between two lattice points: no crease on a lattice line
function EaseShare(AShare: Single): Single;
begin
  Result := AShare * AShare * (3 - 2 * AShare);
end;

// The points of every cell that holds an x of -AReach..AReach and a y of
// ANear..AFar, a cell being one unit a side
procedure TNoiseWindow.Roll(AReach, ANear, AFar: Double; ASeed: Cardinal);
begin
  FirstCol := Floor(-AReach);
  FirstRow := Floor(ANear);
  // A cell has a lattice line on its far side as well
  Cols := Floor(AReach) - FirstCol + 2;
  var Rows := Floor(AFar) - FirstRow + 2;
  SetLength(Rolls, Cols * Rows);
  for var Row := 0 to Rows - 1 do
    for var Col := 0 to Cols - 1 do
      Rolls[Row * Cols + Col] := LatticeRoll(FirstCol + Col, FirstRow + Row,
        ASeed);
end;

// Smooth noise at a point inside the cells rolled, two values at once
function TNoiseWindow.NoiseAt(AX, AY: Double): TNoisePair;
begin
  var Col := Floor(AX);
  var Row := Floor(AY);
  var ShareX := EaseShare(AX - Col);
  var ShareY := EaseShare(AY - Row);
  var Above := (Row - FirstRow) * Cols + Col - FirstCol;
  var Below := Above + Cols;
  var Upper := MixPairs(Rolls[Above], Rolls[Above + 1], ShareX);
  var Lower := MixPairs(Rolls[Below], Rolls[Below + 1], ShareX);
  Result := MixPairs(Upper, Lower, ShareY);
end;

constructor THaze.Create(const APlacement: TDynamicPlacement;
  AObj: TJSONObject; const AOwner: string);
begin
  inherited Create(APlacement, AObj, AOwner);
  // Over anything else it would paint the backdrop on top of it
  if APlacement.Layer <> dlBackdrop then
    raise EDynamicError.CreateFmt(SHazeLayer, [AOwner]);
  FLength := ReadPositive(AObj, 'length', DefaultHazeLength, AOwner);
  FMouth := ReadReach(AObj, 'mouth', DefaultHazeMouth, AOwner);
  FWidth := ReadPositive(AObj, 'width', DefaultHazeWidth, AOwner);
  FShift := ReadReach(AObj, 'shift', DefaultHazeShift, AOwner);
  FGrain := AObj.GetValue<Double>('grain', DefaultHazeGrain);
  if FGrain < MinHazeGrain then
    raise EDynamicError.CreateFmt(SHazeGrain, [AOwner]);
  FSpeed := ReadReach(AObj, 'speed', DefaultHazeSpeed, AOwner);
  FShade := ReadShare(AObj, 'shade', DefaultHazeShade, AOwner);
  FBlurs := AObj.GetValue<Boolean>('blur', True);
  // Counterclockwise from the right, and the screen's Y runs down
  var Angle := DegToRad(AObj.GetValue<Double>('angle', DefaultHazeAngle));
  FFlow.X := Cos(Angle);
  FFlow.Y := -Sin(Angle);
  FSeed := PlacementSeed(APlacement);
  BuildMesh;
end;

// Rows of knots across the plume, from the point to the far end; every
// row spans the plume's width there, so no knot lies outside it
procedure THaze.BuildMesh;
begin
  var Rows := Max(1, Ceil(FLength / HazeRowLength));
  var KnotsInRow := HazeColumns + 1;
  SetLength(FKnots, KnotsInRow * (Rows + 1));
  SetLength(FPushes, Length(FKnots));
  SetLength(FVertices, Length(FKnots));
  for var Row := 0 to Rows do
  begin
    var Share: Single := Row / Rows;
    var Rest: Single := 1 - Share;
    var HalfWidth := (FMouth + (FWidth - FMouth) * Power(Share, HazeFlare)) / 2;
    var AlongGrip := EnsureRange(Share / HazeOnsetShare, 0.0, 1.0) *
      Power(Rest, HazeFadePower);
    for var Col := 0 to HazeColumns do
    begin
      // -1 on one rim, 1 on the other
      var Side: Single := Col / HazeColumns * 2 - 1;
      var Index := Row * KnotsInRow + Col;
      FKnots[Index].Across := Side * HalfWidth;
      FKnots[Index].Along := Share * FLength;
      FKnots[Index].Grip := EaseShare(1 - Abs(Side)) * AlongGrip;
      FReach := Max(FReach, Abs(FKnots[Index].Across));
    end;
  end;

  // Two triangles a cell
  SetLength(FIndices, HazeColumns * Rows * 6);
  var Next := 0;
  for var Row := 0 to Rows - 1 do
    for var Col := 0 to HazeColumns - 1 do
    begin
      var ThisRow := Row * KnotsInRow + Col;
      var NextRow := ThisRow + KnotsInRow;
      FIndices[Next] := ThisRow;
      FIndices[Next + 1] := ThisRow + 1;
      FIndices[Next + 2] := NextRow;
      FIndices[Next + 3] := ThisRow + 1;
      FIndices[Next + 4] := NextRow + 1;
      FIndices[Next + 5] := NextRow;
      Inc(Next, 6);
    end;
end;

procedure THaze.Advance(AMotionX, AMotionY: Single; AParentAlive: Boolean);
begin
  Inc(FTicks);
end;

// The noise of every layer at every knot, carried along the flow: at
// ASeconds a layer has run its speed times that, away from the point
procedure THaze.RollPushes(ASeconds: Double);
var
  Window: TNoiseWindow;
begin
  for var i := 0 to High(FPushes) do
  begin
    FPushes[i].X := 0;
    FPushes[i].Y := 0;
  end;

  // The rows of knots run from the point, so the last knot is the farthest
  var Farthest := FKnots[High(FKnots)].Along;
  for var Layer in HazeLayers do
  begin
    var Grain: Double := FGrain * Layer.GrainShare;
    var Run := FSpeed * Layer.SpeedShare * ASeconds / Grain;
    // Double all the way: hours of play run the flow far past what a
    // Single tells apart
    var Flowed: Double := Frac(Run / NoiseRows) * NoiseRows;
    // The edges are spelled as the knots' own places below: a knot on
    // the edge of the window must not round out of it
    Window.Roll(FReach / Grain, -Flowed, Farthest / Grain - Flowed,
      FSeed xor Layer.Salt);
    for var i := 0 to High(FKnots) do
    begin
      var Noise := Window.NoiseAt(FKnots[i].Across / Grain,
        FKnots[i].Along / Grain - Flowed);
      FPushes[i].X := FPushes[i].X + Noise.First * Layer.Weight;
      FPushes[i].Y := FPushes[i].Y + Noise.Second * Layer.Weight;
    end;
  end;
end;

// Every knot where the plume puts it on the screen, showing the point of
// the backdrop its push has moved there. The blur copy is pushed a
// quarter turn round from the sharp one and is part clear. In the depth
// the plume and its pushes are smaller by the canvas' Scale, the pushes
// and the shade weaker by its Tone.
procedure THaze.PlaceVertices(const ACanvas: TDynamicCanvas; AX, AY: Single;
  ACopy: THazeCopy);
begin
  var Backdrop := ACanvas.Backdrop;
  var Tint := TintColor(Backdrop.Tint);
  var Alpha: UInt8 := 255;
  if ACopy = hcBlur then
    Alpha := Round(255 * HazeBlurOpacity);

  for var i := 0 to High(FKnots) do
  begin
    var Knot := FKnots[i];
    var Strength := Knot.Grip * Intensity * ACanvas.Tone;
    var PushAcross := FPushes[i].X;
    var PushAlong := FPushes[i].Y;
    if ACopy = hcBlur then
    begin
      PushAcross := FPushes[i].Y;
      PushAlong := -FPushes[i].X;
    end;
    var HomeAcross := Knot.Across * ACanvas.Scale;
    var HomeAlong := Knot.Along * ACanvas.Scale;
    var Across := HomeAcross + PushAcross * FShift * Strength * ACanvas.Scale;
    var Along := HomeAlong +
      PushAlong * FShift * HazeAlongShare * Strength * ACanvas.Scale;

    // Across runs a quarter turn from the flow: (Flow.Y, -Flow.X)
    FVertices[i].Position.X := AX + FFlow.X * HomeAlong + FFlow.Y * HomeAcross;
    FVertices[i].Position.Y := AY + FFlow.Y * HomeAlong - FFlow.X * HomeAcross;
    var SeenX := AX + FFlow.X * Along + FFlow.Y * Across;
    var SeenY := AY + FFlow.Y * Along - FFlow.X * Across;
    FVertices[i].TexCoord.X := EnsureRange(SeenX / Backdrop.Width, 0.0, 1.0);
    FVertices[i].TexCoord.Y := EnsureRange(SeenY / Backdrop.Height, 0.0, 1.0);

    var Light := 1 - FShade * Strength;
    FVertices[i].Color.R := Round(Tint.R * Light);
    FVertices[i].Color.G := Round(Tint.G * Light);
    FVertices[i].Color.B := Round(Tint.B * Light);
    FVertices[i].Color.A := Alpha;
  end;
end;

procedure THaze.DrawAt(const ACanvas: TDynamicCanvas; AX, AY: Single;
  AAlpha: Single);
var
  BlendMode: Integer;
begin
  var Backdrop := ACanvas.Backdrop;
  if (Backdrop.Texture = nil) or (Intensity <= 0) then
    Exit;

  RollPushes((FTicks + AAlpha) / LogicTicksPerSecond);
  BlendMode := SdlBlendModeNone;
  // The blur copy is part clear, and a backdrop without an alpha channel
  // is drawn with no blending at all
  SDL_GetTextureBlendMode(Backdrop.Texture, @BlendMode);
  SDL_SetTextureBlendMode(Backdrop.Texture, SdlBlendModeBlend);
  PlaceVertices(ACanvas, AX, AY, hcSharp);
  SDL_RenderGeometry(ACanvas.Renderer, Backdrop.Texture, @FVertices[0],
    Length(FVertices), @FIndices[0], Length(FIndices));
  if FBlurs then
  begin
    PlaceVertices(ACanvas, AX, AY, hcBlur);
    SDL_RenderGeometry(ACanvas.Renderer, Backdrop.Texture, @FVertices[0],
      Length(FVertices), @FIndices[0], Length(FIndices));
  end;
  SDL_SetTextureBlendMode(Backdrop.Texture, BlendMode);
end;

// ---------------------------------------------------------------------------
// Parsing
// ---------------------------------------------------------------------------

function KindOf(const AId, ALevelId, AWhere: string): TDynamicKind;
begin
  for var Kind := Low(TDynamicKind) to High(TDynamicKind) do
    if SameText(AId, DynamicKindIds[Kind]) then
      Exit(Kind);
  raise EDynamicError.CreateFmt(SDynamicBadKind, [ALevelId, AWhere, AId]);
end;

function ScreenNumber(AValue: TJSONValue; const AOwner: string): Integer;
begin
  if not (AValue is TJSONNumber) then
    raise EDynamicError.CreateFmt(SDynamicBadScreens, [AOwner]);
  Result := TJSONNumber(AValue).AsInt;
end;

// "screens": [first, last]; False when the object names none
function ReadScreens(AObj: TJSONObject; const AOwner: string;
  out AFirst, ALast: Integer): Boolean;
begin
  AFirst := 0;
  ALast := 0;
  var Raw := AObj.GetValue('screens');
  if Raw = nil then
    Exit(False);
  if not (Raw is TJSONArray) or (TJSONArray(Raw).Count <> 2) then
    raise EDynamicError.CreateFmt(SDynamicBadScreens, [AOwner]);
  AFirst := ScreenNumber(TJSONArray(Raw).Items[0], AOwner);
  ALast := ScreenNumber(TJSONArray(Raw).Items[1], AOwner);
  Result := True;
end;

function ReadPlacement(AObj: TJSONObject; const ALevelId, AOwner: string;
  ADefaultLayer: TDynamicLayer): TDynamicPlacement;
var
  First, Last: Integer;
begin
  Result := Default(TDynamicPlacement);
  Result.Parent := AObj.GetValue<string>('parent', '');
  var HasScreen := AObj.TryGetValue<Integer>('screen', Result.Screen);
  var HasScreens := ReadScreens(AObj, AOwner, First, Last);
  var Places := Ord(Result.Parent <> '') + Ord(HasScreen) + Ord(HasScreens);
  if Places = 0 then
    raise EDynamicError.CreateFmt(SDynamicNoPlace, [ALevelId, AOwner]);
  if Places > 1 then
    raise EDynamicError.CreateFmt(SDynamicTwoPlaces, [ALevelId, AOwner]);
  Result.LastScreen := Result.Screen;
  if HasScreens then
  begin
    Result.Screen := First;
    Result.LastScreen := Last;
  end;

  Result.X := AObj.GetValue<Double>('x');
  Result.Y := AObj.GetValue<Double>('y');
  Result.Tint := ReadTint(AObj, AOwner);
  Result.Tag := AObj.GetValue<string>('tag', '');
  Result.Layer := TDynamicLayer(ReadWord(AObj, 'layer',
    DynamicLayerIds[ADefaultLayer], DynamicLayerIds, 'layer', AOwner));
  Result.Turns := AObj.GetValue<Boolean>('turns', False);
  if Result.Turns and (Result.Parent = '') then
    raise EDynamicError.CreateFmt(SDynamicTurnsNailed, [ALevelId, AOwner]);
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
    dkGlobe:
      Result := TSkyGlobe.Create(APlacement, AObj, AOwner);
    dkSparks:
      Result := TSparks.Create(APlacement, AObj, AOwner);
    dkFan:
      Result := TFan.Create(APlacement, AObj, AOwner);
    dkHaze:
      Result := THaze.Create(APlacement, AObj, AOwner);
    dkLightning:
      Result := TLightning.Create(APlacement, AObj, AOwner);
  else
    raise EDynamicError.CreateFmt(SDynamicKindUnbuilt,
      [DynamicKindIds[AKind]]);
  end;
end;

function ParseDynamic(AObj: TJSONObject;
  const ALevelId, AWhere: string): TDynamicObject;
begin
  var Kind := KindOf(AObj.GetValue<string>('kind', ''), ALevelId, AWhere);
  // "beacon #2" - dynamic objects carry no id of their own
  var Owner := Format('%s %s', [DynamicKindIds[Kind], AWhere]);
  var Placement := ReadPlacement(AObj, ALevelId, Owner, DefaultLayers[Kind]);
  Result := CreateDynamic(Kind, Placement, AObj, Owner);
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
      Result.Add(ParseDynamic(DynamicsArr.Items[i] as TJSONObject, ALevelId,
        Format('#%d', [i + 1])));
  except
    Result.Free;
    raise;
  end;
end;

end.
