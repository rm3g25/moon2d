{
  Pads.Flights - the flights of a pad group rebuild: every pad from its
  cell to the cell the assignment gave it (Pads.Formations), and when it
  sets off. Pure functions; Pads.World flies the pads along them.

  A flight has two legs, across and down in either order - an L - and a
  pause on its corner. A leg sets off, throws the pad at up to TopSpeed
  and brakes it onto the cell.

  Pads in front do not fly through one another: the plan takes the space
  every pad holds tick by tick, the loaded pads first, then the longest
  flights. A pad that would cut into one already planned tries its legs
  the other way round, then waits at home a little longer, up to about a
  second. When nothing fits, it goes deep: into the depth behind the
  others, where it is neither a floor nor a body, and comes out on its
  cell. Pads in the depth may pass through one another. A loaded pad -
  the hero stands on it - never goes deep: when it fits nowhere, the plan
  fails and the formation is thrown again.

  A pad going deep leaves the front at the very start of the rebuild,
  before its flight sets off: whether it was loaded was asked at that
  tick, so no rider is ever taken into the depth.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Pads.Flights;
{$I ..\..\Moon2D.inc}

interface

uses
  Render.Brush, Pads.Formations;

type
  // Ticks count from the start of the rebuild; places are the pad's
  // top-left corner, in screen units
  TPadFlight = record
    FromX, FromY: Double;
    CornerX, CornerY: Double;
    ToX, ToY: Double;
    FirstDistance, SecondDistance: Double;
    FirstTicks, SecondTicks: Integer;
    CornerTicks: Integer; // the pause on the corner; 0 for a single leg
    Depart: Integer;
    // Flown in the depth behind the others
    Deep: Boolean;
    // On the cell; a deep pad starts coming out of the depth
    function Arrive: Integer;
    // Over: on the cell and, for a deep pad, out of the depth
    function Done: Integer;
    procedure Place(ATick: Integer; out AX, AY: Double);
    // In the depth: neither a floor nor a body
    function Behind(ATick: Integer): Boolean;
    // 0 in front .. 1 all the way into the depth; ATime between ticks
    function Depth(ATime: Single): Single;
  end;

  TPadFlights = TArray<TPadFlight>;

// AStart[i] to ATarget[i] for every pad; ALoaded - a rider stands on the
// pad; ARelease - ticks after the start before which the pad stays home.
// False when a pad fits nowhere: a loaded one in front, another in front
// or in the depth.
function TryPlanFlights(var ARandom: TXorShift;
  const AStart, ATarget: TPadCells; const ALoaded: TArray<Boolean>;
  const ARelease: TArray<Integer>; out AFlights: TPadFlights): Boolean;

implementation

uses
  System.Math, Render.Sprites;

const
  // The choreography of the plan, to be tuned on screen: the throw, the
  // rate a leg speeds up and brakes at - a rebuild of screen 17 takes
  // about one and a half seconds with it - and the pause on the corner
  TopSpeed = 14.0; // units a tick
  Acceleration = 2.0; // units a tick a tick
  CornerPauseTicks = 3;
  // Into the depth and out of it
  SinkTicks = 6;
  // A pad that fits nowhere waits at home this much longer at most,
  // step by step
  MaxHoldTicks = 33; // about a second
  HoldStepTicks = 3;
  // A leg's time a hair over a whole tick from arithmetic is that tick
  TimeSlack = 1e-9;
  // Bodies side by side touch: arithmetic leaving them a hair closer
  // than a cell apart does not make them cut
  TouchSlack = 1e-6;

// ---------------------------------------------------------------------------
// A leg: up to speed, on at it, braking - the same rate both ways
// ---------------------------------------------------------------------------

// The time a leg speeds up for: to TopSpeed, or less on a leg too short
// to reach it before it must brake
function RampTime(ADistance: Double): Double;
begin
  Result := Min(TopSpeed / Acceleration, Sqrt(ADistance / Acceleration));
end;

function LegTime(ADistance: Double): Double;
begin
  var Ramp := RampTime(ADistance);
  var RampDistance := Acceleration * Ramp * Ramp;
  Result := 2 * Ramp + (ADistance - RampDistance) / (Acceleration * Ramp);
end;

function LegTicks(ADistance: Double): Integer;
begin
  Result := 0;
  if ADistance > 0 then
    Result := Ceil(LegTime(ADistance) - TimeSlack);
end;

// The distance covered ATick into a leg flown in ATicks: the leg's own
// time stretched over its whole ticks
function LegCovered(ADistance: Double; ATick, ATicks: Integer): Double;
begin
  if ATick >= ATicks then
    Exit(ADistance);
  var Total := LegTime(ADistance);
  var Time := ATick * Total / ATicks;
  var Ramp := RampTime(ADistance);
  if Time <= Ramp then
    Exit(Acceleration * Time * Time / 2);
  if Time <= Total - Ramp then
    Exit(Acceleration * Ramp * Ramp / 2 + Acceleration * Ramp * (Time - Ramp));
  var Rest := Total - Time;
  Result := ADistance - Acceleration * Rest * Rest / 2;
end;

// ---------------------------------------------------------------------------
// TPadFlight
// ---------------------------------------------------------------------------

function TPadFlight.Arrive: Integer;
begin
  Result := Depart + FirstTicks + CornerTicks + SecondTicks;
end;

function TPadFlight.Done: Integer;
begin
  Result := Arrive;
  if Deep then
    Inc(Result, SinkTicks);
end;

procedure TPadFlight.Place(ATick: Integer; out AX, AY: Double);
begin
  AX := FromX;
  AY := FromY;
  var Time := ATick - Depart;
  if Time <= 0 then
    Exit;
  if Time < FirstTicks then
  begin
    var Share := LegCovered(FirstDistance, Time, FirstTicks) / FirstDistance;
    AX := FromX + (CornerX - FromX) * Share;
    AY := FromY + (CornerY - FromY) * Share;
    Exit;
  end;

  Dec(Time, FirstTicks);
  AX := CornerX;
  AY := CornerY;
  if Time < CornerTicks then
    Exit;
  Dec(Time, CornerTicks);
  if Time < SecondTicks then
  begin
    var Share := LegCovered(SecondDistance, Time, SecondTicks) / SecondDistance;
    AX := CornerX + (ToX - CornerX) * Share;
    AY := CornerY + (ToY - CornerY) * Share;
    Exit;
  end;
  AX := ToX;
  AY := ToY;
end;

function TPadFlight.Behind(ATick: Integer): Boolean;
begin
  Result := Deep and (ATick < Done);
end;

function TPadFlight.Depth(ATime: Single): Single;
begin
  if not Deep then
    Exit(0);
  if ATime < SinkTicks then
    Exit(EnsureRange(ATime / SinkTicks, 0.0, 1.0));
  if ATime < Arrive then
    Exit(1);
  Result := EnsureRange((Done - ATime) / SinkTicks, 0.0, 1.0);
end;

// ---------------------------------------------------------------------------
// The plan
// ---------------------------------------------------------------------------

function BuildFlight(const AFrom, ATo: TPadCell; AAcrossFirst: Boolean;
  ADepart: Integer; ADeep: Boolean): TPadFlight;
begin
  Result.FromX := AFrom.Col * TileSize;
  Result.FromY := AFrom.Row * TileSize;
  Result.ToX := ATo.Col * TileSize;
  Result.ToY := ATo.Row * TileSize;
  Result.CornerX := Result.FromX;
  Result.CornerY := Result.ToY;
  if AAcrossFirst then
  begin
    Result.CornerX := Result.ToX;
    Result.CornerY := Result.FromY;
  end;
  Result.FirstDistance := Abs(Result.CornerX - Result.FromX) +
    Abs(Result.CornerY - Result.FromY);
  Result.SecondDistance := Abs(Result.ToX - Result.CornerX) +
    Abs(Result.ToY - Result.CornerY);
  Result.FirstTicks := LegTicks(Result.FirstDistance);
  Result.SecondTicks := LegTicks(Result.SecondDistance);
  Result.CornerTicks := 0;
  if (Result.FirstDistance > 0) and (Result.SecondDistance > 0) then
    Result.CornerTicks := CornerPauseTicks;
  Result.Depart := ADepart;
  Result.Deep := ADeep;
end;

// The space the pad holds at the tick, for the plan. A deep pad holds its
// cell from the tick it starts coming out of the depth on it.
function HoldsSpace(const AFlight: TPadFlight; ATick: Integer): Boolean;
begin
  Result := not AFlight.Deep or (ATick >= AFlight.Arrive);
end;

// Two bodies a cell big cut into one another; touching is no cut
function Clash(const AFlight, AOther: TPadFlight): Boolean;
var
  X, Y, OtherX, OtherY: Double;
begin
  for var Tick := 0 to Max(AFlight.Done, AOther.Done) do
  begin
    if not HoldsSpace(AFlight, Tick) or not HoldsSpace(AOther, Tick) then
      Continue;
    AFlight.Place(Tick, X, Y);
    AOther.Place(Tick, OtherX, OtherY);
    var Cut := (Abs(X - OtherX) < TileSize - TouchSlack) and
      (Abs(Y - OtherY) < TileSize - TouchSlack);
    if Cut then
      Exit(True);
  end;
  Result := False;
end;

function Fits(const AFlight: TPadFlight; const APlanned: TPadFlights): Boolean;
begin
  for var Other in APlanned do
    if Clash(AFlight, Other) then
      Exit(False);
  Result := True;
end;

// In front: the legs either way round, the start held back step by step
function TryFront(const AFrom, ATo: TPadCell; AAcrossFirst: Boolean;
  ARelease: Integer; const APlanned: TPadFlights;
  out AFlight: TPadFlight): Boolean;
begin
  for var Step := 0 to MaxHoldTicks div HoldStepTicks do
  begin
    var Depart := ARelease + Step * HoldStepTicks;
    AFlight := BuildFlight(AFrom, ATo, AAcrossFirst, Depart, False);
    if Fits(AFlight, APlanned) then
      Exit(True);
    AFlight := BuildFlight(AFrom, ATo, not AAcrossFirst, Depart, False);
    if Fits(AFlight, APlanned) then
      Exit(True);
  end;
  Result := False;
end;

// In the depth: it sinks at the start and sets off once it is down there;
// what it must fit is its coming out on the cell
function TryDeep(const AFrom, ATo: TPadCell; AAcrossFirst: Boolean;
  ARelease: Integer; const APlanned: TPadFlights;
  out AFlight: TPadFlight): Boolean;
begin
  for var Step := 0 to MaxHoldTicks div HoldStepTicks do
  begin
    var Depart := Max(ARelease, SinkTicks) + Step * HoldStepTicks;
    AFlight := BuildFlight(AFrom, ATo, AAcrossFirst, Depart, True);
    if Fits(AFlight, APlanned) then
      Exit(True);
  end;
  Result := False;
end;

// The loaded pads first - only the front is theirs -, then the longest
// flights, then the file order
function PlansBefore(APad, AOther: Integer; const AStart, ATarget: TPadCells;
  const ALoaded: TArray<Boolean>): Boolean;
begin
  if ALoaded[APad] <> ALoaded[AOther] then
    Exit(ALoaded[APad]);
  var Flown := FlightCells(AStart[APad], ATarget[APad]);
  var OtherFlown := FlightCells(AStart[AOther], ATarget[AOther]);
  if Flown <> OtherFlown then
    Exit(Flown > OtherFlown);
  Result := APad < AOther;
end;

function PlanOrder(const AStart, ATarget: TPadCells;
  const ALoaded: TArray<Boolean>): TArray<Integer>;
begin
  SetLength(Result, Length(AStart));
  for var i := 0 to High(Result) do
  begin
    var Slot := i;
    while (Slot > 0) and
      PlansBefore(i, Result[Slot - 1], AStart, ATarget, ALoaded) do
    begin
      Result[Slot] := Result[Slot - 1];
      Dec(Slot);
    end;
    Result[Slot] := i;
  end;
end;

function TryPlanFlights(var ARandom: TXorShift;
  const AStart, ATarget: TPadCells; const ALoaded: TArray<Boolean>;
  const ARelease: TArray<Integer>; out AFlights: TPadFlights): Boolean;
begin
  SetLength(AFlights, Length(AStart));
  var Planned: TPadFlights := [];
  for var PadIndex in PlanOrder(AStart, ATarget, ALoaded) do
  begin
    var AcrossFirst := Roll(ARandom, 2) = 0;
    var Flight: TPadFlight;
    var Fitted := TryFront(AStart[PadIndex], ATarget[PadIndex], AcrossFirst,
      ARelease[PadIndex], Planned, Flight);
    if not Fitted and not ALoaded[PadIndex] then
      Fitted := TryDeep(AStart[PadIndex], ATarget[PadIndex], AcrossFirst,
        ARelease[PadIndex], Planned, Flight);
    if not Fitted then
      Exit(False);
    AFlights[PadIndex] := Flight;
    Planned := Planned + [Flight];
  end;
  Result := True;
end;

end.
