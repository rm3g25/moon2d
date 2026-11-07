{
  Tests.Game.Takeoff - the Ram off the road: nothing till it starts. The
  front jet catches at once, told with the first tick, and the bow lifts
  the other way round from where the hull faces, about its rear wheel,
  nothing risen yet. The rear jet catches once, a while after, with the
  wheel spat out on the same tick. It rises to its height, never down on
  the way, and stays there; it rights itself as it rises, swinging past
  level and back, and settles, told once - then it hangs level. On the
  road it turns about the wheel, off it about its middle. A jet flares as
  it catches and comes down to its steady fire. A stop takes it all.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Game.Takeoff;

interface

uses
  DUnitX.TestFramework,
  Game.Takeoff;

type
  [TestFixture]
  TTakeoffTests = class
  private
    FTakeoff: TTakeoff;
    // Started from AFrom degrees, facing right, and ticked till the rear
    // jet catches
    procedure SpitTheWheel(AFrom: Single);
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure TestNothingTillItStarts;
    [Test]
    procedure TestTheFrontJetCatchesWithTheFirstTick;
    [Test]
    procedure TestTheBowLiftsAgainstTheWayItFaces;
    [Test]
    procedure TestTheRearJetCatchesOnceWithTheWheel;
    [Test]
    procedure TestRisesToItsHeightNeverDown;
    [Test]
    procedure TestRightsItselfPastLevelAndSettles;
    [Test]
    procedure TestOnTheRoadAboutTheWheelOffItAboutItsMiddle;
    [Test]
    procedure TestAJetFlaresThenBurnsSteady;
    [Test]
    procedure TestAStopTakesItAll;
  end;

implementation

uses
  System.Math,
  System.SysUtils;

const
  Slop = 0.001;
  // Enough ticks for it to rise and settle
  ManyTicks = 600;
  // The lean of 18b it starts from, onto its bow
  ShedLean = 3.0;

procedure TTakeoffTests.Setup;
begin
  FTakeoff.Stop;
end;

procedure TTakeoffTests.SpitTheWheel(AFrom: Single);
begin
  FTakeoff.Start(AFrom, 1);
  for var i := 1 to ManyTicks do
    if FTakeoff.Tick.Spit then
      Exit;
  Assert.Fail('The rear jet never caught');
end;

procedure TTakeoffTests.TestNothingTillItStarts;
begin
  Assert.IsFalse(FTakeoff.Running, 'Not running');
  var Cue := FTakeoff.Tick;
  Assert.IsFalse(Cue.Ignite or Cue.Spit or Cue.Steady, 'No cue');
  Assert.AreEqual(0.0, Double(FTakeoff.LeanAt(1)), Slop, 'Level');
  Assert.AreEqual(0.0, Double(FTakeoff.LiftAt(1)), Slop, 'On the road');
  Assert.AreEqual(0.0, Double(FTakeoff.JetAt(tjFront, 1)), Slop, 'No fire');
end;

procedure TTakeoffTests.TestTheFrontJetCatchesWithTheFirstTick;
begin
  FTakeoff.Start(ShedLean, 1);
  Assert.IsTrue(FTakeoff.Running, 'Running');
  var Cue := FTakeoff.Tick;
  Assert.IsTrue(Cue.Ignite, 'A jet catches');
  Assert.IsTrue(Cue.Jet = tjFront, 'The front one');
  Assert.IsFalse(Cue.Spit, 'No wheel yet');
  Assert.IsTrue(FTakeoff.JetAt(tjFront, 1) > 0, 'It burns');
  Assert.AreEqual(0.0, Double(FTakeoff.JetAt(tjRear, 1)), Slop, 'The rear not');
end;

// Facing right its bow is on the right: up is counter-clockwise
procedure TTakeoffTests.TestTheBowLiftsAgainstTheWayItFaces;
begin
  FTakeoff.Start(ShedLean, 1);
  for var i := 1 to BowUpTicks do
    FTakeoff.Tick;
  Assert.AreEqual(-BowUpDegrees, Double(FTakeoff.LeanAt(1)), Slop,
    'Facing right, bow up');
  Assert.AreEqual(0.0, Double(FTakeoff.LiftAt(1)), Slop, 'Not risen yet');

  FTakeoff.Start(-ShedLean, -1);
  for var i := 1 to BowUpTicks do
    FTakeoff.Tick;
  Assert.AreEqual(BowUpDegrees, Double(FTakeoff.LeanAt(1)), Slop,
    'Facing left, bow up');
end;

procedure TTakeoffTests.TestTheRearJetCatchesOnceWithTheWheel;
begin
  FTakeoff.Start(ShedLean, 1);
  var Ignites := 0;
  var Spits := 0;
  var SpitAt := 0;
  for var i := 1 to ManyTicks do
  begin
    var Cue := FTakeoff.Tick;
    if Cue.Ignite then
      Inc(Ignites);
    if Cue.Spit then
    begin
      Inc(Spits);
      SpitAt := i;
      Assert.IsTrue(Cue.Ignite and (Cue.Jet = tjRear), 'The rear jet with it');
    end;
  end;
  Assert.AreEqual(2, Ignites, 'Two jets, each once');
  Assert.AreEqual(1, Spits, 'One wheel');
  Assert.IsTrue((SpitAt >= RearJetAfterTicks) and (SpitAt <= RearJetAfterTicks + 1),
    Format('A while after the front, not at tick %d', [SpitAt]));
end;

procedure TTakeoffTests.TestRisesToItsHeightNeverDown;
begin
  SpitTheWheel(ShedLean);
  var Last: Single := 0;
  for var i := 1 to ManyTicks do
  begin
    FTakeoff.Tick;
    var Lift := FTakeoff.LiftAt(1);
    Assert.IsTrue(Lift >= Last - Slop, Format('Down at tick %d', [Integer(i)]));
    Last := Lift;
  end;
  Assert.AreEqual(HangLift, Double(Last), Slop, 'At its height');
  Assert.IsTrue(RiseTicks < ManyTicks, 'Watched long enough');
end;

// Facing right the bow is up counter-clockwise, below 0: past level is
// over 0
procedure TTakeoffTests.TestRightsItselfPastLevelAndSettles;
begin
  SpitTheWheel(ShedLean);
  var PastLevel := False;
  var Steadies := 0;
  for var i := 1 to ManyTicks do
  begin
    if FTakeoff.Tick.Steady then
      Inc(Steadies);
    if FTakeoff.LeanAt(1) > 0 then
      PastLevel := True;
  end;
  Assert.IsTrue(PastLevel, 'Swung past level');
  Assert.AreEqual(1, Steadies, 'Settled, told once');
  Assert.IsTrue(FTakeoff.Stage = tkHanging, 'Hangs');
  Assert.AreEqual(0.0, Double(FTakeoff.LeanAt(0)), Slop, 'Level a tick ago');
  Assert.AreEqual(0.0, Double(FTakeoff.LeanAt(1)), Slop, 'Level');
end;

procedure TTakeoffTests.TestOnTheRoadAboutTheWheelOffItAboutItsMiddle;
begin
  FTakeoff.Start(ShedLean, 1);
  for var i := 1 to BowUpTicks do
    FTakeoff.Tick;
  Assert.AreEqual(0.0, Double(FTakeoff.AirAt(1)), Slop, 'On the road');
  for var i := 1 to ManyTicks do
    FTakeoff.Tick;
  Assert.AreEqual(1.0, Double(FTakeoff.AirAt(1)), Slop, 'Off it');
end;

procedure TTakeoffTests.TestAJetFlaresThenBurnsSteady;
const
  Settled = 30;
begin
  FTakeoff.Start(ShedLean, 1);
  var Brightest: Single := 0;
  for var i := 1 to Settled do
  begin
    FTakeoff.Tick;
    Brightest := Max(Brightest, FTakeoff.JetAt(tjFront, 1));
  end;
  Assert.IsTrue(Brightest > 1, 'A flare as it catches');
  Assert.AreEqual(1.0, Double(FTakeoff.JetAt(tjFront, 1)), Slop, 'Steady');
end;

procedure TTakeoffTests.TestAStopTakesItAll;
begin
  SpitTheWheel(ShedLean);
  FTakeoff.Tick;
  FTakeoff.Stop;
  Assert.IsFalse(FTakeoff.Running, 'Stopped');
  Assert.AreEqual(0.0, Double(FTakeoff.LeanAt(1)), Slop, 'Level');
  Assert.AreEqual(0.0, Double(FTakeoff.LiftAt(1)), Slop, 'On the road');
  Assert.AreEqual(0.0, Double(FTakeoff.JetAt(tjRear, 1)), Slop, 'No fire');
  Assert.IsFalse(FTakeoff.Tick.Ignite, 'Nothing catches');
end;

initialization
  TDUnitX.RegisterTestFixture(TTakeoffTests);

end.
