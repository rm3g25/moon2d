{
  Game.Explosions - the one home of "something blew up": a flash, a
  fireball, the debris of Effects.Debris and a smoke plume, sized by the
  kind of the explosion. A monster names its kind in monsters.json
  ("explosion"); what each kind looks like lives here.

  The look only: what an explosion does - the wave that wounds - is
  Game.Blasts. One thing of the look can wound: the shards of the
  debris, when the game detonates them live; whom they strike is the
  game's to say (StrikeShards). The sound and the jolt of a blast are
  the game's: it knows when it detonates one. The aftershocks of a big
  wreck go off here, on their own clock, so each one calls back for its
  echo.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.Explosions;
{$I ..\Moon2D.inc}

interface

uses
  System.Generics.Collections, Sdl2.Core, Render.Brush, Monsters.Defs,
  Effects.Sparks, Effects.Debris, Levels.Tint, Levels.Dynamics;

type
  // The game's answer to an aftershock: its sound, its jolt
  TEchoAftershock = reference to procedure;

  TExplosions = class
  private type
    TFlash = record
      X, Y: Single;
      Size: Single;
      Age, Life: Integer;
    end;

    // A cloud of the explosion: its puffs, their color at birth, and the
    // ticks it pours for, thinning to nothing
    TCloudLook = record
      Puffs: TSmokeLook;
      Tint: TColorTint;
      Ticks: Integer;
    end;

    TExplosionLook = record
      Debris: TDebrisLook;
      FlashSize: Single; // units across
      FlashTicks: Integer;
      // The fireball: hot puffs over the body - what burns where it stood
      Fire: TCloudLook;
      // The plume, behind the figures
      Smoke: TCloudLook;
      // A big wreck keeps popping: blasts of AftershockKind around the
      // heart, AftershockSpread units out, over the next AftershockTicks
      Aftershocks: Integer;
      AftershockKind: TExplosionKind;
      AftershockSpread: Single;
      AftershockTicks: Integer;
    end;

    TAftershock = record
      X, Y: Single;
      Kind: TExplosionKind;
      Delay: Integer; // ticks
    end;
  private
    FDebris: TDebrisField;
    FFlashes: TList<TFlash>;
    FFires: TObjectList<TSmoke>;
    FPlumes: TObjectList<TSmoke>;
    FAftershocks: TList<TAftershock>;
    FEcho: TEchoAftershock;
    // Own stream, not Random: that one feeds the boss spawn table
    FRandom: TXorShift;
    function Pour(AX, AY: Single; const ALook: TCloudLook;
      ASalt: Cardinal): TSmoke;
    procedure TickClouds(const AClouds: TObjectList<TSmoke>);
    procedure QueueAftershocks(AX, AY: Single; const ALook: TExplosionLook);
    procedure TickAftershocks;
    procedure Blast(AX, AY: Single; const ALook: TExplosionLook;
      AShardLives: Integer);
    procedure DrawFlash(const ACanvas: TDynamicCanvas; const AFlash: TFlash;
      AOrigin: TSdlPoint; AAlpha: Single);
  public
    constructor Create(ARenderer: PSdlRenderer; const AProbe: TSolidProbe;
      const AEcho: TEchoAftershock);
    destructor Destroy; override;
    // AX/AY - the heart of the blast, screen units; ekNone does nothing.
    // AShardLives - what a shard takes off a body it falls on; without
    // it the debris is decoration
    procedure Detonate(AX, AY: Single; AKind: TExplosionKind;
      AShardLives: Integer = 0);
    // Shows the game every shard that can still wound, once a tick
    procedure StrikeShards(const AStrike: TShardStrike);
    procedure Tick;
    // The plumes, behind the figures; AOrigin - the world's shake
    procedure DrawSmoke(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
      AAlpha: Single);
    // The fireballs, the debris and the flashes, over the bullets
    procedure Draw(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
      AAlpha: Single);
    // A door or a death: nothing follows the hero to the next screen
    procedure Clear;
  end;

implementation

uses
  Render.Glow;

const
  BarrelExplosion: TExplosions.TExplosionLook = (
    Debris: (Shards: 18; ShardSpeed: 7; ShardSize: 6; ShardCone: 150;
      RestSeconds: 4; Sparks: 64; SparkSpeed: 10);
    FlashSize: 96;
    FlashTicks: 7;
    Fire: (
      Puffs: (Rate: 330; Life: 0.55; Size: 9; EndSize: 26; Opacity: 0.9;
        Angle: 90; Cone: 360; Speed: 55; Drag: 0.9; Lift: 30; Wind: 0;
        Turbulence: 6; Spin: 120; Flow: sfSteady; Frequency: 1; Heat: 1;
        EndTint: (R: 28; G: 10; B: 6));
      Tint: (R: 100; G: 62; B: 24);
      Ticks: 6);
    Smoke: (
      Puffs: (Rate: 95; Life: 1.4; Size: 10; EndSize: 34; Opacity: 0.7;
        Angle: 90; Cone: 140; Speed: 30; Drag: 0.6; Lift: 8; Wind: 0;
        Turbulence: 4; Spin: 60; Flow: sfSteady; Frequency: 1; Heat: 0.7;
        EndTint: (R: 70; G: 70; B: 72));
      Tint: (R: 52; G: 50; B: 48);
      Ticks: 28);
    Aftershocks: 0; AftershockKind: ekNone; AftershockSpread: 0;
    AftershockTicks: 0);

  // The tank, the flying platform: a heavier body, more metal to throw
  MachineExplosion: TExplosions.TExplosionLook = (
    Debris: (Shards: 28; ShardSpeed: 8; ShardSize: 7; ShardCone: 160;
      RestSeconds: 5; Sparks: 90; SparkSpeed: 11);
    FlashSize: 130;
    FlashTicks: 8;
    Fire: (
      Puffs: (Rate: 430; Life: 0.6; Size: 11; EndSize: 32; Opacity: 0.9;
        Angle: 90; Cone: 360; Speed: 65; Drag: 0.9; Lift: 30; Wind: 0;
        Turbulence: 7; Spin: 120; Flow: sfSteady; Frequency: 1; Heat: 1;
        EndTint: (R: 28; G: 10; B: 6));
      Tint: (R: 100; G: 62; B: 24);
      Ticks: 7);
    Smoke: (
      Puffs: (Rate: 115; Life: 1.8; Size: 12; EndSize: 44; Opacity: 0.72;
        Angle: 90; Cone: 150; Speed: 36; Drag: 0.6; Lift: 8; Wind: 0;
        Turbulence: 5; Spin: 60; Flow: sfSteady; Frequency: 1; Heat: 0.8;
        EndTint: (R: 66; G: 66; B: 68));
      Tint: (R: 46; G: 44; B: 42);
      Ticks: 36);
    Aftershocks: 0; AftershockKind: ekNone; AftershockSpread: 0;
    AftershockTicks: 0);

  // The boss goes with a blast that fills the screen, then the wreck
  // pops for a second and a half
  BossExplosion: TExplosions.TExplosionLook = (
    Debris: (Shards: 48; ShardSpeed: 10; ShardSize: 9; ShardCone: 180;
      RestSeconds: 7; Sparks: 160; SparkSpeed: 13);
    FlashSize: 220;
    FlashTicks: 11;
    Fire: (
      Puffs: (Rate: 620; Life: 0.75; Size: 16; EndSize: 46; Opacity: 0.9;
        Angle: 90; Cone: 360; Speed: 95; Drag: 0.9; Lift: 30; Wind: 0;
        Turbulence: 8; Spin: 100; Flow: sfSteady; Frequency: 1; Heat: 1;
        EndTint: (R: 28; G: 10; B: 6));
      Tint: (R: 100; G: 62; B: 24);
      Ticks: 9);
    Smoke: (
      Puffs: (Rate: 170; Life: 2.4; Size: 16; EndSize: 64; Opacity: 0.75;
        Angle: 90; Cone: 160; Speed: 44; Drag: 0.6; Lift: 8; Wind: 0;
        Turbulence: 6; Spin: 50; Flow: sfSteady; Frequency: 1; Heat: 0.9;
        EndTint: (R: 62; G: 62; B: 64));
      Tint: (R: 40; G: 38; B: 36);
      Ticks: 50);
    Aftershocks: 5; AftershockKind: ekBarrel; AftershockSpread: 24;
    AftershockTicks: 50);

  FlashColor: TRgb = (R: 255; G: 190; B: 110);
  FlashGrowth = 0.3; // the flash swells by this share as it dies
  FlashCoreShare = 0.4; // the white core across, in flash sizes
  // The fireball and the plume are born of one point: their dice must
  // not roll alike
  FireSeedSalt = $46697265; // "Fire"
  SmokeSeedSalt = 0; // the plume's dice are the point's own

constructor TExplosions.Create(ARenderer: PSdlRenderer;
  const AProbe: TSolidProbe; const AEcho: TEchoAftershock);
begin
  inherited Create;
  FEcho := AEcho;
  FFlashes := TList<TFlash>.Create;
  FFires := TObjectList<TSmoke>.Create(True);
  FPlumes := TObjectList<TSmoke>.Create(True);
  FAftershocks := TList<TAftershock>.Create;
  FRandom.Seed := $4B61626F; // "Kabo"
  FDebris := TDebrisField.Create(ARenderer, AProbe);
end;

destructor TExplosions.Destroy;
begin
  FDebris.Free;
  FAftershocks.Free;
  FPlumes.Free;
  FFires.Free;
  FFlashes.Free;
  inherited;
end;

procedure TExplosions.Detonate(AX, AY: Single; AKind: TExplosionKind;
  AShardLives: Integer);
begin
  case AKind of
    ekBarrel:
      Blast(AX, AY, BarrelExplosion, AShardLives);
    ekMachine:
      Blast(AX, AY, MachineExplosion, AShardLives);
    ekBoss:
      Blast(AX, AY, BossExplosion, AShardLives);
  end;
end;

procedure TExplosions.StrikeShards(const AStrike: TShardStrike);
begin
  FDebris.Strike(AStrike);
end;

procedure TExplosions.Blast(AX, AY: Single; const ALook: TExplosionLook;
  AShardLives: Integer);
var
  Flash: TFlash;
begin
  Flash.X := AX;
  Flash.Y := AY;
  Flash.Size := ALook.FlashSize;
  Flash.Age := 0;
  Flash.Life := ALook.FlashTicks;
  FFlashes.Add(Flash);

  FDebris.Burst(AX, AY, ALook.Debris, AShardLives);
  FFires.Add(Pour(AX, AY, ALook.Fire, FireSeedSalt));
  FPlumes.Add(Pour(AX, AY, ALook.Smoke, SmokeSeedSalt));

  QueueAftershocks(AX, AY, ALook);
end;

function TExplosions.Pour(AX, AY: Single; const ALook: TCloudLook;
  ASalt: Cardinal): TSmoke;
begin
  var Placement := Default(TDynamicPlacement);
  Placement.X := AX;
  Placement.Y := AY;
  Placement.Tint := ALook.Tint;
  var Seed := (Cardinal(Round(AX)) shl 16) xor Cardinal(Round(AY)) xor ASalt;
  Result := TSmoke.CreateLook(Placement, ALook.Puffs, 1, Seed);
  Result.FadeTo(0, ALook.Ticks);
end;

procedure TExplosions.QueueAftershocks(AX, AY: Single;
  const ALook: TExplosionLook);
var
  Aftershock: TAftershock;
begin
  for var i := 1 to ALook.Aftershocks do
  begin
    Aftershock.X := AX + (2 * FRandom.NextUnit - 1) * ALook.AftershockSpread;
    Aftershock.Y := AY + (2 * FRandom.NextUnit - 1) * ALook.AftershockSpread;
    Aftershock.Kind := ALook.AftershockKind;
    // Spread over the span, each one late by up to half a step
    var StepTicks: Single := ALook.AftershockTicks / ALook.Aftershocks;
    Aftershock.Delay := 1 + Round(StepTicks * (i - 1 + FRandom.NextUnit / 2));
    FAftershocks.Add(Aftershock);
  end;
end;

procedure TExplosions.TickAftershocks;
begin
  for var i := FAftershocks.Count - 1 downto 0 do
  begin
    var Aftershock := FAftershocks[i];
    Dec(Aftershock.Delay);
    if Aftershock.Delay > 0 then
    begin
      FAftershocks[i] := Aftershock;
      Continue;
    end;
    FAftershocks.Delete(i);
    Detonate(Aftershock.X, Aftershock.Y, Aftershock.Kind);
    FEcho;
  end;
end;

procedure TExplosions.Tick;
begin
  TickAftershocks;

  for var i := FFlashes.Count - 1 downto 0 do
  begin
    var Flash := FFlashes[i];
    Inc(Flash.Age);
    if Flash.Age >= Flash.Life then
      FFlashes.Delete(i)
    else
      FFlashes[i] := Flash;
  end;

  FDebris.Tick;
  TickClouds(FFires);
  TickClouds(FPlumes);
end;

procedure TExplosions.TickClouds(const AClouds: TObjectList<TSmoke>);
begin
  // A cloud stands where it was born: the placement holds the point,
  // the origin stays at the corner of the screen
  for var i := AClouds.Count - 1 downto 0 do
  begin
    AClouds[i].Tick(0, 0, True);
    if AClouds[i].Exhausted then
      AClouds.Delete(i);
  end;
end;

procedure TExplosions.DrawSmoke(const ACanvas: TDynamicCanvas;
  AOrigin: TSdlPoint; AAlpha: Single);
begin
  for var Plume in FPlumes do
    Plume.Draw(ACanvas, AOrigin.X, AOrigin.Y, AAlpha);
end;

procedure TExplosions.DrawFlash(const ACanvas: TDynamicCanvas;
  const AFlash: TFlash; AOrigin: TSdlPoint; AAlpha: Single);
begin
  var Share: Single := (AFlash.Age + AAlpha) / AFlash.Life;
  if Share > 1 then
    Share := 1;
  var Level: Single := Sqr(1 - Share);
  var CenterX: Single := AOrigin.X + AFlash.X;
  var CenterY: Single := AOrigin.Y + AFlash.Y;
  DrawGlow(ACanvas.Renderer, ACanvas.PointGlow, CenterX, CenterY,
    AFlash.Size * (1 + FlashGrowth * Share), Mix(White, FlashColor, Share),
    Level);
  DrawGlow(ACanvas.Renderer, ACanvas.PointGlow, CenterX, CenterY,
    AFlash.Size * FlashCoreShare, White, Level);
end;

procedure TExplosions.Draw(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
  AAlpha: Single);
begin
  for var Fire in FFires do
    Fire.Draw(ACanvas, AOrigin.X, AOrigin.Y, AAlpha);
  FDebris.Draw(AOrigin, AAlpha);
  for var Flash in FFlashes do
    DrawFlash(ACanvas, Flash, AOrigin, AAlpha);
end;

procedure TExplosions.Clear;
begin
  FFlashes.Clear;
  FFires.Clear;
  FPlumes.Clear;
  FAftershocks.Clear;
  FDebris.Clear;
end;

end.
