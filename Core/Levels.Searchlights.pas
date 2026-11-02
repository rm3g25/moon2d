{
  Levels.Searchlights - where the chase city's searchlights point at a time
  of the far plane's clock (Levels.FarPlane: "searchlights"), and how
  bright a beam is along its way.

  A beam lies at the depth of its lamp: it rides with the city as a
  building standing there does, and its numbers are units at that depth.
  Inside the dome it is bright, from the lamp's level down to the glass's;
  where it leaves the dome's silhouette - the half-ellipse through its
  frame's centre - it steps down to a faint tail in the lunar dust.

  Its angle is an aim and two slow waves on a clock of the lamp's own: the
  far plane's, less what the pauses took. The time is cut into windows,
  some of them holding a pause - the speed eases down as (1 + cos) / 2,
  holds still, eases back up. The dice are Levels.CityLife's, the stand's
  (tools/chase/stand.template.html) to the bit, so a lamp stops on the
  same tick on the stand and in the game. The time is the clock's ticks
  with their fraction: a beam glides between ticks as the city does.

  No SDL: Render.FarPlane asks, and draws.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Levels.Searchlights;
{$I ..\Moon2D.inc}

interface

uses
  Levels.FarPlane;

type
  // A beam on the screen, in units: from its lamp along a unit direction;
  // Glass - how far along it leaves its dome, 0 for a lamp in none
  TSearchlightBeam = record
    FromX, FromY: Double;
    DirX, DirY: Double;
    Glass: Double;
    // The point ADistance along it
    function AtX(ADistance: Double): Double;
    function AtY(ADistance: Double): Double;
  end;

function SearchlightSeed(ALamp: Integer): Cardinal;
// The lamp's own clock: AClock - ticks of the far plane's clock with their
// fraction - less what the pauses before it took
function SearchlightClock(const APause: TSearchlightPause; ASeed: Cardinal;
  AClock: Double): Double;
// Radians on the screen, Y down
function SearchlightAngle(const ALights: TCitySearchlights; ALamp: Integer;
  AClock: Double): Double;
// ACityOffset - how far the city has ridden left
function SearchlightBeam(const ADef: TFarPlaneDef; ALamp: Integer;
  ACityOffset, AClock: Double): TSearchlightBeam;
// How bright the beam is ADistance along it; past the glass, the tail's.
// Exactly at the glass - the inner side
function BeamLevel(const ALights: TCitySearchlights; const ABeam: TSearchlightBeam;
  ADistance: Double): Double;
// The tail's level AShare of the way along it, 0..1
function TailLevel(const ALights: TCitySearchlights; AShare: Double): Double;

implementation

uses
  System.Math, Levels.CityLife;

const
  SearchSeed = $5E1;
  SweepPhaseKeys = 1;
  FirstWindowKey = 3;
  WindowKeys = 100;
  PausedKeys = 1000;
  PauseAtKeys = 2000;
  HoldKeys = 3000;

type
  // A window of the lamp's time on the far plane's clock: its number from
  // the first, where it begins, how long it lasts
  TClockWindow = record
    Index: Integer;
    Start: Double;
    Length: Integer;
  end;

  // A window's pause on the far plane's clock: where it begins, how long it
  // holds still, how long it lasts with its eases
  TWindowPause = record
    At: Double;
    Hold, Span: Integer;
  end;

function TSearchlightBeam.AtX(ADistance: Double): Double;
begin
  Result := FromX + DirX * ADistance;
end;

function TSearchlightBeam.AtY(ADistance: Double): Double;
begin
  Result := FromY + DirY * ADistance;
end;

function SearchlightSeed(ALamp: Integer): Cardinal;
begin
  Result := Mix(SearchSeed + ALamp);
end;

// How much of the lamp's clock a pause has taken AInside ticks into it
function PauseLost(AInside: Double; AEase, AHold: Integer): Double;
begin
  if AInside <= 0 then
    Exit(0);
  if AInside < AEase then
    Exit(AInside / 2 - AEase / (2 * Pi) * Sin(Pi * AInside / AEase));
  if AInside < AEase + AHold then
    Exit(AEase / 2 + AInside - AEase);
  var Up: Double := AInside - AEase - AHold;
  Result := AEase / 2 + AHold + Up / 2 + AEase / (2 * Pi) * Sin(Pi * Up / AEase);
end;

// False - the window holds no pause
function WindowPause(const APause: TSearchlightPause; ASeed: Cardinal;
  const AWindow: TClockWindow; out APlace: TWindowPause): Boolean;
begin
  Result := Roll(ASeed, PausedKeys + AWindow.Index) < APause.Share;
  if not Result then
    Exit;
  APlace.Hold := RollInt(ASeed, HoldKeys + AWindow.Index, APause.HoldLeast, APause.HoldMost);
  APlace.Span := 2 * APause.EaseTicks + APlace.Hold;
  var Latest := Max(0, AWindow.Length - APlace.Span);
  APlace.At := AWindow.Start + RollInt(ASeed, PauseAtKeys + AWindow.Index, 0, Latest);
end;

function SearchlightClock(const APause: TSearchlightPause; ASeed: Cardinal;
  AClock: Double): Double;
var
  Window: TClockWindow;
  Pause: TWindowPause;
begin
  Window.Index := 0;
  Window.Start := -RollInt(ASeed, FirstWindowKey, 0, APause.WindowMost);
  var Lost: Double := 0;
  repeat
    Window.Length := RollInt(ASeed, WindowKeys + Window.Index, APause.WindowLeast,
      APause.WindowMost);
    var Paused := WindowPause(APause, ASeed, Window, Pause);
    if Paused and (AClock < Pause.At + Pause.Span) then
      Exit(AClock - Lost - PauseLost(AClock - Pause.At, APause.EaseTicks, Pause.Hold));
    if Paused then
      Lost := Lost + APause.EaseTicks + Pause.Hold;
    Window.Start := Window.Start + Window.Length;
    if AClock < Window.Start then
      Exit(AClock - Lost);
    Inc(Window.Index);
  until False;
end;

function SearchlightAngle(const ALights: TCitySearchlights; ALamp: Integer;
  AClock: Double): Double;
begin
  var Lamp := ALights.Lamps[ALamp];
  var Seed := SearchlightSeed(ALamp);
  var Own := SearchlightClock(ALights.Pause, Seed, AClock);
  var Degrees: Double := Lamp.Aim;
  for var i := 0 to High(Lamp.Waves) do
  begin
    var Wave := Lamp.Waves[i];
    var Turn: Double := Own / Wave.PeriodTicks + Roll(Seed, SweepPhaseKeys + i);
    Degrees := Degrees + Wave.Degrees * Sin(2 * Pi * Turn);
  end;
  Result := DegToRad(Degrees);
end;

// The frame whose footprint along the city's layer holds the lamp; -1 none
function DomeOf(const ADef: TFarPlaneDef; const ALamp: TSearchlightLamp): Integer;
begin
  for var i := 0 to High(ADef.Frames) do
  begin
    var Frame := ADef.Frames[i];
    if (ALamp.X >= Frame.X) and (ALamp.X <= Frame.X + Frame.W) then
      Exit(i);
  end;
  Result := -1;
end;

// Where the beam leaves the frame's half-ellipse through its centre, at the
// nearness of the base line; 0 - it starts outside
function GlassDistance(const ADef: TFarPlaneDef; const AFrame: TDomeFrame;
  ACityOffset: Double; const ABeam: TSearchlightBeam): Double;
begin
  var CentreX: Double := AFrame.X + AFrame.W / 2 - ACityOffset;
  var RadiusX: Double := AFrame.W / 2;
  var RadiusY: Double := AFrame.H;
  var X := (ABeam.FromX - CentreX) / RadiusX;
  var Y := (ABeam.FromY - ADef.Camera.BaseY) / RadiusY;
  var DX := ABeam.DirX / RadiusX;
  var DY := ABeam.DirY / RadiusY;
  var A := DX * DX + DY * DY;
  var B := 2 * (X * DX + Y * DY);
  var C := X * X + Y * Y - 1;
  if C >= 0 then
    Exit(0);
  Result := (-B + Sqrt(B * B - 4 * A * C)) / (2 * A);
end;

function SearchlightBeam(const ADef: TFarPlaneDef; ALamp: Integer;
  ACityOffset, AClock: Double): TSearchlightBeam;
begin
  var Lamp := ADef.Searchlights.Lamps[ALamp];
  var Middle: Double := ADef.ScreenWidth / 2;
  var Nearness: Double := ADef.Nearness(Lamp.Y);
  var Angle := SearchlightAngle(ADef.Searchlights, ALamp, AClock);
  Result.FromX := Middle + (Lamp.X - ACityOffset - Middle) * Nearness;
  Result.FromY := Lamp.Y - Lamp.Lift;
  Result.DirX := Cos(Angle);
  Result.DirY := Sin(Angle);
  Result.Glass := 0;
  var Dome := DomeOf(ADef, Lamp);
  if (Dome >= 0) and ADef.Camera.Present then
    Result.Glass := GlassDistance(ADef, ADef.Frames[Dome], ACityOffset, Result);
end;

function TailLevel(const ALights: TCitySearchlights; AShare: Double): Double;
begin
  var Share := EnsureRange(AShare, 0.0, 1.0);
  var Eased := Share * Share * (3 - 2 * Share);
  Result := ALights.GlassLevel * ALights.TailShare * (1 - Eased);
end;

function BeamLevel(const ALights: TCitySearchlights; const ABeam: TSearchlightBeam;
  ADistance: Double): Double;
begin
  if ADistance < 0 then
    Exit(0);
  if (ABeam.Glass > 0) and (ADistance <= ABeam.Glass) then
    Exit(ALights.Level + (ALights.GlassLevel - ALights.Level) * ADistance / ABeam.Glass);
  var Past := ADistance - ABeam.Glass;
  if Past > ALights.Tail then
    Exit(0);
  Result := TailLevel(ALights, Past / ALights.Tail);
end;

end.
