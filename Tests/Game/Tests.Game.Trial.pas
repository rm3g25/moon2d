{
  Tests.Game.Trial - the open sky of the gravel trial: the pace an event
  sets, the act that shuts it, and the skyFall action of a level's events
  that opens it. The wave the trial may end in: one act more only when the
  trial has one, its cap of the living, its pace while it fills up and
  after a death, its herald, its count, its gate, its kills, and the
  guests that hold the gate but not the wave. The medkit of every act's
  middle, the wave's too. And what a level makes of
  it: the finale trigger, the trialDone and waveKilled conditions, the
  waveOnto and straysLeave actions, the tanks of the arena.

  The trial is ticked with one body holding the gate, so an act never
  ends by itself; a test that wants the act over lets the gravel of a
  batch of one fall and then ticks with nobody holding the gate. In the act
  of the wave the test keeps the count of the living itself: a body let
  down is alive from the next tick, and dies when the test says. The
  events are read from JSON of the test's own, the triggers from a room of
  Tests.Rooms; two tests load level2.json beside the executable for the
  gravel arena.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Game.Trial;

interface

uses
  DUnitX.TestFramework,
  Game.Trial;

type
  [TestFixture]
  TTrialSkyTests = class
  private
    FTrial: TGravelTrial;
    function SkyFallsIn(ATicks: Integer): TArray<Integer>;
    procedure DealTheOnlyGravel;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestSkyIsShutUntilOpened;
    [Test]
    procedure TestOpenSkyLetsABodyFallAtItsPace;
    [Test]
    procedure TestPaceUnderATickIsATick;
    [Test]
    procedure TestSkyOpenedAgainTakesTheNewPace;
    [Test]
    procedure TestSkyShutsWithTheAct;
    [Test]
    procedure TestSkyOfAStoppedTrialStaysShut;
    [Test]
    procedure TestSkyIsNotOpenedOutsideTheTrial;
  end;

  [TestFixture]
  TTrialWaveTests = class
  private
    FTrial: TGravelTrial;
    // The bodies of the wave alive, as the game would count them
    FAlive: Integer;
    function GoThroughGravelAct: TTrialCue;
    procedure ReachWaveAct;
    function TickWave: TTrialCue;
    function WaveSpawnsIn(ATicks: Integer): TArray<Integer>;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestWithoutFinaleTheGravelsAreTheWholeTrial;
    [Test]
    procedure TestFinaleIsOneActMore;
    [Test]
    procedure TestFinaleWithNoCapIsNoWave;
    [Test]
    procedure TestWaveFillsUpAWaveApart;
    [Test]
    procedure TestWaveNeverPassesItsCap;
    [Test]
    procedure TestDeadBodyIsReplacedAfterTheRefill;
    [Test]
    procedure TestFirstBodyOfTheWaveIsAHerald;
    [Test]
    procedure TestWaveIsNeitherGravelsNorAimed;
    [Test]
    procedure TestWaveLetsDownItsCountAndNoMore;
    [Test]
    procedure TestWaveGateWaitsForTheLastBody;
    [Test]
    procedure TestProgressOfTheWaveAct;
    [Test]
    procedure TestGuestsHoldTheGateButNotTheWave;
    [Test]
    procedure TestWaveKillsAreCountedInItsActOnly;
  end;

  [TestFixture]
  TTrialMiddleMedkitTests = class
  private
    FTrial: TGravelTrial;
    function MedkitsIn(ATicks: Integer): Integer;
    procedure KillGravels(ACount: Integer);
    procedure DealWholeBatch;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestHalfTheBatchKilledPaysAMedkit;
    [Test]
    procedure TestEveryActPaysItsMiddle;
    [Test]
    procedure TestHalfTheWaveKilledPaysAMedkit;
    [Test]
    procedure TestActOfOneHasNoMiddle;
  end;

  [TestFixture]
  TFinaleLevelTests = class
  public
    [Test]
    procedure TestFinaleIsRead;
    [Test]
    procedure TestTrialWithoutFinaleHasNone;
    [Test]
    procedure TestFinaleWithoutTrialRaises;
    [Test]
    procedure TestFinaleWithNoMonsterRaises;
    [Test]
    procedure TestFinaleWithABadCountRaises;
    [Test]
    procedure TestFinaleWithNoCapRaises;
    [Test]
    procedure TestTrialDoneAndWaveOntoAreRead;
    [Test]
    procedure TestWaveOntoAnUnknownBankRaises;
    [Test]
    procedure TestLevelTwoArenaEndsInBetoners;
    [Test]
    procedure TestWaveKilledIsRead;
    [Test]
    procedure TestStraysLeaveIsRead;
    [Test]
    procedure TestLevelTwoArenaTanksComeAtHalfTheWave;
  end;

  [TestFixture]
  TSkyFallEventTests = class
  public
    [Test]
    procedure TestSkyFallReadsItsMonsterAndPace;
    [Test]
    procedure TestSkyFallWithNoMonsterRaises;
    [Test]
    procedure TestSkyFallWithNoPaceRaises;
    [Test]
    procedure TestSkyFallNeedsAnEventThatWaitsForAnAct;
    [Test]
    procedure TestLevelTwoArenaSkyOpensInActFive;
  end;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  System.JSON,
  Game.Config,
  Levels.Defs,
  Levels.Events,
  Levels.Pads,
  Monsters.Defs,
  Tests.Rooms;

const
  // One gravel to a batch: the act is over once it is dead
  BatchOfOne = 1;
  // Bodies holding the gate: the act waits for them
  GateHeld = 1;
  GateOpen = 0;
  TicksPerSecond = 33;
  LevelTwoFile = 'level2.json';
  LevelTwoArenaScreen = 9;
  LevelTwoArenaChaosAct = 5;
  SkyBarrelId = 'skyBarrel';
  // A wave of four, two alive at once
  WaveCount = 4;
  WaveCap = 2;
  WaveAct = TrialActs + 1;
  // Long enough for any wave of the tests to fill up
  WaveWatchTicks = 300;
  // Ticks an act of the tests is given to deal its gravel
  DealTicks = 1000;
  BetonerId = 'betoner';
  TankId = 'tank';
  TankSprites = 'tank.mns';
  LevelTwoArenaFlock = 's09-strays';
  // The tanks come along the hero's row, over the floor
  LevelTwoTankRow = 10;
  LevelTwoPressBank = 's09-press-4';

procedure TTrialSkyTests.Setup;
begin
  FTrial := TGravelTrial.Create;
end;

procedure TTrialSkyTests.TearDown;
begin
  FreeAndNil(FTrial);
end;

// The ticks, counted from 1, on which the sky let a body fall
function TTrialSkyTests.SkyFallsIn(ATicks: Integer): TArray<Integer>;
begin
  Result := nil;
  for var Tick := 1 to ATicks do
    if FTrial.Tick(GateHeld).SkyFall then
      Result := Result + [Tick];
end;

// The batch of one is let down: from now on the gate is watched
procedure TTrialSkyTests.DealTheOnlyGravel;
begin
  for var i := 1 to TrialFirstWaveTicks do
    FTrial.Tick(GateHeld);
  Assert.AreEqual(BatchOfOne, FTrial.Progress.Dealt, 'The gravel is not down');
end;

procedure TTrialSkyTests.TestSkyIsShutUntilOpened;
begin
  FTrial.Start(BatchOfOne);

  Assert.AreEqual(0, Length(SkyFallsIn(10 * TicksPerSecond)),
    'A sky nobody opened let something fall');
end;

procedure TTrialSkyTests.TestOpenSkyLetsABodyFallAtItsPace;
begin
  FTrial.Start(BatchOfOne);
  FTrial.OpenSky(1);

  var Falls := SkyFallsIn(3 * TicksPerSecond);

  Assert.AreEqual(3, Length(Falls), 'Three seconds, one body a second');
  Assert.AreEqual(TicksPerSecond, Falls[0], 'The first one a whole pace on');
  Assert.AreEqual(2 * TicksPerSecond, Falls[1], 'The second');
  Assert.AreEqual(3 * TicksPerSecond, Falls[2], 'The third');
end;

procedure TTrialSkyTests.TestPaceUnderATickIsATick;
const
  Ticks = 20;
begin
  FTrial.Start(BatchOfOne);
  FTrial.OpenSky(0.001);

  Assert.AreEqual(Ticks, Length(SkyFallsIn(Ticks)),
    'A body every tick, never more');
end;

procedure TTrialSkyTests.TestSkyOpenedAgainTakesTheNewPace;
begin
  FTrial.Start(BatchOfOne);
  FTrial.OpenSky(10);
  SkyFallsIn(TicksPerSecond);
  FTrial.OpenSky(1);

  var Falls := SkyFallsIn(TicksPerSecond);

  Assert.AreEqual(1, Length(Falls), 'The new pace');
  Assert.AreEqual(TicksPerSecond, Falls[0], 'counted from the moment it is told');
end;

procedure TTrialSkyTests.TestSkyShutsWithTheAct;
begin
  FTrial.Start(BatchOfOne);
  DealTheOnlyGravel;
  // A body every tick: the tick the act ends on is one the sky would fall on
  FTrial.OpenSky(0.001);
  Assert.IsTrue(FTrial.Tick(GateHeld).SkyFall, 'The sky is not open');

  var Cue := FTrial.Tick(GateOpen);

  Assert.IsTrue(Cue.ActEnded, 'The gate did not open');
  Assert.IsFalse(Cue.SkyFall, 'The sky let a body fall on the tick it shut');
  Assert.AreEqual(0, Length(SkyFallsIn(5 * TicksPerSecond)),
    'The sky of the act stayed open into the next one');
end;

procedure TTrialSkyTests.TestSkyOfAStoppedTrialStaysShut;
begin
  FTrial.Start(BatchOfOne);
  FTrial.OpenSky(0.001);
  FTrial.Stop;
  FTrial.Start(BatchOfOne);

  Assert.AreEqual(0, Length(SkyFallsIn(5 * TicksPerSecond)),
    'The sky outlived the trial');
end;

procedure TTrialSkyTests.TestSkyIsNotOpenedOutsideTheTrial;
begin
  FTrial.OpenSky(0.001);
  FTrial.Start(BatchOfOne);

  Assert.AreEqual(0, Length(SkyFallsIn(5 * TicksPerSecond)),
    'A sky opened before the trial ran');
end;

// ---------------------------------------------------------------------------
// The wave
// ---------------------------------------------------------------------------

procedure TTrialWaveTests.Setup;
begin
  FTrial := TGravelTrial.Create;
  FAlive := 0;
end;

procedure TTrialWaveTests.TearDown;
begin
  FreeAndNil(FTrial);
end;

// The gravel of a batch of one let down, then the gate opened: the cue of
// the tick it opened on
function TTrialWaveTests.GoThroughGravelAct: TTrialCue;
begin
  var Ticks := 0;
  while FTrial.Progress.Dealt < BatchOfOne do
  begin
    FTrial.Tick(GateHeld);
    Inc(Ticks);
    Assert.IsTrue(Ticks < DealTicks, 'The gravel of the act never came');
  end;
  Result := FTrial.Tick(GateOpen);
  Assert.IsTrue(Result.ActEnded, 'The gate did not open');
end;

procedure TTrialWaveTests.ReachWaveAct;
begin
  for var i := 1 to TrialActs do
    GoThroughGravelAct;
  Assert.AreEqual(WaveAct, FTrial.Act, 'The trial is not in the act of its wave');
end;

// A body let down is alive from the next tick on
function TTrialWaveTests.TickWave: TTrialCue;
begin
  Result := FTrial.Tick(FAlive, FAlive);
  if Result.SpawnWave then
    Inc(FAlive);
end;

// The ticks, counted from 1, on which a body of the wave was let down
function TTrialWaveTests.WaveSpawnsIn(ATicks: Integer): TArray<Integer>;
begin
  Result := nil;
  for var Tick := 1 to ATicks do
    if TickWave.SpawnWave then
      Result := Result + [Tick];
end;

procedure TTrialWaveTests.TestWithoutFinaleTheGravelsAreTheWholeTrial;
begin
  FTrial.Start(BatchOfOne);
  Assert.AreEqual(TrialActs, FTrial.Acts, 'The acts of a trial with no wave');

  for var i := 1 to TrialActs - 1 do
    Assert.IsFalse(GoThroughGravelAct.Finished, 'It ended too early');
  Assert.IsTrue(GoThroughGravelAct.Finished, 'The last act of gravels ends it');
  Assert.IsFalse(FTrial.Active, 'and it runs no more');
end;

procedure TTrialWaveTests.TestFinaleIsOneActMore;
begin
  FTrial.Start(BatchOfOne, WaveCount, WaveCap);
  Assert.AreEqual(WaveAct, FTrial.Acts, 'One act more for the wave');

  for var i := 1 to TrialActs do
    Assert.IsFalse(GoThroughGravelAct.Finished,
      'The gravels ended a trial that has a wave');
  Assert.IsTrue(FTrial.Active, 'The trial goes on');
  Assert.AreEqual(WaveAct, FTrial.Act, 'into the act of its wave');
end;

procedure TTrialWaveTests.TestFinaleWithNoCapIsNoWave;
begin
  FTrial.Start(BatchOfOne, WaveCount, 0);
  Assert.AreEqual(TrialActs, FTrial.Acts, 'A wave nobody may be alive in');
  FTrial.Start(BatchOfOne, 0, WaveCap);
  Assert.AreEqual(TrialActs, FTrial.Acts, 'A wave of nobody');
end;

// The breath of the act change, then a body a wave apart until it is full
procedure TTrialWaveTests.TestWaveFillsUpAWaveApart;
begin
  FTrial.Start(BatchOfOne, WaveCount, WaveCap);
  ReachWaveAct;

  var Spawns := WaveSpawnsIn(WaveWatchTicks);

  Assert.AreEqual(WaveCap, Integer(Length(Spawns)), 'Bodies let down with nobody dying');
  Assert.AreEqual(TrialActBreakTicks, Spawns[0], 'The first after the breath');
  Assert.AreEqual(TrialActBreakTicks + TrialWaveTicks, Spawns[1],
    'The second a wave later');
end;

procedure TTrialWaveTests.TestWaveNeverPassesItsCap;
const
  Cap = 3;
  Count = 10;
begin
  FTrial.Start(BatchOfOne, Count, Cap);
  ReachWaveAct;

  for var Tick := 1 to WaveWatchTicks do
  begin
    TickWave;
    Assert.IsTrue(FAlive <= Cap, Format('%d alive on tick %d', [FAlive, Tick]));
  end;
  Assert.AreEqual(Cap, FAlive, 'The wave stands full');
end;

// Counted from the first tick the trial sees one fewer
procedure TTrialWaveTests.TestDeadBodyIsReplacedAfterTheRefill;
begin
  FTrial.Start(BatchOfOne, WaveCount, WaveCap);
  ReachWaveAct;
  WaveSpawnsIn(WaveWatchTicks);
  Assert.AreEqual(WaveCap, FAlive, 'The wave did not fill up');

  Dec(FAlive);
  var Spawns := WaveSpawnsIn(WaveWatchTicks);

  Assert.AreEqual(1, Integer(Length(Spawns)), 'One body for the one that died');
  Assert.AreEqual(TrialWaveRefillTicks, Spawns[0], 'a refill after its death');
end;

procedure TTrialWaveTests.TestFirstBodyOfTheWaveIsAHerald;
begin
  FTrial.Start(BatchOfOne, WaveCount, WaveCap);
  ReachWaveAct;

  var Heralds := 0;
  var First := True;
  for var Tick := 1 to WaveWatchTicks do
  begin
    var Cue := TickWave;
    if not Cue.SpawnWave then
      Continue;
    if Cue.Herald then
      Inc(Heralds);
    Assert.IsTrue(Cue.Herald = First, 'Only the first comes as a herald');
    First := False;
    // Every body dies at once: the whole count comes down
    FAlive := 0;
  end;
  Assert.AreEqual(1, Heralds, 'The wave has one herald');
end;

procedure TTrialWaveTests.TestWaveIsNeitherGravelsNorAimed;
begin
  FTrial.Start(BatchOfOne, WaveCount, WaveCap);
  ReachWaveAct;

  for var Tick := 1 to WaveWatchTicks do
  begin
    var Cue := TickWave;
    Assert.IsFalse(Cue.SpawnGravel, 'A gravel came in the act of the wave');
    Assert.IsFalse(Cue.MarkAimed or Cue.SpawnAimed, 'The wave was aimed');
    FAlive := 0;
  end;
end;

// Every body killed the tick after it lands: the count is the only limit,
// and the gate opens the tick after the last one
procedure TTrialWaveTests.TestWaveLetsDownItsCountAndNoMore;
begin
  FTrial.Start(BatchOfOne, WaveCount, WaveCap);
  ReachWaveAct;

  var Spawned := 0;
  var Finished := False;
  for var Tick := 1 to WaveWatchTicks do
  begin
    var Cue := FTrial.Tick(GateOpen);
    if Cue.SpawnWave then
    begin
      Inc(Spawned);
      Continue;
    end;
    if Cue.Finished then
    begin
      Assert.AreEqual(WaveCount, Spawned, 'The gate opened before the count');
      Assert.IsTrue(Cue.ActEnded, 'The last act ends with the trial');
      Finished := True;
      Break;
    end;
  end;
  Assert.IsTrue(Finished, 'The trial never finished');
  Assert.AreEqual(WaveCount, Spawned, 'The bodies of the wave');
  Assert.IsFalse(FTrial.Active, 'The trial runs no more');
end;

procedure TTrialWaveTests.TestWaveGateWaitsForTheLastBody;
begin
  FTrial.Start(BatchOfOne, WaveCap, WaveCap);
  ReachWaveAct;
  WaveSpawnsIn(WaveWatchTicks);
  Assert.AreEqual(WaveCap, FAlive, 'The whole count is down');

  for var Tick := 1 to WaveWatchTicks do
    Assert.IsFalse(TickWave.Finished, 'The trial ended over the living');
  FAlive := 1;
  Assert.IsFalse(TickWave.Finished, 'The trial ended over the last one');
  FAlive := 0;
  var Cue := TickWave;
  Assert.IsTrue(Cue.Finished, 'The last body is dead');
  Assert.IsFalse(FTrial.Active, 'and the trial with it');
end;

procedure TTrialWaveTests.TestProgressOfTheWaveAct;
begin
  FTrial.Start(BatchOfOne, WaveCount, WaveCap);
  ReachWaveAct;

  Assert.AreEqual(WaveAct, FTrial.Progress.Act, 'The act');
  Assert.AreEqual(WaveCount, FTrial.Progress.Batch, 'The batch is the count');
  Assert.AreEqual(0, FTrial.Progress.Dealt, 'Nothing let down yet');
  WaveSpawnsIn(WaveWatchTicks);
  Assert.AreEqual(WaveCap, FTrial.Progress.Dealt, 'The bodies let down');
end;

// Four guests in the room the whole act: the wave fills up all the same,
// and the trial waits for the guests once the wave is dead
procedure TTrialWaveTests.TestGuestsHoldTheGateButNotTheWave;
const
  Guests = 4;
begin
  FTrial.Start(BatchOfOne, WaveCap, WaveCap);
  ReachWaveAct;

  var Spawned := 0;
  for var Tick := 1 to WaveWatchTicks do
    if FTrial.Tick(Guests + FAlive, FAlive).SpawnWave then
    begin
      Inc(FAlive);
      Inc(Spawned);
    end;
  Assert.AreEqual(WaveCap, Spawned, 'The guests held the wave back');

  FAlive := 0;
  for var Tick := 1 to WaveWatchTicks do
    Assert.IsFalse(FTrial.Tick(Guests, 0).Finished,
      'The trial ended over the guests');
  Assert.IsTrue(FTrial.Tick(GateOpen, 0).Finished, 'The room is clear');
end;

procedure TTrialWaveTests.TestWaveKillsAreCountedInItsActOnly;
begin
  FTrial.Start(BatchOfOne, WaveCount, WaveCap);
  FTrial.NoteWaveKilled;
  ReachWaveAct;
  Assert.AreEqual(0, FTrial.Progress.WaveKilled,
    'A kill before the wave counted');

  FTrial.NoteWaveKilled;
  FTrial.NoteWaveKilled;
  Assert.AreEqual(2, FTrial.Progress.WaveKilled, 'The kills of the wave');
end;

// ---------------------------------------------------------------------------
// The medkit of the middle
// ---------------------------------------------------------------------------

const
  // Half of it is two kills; five acts of two kills stay under the fifteen
  // a medkit of its own
  BatchOfFour = 4;
  HalfOfFour = 2;
  // Enough for the medkits owed to come down, one a tick
  MedkitTicks = 5;
  // Enough for the batch of four to be dealt and an aimed one to land
  BatchTicks = 200;

procedure TTrialMiddleMedkitTests.Setup;
begin
  FTrial := TGravelTrial.Create;
end;

procedure TTrialMiddleMedkitTests.TearDown;
begin
  FreeAndNil(FTrial);
end;

function TTrialMiddleMedkitTests.MedkitsIn(ATicks: Integer): Integer;
begin
  Result := 0;
  for var Tick := 1 to ATicks do
    if FTrial.Tick(GateHeld).SpawnMedkit then
      Inc(Result);
end;

procedure TTrialMiddleMedkitTests.KillGravels(ACount: Integer);
begin
  for var i := 1 to ACount do
    FTrial.NoteGravelKilled;
end;

procedure TTrialMiddleMedkitTests.DealWholeBatch;
begin
  for var Tick := 1 to BatchTicks do
    FTrial.Tick(GateHeld);
  Assert.AreEqual(BatchOfFour, FTrial.Progress.Dealt, 'The batch is not down');
end;

procedure TTrialMiddleMedkitTests.TestHalfTheBatchKilledPaysAMedkit;
begin
  FTrial.Start(BatchOfFour);

  KillGravels(HalfOfFour - 1);
  Assert.AreEqual(0, MedkitsIn(MedkitTicks), 'Before the middle');
  KillGravels(1);
  Assert.AreEqual(1, MedkitsIn(MedkitTicks), 'At the middle');
  KillGravels(BatchOfFour - HalfOfFour);
  Assert.AreEqual(0, MedkitsIn(MedkitTicks), 'Past the middle');
end;

// Half of every act killed, the gate opened: one medkit an act
procedure TTrialMiddleMedkitTests.TestEveryActPaysItsMiddle;
begin
  FTrial.Start(BatchOfFour);

  for var Act: Integer := 1 to TrialActs do
  begin
    Assert.AreEqual(Act, FTrial.Act, 'The act');
    DealWholeBatch;
    KillGravels(HalfOfFour);
    Assert.AreEqual(1, MedkitsIn(MedkitTicks),
      Format('The middle of act %d', [Act]));
    FTrial.Tick(GateOpen);
  end;
  Assert.IsFalse(FTrial.Active, 'The trial is over');
end;

procedure TTrialMiddleMedkitTests.TestHalfTheWaveKilledPaysAMedkit;
begin
  FTrial.Start(BatchOfOne, WaveCount, WaveCap);
  for var i := 1 to TrialActs do
  begin
    for var Tick := 1 to BatchTicks do
      if FTrial.Progress.Dealt < BatchOfOne then
        FTrial.Tick(GateHeld);
    FTrial.Tick(GateOpen);
  end;
  Assert.AreEqual(WaveAct, FTrial.Act, 'The act of the wave');

  FTrial.NoteWaveKilled;
  Assert.AreEqual(0, MedkitsIn(MedkitTicks), 'Before the middle of the wave');
  FTrial.NoteWaveKilled;
  Assert.AreEqual(1, MedkitsIn(MedkitTicks), 'At the middle of the wave');
  FTrial.NoteWaveKilled;
  FTrial.NoteWaveKilled;
  Assert.AreEqual(0, MedkitsIn(MedkitTicks), 'Past it');
end;

procedure TTrialMiddleMedkitTests.TestActOfOneHasNoMiddle;
begin
  FTrial.Start(BatchOfOne);
  KillGravels(1);
  Assert.AreEqual(0, MedkitsIn(MedkitTicks), 'An act of one paid a middle');
end;

// ---------------------------------------------------------------------------
// The level
// ---------------------------------------------------------------------------

// The screen triggers of a room of one screen; AFinale is the members of
// the finale as they stand in a file, '' for a trial with none, and with
// ATrial False there is no trial at all
function FinaleLevel(const AFinale: string; ATrial: Boolean = True): TLevel;
begin
  var Members := '';
  if ATrial then
    Members := '"gravelBoss":15';
  if AFinale <> '' then
  begin
    if Members <> '' then
      Members := Members + ',';
    Members := Members + '"finale":{' + AFinale + '}';
  end;
  Result := LevelFromRows(RoomRowsOf(0, 0, 0, 0),
    '"screenTriggers":[{"screen":1,"triggers":{' + Members + '}}]');
end;

// By value, not const: an anonymous method captures them
procedure ExpectFinaleRefused(AFinale: string; ATrial: Boolean; AWhy: string);
begin
  Assert.WillRaise(
    procedure
    begin
      FinaleLevel(AFinale, ATrial).Free;
    end, ELevelError, AWhy);
end;

procedure TFinaleLevelTests.TestFinaleIsRead;
begin
  var Level := FinaleLevel('"monster":"betoner",' +
    '"count":{"normal":10,"hard":15,"wild":20},"alive":3');
  try
    var Triggers := Level.ScreenTriggers[0].Triggers;
    Assert.IsTrue(Triggers.HasFinale, 'The trial has a finale');
    Assert.AreEqual(BetonerId, Triggers.Finale.MonsterId, 'Its monster');
    Assert.AreEqual(10, Triggers.Finale.Count.ForGrade(dfNormal), 'normal');
    Assert.AreEqual(15, Triggers.Finale.Count.ForGrade(dfHard), 'hard');
    Assert.AreEqual(20, Triggers.Finale.Count.ForGrade(dfWild), 'wild');
    Assert.AreEqual(3, Triggers.Finale.Alive, 'Its cap');
  finally
    Level.Free;
  end;

  Level := FinaleLevel('"monster":"betoner","count":7,"alive":2');
  try
    var Count := Level.ScreenTriggers[0].Triggers.Finale.Count;
    Assert.AreEqual(7, Count.ForGrade(dfWild), 'One count for every grade');
  finally
    Level.Free;
  end;
end;

procedure TFinaleLevelTests.TestTrialWithoutFinaleHasNone;
begin
  var Level := FinaleLevel('');
  try
    var Triggers := Level.ScreenTriggers[0].Triggers;
    Assert.IsTrue(Triggers.HasGravelBoss, 'The trial');
    Assert.IsFalse(Triggers.HasFinale, 'ends in no wave');
  finally
    Level.Free;
  end;
end;

procedure TFinaleLevelTests.TestFinaleWithoutTrialRaises;
begin
  ExpectFinaleRefused('"monster":"betoner","count":10,"alive":3', False,
    'A finale with no trial to end');
end;

procedure TFinaleLevelTests.TestFinaleWithNoMonsterRaises;
begin
  ExpectFinaleRefused('"count":10,"alive":3', True, 'No monster');
  ExpectFinaleRefused('"monster":"","count":10,"alive":3', True,
    'An empty monster');
end;

procedure TFinaleLevelTests.TestFinaleWithABadCountRaises;
begin
  ExpectFinaleRefused('"monster":"betoner","alive":3', True, 'No count');
  ExpectFinaleRefused('"monster":"betoner","count":0,"alive":3', True,
    'A count of nobody');
  ExpectFinaleRefused('"monster":"betoner","count":"ten","alive":3', True,
    'A count that is no number');
  ExpectFinaleRefused('"monster":"betoner","count":{"hard":15},"alive":3',
    True, 'A grade with no count');
end;

procedure TFinaleLevelTests.TestFinaleWithNoCapRaises;
begin
  ExpectFinaleRefused('"monster":"betoner","count":10', True, 'No cap');
  ExpectFinaleRefused('"monster":"betoner","count":10,"alive":0', True,
    'A cap of nobody');
end;

procedure TFinaleLevelTests.TestTrialDoneAndWaveOntoAreRead;
begin
  var Json := '{"events":[{"id":"won","screen":1,"when":"trialDone",' +
    '"then":[{"action":"waveOnto","target":"balcony"}]}]}';
  var Root := TJSONObject.ParseJSONValue(Json) as TJSONObject;
  try
    var Events := ParseLevelEvents(Root, 'test');
    Assert.AreEqual<TEventCondition>(ecTrialDone, Events[0].Condition,
      'The condition');
    Assert.AreEqual<TEventActionKind>(eaWaveOnto, Events[0].Actions[0].Kind,
      'The action');
    Assert.AreEqual('balcony', Events[0].Actions[0].Target, 'Its bank');
  finally
    Root.Free;
  end;

  Assert.WillRaise(
    procedure
    begin
      var NoBank := TJSONObject.ParseJSONValue('{"events":[{"id":"w",' +
        '"screen":1,"when":"enterScreen","then":[{"action":"waveOnto"}]}]}')
        as TJSONObject;
      try
        ParseLevelEvents(NoBank, 'test');
      finally
        NoBank.Free;
      end;
    end, ELevelEventError, 'A wave onto no bank');
end;

procedure TFinaleLevelTests.TestWaveOntoAnUnknownBankRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      LevelFromRows(RoomRowsOf(0, 0, 0, 0), '"events":[{"id":"w","screen":1,' +
        '"when":"actReached","act":6,"then":[{"action":"waveOnto",' +
        '"target":"nowhere"}]}]').Free;
    end, ELevelError, 'A wave onto a bank no shelf stands in');
