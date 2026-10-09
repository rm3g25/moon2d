{
  Bullets - bullets and bullet bursts, ported from bullets.pas (2008).

  Physics per tick: X += DX; Y += DY; DY += Gravity/100 - a bullet is a
  tiny projectile with real ballistics. Weapon "influence" is that
  gravity: the pistol fires at influence 1 (near-flat), explosion
  fragments at ~28 (they arc and rain down).

  Two bursts exist in the game: the hero's own and one shared by all
  monsters. Contact=True (normal shots) lets a hero bullet destroy a
  monster bullet mid-air - anti-missile defense by aim. Explosion
  fragments spawn with Contact=False INTO THE HERO'S burst: they damage
  monsters (chain-reaction barrels) but do not intercept.

  A bullet never just disappears against a wall: it switches to
  bsBursting and plays destruction frames 2..8 in place.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Bullets;
{$I ..\Moon2D.inc}

interface

uses
  System.SysUtils, System.Math, System.Generics.Collections,
  Sdl2.Core, Render.Sprites, Sprites.Sets;

type
  // The k/t fan formula of 2008 appears five times across the game with
  // only these four numbers changing - the classic travel test: values
  // that always move together become a record
  TFanShape = record
    Rows: Integer;        // k range: vertical spread of spawn rows
    Cols: Integer;        // t range: horizontal spread
    BaseSpeed: Integer;
    SpeedSpread: Integer; // fragment speed = BaseSpeed + Random(SpeedSpread)
  end;

  TBulletStatus = (bsFlying, bsBursting, bsInactive);

  TBullet = class
  private
    FX, FY: Double;
    FDX, FDY: Double;
    FGravity: Double;      // 'dyy': DY += FGravity/100 per tick
    FStatus: TBulletStatus;
    FBurstFrame: Double;   // 1 -> 8, +0.25 per draw, then inactive
    FContact: Boolean;     // participates in bullet-vs-bullet interception
  public
    // Parameter order matches TBurst.NewBullet - the one caller; two
    // different orders for the same six values was a transposition trap
    constructor Create(ASpeed: Integer; AX, AY: Double;
      AAngleDegrees, AInfluence: Integer; AContact: Boolean);
    procedure Move;        // one tick of flight
    procedure StartBurst;  // hit something: explode in place
    procedure StartBurstSliding; // hit a wall: explode, keep 1/8 inertia

    property X: Double read FX;
    property Y: Double read FY;
    property DX: Double read FDX write FDX;
    property DY: Double read FDY write FDY;
    property Status: TBulletStatus read FStatus write FStatus;
    property Contact: Boolean read FContact;
  end;

  TBurst = class
  private
    FBullets: TObjectList<TBullet>;
    FCache: TSpriteCache;     // rooted at weapon\
    FSpriteSet: TSpriteSet;   // owned; nil = folder era
    FFlightTexture: PSdlTexture;
    FBurstTextures: array [2..8] of PSdlTexture;
  public
    // ABaseName: 'bullet' for the hero, 'bull' for monsters -
    // flight frame <name>.bmp, destruction frames <name>2..8.bmp
    constructor Create(const ARenderer: PSdlRenderer;
      const ABaseName: string);
    destructor Destroy; override;

    procedure NewBullet(ASpeed: Integer; AX, AY: Double;
      AAngleDegrees, AInfluence: Integer; AContact: Boolean);
    // Screen transition of 2008 wiped both bursts (moon.dpr 1089-1090):
    // bullets do not follow the hero through doors.
    procedure Clear;
    // Move all, advance burst animations, drop inactive ones.
    procedure Update;
    procedure Draw(const ASprites: TSpriteRenderer);

    // The k/t fan formula of moon.dpr with the shape as a parameter - the
    // ice-form shatter, the bonus explosion and the boss's fans are all
    // this one template wearing different numbers.
    // Fragments carry Contact=False and land in WHICHEVER burst this is
    // called on.
    procedure SpawnFan(ACenterX, ACenterY: Double; const AShape: TFanShape);

    property Bullets: TObjectList<TBullet> read FBullets;
  end;

implementation

const
  BulletQuad = 32;    // a bullet draws as a full 32-unit sprite quad
  BurstFrameStep = 0.25;

// ---------------------------------------------------------------------------
// TBullet
// ---------------------------------------------------------------------------

constructor TBullet.Create(ASpeed: Integer; AX, AY: Double;
  AAngleDegrees, AInfluence: Integer; AContact: Boolean);
begin
  inherited Create;
  FX := AX;
  FY := AY;
  FStatus := bsFlying;
  FBurstFrame := 1;
  FContact := AContact;
  // Verbatim 2008 trigonometry, including the /57 'radians'
  FDY := -Sin(AAngleDegrees / 57) * ASpeed;
  FDX := Cos(AAngleDegrees / 57) * ASpeed;
  FGravity := AInfluence;
end;

procedure TBullet.Move;
begin
  if FStatus <> bsFlying then
    Exit;

  FX := FX + FDX;
  FY := FY + FDY;
  FDY := FDY + FGravity / 100;
end;

procedure TBullet.StartBurst;
begin
  FStatus := bsBursting;
  FDX := 0;
  FDY := 0;
end;

procedure TBullet.StartBurstSliding;
begin
  FStatus := bsBursting;
  FDX := FDX / 8;
  FDY := FDY / 8;
end;

// ---------------------------------------------------------------------------
// TBurst
// ---------------------------------------------------------------------------

constructor TBurst.Create(const ARenderer: PSdlRenderer;
  const ABaseName: string);
begin
  inherited Create;
  FBullets := TObjectList<TBullet>.Create(True);
  FCache := TSpriteCache.Create(ARenderer);
  if FileExists(SpriteSetsDir + 'weapon.mset') then
  begin
    FSpriteSet := TSpriteSet.Create(SpriteSetsDir + 'weapon.mset');
    FCache.AttachSpriteSet(FSpriteSet);
  end;
  FFlightTexture := FCache.Get(ABaseName + '.png');
  for var i := Low(FBurstTextures) to High(FBurstTextures) do
    FBurstTextures[i] := FCache.Get(ABaseName + IntToStr(i) + '.png');
end;

destructor TBurst.Destroy;
begin
  FBullets.Free;
  FCache.Free;
  FSpriteSet.Free;
  inherited;
end;

// ASpeed in units per tick; AInfluence is 2008 'influence' - the
// gravity fed into DY += AInfluence/100; AContact - see the unit header
procedure TBurst.NewBullet(ASpeed: Integer; AX, AY: Double;
  AAngleDegrees, AInfluence: Integer; AContact: Boolean);
begin
  FBullets.Add(TBullet.Create(ASpeed, AX, AY, AAngleDegrees,
    AInfluence, AContact));
end;

procedure TBurst.Clear;
begin
  FBullets.Clear; // TObjectList owns the bullets and frees them here
end;

procedure TBurst.Update;
begin
  for var i := FBullets.Count - 1 downto 0 do
    if FBullets[i].Status = bsInactive then
      FBullets.Delete(i)
    else
      FBullets[i].Move;
end;

procedure TBurst.Draw(const ASprites: TSpriteRenderer);
var
  Dest: TSdlRect;
begin
  for var Bullet in FBullets do
  begin
    // Verbatim quad of TBullet.Put: x-16..x+16, y-48..y-16
    Dest.X := Round(Bullet.FX) - BulletQuad div 2;
    Dest.Y := Round(Bullet.FY) - BulletQuad - BulletQuad div 2;
    Dest.W := BulletQuad;
    Dest.H := BulletQuad;

    case Bullet.Status of
      bsFlying:
        ASprites.DrawRect(FFlightTexture, Dest);
      bsBursting:
        begin
          if Round(Bullet.FBurstFrame) > High(FBurstTextures) then
            Bullet.FStatus := bsInactive
          else
            ASprites.DrawRect(
              FBurstTextures[EnsureRange(Round(Bullet.FBurstFrame),
                Low(FBurstTextures), High(FBurstTextures))],
              Dest);
          Bullet.FBurstFrame := Bullet.FBurstFrame + BurstFrameStep;
        end;
    end;
  end;
end;

procedure TBurst.SpawnFan(ACenterX, ACenterY: Double;
  const AShape: TFanShape);
begin
  // The 18 inside the angle term is part of the QUOTED 2008 formula,
  // not AShape.Cols in disguise: the original used 18 for every fan
  // size. Do not "fix" it - the spray sculpture depends on it.
  for var k := 1 to AShape.Rows do
    for var t := 1 to AShape.Cols do
      NewBullet(AShape.BaseSpeed + Random(AShape.SpeedSpread),
        ACenterX + 8 + t + Random(7) - 7,
        ACenterY + 8 + k * 2,
        108 + k - Round(t * 2 * ((18 + k) / k)),
        30 - Round(k / 4),
        False);
end;

end.
