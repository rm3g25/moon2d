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

  One climb in MedkitClimbs carries a medkit, which one of them the dice's:
  on its middle pad by height, of the pads between the foot and the top
  the one nearest halfway. The dispatcher does not know the monsters - it
  tells the game where a medkit is to stand, and the game stands it.

  A guard keeps him from waiting too long: when no climb has ended for
  GuardUnits of road, the next group is a climb - one of the dice's like
  any other, nothing to tell it by. A new group comes only when the screen
  has room for all of it: never more than MostAdrift pads sent at once,
  and a climb is never cut.

  The pads come from the pool of the screen: the pads that drift in the
  level file, asleep until sent. A pool smaller than MostAdrift raises at
  load, and so does a pad of it neither of the two widths. A width the
  pool has run out of is made up with the other.

  The hunt of the bunker's last third sends a wave over the road, for the
  hero to jump the machine as it drives through him: told to, it lays
  three rows of pads, each at its deck, dense - the gaps narrower than the
  hero - over the whole screen and more, at the decks of a climb. They fly
  in at once, each row from its own side - from beyond the right edge,
  from beyond the left one, from above - and come to the road's pace; a
  slot where a pad already rides is left to that pad. The cue tells when they have flown
  in. Then the wave rides off as any pad does, and the groups come again
  right after it, a little denser than before - the guard shorter, more
  climbs among them. The wave is not counted among the pads adrift: the
  groups do not wait for it to leave.

  It does not know the belt, the hero, the bunker or the monsters: the
  game tells it how far the road has run, while the road runs, and hears
  back where the medkits go.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Pads.Drift;
{$I ..\..\Moon2D.inc}

interface

uses
  Sdl2.Core, Render.Brush, Pads.World;

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
  // After the wave of the hunt: 4 s, and more climbs
  HuntGuardUnits = 132;
  HuntClimbShare = 0.7;
  // Of every three climbs one carries a medkit
  MedkitClimbs = 3;
  // The rows of the wave at the decks of a climb: the foot a plain jump
  // from the road, each a climb's step over the last, the top where a shot
  // down reaches the hatch; the middle one clear of the top of the bunker
  // (about 204)
  RowCount = 3;
  RowDecks: array [0..RowCount - 1] of Integer = (ClimbFootHighest, 192,
    WayUpDeck);
  // Edge to edge along a row: narrower than his body (16)
  RowGapLeast = 4;
  RowGapMost = 12;
  // Two decks nearer than a cell: their pictures meet
  RowsApart = 32;
  // The wave: from the left edge to this far past the right one - more
  // than the road rides while it flies in and the machine drives through -
  // flying in over this long, each row from its own side, from this far off
  // its place: the foot from beyond the right edge, the middle from beyond
  // the left one - the whole stretch of it, the screen, RowsBeyond and a
  // long pad - the top from above
  RowsBeyond = 128;
  RowsComeTicks = 120;
  RowsComeFrom: array [0..RowCount - 1] of TSdlFPoint = ((X: 560; Y: 0),
    (X: -720; Y: 0), (X: 0; Y: -200));

