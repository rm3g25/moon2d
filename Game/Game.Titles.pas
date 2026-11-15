{
  Game.Titles - the titles over the picture the flight ends on
  (docs/mechanics/finale-flight.md): their clock and what it tells. The
  clock starts with the end track, at the hull's burst, and goes by the
  track where the mixer tells its place - the cues stand on its beats - and
  by the ticks where it does not. On it: the studio's card comes and goes,
  and the logo flares and stands. The hero is his own through it.

  Titles with a path fly: at its cue the camera leaves, and the eye goes
  the path (Levels.EyePath) by the flight's own seconds. In the flight the
  clock goes by the ticks alone: the track tells its place in steps of the
  mixer's buffer, and a clock leaning after it would shake the camera. A
  track far off still takes it at once.

  For the time being the flight is flown as far as the eye keeps its rest
  (TEyePath.RestTill); the frame goes dark over its last second, and there
  it ends.

  Only the clock, its cues, the eye and how much of the card shows: the
  track, the logo, the gate's lamp and the drawing are the caller's. No SDL.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.Titles;
{$I ..\Moon2D.inc}

interface

uses
  Levels.Titles, Levels.EyePath;

const
  // The fixed timestep: the cues' seconds in ticks
  TitlesTicksPerSecond = 33;
  // The card comes in and goes out over this long
  TitlesFadeSeconds = 1.0;
  // The white of the logo's flash is gone this many ticks after it
  TitlesFlashTicks = 3;
  // Handed to Tick for a track that tells no place: the clock counts its
  // ticks alone
  NoTrackSeconds = -1.0;
  // The frame goes dark over this long before the flight ends
  TitlesTailSeconds = 1.0;

type
  TTitlesCue = record
    // The clock has come to the flash: the logo flares, once
    Flashes: Boolean;
    // The clock has come to the flight: the camera leaves, once
    FlightStarts: Boolean;
    // The flight has come to where it ends, once
    FlightEnds: Boolean;
  end;

  TTitles = class
  private
    FDef: TTitlesDef;
    FRunning: Boolean;
    FSeconds, FLastSeconds: Double;
    FFlashed: Boolean;
    FSinceFlash: Integer;
    FFlying: Boolean;
    FFlightOver: Boolean;
    // The second of the flight it ends on
    FFlightTill: Double;
  public
    // ADef - the level's; without titles Start starts nothing
    procedure Arm(const ADef: TTitlesDef);
    // The end track starts: the clock runs from 0. Nothing once running
    procedure Start;
    // A death before the end, a new level: none
    procedure Clear;
    // ATrackSeconds - the place of the end track, below zero when the
    // mixer tells none. The clock goes a tick on and, before the flight,
    // leans toward the track by half a tick at the most; a track far off
    // takes it at once
    function Tick(ATrackSeconds: Double): TTitlesCue;
    // The clock put at ASeconds, with nothing between
    procedure JumpTo(ASeconds: Double);
    // The first cue later than ASeconds; below zero - none
    function CueAfter(ASeconds: Double): Double;
    // The clock AAlpha of the way from the last tick to this one
    function SecondsAt(AAlpha: Single): Double;
    // How much of the card shows, 0..1, between the ticks
    function CardLevel(AAlpha: Single): Single;
    // The white over the frame at the flash, 1 on its tick and gone
    // TitlesFlashTicks later
    function FlashLevel(AAlpha: Single): Single;
    // The flight's own seconds between the ticks; 0 before it
    function FlightSeconds(AAlpha: Single): Double;
    // The eye between the ticks. AStand - the place of the city's strip
    // that stands in the middle of the screen where the world stands; not
    // flying, the eye is at its rest there
    function EyeAt(AAlpha: Single; AStand: Double): TEye;
    // The dark over the frame as the flight ends, 0..1, between the ticks
    function TailLevel(AAlpha: Single): Single;
    property Running: Boolean read FRunning;
    property Seconds: Double read FSeconds;
    // From the flash on the logo stands
    property LogoShown: Boolean read FFlashed;
    // From the flight's cue on
    property Flying: Boolean read FFlying;
  end;

implementation

uses
  System.Math;

const
  TickSeconds = 1 / TitlesTicksPerSecond;
  // The share of its way to the track the clock closes a tick
  TrackPull = 0.1;
  MostPullSeconds = TickSeconds / 2;
  // Further from the track than this the clock does not lean, it jumps:
  // the track was moved, or the game stood
  TrackJumpSeconds = 0.5;
  NoCue = -1.0;

function Confine(AShare: Double): Single;
begin
  if AShare <= 0 then
    Exit(0);
  if AShare >= 1 then
    Exit(1);
  Result := AShare;
end;

// 0 till AFrom, 1 from a fade later
function ComesIn(ASeconds, AFrom: Double): Single;
begin
  Result := Confine((ASeconds - AFrom) / TitlesFadeSeconds);
end;

// 1 till a fade before ATill, 0 from ATill on
function GoesOut(ASeconds, ATill: Double): Single;
begin
  Result := Confine((ATill - ASeconds) / TitlesFadeSeconds);
end;

// How far the clock goes toward a track AOff seconds from it, in a tick
function Lean(AOff: Double): Double;
begin
  Result := AOff * TrackPull;
  if Result > MostPullSeconds then
    Result := MostPullSeconds
  else if Result < -MostPullSeconds then
    Result := -MostPullSeconds;
end;

procedure TTitles.Arm(const ADef: TTitlesDef);
begin
  FDef := ADef;
  FFlightTill := ADef.Path.RestTill;
  Clear;
end;

procedure TTitles.Start;
begin
  if FRunning or not FDef.Present then
    Exit;
  FRunning := True;
end;

procedure TTitles.Clear;
begin
  FRunning := False;
  FSeconds := 0;
  FLastSeconds := 0;
  FFlashed := False;
  FSinceFlash := 0;
  FFlying := False;
  FFlightOver := False;
end;

function TTitles.Tick(ATrackSeconds: Double): TTitlesCue;
begin
  Result := Default(TTitlesCue);
  if not FRunning then
    Exit;
  FLastSeconds := FSeconds;
  FSeconds := FSeconds + TickSeconds;
  if ATrackSeconds >= 0 then
  begin
    var Off: Double := ATrackSeconds - FSeconds;
    if Abs(Off) > TrackJumpSeconds then
      JumpTo(ATrackSeconds)
    else if not FFlying then
      FSeconds := FSeconds + Lean(Off);
  end;

  if FFlashed then
    Inc(FSinceFlash)
  else if FSeconds >= FDef.Cues.Flash then
  begin
    FFlashed := True;
    Result.Flashes := True;
  end;

  if FDef.Flies and not FFlying and (FSeconds >= FDef.Cues.Flight) then
  begin
    FFlying := True;
    Result.FlightStarts := True;
  end;
  var Landed := FFlying and (FSeconds - FDef.Cues.Flight >= FFlightTill);
  if Landed and not FFlightOver then
  begin
    FFlightOver := True;
    Result.FlightEnds := True;
  end;
end;

procedure TTitles.JumpTo(ASeconds: Double);
begin
  FSeconds := ASeconds;
  FLastSeconds := ASeconds;
end;

function TTitles.CueAfter(ASeconds: Double): Double;
begin
  if FDef.Cues.Card > ASeconds then
    Exit(FDef.Cues.Card);
  if FDef.Cues.Flash > ASeconds then
    Exit(FDef.Cues.Flash);
  Result := NoCue;
end;

function TTitles.SecondsAt(AAlpha: Single): Double;
begin
  Result := FLastSeconds + (FSeconds - FLastSeconds) * AAlpha;
end;

function TTitles.CardLevel(AAlpha: Single): Single;
begin
  if not FRunning then
    Exit(0);
  var Clock := SecondsAt(AAlpha);
  Result := Min(ComesIn(Clock, FDef.Cues.Card), GoesOut(Clock, FDef.Cues.CardOut));
end;

function TTitles.FlashLevel(AAlpha: Single): Single;
begin
  if not FFlashed then
    Exit(0);
  Result := Confine(1 - (FSinceFlash + AAlpha) / TitlesFlashTicks);
end;

// On the tick the flight starts the last tick lies before its cue
function TTitles.FlightSeconds(AAlpha: Single): Double;
begin
  if not FFlying then
    Exit(0);
  Result := SecondsAt(AAlpha) - FDef.Cues.Flight;
  if Result < 0 then
    Result := 0;
end;

function TTitles.EyeAt(AAlpha: Single; AStand: Double): TEye;
begin
  Result := FDef.Path.EyeAt(FlightSeconds(AAlpha), AStand);
end;

function TTitles.TailLevel(AAlpha: Single): Single;
begin
  if not FFlying then
    Exit(0);
  var IntoTail: Double := FlightSeconds(AAlpha) - (FFlightTill - TitlesTailSeconds);
  Result := Confine(IntoTail / TitlesTailSeconds);
end;

end.
