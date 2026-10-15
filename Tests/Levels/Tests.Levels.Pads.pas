{
  Tests.Levels.Pads - what a level makes of the pads section of its JSON
  and of the respawn points that lean on the pads: what is read as
  written, what a missing member comes to, and which files the level
  turns down - EPadError from the parser, ELevelError from the checks
  that run after it.

  The level is loaded from a one-screen room with the pads and the
  respawns of the test added to its root; four tests load level2.json
  beside the executable, for the shelf and the two carousels it holds and
  the floor of the gravel arena. The
  carousels of a level and the entities that sit on a pad lean on the
  pads as the respawns do, and are tried here too. The checks of pad
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
    procedure UseLevelTwo;
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
    procedure TestShelfStandsInEveryBankItIsGiven;
    [Test]
    procedure TestBadShelfBankRaises;
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
    [Test]
    procedure TestCarouselPlacesItsPadsWhereTheyStart;
    [Test]
    procedure TestCarouselPadTakesNoPlaceOfItsOwn;
    [Test]
    procedure TestCarouselAndItsPadsMustMatch;
    [Test]
    procedure TestCarouselPadDoesNothingElse;
    [Test]
    procedure TestCarouselKeepsARoomClearOfWalls;
    [Test]
    procedure TestCarouselStaysOnTheScreen;
    [Test]
    procedure TestCarouselPadsMayNotCutIntoEachOther;
    [Test]
    procedure TestRespawnOverACarouselPadRaises;
    [Test]
    procedure TestEntitySitsOnTheMiddleOfItsPad;
    [Test]
    procedure TestEntityOnACarouselSitsOnTheStartItself;
    [Test]
    procedure TestEntityOnAParkedCarouselWaitsOverThePark;
    [Test]
    procedure TestSeatedEntityTakesNoCell;
    [Test]
    procedure TestSeatOnAnUnknownPadRaises;
    [Test]
    procedure TestLevelTwoCarouselIsInItsFile;
    [Test]
    procedure TestLevelTwoArenaCarouselIsInItsFile;
    [Test]
    procedure TestLevelTwoArenaFloorOfActFourIsOneThroughOne;
    [Test]
    procedure TestLevelTwoArenaPyramidSparesTheHero;
    [Test]
    procedure TestLevelTwoArenaCarouselBreaksInActFive;
    [Test]
    procedure TestLevelTwoArenaFloorOfActFiveComesBackInPieces;
    [Test]
    procedure TestStrayReadsWhatItIsGiven;
    [Test]
    procedure TestBadStrayRaises;
    [Test]
    procedure TestStrayDoesNothingElse;
    [Test]
    procedure TestStrayZoneStaysInItsRoom;
    [Test]
    procedure TestStrayRowsAndColumnsAreClearOfWalls;
    [Test]
    procedure TestStraysOfAnUnknownFlockRaise;
    [Test]
    procedure TestLevelTwoArenaStraysAreLetGoInActFive;
  end;

implementation

uses
  System.IOUtils,
  System.SysUtils,
  Levels.Carousels,
  Levels.Events,
  Levels.Pads,
  Render.Sprites,
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
  // The carousel of level 2, screen 8
  LevelTwoCarouselTag = 's08-carousel';
  LevelTwoCarouselScreen = 8;
  // The carousel of the gravel arena, screen 9, parked until act 4, and
  // the banks of the floor that act 4 wakes and puts to sleep
  LevelTwoArenaCarouselTag = 's09-carousel';
  LevelTwoArenaScreen = 9;
  LevelTwoArenaGridBank = 's09-grid';
  LevelTwoArenaGapsBank = 's09-gaps';
  LevelTwoArenaFloorBank = 's09-floor';
  LevelTwoArenaFlock = 's09-strays';
  // The act the arena carousel breaks and the floor comes back in pieces
  LevelTwoArenaChaosAct = 5;
  // The carousel of the tests: a circle of 80 round (256, 160), a lap in
  // 4 seconds. Its decks go from 176 to 336 across and from 80 to 240
  // down; a pad 32 wide starts on the right at (320, 160) as placed.
  WheelTag = 'wheel';
  // A respawn point on column 11, row 4: its middle is over the first
  // pad of the wheel, its feet above the deck
  RespawnOverTheWheel = '"respawns":[{"screen":1,"x":11,"y":4}]';

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

// A pad that strays in AZone - [left, top, right, bottom] in cells - with
// AExtra beside its stray section and none of a place
function StrayPad(const AZone: string; const AExtra: string = ''): string;
begin
  Result := Format('{"sprite":"%s","screen":1,"width":%d,' +
    '"stray":{"flock":"flock","zone":%s}', [SpriteName, PadWidth, AZone]);
  if AExtra <> '' then
    Result := Result + ',' + AExtra;
  Result := Result + '}';
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

// The sky room: no wall anywhere, nothing for a plunge to hit
function SkyRows: TArray<string>;
begin
  SetLength(Result, RoomRows);
  for var i := 0 to RoomRows - 1 do
    Result[i] := StringOfChar('.', RoomCols);
end;

// The carousel of the tests, its center and size as they stand in a file
function WheelJson(const ACenter: string = '[256,160]';
  const ASize: string = '[160,160]'; AScreen: Integer = 1): string;
begin
  Result := Format('{"tag":"%s","screen":%d,"center":%s,"size":%s,' +
    '"period":4}', [WheelTag, AScreen, ACenter, ASize]);
end;

function CarouselsSection(const ACarousels: array of string): string;
begin
  Result := '"carousels":[' + string.Join(',', ACarousels) + ']';
end;

// A pad that rides the carousel tagged ACarousel, with no place of its own
function RiderJson(const AExtra: string = '';
  const ACarousel: string = WheelTag): string;
begin
  Result := Format('{"sprite":"%s","screen":1,"width":%d,"carousel":"%s"',
    [SpriteName, PadWidth, ACarousel]);
  if AExtra <> '' then
    Result := Result + ',' + AExtra;
  Result := Result + '}';
end;

// The wheel and one rider with AExtra
function WheelOfOne(const AExtra: string = ''): string;
begin
  Result := CarouselsSection([WheelJson]) + ',' +
    PadsSection([RiderJson(AExtra)]);
end;

function EntitiesSection(const AEntities: array of string): string;
begin
  Result := '"entities":[' + string.Join(',', AEntities) + ']';
end;

// A barrel that sits on the pad tagged APad; AExtra beside it
function SeatedJson(const APad: string; const AExtra: string = ''): string;
begin
  Result := Format('{"monsterId":"barrel","screen":1,"seat":"%s"', [APad]);
  if AExtra <> '' then
    Result := Result + ',' + AExtra;
  Result := Result + '}';
end;

function RespawnOverTheGap: string;
begin
  Result := Format('"respawns":[{"screen":1,"x":%d,"y":8}]', [GapCol]);
end;

// The columns of the shelves of ABank on AScreen, in file order, one space
// between two
function BankColumns(const ALevel: TLevel; AScreen: Integer;
  const ABank: string): string;
begin
  var Columns: TArray<string> := [];
  for var Pad in ALevel.Pads do
    if (Pad.Screen = AScreen) and Pad.Shelf.InBank(ABank) then
      Columns := Columns + [IntToStr(Pad.X div TileSize)];
  Result := string.Join(' ', Columns);
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

procedure TLevelPadsTests.UseLevelTwo;
begin
  FreeAndNil(FLevel);
  FLevel := TLevel.Create;
  FLevel.LoadFromFile(TPath.Combine(ExtractFilePath(ParamStr(0)),
    LevelTwoFile));
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
  Assert.AreEqual('', Pad.Carousel, 'A pad rides no carousel unless asked');
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
  Assert.IsFalse(Plunge.StaysDown, 'A pad climbs home unless told otherwise');

  UseLevel(GapRows(shOpen), PadsSection([
    PadJson(GapX, LedgeTopY, '"plunge":{"staysDown":true}')]));
  Assert.IsTrue(OnlyPad(FLevel).Plunge.StaysDown, 'Told so, it stays down');
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

procedure TLevelPadsTests.TestShelfStandsInEveryBankItIsGiven;
begin
  UseLevel(GapRows(shOpen), PadsSection([ShelfPad('"bank":"floor"')]));
  var OneBank := OnlyPad(FLevel).Shelf;
  Assert.IsTrue(OneBank.InBank('floor'), 'A bank given as a name');
  Assert.IsFalse(OneBank.InBank('grid'), 'and no other bank');

  UseLevel(GapRows(shOpen), PadsSection([ShelfPad('"bank":["floor","grid"]')]));
  var TwoBanks := OnlyPad(FLevel).Shelf;
  Assert.AreEqual(2, Integer(Length(TwoBanks.Banks)), 'Banks given as a list');
  Assert.IsTrue(TwoBanks.InBank('floor'), 'The first bank of the list');
  Assert.IsTrue(TwoBanks.InBank('grid'), 'The second bank of the list');
  Assert.IsFalse(TwoBanks.InBank('isle'), 'No bank the list leaves out');

  UseLevel(GapRows(shOpen), PadsSection([ShelfPad('')]));
  Assert.AreEqual(0, Integer(Length(OnlyPad(FLevel).Shelf.Banks)),
    'A shelf with no bank stands in none');
end;

procedure TLevelPadsTests.TestBadShelfBankRaises;
const
  BadBanks: array [0 .. 4] of string = ('"bank":""', '"bank":5',
    '"bank":{}', '"bank":["floor",3]', '"bank":["floor",""]');
begin
  for var Bad in BadBanks do
    ExpectRaises(EPadError, GapRows(shOpen), PadsSection([ShelfPad(Bad)]),
      'A shelf of ' + Bad);
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

// The four pads of the wheel start a quarter of the lap apart, in file
// order, from the right of the middle down: the placement holds the left
// edge of the deck and the deck's height, rounded to whole units
procedure TLevelPadsTests.TestCarouselPlacesItsPadsWhereTheyStart;
const
  Expected: array [0 .. 3, 0 .. 1] of Integer =
    ((320, 160), (240, 240), (160, 160), (240, 80));
begin
  UseLevel(OpenRows, CarouselsSection([WheelJson]) + ',' +
    PadsSection([RiderJson, RiderJson, RiderJson, RiderJson]));

  Assert.AreEqual(1, Integer(Length(FLevel.Carousels)), 'One carousel');
  Assert.AreEqual(WheelTag, FLevel.Carousels[0].Tag);
  Assert.AreEqual(4, Integer(Length(FLevel.Pads)), 'Four pads');
  for var i := 0 to 3 do
  begin
    var Pad := FLevel.Pads[i];
    Assert.AreEqual(WheelTag, Pad.Carousel, Format('Pad %d rides', [i]));
    Assert.AreEqual(Expected[i, 0], Pad.X, Format('The x of pad %d', [i]));
    Assert.AreEqual(Expected[i, 1], Pad.Y, Format('The y of pad %d', [i]));
  end;
end;

procedure TLevelPadsTests.TestCarouselPadTakesNoPlaceOfItsOwn;
begin
  ExpectLoads(OpenRows, WheelOfOne, 'A rider with no place');
  ExpectRaises(EPadError, OpenRows, WheelOfOne('"x":96'), 'A rider with an x');
  ExpectRaises(EPadError, OpenRows, WheelOfOne('"y":160'), 'A rider with a y');
end;

// A pad on a carousel the level has not, a carousel with no pad, two
// carousels of one tag, a carousel off the screen list
procedure TLevelPadsTests.TestCarouselAndItsPadsMustMatch;
begin
  ExpectLoads(OpenRows, WheelOfOne, 'The wheel and its rider');
  ExpectRaises(ELevelError, OpenRows, CarouselsSection([WheelJson]) + ',' +
    PadsSection([RiderJson, RiderJson('', 'whel')]),
    'A rider of a misspelt carousel beside one of the wheel');
  ExpectRaises(ELevelError, OpenRows, CarouselsSection([WheelJson]) + ',' +
    PadsSection([PadJson(96, 160)]), 'A carousel that carries no pad');
  ExpectRaises(ELevelError, OpenRows, CarouselsSection([WheelJson,
    WheelJson('[256,192]')]) + ',' + PadsSection([RiderJson]),
    'Two carousels of one tag');
  ExpectRaises(ELevelError, OpenRows, CarouselsSection([WheelJson(
    '[256,160]', '[160,160]', 2)]) + ',' + PadsSection([RiderJson]),
    'A carousel on a screen the level has not');
end;

// The sky room: a still pad where the rider starts may travel, plunge or
// be a shelf; the rider may do none of it, and may join no group
procedure TLevelPadsTests.TestCarouselPadDoesNothingElse;
const
  PathTo = '"path":{"stops":[[200,160]],"speed":32}';
begin
  ExpectLoads(SkyRows, WheelOfOne, 'The rider alone');
  ExpectLoads(SkyRows, PadsSection([PadJson(320, 160, PathTo)]),
    'A still pad there on a path');
  ExpectLoads(SkyRows, PadsSection([PadJson(320, 160, '"plunge":{}')]),
    'A still pad there that plunges');
  ExpectLoads(SkyRows, PadsSection([PadJson(320, 160, '"shelf":{}')]),
    'A still pad there that is a shelf');

  ExpectRaises(ELevelError, SkyRows, WheelOfOne(PathTo),
    'A rider on a path');
  ExpectRaises(ELevelError, SkyRows, WheelOfOne('"plunge":{}'),
    'A rider that plunges');
  ExpectRaises(ELevelError, SkyRows, WheelOfOne('"shelf":{}'),
    'A rider that is a shelf');
  ExpectRaises(ELevelError, SkyRows, WheelOfOne('"group":"zone"') + ',' +
    GroupZone, 'A rider in a group');
end;

// A rider keeps a cell clear above its deck, for what stands on it, and
// a cell below, for its body: the top deck flies at 80, the bottom at 240
procedure TLevelPadsTests.TestCarouselKeepsARoomClearOfWalls;
begin
  ExpectLoads(RoomRowsOf(0, 1, 8, 9), WheelOfOne,
    'A ledge on row 1, two cells over the top deck');
  ExpectRaises(ELevelError, RoomRowsOf(0, 2, 8, 9), WheelOfOne,
    'A ledge on row 2, within a cell over the top deck');
  ExpectLoads(RoomRowsOf(0, 10, 8, 9), WheelOfOne,
    'A ledge on row 10, two cells under the bottom deck');
  ExpectRaises(ELevelError, RoomRowsOf(0, 9, 8, 9), WheelOfOne,
    'A ledge on row 9, within a cell under the bottom deck');
  ExpectRaises(ELevelError, RoomRowsOf(6, 0, 0, 0), WheelOfOne,
    'A wall on column 6, in the way of the left side');
end;

// A rider and its room stay on the screen all the way round
procedure TLevelPadsTests.TestCarouselStaysOnTheScreen;
begin
  ExpectLoads(OpenRows, CarouselsSection([WheelJson('[256,112]')]) + ',' +
    PadsSection([RiderJson]), 'The top deck at 32, its room up to the edge');
  ExpectRaises(ELevelError, OpenRows, CarouselsSection([WheelJson(
    '[256,100]')]) + ',' + PadsSection([RiderJson]),
    'The top deck at 20, its room over the edge');
  ExpectRaises(ELevelError, OpenRows, CarouselsSection([WheelJson(
    '[460,160]')]) + ',' + PadsSection([RiderJson]),
    'The right deck past the right edge');
end;

// Two riders half a lap apart on a circle of 10 cut into one another;
// on the wheel they do not
procedure TLevelPadsTests.TestCarouselPadsMayNotCutIntoEachOther;
begin
  ExpectLoads(OpenRows, CarouselsSection([WheelJson]) + ',' +
    PadsSection([RiderJson, RiderJson]), 'Two riders on the wheel');
  ExpectRaises(ELevelError, OpenRows, CarouselsSection([WheelJson(
    '[256,160]', '[20,20]')]) + ',' + PadsSection([RiderJson, RiderJson]),
    'Two riders on a circle of 10');
end;

procedure TLevelPadsTests.TestRespawnOverACarouselPadRaises;
begin
  ExpectLoads(SkyRows, PadsSection([PadJson(320, 160)]) + ',' +
    RespawnOverTheWheel, 'Over a still pad where the rider starts');
  ExpectRaises(ELevelError, SkyRows, WheelOfOne + ',' + RespawnOverTheWheel,
    'Over the rider');
end;

// A pad 64 wide at (100, 160): its middle is 132, so a body a cell wide
// stands from 116, its feet on 160; its cell is the nearest, 5 and 5. An
// entity with no seat keeps its cell.
procedure TLevelPadsTests.TestEntitySitsOnTheMiddleOfItsPad;
begin
  UseLevel(OpenRows, PadsSection([PadJson(100, 160, '"tag":"bench"', 64)]) +
    ',' + EntitiesSection([SeatedJson('bench'),
    '{"monsterId":"barrel","screen":1,"x":12,"y":3}']));

  var Seated := FLevel.Entities[0];
  Assert.AreEqual('bench', Seated.Seat);
  Assert.IsTrue(IsNear(Seated.SeatLeft, 116), Format('It stands from %g',
    [Seated.SeatLeft]));
  Assert.IsTrue(IsNear(Seated.SeatFeet, 160), Format('Its feet are on %g',
    [Seated.SeatFeet]));
  Assert.AreEqual(5, Seated.X, 'The column nearest');
  Assert.AreEqual(5, Seated.Y, 'The row nearest');

  var Standing := FLevel.Entities[1];
  Assert.AreEqual('', Standing.Seat);
  Assert.AreEqual(12, Standing.X, 'An entity with no seat keeps its column');
  Assert.AreEqual(3, Standing.Y, 'and its row');
end;

// A wheel round (256.4, 160.3): the rider is placed at (320, 160), and the
// entity on it sits where the deck truly starts, 320.4 and 160.3
procedure TLevelPadsTests.TestEntityOnACarouselSitsOnTheStartItself;
begin
  UseLevel(OpenRows, CarouselsSection([WheelJson('[256.4,160.3]')]) + ',' +
    PadsSection([RiderJson('"tag":"ride"')]) + ',' +
    EntitiesSection([SeatedJson('ride')]));

  Assert.AreEqual(320, FLevel.Pads[0].X, 'The rider is placed rounded');
  Assert.AreEqual(160, FLevel.Pads[0].Y, 'in x and in y');
  var Seated := FLevel.Entities[0];
  Assert.IsTrue(Abs(Seated.SeatLeft - 320.4) < 0.001, Format('It stands ' +
    'from %g', [Seated.SeatLeft]));
  Assert.IsTrue(Abs(Seated.SeatFeet - 160.3) < 0.001, Format('Its feet are ' +
    'on %g', [Seated.SeatFeet]));
end;

procedure TLevelPadsTests.TestEntityOnAParkedCarouselWaitsOverThePark;
begin
  var ParkedWheel := Format('{"tag":"%s","screen":1,"center":[256,160],' +
    '"size":[160,160],"period":4,"parked":"above"}', [WheelTag]);
  UseLevel(OpenRows, CarouselsSection([ParkedWheel]) + ',' +
    PadsSection([RiderJson('"tag":"ride"')]) + ',' +
    EntitiesSection([SeatedJson('ride')]));

  var Seated := FLevel.Entities[0];
  Assert.IsTrue(Abs(Seated.SeatLeft - 320) < 0.001, Format('It stands over ' +
    'its slot, from %g', [Seated.SeatLeft]));
  Assert.IsTrue(Abs(Seated.SeatFeet - PadParkedTop) < 0.001, Format('Its ' +
    'feet are on the parked deck, not on %g', [Seated.SeatFeet]));
end;

procedure TLevelPadsTests.TestSeatedEntityTakesNoCell;
begin
  var Bench := PadsSection([PadJson(100, 160, '"tag":"bench"', 64)]);
  ExpectLoads(OpenRows, Bench + ',' + EntitiesSection([SeatedJson('bench')]),
    'An entity on a seat');
  ExpectRaises(ELevelError, OpenRows, Bench + ',' +
    EntitiesSection([SeatedJson('bench', '"x":4')]), 'A seat and an x');
  ExpectRaises(ELevelError, OpenRows, Bench + ',' +
    EntitiesSection([SeatedJson('bench', '"y":5')]), 'A seat and a y');
end;

procedure TLevelPadsTests.TestSeatOnAnUnknownPadRaises;
begin
  ExpectRaises(ELevelError, OpenRows,
    PadsSection([PadJson(100, 160, '"tag":"bench"', 64)]) + ',' +
    EntitiesSection([SeatedJson('bnech')]), 'A seat on a misspelt pad');
end;

// The hall of screen 8: the carousel turns clockwise, and every pad it
// carries has one entity on it - two betoners, barrels on the rest
procedure TLevelPadsTests.TestLevelTwoCarouselIsInItsFile;
var
  Carousel: TCarousel;
begin
  FreeAndNil(FLevel);
  FLevel := TLevel.Create;
  FLevel.LoadFromFile(TPath.Combine(ExtractFilePath(ParamStr(0)),
    LevelTwoFile));

  Assert.IsTrue(TryFindCarousel(FLevel.Carousels, LevelTwoCarouselTag,
    Carousel), 'Level 2 holds no carousel tagged ' + LevelTwoCarouselTag);
  Assert.AreEqual(LevelTwoCarouselScreen, Carousel.Screen,
    'The screen of the carousel');
  Assert.AreEqual<TCarouselTurn>(ctClockwise, Carousel.Turn);

  var Riders := 0;
  var Betoners := 0;
  for var Pad in FLevel.Pads do
  begin
    if Pad.Carousel <> LevelTwoCarouselTag then
      Continue;
    Inc(Riders);
    var Seated := 0;
    for var Entity in FLevel.Entities do
      if (Entity.Seat <> '') and (Entity.Seat = Pad.Tag) then
      begin
        Inc(Seated);
        if Entity.MonsterId = 'betoner' then
          Inc(Betoners)
        else
          Assert.AreEqual('barrel', Entity.MonsterId,
            'On ' + Pad.Tag + ' sits neither a betoner nor a barrel');
      end;
    Assert.AreEqual(1, Seated, 'Entities on ' + Pad.Tag);
  end;
  Assert.IsTrue(Riders > 2, Format('The carousel carries %d pads', [Riders]));
  Assert.AreEqual(2, Betoners, 'Betoners on the carousel');
end;

// Two medkits ride it half a lap apart: a pad's slot is its place among
// the riders in file order
procedure TLevelPadsTests.TestLevelTwoArenaCarouselIsInItsFile;
var
  Carousel: TCarousel;
begin
  UseLevelTwo;

  Assert.IsTrue(TryFindCarousel(FLevel.Carousels, LevelTwoArenaCarouselTag,
    Carousel), 'Level 2 holds no carousel tagged ' + LevelTwoArenaCarouselTag);
  Assert.AreEqual(LevelTwoArenaScreen, Carousel.Screen,
    'The screen of the carousel');
  Assert.AreEqual<TCarouselShape>(csBox, Carousel.Shape);
  Assert.IsTrue(Carousel.Parked, 'It waits above the screen until act 4');

  var Riders := 0;
  var MedkitSlots: TArray<Integer> := [];
  for var Pad in FLevel.Pads do
  begin
    if Pad.Carousel <> LevelTwoArenaCarouselTag then
      Continue;
    for var Entity in FLevel.Entities do
      if Entity.Seat = Pad.Tag then
      begin
        Assert.AreEqual('medkit', Entity.MonsterId,
          'On ' + Pad.Tag + ' sits something other than a medkit');
        MedkitSlots := MedkitSlots + [Riders];
      end;
    Inc(Riders);
  end;
  Assert.IsTrue(Riders >= 2, Format('The carousel carries %d pads', [Riders]));
  Assert.AreEqual(2, Integer(Length(MedkitSlots)), 'Medkits on the carousel');
  Assert.AreEqual(Riders div 2, Abs(MedkitSlots[1] - MedkitSlots[0]),
    'The medkits ride half a lap apart');
end;

// Columns 4, 6, 8, 10 and 14 wake in act 4; the old isle's columns 5 and
// 11 go to sleep. Every one of them is a shelf of the floor, so act 3 takes
// them away with the rest.
procedure TLevelPadsTests.TestLevelTwoArenaFloorOfActFourIsOneThroughOne;
const
  FloorBank = 's09-floor';
begin
  UseLevelTwo;

  Assert.AreEqual('4 6 8 10 14',
    BankColumns(FLevel, LevelTwoArenaScreen, LevelTwoArenaGridBank),
    'The columns of the floor that wakes in act 4');
  Assert.AreEqual('5 11',
    BankColumns(FLevel, LevelTwoArenaScreen, LevelTwoArenaGapsBank),
    'The columns of the floor that sleeps in act 4');
  for var Pad in FLevel.Pads do
  begin
    var OfActFour := Pad.Shelf.InBank(LevelTwoArenaGridBank) or
      Pad.Shelf.InBank(LevelTwoArenaGapsBank);
    if OfActFour then
      Assert.IsTrue(Pad.Shelf.InBank(FloorBank),
        Pad.Tag + ' is not a shelf of the floor');
  end;
end;

// The act 4 pyramid waits for the hero to step off; the floor goes under
// his feet in act 3 and in act 5
procedure TLevelPadsTests.TestLevelTwoArenaPyramidSparesTheHero;
const
  PyramidBank = 's09-pyramid';
  FloorBank = 's09-floor';
begin
  UseLevelTwo;

  var PyramidSleeps := 0;
  var FloorSleeps := 0;
  for var Event in FLevel.Events do
    for var Action in Event.Actions do
    begin
      if Action.Kind <> eaShelvesSleep then
        Continue;
      if Action.Target = PyramidBank then
      begin
        Inc(PyramidSleeps);
        Assert.IsTrue(Action.SpareHero, 'The pyramid spares the hero');
      end;
      if Action.Target = FloorBank then
      begin
        Inc(FloorSleeps);
        Assert.IsFalse(Action.SpareHero, 'The floor does not');
      end;
    end;
  Assert.AreEqual(1, PyramidSleeps, 'The pyramid is told to sleep once');
  Assert.AreEqual(2, FloorSleeps, 'The floor is told to sleep twice');
end;

// The event of act 5 breaks it; every pad of it has a tag, and the rigs of
// the failing look hang on the tag made from it
procedure TLevelPadsTests.TestLevelTwoArenaCarouselBreaksInActFive;
var
  Carousel: TCarousel;
begin
  UseLevelTwo;

  Assert.IsTrue(TryFindCarousel(FLevel.Carousels, LevelTwoArenaCarouselTag,
    Carousel), 'Level 2 holds no carousel tagged ' + LevelTwoArenaCarouselTag);
  Assert.IsTrue(Carousel.Failing.Breaks, 'The arena carousel may break');
  Assert.IsTrue(Carousel.Failing.Plunge.Plunges, 'Its pads plunge then');
  Assert.IsTrue(Carousel.Failing.Plunge.StaysDown,
    'A broken pad that falls under the hero does not come back');

  var Breaks := 0;
  for var Event in FLevel.Events do
    for var Action in Event.Actions do
      if (Action.Kind = eaBreakCarousel) and
        (Action.Target = LevelTwoArenaCarouselTag) then
      begin
        Inc(Breaks);
        Assert.AreEqual(LevelTwoArenaChaosAct, Event.Act,
          'The act the carousel breaks in');
      end;
  Assert.AreEqual(1, Breaks, 'The carousel is broken once');

  for var Pad in FLevel.Pads do
  begin
    if Pad.Carousel <> LevelTwoArenaCarouselTag then
      Continue;
    var Hung := 0;
    for var DynamicObject in FLevel.Dynamics do
      if DynamicObject.Placement.Parent = FailingRigTag(Pad.Tag) then
        Inc(Hung);
    Assert.IsTrue(Hung > 0, 'No part of the failing look hangs on ' + Pad.Tag);
  end;
end;

// Act 5 puts the whole floor to sleep and wakes a few shelves of it, as the
// dice pick them: the wake replaces the sleep of the shelves it picks
procedure TLevelPadsTests.TestLevelTwoArenaFloorOfActFiveComesBackInPieces;
begin
  UseLevelTwo;

  var Shelves := 0;
  for var Pad in FLevel.Pads do
    if Pad.Shelf.InBank(LevelTwoArenaFloorBank) then
      Inc(Shelves);

  var Sleeps := 0;
  var Wakes := 0;
  for var Event in FLevel.Events do
  begin
    if (Event.Condition <> ecActReached) or
      (Event.Act <> LevelTwoArenaChaosAct) then
      Continue;
    for var Action in Event.Actions do
    begin
      if Action.Target <> LevelTwoArenaFloorBank then
        Continue;
      if Action.Kind = eaShelvesSleep then
      begin
        Inc(Sleeps);
        Assert.AreEqual(0, Wakes, 'The floor sleeps before it wakes');
        Assert.AreEqual(0, Action.Telling.Pick, 'The whole floor sleeps');
      end;
      if Action.Kind = eaShelvesWake then
      begin
        Inc(Wakes);
        var Pick := Action.Telling.Pick;
        Assert.IsTrue((Pick > 0) and (Pick < Shelves), Format('%d of %d ' +
          'floor shelves wake', [Pick, Shelves]));
      end;
    end;
  end;
  Assert.AreEqual(1, Sleeps, 'The floor of act 5 is told to sleep once');
  Assert.AreEqual(1, Wakes, 'The floor of act 5 is told to wake once');
end;

// The gap room's shaft, column 8, is open from the top to the bottom: a pad
// strays down it
procedure TLevelPadsTests.TestStrayReadsWhatItIsGiven;
begin
  UseLevel(GapRows(shOpen), PadsSection([Format('{"sprite":"%s","screen":1,' +
    '"width":32,"stray":{"flock":"birds","zone":[8,2,8,7],"wait":1.5}}',
    [SpriteName])]));

  var Stray := OnlyPad(FLevel).Stray;
  Assert.IsTrue(Stray.Strays, 'It strays');
  Assert.AreEqual('birds', Stray.Flock);
  Assert.AreEqual(8, Stray.Zone.Left);
  Assert.AreEqual(2, Stray.Zone.Top);
  Assert.AreEqual(8, Stray.Zone.Right);
  Assert.AreEqual(7, Stray.Zone.Bottom);
  Assert.IsTrue(IsNear(Stray.Wait, 1.5), 'The wait');
  Assert.AreEqual(PadStrayWaitLeft, OnlyPad(FLevel).X, 'It waits off the left');
  Assert.AreEqual(PadParkedTop, OnlyPad(FLevel).Y, 'As high as a parked pad');

  UseLevel(GapRows(shOpen), PadsSection([StrayPad('[8,2,8,7]')]));
  Assert.IsTrue(IsNear(OnlyPad(FLevel).Stray.Wait, 0), 'No wait by default');
  UseLevel(OpenRows, PadsSection([PadJson(96, 160)]));
  Assert.IsFalse(OnlyPad(FLevel).Stray.Strays, 'A pad strays only when asked');
end;

procedure TLevelPadsTests.TestBadStrayRaises;
begin
  ExpectRaises(EPadError, GapRows(shOpen),
    PadsSection([StrayPad('[8,2,8,7]', '"x":256,"y":64')]),
    'A pad that strays given a place');
  ExpectRaises(EPadError, GapRows(shOpen), PadsSection([Format(
    '{"sprite":"%s","screen":1,"width":32,"stray":{"zone":[8,2,8,7]}}',
    [SpriteName])]), 'A pad that strays in no flock');
  ExpectRaises(EPadError, GapRows(shOpen), PadsSection([StrayPad('[8,2,8]')]),
    'A zone of three numbers');
  ExpectRaises(EPadError, GapRows(shOpen), PadsSection([Format(
    '{"sprite":"%s","screen":1,"width":32,"stray":{"flock":"flock",' +
    '"zone":[8,2,8,7],"wait":-1}}', [SpriteName])]), 'A wait below 0');
end;

procedure TLevelPadsTests.TestStrayDoesNothingElse;
begin
  ExpectLoads(GapRows(shOpen), PadsSection([StrayPad('[8,2,8,7]')]),
    'A pad that strays and does nothing else');
  ExpectRaises(ELevelError, GapRows(shOpen),
    PadsSection([StrayPad('[8,2,8,7]', '"plunge":{}')]),
    'A pad that strays and plunges');
  ExpectRaises(ELevelError, GapRows(shOpen),
    PadsSection([StrayPad('[8,2,8,7]', '"path":{"stops":[[256,64]],"speed":32}')]),
    'A pad that strays and travels a path');
end;

// The room is the screen less a cell at the left, the right and the top
procedure TLevelPadsTests.TestStrayZoneStaysInItsRoom;
begin
  ExpectRaises(ELevelError, GapRows(shOpen), PadsSection([StrayPad('[0,2,8,7]')]),
    'A zone in the left wall');
  ExpectRaises(ELevelError, GapRows(shOpen), PadsSection([StrayPad('[8,0,8,7]')]),
    'A zone in the top row');
  ExpectRaises(ELevelError, GapRows(shOpen), PadsSection([StrayPad('[8,2,15,7]')]),
    'A zone whose pad reaches into the right wall');
  ExpectRaises(ELevelError, GapRows(shOpen), PadsSection([StrayPad('[8,7,8,2]')]),
    'A zone upside down');
  ExpectRaises(ELevelError, GapRows(shOpen), PadsSection([StrayPad('[8,2,8,12]')]),
    'A zone past the bottom');
end;

procedure TLevelPadsTests.TestStrayRowsAndColumnsAreClearOfWalls;
begin
  ExpectRaises(ELevelError, GapRows(shOpen), PadsSection([StrayPad('[7,2,8,7]')]),
    'Column 7 falls onto the floor');
  ExpectRaises(ELevelError, GapRows(shOpen), PadsSection([StrayPad('[8,2,8,9]')]),
    'Row 9 runs into the floor');
  ExpectRaises(ELevelError, GapRows(shPlugged),
    PadsSection([StrayPad('[8,2,8,7]')]), 'The shaft under column 8 plugged');
end;

procedure TLevelPadsTests.TestStraysOfAnUnknownFlockRaise;
const
  Event = ',"events":[{"id":"go","screen":1,"when":"enterScreen",' +
    '"then":[{"action":"strays","target":"%s"}]}]';
begin
  var Pads := PadsSection([StrayPad('[8,2,8,7]')]);
  ExpectLoads(GapRows(shOpen), Pads + Format(Event, ['flock']),
    'Its own flock let go');
  ExpectRaises(ELevelError, GapRows(shOpen), Pads + Format(Event, ['nobody']),
    'A flock no pad strays in');
end;

// The act 5 event lets the flock go once
procedure TLevelPadsTests.TestLevelTwoArenaStraysAreLetGoInActFive;
begin
  UseLevelTwo;

  var Strays := 0;
  for var Pad in FLevel.Pads do
    if Pad.Stray.Strays and (Pad.Stray.Flock = LevelTwoArenaFlock) then
    begin
      Inc(Strays);
      Assert.AreEqual(LevelTwoArenaScreen, Pad.Screen, Pad.Tag + ' strays off the arena');
    end;
  Assert.IsTrue(Strays > 0, 'No pad strays in ' + LevelTwoArenaFlock);

  var LetGo := 0;
  for var Event in FLevel.Events do
    for var Action in Event.Actions do
      if (Action.Kind = eaStrays) and (Action.Target = LevelTwoArenaFlock) then
      begin
        Inc(LetGo);
        Assert.AreEqual(LevelTwoArenaChaosAct, Event.Act,
          'The act the flock is let go in');
      end;
  Assert.AreEqual(1, LetGo, 'The flock is let go once');
end;

initialization
  TDUnitX.RegisterTestFixture(TLevelPadsTests);

end.
