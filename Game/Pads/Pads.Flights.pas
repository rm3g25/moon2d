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

  The pads are not all a flight minds. The caller may bar a place at a
  tick (TFlightBar): a barred flight looks for its way as one that cuts
  into a pad does. A loaded pad, with the front alone to look in, may
  wait longer for it.

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
    // At this tick the pad comes onto the corner of its L; a flight of a
    // single leg has none
    function TurnsCorner(ATick: Integer): Boolean;
    // In the depth: neither a floor nor a body
    function Behind(ATick: Integer): Boolean;
    // 0 in front .. 1 all the way into the depth; ATime between ticks
    function Depth(ATime: Single): Single;
  end;

  TPadFlights = TArray<TPadFlight>;

  // The body of a pad, its top-left corner at AX, AY, has no place there
  // at the tick. ADeep - the pad is in the depth: what stands in front
  // alone is not in its way.
  TFlightBar = reference to function(ATick: Integer; AX, AY: Double;
    ADeep: Boolean): Boolean;

  // A rebuild as its plan is asked for; the arrays go pad by pad
  TFlightBrief = record
    Start, Target: TPadCells;
    // A rider stands on the pad
    Loaded: TArray<Boolean>;
    // Ticks after the start before which the pad stays home
    Release: TArray<Integer>;
    // nil: the pads alone are in one another's way
    Bar: TFlightBar;
  end;

// False when a pad fits nowhere: a loaded one in front, another in front
// or in the depth.
function TryPlanFlights(var ARandom: TXorShift; const ABrief: TFlightBrief;
  out AFlights: TPadFlights): Boolean;

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
  // A loaded pad waits this many times longer: nothing but a bar stops
  // it, and a bar - the conductor passing - clears within a few seconds
  LoadedHoldScale = 3;
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

function TPadFlight.TurnsCorner(ATick: Integer): Boolean;
begin
  Result := (CornerTicks > 0) and (ATick = Depart + FirstTicks);
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

type
  // One pad's flight as the plan looks for it
  TFlightAsk = record
    From, Target: TPadCell;
    Release: Integer;
    Loaded: Boolean;
    // The order of the legs tried first
    AcrossFirst: Boolean;
  end;

  // What a flight still to be planned has to fit
  TPlanSoFar = record
    Bar: TFlightBar;
    Flights: TPadFlights;
  end;

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

// Barred at a tick of it, from the one it sets off at: before that the
// pad stands where the level file or the last rebuild put it
function Barred(const AFlight: TPadFlight; const ABar: TFlightBar): Boolean;
var
  X, Y: Double;
begin
  if not Assigned(ABar) then
    Exit(False);
  for var Tick := AFlight.Depart to AFlight.Done do
  begin
    AFlight.Place(Tick, X, Y);
    if ABar(Tick, X, Y, not HoldsSpace(AFlight, Tick)) then
      Exit(True);
  end;
  Result := False;
end;

function Fits(const AFlight: TPadFlight; const APlan: TPlanSoFar): Boolean;
begin
  for var Other in APlan.Flights do
    if Clash(AFlight, Other) then
      Exit(False);
  Result := not Barred(AFlight, APlan.Bar);
end;

// The legs in the order asked for or, when that does not fit, the other
// way round
function TryLegs(const AAsk: TFlightAsk; const APlan: TPlanSoFar;
  ADepart: Integer; ADeep: Boolean; out AFlight: TPadFlight): Boolean;
begin
  AFlight := BuildFlight(AAsk.From, AAsk.Target, AAsk.AcrossFirst, ADepart,
    ADeep);
  if Fits(AFlight, APlan) then
    Exit(True);
  AFlight := BuildFlight(AAsk.From, AAsk.Target, not AAsk.AcrossFirst,
    ADepart, ADeep);
  Result := Fits(AFlight, APlan);
end;

// In front: the start held back step by step
function TryFront(const AAsk: TFlightAsk; const APlan: TPlanSoFar;
  out AFlight: TPadFlight): Boolean;
begin
  var MostHold := MaxHoldTicks;
  if AAsk.Loaded then
    MostHold := LoadedHoldScale * MaxHoldTicks;
  for var Step := 0 to MostHold div HoldStepTicks do
    if TryLegs(AAsk, APlan, AAsk.Release + Step * HoldStepTicks, False,
      AFlight) then
      Exit(True);
  Result := False;
end;

// In the depth: it sinks at the start and sets off once it is down there.
// Of the pads it must fit only its coming out on the cell, so the order
// of its legs is the bar's to tell apart.
function TryDeep(const AAsk: TFlightAsk; const APlan: TPlanSoFar;
  out AFlight: TPadFlight): Boolean;
begin
  var Soonest := Max(AAsk.Release, SinkTicks);
  for var Step := 0 to MaxHoldTicks div HoldStepTicks do
    if TryLegs(AAsk, APlan, Soonest + Step * HoldStepTicks, True, AFlight) then
      Exit(True);
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

function TryPlanFlights(var ARandom: TXorShift; const ABrief: TFlightBrief;
  out AFlights: TPadFlights): Boolean;
var
  Plan: TPlanSoFar;
  Ask: TFlightAsk;
begin
  SetLength(AFlights, Length(ABrief.Start));
  Plan.Bar := ABrief.Bar;
  Plan.Flights := [];
  for var PadIndex in PlanOrder(ABrief.Start, ABrief.Target, ABrief.Loaded) do
  begin
    Ask.From := ABrief.Start[PadIndex];
    Ask.Target := ABrief.Target[PadIndex];
    Ask.Release := ABrief.Release[PadIndex];
    Ask.Loaded := ABrief.Loaded[PadIndex];
    Ask.AcrossFirst := Roll(ARandom, 2) = 0;
    var Flight: TPadFlight;
    var Fitted := TryFront(Ask, Plan, Flight);
    if not Fitted and not Ask.Loaded then
      Fitted := TryDeep(Ask, Plan, Flight);
    if not Fitted then
      Exit(False);
    AFlights[PadIndex] := Flight;
    Plan.Flights := Plan.Flights + [Flight];
  end;
  Result := True;
end;

end.