end;

// The betoners of the plan, onto the balconies of row 9, which sleep once
// the trial is won, sparing the hero
procedure TFinaleLevelTests.TestLevelTwoArenaEndsInBetoners;
const
  BalconyShelves = 6;
begin
  var Level := TLevel.Create;
  try
    Level.LoadFromFile(TPath.Combine(ExtractFilePath(ParamStr(0)),
      LevelTwoFile));

    var Finales := 0;
    for var Trigger in Level.ScreenTriggers do
    begin
      if not Trigger.Triggers.HasFinale then
        Continue;
      Inc(Finales);
      Assert.AreEqual(LevelTwoArenaScreen, Trigger.Screen, 'The screen');
      var Finale := Trigger.Triggers.Finale;
      Assert.AreEqual(BetonerId, Finale.MonsterId, 'Who comes');
      Assert.AreEqual(10, Finale.Count.ForGrade(dfNormal), 'normal');
      Assert.AreEqual(15, Finale.Count.ForGrade(dfHard), 'hard');
      Assert.AreEqual(20, Finale.Count.ForGrade(dfWild), 'wild');
      Assert.AreEqual(3, Finale.Alive, 'The cap');
    end;
    Assert.AreEqual(1, Finales, 'One trial ends in a wave');

    var Balconies := 0;
    for var Pad in Level.Pads do
      if Pad.Shelf.InBank(LevelTwoPressBank) then
        Inc(Balconies);
    Assert.AreEqual(BalconyShelves, Balconies, 'The balconies of row 9');

    var WaveOnto := 0;
    var EndSleeps := 0;
    for var Event in Level.Events do
      for var Action in Event.Actions do
      begin
        if Action.Kind = eaWaveOnto then
        begin
          Inc(WaveOnto);
          Assert.AreEqual(LevelTwoPressBank, Action.Target, 'Onto the balconies');
          Assert.AreEqual<TEventCondition>(ecActReached, Event.Condition,
            'when the act comes');
          Assert.AreEqual(WaveAct, Event.Act, 'of the wave');
        end;
        if Event.Condition <> ecTrialDone then
          Continue;
        Assert.AreEqual(LevelTwoArenaScreen, Event.Screen, 'The end is the arena''s');
        if (Action.Kind = eaShelvesSleep) and (Action.Target = LevelTwoPressBank) then
        begin
          Inc(EndSleeps);
          Assert.IsTrue(Action.SpareHero, 'The calm spares the hero');
        end;
      end;
    Assert.AreEqual(1, WaveOnto, 'The wave is sent onto a bank once');
    Assert.AreEqual(1, EndSleeps, 'The balconies sleep once the trial is won');
  finally
    Level.Free;
  end;
