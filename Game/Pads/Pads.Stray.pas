{
  Pads.Stray - the cycle of a pad that strays (Levels.Pads, "stray"):
  transport nobody can count on. Once its flock is let go it waits its
  moment, flies in from beyond an edge of the screen - the left, the
  right or the top - to a point of its zone, hangs there, then flies on
  to another point, or out beyond an edge to come in again later. It
  flies in and out along the row or down the column of its point, and
  between two points straight across the zone.

  Now and then it misbehaves, as the dice say: it turns back halfway
  along a leg; it stalls in the air, twitching, its jets cut out; it
  hangs twitching; it shakes for half a second and falls out of the
  screen as a pad that plunges does (Pads.Plunge counts the fall), to
  come in again later. A pad with the hero on it never leaves the room:
  on a leg out it turns back.

  A pad may be sent away: it flies out quietly beyond the nearer side, at
  half its pace, and stays out of sight. From then on it neither turns
  back, nor stalls, nor twitches, nor falls; a leg or a fall under way
  runs out first, and with the hero aboard it hangs until he is off it.

  The room is the screen less a cell at the left, the right and the top:
  only inside it is the pad a deck. Out past the walls nobody rides it,
  and a rider it takes there falls.

  The cycle only counts: where the pad is, how its picture twitches, how
  hard its jets work. Pads.World moves the pad and draws it.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Pads.Stray;
{$I ..\..\Moon2D.inc}

interface

uses
  Render.Brush, Levels.Pads, Pads.Plunge;

type
  // Asleep: out of sight, its flock not let go yet. Waiting: out of sight
  // until it flies in. Flying a leg, hanging at a point, shaking before a
  // fall, falling out of the screen.
  TStrayPhase = (spAsleep, spWaiting, spFlying, spHanging, spGiving,
    spFalling);

  // In from beyond an edge, on to another point, out beyond an edge, back
  // to where the leg it turned from began
  TStrayLeg = (slIn, slOn, slOut, slBack);

  TStrayCycle = record
  private
    FZone: TPadZone;
    FWidth: Integer;
    FWaitLeft, FWaitTop: Double;
    FFirstWaitTicks: Integer;
    FDice: TXorShift;
    FPhase: TStrayPhase;
    // Of a wait or of a hang: the ticks left
    FTicksLeft: Integer;
    FLeft, FTop: Double;
    FLeg: TStrayLeg;
    FFromX, FFromY, FToX, FToY: Double;
    FLegTicks, FLegClock: Integer;
    // The ticks into the leg it turns back at and stalls at; NoMoment -
    // it does not
    FTurnAt: Integer;
    FStallAt: Integer;
    FStallLeft: Integer;
    FTwitchyHang: Boolean;
    FTwitchIn: Integer;
    FDip, FLean: TTwitchSpring;
    FFall: TPlungeCycle;
    // Sent away: it leaves quietly and does not come back
    FDismissed: Boolean;
    function Roll: Double;
    function RollTicks(const ASpan: TTickSpan): Integer;
    function RollShare(ALeast, AMost: Double): Double;
    procedure PickPoint(out AX, AY: Double);
    procedure PickOtherPoint(out AX, AY: Double);
    procedure StartLeg(ALeg: TStrayLeg; AToX, AToY: Double);
    procedure FlyIn;
    procedure FlyOn;
    procedure FlyOut;
    procedure FlyAway;
    procedure TurnBack;
    procedure Hang;
    procedure Give;
    procedure GoWait(const ASpan: TTickSpan);
    procedure LeaveHang(ALoaded: Boolean);
    procedure TickLeg(ALoaded: Boolean);
    procedure TickHang(ALoaded: Boolean);
    procedure TickFall;
    procedure TickTwitch;
    function Twitching: Boolean;
    function GetTop: Double;
  public
    // Asleep at AWaitLeft, AWaitTop, out of sight; a pad AWidth units wide.
    // A pad that does not stray never leaves this state.
    procedure Rewind(const AStray: TPadStray; AWidth: Integer;
      AWaitLeft, AWaitTop: Double);
    // Its flock is let go: it waits its wait, then flies in. ASeed - its
    // dice. Nothing for a pad let go already.
    procedure Launch(ASeed: Cardinal);
    // Sent away: it flies out quietly and stays out of sight. Nothing for a
    // pad asleep - it stays asleep - and a pad sent away is let go no more.
    procedure Dismiss;
    // ALoaded - the hero stands on the pad this tick
    procedure Tick(ALoaded: Boolean);
    // In the air inside the room: a floor and a body
    function Deck: Boolean;
    // How hard the jets work, 0..1
    function Effort: Single;
    // The twitch, for the picture alone: units down, and degrees
    function Dip: Double;
    function Lean: Double;

    property Phase: TStrayPhase read FPhase;
    property Leg: TStrayLeg read FLeg;
    property Dismissed: Boolean read FDismissed;
    // The top-left corner of the deck
    property Left: Double read FLeft;
    property Top: Double read GetTop;
  end;

implementation

uses
  System.Math, Render.Sprites, Game.Space;

type
  TStrayEdge = (seLeft, seRight, seTop);

const
  LogicTicksPerSecond = 33;
  // Units a second along a leg, the mean of an eased one
  StrayPace = 96;
  StrayStep = StrayPace / LogicTicksPerSecond;
  // The walls of the room: a cell at the left, the right and the top
  RoomInset = TileSize;
  // Beyond an edge a pad starts and ends this far out, its rigs too
  OutsideMargin = TileSize;
  NoMoment = -1;
  // How long it hangs at a point, and waits out of sight before it comes
  // in again
  HangSpan: TTickSpan = (Least: 33; Most: 83);
  ReturnSpan: TTickSpan = (Least: 33; Most: 132);
  // At the end of a hang: the odds it falls, and those it flies out
  // rather than on - never with the hero on it
  FallOdds = 0.15;
  OutOdds = 0.35;
  // The odds a leg on or out turns back, and where along it
  TurnOdds = 0.2;
  TurnShareLeast = 0.35;
  TurnShareMost = 0.65;
  // The odds a leg stalls, where along it and for how long
  StallOdds = 0.2;
  StallShareLeast = 0.25;
  StallShareMost = 0.75;
  StallSpan: TTickSpan = (Least: 8; Most: 14);
  // The odds a hang is a twitchy one
  TwitchyOdds = 0.3;
  // A pad sent away flies at this share of the pace, its jets at this much
  QuietShare = 0.5;
  QuietEffort = 0.5;
  // A twitch kicks the picture down by up to DipKick units a tick and
  // round by up to LeanKick degrees, no less than KickFloor of that, every
  // few ticks
  DipKick = 2.2;
  LeanKick = 3.0;
  KickFloor = 0.5;
  TwitchSpan: TTickSpan = (Least: 2; Most: 6);
  // A twitchy hang works its jets in fits, about half
  TwitchyEffort = 0.5;
  // The fall: half a second of shaking, then down out of the screen as far
  // as a pad that plunges goes
  GivingSeconds = 0.5;
  FallDepth = 3 * TileSize;
  // Another point is looked for this many times before the same one is
  // taken
  PointTries = 8;

// Eased in and out: the pad sets off and comes to a stop gently
function Smoothstep(AShare: Double): Double;
begin
  Result := AShare * AShare * (3 - 2 * AShare);
end;

// ---------------------------------------------------------------------------
// TStrayCycle
// ---------------------------------------------------------------------------

procedure TStrayCycle.Rewind(const AStray: TPadStray; AWidth: Integer;
  AWaitLeft, AWaitTop: Double);
begin
  FZone := AStray.Zone;
  FWidth := AWidth;
  FWaitLeft := AWaitLeft;
  FWaitTop := AWaitTop;
  FFirstWaitTicks := Round(AStray.Wait * LogicTicksPerSecond);
  FPhase := spAsleep;
  FLeft := AWaitLeft;
  FTop := AWaitTop;
  FLeg := slIn;
  FStallLeft := 0;
  FTwitchyHang := False;
  FDip := Default(TTwitchSpring);
  FLean := Default(TTwitchSpring);
  FFall := Default(TPlungeCycle);
  FDismissed := False;
end;

procedure TStrayCycle.Launch(ASeed: Cardinal);
begin
  if (FPhase <> spAsleep) or FDismissed then
    Exit;
  // An xorshift seeded with zero stays at zero
  FDice.Seed := ASeed or 1;
  FPhase := spWaiting;
  FTicksLeft := FFirstWaitTicks;
end;

function TStrayCycle.Roll: Double;
begin
  Result := Min(FDice.NextUnit, 0.999999);
end;

function TStrayCycle.RollTicks(const ASpan: TTickSpan): Integer;
begin
  Result := ASpan.Least + Trunc(Roll * (ASpan.Most - ASpan.Least + 1));
end;

function TStrayCycle.RollShare(ALeast, AMost: Double): Double;
begin
  Result := ALeast + (AMost - ALeast) * Roll;
end;

procedure TStrayCycle.PickPoint(out AX, AY: Double);
begin
  var Cols := FZone.Right - FZone.Left + 1;
  var Rows := FZone.Bottom - FZone.Top + 1;
  AX := (FZone.Left + Trunc(Roll * Cols)) * TileSize;
  AY := (FZone.Top + Trunc(Roll * Rows)) * TileSize;
end;

// A zone of one cell has no other: the pad flies to where it hangs
procedure TStrayCycle.PickOtherPoint(out AX, AY: Double);
begin
  for var i := 1 to PointTries do
  begin
    PickPoint(AX, AY);
    if (AX <> FLeft) or (AY <> FTop) then
      Exit;
  end;
end;

// From where the pad stands now. Turning back and stalling are thrown at
// the start of the leg; a leg back neither turns nor stalls, nor does any
// leg of a pad sent away, which flies it slower.
procedure TStrayCycle.StartLeg(ALeg: TStrayLeg; AToX, AToY: Double);
begin
  var Step: Double := StrayStep;
  if FDismissed then
    Step := StrayStep * QuietShare;
  FLeg := ALeg;
  FFromX := FLeft;
  FFromY := FTop;
  FToX := AToX;
  FToY := AToY;
  FLegClock := 0;
  FLegTicks := Max(1, Round(Hypot(AToX - FLeft, AToY - FTop) / Step));
  FTurnAt := NoMoment;
  FStallAt := NoMoment;
  FStallLeft := 0;
  FPhase := spFlying;
  if FDismissed then
    Exit;
  var MayTurn := ALeg in [slOn, slOut];
  if MayTurn and (Roll < TurnOdds) then
    FTurnAt := Round(FLegTicks * RollShare(TurnShareLeast, TurnShareMost));
  if (ALeg <> slBack) and (Roll < StallOdds) then
    FStallAt := Round(FLegTicks * RollShare(StallShareLeast, StallShareMost));
end;

// Along the row of the point from the left or the right, down its column
// from the top
procedure TStrayCycle.FlyIn;
var
  PointX, PointY: Double;
begin
  PickPoint(PointX, PointY);
  var Edge := TStrayEdge(Trunc(Roll * (Ord(High(TStrayEdge)) + 1)));
  case Edge of
    seLeft:
      begin
        FLeft := -FWidth - OutsideMargin;
        FTop := PointY;
      end;
    seRight:
      begin
        FLeft := ScreenWidth + OutsideMargin;
        FTop := PointY;
      end;
    seTop:
      begin
        FLeft := PointX;
        FTop := -2 * TileSize;
      end;
  end;
  StartLeg(slIn, PointX, PointY);
end;

procedure TStrayCycle.FlyOn;
var
  PointX, PointY: Double;
begin
  PickOtherPoint(PointX, PointY);
  StartLeg(slOn, PointX, PointY);
end;

procedure TStrayCycle.FlyOut;
begin
  var Edge := TStrayEdge(Trunc(Roll * (Ord(High(TStrayEdge)) + 1)));
  case Edge of
    seLeft:
      StartLeg(slOut, -FWidth - OutsideMargin, FTop);
    seRight:
      StartLeg(slOut, ScreenWidth + OutsideMargin, FTop);
    seTop:
      StartLeg(slOut, FLeft, -2 * TileSize);
  end;
end;

// Sent away: out along its row beyond the nearer side
procedure TStrayCycle.FlyAway;
begin
  if FLeft + FWidth / 2 < ScreenWidth / 2 then
    StartLeg(slOut, -FWidth - OutsideMargin, FTop)
  else
    StartLeg(slOut, ScreenWidth + OutsideMargin, FTop);
end;

procedure TStrayCycle.Dismiss;
begin
  if FDismissed or (FPhase = spAsleep) then
    Exit;
  FDismissed := True;
  FTwitchyHang := False;
  case FPhase of
    spWaiting:
      FPhase := spAsleep;
    spFlying:
      begin
        FTurnAt := NoMoment;
        FStallAt := NoMoment;
        FStallLeft := 0;
      end;
  end;
end;

// Back to where the leg began - the point it last hung at
procedure TStrayCycle.TurnBack;
begin
  StartLeg(slBack, FFromX, FFromY);
end;

procedure TStrayCycle.Hang;
begin
  FPhase := spHanging;
  FTicksLeft := RollTicks(HangSpan);
  FTwitchyHang := not FDismissed and (Roll < TwitchyOdds);
end;

// As a pad that plunges under the hero, from where it hangs
procedure TStrayCycle.Give;
var
  Plunge: TPadPlunge;
begin
  Plunge := Default(TPadPlunge);
  Plunge.Plunges := True;
  Plunge.Delay := GivingSeconds;
  Plunge.Rise := 1;
  var Seed := Cardinal(Trunc(Roll * MaxInt));
  FFall.Rewind(Plunge, ScreenHeight + FallDepth - FTop, Seed);
  FFall.Tread;
  FPhase := spGiving;
end;

// A pad sent away waits for nothing: out of sight it is asleep for good
procedure TStrayCycle.GoWait(const ASpan: TTickSpan);
begin
  FPhase := spWaiting;
  if FDismissed then
    FPhase := spAsleep
  else
    FTicksLeft := RollTicks(ASpan);
  FLeft := FWaitLeft;
  FTop := FWaitTop;
  FFall := Default(TPlungeCycle);
  FStallLeft := 0;
end;

procedure TStrayCycle.LeaveHang(ALoaded: Boolean);
begin
  if Roll < FallOdds then
    Give
  else if not ALoaded and (Roll < OutOdds) then
    FlyOut
  else
    FlyOn;
end;

procedure TStrayCycle.TickLeg(ALoaded: Boolean);
begin
  if FStallLeft > 0 then
  begin
    Dec(FStallLeft);
    Exit;
  end;
  if FLegClock = FStallAt then
  begin
    FStallAt := NoMoment;
    FStallLeft := RollTicks(StallSpan);
    Exit;
  end;
  var KeepsRider := (FLeg = slOut) and ALoaded;
  if KeepsRider or (FLegClock = FTurnAt) then
  begin
    TurnBack;
    Exit;
  end;

  Inc(FLegClock);
  var Share := Smoothstep(FLegClock / FLegTicks);
  FLeft := FFromX + (FToX - FFromX) * Share;
  FTop := FFromY + (FToY - FFromY) * Share;
  if FLegClock < FLegTicks then
    Exit;
  if FLeg = slOut then
    GoWait(ReturnSpan)
  else
    Hang;
end;

// Sent away, it leaves the hang at once - once the hero is off it
procedure TStrayCycle.TickHang(ALoaded: Boolean);
begin
  if FDismissed then
  begin
    if not ALoaded then
      FlyAway;
    Exit;
  end;
  Dec(FTicksLeft);
  if FTicksLeft <= 0 then
    LeaveHang(ALoaded);
end;

procedure TStrayCycle.TickFall;
begin
  FFall.Tick;
  case FFall.Phase of
    ppFalling:
      FPhase := spFalling;
    ppFallen, ppClimbing:
      GoWait(ReturnSpan);
  end;
end;

function TStrayCycle.Twitching: Boolean;
begin
  var HangsTwitchy := (FPhase = spHanging) and FTwitchyHang;
  Result := HangsTwitchy or (FStallLeft > 0);
end;

// Down always, round either way, as a failing pad twitches; the springs
// swing on when the kicks stop
procedure TStrayCycle.TickTwitch;
begin
  FDip.Tick;
  FLean.Tick;
  if not Twitching then
    Exit;
  Dec(FTwitchIn);
  if FTwitchIn > 0 then
    Exit;
  FTwitchIn := RollTicks(TwitchSpan);
  FDip.Kick(DipKick * RollShare(KickFloor, 1));
  var Way: Double := 1;
  if Roll < 0.5 then
    Way := -1;
  FLean.Kick(Way * LeanKick * RollShare(KickFloor, 1));
end;

procedure TStrayCycle.Tick(ALoaded: Boolean);
begin
  case FPhase of
    spWaiting:
      begin
        Dec(FTicksLeft);
        if FTicksLeft <= 0 then
          FlyIn;
      end;
    spFlying:
      TickLeg(ALoaded);
    spHanging:
      TickHang(ALoaded);
    spGiving, spFalling:
      TickFall;
  end;
  TickTwitch;
end;

function TStrayCycle.Dip: Double;
begin
  Result := FDip.Value + FFall.Dip;
end;

function TStrayCycle.Lean: Double;
begin
  Result := FLean.Value + FFall.Lean;
end;

function TStrayCycle.GetTop: Double;
begin
  Result := FTop + FFall.Below;
end;

function TStrayCycle.Deck: Boolean;
begin
  if FPhase in [spAsleep, spWaiting] then
    Exit(False);
  var InsideAcross := (FLeft >= RoomInset) and
    (FLeft + FWidth <= ScreenWidth - RoomInset);
  Result := InsideAcross and (GetTop >= RoomInset);
end;

function TStrayCycle.Effort: Single;
begin
  case FPhase of
    spFlying:
      if FStallLeft > 0 then
        Result := 0
      else if FDismissed then
        Result := QuietEffort
      else
        Result := 1;
    spHanging:
      if FTwitchyHang then
        Result := TwitchyEffort
      else
        Result := 0;
    spGiving, spFalling:
      Result := FFall.Effort;
  else
    Result := 0;
  end;
end;

end.