type
  // A pad of a group as planned: its width, its deck, the road after it,
  // whether a medkit stands on it
  TDriftStep = record
    Width: Integer;
    Deck: Integer;
    GapAfter: Integer;
    Medkit: Boolean;
  end;

  TDriftCue = record
    // Where the medkits stand from this tick: the middle of their feet, on
    // the deck of a pad just sent
    Medkits: TArray<TSdlFPoint>;
    // The wave has flown in and rides the road
    RowsIn: Boolean;
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
    // The climbs planned in the current round of MedkitClimbs, and which of
    // the round carries the medkit
    FClimbsThisRound: Integer;
    FMedkitClimb: Integer;
    // The wave: ticks left of its flight, and its pads still riding
    FRowsComing: Integer;
    FWave: TArray<TPad>;
    // Since the wave: the guard shorter, more climbs
    FDense: Boolean;
    function RollRange(ALeast, AMost: Integer): Integer;
    function RollWidth: Integer;
    function PlanLone: TArray<TDriftStep>;
    function PlanClimb: TArray<TDriftStep>;
    procedure PlanGroup;
    function AdriftOn(AScreen: Integer): Integer;
    function TakeDrifter(AScreen, AWidth: Integer): TPad;
    procedure SendStep(AScreen: Integer; ATravel: Double;
      var ACue: TDriftCue);
    function RollRowGap: Integer;
    function TakeRowPad(AScreen: Integer; var AWidth: Integer): TPad;
    function LayComingRow(AScreen, ARow: Integer;
      const ARiding: TArray<TPad>): Double;
  public
    // AWorld must outlive the dispatcher; ALevelId names the level in the
    // errors of its pools; ASeed - the dice of the groups
    constructor Create(const AWorld: TPadWorld; const ALevelId: string;
      ASeed: Cardinal);
    // A death, a door, a new level: nothing sent, the pools asleep, the
    // dice new for the new try
    procedure Clear(ASeed: Cardinal);
    // The road has run ATravel units since its start: every pad due by now
    // is sent on AScreen, beyond the right edge, and the cue tells where
    // the medkits on them stand
    function Tick(AScreen: Integer; ATravel: Double): TDriftCue;
    // The road has run ATravel: the wave flies in over AScreen now, the
    // groups wait till it is in and come after it, denser
    procedure BeginRows(AScreen: Integer; ATravel: Double);
    // The groups as after the wave, denser, with no wave: a restart past
    // the bunker's death
    procedure BeginAfterWave;
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
  FClimbsThisRound := 0;
  FMedkitClimb := 0;
  FRowsComing := 0;
  FWave := [];
  FDense := False;
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
  Step := Default(TDriftStep);
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
  Step := Default(TDriftStep);
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

// Nearer halfway up the climb than AOther; as near, the lower of the two
function NearerHalfway(const AStep, AOther: TDriftStep;
  AHalfway: Double): Boolean;
begin
  var Off := Abs(AStep.Deck - AHalfway);
  var OtherOff := Abs(AOther.Deck - AHalfway);
  if Off <> OtherOff then
    Exit(Off < OtherOff);
  Result := AStep.Deck > AOther.Deck;
end;

// Of the pads between the foot and the top, the one nearest halfway
// between their decks
procedure PutMedkitMidway(var AClimb: TArray<TDriftStep>);
begin
  var Halfway := (AClimb[0].Deck + AClimb[High(AClimb)].Deck) / 2;
  var Middle := -1;
  for var i := 1 to High(AClimb) - 1 do
    if (Middle < 0) or NearerHalfway(AClimb[i], AClimb[Middle], Halfway) then
      Middle := i;
  if Middle >= 0 then
    AClimb[Middle].Medkit := True;
end;

procedure TPadDrift.PlanGroup;
begin
  var Guard := GuardUnits;
  var Share := ClimbShare;
  if FDense then
  begin
    Guard := HuntGuardUnits;
    Share := HuntClimbShare;
  end;
  var Waited := FCursor - FClimbEnd > Guard;
  FPlanClimbs := Waited or (FDice.NextUnit < Share);
  if not FPlanClimbs then
  begin
    FPlan := PlanLone;
    Exit;
  end;

  FPlan := PlanClimb;
  if FClimbsThisRound = 0 then
    FMedkitClimb := RollRange(0, MedkitClimbs - 1);
  if FClimbsThisRound = FMedkitClimb then
    PutMedkitMidway(FPlan);
  FClimbsThisRound := (FClimbsThisRound + 1) mod MedkitClimbs;
end;

// The wave's pads are not counted: a pad of it let go past the left edge
// is out of it, so the pool can send it again in a group
function TPadDrift.AdriftOn(AScreen: Integer): Integer;
begin
  var Riding: TArray<TPad> := [];
  for var Pad in FWave do
    if not Pad.Dormant then
      Riding := Riding + [Pad];
  FWave := Riding;

  Result := 0;
  for var Pad in FWorld.Drifters do
    if (Pad.Screen = AScreen) and not Pad.Dormant then
      Inc(Result);
  Result := Result - Length(FWave);
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
// and the road goes on as if they were there - with no medkit, nothing to
// stand it on
procedure TPadDrift.SendStep(AScreen: Integer; ATravel: Double;
  var ACue: TDriftCue);
