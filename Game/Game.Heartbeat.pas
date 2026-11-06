{
  Game.Heartbeat - the one heartbeat that runs from the last of the charge
  to the throw: a double "tuk-tuk", low. It counts the beats and says when
  one is struck and how strong the pulse is between them; the sound, the
  gauge and the heart monitor follow it.

  It does not know the charge: the game hands it a tempo every tick, so
  later steps of the henshin can drive it by their own clock. What the
  last of the charge asks of it is ChargeTempo, what the rite of the
  eclipse asks is RiteTempo. The burst at the end of the rite asks for a
  last beat, stronger than any: the heart is still after it, whatever
  tempo it is handed, till it is stopped.

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
  // The last beat's pulse, against an ordinary one's
  LastBeatStrength = 1.6;

type
  THeartbeat = class
  private
    FRunning: Boolean;
    // Beats a minute gathered since the last beat: a beat is due once
    // they make up a minute's worth of ticks
    FGathered: Single;
    FSinceBeat: Integer; // ticks
    FStruck: Boolean;
    // The last beat is asked for; struck; struck this tick
    FLastDue: Boolean;
    FLast: Boolean;
    FFinal: Boolean;
    procedure StrikeNow;
  public
    // Once per logic tick while the heart beats. The first tick after a
    // stop strikes at once
    procedure Tick(ABeatsPerMinute: Single);
    procedure Stop;
    // The next tick strikes the last beat: none after it till a stop
    procedure StrikeLast;
    // The pulse of both thumps, 0..1 - the last beat's up to
    // LastBeatStrength - AAlpha ticks past the current one
    function Pulse(AAlpha: Single): Single;
    // Ticks since the last beat was struck, AAlpha past the current one;
    // -1 while the heart is still
    function SinceBeat(AAlpha: Single): Single;
    property Running: Boolean read FRunning;
    // A beat was struck this tick: the first of its two thumps
    property Struck: Boolean read FStruck;
    // The beat struck this tick is the last
    property Final: Boolean read FFinal;
  end;

// The tempo of the last of the charge: 60 beats a minute at
// HeartbeatCharge, 90 at full, straight between them
function ChargeTempo(ACharge: Integer): Single;
// The tempo of the rite of the eclipse: 90 with its ring empty, where the
// charge left it, 140 with the ring full, straight between them
function RiteTempo(ARingShare: Single): Single;

implementation

uses
  System.Math, Hud.Energy;

const
  TicksPerSecond = 33;
  TicksPerMinute = 60 * TicksPerSecond;
  StartTempo = 60;
  FullChargeTempo = 90;
  FullRingTempo = 140;
  // A thump fades out over this many ticks
  ThumpTicks = 7;
  DubLevel = 0.7;

function ChargeTempo(ACharge: Integer): Single;
begin
  var Share: Single := (ACharge - HeartbeatCharge) /
    (FullEnergy - HeartbeatCharge);
  Share := EnsureRange(Share, 0, 1);
  Result := StartTempo + (FullChargeTempo - StartTempo) * Share;
end;

function RiteTempo(ARingShare: Single): Single;
begin
  var Share := EnsureRange(ARingShare, 0, 1);
  Result := FullChargeTempo + (FullRingTempo - FullChargeTempo) * Share;
end;

// 1 at the thump, down to 0 over ThumpTicks; 0 before it
function Thump(ATicks: Single): Single;
begin
  if (ATicks < 0) or (ATicks >= ThumpTicks) then
    Exit(0);
  Result := Sqr(1 - ATicks / ThumpTicks);
end;

{ THeartbeat }

procedure THeartbeat.StrikeNow;
begin
  FRunning := True;
  FGathered := 0;
  FSinceBeat := 0;
  FStruck := True;
end;

procedure THeartbeat.Tick(ABeatsPerMinute: Single);
begin
  FStruck := False;
  FFinal := False;
  if FLastDue then
  begin
    StrikeNow;
    FLastDue := False;
    FLast := True;
    FFinal := True;
    Exit;
  end;
  if not FRunning then
  begin
    StrikeNow;
    Exit;
  end;
  Inc(FSinceBeat);
  if FLast then
    Exit;
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
  FLastDue := False;
  FLast := False;
  FFinal := False;
end;

procedure THeartbeat.StrikeLast;
begin
  FLastDue := True;
end;

function THeartbeat.Pulse(AAlpha: Single): Single;
begin
  if not FRunning then
    Exit(0);
  var Since: Single := FSinceBeat + AAlpha;
  var Lub := Thump(Since);
  var Dub: Single := DubLevel * Thump(Since - DubTicks);
  Result := Max(Lub, Dub);
  if FLast then
    Result := Result * LastBeatStrength;
end;

function THeartbeat.SinceBeat(AAlpha: Single): Single;
begin
  if not FRunning then
    Exit(-1);
  Result := FSinceBeat + AAlpha;
end;

end.
