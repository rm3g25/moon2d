{
  Tests.Pads.World - the pad a scene keeps asleep and wakes: neither a
  floor nor a body while it sleeps, both once awake, flown straight to a
  place of its screen, and asleep again after a rewind. A pad the game
  puts to sleep is gone the same way, from among the screen's standing
  pads too, and a rewind gives it back as the file has it.

  The pad names no sprite, so the world asks no art for it, as for a deck
  of the collision grid: no stage is needed. The level wakes a dormant
  pad only when a scene does, so the room carries one that does; the test
  wakes and flies the pad itself, as the scene would. The rest of the
  world is designed in the table of the unit and waits for the stage.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Pads.World;

interface

uses
  DUnitX.TestFramework,
  Levels.Defs,
  Pads.World;

type
  [TestFixture]
  TPadWorldTests = class
  private
    FLevel: TLevel;
    FWorld: TPadWorld;
    function Sleeper: TPad;
    procedure TickWorld(ATimes: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestDormantPadIsNoFloorAndNoBody;
    [Test]
    procedure TestWokenPadIsAFloorAndABody;
    [Test]
    procedure TestFlownInNoTicksItIsThereAtOnce;
    [Test]
    procedure TestFlownPadGoesStraightThereAndStays;
    [Test]
    procedure TestFlyingPadWorksItsJets;
    [Test]
    procedure TestFlyingPadCarriesWhatStandsOnIt;
    [Test]
    procedure TestRewindPutsTheWokenPadBackToSleep;
    [Test]
    procedure TestDozedPadIsGone;
    [Test]
    procedure TestRewindGivesBackADozedPad;
  end;

implementation

uses
  System.Math,
  System.SysUtils,
  Tests.Rooms;

const
  Screen = 1;
  SleeperTag = 'sleeper';
  // Where the file puts the dormant pad, and where it is flown
  HomeX = 96;
  HomeY = 224;
  AwayX = 224;
  AwayY = 128;
  FlightTicks = 30;
  // A hero's feet span this wide, in the middle of a deck 32 across
  FeetInset = 8;
  FeetWidth = 16;
  UnitSlack = 0.001;
  Sections = '"pads":[{"sprite":"","screen":1,"x":96,"y":224,"width":32,' +
    '"tag":"sleeper","dormant":true}],' +
    '"scenes":[{"id":"waking","screen":1,"cues":[' +
    '{"at":0,"do":"wake","target":"sleeper"}]}]';
  // A pad the file keeps awake, for the game to put to sleep
  StanderSections = '"pads":[{"sprite":"","screen":1,"x":96,"y":224,' +
    '"width":32,"tag":"stander"}]';

procedure TPadWorldTests.Setup;
begin
  FLevel := LevelFromRows(RoomRowsOf(0, 0, 0, 0), Sections);
  FWorld := TPadWorld.Create(nil, nil, FLevel, nil, 1);
end;

procedure TPadWorldTests.TearDown;
begin
  FreeAndNil(FWorld);
  FreeAndNil(FLevel);
end;

function TPadWorldTests.Sleeper: TPad;
begin
  Result := FWorld.FindTagged(SleeperTag);
  Assert.IsNotNull(Result, 'The world finds the pad by its tag');
end;

procedure TPadWorldTests.TickWorld(ATimes: Integer);
begin
  for var i := 1 to ATimes do
    FWorld.Tick(Screen, nil);
end;

function IsAt(const APad: TPad; AX, AY: Double): Boolean;
begin
  Result := (Abs(APad.Left - AX) < UnitSlack) and
    (Abs(APad.Top - AY) < UnitSlack);
end;

function FeetLeft(const APad: TPad): Double;
begin
  Result := APad.Left + FeetInset;
end;

procedure ExpectThere(const AWorld: TPadWorld; const APad: TPad;
  AThere: Boolean; const AWhen: string);
begin
  var Left := FeetLeft(APad);
  var Deck := AWorld.DeckUnder(Screen, Left, Left + FeetWidth, APad.Top);
  var Middle := APad.Left + APad.Placement.Width / 2;
  if AThere then
  begin
    Assert.IsTrue(Deck = APad, AWhen + ': feet on the deck stand on it');
    Assert.IsTrue(AWorld.BodyAt(Screen, Middle, APad.Top + 4),
      AWhen + ': a point in the body meets it');
    Assert.IsTrue(AWorld.StopsBulletAt(Screen, Middle, APad.Top + 4),
      AWhen + ': a bullet in the body bursts');
    Assert.AreEqual(1, Integer(Length(AWorld.Bodies(Screen))),
      AWhen + ': the bodies of the screen');
    Assert.IsFalse(APad.Behind, AWhen + ': behind');
  end
  else
  begin
    Assert.IsNull(Deck, AWhen + ': feet on the deck stand on air');
    Assert.IsNull(AWorld.DeckCrossed(Screen, Left, Left + FeetWidth,
      APad.Top - 40, APad.Top + 40, nil), AWhen + ': a fall goes through');
    Assert.IsFalse(AWorld.BodyAt(Screen, Middle, APad.Top + 4),
      AWhen + ': a point in the body meets something');
    Assert.IsFalse(AWorld.StopsBulletAt(Screen, Middle, APad.Top + 4),
      AWhen + ': a bullet in the body bursts');
    Assert.AreEqual(0, Integer(Length(AWorld.Bodies(Screen))),
      AWhen + ': the bodies of the screen');
    Assert.IsTrue(APad.Behind, AWhen + ': not behind');
  end;
end;

procedure TPadWorldTests.TestDormantPadIsNoFloorAndNoBody;
begin
  var Pad := Sleeper;

  Assert.IsTrue(Pad.Dormant, 'The file puts it to sleep');
  ExpectThere(FWorld, Pad, False, 'Born');
  TickWorld(30);
  Assert.IsTrue(Pad.Dormant, 'It sleeps on with nobody to wake it');
  ExpectThere(FWorld, Pad, False, 'Thirty ticks on');
end;

procedure TPadWorldTests.TestWokenPadIsAFloorAndABody;
begin
  var Pad := Sleeper;

  Pad.Wake;

  Assert.IsFalse(Pad.Dormant, 'Woken');
  ExpectThere(FWorld, Pad, True, 'Woken');
  TickWorld(30);
  ExpectThere(FWorld, Pad, True, 'Thirty ticks on');
  Assert.IsTrue(IsAt(Pad, HomeX, HomeY),
    'It wakes where the file puts it');
end;

procedure TPadWorldTests.TestFlownInNoTicksItIsThereAtOnce;
begin
  var Pad := Sleeper;
  Pad.Wake;
  var OldLeft := FeetLeft(Pad);

  Pad.FlyTo(AwayX, AwayY, 0);

  Assert.IsTrue(IsAt(Pad, AwayX, AwayY),
    'There before a tick');
  Assert.IsFalse(Pad.Flying, 'No flight to fly');
  Assert.IsNull(FWorld.DeckCarrying(Screen, OldLeft, OldLeft + FeetWidth,
    HomeY), 'What stood on it is left in the air');
  TickWorld(30);
  Assert.IsTrue(IsAt(Pad, AwayX, AwayY),
    'And it stays');
end;

procedure TPadWorldTests.TestFlownPadGoesStraightThereAndStays;
begin
  var Pad := Sleeper;
  Pad.Wake;
  var Span: Double := Hypot(Double(AwayX - HomeX), Double(AwayY - HomeY));
  var LastLeft := Span;

  Pad.FlyTo(AwayX, AwayY, FlightTicks);

  Assert.IsTrue(Pad.Flying, 'Sent off over ticks: in a flight');
  for var i := 1 to 3 * FlightTicks do
  begin
    TickWorld(1);
    var Gone := Hypot(Pad.Left - HomeX, Pad.Top - HomeY);
    var Left := Hypot(AwayX - Pad.Left, AwayY - Pad.Top);
    Assert.IsTrue(Abs(Gone + Left - Span) < UnitSlack,
      Format('Tick %d: off the straight line', [i]));
    Assert.IsTrue(Left <= LastLeft + UnitSlack,
      Format('Tick %d: it turned back', [i]));
    if i >= FlightTicks then
      Assert.IsTrue(Left < UnitSlack, Format('Tick %d: not there yet', [i]));
    LastLeft := Left;
  end;
  Assert.IsFalse(Pad.Flying, 'The flight is over');
  ExpectThere(FWorld, Pad, True, 'Landed');
end;

procedure TPadWorldTests.TestFlyingPadWorksItsJets;
begin
  var Pad := Sleeper;
  Pad.Wake;
  TickWorld(5);
  Assert.IsFalse(Pad.Thrusting, 'At rest the jets are quiet');

  Pad.FlyTo(AwayX, AwayY, FlightTicks);

  for var i := 1 to FlightTicks - 1 do
  begin
    TickWorld(1);
    Assert.IsTrue(Pad.Thrusting, Format('Tick %d of the flight', [i]));
    Assert.IsTrue(Pad.Effort = 1, Format('Tick %d: effort %g',
      [i, Pad.Effort]));
  end;
  TickWorld(FlightTicks);
  Assert.IsFalse(Pad.Thrusting, 'Landed, the jets are quiet again');
end;

procedure TPadWorldTests.TestFlyingPadCarriesWhatStandsOnIt;
begin
  var Pad := Sleeper;
  Pad.Wake;

  Pad.FlyTo(AwayX, AwayY, FlightTicks);

  for var i := 1 to FlightTicks do
  begin
    var Left := FeetLeft(Pad);
    var FeetY := Pad.Top;
    TickWorld(1);
    Assert.IsTrue(FWorld.DeckCarrying(Screen, Left, Left + FeetWidth,
      FeetY) = Pad, Format('Tick %d: feet where the deck stood a tick ago ' +
      'are not carried', [i]));
  end;
end;

procedure TPadWorldTests.TestRewindPutsTheWokenPadBackToSleep;
begin
  var Pad := Sleeper;
  Pad.Wake;
  Pad.FlyTo(AwayX, AwayY, FlightTicks);
  TickWorld(FlightTicks div 2);

  FWorld.Rewind(1);

  Assert.IsTrue(Pad.Dormant, 'Asleep again');
  Assert.IsFalse(Pad.Flying, 'No flight left');
  Assert.IsTrue(IsAt(Pad, HomeX, HomeY),
    'Back where the file puts it');
  ExpectThere(FWorld, Pad, False, 'Rewound');
end;

procedure TPadWorldTests.TestDozedPadIsGone;
begin
  var Pad := Sleeper;
  Pad.Wake;
  Assert.AreEqual(1, Integer(Length(FWorld.Standing(Screen))), 'Standing awake');

  Pad.Doze;

  Assert.IsTrue(Pad.Dormant, 'Asleep');
  ExpectThere(FWorld, Pad, False, 'Dozed');
  Assert.AreEqual(0, Integer(Length(FWorld.Standing(Screen))),
    'Not among the standing');
end;

procedure TPadWorldTests.TestRewindGivesBackADozedPad;
begin
  var Level := LevelFromRows(RoomRowsOf(0, 0, 0, 0), StanderSections);
  var World := TPadWorld.Create(nil, nil, Level, nil, 1);
  try
    var Pad := World.FindTagged('stander');
    Assert.IsNotNull(Pad, 'The world finds the pad by its tag');
    ExpectThere(World, Pad, True, 'Born');

    Pad.Doze;
    ExpectThere(World, Pad, False, 'Dozed');
    World.Rewind(1);

    Assert.IsFalse(Pad.Dormant, 'Awake again');
    ExpectThere(World, Pad, True, 'Rewound');
  finally
    World.Free;
    Level.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TPadWorldTests);

end.
