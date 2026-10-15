{
  Tests.Game.Trial - the open sky of the gravel trial: the pace an event
  sets, the act that shuts it, and the skyFall action of a level's events
  that opens it.

  The trial is ticked with one body holding the gate, so an act never
  ends by itself; a test that wants the act over lets the gravel of a
  batch of one fall and then ticks with nobody holding the gate. The
  events are read from JSON of the test's own; one test loads level2.json
  beside the executable for the sky of the gravel arena.

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
  Levels.Defs,
  Levels.Events;

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
  TDUnitX.RegisterTestFixture(TSkyFallEventTests);

end.
