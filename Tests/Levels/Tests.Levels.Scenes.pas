{
  Tests.Levels.Scenes - the scenes of a level: what the parser makes of
  the "scenes" section (Levels.Scenes) and what the level's load turns
  down after it (Levels.Defs).

  The parser is tried on its own, over a root of JSON with the scenes of
  the test and nothing else: a cue on its timeline, a cue counted from
  another, the order the cues stand in, the aftermath, the spawn, the mark
  of an aim, and every word that does not load. The load is tried through
  a one-screen room (LevelFromRows) with the pads, the dynamic objects, the
  entities and the events a scene leans on; one test loads level1.json
  beside the executable, for the scene of the cordon.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Levels.Scenes;

interface

uses
  DUnitX.TestFramework,
  Levels.Defs;

type
  [TestFixture]
  TLevelScenesTests = class
  public
    [Test]
    procedure TestSceneComesToItsDefaults;
    [Test]
    procedure TestCueAtPlaysOnItsTick;
    [Test]
    procedure TestCueAfterCountsFromTheCueItNames;
    [Test]
    procedure TestCuesStandInTheOrderOfTheirPlan;
    [Test]
    procedure TestCueAfterLooksOnlyUp;
    [Test]
    procedure TestCueTakesAtOrAfter;
    [Test]
    procedure TestNegativeTicksRaise;
    [Test]
    procedure TestTwoOfOneIdRaise;
    [Test]
    procedure TestAftermathPlaysAtOnce;
    [Test]
    procedure TestSpawnStandsOnASeatOrAPoint;
    [Test]
    procedure TestSpawnReadsWhatItIsGiven;
    [Test]
    procedure TestAimTakesAMarkOrAPoint;
    [Test]
    procedure TestMoveReadsTheAxesItIsGiven;
    [Test]
    procedure TestFlyEasesOnlyWhenTold;
    [Test]
    procedure TestPaceReadsItsTargetAndShare;
    [Test]
    procedure TestJoltReadsItsShare;
    [Test]
    procedure TestWaitReadsItsCondition;
    [Test]
    procedure TestUnknownWordsRaise;
    [Test]
    procedure TestCueWithoutWhatItNeedsRaises;
  end;

  [TestFixture]
  TSceneLoadTests = class
  public
    [Test]
    procedure TestSceneNamesOnlyPadsItsScreenHas;
    [Test]
    procedure TestSceneNamesBodiesOfTheFileOrOfItsOwn;
    [Test]
    procedure TestDormantPadNeedsASceneThatWakesIt;
    [Test]
    procedure TestSceneNamesOnlyWhatTheDynamicsCarry;
    [Test]
    procedure TestCraftGoesBeforeWhatHangsOnIt;
    [Test]
    procedure TestSceneScreenAndItsEventMustBeThere;
    [Test]
    procedure TestCordonOfLevelOneStandsAsDecided;
  end;

implementation

uses
  System.IOUtils,
  System.JSON,
  System.SysUtils,
  Levels.Dynamics,
  Levels.Events,
  Levels.Pads,
  Levels.Scenes,
  Tests.Rooms;

const
  LevelId = 'test';
  SingleSlack = 0.001;
  // What the scene cues of a tag nobody carries try in turn
  MonsterCues: array [0..3] of string = ('hold', 'kill', 'release', 'remove');
  SceneId = 'scene';
  // The scene of the cordon, as decided: level 1, screen 9
  LevelOneFile = 'level1.json';
  CordonScene = 'cordon9';
  CordonScreen = 9;
  CordonLift = 's09-lift';
  CordonTank = 'cordonTank';
  CordonPrey = 'cordonPrey';

// ---------------------------------------------------------------------------
// The parser
// ---------------------------------------------------------------------------

function ScenesOf(const AScenes: string): TArray<TLevelScene>;
begin
  var Root := TJSONObject.ParseJSONValue('{"scenes":[' + AScenes + ']}')
    as TJSONObject;
  try
    Result := ParseLevelScenes(Root, LevelId);
  finally
    Root.Free;
  end;
end;

// A scene of screen 1 with ACues on its timeline; AExtra is more members
// beside them as they stand in a file
function SceneJson(const ACues: string; const AExtra: string = ''): string;
begin
  Result := Format('{"id":"%s","screen":1,"cues":[%s]', [SceneId, ACues]);
  if AExtra <> '' then
    Result := Result + ',' + AExtra;
  Result := Result + '}';
end;

function OneScene(const ACues: string;
  const AExtra: string = ''): TLevelScene;
begin
  var Scenes := ScenesOf(SceneJson(ACues, AExtra));
  Assert.AreEqual(1, Integer(Length(Scenes)), 'The section holds one scene');
  Result := Scenes[0];
end;

// The one cue of a scene of one cue
function OneCue(const ACue: string): TSceneCue;
begin
  var Scene := OneScene(ACue);
  Assert.AreEqual(1, Integer(Length(Scene.Cues)), 'The scene holds one cue');
  Result := Scene.Cues[0];
end;

function IsNear(AValue: Single; AExpected: Double): Boolean;
begin
  Result := Abs(AValue - AExpected) < SingleSlack;
end;

function CueCalled(const AScene: TLevelScene; const AId: string): TSceneCue;
begin
  Result := Default(TSceneCue);
  for var Cue in AScene.Cues do
    if Cue.Id = AId then
      Exit(Cue);
  Assert.Fail('No cue is called ' + AId);
end;

// By value, not const: an anonymous method captures them
procedure ExpectSectionRaises(AScenes, AWhat: string);
begin
  Assert.WillRaise(
    procedure
    begin
      ScenesOf(AScenes);
    end, ELevelSceneError, AWhat);
end;

procedure ExpectCuesRaise(ACues, AWhat: string);
begin
  ExpectSectionRaises(SceneJson(ACues), AWhat);
end;

procedure ExpectAftermathRaises(AAftermath, AWhat: string);
begin
  ExpectSectionRaises(SceneJson('{"at":0,"do":"shade","value":0}',
    '"aftermath":[' + AAftermath + ']'), AWhat);
end;

procedure TLevelScenesTests.TestSceneComesToItsDefaults;
begin
  var Scene := OneScene('{"at":0,"do":"shade","value":50}');

  Assert.AreEqual(SceneId, Scene.Id);
  Assert.AreEqual(1, Scene.Screen);
  Assert.AreEqual<TSceneOnce>(soLevel, Scene.Once, 'Once by default');
  Assert.AreEqual(0, Integer(Length(Scene.Aftermath)), 'No aftermath');
  var Cue := Scene.Cues[0];
  Assert.AreEqual<TSceneCueKind>(ckShade, Cue.Kind);
  Assert.AreEqual(0, Cue.Ticks, 'Ticks by default');
  Assert.IsTrue(IsNear(Cue.Level, 0.5), 'A value of 50');
  Assert.AreEqual('', Cue.Id, 'No id by default');

  var LifeScene := OneScene('{"at":0,"do":"shade","value":50}',
    '"once":"life"');
  Assert.AreEqual<TSceneOnce>(soLife, LifeScene.Once, '"once": "life"');
end;

procedure TLevelScenesTests.TestCueAtPlaysOnItsTick;
begin
  var Cue := OneCue('{"at":7,"do":"shake","value":20,"ticks":3}');

  Assert.AreEqual(7, Cue.At);
  Assert.AreEqual(7, Cue.Plan);
  Assert.AreEqual(-1, Cue.After, 'A cue on its tick counts from no cue');
  Assert.AreEqual(3, Cue.Ticks);
end;

procedure TLevelScenesTests.TestCueAfterCountsFromTheCueItNames;
begin
  var Scene := OneScene(
    '{"id":"first","at":10,"do":"shake","value":20},' +
    '{"id":"second","after":"first","delay":5,"do":"shade","value":10},' +
    '{"id":"third","after":"second","do":"shade","value":0}');

  var Second := CueCalled(Scene, 'second');
  Assert.AreEqual(15, Second.Plan, 'Ten and a delay of five');
  Assert.AreEqual(5, Second.Delay);
  Assert.AreEqual('first', Scene.Cues[Second.After].Id,
    'The cue the second counts from');
  var Third := CueCalled(Scene, 'third');
  Assert.AreEqual(15, Third.Plan, 'No delay: on the tick of the second');
  Assert.AreEqual(0, Third.Delay, 'Delay by default');
  Assert.AreEqual('second', Scene.Cues[Third.After].Id,
    'The cue the third counts from');
end;

procedure TLevelScenesTests.TestCuesStandInTheOrderOfTheirPlan;
begin
  var Scene := OneScene(
    '{"id":"late","at":30,"do":"shade","value":10},' +
    '{"id":"early","at":10,"do":"shade","value":20},' +
    '{"id":"twin","at":10,"do":"shade","value":30},' +
    '{"id":"counted","after":"early","delay":30,"do":"shade","value":40},' +
    '{"id":"middle","at":20,"do":"shade","value":50}');

  var Order: TArray<string> := [];
  for var Cue in Scene.Cues do
    Order := Order + [Cue.Id];
  Assert.AreEqual('early twin middle late counted', string.Join(' ', Order),
    'By the plan, and the file''s order between equals');
  Assert.AreEqual('early', Scene.Cues[CueCalled(Scene, 'counted').After].Id,
    'A cue counted from another still finds it once the cues are sorted');
end;

procedure TLevelScenesTests.TestCueAfterLooksOnlyUp;
begin
  ExpectCuesRaise('{"after":"below","do":"shade","value":0},' +
    '{"id":"below","at":0,"do":"shade","value":0}',
    'After a cue further down the file');
  ExpectCuesRaise('{"id":"self","after":"self","do":"shade","value":0}',
    'After itself');
  ExpectCuesRaise('{"after":"nobody","do":"shade","value":0}',
    'After a cue that is not there');
end;

procedure TLevelScenesTests.TestCueTakesAtOrAfter;
begin
  ExpectCuesRaise('{"id":"first","at":0,"do":"shade","value":0},' +
    '{"at":5,"after":"first","do":"shade","value":0}', 'Both at and after');
  ExpectCuesRaise('{"do":"shade","value":0}', 'Neither at nor after');
end;

procedure TLevelScenesTests.TestNegativeTicksRaise;
begin
  ExpectCuesRaise('{"at":-1,"do":"shade","value":0}', 'At -1');
  ExpectCuesRaise('{"id":"first","at":0,"do":"shade","value":0},' +
    '{"after":"first","delay":-1,"do":"shade","value":0}', 'A delay of -1');
  ExpectCuesRaise('{"at":0,"do":"shade","value":0,"ticks":-1}', 'Ticks -1');
end;

procedure TLevelScenesTests.TestTwoOfOneIdRaise;
begin
  ExpectCuesRaise('{"id":"twice","at":0,"do":"shade","value":0},' +
    '{"id":"twice","at":5,"do":"shade","value":0}', 'Two cues of one id');
  var Cue := '{"at":0,"do":"shade","value":0}';
  ExpectSectionRaises(
    '{"id":"twice","screen":1,"cues":[' + Cue + ']},' +
    '{"id":"TWICE","screen":1,"cues":[' + Cue + ']}',
    'Two scenes of one id, in another case');
end;

procedure TLevelScenesTests.TestAftermathPlaysAtOnce;
begin
  var Scene := OneScene('{"at":0,"do":"shade","value":0}',
    '"aftermath":[{"do":"remove","target":"prey"},' +
    '{"do":"wake","target":"lift"},' +
    '{"do":"fly","target":"lift","x":64,"y":224}]');
  Assert.AreEqual(3, Integer(Length(Scene.Aftermath)), 'Three cues');
  Assert.AreEqual<TSceneCueKind>(ckRemove, Scene.Aftermath[0].Kind,
    'The file''s order');
  Assert.AreEqual<TSceneCueKind>(ckWake, Scene.Aftermath[1].Kind,
    'The file''s order');
  Assert.AreEqual<TSceneCueKind>(ckFly, Scene.Aftermath[2].Kind,
    'The file''s order');

  ExpectAftermathRaises('{"at":0,"do":"remove","target":"prey"}',
    'An aftermath cue at a tick');
  ExpectAftermathRaises('{"after":"x","do":"remove","target":"prey"}',
    'An aftermath cue after another');
  ExpectAftermathRaises('{"id":"x","do":"remove","target":"prey"}',
    'An aftermath cue with an id');
  ExpectAftermathRaises('{"do":"sound","file":"a.wav"}', 'A sound at once');
  ExpectAftermathRaises('{"do":"hint","header":"H","text":"T"}',
    'A hint at once');
  ExpectAftermathRaises(
    '{"do":"wait","until":"deckEmpty","target":"lift"}', 'A wait at once');
end;

procedure TLevelScenesTests.TestSpawnStandsOnASeatOrAPoint;
begin
  var Seated := OneCue('{"at":0,"do":"spawn","monster":"tank",' +
    '"tag":"guest","seat":"lift"}');
  Assert.AreEqual<TSceneCueKind>(ckSpawn, Seated.Kind);
  Assert.AreEqual('lift', Seated.Seat);
  Assert.AreEqual('guest', Seated.Target, 'The tag it gives');

  var Placed := OneCue('{"at":0,"do":"spawn","monster":"tank",' +
    '"tag":"guest","x":416,"y":256}');
  Assert.AreEqual('', Placed.Seat, 'No seat');
  Assert.IsTrue(Placed.MovesX and Placed.MovesY, 'Both x and y read');
  Assert.IsTrue(IsNear(Placed.X, 416.0));
  Assert.IsTrue(IsNear(Placed.Y, 256.0));

  ExpectCuesRaise('{"at":0,"do":"spawn","monster":"tank","tag":"guest",' +
    '"seat":"lift","x":416,"y":256}', 'A seat and a point');
  ExpectCuesRaise('{"at":0,"do":"spawn","monster":"tank","tag":"guest",' +
    '"seat":"lift","x":416}', 'A seat and an x');
  ExpectCuesRaise('{"at":0,"do":"spawn","monster":"tank","tag":"guest",' +
    '"x":416}', 'An x alone');
  ExpectCuesRaise('{"at":0,"do":"spawn","monster":"tank","tag":"guest"}',
    'Neither a seat nor a point');
  ExpectCuesRaise('{"at":0,"do":"spawn","tag":"guest","seat":"lift"}',
    'No monster');
  ExpectCuesRaise('{"at":0,"do":"spawn","monster":"tank","seat":"lift"}',
    'No tag');
end;

procedure TLevelScenesTests.TestSpawnReadsWhatItIsGiven;
begin
  var Bare := OneCue('{"at":0,"do":"spawn","monster":"tank",' +
    '"tag":"guest","seat":"lift"}');
  Assert.AreEqual('tank', Bare.Monster);
  Assert.AreEqual('', Bare.SpriteList, 'The monster''s own art by default');
  Assert.IsFalse(Bare.FacesRight, 'Facing left by default');
  Assert.IsFalse(Bare.Asleep, 'Awake by default');

  var Full := OneCue('{"at":0,"do":"spawn","monster":"tank",' +
    '"spriteList":"tank.mns","tag":"guest","seat":"lift",' +
    '"facing":"right","asleep":true}');
  Assert.AreEqual('tank.mns', Full.SpriteList);
  Assert.IsTrue(Full.FacesRight, '"facing": "right"');
  Assert.IsTrue(Full.Asleep, '"asleep": true');
end;

procedure TLevelScenesTests.TestAimTakesAMarkOrAPoint;
begin
  var OnHero := OneCue('{"at":0,"do":"aim","target":"beam","on":"hero"}');
  Assert.AreEqual<TSceneMark>(smHero, OnHero.Mark, '"on": "hero"');

  var OnTag := OneCue('{"at":0,"do":"aim","target":"beam","on":"prey",' +
    '"ticks":10,"ease":"out"}');
  Assert.AreEqual<TSceneMark>(smMonster, OnTag.Mark, '"on" a tag');
  Assert.AreEqual('prey', OnTag.MarkTag);
  Assert.AreEqual<TMotionEase>(meOut, OnTag.Ease);

  var OnPoint := OneCue('{"at":0,"do":"aim","target":"beam","x":336,' +
    '"y":272}');
  Assert.AreEqual<TSceneMark>(smPoint, OnPoint.Mark, 'x and y in place of on');
  Assert.IsTrue(IsNear(OnPoint.X, 336.0));
  Assert.IsTrue(IsNear(OnPoint.Y, 272.0));

  var TrackOff := OneCue('{"at":0,"do":"track","target":"ship",' +
    '"part":"iris","on":"none"}');
  Assert.AreEqual<TSceneMark>(smNothing, TrackOff.Mark,
    'A track on nothing sends the part back to rest');

  ExpectCuesRaise('{"at":0,"do":"aim","target":"beam","on":"none"}',
    'A beam aimed at nothing');
  ExpectCuesRaise('{"at":0,"do":"aim","target":"beam","x":336}',
    'A point of one axis');
  ExpectCuesRaise('{"at":0,"do":"aim","target":"beam"}', 'No mark at all');
  ExpectCuesRaise('{"at":0,"do":"track","target":"ship","on":"hero"}',
    'A track of no part');
end;

procedure TLevelScenesTests.TestMoveReadsTheAxesItIsGiven;
begin
  var AcrossOnly := OneCue('{"at":0,"do":"move","target":"ship",' +
    '"x":-989.8,"ticks":363,"ease":"out"}');
  Assert.IsTrue(AcrossOnly.MovesX, 'x is read');
  Assert.IsFalse(AcrossOnly.MovesY, 'No y: the other axis is left alone');
  Assert.IsTrue(IsNear(AcrossOnly.X, -989.8));
  Assert.AreEqual<TMotionEase>(meOut, AcrossOnly.Ease);

  var Linear := OneCue('{"at":0,"do":"move","target":"ship","y":-18.4}');
  Assert.IsTrue(Linear.MovesY and not Linear.MovesX, 'y alone');
  Assert.AreEqual<TMotionEase>(meLinear, Linear.Ease, 'Ease by default');
end;

procedure TLevelScenesTests.TestFlyEasesOnlyWhenTold;
begin
  var Paced := OneCue('{"at":0,"do":"fly","target":"lift","x":64,"y":96,' +
    '"ticks":66}');
  Assert.IsFalse(Paced.Eased, 'With no ease it brakes as a pad does');

  var Thrown := OneCue('{"at":0,"do":"fly","target":"rock","x":290,' +
    '"y":256,"ticks":70,"ease":"back"}');
  Assert.IsTrue(Thrown.Eased, 'An ease named is followed');
  Assert.AreEqual<TMotionEase>(meBack, Thrown.Ease);
  Assert.IsTrue(IsNear(Thrown.X, 290) and IsNear(Thrown.Y, 256), 'x and y');
end;

procedure TLevelScenesTests.TestPaceReadsItsTargetAndShare;
begin
  var Cue := OneCue('{"at":0,"do":"pace","target":"dust","value":0,' +
    '"ticks":15}');
  Assert.AreEqual<TSceneCueKind>(ckPace, Cue.Kind);
  Assert.AreEqual('dust', Cue.Target);
  Assert.IsTrue(IsNear(Cue.Level, 0), 'Stilled');
  Assert.AreEqual(15, Cue.Ticks, 'over its ticks');
  Assert.IsTrue(IsNear(OneCue('{"at":0,"do":"pace","target":"dust",' +
    '"value":50}').Level, 0.5), 'A share of the pace of the file');
end;

procedure TLevelScenesTests.TestJoltReadsItsShare;
begin
  var Cue := OneCue('{"at":60,"do":"jolt","value":40}');
  Assert.AreEqual<TSceneCueKind>(ckJolt, Cue.Kind);
  Assert.IsTrue(IsNear(Cue.Level, 0.4), 'A share of the hardest blow');
  ExpectCuesRaise('{"at":0,"do":"jolt"}', 'A jolt of no value');
  ExpectCuesRaise('{"at":0,"do":"jolt","value":120}', 'A jolt past 100');
end;

procedure TLevelScenesTests.TestWaitReadsItsCondition;
begin
  var Scene := OneScene('{"id":"docked","at":5,"do":"shade","value":0},' +
    '{"id":"unloaded","after":"docked","do":"wait","until":"deckEmpty",' +
    '"target":"lift"}');
  var Wait := CueCalled(Scene, 'unloaded');

  Assert.AreEqual<TSceneCueKind>(ckWait, Wait.Kind);
  Assert.AreEqual<TSceneWait>(swDeckEmpty, Wait.Waits);
  Assert.AreEqual('lift', Wait.Target);
end;

procedure TLevelScenesTests.TestUnknownWordsRaise;
begin
  ExpectCuesRaise('{"at":0,"do":"dance"}', 'An unknown cue');
  ExpectCuesRaise('{"at":0,"do":"move","target":"ship","x":1,' +
    '"ease":"bounce"}', 'An unknown ease');
  ExpectCuesRaise('{"at":0,"do":"wait","until":"dusk","target":"lift"}',
    'An unknown condition');
  ExpectCuesRaise('{"at":0,"do":"hint","header":"H","text":"T",' +
    '"place":"middle"}', 'An unknown place');
  ExpectCuesRaise('{"at":0,"do":"spawn","monster":"tank","tag":"guest",' +
    '"seat":"lift","facing":"up"}', 'An unknown facing');
  ExpectSectionRaises(SceneJson('{"at":0,"do":"shade","value":0}',
    '"once":"ever"'), 'An unknown once');
end;

procedure TLevelScenesTests.TestCueWithoutWhatItNeedsRaises;
begin
  ExpectCuesRaise('{"at":0,"do":"sound"}', 'A sound of no file');
  ExpectCuesRaise('{"at":0,"do":"shade"}', 'A shade of no value');
  ExpectCuesRaise('{"at":0,"do":"shade","value":101}', 'A value over 100');
  ExpectCuesRaise('{"at":0,"do":"move","target":"ship"}',
    'A move of no axis');
  ExpectCuesRaise('{"at":0,"do":"move","x":5}', 'A move of no target');
  ExpectCuesRaise('{"at":0,"do":"fly","target":"lift","x":64}',
    'A fly of one axis');
  ExpectCuesRaise('{"at":0,"do":"hint","text":"T"}', 'A hint of no header');
  ExpectCuesRaise('{"at":0,"do":"hint","header":"H"}', 'A hint of no text');
  ExpectCuesRaise('{"at":0,"do":"kill"}', 'A kill of no target');
  ExpectCuesRaise('{"at":0,"do":"pace","value":0}', 'A pace of no target');
  ExpectCuesRaise('{"at":0,"do":"pace","target":"dust","value":120}',
    'A pace past 100');
  ExpectCuesRaise('{"at":0,"do":"fly","target":"lift","x":64,"y":96,' +
    '"ease":"bounce"}', 'A fly of an unknown ease');
  ExpectSectionRaises(SceneJson(''), 'A scene of no cues');
  ExpectSectionRaises('{"screen":1,"cues":[{"at":0,"do":"shade","value":0}]}',
    'A scene of no id');
end;

// ---------------------------------------------------------------------------
// The load
// ---------------------------------------------------------------------------

function OpenRows: TArray<string>;
begin
  Result := RoomRowsOf(0, 0, 0, 0);
end;

// The level the scenes of the load stand in: a pad tagged "lift", a craft
// tagged "ship" with an iris that slides and a plate that does not, a
// beam and a beacon on it, and a gravel tagged "guard". AScenes are the
// scenes, and AExtra more members of the root.
function StageJson(const AScenes: string; const AExtra: string = ''): string;
begin
  Result := '"pads":[{"sprite":"","screen":1,"x":224,"y":224,"width":32,' +
    '"tag":"lift"}],' +
    '"dynamics":[{"kind":"craft","tag":"ship","screen":1,"body":"hull",' +
    '"width":100,"x":0,"y":-100,"parts":[' +
    '{"sprite":"iris","tag":"iris","at":[50,20],"width":4,' +
    '"anchor":"center","reach":3},' +
    '{"sprite":"plate","tag":"plate","at":[0,0],"width":20}]},' +
    '{"kind":"beam","tag":"scan","parent":"ship","x":50,"y":20},' +
    '{"kind":"beacon","tag":"lamp","parent":"ship","x":10,"y":10}],' +
    '"entities":[{"monsterId":"gravel","screen":1,"x":3,"y":11,' +
    '"tag":"guard"}],' +
    '"scenes":[' + AScenes + ']';
  if AExtra <> '' then
    Result := Result + ',' + AExtra;
end;

// By value, not const: an anonymous method captures them
procedure ExpectLoadRaises(ASections, AWhat: string);
begin
  Assert.WillRaise(
    procedure
    begin
      LevelFromRows(OpenRows, ASections).Free;
    end, ELevelError, AWhat);
end;

procedure ExpectLoads(const ASections, AWhat: string);
begin
  var Level := LevelFromRows(OpenRows, ASections);
  try
    Assert.IsNotNull(Level, AWhat);
  finally
    Level.Free;
  end;
end;

procedure ExpectCuesLoad(const ACues, AWhat: string);
begin
  ExpectLoads(StageJson(SceneJson(ACues)), AWhat);
end;

procedure ExpectCuesTurnedDown(ACues, AWhat: string);
begin
  ExpectLoadRaises(StageJson(SceneJson(ACues)), AWhat);
end;

procedure TSceneLoadTests.TestSceneNamesOnlyPadsItsScreenHas;
begin
  ExpectCuesLoad('{"at":0,"do":"fly","target":"lift","x":64,"y":224}',
    'A fly of the pad of the screen');
  ExpectCuesTurnedDown('{"at":0,"do":"fly","target":"ghost","x":64,' +
    '"y":224}', 'A fly of no pad');
  ExpectCuesTurnedDown('{"at":0,"do":"wake","target":"ghost"}',
    'A wake of no pad');
  ExpectCuesTurnedDown('{"at":0,"do":"wait","until":"deckEmpty",' +
    '"target":"ghost"}', 'A wait on no pad');
  ExpectCuesLoad('{"at":0,"do":"spawn","monster":"gravel","tag":"guest",' +
    '"seat":"lift"}', 'A spawn seated on the pad of the screen');
  ExpectCuesTurnedDown('{"at":0,"do":"spawn","monster":"gravel",' +
    '"tag":"guest","seat":"ghost"}', 'A spawn seated on no pad');
end;

procedure TSceneLoadTests.TestSceneNamesBodiesOfTheFileOrOfItsOwn;
begin
  ExpectCuesLoad('{"at":0,"do":"hold","target":"guard"}',
    'A hold of a tag of the file');
  ExpectCuesLoad('{"at":0,"do":"spawn","monster":"gravel","tag":"guest",' +
    '"x":64,"y":352},{"at":5,"do":"kill","target":"guest"}',
    'A kill of a body the scene brings');
  ExpectLoads(StageJson(SceneJson('{"at":0,"do":"release","target":"guest"}',
    '"aftermath":[{"do":"spawn","monster":"gravel","tag":"guest",' +
    '"x":64,"y":352}]')), 'A release of a body the aftermath brings');
  ExpectCuesLoad('{"at":0,"do":"aim","target":"scan","on":"guard"}',
    'An aim on a tag of the file');

  for var Cue in MonsterCues do
    ExpectCuesTurnedDown(Format('{"at":0,"do":"%s","target":"ghost"}', [Cue]),
      Format('A %s of a tag nobody carries', [Cue]));
  ExpectCuesTurnedDown('{"at":0,"do":"aim","target":"scan","on":"ghost"}',
    'An aim on a tag nobody carries');
end;

procedure TSceneLoadTests.TestDormantPadNeedsASceneThatWakesIt;
const
  Sleeper = '{"sprite":"","screen":1,"x":96,"y":224,"width":32,' +
    '"tag":"sleeper","dormant":true}';
begin
  ExpectLoadRaises('"pads":[' + Sleeper + ']',
    'A dormant pad and no scene');
  ExpectLoadRaises('"pads":[' + Sleeper + '],"scenes":[' +
    SceneJson('{"at":0,"do":"shade","value":0}') + ']',
    'A dormant pad and a scene that does not wake it');
  ExpectLoads('"pads":[' + Sleeper + '],"scenes":[' +
    SceneJson('{"at":0,"do":"wake","target":"sleeper"}') + ']',
    'A dormant pad a scene wakes');
end;

procedure TSceneLoadTests.TestSceneNamesOnlyWhatTheDynamicsCarry;
begin
  ExpectCuesLoad('{"at":0,"do":"move","target":"ship","x":5}',
    'A move of the craft');
  ExpectCuesTurnedDown('{"at":0,"do":"move","target":"lamp","x":5}',
    'A move of a beacon');
  ExpectCuesTurnedDown('{"at":0,"do":"move","target":"ghost","x":5}',
    'A move of nothing');
  ExpectCuesLoad('{"at":0,"do":"track","target":"ship","part":"iris",' +
    '"on":"hero"}', 'A track of a part that slides');
  ExpectCuesTurnedDown('{"at":0,"do":"track","target":"ship",' +
    '"part":"plate","on":"hero"}', 'A track of a part that neither turns ' +
    'nor slides');
  ExpectCuesLoad('{"at":0,"do":"aim","target":"scan","on":"hero"}',
    'An aim of the beam');
  ExpectCuesTurnedDown('{"at":0,"do":"aim","target":"lamp","on":"hero"}',
    'An aim of a beacon');
  ExpectCuesLoad('{"at":0,"do":"intensity","target":"lamp","value":100}',
    'An intensity of the beacon');
  ExpectCuesTurnedDown('{"at":0,"do":"intensity","target":"ghost",' +
    '"value":100}', 'An intensity of nothing');
end;

procedure TSceneLoadTests.TestCraftGoesBeforeWhatHangsOnIt;
const
  Craft = '{"kind":"craft","tag":"ship","screen":1,"body":"hull",' +
    '"width":100,"x":0,"y":-100}';
  Lamp = '{"kind":"beacon","tag":"lamp","parent":"ship","x":10,"y":10}';
begin
  ExpectLoads('"dynamics":[' + Craft + ',' + Lamp + ']',
    'The craft ahead of its lamp');
  ExpectLoadRaises('"dynamics":[' + Lamp + ',' + Craft + ']',
    'The lamp ahead of its craft');
end;

procedure TSceneLoadTests.TestSceneScreenAndItsEventMustBeThere;
const
  Shade = '{"at":0,"do":"shade","value":0}';
begin
  ExpectLoadRaises('"scenes":[{"id":"far","screen":2,"cues":[' + Shade +
    ']}]', 'A scene on a screen the level does not have');

  var Event := '"events":[{"id":"start","screen":1,"when":"enterScreen",' +
    '"then":[{"action":"scene","target":"%s"}]}]';
  ExpectLoads('"scenes":[' + SceneJson(Shade) + '],' +
    Format(Event, [SceneId]), 'An event that starts the scene');
  ExpectLoads('"scenes":[' + SceneJson(Shade) + '],' +
    Format(Event, [UpperCase(SceneId)]),
    'An event that starts the scene by its id in another case');
  ExpectLoadRaises('"scenes":[' + SceneJson(Shade) + '],' +
    Format(Event, ['ghost']), 'An event that starts a scene not there');
end;

procedure TSceneLoadTests.TestCordonOfLevelOneStandsAsDecided;
begin
  var Level := TLevel.Create;
  try
    Level.LoadFromFile(TPath.Combine(ExtractFilePath(ParamStr(0)),
      LevelOneFile));

    var Found := False;
    var Scene := Default(TLevelScene);
    for var Candidate in Level.Scenes do
      if Candidate.Id = CordonScene then
      begin
        Found := True;
        Scene := Candidate;
      end;
    Assert.IsTrue(Found, 'Level 1 holds no scene ' + CordonScene);
    Assert.AreEqual(CordonScreen, Scene.Screen, 'The screen of the cordon');
    Assert.AreEqual<TSceneOnce>(soLevel, Scene.Once,
      'The cordon plays once a level');

    var WaitsForTheDeck := False;
    for var Cue in Scene.Cues do
      if (Cue.Kind = ckWait) and (Cue.Target = CordonLift) then
        WaitsForTheDeck := True;
    Assert.IsTrue(WaitsForTheDeck,
      'The pad leaves only once the tank is off it');

    var BringsTheTank := False;
    var TakesThePrey := False;
    for var Cue in Scene.Aftermath do
    begin
      if (Cue.Kind = ckSpawn) and (Cue.Target = CordonTank) then
        BringsTheTank := True;
      if (Cue.Kind = ckRemove) and (Cue.Target = CordonPrey) then
        TakesThePrey := True;
    end;
    Assert.IsTrue(BringsTheTank, 'The aftermath puts the tank');
    Assert.IsTrue(TakesThePrey, 'The aftermath takes the betoner away');

    var LiftAsleep := False;
    for var Pad in Level.Pads do
      if (Pad.Tag = CordonLift) and (Pad.Screen = CordonScreen) then
        LiftAsleep := Pad.Dormant;
    Assert.IsTrue(LiftAsleep, 'The pad of the cordon sleeps in the file');

    var Started := False;
    for var Event in Level.Events do
      for var Action in Event.Actions do
        if (Action.Kind = eaScene) and SameText(Action.Target, CordonScene) and
          (Event.Screen = CordonScreen) then
          Started := True;
    Assert.IsTrue(Started, 'An event of screen 9 starts the cordon');
  finally
    Level.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TLevelScenesTests);
  TDUnitX.RegisterTestFixture(TSceneLoadTests);

end.
