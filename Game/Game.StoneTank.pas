{
  Game.StoneTank - the hidden tank between the Ram's heads and the gauge
  of the form's charge. The charge grows with the fight, but the player
  must not read a hit in it: a wound to a head goes into the tank, not
  into the gauge, and reaches the tank only a while later; the gauge
  drinks from it on a clock of its own, a percent or two at a time in
  uneven pulses. A weak trickle keeps the gauge alive between the bursts.

  Each head has its ceiling - the gauge stops there while it lives - and
  its death pours the whole of what is left up to that ceiling, late as
  any wound: what was still on its way goes into that one pour, and
  nothing of one head spills over into the next head's quarter.
  What its whole lives bring is a little less than the way to its
  ceiling: the trickle and the death make up the rest.

  It does not know the Ram or the gauge: the game tells it the wounds and
  the deaths and gives the hero what a tick says. It does not touch SDL.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.StoneTank;
{$I ..\Moon2D.inc}

interface

uses
  Render.Brush;

const
  // A wound reaches the tank this many ticks after it is dealt
  LateTicks = 50;

type
  TStoneTank = class
  private
    FRunning: Boolean;
    FHeadsDown: Integer;
    // The wounds on their way, a slot a tick; FLateAt the oldest
    FLate: array [0..LateTicks - 1] of Single;
    FLateAt: Integer;
    FTank: Single;
    FPulseTicks: Integer;
    FDice: TXorShift;
    function NewestSlot: Integer;
    procedure EmptyTheWay;
    function NextGap: Integer;
  public
    constructor Create(ASeed: Cardinal);
    // The fight is on: the trickle runs and the gauge drinks
    procedure Start;
    // A death, a door, a new level: nothing on its way, no head down,
    // stopped
    procedure Clear;
    // A head lost AShare of its full lives
    procedure Wound(AShare: Single);
    // A head is dead: what is left from AEnergy up to its ceiling is
    // poured in late, in place of all that was on its way, and the next
    // head's ceiling stands from now on
    procedure HeadDown(AEnergy: Integer);
    // The charge to add to AEnergy this tick, in percent
    function Tick(AEnergy: Integer): Integer;
    // Where the gauge stops while the current head lives
    function Ceiling: Integer;
    property Running: Boolean read FRunning;
  end;

implementation

uses
  System.Math;

const
  // The gauge stops here while the head of this many down lives. The
  // charge comes by heads: a quarter the hunter, a quarter the sweeper.
  // TODO: 95 for the bunker, 100 on its death (tracked: arena-3.md,
  // stage 15b)
  Ceilings: array [0..1] of Integer = (30, 55);
  // What a head's whole lives pour in, percent: a little short of its
  // quarter, so the trickle and the death have something to bring
  HeadShare = 20.0;
  // Percent a tick: about 0.1% a second
  TricklePerTick = 0.1 / 33;
  // A pulse every so many ticks, the gap rolled anew each time
  PulseGapLeast = 8;
  PulseGapSpan = 22;
  // A pulse takes two now and then, when the tank holds them
  DoublePulseShare = 0.3;

constructor TStoneTank.Create(ASeed: Cardinal);
begin
  inherited Create;
  FDice.Seed := ASeed;
  Clear;
end;

procedure TStoneTank.Start;
begin
  if FRunning then
    Exit;
  FRunning := True;
  FPulseTicks := NextGap;
end;

procedure TStoneTank.Clear;
begin
  FRunning := False;
  FHeadsDown := 0;
  EmptyTheWay;
  FLateAt := 0;
  FPulseTicks := 0;
end;

procedure TStoneTank.EmptyTheWay;
begin
  for var i := 0 to High(FLate) do
    FLate[i] := 0;
  FTank := 0;
end;

// The slot read last: it comes round again in LateTicks ticks
function TStoneTank.NewestSlot: Integer;
begin
  Result := (FLateAt + LateTicks - 1) mod LateTicks;
end;

function TStoneTank.NextGap: Integer;
begin
  Result := PulseGapLeast + Trunc(FDice.NextUnit * (PulseGapSpan + 1));
end;

procedure TStoneTank.Wound(AShare: Single);
begin
  if not FRunning or (AShare <= 0) then
    Exit;
  var Slot := NewestSlot;
  FLate[Slot] := FLate[Slot] + AShare * HeadShare;
end;

procedure TStoneTank.HeadDown(AEnergy: Integer);
begin
  if not FRunning then
    Exit;
  EmptyTheWay;
  FLate[NewestSlot] := Max(0, Ceiling - AEnergy);
  Inc(FHeadsDown);
end;

function TStoneTank.Ceiling: Integer;
begin
  Result := Ceilings[Min(FHeadsDown, High(Ceilings))];
end;

function TStoneTank.Tick(AEnergy: Integer): Integer;
begin
  Result := 0;
  if not FRunning then
    Exit;
  FTank := FTank + FLate[FLateAt] + TricklePerTick;
  FLate[FLateAt] := 0;
  FLateAt := (FLateAt + 1) mod LateTicks;
  // What stands at the ceiling is spilt: it must not flood the gauge the
  // moment the next head lifts it
  var Room: Single := Max(0, Ceiling - AEnergy);
  FTank := Min(FTank, Room);

  Dec(FPulseTicks);
  if FPulseTicks > 0 then
    Exit;
  FPulseTicks := NextGap;
  var Step := 1;
  if (FTank >= 2) and (FDice.NextUnit < DoublePulseShare) then
    Step := 2;
  if FTank < Step then
    Exit;
  FTank := FTank - Step;
  Result := Step;
end;

end.
