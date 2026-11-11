{
  Game.Takeoff - the Ram off the road on its jets, its wheels gone. First
  its engine bays come out of the depth of both arches - the rear one
  behind its wheel - and the nozzles slide down out of their rings. Then
  fire bursts down out of the front nozzle and the bow lifts off the road,
  the hull rocking up about its rear wheel; a breath, and the fire out of
  the rear nozzle catches, and the hull rises on its two jets, the rear
  wheel still in its well - till the fire throws it down out of it, a
  little way up. Off the road it turns about its middle, no more about
  the wheel, and rights itself as it rises: it swings past level, back,
  and settles, a spring dying out - then it hangs on its jets. Hanging it
  bobs and rocks, ever so little, out of step, and keeps over the hero:
  told how far he is across, it goes after him with a lag, slower than he
  runs, and banks into the way it goes.

  Hanging, it can be carried: the caller says each tick how fast it goes
  across, how high it is and how it leans, and lets it go to hang again
  where it left it - the Ram's charge flies it so.

  Aloft the nozzles swivel in their rings, within a few degrees either
  way: with the way it goes and harder with the way it gathers or loses
  pace - flying right, their bottoms swing left and the fire pushes it on;
  braking, the other way, the fire thrown ahead.

  Not here: where the hull stands across and how it is drawn - the Ram
  says, and moves it by the pace this gives; the wheel spat out
  (Game.Wheel); the bays, the nozzles, the fire and the dust - the Ram's
  painter.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.Takeoff;
{$I ..\Moon2D.inc}

interface

const
  // The bays come out of the arches over BayTicks, then the nozzles out of
  // their rings over NozzleTicks, then the front jet catches
  BayTicks = 14;
  NozzleTicks = 8;
  // Degrees the bow lifts, and how long it takes
  BowUpDegrees = 10.0;
  BowUpTicks = 24;
  // The rear jet catches this long after the front one
  RearJetAfterTicks = 33;
  // Units it has risen as the rear jet throws its wheel down: a cell and a
  // half - high enough for the fall to read and the bounces to carry, low
  // enough for a hull just off the road, a quarter of its climb gone
  SpitLift = 48.0;
  // Units the hull rises over the road, and how long it takes: the bottom
  // of its body just over the top of the moon form's jump
  HangLift = 184.0;
  RiseTicks = 75;
  // Hanging: up and down by BobUnits over BobTicks, rocking by
  // WobbleDegrees over WobbleTicks - grown into over SwayRampTicks from
  // the moment it settles
  BobUnits = 3.0;
  BobTicks = 80;
  WobbleDegrees = 1.2;
  WobbleTicks = 110;
  SwayRampTicks = 33;
  // After the hero: pulled toward him, held back by the drag, gathering or
  // losing no more than ChaseAccel a tick and never faster than
  // ChaseMaxPace units a tick - he runs at 2; banked BankPerPace degrees
  // clockwise for each unit a tick it goes right
  ChaseSpring = 0.004;
  ChaseDrag = 0.12;
  ChaseAccel = 0.06;
  ChaseMaxPace = 1.6;
  BankPerPace = 2.5;
  // The nozzles' swivel, degrees either way at most: the actuators are
  // painted fixed in the bay
  SwivelMost = 12.0;

type
  // tkOpening - the bays and the nozzles coming out, no fire yet; tkBowUp -
  // the front jet, the bow lifting about the rear wheel; tkRising - both
  // jets, off the road; tkHanging - risen and settled, it bobs, rocks and
  // keeps over the hero; tkCarried - aloft, flown by the caller
  TTakeoffStage = (tkNone, tkOpening, tkBowUp, tkRising, tkHanging, tkCarried);
  TTakeoffJet = (tjFront, tjRear);

  TTakeoffCue = record
    // A jet catches: the front one once the nozzles are out, the rear one
    // as it starts to rise
    Ignite: Boolean;
    Jet: TTakeoffJet;
    // The rear wheel thrown down out of its well, SpitLift up
    Spit: Boolean;
    // Risen and settled: it hangs
    Steady: Boolean;
  end;

  TTakeoff = record
  private
    FStage: TTakeoffStage;
    // Ticks into the stage
    FTicks: Integer;
    // Degrees clockwise: where it leaned as it started, where the bow
    // lifted stands; the spring's swing, degrees a tick
    FFrom, FBowUp: Single;
    FLean, FLastLean: Single;
    FSwing: Single;
    FLift, FLastLift: Single;
    FAir, FLastAir: Single;
    FSpat: Boolean;
    // 0..1: how far the bays are out of the arches, the nozzles out of
    // their rings
    FBay, FLastBay: Single;
    FNozzle, FLastNozzle: Single;
    // Units a tick across, after the hero or as carried; how much that
    // changed this tick
    FPace: Single;
    FGain: Single;
    // Degrees clockwise the nozzles turn in their rings
    FSwivel, FLastSwivel: Single;
    // Ticks since each jet caught; -1 - out
    FLit: array [TTakeoffJet] of Integer;
    FJets, FLastJets: array [TTakeoffJet] of Single;
    procedure Catch(AJet: TTakeoffJet; var ACue: TTakeoffCue);
    procedure TickOpening(var ACue: TTakeoffCue);
    procedure TickBowUp(var ACue: TTakeoffCue);
    procedure TickRising(var ACue: TTakeoffCue);
    procedure TickHanging(AToward: Single);
    procedure TickJets;
    procedure TickSwivel;
  public
    // From ALean degrees clockwise, the hull facing AFacing - 1 right, -1
    // left: the bow lifts the other way round
    procedure Start(ALean: Single; AFacing: Integer);
    // Hanging from the start, level, the bays and the nozzles out, both
    // jets burning steadily, the rear wheel long spat: a restart in the
    // air phase
    procedure Hang;
    procedure Stop;
    // AToward: units from the middle of the hull to where it is to keep
    // over, across - right is more; heard only while it hangs
    function Tick(AToward: Single = 0): TTakeoffCue;
    // After the tick's Tick: this tick it goes APace units across, hangs
    // ALift over the road and leans ALean degrees clockwise. Hanging, it is
    // carried from now on; nothing on its way up.
    procedure Carry(APace, ALift, ALean: Single);
    // Carried, it hangs again from where it was left, its pace kept
    procedure Release;
    function Running: Boolean;
    // Hanging or carried
    function Aloft: Boolean;
    property Stage: TTakeoffStage read FStage;
    // The rear wheel is out of its well
    property Spat: Boolean read FSpat;
    // Units a tick it goes across this tick, right is more
    property Pace: Single read FPace;
    // AAlpha of the way from the last tick to this one
    function LeanAt(AAlpha: Single): Single;
    function LiftAt(AAlpha: Single): Single;
    // 0 - it turns about its rear wheel's touch of the road, 1 - about its
    // middle
    function AirAt(AAlpha: Single): Single;
    // 0 out, 1 burning; over 1 for a moment as it catches
    function JetAt(AJet: TTakeoffJet; AAlpha: Single): Single;
    // 0 in the depth of the arch, 1 out; both arches alike
    function BayAt(AAlpha: Single): Single;
    // 0 in the ring, 1 out
    function NozzleAt(AAlpha: Single): Single;
    // Degrees clockwise the nozzles turn in their rings, within SwivelMost
    function SwivelAt(AAlpha: Single): Single;
  end;

implementation

uses
  System.Math;

const
  // Off the road it comes to turn about its middle over this long
  AirTicks = 20;
  // The spring that rights it: a swing of about 44 ticks, dying out to a
  // third past level and back
  SpringPull = 0.0204;
  SpringDrag = 0.1;
  // Under these it has settled
  SettledDegrees = 0.05;
  SettledSwing = 0.01;
  // A jet catches over JetCatchTicks, flaring up by JetFlare of itself,
  // and comes down to its steady fire over JetSettleTicks
  JetCatchTicks = 3;
  JetFlare = 0.5;
  JetSettleTicks = 10;
  // The swivel: degrees for a unit a tick of pace, and for a unit a tick
  // gained or lost in a tick - the push outweighs the drift, so a brake
  // throws the fire ahead however fast it still goes; each tick it turns
  // this share of the way to where it is wanted
  SwivelPerPace = 0.5;
  SwivelPerGain = 60.0;
  SwivelLearn = 0.25;

function SmoothStep(AShare: Single): Single;
begin
  var Share := EnsureRange(AShare, 0.0, 1.0);
  Result := Share * Share * (3 - 2 * Share);
end;

function Lerp(AFrom, ATo, AAmount: Single): Single;
begin
  Result := AFrom + (ATo - AFrom) * AAmount;
end;

procedure TTakeoff.Start(ALean: Single; AFacing: Integer);
begin
  Stop;
  FStage := tkOpening;
  FFrom := ALean;
  FBowUp := -Sign(AFacing) * BowUpDegrees;
  FLean := ALean;
  FLastLean := ALean;
end;

procedure TTakeoff.Hang;
begin
  Stop;
  FStage := tkHanging;
  FLift := HangLift;
  FLastLift := HangLift;
  FAir := 1;
  FLastAir := 1;
  FSpat := True;
  FBay := 1;
  FLastBay := 1;
  FNozzle := 1;
  FLastNozzle := 1;
  for var Jet := Low(TTakeoffJet) to High(TTakeoffJet) do
  begin
    FLit[Jet] := JetCatchTicks + JetSettleTicks;
    FJets[Jet] := 1;
    FLastJets[Jet] := 1;
  end;
end;

procedure TTakeoff.Stop;
begin
  FStage := tkNone;
  FTicks := 0;
  FFrom := 0;
  FBowUp := 0;
  FLean := 0;
  FLastLean := 0;
  FSwing := 0;
  FLift := 0;
  FLastLift := 0;
  FAir := 0;
  FLastAir := 0;
  FSpat := False;
  FBay := 0;
  FLastBay := 0;
  FNozzle := 0;
  FLastNozzle := 0;
  FPace := 0;
  FGain := 0;
  FSwivel := 0;
  FLastSwivel := 0;
  for var Jet := Low(TTakeoffJet) to High(TTakeoffJet) do
  begin
    FLit[Jet] := -1;
    FJets[Jet] := 0;
    FLastJets[Jet] := 0;
  end;
end;

function TTakeoff.Running: Boolean;
begin
  Result := FStage <> tkNone;
end;

function TTakeoff.Tick(AToward: Single): TTakeoffCue;
begin
  Result := Default(TTakeoffCue);
  if FStage = tkNone then
    Exit;
  FLastLean := FLean;
  FLastLift := FLift;
  FLastAir := FAir;
  FLastBay := FBay;
  FLastNozzle := FNozzle;
  FLastJets := FJets;
  FLastSwivel := FSwivel;
  Inc(FTicks);
  case FStage of
    tkOpening:
      TickOpening(Result);
    tkBowUp:
      TickBowUp(Result);
    tkRising:
      TickRising(Result);
    tkHanging:
      begin
        TickHanging(AToward);
        TickSwivel;
      end;
  end;
  TickJets;
end;

procedure TTakeoff.Carry(APace, ALift, ALean: Single);
begin
  if not Aloft then
    Exit;
  FStage := tkCarried;
  FGain := APace - FPace;
  FPace := APace;
  FLift := ALift;
  FLean := ALean;
  TickSwivel;
end;

// The hang's sway grows in again from nothing, so a hull let go level at
// its height does not jump
procedure TTakeoff.Release;
begin
  if FStage <> tkCarried then
    Exit;
  FStage := tkHanging;
  FTicks := 0;
  FGain := 0;
end;

function TTakeoff.Aloft: Boolean;
begin
  Result := FStage in [tkHanging, tkCarried];
end;

procedure TTakeoff.Catch(AJet: TTakeoffJet; var ACue: TTakeoffCue);
begin
  FLit[AJet] := 0;
  ACue.Ignite := True;
  ACue.Jet := AJet;
end;

// The front jet catches on the tick the nozzles are out, so the cue is
// heard with the first fire
procedure TTakeoff.TickOpening(var ACue: TTakeoffCue);
begin
  FBay := SmoothStep(FTicks / BayTicks);
  FNozzle := SmoothStep((FTicks - BayTicks) / NozzleTicks);
  if FTicks < BayTicks + NozzleTicks then
    Exit;
  FStage := tkBowUp;
  FTicks := 0;
  Catch(tjFront, ACue);
end;

procedure TTakeoff.TickBowUp(var ACue: TTakeoffCue);
begin
  FLean := Lerp(FFrom, FBowUp, SmoothStep(FTicks / BowUpTicks));
  if FTicks < RearJetAfterTicks then
    Exit;
  FStage := tkRising;
  FTicks := 0;
  FSwing := 0;
  Catch(tjRear, ACue);
end;

// Up on a smooth step; the spring pulls the lean to level all the while
procedure TTakeoff.TickRising(var ACue: TTakeoffCue);
begin
  FLift := HangLift * SmoothStep(FTicks / RiseTicks);
  if not FSpat and (FLift >= SpitLift) then
  begin
    FSpat := True;
    ACue.Spit := True;
  end;
  FAir := SmoothStep(FTicks / AirTicks);
  FSwing := FSwing - SpringPull * FLean - SpringDrag * FSwing;
  FLean := FLean + FSwing;
  var Settled := (FTicks >= RiseTicks) and (Abs(FLean) < SettledDegrees) and
    (Abs(FSwing) < SettledSwing);
  if not Settled then
    Exit;
  FLean := 0;
  FSwing := 0;
  FStage := tkHanging;
  FTicks := 0;
  ACue.Steady := True;
end;

// Bob and rock grow in from nothing, so the settled hull does not jump;
// the bank follows the pace, which starts from rest
procedure TTakeoff.TickHanging(AToward: Single);
begin
  var Pull := EnsureRange(ChaseSpring * AToward - ChaseDrag * FPace,
    -ChaseAccel, ChaseAccel);
  var OldPace := FPace;
  FPace := EnsureRange(FPace + Pull, -ChaseMaxPace, ChaseMaxPace);
  FGain := FPace - OldPace;
  var Sway := Min(FTicks / SwayRampTicks, 1);
  FLift := HangLift + Sway * BobUnits * Sin(2 * Pi * FTicks / BobTicks);
  FLean := Sway * WobbleDegrees * Sin(2 * Pi * FTicks / WobbleTicks) +
    BankPerPace * FPace;
end;

procedure TTakeoff.TickJets;
begin
  for var Jet := Low(TTakeoffJet) to High(TTakeoffJet) do
  begin
    if FLit[Jet] < 0 then
      Continue;
    Inc(FLit[Jet]);
    if FLit[Jet] <= JetCatchTicks then
      FJets[Jet] := (1 + JetFlare) * FLit[Jet] / JetCatchTicks
    else
      FJets[Jet] := 1 + JetFlare *
        Max(0, 1 - (FLit[Jet] - JetCatchTicks) / JetSettleTicks);
  end;
end;

// Flying right, the bottoms swing left - clockwise - so the fire pushes it
// on; a gain right swings them further, a loss swings them back past
// straight down
procedure TTakeoff.TickSwivel;
begin
  var Wanted := EnsureRange(SwivelPerPace * FPace + SwivelPerGain * FGain,
    -SwivelMost, SwivelMost);
  FSwivel := FSwivel + SwivelLearn * (Wanted - FSwivel);
end;

function TTakeoff.LeanAt(AAlpha: Single): Single;
begin
  Result := Lerp(FLastLean, FLean, AAlpha);
end;

function TTakeoff.LiftAt(AAlpha: Single): Single;
begin
  Result := Lerp(FLastLift, FLift, AAlpha);
end;

function TTakeoff.AirAt(AAlpha: Single): Single;
begin
  Result := Lerp(FLastAir, FAir, AAlpha);
end;

function TTakeoff.JetAt(AJet: TTakeoffJet; AAlpha: Single): Single;
begin
  Result := Lerp(FLastJets[AJet], FJets[AJet], AAlpha);
end;

function TTakeoff.BayAt(AAlpha: Single): Single;
begin
  Result := Lerp(FLastBay, FBay, AAlpha);
end;

function TTakeoff.NozzleAt(AAlpha: Single): Single;
begin
  Result := Lerp(FLastNozzle, FNozzle, AAlpha);
end;

function TTakeoff.SwivelAt(AAlpha: Single): Single;
begin
  Result := Lerp(FLastSwivel, FSwivel, AAlpha);
end;

end.
