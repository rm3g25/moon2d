{
  Pads.Plunge - the cycle of a pad that plunges under the hero
  (Levels.Pads, "plunge"): it holds until he stands on it, gives for the
  delay, falls out of the screen, lies below for the rest and climbs
  home, to hold again. Once it gives, stepping off does not save it.

  The pad is failing and shows it all the way round: it twitches, and its
  jets work unevenly - in fits while it holds, flat out and choking while
  it gives, dead in the fall, by lunges on the climb, which goes as
  unevenly as they do.

  The cycle only counts: how far below its place the pad is, how far a
  twitch dips and leans its picture, how hard its jets work. Pads.World
  moves the pad and draws it; the game passes the effort on to what hangs
  on the pad.

  The dice are the cycle's own, seeded by the pad: two plunging pads
  twitch out of step, and every try at a level twitches alike.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Pads.Plunge;
{$I ..\..\Moon2D.inc}

interface

uses
  Render.Brush, Levels.Pads;

type
  // Holding: on its place, the hero not on it yet. Giving: he has stood
  // on it, the delay runs. Falling, then Fallen: at rest under the
  // screen. Climbing: on the way home.
  TPlungePhase = (ppHolding, ppGiving, ppFalling, ppFallen, ppClimbing);

  // A value on a damped spring: a kick sets it swinging about zero
  TTwitchSpring = record
    Value, Speed: Double;
    procedure Kick(ASpeed: Double);
    procedure Tick;
  end;

  // Ticks from one throw of the dice to the next, either end included
  TTickSpan = record
    Least, Most: Integer;
  end;

  TPlungeCycle = record
  private
    FPlunges: Boolean;
    FDelayTicks, FRestTicks: Integer;
    FRiseStep: Double; // units a tick, at an even gait
    FReach: Double;
    FDice: TXorShift;
    FPhase: TPlungePhase;
    FPhaseTicks: Integer;
    FBelow: Double;
    FFallSpeed: Double; // units a tick
    FDip, FLean: TTwitchSpring;
    FTwitchIn: Integer; // ticks to the next twitch
    // The jets' power as the dice last threw it, 0..1, and the ticks to
    // the next throw
    FPower: Double;
    FPowerIn: Integer;
    procedure Enter(APhase: TPlungePhase);
    function RollTicks(const ASpan: TTickSpan): Integer;
    function RollKick(AMost: Double): Double;
    procedure Fall;
    procedure Climb;
    procedure TickPower;
    procedure TickTwitch;
  public
    // On its place, holding. AReach - how far below its place the pad
    // falls; ASeed - its dice. A pad that does not plunge never leaves
    // this state.
    procedure Rewind(const APlunge: TPadPlunge; AReach: Double;
      ASeed: Cardinal);
    // The hero stands on the pad this tick
    procedure Tread;
    procedure Tick;
    // How hard the jets work, 0..1
    function Effort: Single;

    property Phase: TPlungePhase read FPhase;
    // Units below its place
    property Below: Double read FBelow;
    // The twitch, for the picture alone: units down, and degrees
    property Dip: Double read FDip.Value;
    property Lean: Double read FLean.Value;
  end;

implementation

uses
  System.Math;

const
  // Seconds and units a second in JSON, ticks and units a tick in the
  // code; the logic runs 33 ticks a second (tickRate of Game.Config)
  LogicTicksPerSecond = 33;
  // The fall: the speed gained every tick, and the most of it. Slower,
  // and the pad reads as a lift going down; at this pace the hero has
  // some half a second of the fall to jump off it.
  FallGravity = 0.5;
  FallTopSpeed = 12.0;
  // The spring of a twitch is the spring of a pad's sag under a landing
  // (Pads.World), so the two read as one machine
  SpringStiffness = 0.18;
  SpringDamping = 0.3;
  SpringRest = 0.05; // closer than this, at rest
  // A twitch kicks the picture down by up to DipKick units a tick and
  // round by up to LeanKick degrees a tick - some two units and three
  // degrees at the widest -, and by no less than KickFloor of that
  DipKick = 1.8;
  LeanKick = 2.2;
  KickFloor = 0.5;
  // The pad twitches now and then; giving, all the time and harder
  CalmTwitchSpan: TTickSpan = (Least: 6; Most: 30);
  GivingTwitchSpan: TTickSpan = (Least: 2; Most: 5);
  GivingTwitchGain = 1.3;
  // The jets hold a power for a few ticks - long enough for what hangs
  // on the pad to follow (EffortEaseTicks of Levels.Dynamics)
  CalmPowerSpan: TTickSpan = (Least: 3; Most: 9);
  GivingPowerSpan: TTickSpan = (Least: 2; Most: 4);
  // Holding, the jets idle low and flare now and then, never to the full;
  // giving, they run flat out but for the throws under GivingChoke, when
  // they cut out; climbing, they never fall under ClimbEffortLeast
  IdleEffortMost = 0.6;
  GivingChoke = 0.3;
  ClimbEffortLeast = 0.4;
  // The climb goes by the jets' power: from a crawl to a lunge, at the
  // pad's own pace on average
  ClimbGaitLeast = 0.3;
  ClimbGaitMost = 1.7;

// ---------------------------------------------------------------------------
// TTwitchSpring
// ---------------------------------------------------------------------------

procedure TTwitchSpring.Kick(ASpeed: Double);
begin
  Speed := Speed + ASpeed;
end;

procedure TTwitchSpring.Tick;
begin
  Speed := Speed - SpringStiffness * Value - SpringDamping * Speed;
  Value := Value + Speed;
  if (Abs(Value) < SpringRest) and (Abs(Speed) < SpringRest) then
  begin
    Value := 0;
    Speed := 0;
  end;
end;

// ---------------------------------------------------------------------------
// TPlungeCycle
// ---------------------------------------------------------------------------

procedure TPlungeCycle.Rewind(const APlunge: TPadPlunge; AReach: Double;
  ASeed: Cardinal);
begin
  FPlunges := APlunge.Plunges;
  FDelayTicks := Round(APlunge.Delay * LogicTicksPerSecond);
  FRestTicks := Round(APlunge.Rest * LogicTicksPerSecond);
  FRiseStep := APlunge.Rise / LogicTicksPerSecond;
  FReach := AReach;
  // An xorshift seeded with zero stays at zero
  FDice.Seed := ASeed or 1;

  FBelow := 0;
  FDip := Default(TTwitchSpring);
  FLean := Default(TTwitchSpring);
  FPower := 0;
  Enter(ppHolding);
end;

// Both dice are thrown anew on the next tick: the pad answers the change
// at once - it lurches the moment the hero is on it
procedure TPlungeCycle.Enter(APhase: TPlungePhase);
begin
  FPhase := APhase;
  FPhaseTicks := 0;
  FFallSpeed := 0;
  FTwitchIn := 0;
  FPowerIn := 0;
end;

procedure TPlungeCycle.Tread;
begin
  if FPlunges and (FPhase = ppHolding) then
    Enter(ppGiving);
end;

function TPlungeCycle.RollTicks(const ASpan: TTickSpan): Integer;
begin
  Result := ASpan.Least +
    Trunc(FDice.NextUnit * (ASpan.Most - ASpan.Least + 1));
end;

function TPlungeCycle.RollKick(AMost: Double): Double;
begin
  Result := AMost * (KickFloor + (1 - KickFloor) * FDice.NextUnit);
end;

procedure TPlungeCycle.Fall;
begin
  FFallSpeed := Min(FFallSpeed + FallGravity, FallTopSpeed);
  FBelow := Min(FBelow + FFallSpeed, FReach);
  if FBelow >= FReach then
    Enter(ppFallen);
end;

procedure TPlungeCycle.Climb;
begin
  var Gait := ClimbGaitLeast + (ClimbGaitMost - ClimbGaitLeast) * FPower;
  FBelow := Max(0.0, FBelow - FRiseStep * Gait);
  if FBelow <= 0 then
    Enter(ppHolding);
end;

procedure TPlungeCycle.TickPower;
begin
  Dec(FPowerIn);
  if FPowerIn > 0 then
    Exit;

  var Span := CalmPowerSpan;
  if FPhase = ppGiving then
    Span := GivingPowerSpan;
  FPowerIn := RollTicks(Span);
  FPower := FDice.NextUnit;
end;

// The springs swing on in every phase; the kicks stop with the jets - a
// pad in its fall is dead weight
procedure TPlungeCycle.TickTwitch;
begin
  FDip.Tick;
  FLean.Tick;
  if FPhase in [ppFalling, ppFallen] then
    Exit;
  Dec(FTwitchIn);
  if FTwitchIn > 0 then
    Exit;

  var Span := CalmTwitchSpan;
  var Gain: Double := 1;
  if FPhase = ppGiving then
  begin
    Span := GivingTwitchSpan;
    Gain := GivingTwitchGain;
  end;
  FTwitchIn := RollTicks(Span);

  // Down always: the pad sinks a little and catches itself. Round either
  // way: it has no side it favours.
  FDip.Kick(Gain * RollKick(DipKick));
  var Way: Double := 1;
  if FDice.NextUnit < 0.5 then
    Way := -1;
  FLean.Kick(Way * Gain * RollKick(LeanKick));
end;

// The power first: the climb of this tick goes by it
procedure TPlungeCycle.Tick;
begin
  if not FPlunges then
    Exit;
  Inc(FPhaseTicks);
  TickPower;
  case FPhase of
    ppGiving:
      if FPhaseTicks >= FDelayTicks then
        Enter(ppFalling);
    ppFalling:
      Fall;
    ppFallen:
      if FPhaseTicks >= FRestTicks then
        Enter(ppClimbing);
    ppClimbing:
      Climb;
  end;
  TickTwitch;
end;

function TPlungeCycle.Effort: Single;
begin
  case FPhase of
    ppHolding:
      Result := IdleEffortMost * Sqr(FPower);
    ppGiving:
      if FPower < GivingChoke then
        Result := 0
      else
        Result := 1;
    ppClimbing:
      Result := ClimbEffortLeast + (1 - ClimbEffortLeast) * FPower;
  else
    Result := 0;
  end;
end;

end.
