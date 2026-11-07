{
  Game.Wheel - a wheel off its axle: the Ram's front wheel, broken off
  once its armour is gone, and its rear one, thrown down out of its well
  by the jet once the hull is off the road. The first hops off the road,
  the second falls onto it; each strikes the road, bounces lower and
  lower, losing speed at every strike, and once a bounce has too little in
  it, rolls. All the while it goes to the right at an even pace, turning
  by the way it has rolled, and is gone once it has rolled off the right
  edge of the screen. Its touch is the hull's: it wounds and throws the
  hero, away from its middle. A bullet that meets its rim is thrown off -
  it loses nothing.

  Not here: why it came off and what its touch does to the hero - the Ram
  and the game say; its picture - the hull's wheel (Monsters.Hull).

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.Wheel;
{$I ..\Moon2D.inc}

interface

uses
  Sdl2.Core;

const
  // Units a tick it rolls to the right, from the moment it is off
  WheelRollPace = 3.0;
  // Units a tick up as it hops off; the moon's pull, the hero's and the
  // wrecks', brings it down from about 22 over the road
  WheelHopKick = 2.5;
  // Units a tick down the jet throws a dropped one at
  WheelSpitKick = 4.0;
  WheelGravity = 2 / 14;
  // The share of its speed a strike gives back up: a dropped one, struck
  // at about 5.5, bounces to about 40, 16 and 7; a hopped one to about 10
  // and 5
  WheelBounceKeep = 0.6;
  // A bounce slower than this, units a tick, and it rolls
  WheelRestRise = 1.0;

type
  TLooseWheel = record
  private
    FRunning: Boolean;
    FCenter, FLastCenter: TSdlFPoint;
    FRadius: Single;
    // Where its middle stands rolling on the road
    FRollY: Single;
    // Units a tick up, below 0 down; in the air till it comes down
    FRise: Single;
    FAirborne: Boolean;
    FStruck: Single;
    // Degrees clockwise
    FTurn, FLastTurn: Single;
    procedure Launch(const ACenter: TSdlFPoint; ARadius, ARollY,
      AKick: Single);
    procedure Roll;
    function Hop: Boolean;
  public
    // Off its axle with its middle at ACenter, its bottom on the road,
    // hopping off
    procedure Start(const ACenter: TSdlFPoint; ARadius: Single);
    // Thrown down with its middle at ACenter, over the road where its
    // middle rolls at ARollY
    procedure Drop(const ACenter: TSdlFPoint; ARadius, ARollY: Single);
    procedure Stop;
    // True the tick it strikes the road
    function Tick: Boolean;
    function Running: Boolean;
    // Units a tick down it struck the road at this tick; 0 - it did not
    function Struck: Single;
    // The bottom of its rim
    function Contact: TSdlFPoint;
    // AAlpha of the way from the last tick to this one
    function CenterAt(AAlpha: Single): TSdlFPoint;
    function TurnAt(AAlpha: Single): Single;
    function Touches(const ABody: TSdlFRect): Boolean;
    // Away from its middle: -1 left, 1 right; 0 - straight up, where the
    // edge of the screen on that side leaves the body no room past it
    function AwaySide(const ABody: TSdlFRect): Integer;
    // Where the stretch AFrom-ATo first meets its rim, and the rim's way
    // out there; a stretch begun inside meets it where it began
    function Strike(const AFrom, ATo: TSdlFPoint; out AAt,
      ANormal: TSdlFPoint): Boolean;
  end;

implementation

uses
  System.Math, Game.Space;

procedure TLooseWheel.Start(const ACenter: TSdlFPoint; ARadius: Single);
begin
  Launch(ACenter, ARadius, ACenter.Y, WheelHopKick);
end;

procedure TLooseWheel.Drop(const ACenter: TSdlFPoint; ARadius, ARollY: Single);
begin
  Launch(ACenter, ARadius, ARollY, -WheelSpitKick);
end;

procedure TLooseWheel.Launch(const ACenter: TSdlFPoint; ARadius, ARollY,
  AKick: Single);
begin
  FRunning := True;
  FCenter := ACenter;
  FLastCenter := ACenter;
  FRadius := ARadius;
  FRollY := ARollY;
  FRise := AKick;
  FAirborne := True;
  FStruck := 0;
  FTurn := 0;
  FLastTurn := 0;
end;

procedure TLooseWheel.Stop;
begin
  FRunning := False;
  FAirborne := False;
  FStruck := 0;
end;

function TLooseWheel.Running: Boolean;
begin
  Result := FRunning;
end;

function TLooseWheel.Struck: Single;
begin
  Result := FStruck;
end;

function TLooseWheel.Contact: TSdlFPoint;
begin
  Result.X := FCenter.X;
  Result.Y := FCenter.Y + FRadius;
end;

function TLooseWheel.Tick: Boolean;
begin
  Result := False;
  FStruck := 0;
  if not FRunning then
    Exit;
  FLastCenter := FCenter;
  FLastTurn := FTurn;
  Roll;
  Result := Hop;
  if FCenter.X - FRadius > ScreenWidth then
    Stop;
end;

// To the right, turning clockwise by the way it rolls, the way SDL counts
procedure TLooseWheel.Roll;
const
  WrapDegrees = 3600;
begin
  FCenter.X := FCenter.X + WheelRollPace;
  FTurn := FTurn + RadToDeg(WheelRollPace / FRadius);
  if FTurn > WrapDegrees then
  begin
    var WholeTurnDegrees: Single := 360 * Trunc(FTurn / 360);
    FTurn := FTurn - WholeTurnDegrees;
    FLastTurn := FLastTurn - WholeTurnDegrees;
  end;
end;

// True as it strikes the road; it bounces off it with a share of its
// speed, or rolls
function TLooseWheel.Hop: Boolean;
begin
  Result := False;
  if not FAirborne then
    Exit;
  FCenter.Y := FCenter.Y - FRise;
  FRise := FRise - WheelGravity;
  if FCenter.Y < FRollY then
    Exit;
  FCenter.Y := FRollY;
  FStruck := -FRise;
  FRise := FStruck * WheelBounceKeep;
  if FRise < WheelRestRise then
  begin
    FRise := 0;
    FAirborne := False;
  end;
  Result := True;
end;

function TLooseWheel.CenterAt(AAlpha: Single): TSdlFPoint;
begin
  Result.X := FLastCenter.X + (FCenter.X - FLastCenter.X) * AAlpha;
  Result.Y := FLastCenter.Y + (FCenter.Y - FLastCenter.Y) * AAlpha;
end;

function TLooseWheel.TurnAt(AAlpha: Single): Single;
begin
  Result := FLastTurn + (FTurn - FLastTurn) * AAlpha;
end;

// The nearest point of the body to its middle, inside its rim
function TLooseWheel.Touches(const ABody: TSdlFRect): Boolean;
begin
  if not FRunning then
    Exit(False);
  var NearestX := EnsureRange(FCenter.X, ABody.X, ABody.X + ABody.W);
  var NearestY := EnsureRange(FCenter.Y, ABody.Y, ABody.Y + ABody.H);
  Result := Hypot(NearestX - FCenter.X, NearestY - FCenter.Y) < FRadius;
end;

// The share of the stretch on the circle: the nearer root of
// |AFrom + Share * Way - Center| = Radius
function TLooseWheel.Strike(const AFrom, ATo: TSdlFPoint; out AAt,
  ANormal: TSdlFPoint): Boolean;
const
  // Shorter than this, a way points nowhere
  NoWay = 1E-6;
begin
  AAt := ATo;
  ANormal.X := 0;
  ANormal.Y := -1;
  if not FRunning then
    Exit(False);
  var WayX: Single := ATo.X - AFrom.X;
  var WayY: Single := ATo.Y - AFrom.Y;
  var OffX: Single := AFrom.X - FCenter.X;
  var OffY: Single := AFrom.Y - FCenter.Y;
  var Square: Single := WayX * WayX + WayY * WayY;
  var Half: Single := OffX * WayX + OffY * WayY;
  var Outside: Single := OffX * OffX + OffY * OffY - FRadius * FRadius;
  var Share: Single := 0;
  if Outside > 0 then
  begin
    var Reach: Single := Half * Half - Square * Outside;
    if (Square < NoWay) or (Reach < 0) then
      Exit(False);
    Share := (-Half - Sqrt(Reach)) / Square;
    if (Share < 0) or (Share > 1) then
      Exit(False);
  end;
  AAt.X := AFrom.X + WayX * Share;
  AAt.Y := AFrom.Y + WayY * Share;
  var OutX: Single := AAt.X - FCenter.X;
  var OutY: Single := AAt.Y - FCenter.Y;
  var FromMiddle: Single := Hypot(OutX, OutY);
  if FromMiddle > NoWay then
  begin
    ANormal.X := OutX / FromMiddle;
    ANormal.Y := OutY / FromMiddle;
  end;
  Result := True;
end;

function TLooseWheel.AwaySide(const ABody: TSdlFRect): Integer;
begin
  Result := 1;
  var Room := ScreenWidth - (FCenter.X + FRadius);
  if ABody.X + ABody.W / 2 < FCenter.X then
  begin
    Result := -1;
    Room := FCenter.X - FRadius;
  end;
  if Room < ABody.W then
    Result := 0;
end;

end.
