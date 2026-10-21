{
  Tests.Scenes.Director - a scene played against a world made by hand: when
  its cues play, what a wait holds up, when the scene is over, what is left
  when the hero leaves its screen, and what a death does to it - before
  its end, after it, once a level and once a life. And what its cues do to
  the bodies they tag and to the pads they name.

  The stage is a one-screen room: a craft tagged "ship", a pad tagged
  "lift", a dormant pad tagged "sleeper" (a scene of the level wakes it, or
  the level would not load), and two gravels, "prey" and "rider", which
  the test makes itself from the level's entities and puts in the field.
  The field stands over a level of no entities, so it asks the renderer
  for no art; the pads name no sprite, so the world asks for none either.
  The test ticks the world in the game's order: the director, the pads,
  then the dynamic objects.

  The director keeps hold of the sound bank, and the bank opens the
  mixer. The fixture opens it once on SDL's dummy audio driver: if the
  mixer opens, it plays to nowhere; if it does not, the bank is off and
  stays silent. Either way no scene here plays a sound, and no scene
  prints a line - there is no message board.

  What is drawn - the shade, the turn of a part, the swing of a beam - and
  the volume of the music are not seen here.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Scenes.Director;

interface

uses
  DUnitX.TestFramework,
  Audio,
  Levels.Defs,
  Levels.Dynamics,
  Monsters,
  Monsters.Defs,
  Pads.World,
  Scenes.Director;

type
  [TestFixture]
  TSceneDirectorTests = class
  private
    FAudio: TSoundBank;
    FLevel: TLevel;
    FBareLevel: TLevel;
    FPads: TPadWorld;
    FRegistry: TMonsterRegistry;
    FField: TMonsterField;
    FDirector: TSceneDirector;
    procedure UseScene(const AScene: string);
    procedure FreeStage;
    function Stage: TSceneStage;
    procedure Play(ATimes: Integer; AScreen: Integer = 1);
    function Ship: TCraft;
    function ShipX: Single;
    function ShipY: Single;
    function Body(const ATag: string): TMonster;
    function Pad(const ATag: string): TPad;
  public
    [SetupFixture]
    procedure SetupFixture;
    [TearDownFixture]
    procedure TearDownFixture;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestCueActsFromItsTickOn;
    [Test]
    procedure TestCueAfterAnotherPlaysItsDelayLater;
    [Test]
    procedure TestWaitHoldsWhatComesAfterUntilTheDeckIsEmpty;
    [Test]
    procedure TestCorpseOnTheDeckHoldsNothingUp;
    [Test]
    procedure TestSceneIsStartedByItsIdInAnyCase;
    [Test]
    procedure TestSceneThatHasPlayedDoesNotStartAgain;
    [Test]
    procedure TestLeavingMidSceneLandsItAndLeavesTheAftermath;
    [Test]
    procedure TestLeavingAfterTheEndLeavesTheWorldAlone;
    [Test]
    procedure TestDeathMidSceneTakesItBackToTheStart;
    [Test]
    procedure TestDeathAfterTheEndPutsTheAftermathOnAnyScreen;
    [Test]
    procedure TestSceneOfALifeIsRewoundByADeathOnItsScreen;
    [Test]
    procedure TestShakeRunsFromItsCueToARewind;
    [Test]
    procedure TestJoltIsOneBlowTakenOnce;
    [Test]
    procedure TestCuesActOnTheBodiesTheyTag;
    [Test]
    procedure TestSpawnStandsTheBodyItsTagNames;
    [Test]
    procedure TestSpawnLeavesADeadBodyWhereItLies;
    [Test]
    procedure TestWakeAndFlyBringTheSleepingPad;
  end;

implementation

uses
  System.IOUtils,
  System.SysUtils,
  Winapi.Windows,
  Game.Config,
  Render.Sprites,
  Tests.Rooms;

const
  SceneId = 's';
  // Where the file puts the craft's corner
  ShipFileX = 0;
  ShipFileY = -100;
  // The lift and where an aftermath flies it
  LiftX = 224;
  LiftY = 224;
  AwayX = 64;
  // The dormant pad and where a scene flies it
  SleeperX = 96;
  SleeperFlownY = 128;
  // Where the hero stands, by his middle: nothing here looks at him
  HeroX = 400;
  HeroY = 300;
  // A screen other than the scene's: the director asks no level about it
  ElsewhereScreen = 2;
  UnitSlack = 0.001;
  AftermathOfTheLift = '"aftermath":[{"do":"fly","target":"lift",' +
    '"x":64,"y":224}]';

// The scene of the test: ACues on its timeline; AExtra more members, as
// they stand in a file
function SceneJson(const ACues: string; const AExtra: string = ''): string;
begin
  Result := Format('{"id":"%s","screen":1,"cues":[%s]', [SceneId, ACues]);
  if AExtra <> '' then
    Result := Result + ',' + AExtra;
  Result := Result + '}';
end;

function StageSections(const AScene: string): string;
begin
  Result := '"pads":[' +
    '{"sprite":"","screen":1,"x":224,"y":224,"width":32,"tag":"lift"},' +
    '{"sprite":"","screen":1,"x":96,"y":224,"width":32,"tag":"sleeper",' +
    '"dormant":true}],' +
    '"dynamics":[{"kind":"craft","tag":"ship","screen":1,"body":"hull",' +
    '"width":100,"x":0,"y":-100}],' +
    '"entities":[' +
    '{"monsterId":"gravel","screen":1,"x":3,"y":11,"tag":"prey"},' +
    '{"monsterId":"gravel","screen":1,"x":12,"y":11,"tag":"rider"}],' +
    '"scenes":[' + AScene + ',' +
    '{"id":"waking","screen":1,"cues":[' +
    '{"at":0,"do":"wake","target":"sleeper"}]}]';
end;

function IsNear(AValue, AExpected: Double): Boolean;
begin
  Result := Abs(AValue - AExpected) < UnitSlack;
end;

procedure TSceneDirectorTests.SetupFixture;
begin
  SetEnvironmentVariable('SDL_AUDIODRIVER', 'dummy');
  var Home := ExtractFilePath(ParamStr(0));
  FAudio := TSoundBank.Create(TPath.Combine(Home, 'sounds'),
    TPath.Combine(Home, 'music'));
end;

procedure TSceneDirectorTests.TearDownFixture;
begin
  FreeAndNil(FAudio);
end;

procedure TSceneDirectorTests.TearDown;
begin
  FreeStage;
end;

// The director before the field, the field - which owns the bodies, and
// they lean on the level and the pads - before the pads and the levels
procedure TSceneDirectorTests.FreeStage;
begin
  FreeAndNil(FDirector);
  FreeAndNil(FField);
  FreeAndNil(FPads);
  FreeAndNil(FRegistry);
  FreeAndNil(FBareLevel);
  FreeAndNil(FLevel);
end;

procedure TSceneDirectorTests.UseScene(const AScene: string);
begin
  FreeStage;
  var Rows := RoomRowsOf(0, 0, 0, 0);
  FLevel := LevelFromRows(Rows, StageSections(AScene));
  FBareLevel := LevelFromRows(Rows, '');
  FPads := TPadWorld.Create(nil, nil, FLevel, nil, 1);
  FRegistry := TMonsterRegistry.Create;
  FRegistry.LoadFromFile(
    TPath.Combine(ExtractFilePath(ParamStr(0)), 'monsters.json'));
  FField := TMonsterField.Create(nil, FRegistry, FBareLevel, FPads, dfNormal,
    1.0);
  for var Placement in FLevel.Entities do
    FField.Monsters.Add(TMonster.Create(FRegistry.Find(Placement.MonsterId),
      Default(TAnimSet), nil, nil, FLevel, FPads, Placement, 1.0));
  FDirector := TSceneDirector.Create(FLevel.Scenes, FLevel.Dynamics, FPads,
    FAudio, nil);
end;

function TSceneDirectorTests.Stage: TSceneStage;
begin
  Result.Hero.X := HeroX;
  Result.Hero.Y := HeroY;
  Result.Field := FField;
  Result.Bullets := nil;
end;

procedure TSceneDirectorTests.Play(ATimes: Integer; AScreen: Integer);
begin
  for var i := 1 to ATimes do
  begin
    FDirector.Tick(AScreen, Stage);
    FPads.Tick(AScreen, nil);
    for var DynamicObject in FLevel.Dynamics do
      DynamicObject.Tick(0, 0, True);
  end;
end;

function TSceneDirectorTests.Ship: TCraft;
begin
  Result := FLevel.Dynamics[0] as TCraft;
end;

function TSceneDirectorTests.ShipX: Single;
begin
  Result := Ship.CornerAt(1).X;
end;

function TSceneDirectorTests.ShipY: Single;
begin
  Result := Ship.CornerAt(1).Y;
end;

function TSceneDirectorTests.Body(const ATag: string): TMonster;
begin
  Result := FField.FirstTagged(ATag);
  Assert.IsNotNull(Result, 'No body is tagged ' + ATag);
end;

function TSceneDirectorTests.Pad(const ATag: string): TPad;
begin
  Result := FPads.FindTagged(ATag);
  Assert.IsNotNull(Result, 'No pad is tagged ' + ATag);
end;

procedure TSceneDirectorTests.TestCueActsFromItsTickOn;
begin
  UseScene(SceneJson(
    '{"at":10,"do":"move","target":"ship","x":200,"ticks":20}'));
  FDirector.Start(SceneId);

  Play(10);
  Assert.IsTrue(IsNear(ShipX, ShipFileX), 'Before its tick the cue did ' +
    'something');
  Play(20);
  Assert.IsTrue(IsNear(ShipX, 200), Format('Twenty ticks into its move the ' +
    'craft is at %g', [ShipX]));
end;

procedure TSceneDirectorTests.TestCueAfterAnotherPlaysItsDelayLater;
begin
  UseScene(SceneJson(
    '{"id":"a","at":5,"do":"move","target":"ship","y":50},' +
    '{"id":"b","after":"a","do":"move","target":"ship","x":70},' +
    '{"after":"b","delay":4,"do":"move","target":"ship","x":300}'));
  FDirector.Start(SceneId);

  Play(5);
  Assert.IsTrue(IsNear(ShipY, ShipFileY) and IsNear(ShipX, ShipFileX),
    'Before tick 5');
  Play(1);
  Assert.IsTrue(IsNear(ShipY, 50), 'Tick 5: the first cue');
  Assert.IsTrue(IsNear(ShipX, 70), 'Tick 5: the cue after it with no delay ' +
    'plays on the same tick');
  Play(3);
  Assert.IsTrue(IsNear(ShipX, 70), 'Tick 8: the delay of four is not out');
  Play(1);
  Assert.IsTrue(IsNear(ShipX, 300), 'Tick 9: four after the cue it counts ' +
    'from');
end;

procedure TSceneDirectorTests.TestWaitHoldsWhatComesAfterUntilTheDeckIsEmpty;
begin
  UseScene(SceneJson(
    '{"id":"w","at":0,"do":"wait","until":"deckEmpty","target":"lift"},' +
    '{"after":"w","delay":5,"do":"move","target":"ship","x":200}'));
  Body('rider').Stand(LiftX, LiftY, False);
  FDirector.Start(SceneId);

  Play(40);
  Assert.IsTrue(IsNear(ShipX, ShipFileX),
    'A live body stands on the deck, and the cue after the wait played');

  FField.RemoveTagged('rider');
  Play(5);
  Assert.IsTrue(IsNear(ShipX, ShipFileX),
    'The cue after the wait counts from the start of the scene');
  Play(1);
  Assert.IsTrue(IsNear(ShipX, 200), 'The cue after the wait did not count ' +
    'its delay from the tick the deck was empty');
end;

procedure TSceneDirectorTests.TestCorpseOnTheDeckHoldsNothingUp;
begin
  UseScene(SceneJson(
    '{"id":"w","at":0,"do":"wait","until":"deckEmpty","target":"lift"},' +
    '{"after":"w","do":"move","target":"ship","x":200}'));
  Body('rider').Stand(LiftX, LiftY, False);
  FDirector.Start(SceneId);
  Play(5);

  FField.SmiteTagged('rider', nil);
  Play(1);

  Assert.IsTrue(IsNear(ShipX, 200),
    'A body struck down on the deck holds the pad up');
end;

procedure TSceneDirectorTests.TestSceneIsStartedByItsIdInAnyCase;
begin
  UseScene(SceneJson('{"at":0,"do":"move","target":"ship","x":200}'));

  FDirector.Start(UpperCase(SceneId));
  Play(1);

  Assert.IsTrue(IsNear(ShipX, 200),
    'An event that loads with the id in another case never plays its scene');
end;

procedure TSceneDirectorTests.TestSceneThatHasPlayedDoesNotStartAgain;
begin
  UseScene(SceneJson('{"at":0,"do":"move","target":"ship","x":200}'));
  FDirector.Start(SceneId);
  Play(3);
  Ship.Rewind;

  FDirector.Start(SceneId);
  Play(3);

  Assert.IsTrue(IsNear(ShipX, ShipFileX), 'A scene played twice in a life');
end;

procedure TSceneDirectorTests.TestLeavingMidSceneLandsItAndLeavesTheAftermath;
begin
  UseScene(SceneJson(
    '{"at":0,"do":"move","target":"ship","x":200,"ticks":50}',
    AftermathOfTheLift));
  FDirector.Start(SceneId);
  Play(20);
  Assert.IsTrue(ShipX < 200, 'Twenty ticks into a move of fifty');

  Play(1, ElsewhereScreen);

  Assert.IsTrue(IsNear(ShipX, 200), Format('The craft did not land where its ' +
    'move would have ended: at %g', [ShipX]));
  Assert.IsTrue(IsNear(Pad('lift').Left, AwayX), 'The aftermath is not put');
end;

procedure TSceneDirectorTests.TestLeavingAfterTheEndLeavesTheWorldAlone;
begin
  UseScene(SceneJson(
    '{"at":0,"do":"move","target":"ship","x":200,"ticks":50}',
    AftermathOfTheLift));
  FDirector.Start(SceneId);
  Play(60);

  Play(1, ElsewhereScreen);

  Assert.IsTrue(IsNear(Pad('lift').Left, LiftX),
    'A scene over once its longest cue has run is cut short again');
end;

procedure TSceneDirectorTests.TestDeathMidSceneTakesItBackToTheStart;
begin
  UseScene(SceneJson(
    '{"at":0,"do":"move","target":"ship","x":200,"ticks":100}',
    AftermathOfTheLift));
  FDirector.Start(SceneId);
  Play(20);
  var MidX := ShipX;
  Assert.IsTrue(MidX > ShipFileX, 'Twenty ticks into the move');

  FDirector.ReArm(1, Stage);

  Assert.IsTrue(IsNear(ShipX, ShipFileX), 'The craft is not back where the ' +
    'file puts it');
  Assert.IsTrue(IsNear(Pad('lift').Left, LiftX), 'The aftermath is put over ' +
    'a scene that never ended');
  FDirector.Start(SceneId);
  Play(20);
  Assert.IsTrue(IsNear(ShipX, MidX), 'Started again, it does not play as ' +
    'from the beginning');
end;

procedure TSceneDirectorTests.TestDeathAfterTheEndPutsTheAftermathOnAnyScreen;
begin
  UseScene(SceneJson('{"at":0,"do":"move","target":"ship","x":200}',
    '"aftermath":[{"do":"remove","target":"prey"},' +
    '{"do":"fly","target":"lift","x":64,"y":224}]'));
  FDirector.Start(SceneId);
  Play(3);

  FDirector.ReArm(ElsewhereScreen, Stage);
  Assert.IsTrue(IsNear(Pad('lift').Left, AwayX),
    'A death on another screen: the pad is not where the aftermath puts it');
  Assert.AreEqual<TMonsterLife>(mlDead, Body('prey').Life,
    'A death on another screen: the body the aftermath takes is there');

  FPads.Rewind(1);
  FDirector.ReArm(1, Stage);
  Assert.IsTrue(IsNear(Pad('lift').Left, AwayX),
    'A second death, on the scene''s screen: the aftermath is not put again');

  Ship.Rewind;
  FDirector.Start(SceneId);
  Play(3);
  Assert.IsTrue(IsNear(ShipX, ShipFileX), 'A scene of a level plays again ' +
    'after a death past its end');
end;

procedure TSceneDirectorTests.TestSceneOfALifeIsRewoundByADeathOnItsScreen;
begin
  UseScene(SceneJson('{"at":0,"do":"move","target":"ship","x":200}',
    '"once":"life",' + AftermathOfTheLift));
  FDirector.Start(SceneId);
  Play(3);

  FDirector.ReArm(ElsewhereScreen, Stage);
  Ship.Rewind;
  FDirector.Start(SceneId);
  Play(3);
  Assert.IsTrue(IsNear(ShipX, ShipFileX),
    'A death on another screen let the scene of a life play again');

  FDirector.ReArm(1, Stage);
  FDirector.Start(SceneId);
  Play(3);
  Assert.IsTrue(IsNear(ShipX, 200),
    'A death on its screen does not let it play again');
  Assert.IsTrue(IsNear(Pad('lift').Left, LiftX),
    'The scene of a life put an aftermath');
end;

procedure TSceneDirectorTests.TestShakeRunsFromItsCueToARewind;
begin
  UseScene(SceneJson(
    '{"at":3,"do":"shake","value":100},' +
    '{"at":0,"do":"move","target":"ship","x":200,"ticks":100}'));
  FDirector.Start(SceneId);

  Play(3);
  Assert.IsTrue(FDirector.Trauma = 0, 'The ground shook before the cue');
  Play(1);
  Assert.IsTrue(FDirector.Trauma > 0, 'The ground does not shake');
  FDirector.ReArm(1, Stage);
  Assert.IsTrue(FDirector.Trauma = 0, 'The ground shakes on after a death');
end;

procedure TSceneDirectorTests.TestJoltIsOneBlowTakenOnce;
begin
  UseScene(SceneJson(
    '{"at":3,"do":"jolt","value":40},' +
    '{"at":0,"do":"move","target":"ship","x":200,"ticks":100}'));
  FDirector.Start(SceneId);

  Play(3);
  Assert.IsTrue(FDirector.TakeJolt = 0, 'The blow came before its cue');
  Play(1);
  Assert.IsTrue(IsNear(FDirector.TakeJolt, 0.4), 'The blow of the cue');
  Assert.IsTrue(FDirector.TakeJolt = 0, 'Taken twice');
  Play(1);
  Assert.IsTrue(FDirector.TakeJolt = 0, 'It came again a tick later');
end;

procedure TSceneDirectorTests.TestCuesActOnTheBodiesTheyTag;
begin
  UseScene(SceneJson(
    '{"at":0,"do":"hold","target":"prey"},' +
    '{"at":2,"do":"release","target":"prey"},' +
    '{"at":4,"do":"kill","target":"rider"},' +
    '{"at":6,"do":"remove","target":"prey"}'));
  var Prey := Body('prey');
  var Rider := Body('rider');
  Prey.Dormant := True;
  FDirector.Start(SceneId);

  Play(1);
  Assert.IsTrue(Prey.Held, 'Hold: its fire is not held');
  Assert.IsFalse(Rider.Held, 'Hold: a body of another tag is held');

  Play(2);
  Assert.IsFalse(Prey.Held, 'Release: its fire is still held');
  Assert.IsFalse(Prey.Dormant, 'Release: it still sleeps');

  Play(2);
  Assert.AreEqual<TMonsterLife>(mlDying, Rider.Life, 'Kill');
  Assert.AreEqual<TMonsterEvent>(meDied, Rider.DrainEvent, 'Kill: its death');
  Assert.AreEqual<TMonsterEvent>(meNone, Rider.DrainEvent,
    'Kill: a burst or a second death');

  Play(2);
  Assert.AreEqual<TMonsterLife>(mlDead, Prey.Life, 'Remove');
  Assert.AreEqual<TMonsterEvent>(meNone, Prey.DrainEvent,
    'Remove: it tells a death');
end;

procedure TSceneDirectorTests.TestSpawnStandsTheBodyItsTagNames;
begin
  UseScene(SceneJson('{"at":0,"do":"spawn","monster":"gravel",' +
    '"tag":"rider","seat":"lift","facing":"right","asleep":true}'));
  var Count := FField.Monsters.Count;
  var Rider := Body('rider');
  FDirector.Start(SceneId);

  Play(1);

  Assert.AreEqual(Count, FField.Monsters.Count, 'A second body was born');
  Assert.IsTrue(IsNear(Rider.X, LiftX) and IsNear(Rider.Y, LiftY),
    Format('Not in the middle of the deck: at %g, %g', [Rider.X, Rider.Y]));
  Assert.IsTrue(Rider.DeckUnderFeet = Pad('lift'), 'The deck is not under it');
  Assert.IsTrue(Rider.Direction, 'It does not face right');
  Assert.IsTrue(Rider.Dormant, 'It is not asleep');
end;

procedure TSceneDirectorTests.TestSpawnLeavesADeadBodyWhereItLies;
begin
  UseScene(SceneJson('{"at":0,"do":"kill","target":"prey"},' +
    '{"at":1,"do":"spawn","monster":"gravel","tag":"prey","x":400,' +
    '"y":352}'));
  var Count := FField.Monsters.Count;
  var Prey := Body('prey');
  var StartX := Prey.X;
  FDirector.Start(SceneId);

  Play(2);

  Assert.AreEqual(Count, FField.Monsters.Count, 'A second body was born');
  Assert.AreNotEqual<TMonsterLife>(mlAlive, Prey.Life, 'The dead rose');
  Assert.IsTrue(IsNear(Prey.X, StartX), 'The dead body was moved');
end;

procedure TSceneDirectorTests.TestWakeAndFlyBringTheSleepingPad;
begin
  UseScene(SceneJson('{"at":0,"do":"wake","target":"sleeper"},' +
    '{"at":0,"do":"fly","target":"sleeper","x":96,"y":128,"ticks":20}'));
  var Sleeper := Pad('sleeper');
  Assert.IsTrue(Sleeper.Dormant, 'The file puts it to sleep');
  FDirector.Start(SceneId);

  Play(1);
  Assert.IsFalse(Sleeper.Dormant, 'Not woken');
  Assert.IsTrue(Sleeper.Flying, 'Not flying');

  Play(25);
  Assert.IsTrue(IsNear(Sleeper.Left, SleeperX) and
    IsNear(Sleeper.Top, SleeperFlownY), Format('Not where it was flown: ' +
    'at %g, %g', [Sleeper.Left, Sleeper.Top]));
end;

initialization
  TDUnitX.RegisterTestFixture(TSceneDirectorTests);

end.
