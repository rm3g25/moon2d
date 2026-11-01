{
  Levels.Monorail - where the chase city's train stands at a time of the
  far plane's clock (Levels.FarPlane: "train"): one train shuttling on the
  monorail between the city's two stations - a dwell at a station, a run
  to the other, and back.

  The line is the train's depth with the city at rest: a place on it is
  where a thing's left edge would stand on the screen with the city's
  offset at 0. The stations stand at the train's depth, so a mouth keeps
  its place on the line however the city rides; on the screen a place
  stands the city's offset times the nearness to the left of it. At a stop
  the train's nose stands Inside units past a mouth; it is shown between
  the mouths only, cut there as it goes in.

  A run pushes up to cruise over AccelTicks with a steady push, rolls on,
  and comes down the same way; one too short to reach cruise turns
  halfway. A dwell is the dice of Levels.CityLife - the stand's
  (tools/chase/stand.template.html) to the bit, so the train leaves a
  station on the same tick on the stand and in the game. The time is the
  clock's ticks with their fraction: the train glides between ticks as
  the city does.

  No SDL: Render.FarPlane asks, and draws.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Levels.Monorail;
{$I ..\Moon2D.inc}

interface

uses
  Levels.FarPlane;

type
  TMonorailLine = record
    // The stations' feet, the train's depth, and its nearness
    Depth, Nearness: Double;
    LeftMouth, RightMouth: Double;
    // The train's left edge at its stop at each station
    LeftStop, RightStop: Double;
  end;

  // A run from stop to stop, in ticks of the far plane
  TTrainRun = record
    Distance: Double;
    // Units a tick the speed gains each tick while it pushes
    Push: Double;
    // How long it pushes at each end; the speed it reaches, units a tick;
    // how long it rolls at that speed
    Ramp, Peak, Roll: Double;
    function Ticks: Double;
    // How far it has gone ATicks into the run
    function Place(ATicks: Double): Double;
  end;

  // The share of the train's picture between the mouths
  TTrainShown = record
    From, Till: Double;
    function Any: Boolean;
  end;

// Raises if the stations stand at two depths or the stops leave no run
// between them
function MonorailLine(const ADef: TFarPlaneDef): TMonorailLine;
function TrainRun(const ATrain: TCityTrain; ADistance: Double): TTrainRun;
// The train's left edge on the line; ATime - ticks of the far plane's
// clock with their fraction
function TrainLeft(const ATrain: TCityTrain; const ALine: TMonorailLine;
  ATime: Double): Double;
// ALeft - the train's left edge on the line
function TrainShown(const ATrain: TCityTrain; const ALine: TMonorailLine;
  ALeft: Double): TTrainShown;

implementation

uses
  System.Math, Levels.CityLife;

resourcestring
  SMonorailDepths = 'The stations of the train stand at two depths, %g and %g';
  SMonorailNoRun = 'The train''s stops leave no run between them: %g to %g';

const
  TicksPerSecond = 33;
  TrainSeed = $7A1;
  FirstDwellKey = 1;
  DwellKeys = 100;

function TTrainRun.Ticks: Double;
begin
  Result := 2 * Ramp + Roll;
end;

function TTrainRun.Place(ATicks: Double): Double;
begin
  if ATicks < Ramp then
    Exit(Push * ATicks * ATicks / 2);
  if ATicks < Ramp + Roll then
    Exit(Push * Ramp * Ramp / 2 + Peak * (ATicks - Ramp));
  var Left: Double := Ticks - ATicks;
  Result := Distance - Push * Left * Left / 2;
end;

function TTrainShown.Any: Boolean;
begin
  Result := Till > From;
end;

// Where an element's left edge stands on the line at ANearness
function LineLeft(const ADef: TFarPlaneDef; const AElement: TFarPlaneElement;
  ANearness: Double): Double;
begin
  var Middle: Double := ADef.ScreenWidth / 2;
  Result := Middle + (AElement.X + AElement.W / 2 - Middle) * ANearness - AElement.W / 2;
end;

// The mouth faces the beam: from the picture's left, from its right on a
// station drawn mirrored
function MouthOf(const ADef: TFarPlaneDef; const AStation: TFarPlaneElement;
  ANearness: Double): Double;
begin
  var Share: Double := ADef.Train.Mouth;
  if AStation.Mirror then
    Share := 1 - Share;
  Result := LineLeft(ADef, AStation, ANearness) + Share * AStation.W;
end;

function MonorailLine(const ADef: TFarPlaneDef): TMonorailLine;
begin
  var Stations := ADef.CityElements(ADef.Train.Station);
  var Left := Stations[0];
  var Right := Stations[1];
  if Right.X < Left.X then
  begin
    Left := Stations[1];
    Right := Stations[0];
  end;
  if Left.DepthY <> Right.DepthY then
    raise EFarPlaneError.CreateFmt(SMonorailDepths, [Left.DepthY, Right.DepthY]);

  Result.Depth := Left.DepthY;
  Result.Nearness := ADef.Nearness(Left.DepthY);
  Result.LeftMouth := MouthOf(ADef, Left, Result.Nearness);
  Result.RightMouth := MouthOf(ADef, Right, Result.Nearness);
  Result.LeftStop := Result.LeftMouth - ADef.Train.Inside;
  Result.RightStop := Result.RightMouth + ADef.Train.Inside - ADef.Train.W;
  if Result.RightStop <= Result.LeftStop then
    raise EFarPlaneError.CreateFmt(SMonorailNoRun, [Result.LeftStop, Result.RightStop]);
end;

function TrainRun(const ATrain: TCityTrain; ADistance: Double): TTrainRun;
begin
  Result.Distance := ADistance;
  Result.Push := ATrain.Cruise / TicksPerSecond / ATrain.AccelTicks;
  var Longest: Double := ATrain.AccelTicks;
  // Pushing up for half the run and down for the other half
  var Halfway: Double := Sqrt(ADistance / Result.Push);
  Result.Ramp := Min(Longest, Halfway);
  Result.Peak := Result.Push * Result.Ramp;
  // A run that turns halfway rolls for nothing, the arithmetic's dust aside
  Result.Roll := (ADistance - Result.Push * Result.Ramp * Result.Ramp) / Result.Peak;
  if Result.Roll < 0 then
    Result.Roll := 0;
end;

// From its first dwell at the left station, somewhere into it: legs of a
// dwell and a run, out from the left on the even ones
function TrainLeft(const ATrain: TCityTrain; const ALine: TMonorailLine;
  ATime: Double): Double;
begin
  var Run := TrainRun(ATrain, ALine.RightStop - ALine.LeftStop);
  var Start: Double := -RollInt(TrainSeed, FirstDwellKey, 0, ATrain.DwellMost);
  var Leg := 0;
  repeat
    var Outward := not Odd(Leg);
    var From := ALine.RightStop;
    if Outward then
      From := ALine.LeftStop;
    Start := Start + RollInt(TrainSeed, DwellKeys + Leg, ATrain.DwellLeast, ATrain.DwellMost);
    if ATime < Start then
      Exit(From);
    if ATime < Start + Run.Ticks then
    begin
      var Gone := Run.Place(ATime - Start);
      if Outward then
        Exit(From + Gone);
      Exit(From - Gone);
    end;
    Start := Start + Run.Ticks;
    Inc(Leg);
  until False;
end;

function TrainShown(const ATrain: TCityTrain; const ALine: TMonorailLine;
  ALeft: Double): TTrainShown;
begin
  Result.From := (ALine.LeftMouth - ALeft) / ATrain.W;
  if Result.From < 0 then
    Result.From := 0;
  Result.Till := (ALine.RightMouth - ALeft) / ATrain.W;
  if Result.Till > 1 then
    Result.Till := 1;
end;

end.
