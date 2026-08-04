{
  Monsters - monsters, ported from monst.pas (2008 release) onto the
  data-driven definitions of Monsters.Defs. The fourteen 'if typ =' string
  ladders of the original became dispatch over two enums:

    Movement.Kind: mkPatrol (turns at walls AND ledges - CanIGoLeft1),
      mkPatrolNoEdgeCheck (walls only - CanIGoLeft2), mkChaseHero
      (Vinter follows the hero's X), mkStatic, mkBossFly (rectangle
      flight: down until y>320, left until x<32, up until y<64,
      right until x>448).

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
  lives (turns the HERO into ice form), rage under 80 lives (speed x2,
  fire x3, music change, a 24x44 fragment wave), victory double-fan.

  Moon 2D remake. Requires Delphi 12+.
}
unit Monsters;
{$I Moon2D.inc}

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Math,
  System.Generics.Collections,
  Sdl2.Core, Render.Sprites, Sprites.Sets, Game.Config, Levels.Defs,
  Monsters.Defs, Bullets;

type
  TMonsterAction = (maStand, maWalkLeft, maWalkRight, maFalling,
    maFlyDown, maFlyLeft, maFlyUp, maFlyRight);

  TMonsterLife = (mlAlive, mlDying, mlDead);

  // Requests a monster cannot fulfil itself ('MessageToMain' of 2008);
  // the game loop drains these each tick.
  TMonsterEvent = (meNone, meBossWantsMinion, meHenshin, meBossRage,
    meLevelComplete, meDied);

  TMonster = class
  private
    FDef: TMonsterDef;
    FAnim: TAnimSet;
    FX, FY: Double;
    FScreen: Integer;
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
    FFireEveryTicks: Integer;
    FBossMinionTimer: Integer;
    FSecret: Boolean;
    FEvents: TList<TMonsterEvent>;
    FLevel: TLevel;
    FHeroX, FHeroY: Integer;

    function Solid(ACol, ARow: Integer): Boolean;
    function CellOfX(APixel: Integer): Integer;
    function CellOfY(APixel: Integer): Integer;
    function CanGoLeftEdgeAware: Boolean;   // CanIGoLeft1
    function CanGoRightEdgeAware: Boolean;  // CanIGoRight1
    function CanGoLeftWallOnly: Boolean;    // CanIGoLeft2
    function CanGoRightWallOnly: Boolean;   // CanIGoRight2
    function CanGoDown: Boolean;
    procedure ShoveX(ADeltaX: Integer);
    procedure FireAt(const ABullets: TBurst);
    procedure AdvanceFrame;
    procedure PatrolStep(ACanLeft, ACanRight: Boolean);
    procedure MoveWalking;
    procedure MoveFalling;
    procedure MoveFlying;
    procedure EnrageTankIfLow;
    procedure ProcessBossThresholds(const AEnemyBullets: TBurst);
    procedure BeginDying(const AEnemyBullets: TBurst);
  public
    constructor Create(const ADef: TMonsterDef; const AAnim: TAnimSet;
      const ALevel: TLevel; const APlacement: TEntityPlacement;
      ALivesScale: Double);

    // One logic tick (33 Hz - the REAL rate of the 2008 20 ms timer).
    // AHeroX/AHeroY feed the chasers and aimers; enemy bullets go into
    // ABullets (the shared monster burst).
    procedure Tick(AHeroX, AHeroY: Integer; const ABullets: TBurst);
    procedure Draw(const ASprites: TSpriteRenderer);
    // Applies knockback through the wall oracle; queues explosion fans
    // and events.
    procedure TakeDamage(AKnockDx, ALosses: Integer;
      const AEnemyBullets: TBurst);
    function DrainEvent: TMonsterEvent;

    property Def: TMonsterDef read FDef;
    property X: Double read FX;
    property Y: Double read FY;
    property Screen: Integer read FScreen;
    property Life: TMonsterLife read FLife;
    property Lives: Integer read FLives;
    property LivesAll: Integer read FLivesAll;
    property Direction: Boolean read FDirection;
  end;

  TMonsterField = class
  private
    FMonsters: TObjectList<TMonster>;
    FAnimSets: TDictionary<string, TAnimSet>; // .mns name -> frames
    // Monsters migrating to .mset: each gets its own set + cache pair,
    // both owned here. The shared FCache keeps serving the rest.
    FSpriteSets: TObjectList<TSpriteSet>;
    FSetCaches: TObjectList<TSpriteCache>;
    FRenderer: PSdlRenderer;
    FCache: TSpriteCache; // rooted at monsters\
    FRegistry: TMonsterRegistry;
    FLevel: TLevel;
    // The difficulty multiplier of FindMostersOnScreen (moon.dpr
    // 1092-1094): every monster born in this field - placed or
    // sky-dropped - gets its lives scaled by it
    FLivesScale: Double;
    function AnimFor(const AMnsName: string): TAnimSet;
  public
    constructor Create(const ARenderer: PSdlRenderer;
      const ARegistry: TMonsterRegistry; const ALevel: TLevel;
      ADifficulty: TDifficulty; ALivesScale: Double);
    destructor Destroy; override;

    procedure Tick(AScreen, AHeroX, AHeroY: Integer;
      const ABullets: TBurst);
    // AddMonstOnBoss1 verbatim: a random minion at cell (random(15)+1, 1)
    // - the top edge of the boss screen; gravity does the dramatic entry.
    procedure SpawnFromSky(const AMonsterId: string; AScreen: Integer);
    // 'ExistLive' of monst.pas as the breakthrough gate: ANY live body
    // on the screen counts, pickups included - the 2008 check did not
    // discriminate by category (or did - monst.pas knows; the verbatim
    // reading is kept: the trial medkits lie on the floor by the entry
    // and get trampled in the chaos anyway).
    function AnyAliveOnScreen(AScreen: Integer): Boolean;
    procedure Draw(const ASprites: TSpriteRenderer; AScreen: Integer);

    property Monsters: TObjectList<TMonster> read FMonsters;
  end;

