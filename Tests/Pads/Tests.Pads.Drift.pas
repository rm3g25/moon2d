{
  Tests.Pads.Drift - the pads of a chase: sent in from beyond the right
  edge as the road runs, in groups - a lone pad or a climb that a hero can
  go up from the road to where a shot reaches the hatch; the chase opening
  with a climb, a climb never far behind the last, never more pads at once
  than the screen takes, no two across each other, every number of them
  the dice's. The pads ride the road and carry what stands on them, are
  let go past the left edge and sent again; a clear puts the pool to
  sleep. And the level file's word on a pad that drifts.

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
  Levels.Defs,
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
    procedure RunRoad(ATicks: Integer; ASpeed: Double = 1);
    procedure RunVaried(ATicks: Integer);
    function Groups: TArray<TSentGroup>;
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
  end;

implementation

uses
  System.SysUtils,
  Game.Space,
  Levels.Pads,
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
    FDrift.Tick(Screen, FTravel);
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

initialization
  TDUnitX.RegisterTestFixture(TPadDriftTests);

end.
