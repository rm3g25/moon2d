{
  Game.Takeoff - the Ram off the road on its jets, its wheels gone. Fire
  bursts down out of the empty front well and the bow lifts off the road,
  the hull rocking up about its rear wheel; a breath, and the fire out of
  the rear well spits the rear wheel out, and the hull rises on its two
  jets. Off the road it turns about its middle, no more about the wheel,
  and rights itself as it rises: it swings past level, back, and settles,
  a spring dying out - then it hangs, steady, its jets burning.

  Not here: where the hull stands across and how it is drawn - the Ram
  says; the wheel spat out (Game.Wheel); the fire and the dust - the Ram's
  painter.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.Takeoff;
{$I ..\Moon2D.inc}

interface

const
  // Degrees the bow lifts, and how long it takes
  BowUpDegrees = 10.0;
  BowUpTicks = 24;
  // The rear jet catches this long after the front one
  RearJetAfterTicks = 33;
  // Units the hull rises over the road, and how long it takes: the bottom
  // of its body just over the top of the moon form's jump
  HangLift = 184.0;
  RiseTicks = 75;

type
  // tkBowUp - the front jet, the bow lifting about the rear wheel;
  // tkRising - both jets, off the road; tkHanging - risen and settled
  TTakeoffStage = (tkNone, tkBowUp, tkRising, tkHanging);
  TTakeoffJet = (tjFront, tjRear);

  TTakeoffCue = record
    // A jet catches: the front one at the start, the rear one as it spits
    // the wheel out
    Ignite: Boolean;
    Jet: TTakeoffJet;
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
    // Ticks since each jet caught; -1 - out
    FLit: array [TTakeoffJet] of Integer;
    FJets, FLastJets: array [TTakeoffJet] of Single;
    procedure Catch(AJet: TTakeoffJet; var ACue: TTakeoffCue);
    procedure TickBowUp(var ACue: TTakeoffCue);
    procedure TickRising(var ACue: TTakeoffCue);
    procedure TickJets;
  public
    // From ALean degrees clockwise, the hull facing AFacing - 1 right, -1
    // left: the bow lifts the other way round
    procedure Start(ALean: Single; AFacing: Integer);
    procedure Stop;
    function Tick: TTakeoffCue;
    function Running: Boolean;
    property Stage: TTakeoffStage read FStage;
    // AAlpha of the way from the last tick to this one
    function LeanAt(AAlpha: Single): Single;
    function LiftAt(AAlpha: Single): Single;
    // 0 - it turns about its rear wheel's touch of the road, 1 - about its
    // middle
    function AirAt(AAlpha: Single): Single;
    // 0 out, 1 burning; over 1 for a moment as it catches
    function JetAt(AJet: TTakeoffJet; AAlpha: Single): Single;
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
  FStage := tkBowUp;
  FFrom := ALean;
  FBowUp := -Sign(AFacing) * BowUpDegrees;
  FLean := ALean;
  FLastLean := ALean;
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

function TTakeoff.Tick: TTakeoffCue;
begin
  Result := Default(TTakeoffCue);
  if FStage = tkNone then
    Exit;
  FLastLean := FLean;
  FLastLift := FLift;
  FLastAir := FAir;
  FLastJets := FJets;
  // The front jet catches with the first tick, so the cue is heard at once
  if FLit[tjFront] < 0 then
    Catch(tjFront, Result);
  Inc(FTicks);
  case FStage of
    tkBowUp:
      TickBowUp(Result);
    tkRising:
      TickRising(Result);
  end;
  TickJets;
end;

procedure TTakeoff.Catch(AJet: TTakeoffJet; var ACue: TTakeoffCue);
begin
  FLit[AJet] := 0;
  ACue.Ignite := True;
  ACue.Jet := AJet;
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
  ACue.Spit := True;
end;

// Up on a smooth step; the spring pulls the lean to level all the while
procedure TTakeoff.TickRising(var ACue: TTakeoffCue);
begin
  FLift := HangLift * SmoothStep(FTicks / RiseTicks);
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

end.
