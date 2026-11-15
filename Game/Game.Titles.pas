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
  track far off still takes it at once. Once the path is flown the eye
  stands, and the clock leans again.

  On the way the eye passes the TEK sign and the sun comes out of the
  dome's glass, each on a cue by the flight's seconds (SignSince,
  FlareSince). The frame goes dark over the path's last second.

  Titles that end at the stars: the sky of the menu comes out of the black
  while the eye still climbs, standing high and coming down as if the eye
  rose into it - at first as fast as the pitch of the path rose there,
  slowing to its rest by its cue; the nebula comes in after the stars. Then
  the two phrases, the lines of the credits one after another, and the last
  screen. The track's end is the titles' end.

  Only the clock, its cues, the eye and how much of each thing shows: the
  track, the logo, the gate's lamp, the sky and the drawing are the
  caller's. No SDL.

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
  // The card, the phrases and the lines come in and go out over this long
  TitlesFadeSeconds = 1.0;
  // The white of the logo's flash is gone this many ticks after it
  TitlesFlashTicks = 3;
  // Handed to Tick for a track that tells no place: the clock counts its
  // ticks alone
  NoTrackSeconds = -1.0;
  // The frame goes dark over this long before the path is flown
  TitlesDarkSeconds = 1.0;
  // The nebula comes in over this long from the sky's cue
  TitlesNebulaSeconds = 4.0;
  // The lines of the credits at the stars
  TitlesCreditLines = 3;

type
  TTitlesCue = record
    // The clock has come to the flash: the logo flares, once
    Flashes: Boolean;
    // The clock has come to the flight: the camera leaves, once
    FlightStarts: Boolean;
    // The sky of the menu comes out of the black, once
    SkyComes: Boolean;
    // The last screen, once
    LastComes: Boolean;
    // The track is over, once: the titles are done
    TrackEnds: Boolean;
  end;

  TTitles = class
  private
    FDef: TTitlesDef;
    FRunning: Boolean;
    FSeconds, FLastSeconds: Double;
    FFlashed: Boolean;
    FSinceFlash: Integer;
    FFlying: Boolean;
    FSkyOut: Boolean;
    FLastShown: Boolean;
    FTrackOver: Boolean;
    // The second of the flight its path is flown to
    FFlightTill: Double;
    // How far above its rest the sky stands when it comes, as a tangent of
    // the eye's pitch
    FSkyRiseTan: Double;
    function AtTheStarsDef: Boolean;
  public
    // ADef - the level's; without titles Start starts nothing
    procedure Arm(const ADef: TTitlesDef);
    // The end track starts: the clock runs from 0. Nothing once running
    procedure Start;
    // A death before the end, a new level, the end of the track: none
    procedure Clear;
    // ATrackSeconds - the place of the end track, below zero when the
    // mixer tells none. The clock goes a tick on and, out of the flight,
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
    // The flight's seconds from the cue the TEK sign stutters on, and from
    // the one the sun flares on; below 0 before each
    function SignSince(AAlpha: Single): Double;
    function FlareSince(AAlpha: Single): Double;
    // The eye between the ticks. AStand - the place of the city's strip
    // that stands in the middle of the screen where the world stands; not
    // flying, the eye is at its rest there
    function EyeAt(AAlpha: Single; AStand: Double): TEye;
    // The dark over the frame as the path ends, 0..1, between the ticks
    function DarkLevel(AAlpha: Single): Single;
    // The eye has come to the path's end and stands
    function PathFlown: Boolean;
    // At the stars, between the ticks: how much of the stars and of the
    // nebula shows, 0..1
    function StarsLevel(AAlpha: Single): Single;
    function NebulaLevel(AAlpha: Single): Single;
    // How far above its rest the sky stands, as the tangent of a pitch:
    // times the focal length, units. All of it till the sky comes, none
    // from its rest on
    function SkyRise(AAlpha: Single): Double;
    // The two phrases, 0..1
    function MissionLevel(AAlpha: Single): Single;
    function PromiseLevel(AAlpha: Single): Single;
    // The line AIndex of the credits, 0..TitlesCreditLines - 1, 0..1
    function CreditLevel(AIndex: Integer; AAlpha: Single): Single;
    // The last screen, 0..1
    function LastLevel(AAlpha: Single): Single;
    property Running: Boolean read FRunning;
    property Seconds: Double read FSeconds;
    // From the flash on the logo stands
    property LogoShown: Boolean read FFlashed;
    // From the flight's cue on
    property Flying: Boolean read FFlying;
    // From the sky's cue on
    property AtTheStars: Boolean read FSkyOut;
    // From the last screen's cue on
    property LastShown: Boolean read FLastShown;
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
  // The sky comes down as (1 - s)^3 of the way left: at its start as fast
  // as a curve this steep allows, standing at its end
  SkyEasePower = 3;
  // The pitch's pace is taken over this much of the flight either side
  PaceSpan = 0.01;

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

// How fast the tangent of the path's pitch grows at ASeconds of the flight,
// a second
function PitchTangentPace(const APath: TEyePath; ASeconds: Double): Double;
begin
  var Before: Double := Tan(DegToRad(APath.EyeAt(ASeconds - PaceSpan, 0).Pitch));
  var After: Double := Tan(DegToRad(APath.EyeAt(ASeconds + PaceSpan, 0).Pitch));
  Result := (After - Before) / (2 * PaceSpan);
end;