implementation

function RoundHalfUp(AValue: Double): Integer;
begin
  Result := Trunc(AValue + 0.5);
end;

const
  MonsterBound = 8;
  SpriteResetThreshold = 8.7;
  MonstersDir = 'monsters';
  // Patrol turns AT the right edge, not beyond it: GameWidth - SpriteSize
  PatrolRightLimit = 480;
  TankRageLives = 20;      // cluster5 shooters double up below this
  BossRageLives = 80;      // the boss goes berserk below this
  EnragedMinionTicks = 100; // rage shortens the reinforcement interval

// ---------------------------------------------------------------------------
// TMonster
// ---------------------------------------------------------------------------

constructor TMonster.Create(const ADef: TMonsterDef; const AAnim: TAnimSet;
  const ALevel: TLevel; const APlacement: TEntityPlacement;
  ALivesScale: Double);
begin
  inherited Create;
  FDef := ADef;
  FAnim := AAnim;
  FLevel := ALevel;
  FEvents := TList<TMonsterEvent>.Create;

  FScreen := APlacement.Screen;
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
    FAction := maFlyDown;
    FBossMinionTimer := ADef.Boss.SpawnEveryTicks;
  end;
end;

function TMonster.DrainEvent: TMonsterEvent;
begin
  if FEvents.Count = 0 then
    Exit(meNone);
  Result := FEvents[0];
  FEvents.Delete(0);
end;

// --- coordinate and collision oracles, verbatim -----------------------------

function TMonster.CellOfX(APixel: Integer): Integer;
begin
  Result := Trunc(16 * APixel / 512 + 1);
end;

function TMonster.CellOfY(APixel: Integer): Integer;
begin
  Result := Trunc(12 * APixel / 384 + 1);
end;

function TMonster.Solid(ACol, ARow: Integer): Boolean;
begin
  Result := FLevel.SolidAt(FScreen, ACol - 1, ARow - 1);
end;

function TMonster.CanGoLeftEdgeAware: Boolean;
begin
  // Wall ahead OR no floor ahead - both turn the patroller around
  Result := True;
  if FX < 2 then
    Exit(False);
  var AheadCol := CellOfX(Round(FX) + MonsterBound);
  if Solid(AheadCol, CellOfY(Round(FY)) - 1) or
     not Solid(AheadCol, CellOfY(Round(FY))) then
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
  if Solid(AheadCol, CellOfY(Round(FY)) - 1) or
     not Solid(AheadCol, CellOfY(Round(FY))) then
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
  if CellOfX(Round(FX)) <> 16 then
  begin
    var Pixel := Round(FX) - MonsterBound;
    var Col := CellOfX(Pixel);
    if Pixel mod SpriteSize <> 0 then
      Inc(Col);
    if Solid(Col, CellOfY(Round(FY) + 3)) then
      Result := False;
  end;
