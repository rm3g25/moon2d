{
  Tests.Levels.Pads - what a level makes of the pads section of its JSON
  and of the respawn points that lean on the pads: what is read as
  written, what a missing member comes to, and which files the level
  turns down - EPadError from the parser, ELevelError from the checks
  that run after it.

  The level is loaded from a one-screen room with the pads and the
  respawns of the test added to its root. The checks of pad groups, of
  the rigs a pad wears and of the events are not tried here.

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
  end;

implementation

uses
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
  var Zone := '"padGroups":[{"tag":"zone","screen":1,"zone":[2,4,13,8],' +
    '"pairs":2,"farFlight":5,"farShare":5}]';

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

initialization
  TDUnitX.RegisterTestFixture(TLevelPadsTests);

end.
