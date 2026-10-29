{
  Tests.Game.Wrecks - the pads the sweeper's wave knocks off: a wreck
  flies away from the blast and up, whichever side of it the pad stood;
  from any point over the Ram's roof the head may burst at, none of the
  five pads of the boss arena comes down onto the road, and every one is
  off the screen within a few seconds; its picture spins faster and
  faster while it flies, no faster than its most, the way it flies; a
  clear takes the wrecks away.

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
    procedure TestSpinsFasterUpToItsMost;
    [Test]
    procedure TestClearTakesThemAway;
  end;

implementation

uses
  System.Math,
  System.SysUtils,
  Sdl2.Core;

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
  SpinStart = 18.0;
  SpinMost = 45.0;

function At(AX, AY: Single): TSdlFPoint;
begin
  Result.X := AX;
  Result.Y := AY;
end;

function MiddleOf(const ABox: TPadBox): TSdlFPoint;
begin
  Result := At(ABox.X + ABox.W / 2, ABox.Y + PadHeight / 2);
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
  FWrecks.Launch(nil, At(300, 200), 32, PadHeight, Blast);
  FWrecks.Launch(nil, At(150, 120), 32, PadHeight, Blast);
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
      for var Pad in ArenaPads do
        FWrecks.Launch(nil, MiddleOf(Pad), Pad.W, PadHeight, At(BlastX, BlastY));
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

procedure TPadWreckTests.TestSpinsFasterUpToItsMost;
begin
  FWrecks.Launch(nil, At(300, 200), 32, PadHeight, At(250, 180));
  FWrecks.Launch(nil, At(150, 200), 32, PadHeight, At(250, 180));
  FWrecks.Tick;
  var Last := FWrecks[0].Spin - FWrecks[0].LastSpin;
  Assert.AreEqual(SpinStart, Double(Last), 0.001, 'It starts at its start');
  for var i := 1 to LongestFlightTicks do
  begin
    FWrecks.Tick;
    if FWrecks[0].Gone then
      Break;
    var Turn := FWrecks[0].Spin - FWrecks[0].LastSpin;
    Assert.IsTrue(Turn > Last - 0.001, 'Slower');
    Assert.IsTrue(Turn <= SpinMost + 0.001, 'Too fast');
    Last := Turn;
  end;
  Assert.IsTrue(Last > SpinStart, 'Faster by the time it leaves');
  Assert.IsTrue(FWrecks[0].Spin > 0, 'Off to the right: clockwise');
  Assert.IsTrue(FWrecks[1].Spin < 0, 'Off to the left: the other way');
end;

procedure TPadWreckTests.TestClearTakesThemAway;
begin
  FWrecks.Launch(nil, At(300, 200), 32, PadHeight, At(250, 180));
  var Clears := FWrecks.Clears;
  FWrecks.Clear;
  Assert.AreEqual(0, FWrecks.Count, 'None');
  Assert.IsFalse(FWrecks.Flying, 'None flying');
  Assert.AreEqual(Clears + 1, FWrecks.Clears, 'Counted');
end;

initialization
  TDUnitX.RegisterTestFixture(TPadWreckTests);

end.