end;

function EventsOf(const AJson: string): TArray<TLevelEvent>;
begin
  var Root := TJSONObject.ParseJSONValue(AJson) as TJSONObject;
  try
    Result := ParseLevelEvents(Root, 'test');
  finally
    Root.Free;
  end;
end;

// By value, not const: an anonymous method captures it
procedure ExpectEventRefused(AJson, AWhy: string);
begin
  Assert.WillRaise(
    procedure
    begin
      EventsOf(AJson);
    end, ELevelEventError, AWhy);
end;

// AWhen is the members of the condition as they stand in a file
function TanksEvent(const AWhen: string): string;
begin
  Result := '{"events":[{"id":"tanks","screen":1,' + AWhen + ',"then":[' +
    '{"action":"bigMessage","text":"!"}]}]}';
end;

procedure TFinaleLevelTests.TestWaveKilledIsRead;
begin
  var Events := EventsOf(TanksEvent(
    '"when":"waveKilled","act":6,"part":1,"of":2'));
  Assert.AreEqual<TEventCondition>(ecWaveKilled, Events[0].Condition,
    'The condition');
  Assert.AreEqual(6, Events[0].Act, 'Its act');
  Assert.AreEqual(1, Events[0].Part, 'Its part');
  Assert.AreEqual(2, Events[0].Whole, 'of');

  ExpectEventRefused(TanksEvent('"when":"waveKilled","part":1,"of":2'),
    'No act');
  ExpectEventRefused(TanksEvent('"when":"waveKilled","act":6,"part":2,"of":2'),
    'A part of the whole');
  ExpectEventRefused(TanksEvent('"when":"waveKilled","act":6,"part":1'),
    'No whole');
