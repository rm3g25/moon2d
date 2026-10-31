{
  Game.Belt - the treadmill of the chase. The machine drives off and does
  not leave the screen: the road slides left under it instead, and
  everything of the world rides the road. This is only the road's motion:
  how fast it runs this tick and how far it has run. It comes up to speed
  from a standstill and runs down to one with no jerk either way - a
  ramp begun in the middle of another starts from the speed it finds.

  It does not know the Ram, the hero or the road's picture: the game
  starts and stops it, carries the world by its speed and slides the road
  by how far it has run. It does not touch SDL.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.Belt;
{$I ..\Moon2D.inc}

interface

const
  // The road of the chase: 33 units a second at 33 Hz
  BeltCruise = 1.0;
  // From a standstill to cruise, and from cruise to a standstill: 2 s
  BeltRampTicks = 66;

type
  TBelt = class
  private
    FSpeed: Single;
    // The ramp under way: from, to, ticks into it
    FRampFrom, FRampTo: Single;
    FRampTicks: Integer;
    FTravel, FLastTravel: Double;
    procedure RampTo(ASpeed: Single);
  public
    constructor Create;
    // Up to cruise; nothing for one that runs or speeds up already
    procedure Start;
    // Down to a standstill; nothing for one that stands or runs down
    procedure Stop;
    // A death, a door, a new level: standing, and nothing run
    procedure Clear;
    procedure Tick;
    // Moving, or about to
    function Running: Boolean;
    // How far it has run between the last tick and this one, AAlpha of
    // the way; units, growing as the road goes left
    function TravelAt(AAlpha: Single): Double;
    // Units the road has gone left this tick: what it carries goes as far
    property Speed: Single read FSpeed;
    property Travel: Double read FTravel;
  end;

implementation

function SmoothStep(AShare: Single): Single;
begin
  var Share := AShare;
  if Share < 0 then
    Share := 0
  else if Share > 1 then
    Share := 1;
  Result := Share * Share * (3 - 2 * Share);
end;

constructor TBelt.Create;
begin
  inherited Create;
  Clear;
end;

procedure TBelt.RampTo(ASpeed: Single);
begin
  FRampFrom := FSpeed;
  FRampTo := ASpeed;
  FRampTicks := 0;
end;

procedure TBelt.Start;
begin
  if FRampTo <> BeltCruise then
    RampTo(BeltCruise);
end;

procedure TBelt.Stop;
begin
  if FRampTo <> 0 then
    RampTo(0);
end;

procedure TBelt.Clear;
begin
  FSpeed := 0;
  FRampFrom := 0;
  FRampTo := 0;
  FRampTicks := BeltRampTicks;
  FTravel := 0;
  FLastTravel := 0;
end;

procedure TBelt.Tick;
begin
  FLastTravel := FTravel;
  if FRampTicks < BeltRampTicks then
  begin
    Inc(FRampTicks);
    FSpeed := FRampFrom +
      (FRampTo - FRampFrom) * SmoothStep(FRampTicks / BeltRampTicks);
  end;
  FTravel := FTravel + FSpeed;
end;

function TBelt.Running: Boolean;
begin
  Result := (FSpeed > 0) or (FRampTo > 0);
end;

function TBelt.TravelAt(AAlpha: Single): Double;
begin
  Result := FLastTravel + (FTravel - FLastTravel) * AAlpha;
end;

end.
