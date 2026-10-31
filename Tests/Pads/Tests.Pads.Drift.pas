{
  Tests.Pads.Drift - the pads of a chase: sent in from beyond the right
  edge as the road runs, in groups - a lone pad or a climb that a hero can
  go up from the road to where a shot reaches the hatch; the chase opening
  with a climb, a climb never far behind the last, never more pads at once
  than the screen takes, no two across each other, every number of them
  the dice's. The pads ride the road and carry what stands on them, are
  let go past the left edge and sent again; a clear puts the pool to
  sleep. And the level file's word on a pad that drifts.

  A climb in every three carries a medkit, on its middle pad by height,
  which climb of the three the dice's; the medkit rides its pad out past
  the left edge and is gone, as one on the road is.

  The room is the empty one, its pool of screen 1 as the level's. The pads
  name no sprite, so the world asks no art for them. The road is run by
  hand: the world ticks the pads its way, then the dispatcher hears how
  far it has run - as the game does. What was sent is kept on the road,
  its place on the screen plus the road's run, and cut into groups by the
  gaps: a gap of a climb joins, a wider one parts.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Pads.Drift;

interface

uses
  DUnitX.TestFramework,
  Sdl2.Core,
  Levels.Defs,
  Monsters,
  Monsters.Defs,
  Pads.World,
  Pads.Drift;

type
  // A pad as it was sent: its left edge on the road, its width, its deck
  TSentPad = record
    RoadLeft: Double;
    Width: Integer;
    Deck: Double;
  end;

  TSentGroup = TArray<TSentPad>;

  // Where a medkit was told to stand: the middle of its feet on the road
  TSentMedkit = record
    RoadX: Double;
    Deck: Double;
  end;

  [TestFixture]
  TPadDriftTests = class
  private
    FLevel: TLevel;
    FWorld: TPadWorld;
    FDrift: TPadDrift;
    FTravel: Double;
    // The pads the last tick of the road sent, and all of them so far
    FSent: TArray<TPad>;
    FHistory: TArray<TSentPad>;
    // The medkits the last tick of the road told, on the screen, and all of
    // them so far, on the road
    FTickMedkits: TArray<TSdlFPoint>;
    FMedkits: TArray<TSentMedkit>;
    procedure RunRoad(ATicks: Integer; ASpeed: Double = 1);
    procedure RunVaried(ATicks: Integer);
    function Groups: TArray<TSentGroup>;
    function CarriesMedkit(const AGroup: TSentGroup;
      out APadIndex: Integer): Boolean;
    function ClimbsCarrying: TArray<Boolean>;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestNothingComesBeforeTheRoadRuns;
    [Test]
    procedure TestChaseOpensWithAClimbBeyondTheRightEdge;
    [Test]
    procedure TestEveryGroupIsALonePadOrAPassableClimb;
    [Test]
    procedure TestClimbNeverFarBehindTheLast;
    [Test]
    procedure TestNeverMorePadsThanTheScreenTakes;
    [Test]
    procedure TestTwoPadsNeverOverlapAcross;
    [Test]
    procedure TestTheDiceGiveEveryNumber;
    [Test]
    procedure TestPadsRideTheRoad;
    [Test]
    procedure TestStillRoadStillPads;
    [Test]
    procedure TestPadAdriftCarriesItsRider;
    [Test]
    procedure TestPastTheLeftEdgeLetGoAndSentAgain;
    [Test]
    procedure TestClearPutsThePoolToSleep;
    [Test]
    procedure TestShortPoolRaises;
    [Test]
    procedure TestPadOfAnotherWidthRaises;
    [Test]
    procedure TestPadThatDriftsTakesNoPlace;
    [Test]
    procedure TestPadThatDriftsDoesNothingElse;
    [Test]
    procedure TestMedkitOnlyOnTheMiddlePadOfAClimb;
    [Test]
    procedure TestOneClimbInThreeCarriesAMedkit;
    [Test]
    procedure TestTheDicePickTheClimbOfTheThree;
    [Test]
    procedure TestMedkitStandsOnThePadSentWithIt;
    [Test]
    procedure TestClearStartsTheThreeAnew;
  end;

  // A medkit standing on a pad of the chase, and one on the road; the
  // road runs by hand, as the game runs it
  [TestFixture]
  TDriftLootTests = class
  private
    FLevel: TLevel;
    FWorld: TPadWorld;
    FRegistry: TMonsterRegistry;
    FField: TMonsterField;
    function StandMedkit(AX, AY: Double): TMonster;
    procedure RunRoad(ATicks: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestMedkitRidesItsPadOutAndIsGone;
    [Test]
    procedure TestMedkitOnTheRoadRidesOutAndIsGone;
  end;

implementation

uses
  System.IOUtils,
  System.SysUtils,
  Game.Config,
  Game.Space,
  Levels.Pads,
  Render.Sprites,
  Tests.Rooms;

const
  Screen = 1;
  LevelId = 'test';
  // The pool of the level's chase
  PoolSteps = 8;
  PoolHighs = 4;
  // Three minutes of road at cruise
  LongRunTicks = 6000;
  UnitSlack = 0.001;
  FeetWidth = 16;
  // A run long enough for every place of the medkit in its three
  RoundsRunTicks = 4 * LongRunTicks;
  // The medkit's road: the road at cruise, its floor, a pad over it
  RoadSpeed = 1.0;
  FloorY = 352;
  PadDeck = 200;
  PadLeft = 96;

function DriftPadJson(AWidth: Integer; const ATag: string): string;
begin
  Result := Format('{"sprite":"","screen":1,"width":%d,"drift":true,' +
    '"tag":"%s"}', [AWidth, ATag]);
end;

// The pads section of a pool of ASteps steps and AHighs long pads, and of
// AOther pads AOtherWidth wide
function PoolSections(ASteps, AHighs: Integer; AOther: Integer = 0;
  AOtherWidth: Integer = 0): string;
begin
  var Entries: TArray<string> := [];
  for var i := 1 to ASteps do
    Entries := Entries + [DriftPadJson(StepWidth, Format('step-%d', [i]))];
  for var i := 1 to AHighs do
    Entries := Entries + [DriftPadJson(HighWidth, Format('high-%d', [i]))];
  for var i := 1 to AOther do
    Entries := Entries + [DriftPadJson(AOtherWidth,
      Format('other-%d', [i]))];
  Result := '"pads":[' + string.Join(',', Entries) + ']';
end;

function IsAmong(const APads: TArray<TPad>; const APad: TPad): Boolean;
begin
  for var Pad in APads do
    if Pad = APad then
      Exit(True);
  Result := False;
end;

function RoadRight(const APad: TSentPad): Double;
begin
  Result := APad.RoadLeft + APad.Width;
end;

procedure TPadDriftTests.Setup;
begin
  FLevel := LevelFromRows(RoomRowsOf(0, 0, 0, 0),
    PoolSections(PoolSteps, PoolHighs));
  FWorld := TPadWorld.Create(nil, nil, FLevel, nil, 1);
  FDrift := TPadDrift.Create(FWorld, LevelId, 1);
  FTravel := 0;
  FSent := [];
  FHistory := [];
  FTickMedkits := [];
  FMedkits := [];
end;

procedure TPadDriftTests.TearDown;
begin
  FreeAndNil(FDrift);
  FreeAndNil(FWorld);
  FreeAndNil(FLevel);
end;

procedure TPadDriftTests.RunRoad(ATicks: Integer; ASpeed: Double);
var
  Sent: TSentPad;
begin
  for var i := 1 to ATicks do
  begin
    FWorld.Tick(Screen, nil, -ASpeed);
    var Before := FWorld.Standing(Screen);
    FTravel := FTravel + ASpeed;
    FTickMedkits := FDrift.Tick(Screen, FTravel).Medkits;
    for var Mark in FTickMedkits do
    begin
      var Medkit: TSentMedkit;
      Medkit.RoadX := Mark.X + FTravel;
      Medkit.Deck := Mark.Y;
      FMedkits := FMedkits + [Medkit];
    end;
    FSent := [];
    for var Pad in FWorld.Standing(Screen) do
    begin
      if IsAmong(Before, Pad) then
        Continue;
      FSent := FSent + [Pad];
      Sent.RoadLeft := Pad.Left + FTravel;
      Sent.Width := Pad.Placement.Width;
      Sent.Deck := Pad.Top;
      FHistory := FHistory + [Sent];
    end;
  end;
end;

// The road speeding up and slowing down, as it does in a ramp
procedure TPadDriftTests.RunVaried(ATicks: Integer);
const
  Speeds: array [0..3] of Double = (0.3, 1.0, 1.7, 0.85);
begin
  for var i := 1 to ATicks do
    RunRoad(1, Speeds[i mod Length(Speeds)]);
end;

// Along the road, one after another: a gap of a climb joins a pad to the
// group before it
function TPadDriftTests.Groups: TArray<TSentGroup>;
begin
  var Road := Copy(FHistory);
  for var i := 1 to High(Road) do
    for var j := i downto 1 do
    begin
      if Road[j - 1].RoadLeft <= Road[j].RoadLeft then
        Break;
      var Swapped := Road[j];
      Road[j] := Road[j - 1];
      Road[j - 1] := Swapped;
    end;

  Result := [];
  for var i := 0 to High(Road) do
  begin
    var Joins := (i > 0) and
      (Road[i].RoadLeft - RoadRight(Road[i - 1]) <= ClimbGapMost + UnitSlack);
    if Joins then
    begin
      Result[High(Result)] := Result[High(Result)] + [Road[i]];
      Continue;
    end;
    var Group: TSentGroup := [Road[i]];
    Result := Result + [Group];
  end;
end;

// The foot of a climb: its lowest pad, at the plain jump from the road
function FootOf(const AGroup: TSentGroup): TSentPad;
begin
  Result := AGroup[0];
  for var Pad in AGroup do
    if Pad.Deck > Result.Deck then
      Result := Pad;
end;

function TopOf(const AGroup: TSentGroup): TSentPad;
begin
  Result := AGroup[0];
  for var Pad in AGroup do
    if Pad.Deck < Result.Deck then
      Result := Pad;
end;

function IsClimb(const AGroup: TSentGroup): Boolean;
begin
  Result := Length(AGroup) > 1;
end;

// Its pad the middle by height: neither the foot nor the top, and no pad
// between them nearer halfway up - or as near and lower
function IsMidway(const AGroup: TSentGroup; APadIndex: Integer): Boolean;
begin
  var Foot := FootOf(AGroup).Deck;
  var Top := TopOf(AGroup).Deck;
  var Deck := AGroup[APadIndex].Deck;
  if (Deck = Foot) or (Deck = Top) then
    Exit(False);
  var Halfway := (Foot + Top) / 2;
  var Off := Abs(Deck - Halfway);
  for var Pad in AGroup do
  begin
    var Between := (Pad.Deck <> Foot) and (Pad.Deck <> Top);
    var PadOff := Abs(Pad.Deck - Halfway);
    var AsNearAndLower := (PadOff = Off) and (Pad.Deck > Deck);
    var Nearer := (PadOff < Off) or AsNearAndLower;
    if Between and Nearer then
      Exit(False);
  end;
  Result := True;
end;

// The medkit on a pad of AGroup, if one was told: the middle of its deck
function TPadDriftTests.CarriesMedkit(const AGroup: TSentGroup;
  out APadIndex: Integer): Boolean;
begin
  for var i := 0 to High(AGroup) do
    for var Medkit in FMedkits do
    begin
      var OnDeck := Abs(Medkit.Deck - AGroup[i].Deck) < UnitSlack;
      var Middle := AGroup[i].RoadLeft + AGroup[i].Width / 2;
      if OnDeck and (Abs(Medkit.RoadX - Middle) < UnitSlack) then
      begin
        APadIndex := i;
        Exit(True);
      end;
    end;
  APadIndex := -1;
  Result := False;
end;

// The climbs along the road, whether each carries a medkit; the last group
// may still be coming in, so it is left out
function TPadDriftTests.ClimbsCarrying: TArray<Boolean>;
begin
  Result := [];
  var All := Groups;
  for var g := 0 to High(All) - 1 do
  begin
    if not IsClimb(All[g]) then
      Continue;
    var PadIndex: Integer;
    Result := Result + [CarriesMedkit(All[g], PadIndex)];
  end;
end;

// By value, not const: the anonymous method captures it
procedure ExpectPoolRaises(AWorld: TPadWorld; const AWhat: string);
begin
  Assert.WillRaise(
    procedure
    begin
      TPadDrift.Create(AWorld, LevelId, 1).Free;
    end, EPadError, AWhat);
end;

procedure TPadDriftTests.TestNothingComesBeforeTheRoadRuns;
begin
  for var i := 1 to 100 do
    FWorld.Tick(Screen, nil);

  Assert.AreEqual(0, Integer(Length(FWorld.Standing(Screen))),
    'Pads of the pool on the screen');
end;

procedure TPadDriftTests.TestChaseOpensWithAClimbBeyondTheRightEdge;
begin
  RunRoad(1);

  Assert.AreEqual(1, Integer(Length(FSent)), 'Pads at the start');
  Assert.IsTrue(FSent[0].Left >= ScreenWidth,
    Format('The first pad at %g, inside the screen', [FSent[0].Left]));
  RunRoad(400);
  var First := Groups[0];
  Assert.IsTrue(IsClimb(First), 'The first group is a lone pad');
end;

procedure TPadDriftTests.TestEveryGroupIsALonePadOrAPassableClimb;
begin
  RunVaried(LongRunTicks);

  var All := Groups;
  // The last may still be coming in
  for var g := 0 to High(All) - 1 do
  begin
    var Group := All[g];
    for var Pad in Group do
      Assert.IsTrue((Pad.Deck >= HighestDeck) and (Pad.Deck <= LowestDeck),
        Format('Group %d: a pad on %g', [g, Pad.Deck]));
    if not IsClimb(Group) then
      Continue;
    Assert.IsTrue(FootOf(Group).Deck >= ClimbFootHighest,
      Format('Group %d: its foot on %g, out of the jump from the road',
        [g, FootOf(Group).Deck]));
    Assert.IsTrue(TopOf(Group).Deck <= WayUpDeck,
      Format('Group %d: its top on %g, short of the hatch',
        [g, TopOf(Group).Deck]));
    // Along the road it only rises or only falls, a jump a step
    var Rises := Group[1].Deck < Group[0].Deck;
    for var i := 1 to High(Group) do
    begin
      var Up := Group[i - 1].Deck - Group[i].Deck;
      if not Rises then
        Up := -Up;
      var Gap := Group[i].RoadLeft - RoadRight(Group[i - 1]);
      Assert.IsTrue((Up > 0) and (Up <= ClimbStepMost),
        Format('Group %d, pad %d: a step of %g', [g, i, Up]));
      Assert.IsTrue((Gap >= ClimbGapLeast - UnitSlack) and
        (Gap <= ClimbGapMost + UnitSlack),
        Format('Group %d, pad %d: %g across', [g, i, Gap]));
    end;
  end;
  Assert.IsTrue(Length(All) > 10, 'Too few groups to judge');
end;

procedure TPadDriftTests.TestClimbNeverFarBehindTheLast;
const
  // The guard, and the most a lone pad and its empty road may take after
  // the guard last let one by
  Furthest = GuardUnits + HighWidth + GroupGapMost;
begin
  RunVaried(LongRunTicks);

  var LastEnd := 0.0;
  var Climbs := 0;
  for var Group in Groups do
  begin
    if not IsClimb(Group) then
      Continue;
    if Climbs > 0 then
      Assert.IsTrue(Group[0].RoadLeft - LastEnd <= Furthest + UnitSlack,
        Format('Climb %d: %g of road after the last', [Climbs,
          Group[0].RoadLeft - LastEnd]));
    LastEnd := RoadRight(Group[High(Group)]);
    Inc(Climbs);
  end;
  Assert.IsTrue(Climbs > 5, Format('Only %d climbs', [Climbs]));
end;

procedure TPadDriftTests.TestNeverMorePadsThanTheScreenTakes;
begin
  for var i := 1 to LongRunTicks do
  begin
    RunRoad(1);
    var Count := Length(FWorld.Standing(Screen));
    Assert.IsTrue(Count <= MostAdrift,
      Format('Tick %d: %d pads sent at once', [i, Integer(Count)]));
  end;
end;

procedure TPadDriftTests.TestTwoPadsNeverOverlapAcross;
begin
  for var i := 1 to LongRunTicks do
  begin
    RunRoad(1);
    var Pads := FWorld.Standing(Screen);
    for var j := 0 to High(Pads) do
      for var k := j + 1 to High(Pads) do
      begin
        var Apart := (Pads[j].Right <= Pads[k].Left + UnitSlack) or
          (Pads[k].Right <= Pads[j].Left + UnitSlack);
        Assert.IsTrue(Apart, Format('Tick %d: two pads across each other',
          [i]));
      end;
  end;
end;

procedure TPadDriftTests.TestTheDiceGiveEveryNumber;
begin
  RunRoad(LongRunTicks);

  var Decks: TArray<Integer> := [];
  var Steps := 0;
  var Highs := 0;
  for var Pad in FHistory do
  begin
    var Deck := Round(Pad.Deck);
    var Known := False;
    for var Seen in Decks do
      Known := Known or (Seen = Deck);
    if not Known then
      Decks := Decks + [Deck];
    if Pad.Width = StepWidth then
      Inc(Steps)
    else
      Inc(Highs);
  end;
  Assert.IsTrue(Length(Decks) >= 25,
    Format('Only %d heights', [Integer(Length(Decks))]));
  Assert.IsTrue((Steps > 0) and (Highs > 0), 'One width only');

  var Toward := 0;
  var Away := 0;
  var Lone := 0;
  for var Group in Groups do
    if not IsClimb(Group) then
      Inc(Lone)
    else if Group[1].Deck < Group[0].Deck then
      Inc(Toward)
    else
      Inc(Away);
  Assert.IsTrue(Toward > 0, 'No climb rising toward the machine');
  Assert.IsTrue(Away > 0, 'No climb rising away from it');
  Assert.IsTrue(Lone > 0, 'No lone pad');
end;

procedure TPadDriftTests.TestPadsRideTheRoad;
begin
  RunRoad(1);
  var Pads := FWorld.Standing(Screen);
  var Lefts: TArray<Double> := [];
  for var Pad in Pads do
    Lefts := Lefts + [Pad.Left];

  RunRoad(10, 1.5);

  for var i := 0 to High(Pads) do
    Assert.IsTrue(Abs(Lefts[i] - 15 - Pads[i].Left) < UnitSlack,
      'Ten ticks of the road at 1.5 a tick');
end;

procedure TPadDriftTests.TestStillRoadStillPads;
begin
  RunRoad(30);
  var Pads := FWorld.Standing(Screen);
  var Lefts: TArray<Double> := [];
  for var Pad in Pads do
    Lefts := Lefts + [Pad.Left];

  for var i := 1 to 30 do
    FWorld.Tick(Screen, nil, 0);

  for var i := 0 to High(Pads) do
    Assert.IsTrue(Abs(Lefts[i] - Pads[i].Left) < UnitSlack,
      'The road stands: the pads stand');
end;

procedure TPadDriftTests.TestPadAdriftCarriesItsRider;
begin
  RunRoad(30);
  var Pad := FWorld.Standing(Screen)[0];
  var Feet := Pad.Left + (Pad.Placement.Width - FeetWidth) / 2;
  Assert.IsTrue(FWorld.DeckUnder(Screen, Feet, Feet + FeetWidth,
    Pad.Top) = Pad, 'Feet on the deck stand on it');

  RunRoad(1);

  Assert.IsTrue(FWorld.DeckCarrying(Screen, Feet, Feet + FeetWidth,
    Pad.Top) = Pad, 'It carries what stood on it');
  Assert.IsTrue(Abs(Pad.MotionX + 1) < UnitSlack,
    Format('It went %g, the road 1 to the left', [Pad.MotionX]));
end;

procedure TPadDriftTests.TestPastTheLeftEdgeLetGoAndSentAgain;
begin
  for var i := 1 to LongRunTicks do
  begin
    RunRoad(1);
    for var Pad in FWorld.Standing(Screen) do
      Assert.IsTrue(Pad.Right >= 0,
        Format('Tick %d: a pad wholly past the left edge', [i]));
  end;
  Assert.IsTrue(Length(FHistory) > 3 * (PoolSteps + PoolHighs),
    Format('Only %d pads sent from a pool of %d',
      [Integer(Length(FHistory)), PoolSteps + PoolHighs]));
end;

procedure TPadDriftTests.TestClearPutsThePoolToSleep;
begin
  RunRoad(600);
  Assert.IsTrue(Length(FWorld.Standing(Screen)) > 0, 'Pads on the screen');

  FDrift.Clear(7);

  Assert.AreEqual(0, Integer(Length(FWorld.Standing(Screen))),
    'Pads on the screen after the clear');
  FDrift.Tick(Screen, 0);
  for var Pad in FWorld.Standing(Screen) do
    Assert.IsTrue(Pad.Left >= ScreenWidth,
      'The road begins again beyond the right edge');
end;

procedure TPadDriftTests.TestShortPoolRaises;
var
  Level: TLevel;
  World: TPadWorld;
begin
  Level := LevelFromRows(RoomRowsOf(0, 0, 0, 0),
    PoolSections(MostAdrift - 2, 1));
  try
    World := TPadWorld.Create(nil, nil, Level, nil, 1);
    try
      ExpectPoolRaises(World, 'A pad short of the most at once');
    finally
      World.Free;
    end;
  finally
    Level.Free;
  end;
end;

procedure TPadDriftTests.TestPadOfAnotherWidthRaises;
var
  Level: TLevel;
  World: TPadWorld;
begin
  Level := LevelFromRows(RoomRowsOf(0, 0, 0, 0),
    PoolSections(PoolSteps, PoolHighs, 1, 48));
  try
    World := TPadWorld.Create(nil, nil, Level, nil, 1);
    try
      ExpectPoolRaises(World, 'A pad 48 wide in the pool');
    finally
      World.Free;
    end;
  finally
    Level.Free;
  end;
end;

procedure TPadDriftTests.TestPadThatDriftsTakesNoPlace;
begin
  Assert.WillRaise(
    procedure
    begin
      LevelFromRows(RoomRowsOf(0, 0, 0, 0),
        '"pads":[{"sprite":"","screen":1,"x":64,"y":224,"width":32,' +
        '"drift":true}]').Free;
    end, EPadError, 'A pad that drifts given a place');
end;

procedure TPadDriftTests.TestPadThatDriftsDoesNothingElse;
begin
  Assert.WillRaise(
    procedure
    begin
      LevelFromRows(RoomRowsOf(0, 0, 0, 0),
        '"pads":[{"sprite":"","screen":1,"width":32,"drift":true,' +
        '"dormant":true}]').Free;
    end, ELevelError, 'A pad that drifts and sleeps for a scene');
end;

procedure TPadDriftTests.TestMedkitOnlyOnTheMiddlePadOfAClimb;
begin
  RunVaried(LongRunTicks);

  var All := Groups;
  var Carried := 0;
  // The last may still be coming in
  for var g := 0 to High(All) - 1 do
  begin
    var PadIndex: Integer;
    if not CarriesMedkit(All[g], PadIndex) then
      Continue;
    Inc(Carried);
    Assert.IsTrue(IsClimb(All[g]), Format('Group %d: a medkit on a lone pad',
      [g]));
    Assert.IsTrue(IsMidway(All[g], PadIndex),
      Format('Group %d: a medkit on %g, not the middle of its climb',
        [g, All[g][PadIndex].Deck]));
  end;
  Assert.IsTrue(Carried > 3, Format('Only %d medkits', [Carried]));
end;

procedure TPadDriftTests.TestOneClimbInThreeCarriesAMedkit;
begin
  RunRoad(RoundsRunTicks);

  var Climbs := ClimbsCarrying;
  var Rounds := Length(Climbs) div MedkitClimbs;
  for var r := 0 to Rounds - 1 do
  begin
    var Carrying := 0;
    for var i := 0 to MedkitClimbs - 1 do
      if Climbs[r * MedkitClimbs + i] then
        Inc(Carrying);
    Assert.AreEqual(1, Carrying, Format('Climbs %d to %d',
      [r * MedkitClimbs, (r + 1) * MedkitClimbs - 1]));
  end;
  Assert.IsTrue(Rounds > 5, Format('Only %d rounds', [Rounds]));
end;

procedure TPadDriftTests.TestTheDicePickTheClimbOfTheThree;
var
  Places: array [0..MedkitClimbs - 1] of Integer;
begin
  RunRoad(RoundsRunTicks);

  var Climbs := ClimbsCarrying;
  for var i := 0 to MedkitClimbs - 1 do
    Places[i] := 0;
  for var i := 0 to Length(Climbs) div MedkitClimbs * MedkitClimbs - 1 do
    if Climbs[i] then
      Inc(Places[i mod MedkitClimbs]);
  for var i := 0 to MedkitClimbs - 1 do
    Assert.IsTrue(Places[i] > 0,
      Format('Never the climb %d of its three', [i + 1]));
end;

procedure TPadDriftTests.TestMedkitStandsOnThePadSentWithIt;
begin
  var Told := 0;
  for var i := 1 to LongRunTicks do
  begin
    RunRoad(1);
    for var Mark in FTickMedkits do
    begin
      Inc(Told);
      var Found := False;
      for var Pad in FSent do
      begin
        var OnDeck := Abs(Mark.Y - Pad.Top) < UnitSlack;
        var Middle := Pad.Left + Pad.Placement.Width / 2;
        if OnDeck and (Abs(Mark.X - Middle) < UnitSlack) then
          Found := True;
      end;
      Assert.IsTrue(Found, Format('Tick %d: a medkit on no pad just sent',
        [i]));
    end;
  end;
  Assert.IsTrue(Told > 3, Format('Only %d medkits', [Told]));
end;

procedure TPadDriftTests.TestClearStartsTheThreeAnew;
begin
  // A climb or two into the first three
  RunRoad(300);
  Assert.IsTrue(Length(FHistory) > 0, 'Nothing sent before the clear');

  FDrift.Clear(7);
  FTravel := 0;
  FHistory := [];
  FMedkits := [];
  RunRoad(LongRunTicks);

  var Climbs := ClimbsCarrying;
  Assert.IsTrue(Length(Climbs) >= MedkitClimbs, 'Too few climbs');
  var Carrying := 0;
  for var i := 0 to MedkitClimbs - 1 do
    if Climbs[i] then
      Inc(Carrying);
  Assert.AreEqual(1, Carrying, 'The first three after the clear');
end;

// ---------------------------------------------------------------------------
// The medkit on the road of the chase
// ---------------------------------------------------------------------------

procedure TDriftLootTests.Setup;
begin
  FLevel := LevelFromRows(RoomRowsOf(0, 0, 0, 0),
    PoolSections(PoolSteps, PoolHighs));
  FWorld := TPadWorld.Create(nil, nil, FLevel, nil, 1);
  FRegistry := TMonsterRegistry.Create;
  FRegistry.LoadFromFile(
    TPath.Combine(ExtractFilePath(ParamStr(0)), 'monsters.json'));
  FField := TMonsterField.Create(nil, FRegistry, FLevel, FWorld, dfNormal,
    1.0);
end;

// The field, which owns the bodies leaning on the level and the pads, first
procedure TDriftLootTests.TearDown;
begin
  FreeAndNil(FField);
  FreeAndNil(FRegistry);
  FreeAndNil(FWorld);
  FreeAndNil(FLevel);
end;

function TDriftLootTests.StandMedkit(AX, AY: Double): TMonster;
var
  Placement: TEntityPlacement;
begin
  Placement := Default(TEntityPlacement);
  Placement.MonsterId := 'medkit';
  Placement.Screen := Screen;
  Placement.X := 1;
  Placement.Y := 1;
  Result := TMonster.Create(FRegistry.Find(Placement.MonsterId),
    Default(TAnimSet), nil, nil, FLevel, FWorld, Placement, 1.0);
  FField.Monsters.Add(Result);
  Result.Stand(AX, AY, False);
end;

// The pads first, then the bodies, then the loot on the road
procedure TDriftLootTests.RunRoad(ATicks: Integer);
begin
  for var i := 1 to ATicks do
  begin
    FWorld.Tick(Screen, nil, -RoadSpeed);
    FField.Tick(Screen, 0, 0, nil);
    FField.CarryLoot(Screen, -RoadSpeed);
  end;
end;

procedure TDriftLootTests.TestMedkitRidesItsPadOutAndIsGone;
begin
  var Pad := FWorld.FreeDrifter(Screen, StepWidth);
  Pad.SetAdrift(PadLeft, PadDeck);
  var Medkit := StandMedkit(PadLeft + (StepWidth - SpriteSize) / 2, PadDeck);

  for var i := 1 to PadLeft + StepWidth + 10 do
  begin
    RunRoad(1);
    if Medkit.Life <> mlAlive then
      Break;
    Assert.IsTrue(Abs(Medkit.Y - Pad.Top) < UnitSlack,
      Format('Tick %d: off the deck, its feet at %g', [i, Medkit.Y]));
    Assert.IsTrue(Abs(Medkit.X - Pad.Left) < UnitSlack,
      Format('Tick %d: at %g, its pad at %g', [i, Medkit.X, Pad.Left]));
  end;
  Assert.IsTrue(Medkit.Life <> mlAlive, 'Still there past the left edge');
end;

procedure TDriftLootTests.TestMedkitOnTheRoadRidesOutAndIsGone;
const
  StartX = 40;
  TicksToGo = StartX + SpriteSize;
begin
  var Medkit := StandMedkit(StartX, FloorY);

  RunRoad(TicksToGo - 1);
  Assert.IsTrue(Medkit.Life = mlAlive, 'Gone before wholly past the edge');
  Assert.IsTrue(Abs(Medkit.X - (StartX - (TicksToGo - 1))) < UnitSlack,
    Format('At %g after riding the road', [Medkit.X]));

  RunRoad(1);
  Assert.IsTrue(Medkit.Life <> mlAlive, 'Still there past the left edge');
end;

initialization
  TDUnitX.RegisterTestFixture(TPadDriftTests);
  TDUnitX.RegisterTestFixture(TDriftLootTests);

end.
