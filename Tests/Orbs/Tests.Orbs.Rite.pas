{
  Tests.Orbs.Rite - the rite of orbs ticked without a window: what it
  tells and when, how many orbs it calls and where they are born, when an
  orb is armed, that the pattern about the hero has no holes - not after a
  walk, a leap, a door or losses in flight -, how the orbs draw into his
  body and stay there until the suit, and how the suit gives them back as
  a ring that stands its time and goes out.

  The rite knows no pattern and no score of its own, so most tests bring
  theirs: a grid of seats that stand still, each to be found by its place,
  and a short score whose ticks are spelled. The ice score and the game's
  two patterns are run where the game's own numbers are the subject. The
  hero is a point the test moves; his body is five points about it.

  What the game does with an armed orb is the game's: a test strikes as
  the game would, spending the armed. The look of it all - the sway over a
  face, the spiral of a flight, the wind of the drawing in, what is drawn
  ahead between ticks - is for the eye.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Orbs.Rite;

interface

uses
  DUnitX.TestFramework, System.Generics.Collections, Sdl2.Core, Orbs.Flock,
  Orbs.Harvest, Orbs.Patterns, Orbs.Rite;

type
  TRiteEvents = set of TRiteEvent;
  TPlaces = TArray<TSdlFPoint>;

  [TestFixture]
  TOrbRiteTests = class
  private
    FRite: TOrbRite;
    // A second rite, for the test that runs two side by side
    FTwin: TOrbRite;
    FMatter: TMatter;
    // The hero's middle, where the next tick finds it
    FCenter: TSdlFPoint;
    // Ticks gone by since the rite or the shed began: the number of the
    // next one, counted from 0
    FTicks: Integer;
    // What the rite has told since it began, the oldest first, and the
    // tick of each
    FTold: TList<TRiteEvent>;
    FToldAt: TList<Integer>;
    // The times a rite has asked for the hero's body
    FAsked: Integer;
    function BodyAboutHero: TBodyPoints;
    function NoBody: TBodyPoints;
    procedure RemakeRite(const ABody: TBodyProbe);
    procedure Start(const APattern: TOrbPattern; const AScore: TRiteScore);
    procedure Shed(const AScore: TRiteScore);
    // One tick with the hero where he is; what the rite told in it
    function Tick: TRiteEvents;
    procedure Run(ACount: Integer);
    // Until the tick of this number is done
    procedure RunTo(ATick: Integer);
    // Ticks nobody listens to: what the rite tells stays with it
    procedure RunUnheard(ACount: Integer);
    procedure Walk(AStepX, AStepY: Single);
    // A door: the rite is carried by the step and the hero is there
    procedure Carry(AStepX, AStepY: Single);
    function Orbs: TObjectList<TOrb>;
    function ArmedCount: Integer;
    // Of the first ACount orbs of the flock
    function ArmedAmongFirst(ACount: Integer): Integer;
    function AliveCount: Integer;
    function NewbornCount: Integer;
    // As the game strikes: the armed are spent, AMost of them at most;
    // how many were
    function StrikeArmed(AMost: Integer): Integer;
    // Where every orb is, in the order of the flock
    function Places: TPlaces;
    function AwayFromHero(const AOrb: TOrb): Single;
    function OrbsAt(AX, AY: Single): Integer;
    function IsOnGridSeat(const AOrb: TOrb): Boolean;
    // Every seat of the grid about the hero holds one orb, and there is
    // no orb besides
    procedure ExpectGridFull(const AWhen: string);
    // The point of the hero's body the orb stands on, -1 for none
    function BodyPointUnder(const AOrb: TOrb): Integer;
    function OrbsOnBody: Integer;
    procedure ExpectTold(const AEvents: array of TRiteEvent;
      const AWhat: string);
    procedure ExpectIceRiteRunsToTheSuit(const AName: string);
    procedure ExpectAllGoInAtTheChest(const AWhat: string);
    // Where the orb stands on the oval of the shield about the hero: how
    // far out, 1 on the oval itself, and how far round, radians
    function RingReach(const AOrb: TOrb): Single;
    function RingTurn(const AOrb: TOrb): Single;
    procedure ExpectOnRing(const AWhen: string);
    // The gaps between the neighbours of the ring, radians, the widest
    // last
    function RingGaps: TArray<Single>;
    procedure ExpectSameAsTwin(ATick: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestNewRiteIsIdleAndEmpty;
    [Test]
    procedure TestEventsComeByTheScoresSchedule;
    [Test]
    procedure TestStageFollowsTheSchedule;
    [Test]
    procedure TestGamePatternsRunTheIceRiteToTheSuit;
    [Test]
    procedure TestEveryWaveBringsItsCountOfOrbs;
    [Test]
    procedure TestOrbsAreBornInTheMatterSmallAndUnarmed;
    [Test]
    procedure TestOrbIsArmedOnlyOnItsWayToItsSeat;
    [Test]
    procedure TestPatternIsFullAtThePause;
    [Test]
    procedure TestSeatedOrbTakesTheDepthOfItsSeat;
    [Test]
    procedure TestMiddleWaveTurnsAgainstTheOthers;
    [Test]
    procedure TestPatternGathersAboutAWalkingHero;
    [Test]
    procedure TestSeatedPatternKeepsToTheHeroWhateverHisStep;
    [Test]
    procedure TestLeapDoesNotThrowFlyingOrbs;
    [Test]
    procedure TestPauseSeatsWhoeverIsStillInFlight;
    [Test]
    procedure TestRiteInAnEmptyRoomStillFillsItsPattern;
    [Test]
    procedure TestOrbStruckInFlightIsReplaced;
    [Test]
    procedure TestStandInComesOutOfTheFaceOfTheStruck;
    [Test]
    procedure TestArmedStandInsAreNoMoreThanTheStock;
    [Test]
    procedure TestLateStandInThickensAtItsSeatUnarmed;
    [Test]
    procedure TestPatternClockQuickensThenStandsStillAndFlashes;
    [Test]
    procedure TestOrbsDrawIntoTheBodyAndStayUntilTheSuit;
    [Test]
    procedure TestOrbsDrawInOutOfStep;
    [Test]
    procedure TestBodyIsAskedOnceAsTheCollapseBegins;
    [Test]
    procedure TestLightsOnTheBodyRideWithTheHero;
    [Test]
    procedure TestWithNoBodyEveryOrbGoesInAtTheChest;
    [Test]
    procedure TestCollapseImplodesEveryOrbAndTellsNoFinish;
    [Test]
    procedure TestClearLeavesNothingAndNothingComes;
    [Test]
    procedure TestStartDropsTheRiteAlreadyGoing;
    [Test]
    procedure TestShedAndRiteDropEachOther;
    [Test]
    procedure TestCarryTakesTheGatheringThroughADoor;
    [Test]
    procedure TestCarrySendsNobodyFlyingBack;
    [Test]
    procedure TestCarryKeepsTheSeatedPatternAboutTheHero;
    [Test]
    procedure TestShedBringsItsOrbsOutOfTheBodyArmed;
    [Test]
    procedure TestShedWithNoBodyComesOutOfTheChest;
    [Test]
    procedure TestIceShedStandsInAnEvenRingOfSeventyTwo;
    [Test]
    procedure TestShedRingKeepsToAWalkingHeroAndFlowsOneWay;
    [Test]
    procedure TestShedRingStandsItsTimeThenGoesOutOrbByOrb;
    [Test]
    procedure TestShedRingIsLeftGappedAfterLosses;
    [Test]
    procedure TestDeathImplodesTheShedRing;
    [Test]
    procedure TestCarryTakesTheShedRingThroughADoor;
    [Test]
    procedure TestSameCallsGiveTheSameRite;
  end;

implementation

uses
  System.SysUtils, System.Math, Tests.Matter;

const
  PlaceSlack = 0.01; // units
  // The hero's middle as he stands on the floor of the walled room
  StandX = 256;
  StandY = 336;
  WalkStep = 2; // units a tick
  // The return from a pit: the hero is somewhere else within a tick
  LeapX = -150;
  LeapY = -100;
  // A door is nearly a screen wide
  DoorStep = -480; // units

  // The seats of the test's own patterns: a row to a wave, the first
  // behind the hero and the other two in front
  GridPerWave = 10;
  GridOrbs = PatternWaves * GridPerWave;
  GridLeft = -36;
  GridTop = -30;
  GridColumnStep = 8;
  GridRowStep = 20;
  // The clock pattern's seats sink by this much for a tick of its clock
  ClockPace = 0.05; // units

  // A short score of the test's own, every number unlike the ice score's
  BenchScore: TRiteScore = (WaveGap: 10; WaveSpan: 40; HoverTicks: 12;
    FreezeTicks: 4; CollapseTicks: 9; StandIns: 5; ShedOrbs: 30;
    ShedTicks: 40; ShedSpread: 12);
  // By the bench score, ticks counted from 0: the third wave is called on
  // tick 20 and has 40 ticks to sit
  BenchPause = 60;
  BenchCollapse = 72;
  BenchFinish = 81;

  // Three waves of 24, and as many come out of the suit
  IceOrbs = 72;
  // By the bench score: a stand-in for an orb struck by tick 52 is in its
  // seat by now, and the collapse has not begun
  SettledTick = 65;
  // A rite that is over stays quiet: it is watched this long after
  QuietTicks = 100;
  // No orb takes a second to go
  LongestGoodbye = 33; // ticks
  // An orb just born is under this share of its size
  NewbornSize = 0.5;
  // A body that gives no points is entered at the chest: one point, this
  // near the middle of the body
  ChestReach = 4; // units
  // Farther from the hero than this a flight is all turn about him
  FarFromHero = 60; // units

  // What a rite tells from its start to the suit
  WholeRite: array [0..8] of TRiteEvent = (reWaveCalled, reWaveCalled,
    reWaveCalled, reWaveSeated, reWaveSeated, reWaveSeated, rePaused,
    reCollapsing, reFinished);

  // The points of the hero's body, from his middle
  BodyOffsets: array [0..4] of TSdlFPoint = ((X: -6; Y: -12), (X: 5; Y: -8),
    (X: -3; Y: 2), (X: 7; Y: 9), (X: 0; Y: 14));

  // The shield's oval, the aura's own: its half-axes
  RingAcross = 28; // units
  RingUpright = 35; // units
  RingSlack = 0.01; // of the oval's size
  // The ring is there half a second after the suit is shed
  FormedTicks = 16;
  // A gap of the ring is even to within this share of itself
  GapSlack = 0.02;

function PointAt(AX, AY: Single): TSdlFPoint;
begin
  Result.X := AX;
  Result.Y := AY;
end;

function IsNear(AX, AY, AToX, AToY: Single): Boolean;
begin
  Result := (Abs(AX - AToX) < PlaceSlack) and (Abs(AY - AToY) < PlaceSlack);
end;

function Distance(AX, AY, AToX, AToY: Single): Single;
begin
  Result := Sqrt(Sqr(AToX - AX) + Sqr(AToY - AY));
end;

// The turn about ACenter from ABefore to AAfter, radians, the short way
// round
function TurnBetween(ACenter, ABefore, AAfter: TSdlFPoint): Single;
begin
  var BeforeX: Single := ABefore.X - ACenter.X;
  var BeforeY: Single := ABefore.Y - ACenter.Y;
  var AfterX: Single := AAfter.X - ACenter.X;
  var AfterY: Single := AAfter.Y - ACenter.Y;
  // The sine and the cosine of the turn, times the two lengths
  var Cross: Single := BeforeX * AfterY - BeforeY * AfterX;
  var Dot: Single := BeforeX * AfterX + BeforeY * AfterY;
  Result := ArcTan2(Cross, Dot);
end;

function IsAmong(AValue: Integer; const AValues: array of Integer): Boolean;
begin
  Result := False;
  for var Value in AValues do
    if Value = AValue then
      Exit(True);
end;

// Which of the places the point is at, -1 for none
function PlaceUnder(const APlaces: TPlaces; AX, AY: Single): Integer;
begin
  Result := -1;
  for var i := 0 to High(APlaces) do
    if IsNear(AX, AY, APlaces[i].X, APlaces[i].Y) then
      Exit(i);
end;

function CountOf(const AFlags: TArray<Boolean>): Integer;
begin
  Result := 0;
  for var Flag in AFlags do
    if Flag then
      Inc(Result);
end;

// A seat of the grid stands still: it is found by its place alone
function GridSeat(AWave, AIndex, APerWave: Integer;
  AFlow: Single): TPatternSeat;
begin
  Result.X := GridLeft + AIndex * GridColumnStep;
  Result.Y := GridTop + AWave * GridRowStep;
  Result.Depth := 1;
  if AWave = 0 then
    Result.Depth := -1;
  Result.Level := 1;
end;

// The grid, sinking with the pattern's clock: an orb in its seat shows
// how far the clock has gone
function ClockSeat(AWave, AIndex, APerWave: Integer;
  AFlow: Single): TPatternSeat;
begin
  Result := GridSeat(AWave, AIndex, APerWave, AFlow);
  Result.Y := Result.Y + AFlow * ClockPace;
  Result.Depth := 0;
end;

function GridPattern: TOrbPattern;
begin
  Result.Name := 'grid';
  Result.PerWave := GridPerWave;
  Result.Seat := GridSeat;
end;

function ClockPattern: TOrbPattern;
begin
  Result.Name := 'clock';
  Result.PerWave := GridPerWave;
  Result.Seat := ClockSeat;
end;

// The ticks of the ice score, counted from 0. Read from the score: its
// numbers are still being tuned.
function IcePause: Integer;
begin
  Result := (PatternWaves - 1) * IceRiteScore.WaveGap + IceRiteScore.WaveSpan;
end;

function IceCollapse: Integer;
begin
  Result := IcePause + IceRiteScore.HoverTicks;
end;

function IceFinish: Integer;
begin
  Result := IceCollapse + IceRiteScore.CollapseTicks;
end;

// The stage the bench score has the rite in once the tick is done
function BenchStageAfter(ATick: Integer): TRiteStage;
begin
  Result := rsGathering;
  if ATick >= BenchPause then
    Result := rsHovering;
  if ATick >= BenchCollapse then
    Result := rsCollapsing;
  if ATick >= BenchFinish then
    Result := rsIdle;
end;

// ---------------------------------------------------------------------------
// The bench
// ---------------------------------------------------------------------------

procedure TOrbRiteTests.Setup;
begin
  FTold := TList<TRiteEvent>.Create;
  FToldAt := TList<Integer>.Create;
  FMatter := WalledMatter;
  FCenter := PointAt(StandX, StandY);
  FTicks := 0;
  FAsked := 0;
  FRite := TOrbRite.Create(IceOrbTint, BodyAboutHero);
end;

procedure TOrbRiteTests.TearDown;
begin
  FreeAndNil(FTwin);
  FreeAndNil(FRite);
  FreeAndNil(FToldAt);
  FreeAndNil(FTold);
end;

function TOrbRiteTests.BodyAboutHero: TBodyPoints;
begin
  Inc(FAsked);
  SetLength(Result, Length(BodyOffsets));
  for var i := 0 to High(BodyOffsets) do
    Result[i] := PointAt(FCenter.X + BodyOffsets[i].X,
      FCenter.Y + BodyOffsets[i].Y);
end;

function TOrbRiteTests.NoBody: TBodyPoints;
begin
  Result := nil;
end;

procedure TOrbRiteTests.RemakeRite(const ABody: TBodyProbe);
begin
  FreeAndNil(FRite);
  FRite := TOrbRite.Create(IceOrbTint, ABody);
end;

procedure TOrbRiteTests.Start(const APattern: TOrbPattern;
  const AScore: TRiteScore);
begin
  FRite.Start(APattern, AScore, FCenter, FMatter);
  FTicks := 0;
  FTold.Clear;
  FToldAt.Clear;
end;

procedure TOrbRiteTests.Shed(const AScore: TRiteScore);
begin
  FRite.Shed(AScore, FCenter);
  FTicks := 0;
  FTold.Clear;
  FToldAt.Clear;
end;

function TOrbRiteTests.Tick: TRiteEvents;
begin
  FRite.Tick(FCenter);

  Result := [];
  var Event := FRite.DrainEvent;
  while Event <> reNone do
  begin
    Include(Result, Event);
    FTold.Add(Event);
    FToldAt.Add(FTicks);
    Event := FRite.DrainEvent;
  end;
  Inc(FTicks);
end;

procedure TOrbRiteTests.Run(ACount: Integer);
begin
  for var i := 1 to ACount do
    Tick;
end;

procedure TOrbRiteTests.RunTo(ATick: Integer);
begin
  while FTicks <= ATick do
    Tick;
end;

procedure TOrbRiteTests.RunUnheard(ACount: Integer);
begin
  for var i := 1 to ACount do
    FRite.Tick(FCenter);
  Inc(FTicks, ACount);
end;

procedure TOrbRiteTests.Walk(AStepX, AStepY: Single);
begin
  FCenter := PointAt(FCenter.X + AStepX, FCenter.Y + AStepY);
end;

procedure TOrbRiteTests.Carry(AStepX, AStepY: Single);
begin
  FRite.Carry(AStepX, AStepY);
  Walk(AStepX, AStepY);
end;

function TOrbRiteTests.Orbs: TObjectList<TOrb>;
begin
  Result := FRite.Flock.Orbs;
end;

function TOrbRiteTests.ArmedCount: Integer;
begin
  Result := 0;
  for var Orb in Orbs do
    if Orb.Armed then
      Inc(Result);
end;

function TOrbRiteTests.ArmedAmongFirst(ACount: Integer): Integer;
begin
  Result := 0;
  for var i := 0 to ACount - 1 do
    if Orbs[i].Armed then
      Inc(Result);
end;

function TOrbRiteTests.AliveCount: Integer;
begin
  Result := 0;
  for var Orb in Orbs do
    if Orb.State = osAlive then
      Inc(Result);
end;

function TOrbRiteTests.NewbornCount: Integer;
begin
  Result := 0;
  for var Orb in Orbs do
    if Orb.Age = 0 then
      Inc(Result);
end;

function TOrbRiteTests.StrikeArmed(AMost: Integer): Integer;
begin
  Result := 0;
  for var Orb in Orbs do
  begin
    if Result = AMost then
      Break;
    var IsStruck := (Orb.State = osAlive) and Orb.Armed;
    if not IsStruck then
      Continue;
    FRite.Flock.Spend(Orb);
    Inc(Result);
  end;
end;

function TOrbRiteTests.Places: TPlaces;
begin
  SetLength(Result, Orbs.Count);
  for var i := 0 to Orbs.Count - 1 do
    Result[i] := PointAt(Orbs[i].X, Orbs[i].Y);
end;

function TOrbRiteTests.AwayFromHero(const AOrb: TOrb): Single;
begin
  Result := Distance(FCenter.X, FCenter.Y, AOrb.X, AOrb.Y);
end;

function TOrbRiteTests.OrbsAt(AX, AY: Single): Integer;
begin
  Result := 0;
  for var Orb in Orbs do
    if IsNear(Orb.X, Orb.Y, AX, AY) then
      Inc(Result);
end;

function TOrbRiteTests.IsOnGridSeat(const AOrb: TOrb): Boolean;
begin
  Result := False;
  for var Wave := 0 to PatternWaves - 1 do
    for var Number := 0 to GridPerWave - 1 do
    begin
      var Seat := GridSeat(Wave, Number, GridPerWave, 0);
      if IsNear(AOrb.X, AOrb.Y, FCenter.X + Seat.X, FCenter.Y + Seat.Y) then
        Exit(True);
    end;
end;

procedure TOrbRiteTests.ExpectGridFull(const AWhen: string);
begin
  Assert.AreEqual(GridOrbs, Orbs.Count, AWhen + ': orbs in the flock');
  for var Wave := 0 to PatternWaves - 1 do
    for var Number := 0 to GridPerWave - 1 do
    begin
      var Seat := GridSeat(Wave, Number, GridPerWave, 0);
      Assert.AreEqual(1, OrbsAt(FCenter.X + Seat.X, FCenter.Y + Seat.Y),
        Format('%s: orbs in seat %d of wave %d', [AWhen, Number, Wave]));
    end;
end;

function TOrbRiteTests.BodyPointUnder(const AOrb: TOrb): Integer;
begin
  Result := -1;
  for var i := 0 to High(BodyOffsets) do
    if IsNear(AOrb.X, AOrb.Y, FCenter.X + BodyOffsets[i].X,
      FCenter.Y + BodyOffsets[i].Y) then
      Exit(i);
end;

function TOrbRiteTests.OrbsOnBody: Integer;
begin
  Result := 0;
  for var Orb in Orbs do
    if BodyPointUnder(Orb) >= 0 then
      Inc(Result);
end;

procedure TOrbRiteTests.ExpectTold(const AEvents: array of TRiteEvent;
  const AWhat: string);
begin
  Assert.AreEqual(Integer(Length(AEvents)), FTold.Count,
    AWhat + ': things told');
  for var i := 0 to High(AEvents) do
    Assert.AreEqual<TRiteEvent>(AEvents[i], FTold[i],
      Format('%s: told as number %d', [AWhat, i]));
end;

function TOrbRiteTests.RingReach(const AOrb: TOrb): Single;
begin
  var AcrossShare: Single := (AOrb.X - FCenter.X) / RingAcross;
  var UprightShare: Single := (AOrb.Y - FCenter.Y) / RingUpright;
  Result := Sqrt(Sqr(AcrossShare) + Sqr(UprightShare));
end;

function TOrbRiteTests.RingTurn(const AOrb: TOrb): Single;
begin
  var AcrossShare: Single := (AOrb.X - FCenter.X) / RingAcross;
  var UprightShare: Single := (AOrb.Y - FCenter.Y) / RingUpright;
  Result := ArcTan2(UprightShare, AcrossShare);
end;

procedure TOrbRiteTests.ExpectOnRing(const AWhen: string);
begin
  for var Orb in Orbs do
  begin
    if Orb.State <> osAlive then
      Continue;
    Assert.IsTrue(Abs(RingReach(Orb) - 1) < RingSlack,
      Format('%s: an orb stands at %g of the oval about the hero',
      [AWhen, RingReach(Orb)]));
  end;
end;

function TOrbRiteTests.RingGaps: TArray<Single>;
begin
  var Turns: TArray<Single> := nil;
  for var Orb in Orbs do
    if Orb.State = osAlive then
      Turns := Turns + [RingTurn(Orb)];
  Assert.IsTrue(Length(Turns) > 1, 'A ring is two orbs at the least');
  TArray.Sort<Single>(Turns);

  SetLength(Result, Length(Turns));
  for var i := 0 to High(Turns) - 1 do
    Result[i] := Turns[i + 1] - Turns[i];
  // And round from the last to the first
  Result[High(Result)] := Turns[0] + 2 * Pi - Turns[High(Turns)];
  TArray.Sort<Single>(Result);
end;

procedure TOrbRiteTests.ExpectSameAsTwin(ATick: Integer);
begin
  var Mine := Orbs;
  var Twins := FTwin.Flock.Orbs;
  Assert.AreEqual(Mine.Count, Twins.Count,
    Format('Orbs of the twin on tick %d', [ATick]));
  for var i := 0 to Mine.Count - 1 do
  begin
    var IsSamePlace := (Mine[i].X = Twins[i].X) and (Mine[i].Y = Twins[i].Y);
    var IsSameLook := (Mine[i].Size = Twins[i].Size) and
      (Mine[i].Level = Twins[i].Level) and (Mine[i].Depth = Twins[i].Depth);
    var IsSameState := (Mine[i].Armed = Twins[i].Armed) and
      (Mine[i].State = Twins[i].State);
    Assert.IsTrue(IsSamePlace and IsSameLook and IsSameState,
      Format('Orb %d of the twin differs on tick %d', [i, ATick]));
  end;
end;

// ---------------------------------------------------------------------------
// The schedule and the gathering
// ---------------------------------------------------------------------------

procedure TOrbRiteTests.TestNewRiteIsIdleAndEmpty;
begin
  Assert.AreEqual<TRiteStage>(rsIdle, FRite.Stage, 'A new rite');
  Assert.AreEqual(0, Orbs.Count, 'A new rite has no orbs');
  Assert.AreEqual<TRiteEvent>(reNone, FRite.DrainEvent, 'and nothing to tell');

  Run(10);
  Assert.AreEqual<TRiteStage>(rsIdle, FRite.Stage, 'Ticks start nothing');
  Assert.AreEqual(0, Orbs.Count, 'Ticks bring no orbs');
  Assert.AreEqual(0, FTold.Count, 'and nothing is told');
end;

procedure TOrbRiteTests.TestEventsComeByTheScoresSchedule;
const
  // The ticks of WholeRite by the bench score
  Ticks: array [0..8] of Integer = (0, 10, 20, 40, 50, 60, 60, 72, 81);
begin
  Start(GridPattern, BenchScore);
  Run(BenchFinish + QuietTicks);

  ExpectTold(WholeRite, 'A whole rite');
  for var i := 0 to High(Ticks) do
    Assert.AreEqual(Ticks[i], FToldAt[i],
      Format('The tick of what was told as number %d', [i]));
end;

procedure TOrbRiteTests.TestStageFollowsTheSchedule;
begin
  Start(GridPattern, BenchScore);
  Assert.AreEqual<TRiteStage>(rsGathering, FRite.Stage,
    'A rite just started');

  for var i := 0 to BenchFinish do
  begin
    Tick;
    Assert.AreEqual<TRiteStage>(BenchStageAfter(i), FRite.Stage,
      Format('After tick %d', [i]));
  end;
end;

procedure TOrbRiteTests.ExpectIceRiteRunsToTheSuit(const AName: string);
begin
  Start(FindPattern(AName), IceRiteScore);
  var PausedAt := -1;
  var FinishedAt := -1;
  for var i := 0 to IceFinish + QuietTicks do
  begin
    var Told := Tick;
    if reFinished in Told then
      FinishedAt := i;
    if not (rePaused in Told) then
      Continue;
    PausedAt := i;
    Assert.AreEqual(IceOrbs, Orbs.Count, AName + ': orbs at the pause');
    Assert.AreEqual(0, ArmedCount, AName + ': armed orbs at the pause');
  end;

  ExpectTold(WholeRite, AName);
  // The mercy the ceremony grants at the pause runs out as the suit goes on
  Assert.AreEqual(IceRiteScore.HoverTicks + IceRiteScore.CollapseTicks,
    FinishedAt - PausedAt, AName + ': ticks from the pause to the suit');
end;

procedure TOrbRiteTests.TestGamePatternsRunTheIceRiteToTheSuit;
begin
  ExpectIceRiteRunsToTheSuit(DefaultPatternName);
  ExpectIceRiteRunsToTheSuit('vortex');
end;

procedure TOrbRiteTests.TestEveryWaveBringsItsCountOfOrbs;
begin
  Start(GridPattern, BenchScore);
  Assert.AreEqual(0, Orbs.Count, 'No orb before the first tick');

  // Born[0] - before any wave is called, Born[1] - after the first call
  var Born: TArray<Integer>;
  SetLength(Born, PatternWaves + 1);
  var Calls := 0;
  for var i := 0 to BenchPause do
  begin
    if reWaveCalled in Tick then
      Inc(Calls);
    if Calls > PatternWaves then
      Assert.Fail('More waves were called than a pattern has');
    Inc(Born[Calls], NewbornCount);
  end;

  Assert.AreEqual(0, Born[0], 'Orbs born before a wave was called');
  for var Wave := 1 to PatternWaves do
    Assert.AreEqual(GridPerWave, Born[Wave],
      Format('Orbs born of wave %d', [Wave]));
  Assert.AreEqual(GridOrbs, Orbs.Count, 'Orbs at the pause');
end;

procedure TOrbRiteTests.TestOrbsAreBornInTheMatterSmallAndUnarmed;
begin
  Start(FindPattern(DefaultPatternName), IceRiteScore);

  var Seen := 0;
  for var i := 0 to IcePause - 1 do
  begin
    Tick;
    for var Orb in Orbs do
    begin
      if Orb.Age > 0 then
        Continue;
      Inc(Seen);
      Assert.IsTrue(SolidAt(FMatter, Orb.X, Orb.Y),
        Format('An orb was born in the open, at (%g, %g)', [Orb.X, Orb.Y]));
      Assert.IsTrue(Orb.Size < NewbornSize, 'An orb was born at its size');
      Assert.IsFalse(Orb.Armed, 'An orb was born armed, inside the matter');
    end;
  end;
  Assert.AreEqual(IceOrbs, Seen, 'Orbs born');
end;

procedure TOrbRiteTests.TestOrbIsArmedOnlyOnItsWayToItsSeat;
begin
  Start(GridPattern, BenchScore);

  // Nobody is dropped before the suit: an orb keeps its place in the flock
  var WasArmed: TArray<Boolean>;
  SetLength(WasArmed, GridOrbs);
  for var i := 0 to BenchFinish do
  begin
    var Told := Tick;
    for var j := 0 to Orbs.Count - 1 do
    begin
      if Orbs[j].Armed then
        WasArmed[j] := True;
      var IsBornArmed := (Orbs[j].Age = 0) and Orbs[j].Armed;
      Assert.IsFalse(IsBornArmed, 'An orb was born armed');
    end;

    // The first wave is the first of the flock: it is born before the
    // second is called
    var IsFirstWaveSeated := (reWaveSeated in Told) and
      (FTold.Count = PatternWaves + 1);
    if IsFirstWaveSeated then
      Assert.AreEqual(0, ArmedAmongFirst(GridPerWave),
        'Armed orbs of the first wave once it is told seated');
    if i = BenchPause then
      Assert.AreEqual(GridOrbs, CountOf(WasArmed),
        'Orbs that were armed on their way');
    if i >= BenchPause then
      Assert.AreEqual(0, ArmedCount, Format('Armed orbs on tick %d', [i]));
  end;
end;

procedure TOrbRiteTests.TestPatternIsFullAtThePause;
begin
  Start(GridPattern, BenchScore);
  RunTo(BenchPause);
  ExpectGridFull('At the pause');
end;

procedure TOrbRiteTests.TestSeatedOrbTakesTheDepthOfItsSeat;
begin
  Start(GridPattern, BenchScore);
  RunTo(BenchPause + 1);

  var BackRow: Single := FCenter.Y + GridSeat(0, 0, GridPerWave, 0).Y;
  var Behind := 0;
  var InFront: TOrb := nil;
  for var Orb in Orbs do
  begin
    if Orb.Depth >= 0 then
    begin
      InFront := Orb;
      Continue;
    end;
    Inc(Behind);
    Assert.IsTrue(Abs(Orb.Y - BackRow) < PlaceSlack,
      'An orb behind the hero is not of the row behind him');
  end;
  Assert.AreEqual(GridPerWave, Behind, 'Orbs behind the hero');
  Assert.IsTrue(Assigned(InFront), 'No orb is in front of the hero');

  // The seats burn alike: what differs is the depth
  for var Orb in Orbs do
  begin
    if Orb.Depth >= 0 then
      Continue;
    var IsFarther := (Orb.Size < InFront.Size) and (Orb.Level < InFront.Level);
    Assert.IsTrue(IsFarther,
      'An orb behind the hero is as big or as bright as one in front');
  end;
end;

procedure TOrbRiteTests.TestMiddleWaveTurnsAgainstTheOthers;
begin
  Start(GridPattern, BenchScore);

  // By the wave: the turn about the hero its orbs have made in flight
  var Turned: TArray<Single>;
  SetLength(Turned, PatternWaves);
  var Before: TPlaces;
  SetLength(Before, GridOrbs);
  for var i := 0 to BenchPause - 1 do
  begin
    Tick;
    for var j := 0 to Orbs.Count - 1 do
    begin
      var Orb := Orbs[j];
      var Here := PointAt(Orb.X, Orb.Y);
      var IsTurning := Orb.Armed and (AwayFromHero(Orb) > FarFromHero);
      if IsTurning then
        Turned[j div GridPerWave] := Turned[j div GridPerWave] +
          TurnBetween(FCenter, Before[j], Here);
      Before[j] := Here;
    end;
  end;

  var IsMiddleAgainst := (Turned[0] * Turned[1] < 0) and
    (Turned[1] * Turned[2] < 0);
  Assert.IsTrue(IsMiddleAgainst,
    Format('The waves turned %g, %g and %g radians about the hero',
    [Turned[0], Turned[1], Turned[2]]));
end;

procedure TOrbRiteTests.TestPatternGathersAboutAWalkingHero;
const
  WalkFromX = 150;
begin
  FCenter := PointAt(WalkFromX, StandY);
  Start(GridPattern, BenchScore);

  for var i := 0 to BenchPause do
  begin
    Walk(WalkStep, 0);
    Tick;
  end;
  ExpectGridFull('About a hero who walked through the gathering');
end;

procedure TOrbRiteTests.TestSeatedPatternKeepsToTheHeroWhateverHisStep;
const
  // A walk, an ice jump and the return from a pit
  Steps: array [0..6] of TSdlFPoint = ((X: 2; Y: 0), (X: 2; Y: 0),
    (X: 2; Y: 0), (X: 10; Y: -10), (X: 10; Y: -10), (X: 10; Y: -10),
    (X: -200; Y: 0));
begin
  Start(GridPattern, BenchScore);
  RunTo(BenchPause);

  for var Step in Steps do
  begin
    Walk(Step.X, Step.Y);
    Tick;
    ExpectGridFull(Format('After a step of (%g, %g)', [Step.X, Step.Y]));
  end;
end;

procedure TOrbRiteTests.TestLeapDoesNotThrowFlyingOrbs;
begin
  Start(GridPattern, IceRiteScore);
  // Late in the flight of the first wave: a flight half flown is the one
  // a leap would throw
  Run(IceRiteScore.WaveSpan * 3 div 4);
  var Was := Places;
  var WasArmed: TArray<Boolean>;
  SetLength(WasArmed, Orbs.Count);
  for var i := 0 to Orbs.Count - 1 do
    WasArmed[i] := Orbs[i].Armed;
  Assert.IsTrue(CountOf(WasArmed) > 0, 'Nobody is in flight as the hero leaps');

  Walk(LeapX, LeapY);
  Tick;
  var Leap := Distance(0, 0, LeapX, LeapY);
  for var i := 0 to High(Was) do
  begin
    if not WasArmed[i] then
      Continue;
    var Moved := Distance(Was[i].X, Was[i].Y, Orbs[i].X, Orbs[i].Y);
    Assert.IsTrue(Moved < Leap / 4,
      Format('A flying orb was thrown %g units with the hero', [Moved]));
  end;

  RunTo(IcePause);
  ExpectGridFull('At the pause after a leap');
end;

procedure TOrbRiteTests.TestPauseSeatsWhoeverIsStillInFlight;
begin
  Start(GridPattern, BenchScore);
  Run(BenchPause - 3);
  Assert.IsTrue(ArmedCount > 0, 'Nobody is in flight three ticks off the pause');

  // A leap this late starts the flights over: they are due past the pause
  Walk(LeapX, LeapY);
  RunTo(BenchPause);
  Assert.AreEqual(0, ArmedCount, 'Armed orbs at the pause');
  ExpectGridFull('At the pause after a late leap');
end;

procedure TOrbRiteTests.TestRiteInAnEmptyRoomStillFillsItsPattern;
begin
  FMatter := EmptyMatter;
  Start(GridPattern, BenchScore);
  RunTo(BenchPause);
  ExpectGridFull('In a room with no matter');
end;

// ---------------------------------------------------------------------------
// Stand-ins
// ---------------------------------------------------------------------------

procedure TOrbRiteTests.TestOrbStruckInFlightIsReplaced;
const
  StrikeTicks: array [0..3] of Integer = (15, 30, 45, 52);
  StruckAtOnce = 3;
begin
  Start(GridPattern, BenchScore);

  for var i := 0 to SettledTick do
  begin
    Tick;
    Assert.IsTrue(Orbs.Count <= GridOrbs, 'More orbs than seats');
    if not IsAmong(i, StrikeTicks) then
      Continue;
    Assert.IsTrue(StrikeArmed(StruckAtOnce) > 0,
      Format('Nobody is in flight to strike on tick %d', [i]));
  end;
  ExpectGridFull('After losses in flight');
end;

procedure TOrbRiteTests.TestStandInComesOutOfTheFaceOfTheStruck;
const
  // Every wave is born by now, and the pause is far off
  StrikeTick = 30;
  StruckCount = 4;
begin
  Start(GridPattern, BenchScore);

  // Where each orb was born, by its place in the flock: nobody is dropped
  // yet
  var BornAt: TPlaces := nil;
  for var i := 0 to StrikeTick do
  begin
    Tick;
    for var Orb in Orbs do
      if Orb.Age = 0 then
        BornAt := BornAt + [PointAt(Orb.X, Orb.Y)];
  end;
  Assert.AreEqual(GridOrbs, Integer(Length(BornAt)),
    'Orbs born before the strike');

  var Faces: TPlaces := nil;
  for var i := 0 to Orbs.Count - 1 do
  begin
    var IsStruck := Orbs[i].Armed and (Length(Faces) < StruckCount);
    if not IsStruck then
      Continue;
    Faces := Faces + [BornAt[i]];
    FRite.Flock.Spend(Orbs[i]);
  end;
  Assert.AreEqual(StruckCount, Integer(Length(Faces)), 'Orbs struck in flight');

  var Reborn: TArray<Boolean>;
  SetLength(Reborn, StruckCount);
  for var i := StrikeTick + 1 to BenchScore.WaveSpan - 1 do
  begin
    Tick;
    for var Orb in Orbs do
    begin
      if Orb.Age > 0 then
        Continue;
      var Face := PlaceUnder(Faces, Orb.X, Orb.Y);
      Assert.IsTrue(Face >= 0,
        'A stand-in was born away from the faces of the struck');
      Assert.IsFalse(Reborn[Face], 'One face gave two stand-ins');
      Reborn[Face] := True;
    end;
  end;
  Assert.AreEqual(StruckCount, CountOf(Reborn), 'Stand-ins born');
end;

procedure TOrbRiteTests.TestArmedStandInsAreNoMoreThanTheStock;
begin
  Start(GridPattern, BenchScore);

  var Struck := 0;
  for var i := 0 to BenchFinish do
  begin
    Tick;
    Inc(Struck, StrikeArmed(MaxInt));
    if i = SettledTick then
      ExpectGridFull('With every orb in flight struck down');
  end;
  Assert.AreEqual(GridOrbs + BenchScore.StandIns, Struck,
    'Strikes of a whole rite');
end;

procedure TOrbRiteTests.TestLateStandInThickensAtItsSeatUnarmed;
const
  // A few ticks off the pause: too late for a flight
  LateStrikeTick = 55;
begin
  Start(GridPattern, BenchScore);
  RunTo(LateStrikeTick);
  var Struck := StrikeArmed(MaxInt);
  Assert.IsTrue(Struck > 0, 'Nobody is in flight a few ticks off the pause');

  var Born := 0;
  for var i := LateStrikeTick + 1 to BenchCollapse - 1 do
  begin
    Tick;
    Assert.AreEqual(0, ArmedCount, Format('Armed orbs on tick %d', [i]));
    for var Orb in Orbs do
    begin
      if Orb.Age > 0 then
        Continue;
      Inc(Born);
      Assert.IsTrue(Orb.Size < NewbornSize,
        'A late stand-in was born at its size');
      Assert.IsTrue(IsOnGridSeat(Orb), 'A late stand-in was born off its seat');
    end;
  end;
  Assert.AreEqual(Struck, Born, 'Stand-ins born');
  ExpectGridFull('Before the collapse');
end;

// ---------------------------------------------------------------------------
// The hover and the drawing in
// ---------------------------------------------------------------------------

procedure TOrbRiteTests.TestPatternClockQuickensThenStandsStillAndFlashes;
const
  // Of a tick of the clock before the pause: the quickest the hover gets
  // is over this, and its last tick is under that
  QuickenedShare = 1.3;
  StillShare = 0.1;
  // The flash makes an orb bigger by this share at the least
  FlashShare = 1.05;
  StepSlack = 0.0001; // units
begin
  Start(ClockPattern, IceRiteScore);
  RunTo(IcePause - 1);
  // An orb of the first wave: long in its seat, and the hero stands still
  var Orb := Orbs[0];
  var Before: Single := Orb.Y;
  Tick;
  var EvenStep: Single := Orb.Y - Before;
  var QuietSize: Single := Orb.Size;
  Assert.IsTrue(EvenStep > 0, 'The clock stands still before the pause');

  // The rest of the hover, tick by tick: how far the clock went and how
  // big the orb was
  var Steps: TArray<Single>;
  var Sizes: TArray<Single>;
  SetLength(Steps, IceRiteScore.HoverTicks - 1);
  SetLength(Sizes, Length(Steps));
  for var i := 0 to High(Steps) do
  begin
    Before := Orb.Y;
    Tick;
    Steps[i] := Orb.Y - Before;
    Sizes[i] := Orb.Size;
  end;

  var Quickest: Single := 0;
  var Biggest := 0;
  for var i := 0 to High(Steps) do
  begin
    if Steps[i] > Quickest then
      Quickest := Steps[i];
    if Sizes[i] > Sizes[Biggest] then
      Biggest := i;
  end;
  Assert.IsTrue(Quickest > QuickenedShare * EvenStep,
    Format('The clock is at most %g times quicker in the hover',
    [Quickest / EvenStep]));
  Assert.IsTrue(Steps[High(Steps)] < StillShare * EvenStep,
    Format('The clock still goes %g of a tick as the collapse begins',
    [Steps[High(Steps)] / EvenStep]));

  var FreezeFrom: Integer := Length(Steps) - IceRiteScore.FreezeTicks;
  for var i := FreezeFrom + 2 to High(Steps) do
    Assert.IsTrue(Steps[i] <= Steps[i - 1] + StepSlack,
      Format('The clock quickens again %d ticks into the freeze',
      [i - FreezeFrom]));
  Assert.IsTrue(Biggest >= FreezeFrom, 'The flash is not of the freeze');
  Assert.IsTrue(Sizes[Biggest] > FlashShare * QuietSize,
    Format('The flash makes an orb %g times bigger',
    [Sizes[Biggest] / QuietSize]));
end;

procedure TOrbRiteTests.TestOrbsDrawIntoTheBodyAndStayUntilTheSuit;
begin
  Start(GridPattern, BenchScore);
  RunTo(BenchCollapse - 1);

  for var i := BenchCollapse to BenchFinish - 1 do
  begin
    Tick;
    Assert.AreEqual(GridOrbs, AliveCount,
      Format('Orbs alive on tick %d: one that has gone in stays', [i]));
    Assert.AreEqual(0, ArmedCount, Format('Armed orbs on tick %d', [i]));
  end;

  Assert.IsTrue(reFinished in Tick, 'The suit does not come by the score');
  Assert.AreEqual(GridOrbs, Orbs.Count, 'Orbs on the tick of the suit');
  var Used: TArray<Boolean>;
  SetLength(Used, Length(BodyOffsets));
  for var Orb in Orbs do
  begin
    Assert.AreEqual<TOrbState>(osGone, Orb.State,
      'An orb is not let go with the suit');
    var Point := BodyPointUnder(Orb);
    Assert.IsTrue(Point >= 0,
      Format('An orb ended off the body, at (%g, %g) from its middle',
      [Orb.X - FCenter.X, Orb.Y - FCenter.Y]));
    Used[Point] := True;
  end;
  Assert.IsTrue(CountOf(Used) > 1, 'Every orb went in at one point');

  Tick;
  Assert.AreEqual(0, Orbs.Count, 'Orbs a tick after the suit');
  Assert.AreEqual<TRiteStage>(rsIdle, FRite.Stage, 'A rite that is through');
end;

procedure TOrbRiteTests.TestOrbsDrawInOutOfStep;
const
  // The orbs come into the body on at least this many different ticks
  LeastArrivalTicks = 5;
begin
  Start(GridPattern, IceRiteScore);
  RunTo(IceCollapse - 1);

  var Arrived := 0;
  var ArrivalTicks := 0;
  for var i := IceCollapse to IceFinish do
  begin
    Tick;
    var OnBody := OrbsOnBody;
    Assert.IsTrue(OnBody >= Arrived, 'An orb left the body');
    if OnBody > Arrived then
      Inc(ArrivalTicks);
    Arrived := OnBody;
  end;
  Assert.AreEqual(GridOrbs, Arrived, 'Orbs in the body by the suit');
  Assert.IsTrue(ArrivalTicks >= LeastArrivalTicks,
    Format('The orbs came into the body on %d ticks', [ArrivalTicks]));
end;

procedure TOrbRiteTests.TestBodyIsAskedOnceAsTheCollapseBegins;
begin
  Start(GridPattern, BenchScore);
  RunTo(BenchCollapse - 1);
  Assert.AreEqual(0, FAsked, 'The body was asked for before the collapse');

  Tick;
  Assert.AreEqual(1, FAsked, 'The body is asked for as the collapse begins');

  RunTo(BenchFinish + 5);
  Assert.AreEqual(1, FAsked, 'The body was asked for again');
end;

procedure TOrbRiteTests.TestLightsOnTheBodyRideWithTheHero;
begin
  Start(GridPattern, BenchScore);
  RunTo(BenchCollapse - 1);

  for var i := BenchCollapse to BenchFinish do
  begin
    Walk(WalkStep, 0);
    Tick;
  end;
  // The points of the body as they were asked for, where he is now
  Assert.AreEqual(GridOrbs, OrbsOnBody,
    'Orbs on the body of a hero who walked through the collapse');
end;

procedure TOrbRiteTests.ExpectAllGoInAtTheChest(const AWhat: string);
begin
  Start(GridPattern, BenchScore);
  RunTo(BenchFinish);

  Assert.AreEqual(GridOrbs, Orbs.Count, AWhat + ': orbs on the tick of the suit');
  var First := Orbs[0];
  Assert.IsTrue(AwayFromHero(First) < ChestReach,
    Format('%s: the orbs went in %g units from the middle of the body',
    [AWhat, AwayFromHero(First)]));
  for var Orb in Orbs do
    Assert.IsTrue(IsNear(Orb.X, Orb.Y, First.X, First.Y),
      AWhat + ': the orbs went in at more than one point');
end;

procedure TOrbRiteTests.TestWithNoBodyEveryOrbGoesInAtTheChest;
begin
  RemakeRite(nil);
  ExpectAllGoInAtTheChest('No one to ask for the body');

  RemakeRite(NoBody);
  ExpectAllGoInAtTheChest('A body of no points');
end;

// ---------------------------------------------------------------------------
// Death, restart, doors
// ---------------------------------------------------------------------------

procedure TOrbRiteTests.TestCollapseImplodesEveryOrbAndTellsNoFinish;
begin
  Start(GridPattern, BenchScore);
  Run(25);
  Assert.IsTrue(Orbs.Count > 0, 'No orb is there to die with the hero');
  FTold.Clear;
  FToldAt.Clear;

  FRite.Collapse;
  Assert.AreEqual<TRiteStage>(rsIdle, FRite.Stage, 'A rite over a dead hero');
  for var Orb in Orbs do
    Assert.AreEqual<TOrbState>(osImploding, Orb.State);

  for var i := 0 to BenchFinish + QuietTicks do
  begin
    Tick;
    Assert.AreEqual(0, NewbornCount, 'An orb was born over the dead hero');
    if i = LongestGoodbye then
      Assert.AreEqual(0, Orbs.Count, 'Orbs a second after his death');
  end;
  Assert.AreEqual(0, FTold.Count, 'A rite cut short tells nothing more');
end;

procedure TOrbRiteTests.TestClearLeavesNothingAndNothingComes;
begin
  Start(GridPattern, BenchScore);
  RunUnheard(2);

  FRite.Clear;
  Assert.AreEqual(0, Orbs.Count, 'Orbs of a cleared rite');
  Assert.AreEqual<TRiteStage>(rsIdle, FRite.Stage, 'A cleared rite');
  Assert.AreEqual<TRiteEvent>(reNone, FRite.DrainEvent,
    'A cleared rite keeps what it had to tell');

  Run(BenchFinish + QuietTicks);
  Assert.AreEqual(0, Orbs.Count, 'The unborn of a cleared rite were born');
  Assert.AreEqual(0, FTold.Count, 'A cleared rite went on telling');
end;

procedure TOrbRiteTests.TestStartDropsTheRiteAlreadyGoing;
const
  UpToThePause: array [0..6] of TRiteEvent = (reWaveCalled, reWaveCalled,
    reWaveCalled, reWaveSeated, reWaveSeated, reWaveSeated, rePaused);
begin
  Start(GridPattern, BenchScore);
  RunUnheard(30);

  Start(GridPattern, BenchScore);
  Assert.AreEqual(0, Orbs.Count, 'Orbs of the rite that was dropped');
  Assert.AreEqual<TRiteEvent>(reNone, FRite.DrainEvent,
    'The dropped rite is still heard');

  RunTo(BenchPause);
  ExpectGridFull('At the pause of the second rite');
  ExpectTold(UpToThePause, 'The second rite');
end;

procedure TOrbRiteTests.TestShedAndRiteDropEachOther;
begin
  Start(GridPattern, BenchScore);
  RunUnheard(30);

  Shed(BenchScore);
  Assert.AreEqual<TRiteStage>(rsShedding, FRite.Stage, 'A suit shed');
  Assert.AreEqual(BenchScore.ShedOrbs, Orbs.Count,
    'Orbs once the shed has dropped the rite');
  Run(10);
  Assert.AreEqual(0, FTold.Count, 'The dropped rite is still heard');
  Assert.AreEqual(BenchScore.ShedOrbs, Orbs.Count, 'Orbs of the ring');

  Start(GridPattern, BenchScore);
  Assert.AreEqual(0, Orbs.Count, 'Orbs of the ring a rite has dropped');
  Assert.AreEqual<TRiteStage>(rsGathering, FRite.Stage, 'A rite begun');
  RunTo(BenchPause);
  ExpectGridFull('At the pause of a rite begun over a ring');
end;

procedure TOrbRiteTests.TestCarryTakesTheGatheringThroughADoor;
begin
  Start(GridPattern, BenchScore);
  Tick;
  var Was := Places;
  Assert.IsTrue(Length(Was) < GridPerWave,
    'The whole first wave is born on its first tick');

  Carry(DoorStep, 0);
  Assert.AreEqual(GridPerWave, Orbs.Count,
    'Orbs behind the door: the unborn of a called wave come too');
  Assert.AreEqual(GridPerWave, ArmedCount,
    'Armed orbs behind the door: none waits on a face left behind');
  for var i := 0 to High(Was) do
    Assert.IsTrue(IsNear(Orbs[i].X, Orbs[i].Y, Was[i].X + DoorStep, Was[i].Y),
      Format('Orb %d did not cross by the step of the door', [i]));

  RunTo(BenchPause);
  ExpectGridFull('At the pause behind the door');
end;

procedure TOrbRiteTests.TestCarrySendsNobodyFlyingBack;
begin
  Start(GridPattern, BenchScore);
  Run(20);
  var Flying := ArmedCount;
  var IsMixed := (Flying > 0) and (Flying < Orbs.Count);
  Assert.IsTrue(IsMixed,
    'The orbs are not some in flight and some on their faces');

  Carry(DoorStep, 0);
  Assert.AreEqual(Orbs.Count, ArmedCount, 'Armed orbs behind the door');
  var Was := Places;
  Tick;
  for var i := 0 to High(Was) do
  begin
    var Moved := Distance(Was[i].X, Was[i].Y, Orbs[i].X, Orbs[i].Y);
    Assert.IsTrue(Moved < Abs(DoorStep) / 4,
      Format('Orb %d flew %g units on the tick behind the door', [i, Moved]));
  end;
end;

procedure TOrbRiteTests.TestCarryKeepsTheSeatedPatternAboutTheHero;
begin
  Start(GridPattern, BenchScore);
  RunTo(BenchPause + 2);

  Carry(DoorStep, 0);
  ExpectGridFull('Right behind the door');
  Tick;
  ExpectGridFull('A tick behind the door');
end;

// ---------------------------------------------------------------------------
// The suit shed
// ---------------------------------------------------------------------------

procedure TOrbRiteTests.TestShedBringsItsOrbsOutOfTheBodyArmed;
begin
  Shed(BenchScore);

  Assert.AreEqual<TRiteStage>(rsShedding, FRite.Stage, 'A suit shed');
  Assert.AreEqual(1, FAsked, 'The times the body was asked for');
  Assert.AreEqual(BenchScore.ShedOrbs, Orbs.Count, 'Orbs of the suit');
  var Used: TArray<Boolean>;
  SetLength(Used, Length(BodyOffsets));
  for var Orb in Orbs do
  begin
    var IsShield := (Orb.State = osAlive) and Orb.Armed;
    Assert.IsTrue(IsShield, 'An orb of the suit comes out unarmed');
    var Point := BodyPointUnder(Orb);
    Assert.IsTrue(Point >= 0, 'An orb of the suit comes out off the body');
    Used[Point] := True;
  end;
  Assert.IsTrue(CountOf(Used) > 1, 'Every orb came out of one point');
end;

procedure TOrbRiteTests.TestShedWithNoBodyComesOutOfTheChest;
begin
  RemakeRite(nil);
  Shed(BenchScore);

  var First := Orbs[0];
  Assert.IsTrue(AwayFromHero(First) < ChestReach,
    Format('The orbs came out %g units from the middle of the body',
    [AwayFromHero(First)]));
  for var Orb in Orbs do
    Assert.IsTrue(IsNear(Orb.X, Orb.Y, First.X, First.Y),
      'The orbs came out of more than one point');
end;

procedure TOrbRiteTests.TestIceShedStandsInAnEvenRingOfSeventyTwo;
begin
  Shed(IceRiteScore);
  Assert.AreEqual(IceOrbs, Orbs.Count, 'Orbs of the ice suit');

  Run(FormedTicks);
  Assert.AreEqual(IceOrbs, AliveCount, 'Orbs of the ring');
  ExpectOnRing('Half a second after the shed');
  var Even: Single := 2 * Pi / IceOrbs;
  for var Gap in RingGaps do
    Assert.IsTrue(Abs(Gap - Even) < Even * GapSlack,
      Format('A gap of the ring is %g of an even one', [Gap / Even]));
  for var Orb in Orbs do
  begin
    var IsFull := (Orb.Size > 1 - PlaceSlack) and (Orb.Level > 1 - PlaceSlack);
    Assert.IsTrue(IsFull, 'An orb of the ring is not at its size and light');
  end;
end;

procedure TOrbRiteTests.TestShedRingKeepsToAWalkingHeroAndFlowsOneWay;
const
  WalkTicks = 20;
  // The ring has flowed at least this far in that time
  LeastFlow = 0.05; // radians
begin
  Shed(BenchScore);
  Run(FormedTicks);
  // Nobody goes out this early: an orb keeps its place in the flock
  var Began: TArray<Single>;
  SetLength(Began, Orbs.Count);
  for var i := 0 to Orbs.Count - 1 do
    Began[i] := RingTurn(Orbs[i]);

  for var i := 1 to WalkTicks do
  begin
    Walk(WalkStep, 0);
    Tick;
    ExpectOnRing(Format('On step %d of the hero', [i]));
  end;

  var Clockwise := 0;
  var Counter := 0;
  for var i := 0 to High(Began) do
  begin
    var Flowed := Sin(RingTurn(Orbs[i]) - Began[i]);
    if Flowed > Sin(LeastFlow) then
      Inc(Clockwise);
    if Flowed < -Sin(LeastFlow) then
      Inc(Counter);
  end;
  var IsOneWay := (Clockwise = Length(Began)) or (Counter = Length(Began));
  Assert.IsTrue(IsOneWay,
    Format('%d orbs of the ring flowed one way and %d the other',
    [Clockwise, Counter]));
end;

procedure TOrbRiteTests.TestShedRingStandsItsTimeThenGoesOutOrbByOrb;
const
  // The orbs go out on at least this many different ticks
  LeastFadeTicks = 5;
begin
  Shed(BenchScore);
  for var i := 0 to BenchScore.ShedTicks - 1 do
  begin
    Tick;
    Assert.AreEqual(BenchScore.ShedOrbs, AliveCount,
      Format('Orbs of the ring on tick %d', [i]));
  end;

  var Alive := BenchScore.ShedOrbs;
  var FadeTicks := 0;
  var LastTick := BenchScore.ShedTicks + BenchScore.ShedSpread +
    LongestGoodbye;
  for var i := BenchScore.ShedTicks to LastTick do
  begin
    if Orbs.Count > 0 then
      Assert.AreEqual<TRiteStage>(rsShedding, FRite.Stage,
        Format('A ring with orbs in it, on tick %d', [i]));
    Tick;
    if AliveCount < Alive then
      Inc(FadeTicks);
    Alive := AliveCount;
  end;

  Assert.IsTrue(FadeTicks >= LeastFadeTicks,
    Format('The ring went out on %d ticks', [FadeTicks]));
  Assert.AreEqual(0, Orbs.Count, 'Orbs once the ring is out');
  Assert.AreEqual<TRiteStage>(rsIdle, FRite.Stage, 'A shed that is over');
  Assert.AreEqual(0, FTold.Count, 'A shed tells nothing');
end;

procedure TOrbRiteTests.TestShedRingIsLeftGappedAfterLosses;
const
  LostCount = 10;
  WatchedTicks = 30;
  // Of an even gap: how near the hole is to the lost and one more
  HoleSlack = 0.1;
begin
  Shed(IceRiteScore);
  Run(FormedTicks);
  // Neighbours: the orbs take their places in the order of the flock
  for var i := 0 to LostCount - 1 do
    FRite.Flock.Spend(Orbs[i]);

  for var i := 1 to WatchedTicks do
  begin
    Tick;
    Assert.AreEqual(IceOrbs - LostCount, Orbs.Count,
      Format('Orbs of the ring %d ticks after the losses', [i]));
    Assert.AreEqual(0, NewbornCount, 'A lost orb of the ring was replaced');
  end;

  var Even: Single := 2 * Pi / IceOrbs;
  var Gaps := RingGaps;
  var Hole := Gaps[High(Gaps)];
  Assert.IsTrue(Abs(Hole - (LostCount + 1) * Even) < Even * HoleSlack,
    Format('The hole of the ring is %g even gaps wide', [Hole / Even]));
  for var i := 0 to High(Gaps) - 1 do
    Assert.IsTrue(Abs(Gaps[i] - Even) < Even * GapSlack,
      Format('A gap of the ring is %g of an even one', [Gaps[i] / Even]));
end;

procedure TOrbRiteTests.TestDeathImplodesTheShedRing;
begin
  Shed(BenchScore);
  Run(10);

  FRite.Collapse;
  Assert.AreEqual<TRiteStage>(rsIdle, FRite.Stage, 'A ring over a dead hero');
  for var Orb in Orbs do
    Assert.AreEqual<TOrbState>(osImploding, Orb.State);

  Run(LongestGoodbye);
  Assert.AreEqual(0, Orbs.Count, 'Orbs a second after his death');
end;

procedure TOrbRiteTests.TestCarryTakesTheShedRingThroughADoor;
const
  DoorDrop = 32; // units
begin
  Shed(BenchScore);
  Run(FormedTicks);
  var Was := Places;

  Carry(DoorStep, DoorDrop);
  for var i := 0 to High(Was) do
    Assert.IsTrue(IsNear(Orbs[i].X, Orbs[i].Y, Was[i].X + DoorStep,
      Was[i].Y + DoorDrop),
      Format('Orb %d did not cross by the step of the door', [i]));

  Tick;
  Assert.AreEqual(BenchScore.ShedOrbs, AliveCount, 'Orbs behind the door');
  ExpectOnRing('A tick behind the door');
end;

procedure TOrbRiteTests.TestSameCallsGiveTheSameRite;
begin
  var Snowflake := FindPattern(DefaultPatternName);
  FTwin := TOrbRite.Create(IceOrbTint, BodyAboutHero);
  Start(Snowflake, IceRiteScore);
  FTwin.Start(Snowflake, IceRiteScore, FCenter, FMatter);

  for var i := 0 to IceFinish + 1 do
  begin
    Walk(1, 0);
    FTwin.Tick(FCenter);
    Tick;
    ExpectSameAsTwin(i);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TOrbRiteTests);

end.
