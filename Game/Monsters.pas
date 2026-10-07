{
  Monsters - monsters, ported from monst.pas (2008 release) onto the
  data-driven definitions of Monsters.Defs. The fourteen 'if typ =' string
  ladders of the original became dispatch over two enums:

    Movement.Kind: mkPatrol (turns at walls AND ledges - CanIGoLeft1),
      mkPatrolNoEdgeCheck (walls only - CanIGoLeft2), mkChaseHero
      (Vinter follows the hero's X), mkStatic, mkBossFly (the lap of
      Monsters.Pilot).

    Attack.Pattern: apStraightSingle (+ the tank's 5-bullet cross),
      apAimedSingle (boss arccos aim), apAimedDouble (+16 offset),
      apRainVolley (7 bullets straight down, 4 units apart).

  Deaths: a dying monster keeps sliding at Shag/3 and plays frames
  9..16 (CurrentSprite + 8*DeathType); a dead one lies as frame 16.
  Barrels, tanks, platforms and mounts explode TWICE - a 10x18
  fragment fan into the enemy burst (Damage) and another into the
  hero's burst (main loop) - 360 fragments, both friendly and hostile,
  exactly as shipped in the original.

  Boss extras carried over: minion requests on a timer, HENSHIN at 2/3
  lives (turns the HERO into ice form), rage (speed x2, music change, a
  24x44 fragment wave), victory double-fan. The rage is longer and
  calmer than in 2008: it starts under 120 lives on the normal grade,
  not 80 on every grade - the mark grows with the difficulty as the
  lives do - and the gun fires no faster in it (2008: three times as
  fast).

  A machine - a monster that explodes and moves: the tank, the flying
  platform - smokes and sparks once it is down to its last third, and
  shorts out in bolts that come harder with every life it loses (a 2026
  addition). An explosive prop - the barrel - vents a wisp of smoke all
  its life and a plume in that last third (a 2026 addition too).

  A pad (Levels.Pads, a 2026 addition) is floor the grid does not know:
  the floor half of the edge-aware oracles and the pull of gravity also
  ask for a deck under the feet, and a fall lands on a deck it came down
  onto. A walker's walls stay the grid's alone. A deck that travels takes
  whatever lies on it along - the dead too.

  The boss flies by Monsters.Pilot: the lap and, by the tactics the
  level's events set, the maneuvers off it (a 2026 addition). The aimed
  gun fires on the lap alone, and not while the lap is held: in a
  maneuver the disc fires its ports where it ponders, and nothing else.
  A ram ended in a wall and the prize a dodged one owes go out as events.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Monsters;
{$I ..\Moon2D.inc}

interface

uses
  System.SysUtils, System.IOUtils, System.Math,
  System.Generics.Collections,
  Sdl2.Core, Render.Sprites, Sprites.Sets, Game.Config, Game.Space, Levels.Defs,
  Levels.Dynamics, Levels.Tint, Monsters.Defs, Monsters.Disc, Monsters.Pilot,
  Bullets, Pads.World;

type
  TMonsterAction = (maStand, maWalkLeft, maWalkRight, maFalling, maFlying);

  TMonsterLife = (mlAlive, mlDying, mlDead);

  // Requests a monster cannot fulfil itself ('MessageToMain' of 2008);
  // the game loop drains these each tick.
  TMonsterEvent = (meNone, meBossWantsMinion, meHenshin, meBossRage,
    meLevelComplete, meDied, meBossCrashed, meBossOwesPrize);

  // Thirds of full health, the crosshair's language
  TMonsterHealthTier = (htHale, htWounded, htCritical);

  // A body's smoke: the look, the point where it leaves the left-facing
  // art, how thick it stands before the last third and in it (0..1), and
  // the ticks the change takes
  TBodySmoke = record
    Look: TSmokeLook;
    Tint: TColorTint;
    X, Y: Integer;
    Level, CriticalLevel: Single;
    RampTicks: Integer;
  end;

  TMonster = class
  private
    FDef: TMonsterDef;
    FAnim: TAnimSet;
    FX, FY: Double;
    FScreen: Integer;
    FTag: string; // the placement's tag, '' for most; the events read it
    FDirection: Boolean; // True = right
    FAction: TMonsterAction;
    FLife: TMonsterLife;
    FLives: Integer;
    FLivesAll: Integer;
    FCurrentSprite: Double;
    FStep: Integer;          // 'Shag', with placement override applied
    FAcceleration: Double;
    FTimeOfFire: Integer;
    FCanShoot: Boolean;
    FEnraged: Boolean;       // 'BeforeSpeedUp'
    // meHenshin is a one-shot; the event list drains every tick, so it
    // cannot remember what was already sent - this flag can
    FHenshinSent: Boolean;
    FTicksSinceHit: Integer; // NeverHit until the first hit
    FFireEveryTicks: Integer;
    FBossMinionTimer: Integer;
    FSecret: Boolean;
    FEvents: TList<TMonsterEvent>;
    FLevel: TLevel;
    FPads: TPadWorld;
    FHeroX, FHeroY: Integer;
    FSmoke: TSmoke; // machines and explosive props, nil for the rest
    FBodySmoke: TBodySmoke; // what FSmoke was made by
    FSparks: TSparks; // machines only, nil for the rest
    FShort: TLightning; // machines only, nil for the rest
    FWrecked: Boolean; // the smoke stands at its critical level, sparks fly, bolts strike
    FDisc: TDisc; // a disc monster only, nil for the rest
    FPilot: TPilot; // an mkBossFly monster only, nil for the rest
    FLivesBorn: Integer; // the disc's wear counts from here; rage resets FLivesAll
    FRageLives: Integer; // a boss goes into its rage below this
    FFired: Boolean; // this tick

    function Solid(ACol, ARow: Integer): Boolean;
    function CellOfX(APixel: Integer): Integer;
    function CellOfY(APixel: Integer): Integer;
    // The floor under the feet in the cell ahead: the grid's, or a deck
    // spanning AX, the inset edge the oracle looks at
    function FloorAhead(ACol: Integer; AX: Double): Boolean;
    function StandsOnDeck: Boolean;
    procedure RideDeck;
    procedure CarryX(AWay: Double);
    function CanGoLeftEdgeAware: Boolean;   // CanIGoLeft1
    function CanGoRightEdgeAware: Boolean;  // CanIGoRight1
    function CanGoLeftWallOnly: Boolean;    // CanIGoLeft2
    function CanGoRightWallOnly: Boolean;   // CanIGoRight2
    function CanGoDown: Boolean;
    function ShoveBlocked(AStep: Integer): Boolean;
    procedure ShoveX(ADeltaX: Integer);
    procedure FireAt(const ABullets: TBurst);
    procedure FirePorts(const ABullets: TBurst);
    function PilotBusy: Boolean;
    function PilotHoldsGun: Boolean;
    procedure AdvanceFrame;
    procedure PatrolStep(ACanLeft, ACanRight: Boolean);
    procedure MoveWalking;
    procedure MoveFalling;
    procedure MoveFlying;
    procedure EnrageTankIfLow;
    procedure ProcessBossThresholds(const AEnemyBullets: TBurst);
    procedure BeginDying(const AEnemyBullets: TBurst);
    function ThirdMark(AThirds: Integer): Integer;
    function FacesRight: Boolean;
    function BodyPoint(AArtX, AArtY: Integer): TSdlFPoint;
    function SpawnSeed: Cardinal;
    procedure CreateSmoke(const ABodySmoke: TBodySmoke);
    procedure CreateWreckSparks;
    procedure CreateWreckShort;
    function SolidUnderPoint(AX, AY: Single): Boolean;
    procedure WreckIfCritical;
    procedure TickSmoke;
    procedure TickSparks;
    procedure TickShort;
    procedure TickDisc;
    function EyeTarget: TSdlFPoint;
    function DiscCenter: TSdlFPoint;
    function DiscWear: Single;
    function DiscCharge: Single;
  public
    // ADiscArt - the layers of a disc monster, nil for the rest; the
    // caller keeps it and APads alive longer than the monster
    constructor Create(const ADef: TMonsterDef; const AAnim: TAnimSet;
      ADiscArt: TDiscArt; const ALevel: TLevel; const APads: TPadWorld;
      const APlacement: TEntityPlacement; ALivesScale: Double);
    destructor Destroy; override;

    // One logic tick (33 Hz - the REAL rate of the 2008 20 ms timer).
    // AHeroX/AHeroY feed the chasers and aimers; enemy bullets go into
    // ABullets (the shared monster burst).
    procedure Tick(AHeroX, AHeroY: Integer; const ABullets: TBurst);
    // AAlpha in [0..1): how far toward the next tick - only the disc
    // draws between ticks, the frames stay on them
    procedure Draw(const ASprites: TSpriteRenderer; AAlpha: Single);
    procedure DrawSmoke(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
      AAlpha: Single);
    procedure DrawSparks(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
      AAlpha: Single);
    // Applies knockback through the wall oracle; queues explosion fans
    // and events.
    procedure TakeDamage(AKnockDx, ALosses: Integer;
      const AEnemyBullets: TBurst);
    function DrainEvent: TMonsterEvent;
    // A flying boss takes them up; the rest have no pilot to tell
    procedure SetTactics(ATactics: TPilotTactics);
    // The game has seen this body touch the hero
    procedure NoteHeroContact;
    // Asked on meBossCrashed, which only a piloted monster sends
    function LastCrash: TPilotCrash;
    // The lap of a flying boss (Monsters.Pilot); the rest fly no lap:
    // nothing to hold, never on one, none ahead
    procedure HoldLap(AHold: Boolean);
    function FliesLap: Boolean;
    function LapAhead(ATicks: Integer): TArray<TLapStep>;
    function HealthTier: TMonsterHealthTier;
    // How full the current third is, 0..1
    function TierShare: Single;
    // Units down the picture is drawn: the bob and the sag of the deck
    // underfoot; AAlpha as the deck's Lift
    function DeckLift(AAlpha: Single): Single;
    function HitWithin(ATicks: Integer): Boolean;

    property Def: TMonsterDef read FDef;
    property X: Double read FX;
    property Y: Double read FY;
    property Screen: Integer read FScreen;
    property Tag: string read FTag;
    property Life: TMonsterLife read FLife;
    property Lives: Integer read FLives;
    property LivesAll: Integer read FLivesAll;
    property Enraged: Boolean read FEnraged;
    property Direction: Boolean read FDirection;
    property TicksSinceHit: Integer read FTicksSinceHit;
    property Disc: TDisc read FDisc;
  end;

  TMonsterField = class
  private
    FMonsters: TObjectList<TMonster>;
    FAnimSets: TDictionary<string, TAnimSet>; // .mns name -> frames
    // One set and one cache per monster, both owned here.
    FSpriteSets: TObjectList<TSpriteSet>;
    FSetCaches: TObjectList<TSpriteCache>;
    FDiscArts: TObjectDictionary<string, TDiscArt>; // set name -> layers
    FRenderer: PSdlRenderer;
    FRegistry: TMonsterRegistry;
    FLevel: TLevel;
    FPads: TPadWorld;
    // The difficulty multiplier of FindMostersOnScreen (moon.dpr
    // 1092-1094): every monster born in this field - placed or
    // sky-dropped - gets its lives scaled by it
    FLivesScale: Double;
    function SpawnAt(const AMonsterId: string;
      AScreen, APlacementX, APlacementY: Integer): TMonster;
    function AnimFor(const AMnsName: string): TAnimSet;
    function DiscArtFor(const ADef: TMonsterDef): TDiscArt;
  public
    // APads must outlive the field
    constructor Create(const ARenderer: PSdlRenderer;
      const ARegistry: TMonsterRegistry; const ALevel: TLevel;
      const APads: TPadWorld; ADifficulty: TDifficulty; ALivesScale: Double);
    destructor Destroy; override;

    procedure Tick(AScreen, AHeroX, AHeroY: Integer;
      const ABullets: TBurst);
    // AddMonstOnBoss1 verbatim: a random minion at cell (random(15)+1, 1)
    // - the top edge of the boss screen; gravity does the dramatic entry.
    procedure SpawnFromSky(const AMonsterId: string; AScreen: Integer);
    // On the very place of a body at AX, AY: a prize put into the
    // hero's hands - the contact of the same tick collects it
    procedure SpawnOn(const AMonsterId: string; AScreen: Integer;
      AX, AY: Double);
    // 'ExistLive' of monst.pas as the breakthrough gate: ANY live body
    // on the screen counts, pickups included - the 2008 check did not
    // discriminate by category (or did - monst.pas knows; the verbatim
    // reading is kept: the trial medkits lie on the floor by the entry
    // and get trampled in the chaos anyway).
    function AnyAliveOnScreen(AScreen: Integer): Boolean;
    // Any live body carrying the placement tag, on any screen - the
    // events' allDead condition asks here
    function AnyAliveTagged(const ATag: string): Boolean;
    // The events' livesBelow and enraged conditions ask here
    function AnyTaggedLivesBelow(const ATag: string; ALives: Integer): Boolean;
    function AnyTaggedEnraged(const ATag: string): Boolean;
    // The events' tactics action lands here
    procedure SetTaggedTactics(const ATag: string; ATactics: TPilotTactics);
    // The first live body carrying the placement tag; nil when none
    function FirstAliveTagged(const ATag: string): TMonster;
    procedure Draw(const ASprites: TSpriteRenderer; AScreen: Integer;
      AAlpha: Single);
    // Over the monsters of the screen: the smoke of the wrecked machines
    // and of the barrels
    procedure DrawSmoke(const ACanvas: TDynamicCanvas; AScreen: Integer;
      AOrigin: TSdlPoint; AAlpha: Single);
    // Over the smoke: the sparks of the machines
    procedure DrawSparks(const ACanvas: TDynamicCanvas; AScreen: Integer;
      AOrigin: TSdlPoint; AAlpha: Single);

    property Monsters: TObjectList<TMonster> read FMonsters;
  end;

implementation

uses
  Effects.Sparks;

function RoundHalfUp(AValue: Double): Integer;
begin
  Result := Trunc(AValue + 0.5);
end;

const
  MonsterBound = 8;
  // The grid asks for the cell an inset edge of the body stands in; a
  // deck is asked for the point half a unit inside that edge - on whole
  // units the two answers agree at a deck's ends too
  DeckEdgeInset = 0.5;
  SpriteResetThreshold = 8.7;
  // Patrol turns AT the right edge, not beyond it
  PatrolRightLimit = ScreenWidth - SpriteSize; // 480
  TankRageLives = 20;      // cluster5 shooters double up below this
  // The boss goes berserk below this many lives on the normal grade; the
  // mark grows with the difficulty as the lives do. 2008 had 80 on every
  // grade: the rage, the best of the fight, was its shortest part and
  // the one part a harder grade did not lengthen.
  BossRageLives = 120;
  // The aimed gun fires this many times as often in the rage. 2008 had
  // 3 - a shot every 6 ticks; here the rage presses with its rams and
  // the rebuilt arena, and 1 keeps the gun as it was before the rage.
  BossRageFireRate = 1;
  EnragedMinionTicks = 100; // rage shortens the reinforcement interval
  NeverHit = -1;

  // Texture pixels, 2 a unit; a frame wider than this is HD art
  Frame2008Side = 64;

  // A wrecked machine smokes like the boss before his rage (bossSmoke of
  // level 1 at 60%, but straight up - the point mirrors with the art):
  // enough to notice, not enough to hide the fight. Unlit until the last
  // third. The point: the tank's engine deck, the platform's wing root.
  WreckSmoke: TBodySmoke = (
    Look: (Rate: 50; Life: 1.0; Size: 7; EndSize: 26;
      Opacity: 0.7; Angle: 90; Cone: 90; Speed: 6; Drag: 0.2; Lift: 0;
      Wind: 0; Turbulence: 3; Spin: 50; Flow: sfGusty; Frequency: 1.5;
      Heat: 0; EndTint: (R: 72; G: 72; B: 74));
    Tint: (R: 58; G: 57; B: 56);
    X: 22; Y: 13;
    Level: 0; CriticalLevel: 0.6; RampTicks: 33);

  // A barrel vents: a pale wisp all its life, a plume in the last third.
  // Thin on purpose - barrels stand in rows. The point: the cap of the
  // relief valve.
  BarrelSmoke: TBodySmoke = (
    Look: (Rate: 18; Life: 1.6; Size: 2.5; EndSize: 14;
      Opacity: 0.45; Angle: 90; Cone: 30; Speed: 7; Drag: 0.2; Lift: 3;
      Wind: 0; Turbulence: 2; Spin: 40; Flow: sfGusty; Frequency: 0.8;
      Heat: 0; EndTint: (R: 60; G: 62; B: 68));
    Tint: (R: 80; G: 82; B: 86);
    X: 21; Y: 1;
    Level: 0.4; CriticalLevel: 1; RampTicks: 16);

  // A wrecked machine shorts out: a crackle of sparks now and then, few
  // between
  WreckSparks: TSparkSourceLook = (Rate: 2; Burst: 5; Frequency: 0.7;
    Spell: 0; Pause: 0;
    Life: 0.5; Speed: 80; Angle: -90; Cone: 140; Gravity: 200; Drag: 0.85;
    Size: 2.2; Opacity: 1; Flash: 0.55; Fork: 0.25; Wall: swBounce;
    MidTint: (R: 100; G: 66; B: 27); EndTint: (R: 69; G: 14; B: 6));
  WreckSparksLevel = 1;
  WreckSparksRampTicks = 0; // a short has no ramp
  // Where the sparks leave the left-facing art: the tank's hull over
  // the tracks, the underside of the platform's wing
  WreckSparksX = 12;
  WreckSparksY = 19;
  WreckSparksSeedSalt = $57726B21; // "Wrk!"

  WreckShort: TLightningLook = (Reach: 16; Spread: (X: 11; Y: 7); Angle: 90;
    Cone: 360; Collide: lcNone; Size: 1; Jag: 0.26; Fork: 0.18; Frequency: 2.2;
    Strokes: 2; Life: 0.11; Leader: 0; Spell: 0; Pause: 0; Flash: 0.55;
    Jolt: 0; Tint: (R: 66; G: 74; B: 100));
  WreckShortFloor = 0.35;
  WreckShortSpan = 0.65;
  WreckShortX = 12;
  WreckShortY = 19;
  WreckShortSeedSalt = $57726B53; // "WrkS"

// Explodes and moves: a mount explodes too, but is part of the wall
function IsMachine(const ADef: TMonsterDef): Boolean;
begin
  Result := ADef.ExplodesOnDeath and (ADef.Movement.Kind <> mkStatic);
end;

// Explodes and is no one's enemy: the barrel
function IsExplosiveProp(const ADef: TMonsterDef): Boolean;
begin
  Result := ADef.ExplodesOnDeath and (ADef.Category = mcProp);
end;

// ---------------------------------------------------------------------------
// TMonster
// ---------------------------------------------------------------------------

constructor TMonster.Create(const ADef: TMonsterDef; const AAnim: TAnimSet;
  ADiscArt: TDiscArt; const ALevel: TLevel; const APads: TPadWorld;
  const APlacement: TEntityPlacement; ALivesScale: Double);
begin
  inherited Create;
  FDef := ADef;
  FAnim := AAnim;
  FLevel := ALevel;
  FPads := APads;
  FEvents := TList<TMonsterEvent>.Create;

  FScreen := APlacement.Screen;
  FTag := APlacement.Tag;
  // Placement coordinates are sprite-grid cells, as FindMostersOnScreen read
  FX := (APlacement.X - 1) * SpriteSize;
  FY := APlacement.Y * SpriteSize;

  FLives := ADef.Lives;
  if APlacement.Overrides.HasLives then
    FLives := APlacement.Overrides.Lives;
  // Difficulty scale (1/1.5/2) lands on whatever the placement resolved
  // to, per FindMostersOnScreen of 2008. The exact rounding lived in
  // monst.pas (not on hand) - RoundHalfUp per project convention.
  // TODO: verify the rounding against monst.pas (tracked: PORTING-NOTES)
  FLives := RoundHalfUp(FLives * ALivesScale);
  FLivesAll := FLives;
  FLivesBorn := FLives;
  FRageLives := RoundHalfUp(BossRageLives * ALivesScale);

  FStep := ADef.Movement.Speed;
  if APlacement.Overrides.HasSpeed then
    FStep := APlacement.Overrides.Speed;

  // 2008 monsters spawn heading LEFT - toward the approaching hero
  FDirection := False;
  if APlacement.Overrides.HasDirection then
    FDirection := APlacement.Overrides.Direction <> 0;

  FCanShoot := ADef.Attack.HasAttack;
  if APlacement.Overrides.HasCanShoot then
    FCanShoot := FCanShoot and APlacement.Overrides.CanShoot;
  FFireEveryTicks := ADef.Attack.FireEveryTicks;

  FSecret := False; // placement 'secret' flag arrives via level JSON later
  FTicksSinceHit := NeverHit;

  FLife := mlAlive;
  FCurrentSprite := 1;
  if FDirection then
    FAction := maWalkRight
  else
    FAction := maWalkLeft;
  if ADef.Movement.Kind = mkStatic then
    FAction := maWalkLeft; // static types 'walk' with step 0, as in 2008
  if ADef.Movement.Kind = mkBossFly then
  begin
    FAction := maFlying;
    FPilot := TPilot.Create(ALevel, APads, APlacement.Screen,
      ADef.Movement.Speed);
    FBossMinionTimer := ADef.Boss.SpawnEveryTicks;
  end;

  if IsMachine(ADef) then
  begin
    CreateSmoke(WreckSmoke);
    CreateWreckSparks;
    CreateWreckShort;
  end
  else if IsExplosiveProp(ADef) then
    CreateSmoke(BarrelSmoke);
  if ADiscArt <> nil then
    FDisc := TDisc.Create(ADef.Disc, ADiscArt, DiscCenter);
end;

destructor TMonster.Destroy;
begin
  FPilot.Free;
  FDisc.Free;
  FShort.Free;
  FSparks.Free;
  FSmoke.Free;
  FEvents.Free;
  inherited;
end;

function TMonster.SpawnSeed: Cardinal;
begin
  Result := (Cardinal(Round(FX)) shl 16) xor Cardinal(Round(FY));
end;

// Seeded by the spawn point, so two bodies on one screen do not puff in
// step
procedure TMonster.CreateSmoke(const ABodySmoke: TBodySmoke);
begin
  FBodySmoke := ABodySmoke;
  var SmokePlacement := Default(TDynamicPlacement);
  SmokePlacement.Tint := ABodySmoke.Tint;
  FSmoke := TSmoke.CreateLook(SmokePlacement, ABodySmoke.Look,
    ABodySmoke.Level, SpawnSeed);
end;

// Unlit like the smoke, and seeded apart from it. The tint is the
// color of a fresh spark: white heat.
procedure TMonster.CreateWreckSparks;
begin
  var WreckPlacement := Default(TDynamicPlacement);
  WreckPlacement.Tint := TColorTint.Neutral;
  FSparks := TSparks.CreateLook(WreckPlacement, WreckSparks, 0,
    SpawnSeed xor WreckSparksSeedSalt);
  FSparks.UseSolid(SolidUnderPoint);
end;

procedure TMonster.CreateWreckShort;
begin
  FShort := TLightning.CreateLook(Default(TDynamicPlacement), WreckShort, 0,
    SpawnSeed xor WreckShortSeedSalt);
  FShort.UseSolid(SolidUnderPoint);
end;

function TMonster.SolidUnderPoint(AX, AY: Single): Boolean;
begin
  Result := FLevel.SolidAtPoint(FScreen, AX, AY) or
    FPads.BodyAt(FScreen, AX, AY);
end;

procedure TMonster.WreckIfCritical;
begin
  if FWrecked or (FSmoke = nil) or (HealthTier <> htCritical) then
    Exit;
  FWrecked := True;
  FSmoke.FadeTo(FBodySmoke.CriticalLevel, FBodySmoke.RampTicks);
  if FSparks <> nil then
    FSparks.FadeTo(WreckSparksLevel, WreckSparksRampTicks);
end;

procedure TMonster.TickSmoke;
begin
  if FSmoke = nil then
    Exit;

  var Spot := BodyPoint(FBodySmoke.X, FBodySmoke.Y);
  FSmoke.Tick(Spot.X, Spot.Y, FLife = mlAlive);
end;

procedure TMonster.TickSparks;
begin
  if FSparks = nil then
    Exit;

  var Spot := BodyPoint(WreckSparksX, WreckSparksY);
  FSparks.Tick(Spot.X, Spot.Y, FLife = mlAlive);
end;

procedure TMonster.TickShort;
begin
  if FShort = nil then
    Exit;

  if FWrecked then
  begin
    var ShortLevel: Single := WreckShortFloor + WreckShortSpan * (1 - TierShare);
    FShort.FadeTo(ShortLevel, 0);
  end;

  var Spot := BodyPoint(WreckShortX, WreckShortY);
  FShort.Tick(Spot.X, Spot.Y, FLife = mlAlive);
end;

procedure TMonster.DrawSmoke(const ACanvas: TDynamicCanvas;
  AOrigin: TSdlPoint; AAlpha: Single);
begin
  if FSmoke <> nil then
    FSmoke.Draw(ACanvas, FSmoke.Origin.X + AOrigin.X,
      FSmoke.Origin.Y + AOrigin.Y, AAlpha);
end;

procedure TMonster.DrawSparks(const ACanvas: TDynamicCanvas;
  AOrigin: TSdlPoint; AAlpha: Single);
begin
  if FSparks <> nil then
    FSparks.Draw(ACanvas, FSparks.Origin.X + AOrigin.X,
      FSparks.Origin.Y + AOrigin.Y, AAlpha);
  if FShort <> nil then
    FShort.Draw(ACanvas, FShort.Origin.X + AOrigin.X,
      FShort.Origin.Y + AOrigin.Y, AAlpha);
end;

procedure TMonster.TickDisc;
var
  Drive: TDiscDrive;
begin
  if FDisc = nil then
    Exit;
  Drive.Center := DiscCenter;
  Drive.Hero := EyeTarget;
  Drive.SpinScale := FStep / Max(1, FDef.Movement.Speed);
  if FPilot <> nil then
    Drive.SpinScale := FPilot.SpinScale(Drive.SpinScale);
  Drive.Wear := DiscWear;
  Drive.Charge := DiscCharge;
  FDisc.Tick(Drive);
end;

// The hero - or the point a ram has locked on; a stunned eye looks at
// nothing and comes back to the middle
function TMonster.EyeTarget: TSdlFPoint;
begin
  Result.X := FHeroX + SpriteSize / 2;
  Result.Y := FHeroY - SpriteSize / 2;
  if FPilot = nil then
    Exit;

  case FPilot.Gaze of
    pgAimPoint:
      begin
        Result.X := FPilot.AimPoint.X;
        Result.Y := FPilot.AimPoint.Y;
      end;
    pgNowhere:
      Result := DiscCenter;
  end;
end;

// The middle of the sprite: Y is its feet line
function TMonster.DiscCenter: TSdlFPoint;
begin
  Result.X := FX + SpriteSize / 2;
  Result.Y := FY - SpriteSize / 2;
end;

function TMonster.DiscWear: Single;
begin
  if FLivesBorn <= 0 then
    Exit(0);
  Result := EnsureRange((1 - FLives / FLivesBorn) / FDef.Disc.WearFull,
    0.0, 1.0);
end;

// 1 on the tick of a shot, rising toward it over the last TelegraphTicks
function TMonster.DiscCharge: Single;
const
  TelegraphTicks = 10;
begin
  if FFired then
    Exit(1);
  if PilotHoldsGun then
    Exit(FPilot.Charge);
  if not FCanShoot then
    Exit(0);
  var TicksLeft := FFireEveryTicks - FTimeOfFire;
  Result := EnsureRange(1 - TicksLeft / TelegraphTicks, 0.0, 1.0);
end;

// 2008 art faces left; a monster standing still keeps its direction
function TMonster.FacesRight: Boolean;
begin
  if FAction = maStand then
    Exit(FDirection);
  Result := FAction = maWalkRight;
end;

// A point of the left-facing art on the screen: it mirrors with the body
function TMonster.BodyPoint(AArtX, AArtY: Integer): TSdlFPoint;
begin
  var PointX := AArtX;
  if FacesRight then
    PointX := SpriteSize - AArtX;
  Result.X := Round(FX) + PointX;
  Result.Y := Round(FY) - SpriteSize + AArtY;
end;

function TMonster.DrainEvent: TMonsterEvent;
begin
  if FEvents.Count = 0 then
    Exit(meNone);
  Result := FEvents[0];
  FEvents.Delete(0);
end;

// The lives at the top of the given third; the crosshair's boundaries
function TMonster.ThirdMark(AThirds: Integer): Integer;
begin
  Result := Round(FLivesAll * AThirds / 3);
end;

function TMonster.HealthTier: TMonsterHealthTier;
begin
  if FLives > ThirdMark(2) then
    Result := htHale
  else if FLives > ThirdMark(1) then
    Result := htWounded
  else
    Result := htCritical;
end;

function TMonster.TierShare: Single;
var
  Lower, Upper: Integer;
begin
  case HealthTier of
    htHale:
      begin
        Lower := ThirdMark(2);
        Upper := FLivesAll;
      end;
    htWounded:
      begin
        Lower := ThirdMark(1);
        Upper := ThirdMark(2);
      end;
  else
    Lower := 0;
    Upper := ThirdMark(1);
  end;
  if Upper <= Lower then
    Exit(1);
  Result := EnsureRange((FLives - Lower) / (Upper - Lower), 0.0, 1.0);
end;

function TMonster.HitWithin(ATicks: Integer): Boolean;
begin
  Result := (FTicksSinceHit <> NeverHit) and (FTicksSinceHit < ATicks);
end;

// --- coordinate and collision oracles, verbatim -----------------------------

function TMonster.CellOfX(APixel: Integer): Integer;
begin
  Result := Trunc(ScreenCols * APixel / ScreenWidth + 1);
end;

function TMonster.CellOfY(APixel: Integer): Integer;
begin
  Result := Trunc(ScreenRows * APixel / ScreenHeight + 1);
end;

function TMonster.Solid(ACol, ARow: Integer): Boolean;
begin
  Result := FLevel.SolidAt(FScreen, ACol - 1, ARow - 1);
end;

function TMonster.FloorAhead(ACol: Integer; AX: Double): Boolean;
begin
  Result := Solid(ACol, CellOfY(Round(FY))) or
    (FPads.DeckUnder(FScreen, AX, AX, FY) <> nil);
end;

// Either inset edge of the body on a deck, as either one on the grid's
// floor holds it
function TMonster.StandsOnDeck: Boolean;
begin
  Result := FPads.DeckUnder(FScreen, FX + MonsterBound + DeckEdgeInset,
    FX + SpriteSize - MonsterBound - DeckEdgeInset, FY) <> nil;
end;

// Before the tick: the deck the body lay on a tick ago takes it where it
// went - across while no wall stands in the way. Pulled from under it by
// a wall, the body falls, the dead and the gun that never walks too. A
// falling body is not carried: it lands by MoveFalling alone.
procedure TMonster.RideDeck;
begin
  if FAction in [maFlying, maFalling] then
    Exit;
  var Deck := FPads.DeckCarrying(FScreen, FX + MonsterBound + DeckEdgeInset,
    FX + SpriteSize - MonsterBound - DeckEdgeInset, FY);
  if Deck = nil then
    Exit;

  FY := Deck.Top;
  CarryX(Deck.MotionX);

  if not StandsOnDeck and CanGoDown and FDef.AffectedByGravity then
    FAction := maFalling;
end;

// A unit at a time, the wall asked before every one, as ShoveX: a knocked
// deck goes several units a tick, more than one look ahead vouches for
procedure TMonster.CarryX(AWay: Double);
begin
  var Rest := AWay;
  while Rest <> 0 do
  begin
    var Step := EnsureRange(Rest, -1.0, 1.0);
    if (Step < 0) and not CanGoLeftWallOnly then
      Exit;
    if (Step > 0) and not CanGoRightWallOnly then
      Exit;
    FX := FX + Step;
    Rest := Rest - Step;
  end;
end;

function TMonster.DeckLift(AAlpha: Single): Single;
begin
  if FAction = maFlying then
    Exit(0);
  var Deck := FPads.DeckUnder(FScreen, FX + MonsterBound + DeckEdgeInset,
    FX + SpriteSize - MonsterBound - DeckEdgeInset, FY);
  if Deck = nil then
    Exit(0);
  Result := Deck.Lift(AAlpha);
end;

function TMonster.CanGoLeftEdgeAware: Boolean;
begin
  // Wall ahead OR no floor ahead - both turn the patroller around
  Result := True;
  if FX < 2 then
    Exit(False);
  var AheadCol := CellOfX(Round(FX) + MonsterBound);
  if Solid(AheadCol, CellOfY(Round(FY)) - 1) or
     not FloorAhead(AheadCol, Round(FX) + MonsterBound + DeckEdgeInset) then
    Result := False;
end;

function TMonster.CanGoRightEdgeAware: Boolean;
begin
  Result := True;
  if FX > PatrolRightLimit then
    Exit(False);
  var Pixel := Round(FX) - MonsterBound;
  var AheadCol := CellOfX(Pixel);
  if Pixel mod SpriteSize <> 0 then
    Inc(AheadCol); // BelongToXSprite[2]
  var EdgeX := Round(FX) + SpriteSize - MonsterBound - DeckEdgeInset;
  if Solid(AheadCol, CellOfY(Round(FY)) - 1) or
     not FloorAhead(AheadCol, EdgeX) then
    Result := False;
end;

function TMonster.CanGoLeftWallOnly: Boolean;
begin
  Result := True;
  if FX < 2 then
    Exit(False);
  if Solid(CellOfX(Round(FX) + MonsterBound), CellOfY(Round(FY)) - 1) then
    Result := False;
end;

function TMonster.CanGoRightWallOnly: Boolean;
begin
  Result := True;
  if FX > PatrolRightLimit then
    Exit(False);
  var Pixel := Round(FX) - MonsterBound;
  var AheadCol := CellOfX(Pixel);
  if Pixel mod SpriteSize <> 0 then
    Inc(AheadCol);
  if Solid(AheadCol, CellOfY(Round(FY)) - 1) then
    Result := False;
end;

function TMonster.CanGoDown: Boolean;
begin
  // Verbatim monster CanIGoDown: it probes y+3 - the cell UNDER the
  // feet. (The hero's version probes y-3 with different offsets; the
  // one wrong sign here once turned every barrel into a trampoline.)
  Result := True;
  if Solid(CellOfX(Round(FX) + MonsterBound), CellOfY(Round(FY) + 3)) then
    Result := False;
  if CellOfX(Round(FX)) <> ScreenCols then
  begin
    var Pixel := Round(FX) - MonsterBound;
    var Col := CellOfX(Pixel);
    if Pixel mod SpriteSize <> 0 then
      Inc(Col);
    if Solid(Col, CellOfY(Round(FY) + 3)) then
      Result := False;
  end;
end;

// The cell the art of the body would reach one unit on, in every row the
// body stands in: a body that is falling is two rows tall
function TMonster.ShoveBlocked(AStep: Integer): Boolean;
begin
  var EdgeX := Round(FX) + AStep;
  if AStep < 0 then
    Inc(EdgeX, MonsterBound)
  else
    Inc(EdgeX, SpriteSize - MonsterBound - 1);

  var Col := CellOfX(EdgeX);
  for var i := CellOfY(Round(FY) - SpriteSize) to CellOfY(Round(FY) - 1) do
    if Solid(Col, i) then
      Exit(True);
  Result := False;
end;

procedure TMonster.ShoveX(ADeltaX: Integer);
begin
  // An impulse (bullet knockback) may not go anywhere walking could not:
  // the wall-only oracles probe one cell ahead of the CURRENT position,
  // so a multi-unit jump after a single check can overshoot into a solid
  // cell. Stepping unit by unit re-asks the oracle at every position.
  // The oracles answer for the cell the body stands in, so a step can
  // leave a sliver of the art in the wall, and a body falling past rests
  // on that sliver in mid-air: ShoveBlocked asks about the cell the step
  // lands in.
  var StepDir := Sign(ADeltaX);
  for var i := 1 to Abs(ADeltaX) do
  begin
    if (StepDir < 0) and not CanGoLeftWallOnly then
      Exit;
    if (StepDir > 0) and not CanGoRightWallOnly then
      Exit;
    if ShoveBlocked(StepDir) then
      Exit;
    FX := FX + StepDir;
  end;
end;

// --- behavior ---------------------------------------------------------------

procedure TMonster.FireAt(const ABullets: TBurst);

  procedure AimedShot(ACount: Integer; AOffsetX: Integer);
  begin
    // Verbatim boss/shooter2 aiming: arccos with quadrant fix
    var DeltaX := FX - FHeroX;
    var DeltaY := FY - FHeroY;
    var Distance := Round(Sqrt(DeltaX * DeltaX + DeltaY * DeltaY));
    if Distance = 0 then
      Exit;
    // 2008 had whole coordinates, so |DeltaX| <= Distance held by itself.
    // The pilot flies on fractions: a rounded-down Distance pushes the
    // ratio past 1 and ArcCos answers NaN. On whole coordinates the
    // clamp is a no-op, so the 2008 shooters aim exactly as before.
    var Cosine := EnsureRange(DeltaX / Distance, -1.0, 1.0);
    var Angle := Round(57.296 * ArcCos(Cosine));
    if FHeroY >= FY then
      Angle := Angle + 180
    else
      Angle := -Angle + 180;

    var MuzzleX: Double := FX + SpriteSize div 4;
    var MuzzleY: Double := FY + SpriteSize div 4;
    var MuzzleRadius := FDef.Disc.Muzzle;
    if MuzzleRadius > 0 then
    begin
      MuzzleX := FX + SpriteSize / 2 - DeltaX / Distance * MuzzleRadius;
      MuzzleY := FY + SpriteSize / 2 - DeltaY / Distance * MuzzleRadius;
    end;
    for var i := 0 to ACount - 1 do
      ABullets.NewBullet(FDef.Attack.BulletSpeed, MuzzleX + i * AOffsetX,
        MuzzleY, Angle, 0, True);
  end;

begin
  case FDef.Attack.Pattern of
    apAimedSingle:
      AimedShot(1, 0);

    apAimedDouble:
      AimedShot(2, FDef.Attack.SecondBulletOffsetX);

    apRainVolley:
      for var i := 0 to FDef.Attack.VolleyCount - 1 do
        ABullets.NewBullet(FDef.Attack.BulletSpeed,
          FX + SpriteSize div 4 - 4 + i * FDef.Attack.VolleySpacingX,
          FY + SpriteSize div 4, FDef.Attack.AngleDeg, 0, True);

    apStraightSingle, apStraightCluster5:
      begin
        var Angle := 0;
        var BaseX := FX + SpriteSize * 3 / 4;
        if FAction in [maWalkLeft, maFalling] then
        begin
          Angle := 180;
          BaseX := FX + SpriteSize / 4;
        end;
        var BaseY := FY + SpriteSize / 4;
        ABullets.NewBullet(FDef.Attack.BulletSpeed, BaseX, BaseY,
          Angle, 0, True);
        if FDef.Attack.Pattern = apStraightCluster5 then
        begin
          var Offset := FDef.Attack.ClusterOffset;
          ABullets.NewBullet(FDef.Attack.BulletSpeed, BaseX + Offset,
            BaseY, Angle, 0, True);
          ABullets.NewBullet(FDef.Attack.BulletSpeed, BaseX,
            BaseY + Offset, Angle, 0, True);
          ABullets.NewBullet(FDef.Attack.BulletSpeed, BaseX - Offset,
            BaseY, Angle, 0, True);
          ABullets.NewBullet(FDef.Attack.BulletSpeed, BaseX,
            BaseY - Offset, Angle, 0, True);
        end;
      end;
  end;
end;

// One bullet out of every port of the disc, straight along its barrel.
// The ports have turned with the rim: SDL counts that angle clockwise,
// the ports and the bullets count theirs counterclockwise.
procedure TMonster.FirePorts(const ABullets: TBurst);
begin
  for var PortAngle in FDef.Disc.PortAngles do
  begin
    var Angle := PortAngle - FDisc.Pose.Angle;
    // Whole turns off: a bullet's own trigonometry (degrees / 57) drifts
    // with the size of the angle
    Angle := Angle - 360 * Floor(Angle / 360);
    var Radians := DegToRad(Angle);
    // The middle of the disc in a bullet's units: its picture hangs a
    // sprite above its Y
    ABullets.NewBullet(FDef.Attack.BulletSpeed,
      FX + SpriteSize / 2 + Cos(Radians) * FDef.Disc.Muzzle,
      FY + SpriteSize / 2 - Sin(Radians) * FDef.Disc.Muzzle,
      Round(Angle), 0, True);
  end;
end;

function TMonster.PilotBusy: Boolean;
begin
  Result := (FPilot <> nil) and FPilot.Busy;
end;

function TMonster.PilotHoldsGun: Boolean;
begin
  Result := (FPilot <> nil) and FPilot.GunHeld;
end;

procedure TMonster.SetTactics(ATactics: TPilotTactics);
begin
  if FPilot <> nil then
    FPilot.SetTactics(ATactics);
end;

procedure TMonster.NoteHeroContact;
begin
  if FPilot <> nil then
    FPilot.NoteHeroContact;
end;

function TMonster.LastCrash: TPilotCrash;
begin
  Result := FPilot.LastCrash;
end;

procedure TMonster.HoldLap(AHold: Boolean);
begin
  if FPilot <> nil then
    FPilot.HoldLap(AHold);
end;

function TMonster.FliesLap: Boolean;
begin
  Result := (FPilot <> nil) and FPilot.FliesLap;
end;

function TMonster.LapAhead(ATicks: Integer): TArray<TLapStep>;
begin
  Result := [];
  if FPilot <> nil then
    Result := FPilot.LapAhead(FX, FY, ATicks);
end;

// Shared by MoveWalking and MoveFlying - the same frame clock
procedure TMonster.AdvanceFrame;
begin
  FCurrentSprite := FCurrentSprite + FDef.AnimFreq;
  if FCurrentSprite > SpriteResetThreshold then
    FCurrentSprite := 1;
end;

// The patrol flip shared by both patrol kinds: walk while the oracle
// allows, turn around when it refuses. Callers pass the oracle pair -
// edge-aware or wall-only - already evaluated (the oracles are pure
// probes, so the eager extra call is free of side effects).
procedure TMonster.PatrolStep(ACanLeft, ACanRight: Boolean);
begin
  if FAction = maWalkLeft then
  begin
    if ACanLeft then
      FX := FX - FStep
    else
      FAction := maWalkRight;
  end
  else
  begin
    if ACanRight then
      FX := FX + FStep
    else
      FAction := maWalkLeft;
  end;
end;

procedure TMonster.MoveWalking;
begin
  AdvanceFrame;

  // An emplacement (step 0) is never 'blocked': the patrol flip is the
  // ONLY thing that ever changes a walker's facing, and it fires only
  // on a blocked oracle - so a speed-0 gunner froze at its spawn facing
  // forever (the pit tank shot left at a hero standing to its right,
  // report 2026-07-21). A gun that cannot drive can still turn the
  // turret: face the hero, chaser-style. Straight-shooters only - their
  // fire direction IS the facing; aimed/rain gunners target by
  // coordinates, and mirroring a wall mount would detach it from its
  // wall, so they keep the frozen 2008 look.
  if (FStep = 0) and
     (FDef.Attack.Pattern in [apStraightSingle, apStraightCluster5]) then
  begin
    if FX > FHeroX then
      FAction := maWalkLeft
    else if FX < FHeroX then
      FAction := maWalkRight;
    Exit;
  end;

  case FDef.Movement.Kind of
    mkPatrol, mkStatic:
      PatrolStep(CanGoLeftEdgeAware, CanGoRightEdgeAware);

    mkPatrolNoEdgeCheck:
      PatrolStep(CanGoLeftWallOnly, CanGoRightWallOnly);

    mkChaseHero:
      if FLife = mlAlive then
      begin
        if (FAction = maWalkLeft) and CanGoLeftWallOnly then
          FX := FX - FStep;
        if (FAction = maWalkRight) and CanGoRightWallOnly then
          FX := FX + FStep;
        if FX > FHeroX then
          FAction := maWalkLeft
        else if FX < FHeroX then
          FAction := maWalkRight
        else
          FAction := maStand;
      end;
  end;

  // Verbatim: 'if canigodown and typ<>платформа and typ<>крепление' -
  // now a data flag instead of type names. A deck holds the feet too.
  if CanGoDown and not StandsOnDeck and FDef.AffectedByGravity then
    FAction := maFalling;
end;

procedure TMonster.MoveFalling;
const
  // Verbatim: below this line the original kept falling out of the
  // world instead of snapping to a cell
  BelowFloorY = ScreenHeight - 17; // 367
begin
  if CanGoDown or (FY > BelowFloorY) then
  begin
    var PrevY := FY;
    FY := FY + Round(FAcceleration);
    FAcceleration := FAcceleration + (FStep + 1) / 20; // monster gravity
    // A deck the feet came down onto lands them as the grid's floor does
    var Deck := FPads.DeckCrossed(FScreen, FX + MonsterBound + DeckEdgeInset,
      FX + SpriteSize - MonsterBound - DeckEdgeInset, PrevY, FY, nil);
    if Deck = nil then
      Exit;
    Deck.Press(FAcceleration);
    FY := Deck.Top;
  end
  else
  begin
    FY := FY + 16;
    FY := (CellOfY(Round(FY)) - 1) * SpriteSize; // exact landing snap
  end;
  FAcceleration := 0;
  if FDef.Movement.Kind = mkChaseHero then
  begin
    if FX > FHeroX then
      FAction := maWalkLeft
    else
      FAction := maWalkRight;
  end
  else if FDirection then
    FAction := maWalkRight
  else
    FAction := maWalkLeft;
end;

procedure TMonster.MoveFlying;
var
  Brief: TPilotBrief;
begin
  AdvanceFrame;
  Brief.Step := FStep;
  Brief.HeroX := FHeroX;
  Brief.HeroY := FHeroY;
  Brief.BodyAlive := FLife = mlAlive;
  FPilot.Tick(FX, FY, Brief);
  if FPilot.Crashed then
    FEvents.Add(meBossCrashed);
  if FPilot.OwesPrize then
    FEvents.Add(meBossOwesPrize);
end;

procedure TMonster.Tick(AHeroX, AHeroY: Integer; const ABullets: TBurst);
begin
  FHeroX := AHeroX;
  FHeroY := AHeroY;
  RideDeck;
  if FTicksSinceHit <> NeverHit then
    Inc(FTicksSinceHit);

  if FDef.Category = mcBoss then
  begin
    Dec(FBossMinionTimer);
    if FBossMinionTimer = 0 then
    begin
      FBossMinionTimer := FDef.Boss.SpawnEveryTicks;
      if FEnraged then
        FBossMinionTimer := EnragedMinionTicks;
      if FLife = mlAlive then
        FEvents.Add(meBossWantsMinion);
    end;
  end;

  FFired := False;
  // After a hold the aimed gun takes a whole interval to speak again
  if PilotHoldsGun then
    FTimeOfFire := 0
  else if FCanShoot and (FLife = mlAlive) then
  begin
    Inc(FTimeOfFire);
    if FTimeOfFire = FFireEveryTicks then
    begin
      FireAt(ABullets);
      FTimeOfFire := 0;
      FFired := True;
    end;
  end;

  if FLife = mlDying then
  begin
    FCurrentSprite := FCurrentSprite + FDef.AnimFreq / 2;
    if FCurrentSprite > 8 then
    begin
      if FDef.Boss.EndsLevelOnDeath then
        FEvents.Add(meLevelComplete);
      FLife := mlDead;
      FStep := 0;
    end;
  end;

  case FAction of
    maWalkLeft, maWalkRight, maStand:
      if FLife <> mlDead then
        MoveWalking;
    maFalling:
      MoveFalling;
    maFlying:
      MoveFlying;
  end;
  WreckIfCritical;
  TickSmoke;
  TickSparks;
  TickShort;
  TickDisc;
  // After the disc has turned: the ports are where the frame shows them
  if (FPilot <> nil) and FPilot.PortsDue then
    FirePorts(ABullets);
end;

// Tank rage: below the threshold a cluster5 shooter doubles speed and
// fire rate - once, verbatim
procedure TMonster.EnrageTankIfLow;
begin
  if (FDef.Attack.Pattern = apStraightCluster5) and
     (FLives < TankRageLives) and not FEnraged then
  begin
    FEnraged := True;
    FStep := FStep * 2;
    FFireEveryTicks := Max(1, FFireEveryTicks div 2);
    FTimeOfFire := 1;
  end;
end;

procedure TMonster.ProcessBossThresholds(const AEnemyBullets: TBurst);
const
  // The rage wave is the shared k/t fan wearing the 2008 rage numbers
  // (24x44, slow fragments) - the header's 'one template' claim holds
  RageWave: TFanShape = (Rows: 24; Cols: 44; BaseSpeed: 2; SpeedSpread: 2);
begin
  if FDef.Category <> mcBoss then
    Exit;

  if (FLives < FLivesAll * 2 / 3) and not FHenshinSent then
  begin
    // Checking the event list here was the record-skip bug: the list
    // drains every tick, so each hit below 2/3 re-sent the henshin
    // and the EVOLUTION sting screamed on every bullet
    FHenshinSent := True;
    FEvents.Add(meHenshin);
  end;

  if (FLives < FRageLives) and not FEnraged then
  begin
    FEnraged := True;
    // Verbatim '+20': the 'full' reference resets so the crosshair
    // thresholds track the rage phase, not the pre-rage health
    FLivesAll := FLives + 20;
    FStep := FStep * 2;
    FFireEveryTicks := Max(1, FFireEveryTicks div BossRageFireRate);
    FTimeOfFire := 1;
    FEvents.Add(meBossRage);
    AEnemyBullets.SpawnFan(FX, FY, RageWave);
  end;
end;

procedure TMonster.BeginDying(const AEnemyBullets: TBurst);
const
  // Victory double fan verbatim: fast and slow fragments of the same
  // geometry fly together - the boss shatters in two tempos
  FastFragments: TFanShape =
    (Rows: 20; Cols: 44; BaseSpeed: 10; SpeedSpread: 2);
  SlowFragments: TFanShape =
    (Rows: 20; Cols: 44; BaseSpeed: 2; SpeedSpread: 2);
begin
  FLife := mlDying;
  if FDef.Movement.Kind = mkChaseHero then
    if FDirection then
      FAction := maWalkLeft
    else
      FAction := maWalkRight;
  FCurrentSprite := 1;
  FStep := Round(FStep / 3); // dying monsters slide; statics stay put
  FEvents.Add(meDied);

  if FDef.Boss.EndsLevelOnDeath then
  begin
    AEnemyBullets.SpawnFan(FX, FY, FastFragments);
    AEnemyBullets.SpawnFan(FX, FY, SlowFragments);
  end
  else if FDef.ExplodesOnDeath then
    AEnemyBullets.SpawnExplosionFan(FX, FY);
end;

procedure TMonster.TakeDamage(AKnockDx, ALosses: Integer;
  const AEnemyBullets: TBurst);
begin
  FTicksSinceHit := 0;
  EnrageTankIfLow;
  ProcessBossThresholds(AEnemyBullets);

  // Verbatim magnitude (dx/2), rerouted through the collision oracle:
  // the single pre-check of 2008 let fast bullets shove pickups and
  // monsters INTO walls (bugfix queue item 12)
  // A boss in a maneuver holds its line: the wall oracle asks one row,
  // and a body between two rows would be shoved into the other one's
  // wall
  if not PilotBusy then
    ShoveX(Round(AKnockDx / 2));

  Dec(FLives, ALosses);
  if (FLives < 1) and (FLife = mlAlive) then
    BeginDying(AEnemyBullets);
end;

procedure TMonster.Draw(const ASprites: TSpriteRenderer; AAlpha: Single);
var
  Frame: Integer;
begin
  if (FDisc <> nil) and (FLife = mlAlive) then
  begin
    FDisc.Draw(ASprites, AAlpha);
    Exit;
  end;

  var DrawY := Round(FY) - SpriteSize;
  var Mirrored := FAction = maWalkRight; // 2008 art faces left

  case FLife of
    mlAlive:
      begin
        case FAction of
          maStand:
            Frame := 1;
          maFalling:
            Frame := 4;
        else
          Frame := EnsureRange(RoundHalfUp(FCurrentSprite), 1, 8);
        end;
        Mirrored := FacesRight;
        ASprites.Draw(FAnim.Alive[Frame - 1], Round(FX), DrawY, Mirrored);
      end;

    mlDying:
      ASprites.Draw(FAnim.Death[EnsureRange(RoundHalfUp(FCurrentSprite), 1, 8) - 1],
        Round(FX), DrawY, Mirrored);

    mlDead:
      ASprites.Draw(FAnim.Death[7], Round(FX), DrawY, Mirrored);
  end;
end;

// ---------------------------------------------------------------------------
// TMonsterField
// ---------------------------------------------------------------------------

constructor TMonsterField.Create(const ARenderer: PSdlRenderer;
  const ARegistry: TMonsterRegistry; const ALevel: TLevel;
  const APads: TPadWorld; ADifficulty: TDifficulty; ALivesScale: Double);
begin
  inherited Create;
  FMonsters := TObjectList<TMonster>.Create(True);
  FAnimSets := TDictionary<string, TAnimSet>.Create;
  FSpriteSets := TObjectList<TSpriteSet>.Create(True);
  FSetCaches := TObjectList<TSpriteCache>.Create(True);
  FDiscArts := TObjectDictionary<string, TDiscArt>.Create([doOwnsValues]);
  FRenderer := ARenderer;
  FRegistry := ARegistry;
  FLevel := ALevel;
  FPads := APads;
  FLivesScale := ALivesScale;

  for var Placement in ALevel.Entities do
  begin
    // The Doom skill-flag filter: an entity lists the grades it lives
    // on ("difficulty" in level JSON); the field is reborn on restart,
    // so a difficulty change lands here together with the lives scale
    if not (ADifficulty in Placement.Grades) then
      Continue;
    var Def := ARegistry.Find(Placement.MonsterId);
    FMonsters.Add(TMonster.Create(Def, AnimFor(Placement.SpriteList),
      DiscArtFor(Def), ALevel, APads, Placement, FLivesScale));
  end;
end;

procedure TMonsterField.SpawnFromSky(const AMonsterId: string;
  AScreen: Integer);
begin
  // Row 0 is fully above the visible screen: the entry IS the fall
  SpawnAt(AMonsterId, AScreen, Random(15) + 1, 0);
end;

procedure TMonsterField.SpawnOn(const AMonsterId: string;
  AScreen: Integer; AX, AY: Double);
begin
  // Born in a cell, as every monster is, then set on the point itself:
  // a cell may lie half a body aside, out of the contact box
  var Born := SpawnAt(AMonsterId, AScreen, 1, 1);
  Born.FX := AX;
  Born.FY := AY;
end;

// In the cells a level places its entities by
function TMonsterField.SpawnAt(const AMonsterId: string;
  AScreen, APlacementX, APlacementY: Integer): TMonster;
var
  Placement: TEntityPlacement;
begin
  var Def := FRegistry.Find(AMonsterId);
  Placement := Default(TEntityPlacement);
  Placement.MonsterId := AMonsterId;
  Placement.Screen := AScreen;
  Placement.X := APlacementX;
  Placement.Y := APlacementY;
  Placement.SpriteList := Def.SpriteList;
  // Whether AddMonstOnBoss1 scaled its minions is monst.pas knowledge
  // (the 2008 call took no multiplier) - scaled here for consistency.
  // TODO: verify against monst.pas (tracked: PORTING-NOTES)
  Result := TMonster.Create(Def, AnimFor(Def.SpriteList), DiscArtFor(Def),
    FLevel, FPads, Placement, FLivesScale);
  FMonsters.Add(Result);
end;

function TMonsterField.AnyAliveOnScreen(AScreen: Integer): Boolean;
begin
  for var Monster in FMonsters do
    if (Monster.Screen = AScreen) and (Monster.Life = mlAlive) then
      Exit(True);
  Result := False;
end;

function TMonsterField.AnyAliveTagged(const ATag: string): Boolean;
begin
  for var Monster in FMonsters do
    if (Monster.Life = mlAlive) and (Monster.Tag = ATag) then
      Exit(True);
  Result := False;
end;

// The mark is told for the normal grade and grows with the difficulty,
// as the lives it is compared with did at birth
function TMonsterField.AnyTaggedLivesBelow(const ATag: string;
  ALives: Integer): Boolean;
begin
  var Mark := ALives * FLivesScale;
  for var Monster in FMonsters do
    if (Monster.Life = mlAlive) and (Monster.Tag = ATag) and
      (Monster.Lives < Mark) then
      Exit(True);
  Result := False;
end;

function TMonsterField.AnyTaggedEnraged(const ATag: string): Boolean;
begin
  for var Monster in FMonsters do
    if (Monster.Life = mlAlive) and Monster.Enraged and
      (Monster.Tag = ATag) then
      Exit(True);
  Result := False;
end;

function TMonsterField.FirstAliveTagged(const ATag: string): TMonster;
begin
  for var Monster in FMonsters do
    if (Monster.Life = mlAlive) and (Monster.Tag = ATag) then
      Exit(Monster);
  Result := nil;
end;

procedure TMonsterField.SetTaggedTactics(const ATag: string;
  ATactics: TPilotTactics);
begin
  for var Monster in FMonsters do
    if Monster.Tag = ATag then
      Monster.SetTactics(ATactics);
end;

procedure TMonsterField.Tick(AScreen, AHeroX, AHeroY: Integer;
  const ABullets: TBurst);
begin
  for var Monster in FMonsters do
    if Monster.Screen = AScreen then
      Monster.Tick(AHeroX, AHeroY, ABullets);
end;

procedure TMonsterField.Draw(const ASprites: TSpriteRenderer;
  AScreen: Integer; AAlpha: Single);
begin
  for var Monster in FMonsters do
  begin
    if Monster.Screen <> AScreen then
      Continue;
    ASprites.FineY := Monster.DeckLift(AAlpha);
    Monster.Draw(ASprites, AAlpha);
  end;
  ASprites.FineY := 0;
end;

procedure TMonsterField.DrawSmoke(const ACanvas: TDynamicCanvas;
  AScreen: Integer; AOrigin: TSdlPoint; AAlpha: Single);
begin
  for var Monster in FMonsters do
    if Monster.Screen = AScreen then
      Monster.DrawSmoke(ACanvas, AOrigin, AAlpha);
end;

procedure TMonsterField.DrawSparks(const ACanvas: TDynamicCanvas;
  AScreen: Integer; AOrigin: TSdlPoint; AAlpha: Single);
begin
  for var Monster in FMonsters do
    if Monster.Screen = AScreen then
      Monster.DrawSparks(ACanvas, AOrigin, AAlpha);
end;

destructor TMonsterField.Destroy;
begin
  // Monsters before the disc art they draw with
  FMonsters.Free;
  FDiscArts.Free;
  FAnimSets.Free;
  // Caches before sets: a cache holds no set resources at destroy time,
  // but the reading order of the living pair was cache -> set, and the
  // teardown mirrors it.
  FSetCaches.Free;
  FSpriteSets.Free;
  inherited;
end;

// AMnsName is still the 2008 spelling from monsters.json ('gravel.mns');
// the stem names the set. Renaming the field is a data change and waits
// for its own step.
function TMonsterField.AnimFor(const AMnsName: string): TAnimSet;
begin
  if FAnimSets.TryGetValue(AMnsName, Result) then
    Exit;

  var SetName := ChangeFileExt(AMnsName, '');
  var SpriteSet := TSpriteSet.Create(SpriteSetsDir + SetName + '.mset');
  FSpriteSets.Add(SpriteSet);

  var Cache := TSpriteCache.Create(FRenderer);
  Cache.AttachSpriteSet(SpriteSet);
  Cache.ExpectDenseArtAbove(Frame2008Side);
  FSetCaches.Add(Cache);

  Result := LoadAnimSet(Cache, SpriteSet);
  FAnimSets.Add(AMnsName, Result);
end;

function TMonsterField.DiscArtFor(const ADef: TMonsterDef): TDiscArt;
begin
  if not ADef.Disc.Enabled then
    Exit(nil);
  if FDiscArts.TryGetValue(ADef.Disc.SetName, Result) then
    Exit;
  Result := TDiscArt.Create(FRenderer, ADef.Disc.SetName);
  FDiscArts.Add(ADef.Disc.SetName, Result);
end;

end.