begin
  var Step := FPlan[0];
  Delete(FPlan, 0, 1);
  var Width := Step.Width;
  var Pad := TakeDrifter(AScreen, Step.Width);
  if Pad <> nil then
  begin
    Width := Pad.Placement.Width;
    var Left := FCursor - ATravel;
    Pad.SetAdrift(Left, Step.Deck);
    if Step.Medkit then
    begin
      var Mark: TSdlFPoint;
      Mark.X := Left + Width / 2;
      Mark.Y := Step.Deck;
      ACue.Medkits := ACue.Medkits + [Mark];
    end;
  end;
  FCursor := FCursor + Width;
  if FPlanClimbs and (Length(FPlan) = 0) then
    FClimbEnd := FCursor;
  FCursor := FCursor + Step.GapAfter;
end;

function TPadDrift.Tick(AScreen: Integer; ATravel: Double): TDriftCue;
begin
  Result := Default(TDriftCue);
  if FRowsComing > 0 then
  begin
    Dec(FRowsComing);
    Result.RowsIn := FRowsComing = 0;
    Exit;
  end;
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
    SendStep(AScreen, ATravel, Result);
  until False;
end;

function TPadDrift.RollRowGap: Integer;
begin
  Result := RollRange(RowGapLeast, RowGapMost);
end;

// A pad AWidth wide, or of the other width, AWidth told which; nil when
// the pool has run out of both - a hole in the row. The pool is checked at
// load for the climbs, not for the wave.
function TPadDrift.TakeRowPad(AScreen: Integer; var AWidth: Integer): TPad;
begin
  Result := TakeDrifter(AScreen, AWidth);
  if Result <> nil then
    AWidth := Result.Placement.Width;
end;

// A slot of the wave a pad already rides on: across it, and near enough
// its deck for the two pictures to meet
function SlotTaken(const ARiding: TArray<TPad>; ALeft, ARight,
  ADeck: Double): Boolean;
begin
  for var Pad in ARiding do
    if (Pad.Left < ARight + RowGapLeast) and (Pad.Right > ALeft - RowGapLeast) and
      (Abs(Pad.Top - ADeck) < RowsApart) then
      Exit(True);
  Result := False;
end;

// From the left edge on past the right one; a slot a pad rides on is left
// to it. Where on the screen the row ends.
function TPadDrift.LayComingRow(AScreen, ARow: Integer;
  const ARiding: TArray<TPad>): Double;
begin
  var Left: Double := 0;
  while Left < ScreenWidth + RowsBeyond do
  begin
    var Width := RollWidth;
    var Pad: TPad := nil;
    if not SlotTaken(ARiding, Left, Left + Width, RowDecks[ARow]) then
      Pad := TakeRowPad(AScreen, Width);
    if Pad <> nil then
    begin
      Pad.SetAdriftComing(Left, RowDecks[ARow], RowsComeFrom[ARow],
        RowsComeTicks);
      FWave := FWave + [Pad];
    end;
    Left := Left + Width + RollRowGap;
  end;
  Result := Left;
end;

procedure TPadDrift.BeginAfterWave;
begin
  FDense := True;
end;

procedure TPadDrift.BeginRows(AScreen: Integer; ATravel: Double);
begin
  var Riding: TArray<TPad> := [];
  for var Pad in FWorld.Drifters do
    if (Pad.Screen = AScreen) and not Pad.Dormant then
      Riding := Riding + [Pad];

  FPlan := [];
  FGroupWaits := False;
  FRowsComing := RowsComeTicks;
  FWave := [];
  var WaveEnd: Double := 0;
  for var Row := 0 to High(RowDecks) do
    WaveEnd := Max(WaveEnd, LayComingRow(AScreen, Row, Riding));

  // The groups come on the road right after it; the guard counts from its
  // end, as from a climb's
  FDense := True;
  FCursor := Max(FCursor, ATravel + WaveEnd + RollRange(GroupGapLeast,
    GroupGapMost));
  FClimbEnd := FCursor;
end;

end.
