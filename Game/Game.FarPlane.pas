{
  Game.FarPlane - how far each layer of a chase's far plane has ridden
  (Levels.FarPlane): the near ground, the end of the tunnel, the city in the
  crater, the crater's rim.

  Units a second, as the layout has them. The tunnel runs at its peak while
  the cliff is in sight, the city at a share of it; once the tunnel's last
  element is past the left edge both ease to their cruise. The city brakes
  within the last stretch of its strip in proportion to what is left, to a
  floor, so its end never comes into sight; the ridge runs at a share of
  the city. The near ground and the fangs run at speeds of their own, no
  end to them. All of it runs at the belt's share of its cruise - the
  road's ramp starts the far plane and its stop stands it, brake floor
  included.
  The rules are those of the stand (tools/chase), tick for tick.

  It does not know the belt, the hero or SDL: the game hands in the belt's
  share every tick the road ticks, and draws by the offsets.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.FarPlane;
{$I ..\Moon2D.inc}

interface

uses
  Levels.FarPlane;

const
  // The fixed timestep: the layout's seconds in ticks
  FarPlaneTicksPerSecond = 33;
  // The tunnel counts as gone a little after its last element leaves: no
  // ease starts on a sliver still on the screen
  TunnelGoneMargin = 16;

type
  TFarPlane = class
  private
    FDef: TFarPlaneDef;
    FOffsets, FLastOffsets: TFarPlaneOffsets;
    FTunnelSpeed, FCitySpeed: Single;
    FTunnelGone: Boolean;
    FEaseTicks: Integer;
    // Units a second the schedule gives the tunnel and the city, before
    // the belt's share
    procedure ScheduleSpeeds(out ATunnel, ACity: Single);
    function BrakeCity(ACity: Single): Single;
  public
    // ADef - the level's; one without a screen never moves
    constructor Create(const ADef: TFarPlaneDef);
    // A death, a door, a new level: back to the start of the chase
    procedure Clear;
    // ABeltShare - the belt's speed as a share of its cruise, 0..1
    procedure Tick(ABeltShare: Single);
    // Between the last tick and this one, AAlpha of the way
    function OffsetsAt(AAlpha: Single): TFarPlaneOffsets;
    property Offsets: TFarPlaneOffsets read FOffsets;
    property TunnelGone: Boolean read FTunnelGone;
    // Units a second this tick, the belt's share in
    property TunnelSpeed: Single read FTunnelSpeed;
    property CitySpeed: Single read FCitySpeed;
  end;

implementation

uses
  System.Math;

function SmoothStep(AShare: Single): Single;
begin
  var Share := EnsureRange(AShare, 0.0, 1.0);
  Result := Share * Share * (3 - 2 * Share);
end;

constructor TFarPlane.Create(const ADef: TFarPlaneDef);
begin
  inherited Create;
  FDef := ADef;
  Clear;
end;

procedure TFarPlane.Clear;
begin
  FOffsets := Default(TFarPlaneOffsets);
  FLastOffsets := FOffsets;
  FTunnelSpeed := 0;
  FCitySpeed := 0;
  FTunnelGone := False;
  FEaseTicks := 0;
end;

procedure TFarPlane.ScheduleSpeeds(out ATunnel, ACity: Single);
begin
  var Speeds := FDef.Speeds;
  var CityInTunnel := Speeds.CityShareInTunnel * Speeds.TunnelPeak;
  if not FTunnelGone then
  begin
    ATunnel := Speeds.TunnelPeak;
    ACity := CityInTunnel;
    Exit;
  end;
  Inc(FEaseTicks);
  var Eased := SmoothStep(FEaseTicks / (Speeds.EaseSec * FarPlaneTicksPerSecond));
  ATunnel := Speeds.TunnelPeak + (Speeds.TunnelCruise - Speeds.TunnelPeak) * Eased;
  ACity := CityInTunnel + (Speeds.CityCruise - CityInTunnel) * Eased;
end;

function TFarPlane.BrakeCity(ACity: Single): Single;
begin
  var Speeds := FDef.Speeds;
  var Left := FDef.CityLength - FDef.ScreenWidth - FOffsets[fmCity];
  if Left >= Speeds.CityBrakeZone then
    Exit(ACity);
  if Left <= 0 then
    Exit(0);
  var Braked: Single := ACity * Left / Speeds.CityBrakeZone;
  // The floor would carry the strip's end past the edge on its last tick
  var Room: Single := Left * FarPlaneTicksPerSecond;
  Result := Min(Max(Speeds.CityLeast, Braked), Room);
end;

procedure TFarPlane.Tick(ABeltShare: Single);
var
  Tunnel, City: Single;
begin
  FLastOffsets := FOffsets;
  if not FDef.Present then
    Exit;

  ScheduleSpeeds(Tunnel, City);
  if FDef.TunnelEnd - FOffsets[fmTunnel] < -TunnelGoneMargin then
    FTunnelGone := True;
  City := BrakeCity(City);

  FTunnelSpeed := Tunnel * ABeltShare;
  FCitySpeed := City * ABeltShare;
  FOffsets[fmTunnel] := FOffsets[fmTunnel] + FTunnelSpeed / FarPlaneTicksPerSecond;
  FOffsets[fmCity] := FOffsets[fmCity] + FCitySpeed / FarPlaneTicksPerSecond;
  FOffsets[fmRidge] := FOffsets[fmRidge] +
    FCitySpeed * FDef.Speeds.RidgeShareOfCity / FarPlaneTicksPerSecond;
  FOffsets[fmGround] := FOffsets[fmGround] +
    FDef.Speeds.Ground * ABeltShare / FarPlaneTicksPerSecond;
  FOffsets[fmFangs] := FOffsets[fmFangs] +
    FDef.Speeds.Fangs * ABeltShare / FarPlaneTicksPerSecond;
end;

function TFarPlane.OffsetsAt(AAlpha: Single): TFarPlaneOffsets;
begin
  for var Motion := Low(TFarPlaneMotion) to High(TFarPlaneMotion) do
    Result[Motion] := FLastOffsets[Motion] +
      (FOffsets[Motion] - FLastOffsets[Motion]) * AAlpha;
end;

end.
