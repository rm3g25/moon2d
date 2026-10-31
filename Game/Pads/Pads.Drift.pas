{
  Pads.Drift - the pads of a chase. As the road runs, pads are sent in
  from beyond the right edge to ride it left; past the left edge
  Pads.World lets them go, back into the pool.

  They come in groups along the road, an empty stretch between two. A
  group is a lone pad - at any height, any width, a step off the road or
  a pad nobody can reach - or a climb: a pad the plain jump from the road
  reaches, then pads each a jump higher and a short gap across, until one
  stands where a shot down reaches the bunker's hatch. A climb rises
  toward the machine or away from it. The dice give every number of
  every group: no two climbs alike, and a lone pad looks like the foot of
  a climb until the next pad comes in. So the player looks for a way up.

  A guard keeps him from waiting too long: when no climb has ended for
  GuardUnits of road, the next group is a climb - one of the dice's like
  any other, nothing to tell it by. A new group comes only when the screen
  has room for all of it: never more than MostAdrift pads sent at once,
  and a climb is never cut.

  The pads come from the pool of the screen: the pads that drift in the
  level file, asleep until sent. A pool smaller than MostAdrift raises at
  load, and so does a pad of it neither of the two widths. A width the
  pool has run out of is made up with the other.

  It does not know the belt, the hero or the bunker: the game tells it how
  far the road has run, while the road runs.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Pads.Drift;
{$I ..\..\Moon2D.inc}

interface

uses
  Render.Brush, Pads.World;

const
  // The pool's two pictures
  StepWidth = 32;
  HighWidth = 64;
  // A lone pad stands anywhere between these decks
  HighestDeck = 120;
  LowestDeck = 288;
  // A climb starts within the plain jump from the road (352) and goes up
  // a jump a step until a shot down from it reaches the hatch
  ClimbFootHighest = 272;
  WayUpDeck = 144;
  ClimbStepLeast = 48;
  ClimbStepMost = 80;
  // Across between two pads of a climb, edge to edge
  ClimbGapLeast = 16;
  ClimbGapMost = 40;
  // The empty road after a group: wider than any gap of a climb, so two
  // groups never make one
  GroupGapLeast = 48;
  GroupGapMost = 112;
  LongShare = 0.3;
  ClimbShare = 0.6;
  // A climb that rises away from the machine: its top comes in first, and
  // the hero goes up it the way the road goes
  AwayShare = 0.5;
  // No climb ended for 6 s of road at cruise: the next group is one
  GuardUnits = 198;
  MostAdrift = 10;

type
  // A pad of a group as planned: its width, its deck, the road after it
  TDriftStep = record
    Width: Integer;
    Deck: Integer;
    GapAfter: Integer;
  end;

  TPadDrift = class
  private
    FWorld: TPadWorld;
    FDice: TXorShift;
    // Where on the road the next pad's left edge goes: the road's run plus
    // its place on the screen
    FCursor: Double;
    // Where the last climb ended: the right edge of its last pad
    FClimbEnd: Double;
    // The rest of the group under way, whether it is a climb, and whether
    // it still waits for room on the screen
    FPlan: TArray<TDriftStep>;
    FPlanClimbs: Boolean;
    FGroupWaits: Boolean;
    function RollRange(ALeast, AMost: Integer): Integer;
    function RollWidth: Integer;
    function PlanLone: TArray<TDriftStep>;
    function PlanClimb: TArray<TDriftStep>;
    procedure PlanGroup;
    function AdriftOn(AScreen: Integer): Integer;
    function TakeDrifter(AScreen, AWidth: Integer): TPad;
    procedure SendStep(AScreen: Integer; ATravel: Double);
  public
    // AWorld must outlive the dispatcher; ALevelId names the level in the
    // errors of its pools; ASeed - the dice of the groups
    constructor Create(const AWorld: TPadWorld; const ALevelId: string;
      ASeed: Cardinal);
    // A death, a door, a new level: nothing sent, the pools asleep, the
    // dice new for the new try
    procedure Clear(ASeed: Cardinal);
    // The road has run ATravel units since its start: every pad due by now
    // is sent on AScreen, beyond the right edge
    procedure Tick(AScreen: Integer; ATravel: Double);
  end;

implementation

uses
  System.SysUtils, System.Math, Game.Space, Levels.Pads;

resourcestring
  SDriftBadWidth = 'Level "%s": %s drifts and is %d units wide - %d or %d';
  SDriftPoolShort = 'Level "%s": the pool of screen %d holds %d pads - the '
    + 'chase takes %d';

constructor TPadDrift.Create(const AWorld: TPadWorld; const ALevelId: string;
  ASeed: Cardinal);
begin
  inherited Create;
  FWorld := AWorld;
  for var Pad in FWorld.Drifters do
  begin
    var Width := Pad.Placement.Width;
    if (Width <> StepWidth) and (Width <> HighWidth) then
      raise EPadError.CreateFmt(SDriftBadWidth, [ALevelId,
        PadRigName(Pad.Placement), Width, StepWidth, HighWidth]);
    var Pool := 0;
    for var Other in FWorld.Drifters do
      if Other.Screen = Pad.Screen then
        Inc(Pool);
    if Pool < MostAdrift then
      raise EPadError.CreateFmt(SDriftPoolShort,
        [ALevelId, Pad.Screen, Pool, MostAdrift]);
  end;
  Clear(ASeed);
end;

procedure TPadDrift.Clear(ASeed: Cardinal);
begin
  FCursor := 0;
  // The chase opens with a climb
  FClimbEnd := -GuardUnits - 1;
  FPlan := [];
  FPlanClimbs := False;
  FGroupWaits := False;
  // An xorshift seeded with zero stays at zero
  FDice.Seed := ASeed or 1;
  FWorld.LetGoDrifters;
end;

function TPadDrift.RollRange(ALeast, AMost: Integer): Integer;
begin
  Result := ALeast + Min(Trunc(FDice.NextUnit * (AMost - ALeast + 1)),
    AMost - ALeast);
end;

function TPadDrift.RollWidth: Integer;
begin
  Result := StepWidth;
  if FDice.NextUnit < LongShare then
    Result := HighWidth;
end;

function TPadDrift.PlanLone: TArray<TDriftStep>;
var
  Step: TDriftStep;
begin
  Step.Width := RollWidth;
  Step.Deck := RollRange(HighestDeck, LowestDeck);
  Step.GapAfter := RollRange(GroupGapLeast, GroupGapMost);
  Result := [Step];
end;

// Planned from the foot up; one that rises away from the machine is the
// same climb read from the top, its gaps the other way round too
function TPadDrift.PlanClimb: TArray<TDriftStep>;
var
  Step: TDriftStep;
begin
  Result := [];
  var Deck := RollRange(ClimbFootHighest, LowestDeck);
  repeat
    Step.Width := RollWidth;
    Step.Deck := Deck;
    Step.GapAfter := RollRange(ClimbGapLeast, ClimbGapMost);
    Result := Result + [Step];
    Deck := Max(HighestDeck, Deck - RollRange(ClimbStepLeast, ClimbStepMost));
  until Step.Deck <= WayUpDeck;

  if FDice.NextUnit < AwayShare then
  begin
    var Gaps: TArray<Integer> := [];
    for var i := 0 to High(Result) do
      Gaps := Gaps + [Result[i].GapAfter];
    for var i := 0 to Length(Result) div 2 - 1 do
    begin
      var Swapped := Result[i];
      Result[i] := Result[High(Result) - i];
      Result[High(Result) - i] := Swapped;
    end;
    for var i := 0 to High(Result) - 1 do
      Result[i].GapAfter := Gaps[High(Result) - 1 - i];
  end;
  Result[High(Result)].GapAfter := RollRange(GroupGapLeast, GroupGapMost);
end;

procedure TPadDrift.PlanGroup;
begin
  var Waited := FCursor - FClimbEnd > GuardUnits;
  FPlanClimbs := Waited or (FDice.NextUnit < ClimbShare);
  if FPlanClimbs then
    FPlan := PlanClimb
  else
    FPlan := PlanLone;
end;

function TPadDrift.AdriftOn(AScreen: Integer): Integer;
begin
  Result := 0;
  for var Pad in FWorld.Drifters do
    if (Pad.Screen = AScreen) and not Pad.Dormant then
      Inc(Result);
end;

function TPadDrift.TakeDrifter(AScreen, AWidth: Integer): TPad;
begin
  Result := FWorld.FreeDrifter(AScreen, AWidth);
  if Result <> nil then
    Exit;
  var OtherWidth := HighWidth;
  if AWidth = HighWidth then
    OtherWidth := StepWidth;
  Result := FWorld.FreeDrifter(AScreen, OtherWidth);
end;

// The pool is checked at load: a screen with none is a road with no pads,
// and the road goes on as if they were there
procedure TPadDrift.SendStep(AScreen: Integer; ATravel: Double);
begin
  var Step := FPlan[0];
  Delete(FPlan, 0, 1);
  var Width := Step.Width;
  var Pad := TakeDrifter(AScreen, Step.Width);
  if Pad <> nil then
  begin
    Width := Pad.Placement.Width;
    Pad.SetAdrift(FCursor - ATravel, Step.Deck);
  end;
  FCursor := FCursor + Width;
  if FPlanClimbs and (Length(FPlan) = 0) then
    FClimbEnd := FCursor;
  FCursor := FCursor + Step.GapAfter;
end;

procedure TPadDrift.Tick(AScreen: Integer; ATravel: Double);
begin
  repeat
    if Length(FPlan) = 0 then
    begin
      PlanGroup;
      FGroupWaits := True;
    end;
    if FGroupWaits then
    begin
      if AdriftOn(AScreen) + Length(FPlan) > MostAdrift then
        Exit;
      // The road the group waited out is empty road: it comes in at the
      // edge, not inside the screen
      FCursor := Max(FCursor, ATravel + ScreenWidth);
      FGroupWaits := False;
    end;
    if FCursor - ATravel > ScreenWidth then
      Exit;
    SendStep(AScreen, ATravel);
  until False;
end;

end.