end;

procedure TMonster.ShoveX(ADeltaX: Integer);
begin
  // An impulse (bullet knockback) may not go anywhere walking could not:
  // the wall-only oracles probe one cell ahead of the CURRENT position,
  // so a multi-unit jump after a single check can overshoot into a solid
  // cell. Stepping unit by unit re-asks the oracle at every position and
  // stops exactly where MoveWalking would.
  var StepDir := Sign(ADeltaX);
  for var i := 1 to Abs(ADeltaX) do
  begin
    if (StepDir < 0) and not CanGoLeftWallOnly then
      Exit;
    if (StepDir > 0) and not CanGoRightWallOnly then
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
    var Angle := Round(57.296 * ArcCos(DeltaX / Distance));
    if FHeroY >= FY then
      Angle := Angle + 180
    else
      Angle := -Angle + 180;
    for var i := 0 to ACount - 1 do
      ABullets.NewBullet(FDef.Attack.BulletSpeed,
        FX + SpriteSize div 4 + i * AOffsetX, FY + SpriteSize div 4,
        Angle, 0, True);
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
  // now a data flag instead of type names.
  if CanGoDown and FDef.AffectedByGravity then
    FAction := maFalling;
end;

procedure TMonster.MoveFalling;
const
  // Verbatim: below this line the original kept falling out of the
  // world instead of snapping to a cell (GameHeight - 17)
  BelowFloorY = 367;
begin
  if CanGoDown or (FY > BelowFloorY) then
  begin
    FY := FY + Round(FAcceleration);
    FAcceleration := FAcceleration + (FStep + 1) / 20; // monster gravity
    Exit;
  end;

  FY := FY + 16;
  FY := (CellOfY(Round(FY)) - 1) * SpriteSize; // exact landing snap
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
begin
  AdvanceFrame;
  case FAction of
    maFlyDown:
      begin
        FY := FY + FStep;
        if FY > 320 then
          FAction := maFlyLeft;
      end;
    maFlyLeft:
      begin
        FX := FX - FStep;
        if FX < 32 then
          FAction := maFlyUp;
      end;
    maFlyUp:
      begin
        FY := FY - FStep;
        if FY < 64 then
          FAction := maFlyRight;
      end;
    maFlyRight:
      begin
        FX := FX + FStep;
        if FX > 448 then
          FAction := maFlyDown;
      end;
  end;
end;

procedure TMonster.Tick(AHeroX, AHeroY: Integer; const ABullets: TBurst);
begin
  FHeroX := AHeroX;
  FHeroY := AHeroY;

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

  if FCanShoot and (FLife = mlAlive) then
  begin
    Inc(FTimeOfFire);
    if FTimeOfFire = FFireEveryTicks then
    begin
      FireAt(ABullets);
      FTimeOfFire := 0;
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
    maFlyDown, maFlyLeft, maFlyUp, maFlyRight:
      MoveFlying;
  end;
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

  if (FLives < BossRageLives) and not FEnraged then
  begin
    FEnraged := True;
    // Verbatim '+20': the 'full' reference resets so the crosshair
    // thresholds track the rage phase, not the pre-rage health
    FLivesAll := FLives + 20;
    FStep := FStep * 2;
    FFireEveryTicks := Max(1, FFireEveryTicks div 3);
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
  EnrageTankIfLow;
  ProcessBossThresholds(AEnemyBullets);

  // Verbatim magnitude (dx/2), rerouted through the collision oracle:
  // the single pre-check of 2008 let fast bullets shove pickups and
  // monsters INTO walls (bugfix queue item 12)
  ShoveX(Round(AKnockDx / 2));

  Dec(FLives, ALosses);
  if (FLives < 1) and (FLife = mlAlive) then
    BeginDying(AEnemyBullets);
end;

procedure TMonster.Draw(const ASprites: TSpriteRenderer);
var
  Frame: Integer;
begin
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
        if FAction = maStand then
          Mirrored := FDirection;
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
  ADifficulty: TDifficulty; ALivesScale: Double);
begin
  inherited Create;
  FMonsters := TObjectList<TMonster>.Create(True);
  FAnimSets := TDictionary<string, TAnimSet>.Create;
  FSpriteSets := TObjectList<TSpriteSet>.Create(True);
  FSetCaches := TObjectList<TSpriteCache>.Create(True);
  FRenderer := ARenderer;
  FCache := TSpriteCache.Create(ARenderer, MonstersDir);
  FRegistry := ARegistry;
  FLevel := ALevel;
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
      ALevel, Placement, FLivesScale));
  end;
