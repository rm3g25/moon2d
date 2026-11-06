{
  Tests.Game.Wrecks - the pads the sweeper's wave knocks off: a wreck
  flies away from the blast and up, whichever side of it the pad stood;
  from any point over the Ram's roof the head may burst at, none of the
  five pads of the boss arena comes down onto the road, and every one is
  off the screen within a few seconds; the nearer to the blast, the
  harder the kick, and the kick dies down; its picture never spins
  slower, never faster than its most, and no two wrecks of a blast spin
  alike; a new wreck takes the place of one gone, so a long chase does
  not pile them up; a clear takes the wrecks away.

  A pad held at the throw rises a little where it was taken and hangs
  there, flying nowhere; guided, it glides to its place, slow, faster,
  slow, and stays; it spins as fast as it is told, each its own share of
  it, about the point it was held by, its picture turning about it; it
  keeps its place among the wrecks while others come and go; a clear
  takes it away too.

  The wrecks fly in no picture here: the rules need none.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Game.Wrecks;

interface

uses
  DUnitX.TestFramework,
  Game.Wrecks;

type
  [TestFixture]
  TPadWreckTests = class
  private
    FWrecks: TPadWrecks;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestFliesAwayFromTheBlastAndUp;
    [Test]
    procedure TestNoneComesDownOntoTheRoad;
    [Test]
    procedure TestNearerKickedHarder;
    [Test]
    procedure TestKickDiesDown;
    [Test]
    procedure TestSpinsNoSlowerUpToItsMost;
    [Test]
    procedure TestNoTwoSpinAlike;
    [Test]
    procedure TestANewOneTakesAGoneOnesPlace;
    [Test]
    procedure TestClearTakesThemAway;
  end;

  [TestFixture]
  TPadHeldTests = class
  private
    FWrecks: TPadWrecks;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestRisesALittleAndHangs;
    [Test]
    procedure TestSpinsAsToldEachItsOwnShare;
    [Test]
    procedure TestGuidedItGlidesToItsPlace;
    [Test]
    procedure TestThePictureTurnsAboutTheBeam;
    [Test]
    procedure TestStillTillToldToSpin;
    [Test]
    procedure TestKeepsItsPlaceWhileOthersGo;
    [Test]
    procedure TestClearTakesItAway;
  end;

implementation

uses
  System.Math,
  System.SysUtils,
  Sdl2.Core,
  Game.Space;

type
  TPadBox = record
    X, Y, W: Single;
  end;

const
  // The five pads of screen 13 of level 2: their corner and width; the
  // pictures stand about a third of a cell under the deck
  ArenaPads: array [0..4] of TPadBox = ((X: 16; Y: 280; W: 32),
    (X: 72; Y: 188; W: 32), (X: 352; Y: 200; W: 64), (X: 464; Y: 280; W: 32),
    (X: 200; Y: 160; W: 64));
  PadHeight = 12.0;
  RoadY = 352.0;
  // Where the sweeper's head can burst: over the roof of the Ram, from
  // one wall to the other and from the bottom of its mast to the top
  BlastLeft = 70.0;
  BlastRight = 430.0;
  BlastTop = 130.0;
  BlastBottom = 220.0;
  BlastStep = 10.0;
  // Off the screen in five seconds at the most
  LongestFlightTicks = 165;
  WatchedTicks = 40;
  SpinMost = 24.0;
  KickDiesTicks = 30;

function At(AX, AY: Single): TSdlFPoint;
begin
  Result.X := AX;
  Result.Y := AY;
end;

function MiddleOf(const ABox: TPadBox): TSdlFPoint;
begin
  Result := At(ABox.X + ABox.W / 2, ABox.Y + PadHeight / 2);
end;

// As the shock wave measures it: out to the farthest corner of the screen
function ReachOf(const ABlast: TSdlFPoint): Single;
begin
  Result := Max(Max(Hypot(ABlast.X, ABlast.Y), Hypot(ScreenWidth - ABlast.X,
    ABlast.Y)), Max(Hypot(ABlast.X, ScreenHeight - ABlast.Y),
    Hypot(ScreenWidth - ABlast.X, ScreenHeight - ABlast.Y)));
end;

function SpeedOf(const AWreck: TPadWreck): Single;
begin
  Result := Hypot(AWreck.Speed.X, AWreck.Speed.Y);
end;

procedure TPadWreckTests.Setup;
begin
  FWrecks := TPadWrecks.Create;
end;

procedure TPadWreckTests.TearDown;
begin
  FWrecks.Free;
end;

procedure TPadWreckTests.TestFliesAwayFromTheBlastAndUp;
begin
  var Blast := At(250, 180);
  FWrecks.Launch(nil, At(300, 200), 32, PadHeight, Blast, ReachOf(Blast));
  FWrecks.Launch(nil, At(150, 120), 32, PadHeight, Blast, ReachOf(Blast));
  for var i := 1 to WatchedTicks do
    FWrecks.Tick;
  Assert.IsTrue(FWrecks[0].Middle.X > 300, 'Right of the blast: to the right');
  Assert.IsTrue(FWrecks[0].Middle.Y < 200, 'And up, from under the blast too');
  Assert.IsTrue(FWrecks[1].Middle.X < 150, 'Left of it: to the left');
  Assert.IsTrue(FWrecks[1].Middle.Y < 120, 'And up');
end;

procedure TPadWreckTests.TestNoneComesDownOntoTheRoad;
begin
  var BlastX := BlastLeft;
  while BlastX <= BlastRight do
  begin
    var BlastY := BlastTop;
    while BlastY <= BlastBottom do
    begin
      FWrecks.Clear;
      var Blast := At(BlastX, BlastY);
      for var Pad in ArenaPads do
        FWrecks.Launch(nil, MiddleOf(Pad), Pad.W, PadHeight, Blast, ReachOf(Blast));
      var Ticks := 0;
      while FWrecks.Flying do
      begin
        FWrecks.Tick;
        Inc(Ticks);
        for var i := 0 to FWrecks.Count - 1 do
          Assert.IsTrue(FWrecks[i].Middle.Y + PadHeight / 2 < RoadY,
            Format('Pad %d of a blast at %g, %g down on the road', [i + 1,
            BlastX, BlastY]));
        Assert.IsTrue(Ticks <= LongestFlightTicks,
          Format('A blast at %g, %g: a wreck still on the screen', [BlastX,
          BlastY]));
      end;
      BlastY := BlastY + BlastStep;
    end;
    BlastX := BlastX + BlastStep;
  end;
end;

procedure TPadWreckTests.TestNearerKickedHarder;
begin
  var Blast := At(250, 180);
  FWrecks.Launch(nil, At(280, 190), 32, PadHeight, Blast, ReachOf(Blast));
  FWrecks.Launch(nil, At(450, 190), 32, PadHeight, Blast, ReachOf(Blast));
  Assert.IsTrue(SpeedOf(FWrecks[0]) > SpeedOf(FWrecks[1]), 'Near and far alike');
end;

procedure TPadWreckTests.TestKickDiesDown;
begin
  var Blast := At(250, 180);
  FWrecks.Launch(nil, At(270, 190), 32, PadHeight, Blast, ReachOf(Blast));
  var Kick := SpeedOf(FWrecks[0]);
  for var i := 1 to KickDiesTicks do
    FWrecks.Tick;
  Assert.IsTrue(SpeedOf(FWrecks[0]) < Kick, 'The jet outruns the kick');
end;

procedure TPadWreckTests.TestSpinsNoSlowerUpToItsMost;
begin
  var Blast := At(250, 180);
  for var Pad in ArenaPads do
    FWrecks.Launch(nil, MiddleOf(Pad), Pad.W, PadHeight, Blast, ReachOf(Blast));
  var Last: TArray<Single>;
  SetLength(Last, FWrecks.Count);
  for var i := 1 to LongestFlightTicks do
  begin
    FWrecks.Tick;
    for var j := 0 to FWrecks.Count - 1 do
    begin
      if FWrecks[j].Gone then
        Continue;
      var Turn := Abs(FWrecks[j].Spin - FWrecks[j].LastSpin);
      Assert.IsTrue(Turn > 0, Format('Wreck %d does not spin', [j + 1]));
      Assert.IsTrue(Turn > Last[j] - 0.001, Format('Wreck %d slower', [j + 1]));
      Assert.IsTrue(Turn <= SpinMost + 0.001, Format('Wreck %d too fast', [j + 1]));
      Last[j] := Turn;
    end;
  end;
end;

procedure TPadWreckTests.TestNoTwoSpinAlike;
begin
  var Blast := At(250, 180);
  for var Pad in ArenaPads do
    FWrecks.Launch(nil, MiddleOf(Pad), Pad.W, PadHeight, Blast, ReachOf(Blast));
  for var i := 0 to FWrecks.Count - 1 do
    for var j := i + 1 to FWrecks.Count - 1 do
      Assert.IsTrue(Abs(Abs(FWrecks[i].SpinRate) - Abs(FWrecks[j].SpinRate)) > 0.1,
        Format('Wrecks %d and %d spin alike', [i + 1, j + 1]));
end;

procedure TPadWreckTests.TestANewOneTakesAGoneOnesPlace;
begin
  var Blast := At(250, 180);
  FWrecks.Launch(nil, At(270, 190), 32, PadHeight, Blast, ReachOf(Blast));
  FWrecks.Launch(nil, At(230, 190), 32, PadHeight, Blast, ReachOf(Blast));
  for var i := 1 to LongestFlightTicks do
    FWrecks.Tick;
  Assert.IsFalse(FWrecks.Flying, 'Both gone');
  FWrecks.Launch(nil, At(300, 200), 32, PadHeight, Blast, ReachOf(Blast));
  Assert.AreEqual(2, FWrecks.Count, 'In a gone one''s place');
  Assert.IsTrue(FWrecks.Flying, 'And it flies');
end;

procedure TPadWreckTests.TestClearTakesThemAway;
begin
  var Blast := At(250, 180);
  FWrecks.Launch(nil, At(300, 200), 32, PadHeight, Blast, ReachOf(Blast));
  var Clears := FWrecks.Clears;
  FWrecks.Clear;
  Assert.AreEqual(0, FWrecks.Count, 'None');
  Assert.IsFalse(FWrecks.Flying, 'None flying');
  Assert.AreEqual(Clears + 1, FWrecks.Clears, 'Counted');
end;

{ TPadHeldTests }

const
  HeldPad = 64.0;
  // A held pad rises about this far; past this many ticks it hangs
  HeldRiseAbout = 10.0;
  HeldRiseOver = 40;
  RiseSlop = 0.5;
  // A held pad spins at this share of what it is told, either way
  HeldShareLeast = 0.8;
  HeldShareMost = 1.2;
  ManyFlightTicks = 1000;
  NoDrop = 0.0;
  Slop = 0.001;

procedure TPadHeldTests.Setup;
begin
  FWrecks := TPadWrecks.Create;
end;

procedure TPadHeldTests.TearDown;
begin
  FWrecks.Free;
end;

procedure TPadHeldTests.TestRisesALittleAndHangs;
begin
  var Number := FWrecks.Hold(nil, At(200, 150), HeldPad, PadHeight, NoDrop);
  var Last := FWrecks[Number].Middle.Y;
  for var i := 1 to HeldRiseOver do
  begin
    FWrecks.Tick;
    Assert.IsTrue(FWrecks[Number].Middle.Y <= Last, Format('Down at tick %d', [i]));
    Last := FWrecks[Number].Middle.Y;
  end;
  Assert.AreEqual(Double(150 - HeldRiseAbout), Double(Last), RiseSlop, 'Risen');
  for var i := 1 to HeldRiseOver do
    FWrecks.Tick;
  Assert.AreEqual(Double(Last), Double(FWrecks[Number].Middle.Y), 0.001, 'Hangs');
  Assert.AreEqual(200.0, Double(FWrecks[Number].Middle.X), 0.001, 'Straight up');
  Assert.IsFalse(FWrecks[Number].Gone, 'Not gone');
  Assert.IsFalse(FWrecks.Flying, 'Flies nowhere');
end;

procedure TPadHeldTests.TestSpinsAsToldEachItsOwnShare;
const
  Told = 10.0;
  Held = 5;
begin
  for var i := 0 to Held - 1 do
    FWrecks.Hold(nil, At(60 + 80 * i, 150), HeldPad, PadHeight, NoDrop);
  FWrecks.HeldSpin := Told;
  FWrecks.Tick;
  var Spins: TArray<Single> := [];
  for var i := 0 to Held - 1 do
  begin
    var Spin := FWrecks[i].Spin;
    Assert.IsTrue((Abs(Spin) >= HeldShareLeast * Told - 0.001) and
      (Abs(Spin) <= HeldShareMost * Told + 0.001),
      Format('Pad %d spun %.2f for %.0f', [i, Spin, Told]));
    for var Other in Spins do
      Assert.IsTrue(Abs(Other - Spin) > 0.001, Format('Pad %d spins as another', [i]));
    Spins := Spins + [Spin];
  end;
end;

procedure TPadHeldTests.TestGuidedItGlidesToItsPlace;
const
  GlideTicks = 40;
begin
  var Number := FWrecks.Hold(nil, At(200, 150), HeldPad, PadHeight, NoDrop);
  FWrecks.Tick;
  var Till := At(100, 120);
  FWrecks.Guide(Number, Till, GlideTicks);
  var Steps: TArray<Single> := [];
  for var i := 1 to GlideTicks do
  begin
    var Before := FWrecks[Number].Middle;
    FWrecks.Tick;
    var After := FWrecks[Number].Middle;
    Steps := Steps + [Single(Hypot(After.X - Before.X, After.Y - Before.Y))];
  end;
  Assert.AreEqual(Double(Till.X), Double(FWrecks[Number].Middle.X), Slop, 'There across');
  Assert.AreEqual(Double(Till.Y), Double(FWrecks[Number].Middle.Y), Slop, 'There down');
  var Middle := Steps[Length(Steps) div 2];
  Assert.IsTrue((Steps[0] < Middle) and (Steps[High(Steps)] < Middle), 'Slow, faster, slow');
  for var i := 1 to GlideTicks do
    FWrecks.Tick;
  Assert.AreEqual(Double(Till.X), Double(FWrecks[Number].Middle.X), Slop, 'Stays');
end;

// Unturned, the picture hangs under the beam it turns about; turned, it
// swings round it, as far from it
procedure TPadHeldTests.TestThePictureTurnsAboutTheBeam;
const
  Drop = 5.0;
  Quarter = 90.0;
begin
  var Number := FWrecks.Hold(nil, At(200, 150), HeldPad, PadHeight, Drop);
  var Picture := FWrecks.PictureAt(Number, 1);
  Assert.AreEqual(200.0, Double(Picture.X), Slop, 'Under it across');
  Assert.AreEqual(150.0 + Drop, Double(Picture.Y), Slop, 'Under it');
  FWrecks.HeldSpin := Quarter;
  FWrecks.Tick;
  var Turn := FWrecks[Number].Middle;
  Picture := FWrecks.PictureAt(Number, 1);
  var Angle := DegToRad(FWrecks[Number].Spin);
  Assert.AreEqual(Double(Turn.X - Sin(Angle) * Drop), Double(Picture.X), Slop, 'Turned across');
  Assert.AreEqual(Double(Turn.Y + Cos(Angle) * Drop), Double(Picture.Y), Slop, 'Turned down');
  Assert.AreEqual(Double(Drop), Double(Hypot(Picture.X - Turn.X, Picture.Y - Turn.Y)), Slop,
    'As far from it');
  Assert.IsTrue(Abs(Picture.X - Turn.X) > Drop / 2, 'Swung aside');
end;

procedure TPadHeldTests.TestStillTillToldToSpin;
begin
  FWrecks.Hold(nil, At(200, 150), HeldPad, PadHeight, NoDrop);
  for var i := 1 to HeldRiseOver do
    FWrecks.Tick;
  Assert.AreEqual(0.0, Double(FWrecks[0].Spin), 0.001, 'Still');
  FWrecks.HeldSpin := 6;
  FWrecks.Tick;
  Assert.IsTrue(Abs(FWrecks[0].Spin) > 0, 'Spins once told');
end;

// A wreck gone gives its place to the next; a held one never does
procedure TPadHeldTests.TestKeepsItsPlaceWhileOthersGo;
begin
  var Blast := At(250, 180);
  FWrecks.Launch(nil, At(300, 200), 32, PadHeight, Blast, ReachOf(Blast));
  var Number := FWrecks.Hold(nil, At(100, 150), HeldPad, PadHeight, NoDrop);
  var Ticks := 0;
  while FWrecks.Flying and (Ticks < ManyFlightTicks) do
  begin
    FWrecks.Tick;
    Inc(Ticks);
  end;
  Assert.IsTrue(FWrecks[0].Gone, 'The flying one gone');
  FWrecks.Launch(nil, At(300, 200), 32, PadHeight, Blast, ReachOf(Blast));
  Assert.AreEqual(2, FWrecks.Count, 'The new one in the gone one''s place');
  Assert.IsTrue(FWrecks[Number].Held, 'Held where it was');
  Assert.AreEqual(100.0, Double(FWrecks[Number].Middle.X), 0.001, 'The same pad');
end;

procedure TPadHeldTests.TestClearTakesItAway;
begin
  FWrecks.Hold(nil, At(200, 150), HeldPad, PadHeight, NoDrop);
  FWrecks.Clear;
  Assert.AreEqual(0, FWrecks.Count, 'None');
end;

initialization
  TDUnitX.RegisterTestFixture(TPadWreckTests);
  TDUnitX.RegisterTestFixture(TPadHeldTests);

end.
