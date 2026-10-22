{
  Tests.Orbs.Feed - the orbs that carry a charge into its gauge: the
  charge is split among five orbs at most, and every bit of it reaches
  the gauge; they come out of the hero one after another, hang over him
  and keep to him as he goes, then go into the gauge - none before it
  has hung its while. A collapse takes the charge with it. The orbs are
  dark and strike nothing.

  The look of the flight - the curve, the sway, the size - is for the
  eye.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Orbs.Feed;

interface

uses
  DUnitX.TestFramework, Sdl2.Core, Orbs.Flock, Orbs.Feed;

type
  [TestFixture]
  TOrbFeedTests = class
  private
    FFeed: TOrbFeed;
    FHero: TSdlFPoint;
    FGauge: TSdlFPoint;
    procedure TickTimes(ACount: Integer);
    // Ticks until nothing is on its way; the charge landed meanwhile
    function TickUntilFed: Integer;
    function LiveOrbs: Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestNoChargeNoOrbs;
    [Test]
    procedure TestChargeIsOnItsWayAtOnce;
    [Test]
    procedure TestOrbsComeOutOneAfterAnother;
    [Test]
    procedure TestChargeSplitsAmongFiveOrbsAtMost;
    [Test]
    procedure TestEveryBitOfChargeLands;
    [Test]
    procedure TestNothingLandsBeforeOrbsHaveHung;
    [Test]
    procedure TestOrbsHangOverTheHero;
    [Test]
    procedure TestHangingOrbKeepsToTheHero;
    [Test]
    procedure TestOrbGoesIntoTheGauge;
    [Test]
    procedure TestLandedIsTakenOnce;
    [Test]
    procedure TestCollapseTakesTheChargeAlong;
    [Test]
    procedure TestOrbsAreDarkAndStrikeNothing;
  end;

implementation

uses
  System.SysUtils, System.Math;

const
  FirstWaitTicks = 15;
  StepTicks = 9;
  RiseTicks = 30;
  HoverMinTicks = 60;
  // Five orbs out, risen, hung their longest and flown, with room
  LongestFeed = 400;

procedure TOrbFeedTests.Setup;
begin
  FFeed := TOrbFeed.Create(MoonOrbTint);
  FHero.X := 300;
  FHero.Y := 300;
  FGauge.X := 140;
  FGauge.Y := 20;
  FFeed.Tick(FHero);
end;

procedure TOrbFeedTests.TearDown;
begin
  FreeAndNil(FFeed);
end;

procedure TOrbFeedTests.TickTimes(ACount: Integer);
begin
  for var i := 1 to ACount do
    FFeed.Tick(FHero);
end;

function TOrbFeedTests.TickUntilFed: Integer;
begin
  Result := 0;
  for var i := 1 to LongestFeed do
  begin
    FFeed.Tick(FHero);
    Inc(Result, FFeed.TakeLanded);
    if FFeed.Pending = 0 then
      Exit;
  end;
  Assert.Fail(Format('Still on its way after %d ticks', [LongestFeed]));
end;

function TOrbFeedTests.LiveOrbs: Integer;
begin
  Result := 0;
  for var Orb in FFeed.Flock.Orbs do
    if Orb.State = osAlive then
      Inc(Result);
end;

procedure TOrbFeedTests.TestNoChargeNoOrbs;
begin
  FFeed.Start(0, FGauge);
  TickTimes(FirstWaitTicks + 1);
  Assert.AreEqual(0, FFeed.Pending, 'Nothing on its way');
  Assert.AreEqual(0, FFeed.Flock.Orbs.Count, 'No orb');
end;

procedure TOrbFeedTests.TestChargeIsOnItsWayAtOnce;
begin
  FFeed.Start(5, FGauge);
  Assert.AreEqual(5, FFeed.Pending, 'On its way before any orb is out');
  Assert.AreEqual(0, FFeed.Flock.Orbs.Count, 'No orb yet');
end;

procedure TOrbFeedTests.TestOrbsComeOutOneAfterAnother;
begin
  FFeed.Start(5, FGauge);
  TickTimes(FirstWaitTicks - 1);
  var BeforeFirst := FFeed.Flock.Orbs.Count;
  FFeed.Tick(FHero);
  var First := FFeed.Flock.Orbs.Count;
  TickTimes(StepTicks);
  Assert.AreEqual(0, BeforeFirst, 'A beat after the taking');
  Assert.AreEqual(1, First, 'Then one');
  Assert.AreEqual(2, FFeed.Flock.Orbs.Count, 'Then the next');
end;

procedure TOrbFeedTests.TestChargeSplitsAmongFiveOrbsAtMost;
begin
  FFeed.Start(12, FGauge);
  TickTimes(FirstWaitTicks + 4 * StepTicks);
  Assert.AreEqual(5, FFeed.Flock.Orbs.Count, 'Five for twelve');

  FFeed.Clear;
  FFeed.Start(3, FGauge);
  TickTimes(FirstWaitTicks + 4 * StepTicks);
  Assert.AreEqual(3, FFeed.Flock.Orbs.Count, 'One an orb for three');
end;

procedure TOrbFeedTests.TestEveryBitOfChargeLands;
begin
  FFeed.Start(12, FGauge);
  Assert.AreEqual(12, TickUntilFed, 'All twelve, split as it may be');
  FFeed.Tick(FHero);
  Assert.AreEqual(0, FFeed.Flock.Orbs.Count, 'No orb left behind');
end;

procedure TOrbFeedTests.TestNothingLandsBeforeOrbsHaveHung;
begin
  FFeed.Start(5, FGauge);
  TickTimes(FirstWaitTicks + RiseTicks + HoverMinTicks);
  Assert.AreEqual(0, FFeed.TakeLanded, 'Nothing in the gauge yet');
  Assert.AreEqual(5, FFeed.Pending, 'All of it still on its way');
end;

procedure TOrbFeedTests.TestOrbsHangOverTheHero;
begin
  FFeed.Start(5, FGauge);
  TickTimes(FirstWaitTicks + 4 * StepTicks + RiseTicks);
  for var Orb in FFeed.Flock.Orbs do
  begin
    Assert.IsTrue(Orb.Y < FHero.Y, 'Above his center');
    Assert.IsTrue(Abs(Orb.X - FHero.X) < 40, 'About him');
  end;
end;

procedure TOrbFeedTests.TestHangingOrbKeepsToTheHero;
const
  Walk = 100;
begin
  FFeed.Start(1, FGauge);
  TickTimes(FirstWaitTicks + RiseTicks);
  var Orb := FFeed.Flock.Orbs[0];
  var Before := Orb.X;
  FHero.X := FHero.X + Walk;
  FFeed.Tick(FHero);
  Assert.IsTrue(Abs(Orb.X - Before - Walk) < 5, 'Gone along with him');
end;

procedure TOrbFeedTests.TestOrbGoesIntoTheGauge;
begin
  FFeed.Start(1, FGauge);
  TickTimes(FirstWaitTicks + 1);
  var Orb := FFeed.Flock.Orbs[0];
  var Nearest: Single := MaxSingle;
  var Landed := 0;
  for var i := 1 to LongestFeed do
  begin
    FFeed.Tick(FHero);
    // A landed orb is the flock's to drop at its next tick: it is still
    // where it went in
    var Distance: Single := Hypot(Orb.X - FGauge.X, Orb.Y - FGauge.Y);
    Nearest := Min(Nearest, Distance);
    Inc(Landed, FFeed.TakeLanded);
    if Landed > 0 then
      Break;
  end;
  Assert.AreEqual(1, Landed, 'It landed');
  Assert.IsTrue(Nearest < 3, Format('In the gauge, not %g away', [Nearest]));
end;

procedure TOrbFeedTests.TestLandedIsTakenOnce;
begin
  FFeed.Start(5, FGauge);
  var Landed := TickUntilFed;
  Assert.AreEqual(5, Landed, 'Taken');
  Assert.AreEqual(0, FFeed.TakeLanded, 'And not again');
end;

procedure TOrbFeedTests.TestCollapseTakesTheChargeAlong;
begin
  FFeed.Start(5, FGauge);
  TickTimes(FirstWaitTicks + 2 * StepTicks);
  FFeed.Collapse;
  Assert.AreEqual(0, FFeed.Pending, 'Nothing on its way');
  Assert.AreEqual(0, LiveOrbs, 'The orbs out draw into their points');
  TickTimes(LongestFeed);
  Assert.AreEqual(0, FFeed.TakeLanded, 'Nothing lands');
  Assert.AreEqual(0, FFeed.Flock.Orbs.Count, 'And they are gone');
end;

procedure TOrbFeedTests.TestOrbsAreDarkAndStrikeNothing;
begin
  FFeed.Start(5, FGauge);
  TickTimes(FirstWaitTicks + 4 * StepTicks + RiseTicks);
  Assert.IsTrue(MoonOrbTint.Dark, 'Of the moon');
  for var Orb in FFeed.Flock.Orbs do
    Assert.IsFalse(Orb.Armed, 'Not armed');
end;

initialization
  TDUnitX.RegisterTestFixture(TOrbFeedTests);

end.
