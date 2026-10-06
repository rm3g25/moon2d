{
  Orbs.Swirl - a ring of orbs set turning around the spot it was called
  at, each gone when its time is up: the plainest thing a flock can be
  told to do. The developer's stand for the look of an orb and for its
  two ends; no reward of the game calls it.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Orbs.Swirl;
{$I ..\..\Moon2D.inc}

interface

uses
  Sdl2.Core, Render.Brush, Levels.Dynamics, Orbs.Flock;

type
  TSwirlOrb = class(TOrb)
  private
    FSeat: Single; // where on the lap it was born, 0..1
    FLife: Integer; // ticks
  end;

  TOrbSwirl = class
  private
    FFlock: TOrbFlock;
    FCenterX, FCenterY: Single;
    FClock: Integer; // ticks since the call
    // Own stream, not Random: that one feeds the boss spawn table
    FRandom: TXorShift;
    function SeatPoint(ASeat: Single): TSdlFPoint;
    procedure Turn(const AOrb: TSwirlOrb);
  public
    constructor Create(const ATint: TOrbTint);
    destructor Destroy; override;
    // A new ring around the point, in screen units, in place of the old
    procedure Cast(ACenterX, ACenterY: Single);
    // Every orb of the ring goes to dust
    procedure Scatter;
    function Turning: Boolean;
    procedure Tick;
    procedure Draw(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
      AAlpha: Single);
    procedure Clear;
  end;

implementation

const
  OrbCount = 60;
  // An oval a little larger than the hero's body
  RadiusX = 28;
  RadiusY = 35;
  LapTicks = 132; // four seconds
  AppearTicks = 10;
  LifeTicks = 165; // five seconds
  // And up to a second more, each orb its own: they go one by one
  LifeSpreadTicks = 33;
  DiceSeed = $5377726C; // "Swrl"

constructor TOrbSwirl.Create(const ATint: TOrbTint);
begin
  inherited Create;
  FFlock := TOrbFlock.Create(ATint);
  FRandom.Seed := DiceSeed;
end;

destructor TOrbSwirl.Destroy;
begin
  FFlock.Free;
  inherited;
end;

function TOrbSwirl.SeatPoint(ASeat: Single): TSdlFPoint;
begin
  var Lap: Single := 2 * Pi * (ASeat + FClock / LapTicks);
  Result.X := FCenterX + RadiusX * Cos(Lap);
  Result.Y := FCenterY + RadiusY * Sin(Lap);
end;

procedure TOrbSwirl.Cast(ACenterX, ACenterY: Single);
begin
  FFlock.Clear;
  FCenterX := ACenterX;
  FCenterY := ACenterY;
  FClock := 0;

  for var i := 0 to OrbCount - 1 do
  begin
    var Seat: Single := i / OrbCount;
    var Place := SeatPoint(Seat);
    var Orb := TSwirlOrb.Create(Place.X, Place.Y);
    Orb.FSeat := Seat;
    Orb.FLife := LifeTicks + Trunc(FRandom.NextUnit * LifeSpreadTicks);
    Orb.Size := 0;
    Orb.Level := 0;
    FFlock.Add(Orb);
  end;
end;

procedure TOrbSwirl.Scatter;
begin
  for var Orb in FFlock.Orbs do
    FFlock.Spend(Orb);
end;

function TOrbSwirl.Turning: Boolean;
begin
  Result := FFlock.Orbs.Count > 0;
end;

procedure TOrbSwirl.Turn(const AOrb: TSwirlOrb);
begin
  var Place := SeatPoint(AOrb.FSeat);
  AOrb.MoveTo(Place.X, Place.Y);

  var Shown: Single := AOrb.Age / AppearTicks;
  if Shown > 1 then
    Shown := 1;
  AOrb.Size := Shown;
  AOrb.Level := Shown;

  if AOrb.Age >= AOrb.FLife then
    FFlock.Implode(AOrb);
end;

procedure TOrbSwirl.Tick;
begin
  FFlock.Tick;
  Inc(FClock);
  for var Orb in FFlock.Orbs do
    Turn(Orb as TSwirlOrb);
end;

procedure TOrbSwirl.Draw(const ACanvas: TDynamicCanvas; AOrigin: TSdlPoint;
  AAlpha: Single);
begin
  FFlock.Draw(ACanvas, AOrigin, AAlpha);
end;

procedure TOrbSwirl.Clear;
begin
  FFlock.Clear;
end;

end.