procedure TTitles.Arm(const ADef: TTitlesDef);
begin
  FDef := ADef;
  FFlightTill := ADef.FlightTill;
  FSkyRiseTan := 0;
  if ADef.EndsAtTheStars then
  begin
    var Pace := PitchTangentPace(ADef.Path, ADef.Cues.Stars - ADef.Cues.Flight);
    // A way of (1 - s)^n over T seconds starts at n / T of it a second
    FSkyRiseTan := Pace * (ADef.Cues.Still - ADef.Cues.Stars) / SkyEasePower;
  end;
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
  FSkyOut := False;
  FLastShown := False;
  FTrackOver := False;
end;

function TTitles.AtTheStarsDef: Boolean;
begin
  Result := FRunning and FDef.EndsAtTheStars;
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
    else if not FFlying or PathFlown then
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
  if FDef.EndsAtTheStars and not FSkyOut and (FSeconds >= FDef.Cues.Stars) then
  begin
    FSkyOut := True;
    Result.SkyComes := True;
  end;
  if (FDef.Cues.Last > 0) and not FLastShown and (FSeconds >= FDef.Cues.Last) then
  begin
    FLastShown := True;
    Result.LastComes := True;
  end;
  var TrackOver := (FDef.TrackSeconds > 0) and (FSeconds >= FDef.TrackSeconds);
  if TrackOver and not FTrackOver then
  begin
    FTrackOver := True;
    Result.TrackEnds := True;
  end;
end;

procedure TTitles.JumpTo(ASeconds: Double);
begin
  FSeconds := ASeconds;
  FLastSeconds := ASeconds;
end;

// The cues stand in this order, each after the one before it; a cue the
// titles do not have is 0
function TTitles.CueAfter(ASeconds: Double): Double;
begin
  var Cues: TArray<Double> := [FDef.Cues.Card, FDef.Cues.Flash, FDef.Cues.Stars,
    FDef.Cues.Mission, FDef.Cues.Credits, FDef.Cues.Last, FDef.TrackSeconds];
  for var Cue in Cues do
    if (Cue > 0) and (Cue > ASeconds) then
      Exit(Cue);
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

// The flight's own cues stand by its seconds, not on the track's beats
function TTitles.SignSince(AAlpha: Single): Double;
begin
  Result := FlightSeconds(AAlpha) - (FDef.Cues.Neon - FDef.Cues.Flight);
end;

function TTitles.FlareSince(AAlpha: Single): Double;
begin
  Result := FlightSeconds(AAlpha) - (FDef.Cues.Flare - FDef.Cues.Flight);
end;

function TTitles.EyeAt(AAlpha: Single; AStand: Double): TEye;
begin
  Result := FDef.Path.EyeAt(FlightSeconds(AAlpha), AStand);
end;

function TTitles.DarkLevel(AAlpha: Single): Single;
begin
  if not FFlying then
    Exit(0);
  var IntoDark: Double := FlightSeconds(AAlpha) - (FFlightTill - TitlesDarkSeconds);
  Result := Confine(IntoDark / TitlesDarkSeconds);
end;

function TTitles.PathFlown: Boolean;
begin
  Result := FFlying and (FSeconds - FDef.Cues.Flight >= FFlightTill);
end;

function TTitles.StarsLevel(AAlpha: Single): Single;
begin
  if not AtTheStarsDef then
    Exit(0);
  Result := ComesIn(SecondsAt(AAlpha), FDef.Cues.Stars);
end;

function TTitles.NebulaLevel(AAlpha: Single): Single;
begin
  if not AtTheStarsDef then
    Exit(0);
  Result := Confine((SecondsAt(AAlpha) - FDef.Cues.Stars) / TitlesNebulaSeconds);
end;

function TTitles.SkyRise(AAlpha: Single): Double;
begin
  if not AtTheStarsDef then
    Exit(0);
  var Share: Double := (SecondsAt(AAlpha) - FDef.Cues.Stars) /
    (FDef.Cues.Still - FDef.Cues.Stars);
  if Share <= 0 then
    Exit(FSkyRiseTan);
  if Share >= 1 then
    Exit(0);
  var Left: Double := 1 - Share;
  Result := FSkyRiseTan * Left * Left * Left;
end;

function TTitles.MissionLevel(AAlpha: Single): Single;
begin
  if not AtTheStarsDef then
    Exit(0);
  var Clock := SecondsAt(AAlpha);
  Result := Min(ComesIn(Clock, FDef.Cues.Mission), GoesOut(Clock, FDef.Cues.Credits));
end;

function TTitles.PromiseLevel(AAlpha: Single): Single;
begin
  if not AtTheStarsDef then
    Exit(0);
  var Clock := SecondsAt(AAlpha);
  Result := Min(ComesIn(Clock, FDef.Cues.Promise), GoesOut(Clock, FDef.Cues.Credits));
end;

// The lines share the time from the credits' cue to the last screen evenly
function TTitles.CreditLevel(AIndex: Integer; AAlpha: Single): Single;
begin
  if not AtTheStarsDef then
    Exit(0);
  var Span: Double := (FDef.Cues.Last - FDef.Cues.Credits) / TitlesCreditLines;
  var From: Double := FDef.Cues.Credits + AIndex * Span;
  var Clock := SecondsAt(AAlpha);
  Result := Min(ComesIn(Clock, From), GoesOut(Clock, From + Span));
end;

function TTitles.LastLevel(AAlpha: Single): Single;
begin
  if not FRunning or (FDef.Cues.Last <= 0) then
    Exit(0);
  Result := ComesIn(SecondsAt(AAlpha), FDef.Cues.Last);
end;

end.
