{
  Orbs.Shots - the look of the orb gun's shots: a black orb of the moon
  form for every orb-look bullet of a burst (Bullets, blOrb), riding it.
  The bullet is the shot - its flight, what it meets and what that costs
  are the burst's and the game's; the orb is only how it is seen. A
  bullet spent - burst, struck, gone - leaves its orb to dust where it
  was.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Orbs.Shots;
{$I ..\..\Moon2D.inc}

interface

uses
  System.Generics.Collections, Sdl2.Core, Levels.Dynamics, Bullets,
  Orbs.Flock;

type
  TOrbShots = class
  private type
    TShotOrb = record
      Bullet: TBullet;
      Orb: TOrb;
    end;
  private
    FFlock: TOrbFlock;
    FShots: TList<TShotOrb>;
    function Riding(ABullet: TBullet): Boolean;
    procedure Spend(const ABullets: TObjectList<TBullet>);
  public
    constructor Create;
    destructor Destroy; override;
    // Once a tick, after what the bullets met this tick is settled: an orb
    // for every orb-look bullet in flight, where the bullet's picture is;
    // the orb of a bullet no more in flight, or no more in ABullets, goes
    // to dust
    procedure Tick(const ABullets: TObjectList<TBullet>);
    procedure Clear;
    procedure Draw(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
      AAlpha: Single);
    property Flock: TOrbFlock read FFlock;
  end;

implementation

uses
  Render.Sprites;

{ TOrbShots }

constructor TOrbShots.Create;
begin
  inherited Create;
  FFlock := TOrbFlock.Create(MoonOrbTint);
  FShots := TList<TShotOrb>.Create;
end;

destructor TOrbShots.Destroy;
begin
  FShots.Free;
  FFlock.Free;
  inherited;
end;

function TOrbShots.Riding(ABullet: TBullet): Boolean;
begin
  for var Shot in FShots do
    if Shot.Bullet = ABullet then
      Exit(True);
  Result := False;
end;

// Before the flock's tick drops what is spent: no shot keeps an orb that
// is gone
procedure TOrbShots.Spend(const ABullets: TObjectList<TBullet>);
begin
  for var i := FShots.Count - 1 downto 0 do
  begin
    var Shot := FShots[i];
    var Index := ABullets.IndexOf(Shot.Bullet);
    // In the list it is alive: a bullet born where a freed one was is no
    // orb's unless it is an orb's look
    var StillFlies := (Index >= 0) and (ABullets[Index].Look = blOrb) and
      (ABullets[Index].Status = bsFlying);
    if StillFlies then
      Continue;
    FFlock.Spend(Shot.Orb);
    FShots.Delete(i);
  end;
end;

// A bullet's picture hangs a sprite over its point (as BulletStretch has
// it in Game.Moon): the orb is where the picture is
procedure TOrbShots.Tick(const ABullets: TObjectList<TBullet>);
begin
  Spend(ABullets);
  FFlock.Tick;
  for var Bullet in ABullets do
  begin
    if (Bullet.Look <> blOrb) or (Bullet.Status <> bsFlying) or
      Riding(Bullet) then
      Continue;
    var Shot: TShotOrb;
    Shot.Bullet := Bullet;
    Shot.Orb := TOrb.Create(Bullet.X, Bullet.Y - SpriteSize);
    Shot.Orb.Armed := False;
    FFlock.Add(Shot.Orb);
    FShots.Add(Shot);
  end;
  for var Shot in FShots do
    Shot.Orb.MoveTo(Shot.Bullet.X, Shot.Bullet.Y - SpriteSize);
end;

procedure TOrbShots.Clear;
begin
  FFlock.Clear;
  FShots.Clear;
end;

procedure TOrbShots.Draw(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
  AAlpha: Single);
begin
  FFlock.Draw(ACanvas, AOrigin, AAlpha);
end;

end.
