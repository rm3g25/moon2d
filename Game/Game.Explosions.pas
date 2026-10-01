{
  Game.Explosions - the one home of "something blew up": a flash, the
  debris of Effects.Debris and a smoke plume, sized by the kind of the
  explosion. A monster names its kind in monsters.json ("explosion");
  what each kind looks like lives here.

  The look only: the fragment fans of 2008 - the explosion's mechanics,
  the bullets that wound - are spawned by the monster and the game.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.Explosions;
{$I ..\Moon2D.inc}

interface

uses
  System.Generics.Collections, Sdl2.Core, Render.Brush, Monsters.Defs,
  Effects.Debris, Levels.Tint, Levels.Dynamics;

type
  TExplosions = class
  private type
    TFlash = record
      X, Y: Single;
      Size: Single;
      Age, Life: Integer;
    end;

    TExplosionLook = record
      Debris: TDebrisLook;
      FlashSize: Single; // units across
      FlashTicks: Integer;
      Smoke: TSmokeLook;
      SmokeTint: TColorTint;
      // The plume pours this long, thinning to nothing
      SmokeTicks: Integer;
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
    FPlumes: TObjectList<TSmoke>;
    FAftershocks: TList<TAftershock>;
    // Own stream, not Random: that one feeds the boss spawn table
    FRandom: TXorShift;
    procedure QueueAftershocks(AX, AY: Single; const ALook: TExplosionLook);
    procedure TickAftershocks;
    procedure Blast(AX, AY: Single; const ALook: TExplosionLook);
    procedure DrawFlash(const ACanvas: TDynamicCanvas; const AFlash: TFlash;
      AOrigin: TSdlPoint; AAlpha: Single);
  public
    constructor Create(ARenderer: PSdlRenderer; const AProbe: TSolidProbe);
    destructor Destroy; override;
    // AX/AY - the heart of the blast, screen units; ekNone does nothing
    procedure Detonate(AX, AY: Single; AKind: TExplosionKind);
    procedure Tick;
    // The plumes, behind the figures; AOrigin - the world's shake
    procedure DrawSmoke(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
      AAlpha: Single);
    // The flashes and the debris, over the bullets
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
    Debris: (Shards: 14; ShardSpeed: 7; ShardSize: 6; ShardCone: 150;
      RestSeconds: 4; Sparks: 40; SparkSpeed: 10);
    FlashSize: 96;
    FlashTicks: 5;
    Smoke: (Rate: 70; Life: 1.4; Size: 10; EndSize: 34; Opacity: 0.55;
      Angle: 90; Cone: 140; Speed: 30; Drag: 0.6; Lift: 8; Wind: 0;
      Turbulence: 4; Spin: 60; Flow: sfSteady; Frequency: 1; Heat: 0.7;
      EndTint: (R: 70; G: 70; B: 72));
    SmokeTint: (R: 52; G: 50; B: 48);
    SmokeTicks: 22;
    Aftershocks: 0; AftershockKind: ekNone; AftershockSpread: 0;
    AftershockTicks: 0);

  // The tank, the flying platform: a heavier body, more metal to throw
  MachineExplosion: TExplosions.TExplosionLook = (
    Debris: (Shards: 22; ShardSpeed: 8; ShardSize: 7; ShardCone: 160;
      RestSeconds: 5; Sparks: 60; SparkSpeed: 11);
    FlashSize: 130;
    FlashTicks: 6;
    Smoke: (Rate: 90; Life: 1.8; Size: 12; EndSize: 44; Opacity: 0.6;
      Angle: 90; Cone: 150; Speed: 36; Drag: 0.6; Lift: 8; Wind: 0;
      Turbulence: 5; Spin: 60; Flow: sfSteady; Frequency: 1; Heat: 0.8;
      EndTint: (R: 66; G: 66; B: 68));
    SmokeTint: (R: 46; G: 44; B: 42);
    SmokeTicks: 30;
    Aftershocks: 0; AftershockKind: ekNone; AftershockSpread: 0;
    AftershockTicks: 0);

  // The boss goes with a blast that fills the screen, then the wreck
  // pops for a second and a half
  BossExplosion: TExplosions.TExplosionLook = (
    Debris: (Shards: 40; ShardSpeed: 10; ShardSize: 9; ShardCone: 180;
      RestSeconds: 7; Sparks: 120; SparkSpeed: 13);
    FlashSize: 220;
    FlashTicks: 9;
    Smoke: (Rate: 140; Life: 2.4; Size: 16; EndSize: 64; Opacity: 0.65;
      Angle: 90; Cone: 160; Speed: 44; Drag: 0.6; Lift: 8; Wind: 0;
      Turbulence: 6; Spin: 50; Flow: sfSteady; Frequency: 1; Heat: 0.9;
      EndTint: (R: 62; G: 62; B: 64));
    SmokeTint: (R: 40; G: 38; B: 36);
    SmokeTicks: 50;
    Aftershocks: 5; AftershockKind: ekBarrel; AftershockSpread: 24;
    AftershockTicks: 50);

  FlashColor: TRgb = (R: 255; G: 190; B: 110);
  FlashGrowth = 0.3; // the flash swells by this share as it dies
  FlashCoreShare = 0.4; // the white core across, in flash sizes

constructor TExplosions.Create(ARenderer: PSdlRenderer;
  const AProbe: TSolidProbe);
begin
  inherited Create;
  FFlashes := TList<TFlash>.Create;
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
  FFlashes.Free;
  inherited;
end;

procedure TExplosions.Detonate(AX, AY: Single; AKind: TExplosionKind);
begin
  case AKind of
    ekBarrel:
      Blast(AX, AY, BarrelExplosion);
    ekMachine:
      Blast(AX, AY, MachineExplosion);
    ekBoss:
      Blast(AX, AY, BossExplosion);
  end;
end;

procedure TExplosions.Blast(AX, AY: Single; const ALook: TExplosionLook);
var
  Flash: TFlash;
begin
  Flash.X := AX;
  Flash.Y := AY;
  Flash.Size := ALook.FlashSize;
  Flash.Age := 0;
  Flash.Life := ALook.FlashTicks;
  FFlashes.Add(Flash);

  FDebris.Burst(AX, AY, ALook.Debris);

  var Placement := Default(TDynamicPlacement);
  Placement.X := AX;
  Placement.Y := AY;
  Placement.Tint := ALook.SmokeTint;
  var Plume := TSmoke.CreateLook(Placement, ALook.Smoke, 1,
    (Cardinal(Round(AX)) shl 16) xor Cardinal(Round(AY)));
  Plume.FadeTo(0, ALook.SmokeTicks);
  FPlumes.Add(Plume);

  QueueAftershocks(AX, AY, ALook);
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

  // A plume stands where it was born: the placement holds the point,
  // the origin stays at the corner of the screen
  for var i := FPlumes.Count - 1 downto 0 do
  begin
    FPlumes[i].Tick(0, 0, True);
    if FPlumes[i].Exhausted then
      FPlumes.Delete(i);
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
  FDebris.Draw(AOrigin, AAlpha);
  for var Flash in FFlashes do
    DrawFlash(ACanvas, Flash, AOrigin, AAlpha);
end;

procedure TExplosions.Clear;
begin
  FFlashes.Clear;
  FPlumes.Clear;
  FAftershocks.Clear;
  FDebris.Clear;
end;

end.
