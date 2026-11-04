{
  Game.Heartbeat - the one heartbeat that runs from the last of the charge
  to the throw: a double "tuk-tuk", low. It counts the beats and says when
  one is struck and how strong the pulse is between them; the sound, the
  gauge and the heart monitor follow it.

  It does not know the charge: the game hands it a tempo every tick, so
  later steps of the henshin can drive it by their own clock. What the
  last of the charge asks of it is ChargeTempo.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.Heartbeat;
{$I ..\Moon2D.inc}

interface

const
  // The charge the heart starts beating at
  HeartbeatCharge = 97;
  // The second thump comes this many ticks after the first. Heartbeat.wav
  // has its second thump at the same 0.24 s (DubSeconds in
  // tools/sounds/heartbeat.py) - change both or the gauge beats off the
  // sound
  DubTicks = 8;

type
  THeartbeat = class
  private
    FRunning: Boolean;
    // Beats a minute gathered since the last beat: a beat is due once
    // they make up a minute's worth of ticks
    FGathered: Single;
    FSinceBeat: Integer; // ticks
    FStruck: Boolean;
  public
    // Once per logic tick while the heart beats. The first tick after a
    // stop strikes at once
    procedure Tick(ABeatsPerMinute: Single);
    procedure Stop;
    // The pulse of both thumps, 0..1, AAlpha ticks past the current one
    function Pulse(AAlpha: Single): Single;
    property Running: Boolean read FRunning;
    // A beat was struck this tick: the first of its two thumps
    property Struck: Boolean read FStruck;
  end;

// The tempo of the last of the charge: 60 beats a minute at
// HeartbeatCharge, 90 at full, straight between them
function ChargeTempo(ACharge: Integer): Single;

implementation

uses
  System.Math, Hud.Energy;

const
  TicksPerSecond = 33;
  TicksPerMinute = 60 * TicksPerSecond;
  SlowestTempo = 60;
  FastestTempo = 90;
  // A thump fades out over this many ticks
  ThumpTicks = 7;
  DubLevel = 0.7;

function ChargeTempo(ACharge: Integer): Single;
begin
  var Share: Single := (ACharge - HeartbeatCharge) /
    (FullEnergy - HeartbeatCharge);
  Share := EnsureRange(Share, 0, 1);
  Result := SlowestTempo + (FastestTempo - SlowestTempo) * Share;
end;

// 1 at the thump, down to 0 over ThumpTicks; 0 before it
function Thump(ATicks: Single): Single;
begin
  if (ATicks < 0) or (ATicks >= ThumpTicks) then
    Exit(0);
  Result := Sqr(1 - ATicks / ThumpTicks);
end;

{ THeartbeat }

procedure THeartbeat.Tick(ABeatsPerMinute: Single);
begin
  FStruck := False;
  if not FRunning then
  begin
    FRunning := True;
    FGathered := 0;
    FSinceBeat := 0;
    FStruck := True;
    Exit;
  end;
  Inc(FSinceBeat);
  FGathered := FGathered + ABeatsPerMinute;
  if FGathered >= TicksPerMinute then
  begin
    FGathered := FGathered - TicksPerMinute;
    FSinceBeat := 0;
    FStruck := True;
  end;
end;

procedure THeartbeat.Stop;
begin
  FRunning := False;
  FStruck := False;
end;

function THeartbeat.Pulse(AAlpha: Single): Single;
begin
  if not FRunning then
    Exit(0);
  var Since: Single := FSinceBeat + AAlpha;
  var Lub := Thump(Since);
  var Dub: Single := DubLevel * Thump(Since - DubTicks);
  Result := Max(Lub, Dub);
end;

end.