end;

procedure TMonsterField.SpawnFromSky(const AMonsterId: string;
  AScreen: Integer);
var
  Placement: TEntityPlacement;
begin
  var Def := FRegistry.Find(AMonsterId);
  Placement := Default(TEntityPlacement);
  Placement.MonsterId := AMonsterId;
  Placement.Screen := AScreen;
  Placement.X := Random(15) + 1;
  Placement.Y := 0; // fully above the visible screen: the entry IS the fall
  Placement.SpriteList := Def.SpriteList;
  // Whether AddMonstOnBoss1 scaled its minions is monst.pas knowledge
  // (the 2008 call took no multiplier) - scaled here for consistency.
  // TODO: verify against monst.pas (tracked: PORTING-NOTES)
  FMonsters.Add(TMonster.Create(Def, AnimFor(Def.SpriteList),
    FLevel, Placement, FLivesScale));
end;

function TMonsterField.AnyAliveOnScreen(AScreen: Integer): Boolean;
begin
  for var Monster in FMonsters do
    if (Monster.Screen = AScreen) and (Monster.Life = mlAlive) then
      Exit(True);
  Result := False;
end;

procedure TMonsterField.Tick(AScreen, AHeroX, AHeroY: Integer;
  const ABullets: TBurst);
begin
  for var Monster in FMonsters do
    if Monster.Screen = AScreen then
      Monster.Tick(AHeroX, AHeroY, ABullets);
end;

procedure TMonsterField.Draw(const ASprites: TSpriteRenderer;
  AScreen: Integer);
begin
  for var Monster in FMonsters do
    if Monster.Screen = AScreen then
      Monster.Draw(ASprites);
end;

destructor TMonsterField.Destroy;
begin
  FMonsters.Free;
  FAnimSets.Free;
  // Caches before sets: a cache holds no set resources at destroy time,
  // but the reading order of the living pair was cache -> set, and the
  // teardown mirrors it.
  FSetCaches.Free;
  FSpriteSets.Free;
  FCache.Free;
  inherited;
end;

function TMonsterField.AnimFor(const AMnsName: string): TAnimSet;
var
  Lines: TStringList;
begin
  if FAnimSets.TryGetValue(AMnsName, Result) then
    Exit;

  // A monster whose set exists reads it; the folder remains the
  // fallback until step 5 retires the loose images. The gravel pilot
  // proved the path, so the gate is gone rather than grown.
  var Sub := ChangeFileExt(AMnsName, '');
  var SetFile := SpriteSetsDir + Sub + '.mset';
  if FileExists(SetFile) then
  begin
    var SpriteSet := TSpriteSet.Create(SetFile);
    FSpriteSets.Add(SpriteSet);
    var Cache := TSpriteCache.Create(FRenderer, '');
    Cache.AttachSpriteSet(SpriteSet);
    FSetCaches.Add(Cache);
    Result := LoadAnimSet(Cache, SpriteSet);
    FAnimSets.Add(AMnsName, Result);
    Exit;
  end;

  // Frame images live in a subfolder named after the .mns file:
  // monsters\barrel.mns lists bare names found in monsters\barrel\.
  // The shared cache still deduplicates: e1.bmp of two monsters are
  // different files in different subfolders, same-name frames within
  // one folder load once.
  Result := Default(TAnimSet);
  Lines := TStringList.Create;
  try
    Lines.LoadFromFile(
      IncludeTrailingPathDelimiter(MonstersDir) + AMnsName);
    while (Lines.Count > 0) and (Trim(Lines[Lines.Count - 1]) = '') do
      Lines.Delete(Lines.Count - 1);
    // Lines 1..8 are the alive cycle, 9..16 the death cycle; a shorter
    // file fills what it can (bounds come from the arrays, not lore)
    for var i := 0 to Min(High(Result.Alive), Lines.Count - 1) do
      Result.Alive[i] := FCache.Get(Sub + '\' + Trim(Lines[i]));
    for var i := 0 to Min(High(Result.Death),
        Lines.Count - 1 - Length(Result.Alive)) do
      Result.Death[i] :=
        FCache.Get(Sub + '\' + Trim(Lines[Length(Result.Alive) + i]));
  finally
    Lines.Free;
  end;
  FAnimSets.Add(AMnsName, Result);
end;

end.
