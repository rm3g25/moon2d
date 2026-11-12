{
  Game.Charge - the Ram's charge, its own name: from the third rung of the
  air fight it rams across the screen.

  Begun where it hangs, it falls back - it loses pace against the flight
  and drifts off past the left edge, ever faster. Out there, unseen, it
  drops to the corridor it will run along and gathers speed; a red band
  blinks at the left edge across the corridor's height, its eye red there,
  for about a second and a half. Then it comes in from behind at speed,
  bow first, across the whole screen, and brakes short of the right edge:
  its bow thrown up, it slows hard and hangs there low - the nozzles hot
  from the brake, the window - while they cool. Then it climbs straight up
  to its height and is let go to hang.

  The finisher's charge does not brake: at speed it goes on right through
  the screen and is gone past the right edge - what comes after is the
  caller's.

  The corridor is the caller's: how high the hull is to hang as it runs,
  given with the start. The way across, the height and the lean are this
  unit's; the caller flies the hull by them. While it runs low - from the
  pass till it climbs - whatever small barge it meets is the caller's to
  smash; while it rams - the pass and the hard part of the brake - a hero
  it meets is struck. No drawing, no hull, no barges.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.Charge;
{$I ..\Moon2D.inc}

interface

const
  // Falling back it loses this much pace a tick, to this much at most
  ChargeLeaveGain = 0.3;
  ChargeLeaveMost = 8.0;
  // Off once its right edge is this far past the left edge; it comes in
  // from as far
  ChargeBeyond = 24.0;
  // The band at the left edge before it comes: about a second and a half
  ChargeWarnTicks = 43;
  // Units a tick across the screen; the brake takes about this long and
  // stops it with its right edge this far inside the right edge
  ChargePace = 20.0;
  ChargeBrakeTicks = 26;
  ChargeHoldInset = 8.0;
  // Low at the right edge, the nozzles cooling: the window; then up to
  // its height
  ChargeHoldTicks = 82;
  ChargeClimbTicks = 50;
  // A hero is struck while it goes at least this fast
  ChargeRamPace = 4.0;
  // Degrees the bow is down: falling back it flares a little, in the pass
  // it dips, braking it is thrown up, low it settles a little bow up
  ChargeLeaveBow = -4.0;
  ChargePassBow = 3.0;
  ChargeBrakeBow = -10.0;
  ChargeHoldBow = -2.0;

type
  // How a charge ends: ceBrake - short of the right edge, low, the window,
  // then up to its height; ceThrough - on at speed past the right edge
  TChargeEnd = (ceBrake, ceThrough);

  // csNone - not charging; csLeaving - falling back past the left edge;
  // csWarning - out there, the band blinking; csPassing - in at speed;
  // csBraking - slowing hard short of the right edge; csHolding - low, the
  // nozzles hot and cooling; csClimbing - up to its height
  TChargeStage = (csNone, csLeaving, csWarning, csPassing, csBraking,
    csHolding, csClimbing);

  TChargeCue = record
    // It starts to fall back
    Leaves: Boolean;
    // The band blinks at the left edge
    Warns: Boolean;
    // It comes in at speed
    Rushes: Boolean;
    // It brakes, the nozzles thrown ahead
    Brakes: Boolean;
    // Through the screen and gone past the right edge: the end of a charge
    // that does not brake
    Gone: Boolean;
    // Up at its height: to be let go to hang
    Done: Boolean;
  end;

  TCharge = class
  private
    FWidth: Single;
    FEnd: TChargeEnd;
    FStage: TChargeStage;
    FTicks: Integer;
    FLowLift: Single;
    FLeft, FLastLeft: Single;
    FLift: Single;
    FBow: Single;
    // Where the brake set off from, and how long it takes
    FBrakeFrom: Single;
    FBrakeTicks: Integer;
    // How low the hold left it bow up, for the climb to level it from
    FHeldBow: Single;
    FHeat, FLastHeat: Single;
    FWarn, FLastWarn: Single;
    function HoldLeft: Single;
    procedure BowToward(AWanted: Single);
    procedure TickLeaving(var ACue: TChargeCue);
    procedure TickWarning(var ACue: TChargeCue);
    procedure TickPassing(var ACue: TChargeCue);
    procedure TickBraking;
    procedure TickHolding;
    procedure TickClimbing(var ACue: TChargeCue);
    procedure Enter(AStage: TChargeStage);
  public
    // AWidth - the hull's
    constructor Create(AWidth: Single);
    // A death, a new fight: not charging
    procedure Clear;
    // From where it hangs: its left edge at ALeft, going APace units a tick
    // across, ALift over the road; it is to run along the corridor that
    // ALowLift puts it in, and to end as AEnd says. Nothing while it
    // charges.
    procedure Start(ALeft, APace, ALift, ALowLift: Single;
      AEnd: TChargeEnd = ceBrake);
    function Tick: TChargeCue;
    function Running: Boolean;
    property Stage: TChargeStage read FStage;
    // Where it is to be this tick: its left edge, units over the road, and
    // degrees its bow is down
    property Left: Single read FLeft;
    property Lift: Single read FLift;
    property Bow: Single read FBow;
    // Units it went across this tick, right is more
    function Pace: Single;
    property LowLift: Single read FLowLift;
    // From the pass till it climbs: low in the lanes, a small barge it
    // meets is smashed
    function RunsLow: Boolean;
    // Fast enough to strike a hero it meets
    function Rams: Boolean;
    // The nozzles are hot from the brake: an orb that meets one takes a
    // life of the hull
    function Soft: Boolean;
    // From the band till it is up again: no small barge comes in
    function HoldsFlock: Boolean;
    // AAlpha of the way from the last tick to this one: 0 cold to 1 hot;
    // the band's light, 0 none to 1
    function HeatAt(AAlpha: Single): Single;
    function WarnAt(AAlpha: Single): Single;
  end;

implementation

uses
  System.Math, Game.Space, Game.Takeoff;

const
  // Each tick the bow goes this share of the way to where it is wanted
  BowLearn = 0.2;
  // The band blinks once in this long, brighter as it comes
  WarnBlinkTicks = 8;
  WarnFirstLevel = 0.5;

function Lerp(AFrom, ATo, AAmount: Single): Single;
begin
  Result := AFrom + (ATo - AFrom) * AAmount;
end;

function SmoothStep(AShare: Single): Single;
begin
  var Share := EnsureRange(AShare, 0.0, 1.0);
  Result := Share * Share * (3 - 2 * Share);
end;

constructor TCharge.Create(AWidth: Single);
begin
  inherited Create;
  FWidth := AWidth;
  Clear;
end;

procedure TCharge.Clear;
begin
  FStage := csNone;
  FEnd := ceBrake;
  FTicks := 0;
  FLowLift := 0;
  FLeft := 0;
  FLastLeft := 0;
  FLift := 0;
  FBow := 0;
  FBrakeFrom := 0;
  FBrakeTicks := 0;
  FHeldBow := 0;
  FHeat := 0;
  FLastHeat := 0;
  FWarn := 0;
  FLastWarn := 0;
end;

procedure TCharge.Start(ALeft, APace, ALift, ALowLift: Single;
  AEnd: TChargeEnd);
begin
  if Running then
    Exit;
  Clear;
  FEnd := AEnd;
  FLowLift := ALowLift;
  FLeft := ALeft;
  // So the first tick goes on at the pace it hung at
  FLastLeft := ALeft - APace;
  FLift := ALift;
  Enter(csLeaving);
end;

function TCharge.Running: Boolean;
begin
  Result := FStage <> csNone;
end;

procedure TCharge.Enter(AStage: TChargeStage);
begin
  FStage := AStage;
  FTicks := 0;
end;

function TCharge.HoldLeft: Single;
begin
  Result := ScreenWidth - ChargeHoldInset - FWidth;
end;

procedure TCharge.BowToward(AWanted: Single);
begin
  FBow := FBow + BowLearn * (AWanted - FBow);
end;

function TCharge.Tick: TChargeCue;
begin
  Result := Default(TChargeCue);
  if FStage = csNone then
    Exit;
  var LastPace := FLeft - FLastLeft;
  FLastLeft := FLeft;
  FLastHeat := FHeat;
  FLastWarn := FWarn;
  Inc(FTicks);
  case FStage of
    csLeaving:
      begin
        FLeft := FLeft + Max(LastPace - ChargeLeaveGain, -ChargeLeaveMost);
        TickLeaving(Result);
      end;
    csWarning:
      TickWarning(Result);
    csPassing:
      TickPassing(Result);
    csBraking:
      TickBraking;
    csHolding:
      TickHolding;
    csClimbing:
      TickClimbing(Result);
  end;
end;

// It loses pace against the flight - a flare, bow up a little - till it
// is off past the left edge; out there it drops to the corridor unseen
procedure TCharge.TickLeaving(var ACue: TChargeCue);
begin
  ACue.Leaves := FTicks = 1;
  BowToward(ChargeLeaveBow);
  if FLeft + FWidth > -ChargeBeyond then
    Exit;
  Enter(csWarning);
  FLeft := -FWidth - ChargeBeyond;
  FLastLeft := FLeft;
  FLift := FLowLift;
  FBow := ChargePassBow;
  ACue.Warns := True;
end;

procedure TCharge.TickWarning(var ACue: TChargeCue);
begin
  var Share: Single := FTicks / ChargeWarnTicks;
  var Blink := 0.5 + 0.5 * Cos(2 * Pi * FTicks / WarnBlinkTicks);
  FWarn := Lerp(WarnFirstLevel, 1, Share) * Sqr(Blink);
  if FTicks < ChargeWarnTicks then
    Exit;
  FWarn := 0;
  Enter(csPassing);
  FLeft := FLeft + ChargePace;
  ACue.Rushes := True;
end;

// At speed till the brake can stop it short of the right edge; the brake
// from where it is then, so it comes in at the pace it ran. With no brake,
// on till it is gone past the right edge.
procedure TCharge.TickPassing(var ACue: TChargeCue);
begin
  BowToward(ChargePassBow);
  if FEnd = ceThrough then
  begin
    FLeft := FLeft + ChargePace;
    if FLeft < ScreenWidth + ChargeBeyond then
      Exit;
    Enter(csNone);
    ACue.Gone := True;
    Exit;
  end;
  var BrakeReach: Single := ChargePace * ChargeBrakeTicks / 2;
  if FLeft + ChargePace < HoldLeft - BrakeReach then
  begin
    FLeft := FLeft + ChargePace;
    Exit;
  end;
  Enter(csBraking);
  FBrakeFrom := FLeft;
  FBrakeTicks := Max(1, Ceil(2 * (HoldLeft - FBrakeFrom) / ChargePace));
  ACue.Brakes := True;
  // This tick is the brake's first: it never stands still between the two
  FTicks := 1;
  TickBraking;
end;

// Slowing evenly to a stand; the nozzles heat up with the brake
procedure TCharge.TickBraking;
begin
  var Share: Single := Min(FTicks / FBrakeTicks, 1);
  FLeft := HoldLeft - (HoldLeft - FBrakeFrom) * Sqr(1 - Share);
  FHeat := Share;
  BowToward(ChargeBrakeBow);
  if FTicks < FBrakeTicks then
    Exit;
  FLeft := HoldLeft;
  FHeat := 1;
  Enter(csHolding);
end;

// The fade is the window's clock: cold as it climbs
procedure TCharge.TickHolding;
begin
  FHeat := Max(1 - FTicks / ChargeHoldTicks, 0);
  BowToward(ChargeHoldBow);
  if FTicks < ChargeHoldTicks then
    Exit;
  FHeat := 0;
  FHeldBow := FBow;
  Enter(csClimbing);
end;

// Straight up and level, so it is let go at its height, level, at rest
procedure TCharge.TickClimbing(var ACue: TChargeCue);
begin
  var Share := SmoothStep(FTicks / ChargeClimbTicks);
  FLift := Lerp(FLowLift, HangLift, Share);
  FBow := Lerp(FHeldBow, 0, Share);
  if FTicks < ChargeClimbTicks then
    Exit;
  FLift := HangLift;
  FBow := 0;
  Enter(csNone);
  ACue.Done := True;
end;

function TCharge.Pace: Single;
begin
  Result := FLeft - FLastLeft;
end;

function TCharge.RunsLow: Boolean;
begin
  Result := FStage in [csPassing, csBraking, csHolding];
end;

function TCharge.Rams: Boolean;
begin
  Result := (FStage = csPassing) or
    ((FStage = csBraking) and (Pace >= ChargeRamPace));
end;

function TCharge.Soft: Boolean;
begin
  Result := FStage in [csBraking, csHolding];
end;

function TCharge.HoldsFlock: Boolean;
begin
  Result := FStage in [csWarning..csClimbing];
end;

function TCharge.HeatAt(AAlpha: Single): Single;
begin
  Result := Lerp(FLastHeat, FHeat, AAlpha);
end;

function TCharge.WarnAt(AAlpha: Single): Single;
begin
  Result := Lerp(FLastWarn, FWarn, AAlpha);
end;

end.