end;

procedure TFinaleLevelTests.TestStraysLeaveIsRead;
begin
  var Events := EventsOf('{"events":[{"id":"away","screen":1,' +
    '"when":"trialDone","then":[{"action":"straysLeave","target":"birds"}]}]}');
  Assert.AreEqual<TEventActionKind>(eaStraysLeave, Events[0].Actions[0].Kind,
    'The action');
  Assert.AreEqual('birds', Events[0].Actions[0].Target, 'Its flock');

  ExpectEventRefused('{"events":[{"id":"away","screen":1,' +
    '"when":"trialDone","then":[{"action":"straysLeave"}]}]}', 'No flock');
end;

// Half the wave dead: a pair of tanks, one from each side, then another
// pair after it, nose to tail; the strays fly away once the trial is won
procedure TFinaleLevelTests.TestLevelTwoArenaTanksComeAtHalfTheWave;
begin
  var Level := TLevel.Create;
  try
    Level.LoadFromFile(TPath.Combine(ExtractFilePath(ParamStr(0)),
      LevelTwoFile));

    var Pairs := 0;
    var Delays: TArray<Integer> := nil;
    var Leaves := 0;
    for var Event in Level.Events do
    begin
      for var Action in Event.Actions do
        if (Action.Kind = eaStraysLeave) and (Event.Condition = ecTrialDone) then
        begin
          Inc(Leaves);
          Assert.AreEqual(LevelTwoArenaFlock, Action.Target, 'The flock');
        end;
      if Event.Condition <> ecWaveKilled then
        Continue;
      Inc(Pairs);
      Delays := Delays + [Event.DelayTicks];
      Assert.AreEqual(LevelTwoArenaScreen, Event.Screen, 'The screen');
      Assert.AreEqual(WaveAct, Event.Act, 'The act of the wave');
      Assert.AreEqual(1, Event.Part, 'Half');
      Assert.AreEqual(2, Event.Whole, 'the wave');
      var FromLeft := 0;
      var FromRight := 0;
      for var Action in Event.Actions do
      begin
        Assert.AreEqual<TEventActionKind>(eaSpawn, Action.Kind, 'A spawn');
        Assert.AreEqual(TankId, Action.Spawn.MonsterId, 'of a tank');
        Assert.AreEqual(TankSprites, Action.Spawn.SpriteList, 'its sprites');
        Assert.AreEqual(LevelTwoTankRow, Action.Spawn.Row, 'over the floor');
        if Action.Spawn.Side = lsLeft then
          Inc(FromLeft)
        else
          Inc(FromRight);
      end;
      Assert.AreEqual(1, FromLeft, 'One from the left');
      Assert.AreEqual(1, FromRight, 'one from the right');
    end;
    Assert.AreEqual(2, Pairs, 'Two pairs of tanks');
    Assert.IsTrue(Delays[0] <> Delays[1], 'The second pair follows the first');
    Assert.AreEqual(1, Leaves, 'The strays fly away once');
  finally
    Level.Free;
  end;
