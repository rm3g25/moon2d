{
  Game.Titles - the titles over the picture the flight ends on
  (docs/mechanics/finale-flight.md): their clock and what it tells. The
  clock starts with the end track, at the hull's burst, and goes by the
  track where the mixer tells its place - the cues stand on its beats - and
  by the ticks where it does not. On it: the studio's card comes and goes,
  and the logo flares and stands. The hero is his own through it.

  Only the clock, its one cue and how much of the card shows: the track,
  the logo, the gate's lamp and the drawing are the caller's. No SDL.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.Titles;
{$I ..\Moon2D.inc}

interface

uses
  Levels.Titles;

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

type
  TTitlesCue = record
    // The clock has come to the flash: the logo flares, once
    Flashes: Boolean;
  end;

  TTitles = class
  private
    FDef: TTitlesDef;
    FRunning: Boolean;
    FSeconds, FLastSeconds: Double;
    FFlashed: Boolean;
    FSinceFlash: Integer;
  public
    // ADef - the level's; without titles Start starts nothing
    procedure Arm(const ADef: TTitlesDef);
    // The end track starts: the clock runs from 0. Nothing once running
    procedure Start;
    // A death before the end, a new level: none
    procedure Clear;
    // ATrackSeconds - the place of the end track, below zero when the
    // mixer tells none. The clock goes a tick on and leans toward the
    // track by half a tick at the most; a track far off takes it at once
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
    property Running: Boolean read FRunning;
    property Seconds: Double read FSeconds;
    // From the flash on the logo stands
    property LogoShown: Boolean read FFlashed;
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
    else
      FSeconds := FSeconds + Lean(Off);
  end;

  if FFlashed then
    Inc(FSinceFlash)
  else if FSeconds >= FDef.Cues.Flash then
  begin
    FFlashed := True;
    Result.Flashes := True;
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

end.
