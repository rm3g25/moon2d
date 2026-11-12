{
  Game.Dive - the Ram's dive: on the last rung of the air fight it drops
  like a stone.

  Begun where it hangs, it gives all but no warning: its eye flashes, its
  jets go out and for half a second it only sags in the silence. Then it
  falls straight down, ever faster, to the floor the caller gives - just
  over the head of a hero standing on the main barge - and stops there
  hard. A few ticks on its jets catch again, hot: the window. It stays
  low, riding the floor as the caller moves it, while they cool; then it
  climbs straight up to its height and is let go to hang.

  The finisher's dive comes out of the sky: begun over the top edge, out of
  sight and its jets already out, a red band blinks at the top edge over
  the place it will strike, the length of its hull; then it falls from
  there as from its hang.

  The floor is the caller's, told every tick. The height and the lean are
  this unit's; the caller flies the hull by them, and puts its jets out
  and lights them again by its cues. While it falls a hero it meets is
  struck; while it is low - the fall and the hold - whatever small barge
  it meets is the caller's to smash; while its jets burn hot the fire
  under them burns. No drawing, no hull, no barges.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.Dive;
{$I ..\Moon2D.inc}

interface

const
  // The silence: its jets out, it sags this far over this long and keeps
  // this share of its way across a tick
  DiveHushTicks = 16;
  DiveSag = 4.0;
  DivePaceKeep = 0.7;
  // Units a tick gained every tick of the fall: from its height to the
  // main barge's in about half a second
  DiveGravity = 1.0;
  // Low: the jets catch this long after it stops, then burn hot this long
  // - the window - while it rides the floor this share of the way a tick
  DiveRelightTicks = 5;
  DiveHoldTicks = 99;
  DiveFollow = 0.3;
  // Up to its height and level again
  DiveRiseTicks = 50;
  // From over the top edge: the band blinks this long before the fall
  DiveMarkTicks = 20;

type
  // dvNone - not diving; dvMarking - over the top edge, the band blinking
  // over where it will strike; dvHush - its jets out, sagging; dvFalling -
  // like a stone; dvHolding - low, its jets catching again and cooling;
  // dvRising - up to its height
  TDiveStage = (dvNone, dvMarking, dvHush, dvFalling, dvHolding, dvRising);

  TDiveCue = record
    // Over the top edge, the band blinks over where it will strike
    Marks: Boolean;
    // Its eye flashes and its jets go out
    Hushes: Boolean;
    // It falls
    Drops: Boolean;
    // It strikes its floor
    Lands: Boolean;
    // Its jets catch again, hot
    Relights: Boolean;
    // Up at its height: to be let go to hang
    Done: Boolean;
  end;

  TDive = class
  private
    FStage: TDiveStage;
    FTicks: Integer;
    FLift, FLastLift: Single;
    // Where the silence sags from, and later where the rise starts
    FFrom: Single;
    FPace: Single;
    FBow: Single;
    // Units a tick down while it falls
    FSpeed: Single;
    FHeat, FLastHeat: Single;
    FMark, FLastMark: Single;
    procedure TickMarking(var ACue: TDiveCue);
    procedure TickHush(var ACue: TDiveCue);
    procedure TickFalling(AFloor: Single; var ACue: TDiveCue);
    procedure TickHolding(AFloor: Single; var ACue: TDiveCue);
    procedure TickRising(var ACue: TDiveCue);
    procedure Enter(AStage: TDiveStage);
  public
    constructor Create;
    // A death, a new fight: not diving
    procedure Clear;
    // From where it hangs: going APace units a tick across, ALift over the
    // road, its bow ABow degrees down. Nothing while it dives.
    procedure Start(APace, ALift, ABow: Single);
    // Over the top edge, ALift over the road, level and still, its jets out:
    // the band, then the fall. Nothing while it dives.
    procedure StartAbove(ALift: Single);
    // AFloor - the lift it is to stop at this tick, units over the road
    function Tick(AFloor: Single): TDiveCue;
    function Running: Boolean;
    property Stage: TDiveStage read FStage;
    // Where it is to be this tick: units over the road, units a tick across,
    // degrees its bow is down
    property Lift: Single read FLift;
    property Pace: Single read FPace;
    property Bow: Single read FBow;
    // Units it went down this tick
    function Fall: Single;
    // The silence before the fall: its eye flashes
    function Flashes: Boolean;
    // Falling: a hero it meets is struck
    function Slams: Boolean;
    // Falling or low: a small barge it meets is smashed
    function RunsLow: Boolean;
    // Its jets burn hot again: an orb that meets a nozzle takes a life of
    // the hull, and their fire burns
    function Soft: Boolean;
    // From the silence till it is up again: no small barge comes in
    function HoldsFlock: Boolean;
    // AAlpha of the way from the last tick to this one: 0 cold to 1 hot;
    // the band's light over where it will strike, 0 none to 1
    function HeatAt(AAlpha: Single): Single;
    function MarkAt(AAlpha: Single): Single;
  end;

implementation

uses
  System.Math, Game.Takeoff;

const
  // Each tick the bow goes this share of the way to level
  BowLearn = 0.2;
  // The band blinks once in this long, brighter as it comes
  MarkBlinkTicks = 8;
  MarkFirstLevel = 0.5;

function Lerp(AFrom, ATo, AAmount: Single): Single;
begin
  Result := AFrom + (ATo - AFrom) * AAmount;
end;

function SmoothStep(AShare: Single): Single;
begin
  var Share := EnsureRange(AShare, 0.0, 1.0);
  Result := Share * Share * (3 - 2 * Share);
end;

constructor TDive.Create;
begin
  inherited Create;
  Clear;
end;

procedure TDive.Clear;
begin
  FStage := dvNone;
  FTicks := 0;
  FLift := 0;
  FLastLift := 0;
  FFrom := 0;
  FPace := 0;
  FBow := 0;
  FSpeed := 0;
  FHeat := 0;
  FLastHeat := 0;
  FMark := 0;
  FLastMark := 0;
end;

procedure TDive.Start(APace, ALift, ABow: Single);
begin
  if Running then
    Exit;
  Clear;
  FPace := APace;
  FLift := ALift;
  FLastLift := ALift;
  FFrom := ALift;
  FBow := ABow;
  Enter(dvHush);
end;

procedure TDive.StartAbove(ALift: Single);
begin
  if Running then
    Exit;
  Clear;
  FLift := ALift;
  FLastLift := ALift;
  FFrom := ALift;
  Enter(dvMarking);
end;

function TDive.Running: Boolean;
begin
  Result := FStage <> dvNone;
end;

procedure TDive.Enter(AStage: TDiveStage);
begin
  FStage := AStage;
  FTicks := 0;
end;

function TDive.Tick(AFloor: Single): TDiveCue;
begin
  Result := Default(TDiveCue);
  if FStage = dvNone then
    Exit;
  FLastLift := FLift;
  FLastHeat := FHeat;
  FLastMark := FMark;
  Inc(FTicks);
  FBow := FBow - BowLearn * FBow;
  case FStage of
    dvMarking:
      TickMarking(Result);
    dvHush:
      TickHush(Result);
    dvFalling:
      TickFalling(AFloor, Result);
    dvHolding:
      TickHolding(AFloor, Result);
    dvRising:
      TickRising(Result);
  end;
end;

// Out of sight, still: the band blinks, brighter as the fall comes; then
// it falls from a standstill
procedure TDive.TickMarking(var ACue: TDiveCue);
begin
  ACue.Marks := FTicks = 1;
  var Share: Single := FTicks / DiveMarkTicks;
  var Blink := 0.5 + 0.5 * Cos(2 * Pi * FTicks / MarkBlinkTicks);
  FMark := Lerp(MarkFirstLevel, 1, Share) * Sqr(Blink);
  if FTicks < DiveMarkTicks then
    Exit;
  FMark := 0;
  FSpeed := 0;
  Enter(dvFalling);
  ACue.Drops := True;
end;

// Its way across dies out and it sags, the sag growing as a fall does,
// so the fall goes on from it at the pace it reached
procedure TDive.TickHush(var ACue: TDiveCue);
begin
  ACue.Hushes := FTicks = 1;
  FPace := FPace * DivePaceKeep;
  FLift := FFrom - DiveSag * Sqr(FTicks / DiveHushTicks);
  if FTicks < DiveHushTicks then
    Exit;
  FPace := 0;
  FSpeed := 2 * DiveSag / DiveHushTicks;
  Enter(dvFalling);
  ACue.Drops := True;
end;

procedure TDive.TickFalling(AFloor: Single; var ACue: TDiveCue);
begin
  FSpeed := FSpeed + DiveGravity;
  FLift := FLift - FSpeed;
  if FLift > AFloor then
    Exit;
  FLift := AFloor;
  Enter(dvHolding);
  ACue.Lands := True;
end;

// The fade is the window's clock: cold as it rises
procedure TDive.TickHolding(AFloor: Single; var ACue: TDiveCue);
begin
  FLift := FLift + DiveFollow * (AFloor - FLift);
  if FTicks < DiveRelightTicks then
    Exit;
  if FTicks = DiveRelightTicks then
    ACue.Relights := True;
  var Burnt := FTicks - DiveRelightTicks;
  FHeat := Max(1 - Burnt / DiveHoldTicks, 0);
  if Burnt < DiveHoldTicks then
    Exit;
  FHeat := 0;
  FFrom := FLift;
  Enter(dvRising);
end;

procedure TDive.TickRising(var ACue: TDiveCue);
begin
  FLift := Lerp(FFrom, HangLift, SmoothStep(FTicks / DiveRiseTicks));
  if FTicks < DiveRiseTicks then
    Exit;
  FLift := HangLift;
  FBow := 0;
  Enter(dvNone);
  ACue.Done := True;
end;

function TDive.Fall: Single;
begin
  Result := FLastLift - FLift;
end;

function TDive.Flashes: Boolean;
begin
  Result := FStage = dvHush;
end;

function TDive.Slams: Boolean;
begin
  Result := FStage = dvFalling;
end;

function TDive.RunsLow: Boolean;
begin
  Result := FStage in [dvFalling, dvHolding];
end;

function TDive.Soft: Boolean;
begin
  Result := (FStage = dvHolding) and (FTicks >= DiveRelightTicks);
end;

function TDive.HoldsFlock: Boolean;
begin
  Result := Running;
end;

function TDive.HeatAt(AAlpha: Single): Single;
begin
  Result := Lerp(FLastHeat, FHeat, AAlpha);
end;

function TDive.MarkAt(AAlpha: Single): Single;
begin
  Result := Lerp(FLastMark, FMark, AAlpha);
end;

end.