end;

// ---------------------------------------------------------------------------
// The sky's event
// ---------------------------------------------------------------------------

// One event of the action given, waiting for act 1 or, with AAct 0, for
// the hero to come in
function ReadOneEvent(const AAction: string; AAct: Integer): TArray<TLevelEvent>;
begin
  var When := '"when":"enterScreen"';
  if AAct > 0 then
    When := Format('"when":"actReached","act":%d', [AAct]);
  var Json := Format('{"events":[{"id":"sky","screen":1,%s,"then":[%s]}]}',
    [When, AAction]);
  var Root := TJSONObject.ParseJSONValue(Json) as TJSONObject;
  try
    Result := ParseLevelEvents(Root, 'test');
  finally
    Root.Free;
  end;
end;

// By value, not const: an anonymous method captures them
procedure ExpectRefused(AAction: string; AAct: Integer; AWhy: string);
begin
  Assert.WillRaise(
    procedure
    begin
      ReadOneEvent(AAction, AAct);
    end, ELevelEventError, AWhy);
end;

procedure TSkyFallEventTests.TestSkyFallReadsItsMonsterAndPace;
begin
  var Events := ReadOneEvent(
    '{"action":"skyFall","monster":"skyBarrel","every":2.5}', 1);

  var Action := Events[0].Actions[0];
  Assert.AreEqual<TEventActionKind>(eaSkyFall, Action.Kind);
  Assert.AreEqual(SkyBarrelId, Action.SkyFall.MonsterId, 'The monster');
  Assert.IsTrue(Abs(Action.SkyFall.EverySeconds - 2.5) < 0.0001, 'The pace');
