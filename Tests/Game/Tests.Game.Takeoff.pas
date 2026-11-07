{
  Tests.Game.Takeoff - the Ram off the road: nothing till it starts. The
  bays come out first, then the nozzles, never back, the hull as it leaned
  and no fire; the front jet catches once they are out, told with the
  tick, and the bow lifts the other way round from where the hull faces,
  about its rear wheel, nothing risen yet. The rear jet catches once, a while after, with the
  wheel spat out on the same tick. It rises to its height, never down on
  the way, to its height as it settles; it rights itself as it rises,
  swinging past level and back, and settles level, told once. On the road
  it turns about the wheel, off it about its middle. Hanging, it bobs and
  rocks a little about its height and level; told where the hero is, it
  goes after him slower than he runs, no faster than its most, banking
  into the way it goes - rising, it hears none of that. A jet flares as
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
    // Started as off the shed wheel and ticked till it settles
    procedure HangIt;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure TestNothingTillItStarts;
    [Test]
    procedure TestTheBaysThenTheNozzlesComeOutBeforeTheFire;
    [Test]
    procedure TestTheFrontJetCatchesOnceTheNozzlesAreOut;
    [Test]
    procedure TestTheBowLiftsAgainstTheWayItFaces;
    [Test]
    procedure TestTheRearJetCatchesOnceWithTheWheel;
    [Test]
    procedure TestRisesToItsHeightNeverDown;
    [Test]
    procedure TestRightsItselfPastLevelAndSettles;
    [Test]
    procedure TestHangingItBobsAndRocksALittle;
    [Test]
    procedure TestHangingItGoesAfterTheHeroBanking;
    [Test]
    procedure TestRisingItHearsNoneOfTheHero;
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
  // The front jet catches on this tick
  OpenTicks = BayTicks + NozzleTicks;

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

procedure TTakeoffTests.HangIt;
begin
  FTakeoff.Start(ShedLean, 1);
  for var i := 1 to ManyTicks do
    if FTakeoff.Tick.Steady then
      Exit;
  Assert.Fail('It never settled');
end;

procedure TTakeoffTests.TestNothingTillItStarts;
begin
  Assert.IsFalse(FTakeoff.Running, 'Not running');
  var Cue := FTakeoff.Tick;
  Assert.IsFalse(Cue.Ignite or Cue.Spit or Cue.Steady, 'No cue');
  Assert.AreEqual(0.0, Double(FTakeoff.LeanAt(1)), Slop, 'Level');
  Assert.AreEqual(0.0, Double(FTakeoff.LiftAt(1)), Slop, 'On the road');
  Assert.AreEqual(0.0, Double(FTakeoff.JetAt(tjFront, 1)), Slop, 'No fire');
  Assert.AreEqual(0.0, Double(FTakeoff.BayAt(1)), Slop, 'No bay');
  Assert.AreEqual(0.0, Double(FTakeoff.NozzleAt(1)), Slop, 'No nozzle');
end;

procedure TTakeoffTests.TestTheBaysThenTheNozzlesComeOutBeforeTheFire;
begin
  FTakeoff.Start(ShedLean, 1);
  Assert.IsTrue(FTakeoff.Running, 'Running');
  var LastBay: Single := 0;
  var LastNozzle: Single := 0;
  for var i := 1 to OpenTicks - 1 do
  begin
    var Cue := FTakeoff.Tick;
    var Bay := FTakeoff.BayAt(1);
    var Nozzle := FTakeoff.NozzleAt(1);
    Assert.IsFalse(Cue.Ignite, Format('Fire at tick %d', [Integer(i)]));
    Assert.IsTrue((Bay >= LastBay) and (Nozzle >= LastNozzle),
      Format('Back in at tick %d', [Integer(i)]));
    if Bay < 1 then
      Assert.AreEqual(0.0, Double(Nozzle), Slop,
        Format('The nozzle before its bay at tick %d', [Integer(i)]));
    Assert.AreEqual(ShedLean, Double(FTakeoff.LeanAt(1)), Slop, 'As it leaned');
    Assert.AreEqual(0.0, Double(FTakeoff.LiftAt(1)), Slop, 'On the road');
    LastBay := Bay;
    LastNozzle := Nozzle;
  end;
  Assert.AreEqual(1.0, Double(LastBay), Slop, 'The bays out');
  Assert.IsTrue(LastNozzle > 0, 'The nozzles coming');
  FTakeoff.Tick;
  Assert.AreEqual(1.0, Double(FTakeoff.NozzleAt(1)), Slop, 'The nozzles out');
  for var i := 1 to ManyTicks do
    FTakeoff.Tick;
  Assert.AreEqual(1.0, Double(FTakeoff.BayAt(1)), Slop, 'Hanging, the bays out');
  Assert.AreEqual(1.0, Double(FTakeoff.NozzleAt(1)), Slop, 'And the nozzles');
end;

procedure TTakeoffTests.TestTheFrontJetCatchesOnceTheNozzlesAreOut;
begin
  FTakeoff.Start(ShedLean, 1);
  for var i := 1 to OpenTicks - 1 do
    FTakeoff.Tick;
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
  for var i := 1 to OpenTicks + BowUpTicks do
    FTakeoff.Tick;
  Assert.AreEqual(-BowUpDegrees, Double(FTakeoff.LeanAt(1)), Slop,
    'Facing right, bow up');
  Assert.AreEqual(0.0, Double(FTakeoff.LiftAt(1)), Slop, 'Not risen yet');

  FTakeoff.Start(-ShedLean, -1);
  for var i := 1 to OpenTicks + BowUpTicks do
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
  Assert.IsTrue((SpitAt >= OpenTicks + RearJetAfterTicks) and
    (SpitAt <= OpenTicks + RearJetAfterTicks + 1),
    Format('A while after the front, not at tick %d', [SpitAt]));
end;

procedure TTakeoffTests.TestRisesToItsHeightNeverDown;
begin
  SpitTheWheel(ShedLean);
  var Last: Single := 0;
  for var i := 1 to ManyTicks do
  begin
    var Steady := FTakeoff.Tick.Steady;
    var Lift := FTakeoff.LiftAt(1);
    Assert.IsTrue(Lift >= Last - Slop, Format('Down at tick %d', [Integer(i)]));
    Last := Lift;
    if Steady then
    begin
      Assert.AreEqual(HangLift, Double(Lift), Slop, 'At its height');
      Exit;
    end;
  end;
  Assert.Fail('It never settled');
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
    begin
      Inc(Steadies);
      Assert.AreEqual(0.0, Double(FTakeoff.LeanAt(1)), Slop, 'Level as it settles');
    end;
    if (Steadies = 0) and (FTakeoff.LeanAt(1) > 0) then
      PastLevel := True;
  end;
  Assert.IsTrue(PastLevel, 'Swung past level');
  Assert.AreEqual(1, Steadies, 'Settled, told once');
  Assert.IsTrue(FTakeoff.Stage = tkHanging, 'Hangs');
end;

procedure TTakeoffTests.TestHangingItBobsAndRocksALittle;
begin
  HangIt;
  var Lowest: Single := HangLift;
  var Highest: Single := HangLift;
  var MostLean: Single := 0;
  for var i := 1 to ManyTicks do
  begin
    FTakeoff.Tick;
    Lowest := Min(Lowest, FTakeoff.LiftAt(1));
    Highest := Max(Highest, FTakeoff.LiftAt(1));
    MostLean := Max(MostLean, Abs(FTakeoff.LeanAt(1)));
  end;
  Assert.IsTrue(Highest - Lowest > BobUnits, 'It bobs');
  Assert.IsTrue((Lowest >= HangLift - BobUnits - Slop) and
    (Highest <= HangLift + BobUnits + Slop), 'About its height');
  Assert.IsTrue(MostLean > WobbleDegrees / 2, 'It rocks');
  Assert.IsTrue(MostLean <= WobbleDegrees + Slop, 'A little, kept off the hero');
  Assert.AreEqual(0.0, Double(FTakeoff.Pace), Slop, 'In its place');
end;

// He stands 200 to the right of it
procedure TTakeoffTests.TestHangingItGoesAfterTheHeroBanking;
const
  Away = 200.0;
  UnderWay = 60;
  Settled = 400;
begin
  HangIt;
  var Across: Single := 0;
  var Last: Single := 0;
  for var i := 1 to Settled do
  begin
    FTakeoff.Tick(Away - Across);
    Across := Across + FTakeoff.Pace;
    Assert.IsTrue(FTakeoff.Pace <= ChaseMaxPace + Slop,
      Format('Too fast at tick %d', [Integer(i)]));
    if i = 1 then
      Assert.IsTrue((FTakeoff.Pace > 0) and (FTakeoff.Pace < 0.5),
        'Off to the right, slowly from rest');
    // Going its fastest, banked well past its rocking
    if i = UnderWay then
      Assert.IsTrue(FTakeoff.LeanAt(1) > WobbleDegrees, 'Banked clockwise, into the way');
    Last := FTakeoff.Pace;
  end;
  Assert.IsTrue(Abs(Away - Across) < 10, Format('Over him, %.1f off', [Away - Across]));
  Assert.IsTrue(Abs(Last) < 0.2, 'Come to rest over him');
end;

procedure TTakeoffTests.TestRisingItHearsNoneOfTheHero;
begin
  SpitTheWheel(ShedLean);
  for var i := 1 to RiseTicks do
  begin
    FTakeoff.Tick(500);
    Assert.AreEqual(0.0, Double(FTakeoff.Pace), Slop, Format('Off at tick %d',
      [Integer(i)]));
  end;
end;

procedure TTakeoffTests.TestOnTheRoadAboutTheWheelOffItAboutItsMiddle;
begin
  FTakeoff.Start(ShedLean, 1);
  for var i := 1 to OpenTicks + BowUpTicks do
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
  for var i := 1 to OpenTicks + Settled do
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
  Assert.AreEqual(0.0, Double(FTakeoff.BayAt(1)), Slop, 'No bay');
  Assert.AreEqual(0.0, Double(FTakeoff.NozzleAt(1)), Slop, 'No nozzle');
  Assert.IsFalse(FTakeoff.Tick.Ignite, 'Nothing catches');
end;

initialization
  TDUnitX.RegisterTestFixture(TTakeoffTests);

end.
