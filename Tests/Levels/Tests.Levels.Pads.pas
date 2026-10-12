{
  Tests.Levels.Pads - what a level makes of the pads section of its JSON
  and of the respawn points that lean on the pads: what is read as
  written, what a missing member comes to, and which files the level
  turns down - EPadError from the parser, ELevelError from the checks
  that run after it.

  The level is loaded from a one-screen room with the pads and the
  respawns of the test added to its root; one test loads level2.json
  beside the executable, for the shelf it holds. The checks of pad
  groups, of the rigs a pad wears and of the events are not tried here.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Levels.Pads;

interface

uses
  DUnitX.TestFramework,
  Levels.Defs;

type
  [TestFixture]
  TLevelPadsTests = class
  private
    FLevel: TLevel;
    procedure UseLevel(const ARows: array of string;
      const ASections: string);
  public
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestPadReadsItsPlaceAndDefaults;
    [Test]
    procedure TestPadReadsWhatItIsGiven;
    [Test]
    procedure TestRouteDefaultsToPingPong;
    [Test]
    procedure TestBadPadNumbersRaise;
    [Test]
    procedure TestBadPathRaises;
    [Test]
    procedure TestStopOffTheScreenRaises;
    [Test]
    procedure TestTwoPadsOfOneTagRaise;
    [Test]
    procedure TestPlungeReadsItsNumbers;
    [Test]
    procedure TestPlungeLeftOutTakesHalfASecond;
    [Test]
    procedure TestBadPlungeNumbersRaise;
    [Test]
    procedure TestPlungingPadMustStandOnItsPlace;
    [Test]
    procedure TestPlungingPadOverAWallRaises;
    [Test]
    procedure TestRespawnNeedsAFloorThatStays;
    [Test]
    procedure TestBareShelfComesToItsDefaults;
    [Test]
    procedure TestShelfReadsWhatItIsGiven;
    [Test]
    procedure TestShelfProgramIsReadInOrder;
    [Test]
    procedure TestShelfStepWordsAreReadInAnyCase;
    [Test]
    procedure TestShelfProgramBesideOutOrInRaises;
    [Test]
    procedure TestBadShelfStepRaises;
    [Test]
    procedure TestShelfStepsMustTakeTurns;
    [Test]
    procedure TestBadShelfNumbersRaise;
    [Test]
    procedure TestShelfMayNotPlungeOrJoinAGroup;
    [Test]
    procedure TestShelfMayTravelAPath;
    [Test]
    procedure TestRespawnOverAShelfRaises;
    [Test]
    procedure TestLevelTwoShelfIsInItsFile;
  end;

implementation

uses
  System.IOUtils,
  System.SysUtils,
  Levels.Pads,
  Tests.Rooms;

type
  // Whether the shaft of the gap room has a floor of its own
  TShaft = (shOpen, shPlugged);

const
  // The gap room: solid on rows 10 to 12 but for column 9, open to the
  // bottom. Its two ledges have their tops at y = 288, and a pad that
  // plunges stands in the shaft between them.
  GapCol = 9;
  GapX = 256;
  LedgeTopY = 288;
  PadWidth = 32;
  // A pad this wide stands on the screen with its left edge at 480 at most
  LastPadX = 480;
  SpriteName = 's16-platform';
  SingleSlack = 0.0001;
  // The shelf of level 2, screen 7
  LevelTwoFile = 'level2.json';
  LevelTwoShelfTag = 's07-shelf-01';
  LevelTwoShelfScreen = 7;

function OpenRows: TArray<string>;
begin
  Result := RoomRowsOf(0, 0, 0, 0);
end;

function GapRows(AShaft: TShaft): TArray<string>;
begin
  SetLength(Result, RoomRows);
  for var i := 0 to RoomRows - 1 do
  begin
    Result[i] := StringOfChar('.', RoomCols);
    if i >= 9 then
    begin
      Result[i] := StringOfChar('#', RoomCols);
      Result[i][GapCol] := '.';
    end;
  end;
  if AShaft = shPlugged then
    Result[RoomRows - 1][GapCol] := '#';
end;

function IsNear(AValue: Single; AExpected: Double): Boolean;
begin
  Result := Abs(AValue - AExpected) < SingleSlack;
end;

// One pad of the section, with the five members it must have; AExtra is
// more members as they stand in a file
function PadJson(AX, AY: Integer; const AExtra: string = '';
  AWidth: Integer = PadWidth): string;
begin
  Result := Format('{"sprite":"%s","screen":1,"x":%d,"y":%d,"width":%d',
    [SpriteName, AX, AY, AWidth]);
  if AExtra <> '' then
    Result := Result + ',' + AExtra;
  Result := Result + '}';
end;

function PadsSection(const APads: array of string): string;
begin
  Result := '"pads":[' + string.Join(',', APads) + ']';
end;

function PathJson(const ARoute, AStops, ASpeed, APause: string): string;
begin
  Result := Format('"path":{"route":%s,"stops":%s,"speed":%s,"pause":%s}',
    [ARoute, AStops, ASpeed, APause]);
end;

// The pad of the gap that plunges, with the numbers the parser gives
function PlungingPad(const AExtra: string = ''): string;
begin
  var Members := '"plunge":{}';
  if AExtra <> '' then
    Members := Members + ',' + AExtra;
  Result := PadJson(GapX, LedgeTopY, Members);
end;

// The pads of a group the level accepts: a group takes 5 to 60, so the
// subject comes with four mates, all inside the group's zone
function GroupOfFive(const ASubject: string): string;
const
  MateGroup = '"group":"zone"';
begin
  Result := PadsSection([ASubject, PadJson(64, 128, MateGroup),
    PadJson(128, 160, MateGroup), PadJson(192, 128, MateGroup),
    PadJson(320, 160, MateGroup)]);
end;

// The zone the pads of GroupOfFive join
function GroupZone: string;
begin
  Result := '"padGroups":[{"tag":"zone","screen":1,"zone":[2,4,13,8],' +
    '"pairs":2,"farFlight":5,"farShare":5}]';
end;

// The pad of the gap as a shelf: AMembers inside its shelf word, AExtra
// beside it
function ShelfPad(const AMembers: string; const AExtra: string = ''): string;
begin
  var Members := '"shelf":{' + AMembers + '}';
  if AExtra <> '' then
    Members := Members + ',' + AExtra;
  Result := PadJson(GapX, LedgeTopY, Members);
end;

procedure ExpectStep(const AStep: TShelfStep; AStand: TShelfStand;
  ASeconds: Double; const AWhat: string);
begin
  Assert.AreEqual<TShelfStand>(AStand, AStep.Stand, AWhat);
  Assert.IsTrue(IsNear(AStep.Seconds, ASeconds), Format('%s: %g seconds, ' +
    'not %g', [AWhat, AStep.Seconds, ASeconds]));
end;

function RespawnOverTheGap: string;
begin
  Result := Format('"respawns":[{"screen":1,"x":%d,"y":8}]', [GapCol]);
end;

function OnlyPad(const ALevel: TLevel): TPadPlacement;
begin
  Assert.AreEqual(1, Integer(Length(ALevel.Pads)),
    'The level holds one pad');
  Result := ALevel.Pads[0];
end;

// By value, not const: an anonymous method captures them
procedure ExpectRaises(AClass: ExceptClass; ARows: TArray<string>;
  ASections, AWhat: string);
begin
  Assert.WillRaise(
    procedure
    begin
      LevelFromRows(ARows, ASections).Free;
    end, AClass, AWhat);
end;

procedure ExpectLoads(const ARows: TArray<string>; const ASections: string;
  const AWhat: string);
begin
  var Level := LevelFromRows(ARows, ASections);
  try
    Assert.IsNotNull(Level, AWhat);
  finally
    Level.Free;
  end;
end;

procedure TLevelPadsTests.TearDown;
begin
  FreeAndNil(FLevel);
end;

procedure TLevelPadsTests.UseLevel(const ARows: array of string;
  const ASections: string);
begin
  FreeAndNil(FLevel);
  FLevel := LevelFromRows(ARows, ASections);
end;

procedure TLevelPadsTests.TestPadReadsItsPlaceAndDefaults;
begin
  UseLevel(OpenRows, PadsSection([PadJson(96, 160, '', 64)]));

  var Pad := OnlyPad(FLevel);
  Assert.AreEqual(SpriteName, Pad.Sprite);
  Assert.AreEqual(1, Pad.Screen);
  Assert.AreEqual(96, Pad.X);
  Assert.AreEqual(160, Pad.Y);
  Assert.AreEqual(64, Pad.Width);
  Assert.AreEqual<TPadBullets>(pbBlock, Pad.Bullets);
  Assert.AreEqual<TPadRoute>(prNone, Pad.Path.Route);
  Assert.IsTrue(IsNear(Pad.Bob, 0), 'A pad bobs only when asked');
  Assert.AreEqual('', Pad.Tag);
  Assert.AreEqual('', Pad.Group);
  Assert.IsFalse(Pad.Plunge.Plunges, 'A pad holds unless it is asked to give');
  Assert.IsFalse(Pad.Shelf.Slides, 'A pad stays in front unless it is a shelf');
end;

procedure TLevelPadsTests.TestPadReadsWhatItIsGiven;
begin
  var Path := PathJson('"pingpong"', '[[160,128],[224,192]]', '48', '1.5');
  UseLevel(OpenRows, PadsSection([PadJson(96, 160,
    '"bullets":"pass","tag":"lamp-a","bob":2.5,' + Path)]));

  var Pad := OnlyPad(FLevel);
  Assert.AreEqual<TPadBullets>(pbPass, Pad.Bullets);
  Assert.AreEqual('lamp-a', Pad.Tag);
  Assert.IsTrue(IsNear(Pad.Bob, 2.5), 'The bob is read as written');
  Assert.AreEqual<TPadRoute>(prPingPong, Pad.Path.Route);
  Assert.IsTrue(IsNear(Pad.Path.Speed, 48), 'The speed is read as written');
  Assert.IsTrue(IsNear(Pad.Path.Pause, 1.5), 'The pause is read as written');
  Assert.AreEqual(2, Integer(Length(Pad.Path.Stops)));
  Assert.IsTrue(IsNear(Pad.Path.Stops[0].X, 160) and
    IsNear(Pad.Path.Stops[0].Y, 128), 'The first stop comes first');
  Assert.IsTrue(IsNear(Pad.Path.Stops[1].X, 224) and
    IsNear(Pad.Path.Stops[1].Y, 192), 'The second stop comes second');
end;

procedure TLevelPadsTests.TestRouteDefaultsToPingPong;
begin
  UseLevel(OpenRows, PadsSection([PadJson(96, 160,
    '"path":{"stops":[[160,160]],"speed":32}')]));
  Assert.AreEqual<TPadRoute>(prPingPong, OnlyPad(FLevel).Path.Route);

  UseLevel(OpenRows, PadsSection([PadJson(96, 160,
    '"path":{"route":"loop","stops":[[160,160],[224,160]],"speed":32}')]));
  Assert.AreEqual<TPadRoute>(prLoop, OnlyPad(FLevel).Path.Route);
end;

procedure TLevelPadsTests.TestBadPadNumbersRaise;
begin
  ExpectRaises(EPadError, OpenRows, PadsSection([PadJson(96, 160, '', 0)]),
    'A pad of width 0');
  ExpectRaises(EPadError, OpenRows,
    PadsSection([PadJson(96, 160, '"bob":-1')]), 'A pad that bobs by -1');
  ExpectRaises(EPadError, OpenRows,
    PadsSection([PadJson(96, 160, '"bullets":"bounce"')]),
    'A pad with bullets that bounce');
end;

procedure TLevelPadsTests.TestBadPathRaises;
begin
  ExpectRaises(EPadError, OpenRows, PadsSection([PadJson(96, 160,
    PathJson('"zigzag"', '[[160,160]]', '32', '1'))]),
    'A route that is neither pingpong nor loop');
  ExpectRaises(EPadError, OpenRows, PadsSection([PadJson(96, 160,
    PathJson('"pingpong"', '[]', '32', '1'))]), 'A path with no stops');
  ExpectRaises(EPadError, OpenRows, PadsSection([PadJson(96, 160,
    PathJson('"pingpong"', '[[160,160,0]]', '32', '1'))]),
    'A stop of three numbers');
  ExpectRaises(EPadError, OpenRows, PadsSection([PadJson(96, 160,
    PathJson('"pingpong"', '[[160,160]]', '0', '1'))]),
    'A path with a speed of 0');
  ExpectRaises(EPadError, OpenRows, PadsSection([PadJson(96, 160,
    PathJson('"pingpong"', '[[160,160]]', '32', '-1'))]),
    'A path with a pause of -1');
end;

procedure TLevelPadsTests.TestStopOffTheScreenRaises;
begin
  var OffTheScreen := PathJson('"pingpong"',
    Format('[[%d,160]]', [LastPadX + 16]), '32', '1');
  ExpectRaises(ELevelError, OpenRows,
    PadsSection([PadJson(96, 160, OffTheScreen)]),
    'A stop at x = 496 for a pad 32 wide');

  var OnTheEdge := PathJson('"pingpong"',
    Format('[[%d,160]]', [LastPadX]), '32', '1');
  UseLevel(OpenRows, PadsSection([PadJson(96, 160, OnTheEdge)]));
  Assert.AreEqual(1, Integer(Length(FLevel.Pads)));
end;

procedure TLevelPadsTests.TestTwoPadsOfOneTagRaise;
begin
  ExpectRaises(ELevelError, OpenRows, PadsSection([
    PadJson(96, 160, '"tag":"lamp"'), PadJson(160, 160, '"tag":"lamp"')]),
    'Two pads tagged alike');

  UseLevel(OpenRows, PadsSection([PadJson(96, 160), PadJson(160, 160)]));
  Assert.AreEqual(2, Integer(Length(FLevel.Pads)));
end;

procedure TLevelPadsTests.TestPlungeReadsItsNumbers;
begin
  UseLevel(GapRows(shOpen), PadsSection([
    PadJson(GapX, LedgeTopY, '"plunge":{"delay":1,"rest":2,"rise":3}')]));

  var Plunge := OnlyPad(FLevel).Plunge;
  Assert.IsTrue(Plunge.Plunges, 'The pad plunges');
  Assert.IsTrue(IsNear(Plunge.Delay, 1), 'The delay is read as written');
  Assert.IsTrue(IsNear(Plunge.Rest, 2), 'The rest is read as written');
  Assert.IsTrue(IsNear(Plunge.Rise, 3), 'The rise is read as written');
end;

procedure TLevelPadsTests.TestPlungeLeftOutTakesHalfASecond;
begin
  UseLevel(GapRows(shOpen), PadsSection([PlungingPad]));

  var Plunge := OnlyPad(FLevel).Plunge;
  Assert.IsTrue(Plunge.Plunges, 'An empty plunge is still a plunge');
  Assert.IsTrue(IsNear(Plunge.Delay, 0.5), Format('The delay is %g seconds',
    [Plunge.Delay]));
  Assert.IsTrue(Plunge.Rest >= 0, 'The rest is not below 0');
  Assert.IsTrue(Plunge.Rise > 0, 'The rise is above 0');
end;

procedure TLevelPadsTests.TestBadPlungeNumbersRaise;
begin
  ExpectRaises(EPadError, GapRows(shOpen), PadsSection([
    PadJson(GapX, LedgeTopY, '"plunge":{"delay":-1}')]),
    'A plunge with a delay of -1');
  ExpectRaises(EPadError, GapRows(shOpen), PadsSection([
    PadJson(GapX, LedgeTopY, '"plunge":{"rest":-1}')]),
    'A plunge with a rest of -1');
  ExpectRaises(EPadError, GapRows(shOpen), PadsSection([
    PadJson(GapX, LedgeTopY, '"plunge":{"rise":0}')]),
    'A plunge with a rise of 0');
end;

procedure TLevelPadsTests.TestPlungingPadMustStandOnItsPlace;
begin
  var Path := PathJson('"pingpong"', Format('[[%d,%d]]', [GapX, LedgeTopY - 64]),
    '32', '1');
  var Group := '"group":"zone"';
  var Zone := GroupZone;

  // The same pads that do not plunge load: the plunge is what is turned down
  ExpectLoads(GapRows(shOpen), PadsSection([PadJson(GapX, LedgeTopY, Path)]),
    'A pad that travels and does not plunge');
  ExpectLoads(GapRows(shOpen),
    GroupOfFive(PadJson(GapX, LedgeTopY, Group)) + ',' + Zone,
    'A pad in a group that does not plunge');

  ExpectRaises(ELevelError, GapRows(shOpen), PadsSection([PlungingPad(Path)]),
    'A pad that plunges and travels');
  ExpectRaises(ELevelError, GapRows(shOpen),
    GroupOfFive(PlungingPad(Group)) + ',' + Zone,
    'A pad that plunges and joins a group');
end;

procedure TLevelPadsTests.TestPlungingPadOverAWallRaises;
begin
  ExpectLoads(GapRows(shOpen), PadsSection([PlungingPad]),
    'A pad that plunges in the gap');

  ExpectRaises(ELevelError, GapRows(shPlugged), PadsSection([PlungingPad]),
    'A pad that plunges onto a solid cell in its shaft');
  ExpectRaises(ELevelError, GapRows(shOpen), PadsSection([
    PadJson(GapX, LedgeTopY, '"plunge":{}', 2 * PadWidth)]),
    'A pad 64 wide over the gap and the ledge beside it');
end;

procedure TLevelPadsTests.TestRespawnNeedsAFloorThatStays;
begin
  var Respawn := RespawnOverTheGap;
  var StillPad := PadsSection([PadJson(GapX, LedgeTopY)]);
  var OnPath := PadsSection([PadJson(GapX, LedgeTopY,
    PathJson('"pingpong"', Format('[[%d,%d]]', [GapX, LedgeTopY - 64]), '32',
    '1'))]);

  ExpectLoads(GapRows(shOpen), StillPad + ',' + Respawn,
    'A respawn point over a still pad');

  ExpectRaises(ELevelError, GapRows(shOpen),
    PadsSection([PlungingPad]) + ',' + Respawn,
    'A respawn point over a pad that plunges');
  ExpectRaises(ELevelError, GapRows(shOpen), OnPath + ',' + Respawn,
    'A respawn point over a pad on a path');
  ExpectRaises(ELevelError, GapRows(shOpen), Respawn,
    'A respawn point over a gap with no pad in it');
end;

procedure TLevelPadsTests.TestBareShelfComesToItsDefaults;
begin
  UseLevel(GapRows(shOpen), PadsSection([ShelfPad('')]));

  var Shelf := OnlyPad(FLevel).Shelf;
  Assert.IsTrue(Shelf.Slides, 'An empty shelf word is no shelf');
  Assert.AreEqual(2, Integer(Length(Shelf.Steps)), 'The steps of a bare shelf');
  Assert.AreEqual<TShelfStand>(shOut, Shelf.Steps[0].Stand,
    'The first step of a bare shelf');
  Assert.AreEqual<TShelfStand>(shIn, Shelf.Steps[1].Stand,
    'The second step of a bare shelf');
  Assert.IsTrue(Shelf.Steps[0].Seconds > 0, 'The shelf stays out no time');
  Assert.IsTrue(Shelf.Steps[1].Seconds > 0, 'The shelf stays in no time');
  Assert.IsTrue(Shelf.SlideSeconds > 0, 'The shelf slides in no time');
  Assert.IsTrue((Shelf.WarnSeconds >= 0) and
    (Shelf.WarnSeconds < Shelf.Steps[0].Seconds), Format('A warning of %g ' +
    'seconds over a stand of %g', [Shelf.WarnSeconds,
    Shelf.Steps[0].Seconds]));
  Assert.IsTrue(IsNear(Shelf.OffsetSeconds, 0), 'A bare shelf starts late');
  Assert.IsTrue(IsNear(Shelf.Deep.Sink, 0), 'A bare shelf sinks');
  Assert.IsTrue((Shelf.Deep.Scale > 0) and (Shelf.Deep.Scale <= 1),
    Format('In the wall the shelf is %g of its size', [Shelf.Deep.Scale]));
  Assert.IsTrue((Shelf.Deep.Tone >= 0) and (Shelf.Deep.Tone <= 1),
    Format('In the wall the shelf is %g of its light', [Shelf.Deep.Tone]));
end;

procedure TLevelPadsTests.TestShelfReadsWhatItIsGiven;
begin
  UseLevel(GapRows(shOpen), PadsSection([ShelfPad('"out":3,"in":2,' +
    '"slide":0.5,"warn":1,"offset":4,"sink":9,"scale":0.5,"tone":0.2')]));

  var Shelf := OnlyPad(FLevel).Shelf;
  Assert.AreEqual(2, Integer(Length(Shelf.Steps)), 'The steps of out and in');
  ExpectStep(Shelf.Steps[0], shOut, 3, 'The first step');
  ExpectStep(Shelf.Steps[1], shIn, 2, 'The second step');
  Assert.IsTrue(IsNear(Shelf.SlideSeconds, 0.5),
    'The slide is read as written');
  Assert.IsTrue(IsNear(Shelf.WarnSeconds, 1), 'The warning is read as written');
  Assert.IsTrue(IsNear(Shelf.OffsetSeconds, 4),
    'The offset is read as written');
  Assert.IsTrue(IsNear(Shelf.Deep.Sink, 9), 'The sink is read as written');
  Assert.IsTrue(IsNear(Shelf.Deep.Scale, 0.5), 'The scale is read as written');
  Assert.IsTrue(IsNear(Shelf.Deep.Tone, 0.2), 'The tone is read as written');
end;

procedure TLevelPadsTests.TestShelfProgramIsReadInOrder;
begin
  UseLevel(GapRows(shOpen), PadsSection([ShelfPad(
    '"program":[["in",1],["out",2],["in",3],["out",4]]')]));

  var Shelf := OnlyPad(FLevel).Shelf;
  Assert.AreEqual(4, Integer(Length(Shelf.Steps)), 'The steps of the program');
  ExpectStep(Shelf.Steps[0], shIn, 1, 'The first step');
  ExpectStep(Shelf.Steps[1], shOut, 2, 'The second step');
  ExpectStep(Shelf.Steps[2], shIn, 3, 'The third step');
  ExpectStep(Shelf.Steps[3], shOut, 4, 'The fourth step');
end;

procedure TLevelPadsTests.TestShelfStepWordsAreReadInAnyCase;
begin
  UseLevel(GapRows(shOpen), PadsSection([ShelfPad(
    '"program":[["Out",1],["IN",2]]')]));

  var Shelf := OnlyPad(FLevel).Shelf;
  Assert.AreEqual(2, Integer(Length(Shelf.Steps)), 'The steps of the program');
  ExpectStep(Shelf.Steps[0], shOut, 1, 'The step "Out"');
  ExpectStep(Shelf.Steps[1], shIn, 2, 'The step "IN"');
end;

procedure TLevelPadsTests.TestShelfProgramBesideOutOrInRaises;
begin
  var TwoSteps := '"program":[["out",1],["in",1]]';
  ExpectLoads(GapRows(shOpen), PadsSection([ShelfPad(TwoSteps)]),
    'A shelf with a program alone');
  ExpectLoads(GapRows(shOpen), PadsSection([ShelfPad('"out":1,"in":1')]),
    'A shelf with out and in alone');

  ExpectRaises(EPadError, GapRows(shOpen),
    PadsSection([ShelfPad(TwoSteps + ',"out":1')]),
    'A shelf with a program and out');
  ExpectRaises(EPadError, GapRows(shOpen),
    PadsSection([ShelfPad(TwoSteps + ',"in":1')]),
    'A shelf with a program and in');
end;

procedure TLevelPadsTests.TestBadShelfStepRaises;
const
  // Each beside a good step: the bad one is what is turned down
  BadPrograms: array [0 .. 8] of string = (
    '"program":[["out"],["in",1]]',
    '"program":[["out",1,2],["in",1]]',
    '"program":[["sideways",1],["in",1]]',
    '"program":[[1,1],["in",1]]',
    '"program":[["out","1"],["in",1]]',
    '"program":[["out",true],["in",1]]',
    '"program":["out",["in",1]]',
    '"program":[["out",0],["in",1]]',
    '"program":[["out",-1],["in",1]]');
begin
  ExpectLoads(GapRows(shOpen),
    PadsSection([ShelfPad('"program":[["out",1],["in",1]]')]),
    'A program of two good steps');

  for var Bad in BadPrograms do
    ExpectRaises(EPadError, GapRows(shOpen), PadsSection([ShelfPad(Bad)]),
      'A shelf of ' + Bad);
  ExpectRaises(EPadError, GapRows(shOpen), PadsSection([ShelfPad('"out":0')]),
    'A shelf out for 0 seconds');
  ExpectRaises(EPadError, GapRows(shOpen), PadsSection([ShelfPad('"in":-1')]),
    'A shelf in for -1 seconds');
end;

procedure TLevelPadsTests.TestShelfStepsMustTakeTurns;
const
  NoTurns: array [0 .. 3] of string = (
    '"program":[]',
    '"program":[["out",1]]',
    '"program":[["out",1],["out",2]]',
    '"program":[["out",1],["in",1],["out",1]]');
  Turns: array [0 .. 1] of string = (
    '"program":[["in",1],["out",1]]',
    '"program":[["out",1],["in",1],["out",1],["in",1]]');
begin
  for var Good in Turns do
    ExpectLoads(GapRows(shOpen), PadsSection([ShelfPad(Good)]),
      'A shelf of ' + Good);
  for var Bad in NoTurns do
    ExpectRaises(EPadError, GapRows(shOpen), PadsSection([ShelfPad(Bad)]),
      'A shelf of ' + Bad);
end;

procedure TLevelPadsTests.TestBadShelfNumbersRaise;
const
  BadNumbers: array [0 .. 7] of string = ('"slide":-1', '"warn":-1',
    '"offset":-1', '"scale":0', '"scale":1.01', '"scale":-0.5',
    '"tone":-0.1', '"tone":1.1');
  EdgeNumbers: array [0 .. 5] of string = ('"slide":0', '"warn":0',
    '"offset":0', '"scale":1', '"tone":0', '"tone":1');
begin
  for var Edge in EdgeNumbers do
    ExpectLoads(GapRows(shOpen), PadsSection([ShelfPad(Edge)]),
      'A shelf of ' + Edge);
  for var Bad in BadNumbers do
    ExpectRaises(EPadError, GapRows(shOpen), PadsSection([ShelfPad(Bad)]),
      'A shelf of ' + Bad);
end;

procedure TLevelPadsTests.TestShelfMayNotPlungeOrJoinAGroup;
begin
  var Group := '"group":"zone"';

  // The same pads that are no shelf load: the shelf is what is turned down
  ExpectLoads(GapRows(shOpen), PadsSection([ShelfPad('')]), 'A shelf alone');
  ExpectLoads(GapRows(shOpen), PadsSection([PlungingPad]),
    'A pad that plunges and is no shelf');
  ExpectLoads(GapRows(shOpen),
    GroupOfFive(PadJson(GapX, LedgeTopY, Group)) + ',' + GroupZone,
    'A pad in a group that is no shelf');

  ExpectRaises(ELevelError, GapRows(shOpen),
    PadsSection([ShelfPad('', '"plunge":{}')]), 'A shelf that plunges');
  ExpectRaises(ELevelError, GapRows(shOpen),
    GroupOfFive(ShelfPad('', Group)) + ',' + GroupZone,
    'A shelf that joins a group');
end;

procedure TLevelPadsTests.TestShelfMayTravelAPath;
begin
  var Path := PathJson('"pingpong"', Format('[[%d,%d]]',
    [GapX, LedgeTopY - 64]), '32', '1');
  ExpectLoads(GapRows(shOpen), PadsSection([PadJson(GapX, LedgeTopY, Path)]),
    'A pad that travels and is no shelf');

  UseLevel(GapRows(shOpen), PadsSection([ShelfPad('', Path)]));
  var Pad := OnlyPad(FLevel);
  Assert.IsTrue(Pad.Shelf.Slides, 'The shelf that travels is no shelf');
  Assert.AreEqual<TPadRoute>(prPingPong, Pad.Path.Route,
    'The route of the shelf that travels');
end;

procedure TLevelPadsTests.TestRespawnOverAShelfRaises;
begin
  var Respawn := RespawnOverTheGap;
  ExpectLoads(GapRows(shOpen),
    PadsSection([PadJson(GapX, LedgeTopY)]) + ',' + Respawn,
    'A respawn point over a still pad');

  ExpectRaises(ELevelError, GapRows(shOpen),
    PadsSection([ShelfPad('')]) + ',' + Respawn,
    'A respawn point over a shelf');
end;

procedure TLevelPadsTests.TestLevelTwoShelfIsInItsFile;
begin
  FreeAndNil(FLevel);
  FLevel := TLevel.Create;
  FLevel.LoadFromFile(TPath.Combine(ExtractFilePath(ParamStr(0)),
    LevelTwoFile));

  var Found := False;
  var Placement := Default(TPadPlacement);
  for var Pad in FLevel.Pads do
    if Pad.Tag = LevelTwoShelfTag then
    begin
      Found := True;
      Placement := Pad;
    end;

  Assert.IsTrue(Found, 'Level 2 holds no pad tagged ' + LevelTwoShelfTag);
  Assert.AreEqual(LevelTwoShelfScreen, Placement.Screen,
    'The screen of the shelf');
  Assert.IsTrue(Placement.Shelf.Slides, 'The shelf of level 2 does not slide');
  Assert.AreEqual('', Placement.Group, 'The shelf of level 2 joins a group');
  Assert.IsFalse(Placement.Plunge.Plunges, 'The shelf of level 2 plunges');
  for var Step in Placement.Shelf.Steps do
    if Step.Stand = shOut then
      Assert.IsTrue(Placement.Shelf.WarnSeconds < Step.Seconds,
        Format('A warning of %g seconds over a stand of %g',
        [Placement.Shelf.WarnSeconds, Step.Seconds]));
end;

initialization
  TDUnitX.RegisterTestFixture(TLevelPadsTests);

end.