end;

procedure TSkyFallEventTests.TestSkyFallWithNoMonsterRaises;
begin
  ExpectRefused('{"action":"skyFall","every":2}', 1, 'No monster');
  ExpectRefused('{"action":"skyFall","monster":"","every":2}', 1,
    'An empty monster');
end;

procedure TSkyFallEventTests.TestSkyFallWithNoPaceRaises;
begin
  ExpectRefused('{"action":"skyFall","monster":"skyBarrel"}', 1, 'No pace');
  ExpectRefused('{"action":"skyFall","monster":"skyBarrel","every":0}', 1,
    'A pace of nothing');
  ExpectRefused('{"action":"skyFall","monster":"skyBarrel","every":-1}', 1,
    'A pace below nothing');
end;

procedure TSkyFallEventTests.TestSkyFallNeedsAnEventThatWaitsForAnAct;
begin
  ExpectRefused('{"action":"skyFall","monster":"skyBarrel","every":2}', 0,
    'A sky with no act to shut it');
end;

// Act 5 opens the sky over the arena once; the finale has none
procedure TSkyFallEventTests.TestLevelTwoArenaSkyOpensInActFive;
begin
  var Level := TLevel.Create;
  try
    Level.LoadFromFile(TPath.Combine(ExtractFilePath(ParamStr(0)),
      LevelTwoFile));

    var Opened := 0;
    for var Event in Level.Events do
      for var Action in Event.Actions do
      begin
        if Action.Kind <> eaSkyFall then
          Continue;
        Inc(Opened);
        Assert.AreEqual(LevelTwoArenaScreen, Event.Screen, 'The screen');
        Assert.AreEqual(LevelTwoArenaChaosAct, Event.Act, 'The act');
        Assert.AreEqual(SkyBarrelId, Action.SkyFall.MonsterId, 'What falls');
      end;
    Assert.AreEqual(1, Opened, 'The sky opens once');
  finally
    Level.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTrialSkyTests);
  TDUnitX.RegisterTestFixture(TTrialWaveTests);
  TDUnitX.RegisterTestFixture(TTrialMiddleMedkitTests);
  TDUnitX.RegisterTestFixture(TFinaleLevelTests);
  TDUnitX.RegisterTestFixture(TSkyFallEventTests);

end.
