{
  Tests.Game.Capsules - the shuttle's medkits in the Ram's fight: a
  capsule comes down from over the screen onto its mark and never past
  it, braking at the end; it lands once, and its medkit stands on the
  mark a moment after; then the shell is gone. Two dropped at once land
  each on its own; a clear takes them away.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Game.Capsules;

interface

uses
  DUnitX.TestFramework,
  Game.Capsules;

type
  [TestFixture]
  TShuttleCapsuleTests = class
  private
    FCapsules: TShuttleCapsules;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestComesDownOntoItsMark;
    [Test]
    procedure TestBrakesBeforeItLands;
    [Test]
    procedure TestLandsOnceAndOpensOnce;
    [Test]
    procedure TestTheMedkitStandsOnTheMark;
    [Test]
    procedure TestTheShellIsGoneAfterwards;
    [Test]
    procedure TestTwoLandEachOnItsOwn;
    [Test]
    procedure TestClearTakesThemAway;
  end;

implementation

uses
  System.Math,
  Sdl2.Core;

const
  PadX = 88.0;
  PadDeckY = 188.0;
  RoadX = 496.0;
  RoadY = 352.0;
  // Long enough for a capsule to come down, open and be gone
  ManyTicks = 200;
  // Down within two seconds
  LongestFallTicks = 66;

procedure TShuttleCapsuleTests.Setup;
begin
  FCapsules := TShuttleCapsules.Create;
end;

procedure TShuttleCapsuleTests.TearDown;
begin
  FCapsules.Free;
end;

procedure TShuttleCapsuleTests.TestComesDownOntoItsMark;
begin
  FCapsules.Drop(PadX, PadDeckY);
  Assert.IsTrue(FCapsules[0].Bottom - CapsuleHeight < 0,
    'Out of sight at first');
  var Lowest: Single := -1;
  var Ticks := 0;
  while (FCapsules[0].Phase = cpFalling) and (Ticks < LongestFallTicks) do
  begin
    FCapsules.Tick;
    Inc(Ticks);
    Lowest := Max(Lowest, FCapsules[0].Bottom);
    Assert.AreEqual(PadX, FCapsules[0].X, 0.001, 'Straight down');
  end;
  Assert.AreEqual<TCapsulePhase>(cpOpening, FCapsules[0].Phase, 'Down within two seconds');
  Assert.AreEqual(PadDeckY, Lowest, 0.001, 'On the deck, never past it');
end;

procedure TShuttleCapsuleTests.TestBrakesBeforeItLands;
begin
  FCapsules.Drop(RoadX, RoadY);
  FCapsules.Tick;
  var FirstStep := FCapsules[0].Bottom - FCapsules[0].LastBottom;
  var LastStep: Single := FirstStep;
  while FCapsules[0].Phase = cpFalling do
  begin
    FCapsules.Tick;
    LastStep := FCapsules[0].Bottom - FCapsules[0].LastBottom;
  end;
  Assert.IsTrue(FirstStep > 0, 'It falls');
  Assert.IsTrue(LastStep < FirstStep / 4, 'Slow as it touches down');
end;

procedure TShuttleCapsuleTests.TestLandsOnceAndOpensOnce;
begin
  FCapsules.Drop(PadX, PadDeckY);
  var Landings := 0;
  var Medkits := 0;
  for var i := 1 to ManyTicks do
  begin
    var Cue := FCapsules.Tick;
    if Cue.Landed then
      Inc(Landings);
    Inc(Medkits, Length(Cue.Opened));
  end;
  Assert.AreEqual(1, Landings, 'Lands once');
  Assert.AreEqual(1, Medkits, 'One medkit');
end;

procedure TShuttleCapsuleTests.TestTheMedkitStandsOnTheMark;
begin
  FCapsules.Drop(PadX, PadDeckY);
  var LandedAt := -1;
  for var i := 1 to ManyTicks do
  begin
    var Cue := FCapsules.Tick;
    if Cue.Landed then
      LandedAt := i;
    if Length(Cue.Opened) = 0 then
      Continue;
    Assert.IsTrue((LandedAt > 0) and (i > LandedAt), 'After the landing');
    Assert.AreEqual(PadX, Cue.Opened[0].X, 0.001, 'Over the mark');
    Assert.AreEqual(PadDeckY, Cue.Opened[0].Y, 0.001, 'Its feet on the deck');
    Exit;
  end;
  Assert.Fail('No medkit came out');
end;

procedure TShuttleCapsuleTests.TestTheShellIsGoneAfterwards;
begin
  FCapsules.Drop(PadX, PadDeckY);
  for var i := 1 to ManyTicks do
    FCapsules.Tick;
  Assert.AreEqual(0, FCapsules.Count, 'Nothing left of it');
end;

procedure TShuttleCapsuleTests.TestTwoLandEachOnItsOwn;
begin
  FCapsules.Drop(PadX, PadDeckY);
  FCapsules.Drop(RoadX, RoadY);
  var Marks: TArray<TSdlFPoint> := [];
  for var i := 1 to ManyTicks do
    Marks := Marks + FCapsules.Tick.Opened;
  Assert.AreEqual(2, Length(Marks), 'Two medkits');
  var OnThePad := (Marks[0].X = PadX) or (Marks[1].X = PadX);
  var OnTheRoad := (Marks[0].Y = RoadY) or (Marks[1].Y = RoadY);
  Assert.IsTrue(OnThePad and OnTheRoad, 'One on the pad, one on the road');
end;

procedure TShuttleCapsuleTests.TestClearTakesThemAway;
begin
  FCapsules.Drop(PadX, PadDeckY);
  FCapsules.Tick;
  FCapsules.Clear;
  Assert.AreEqual(0, FCapsules.Count, 'None in the air');
  for var i := 1 to ManyTicks do
    Assert.AreEqual(0, Length(FCapsules.Tick.Opened), 'No medkit comes of it');
end;

initialization
  TDUnitX.RegisterTestFixture(TShuttleCapsuleTests);

end.
