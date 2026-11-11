{
  Tests.Game.Takeoff - the Ram off the road: nothing till it starts. The
  bays come out first, then the nozzles, never back, the hull as it leaned
  and no fire; the front jet catches once they are out, told with the
  tick, and the bow lifts the other way round from where the hull faces,
  about its rear wheel, nothing risen yet. The rear jet catches once, a
  while after, and it starts to rise with its rear wheel in; the wheel is
  thrown out once, on the tick it is SpitLift up, and is out from then on.
  It rises to its height, never down on the way, to its height as it
  settles; it rights itself as it rises, swinging past level and back, and
  settles level, told once. On the road it turns about the wheel, off it
  about its middle. Hanging, it bobs and rocks a little about its height
  and level; told where the hero is, it goes after him slower than he
  runs, no faster than its most, banking into the way it goes - rising, it
  hears none of that. A jet flares as it catches and comes down to its
  steady fire. A stop takes it all, the wheel in again.

  Hanging, it can be carried - where it is told, between the ticks too -
  and let go to hang on from its height with no jump; on its way up it
  cannot. Aloft its nozzles swivel with the way it goes and the way it
  gathers pace, never past their most; a hard brake throws them ahead; on
  the road they do not swivel.

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
    procedure CatchTheRearJet(AFrom: Single);
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
    procedure TestTheRearJetCatchesOnceThenTheWheelIsThrownOut;
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
    [Test]
    procedure TestHungItIsSteadyFromTheStart;
    [Test]
    procedure TestCarriedItIsWhereItIsTold;
    [Test]
    procedure TestLetGoItHangsOnFromItsHeight;
    [Test]
    procedure TestOnItsWayUpItCannotBeCarried;
    [Test]
    procedure TestGoingRightTheNozzlesSwingBackNeverPastTheirMost;
    [Test]
    procedure TestAHardBrakeThrowsTheNozzlesAhead;
    [Test]
    procedure TestOnTheRoadTheNozzlesDoNotSwivel;
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

procedure TTakeoffTests.CatchTheRearJet(AFrom: Single);
begin
  FTakeoff.Start(AFrom, 1);
  for var i := 1 to ManyTicks do
  begin
    var Cue := FTakeoff.Tick;
    if Cue.Ignite and (Cue.Jet = tjRear) then
      Exit;
  end;
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

procedure TTakeoffTests.TestTheRearJetCatchesOnceThenTheWheelIsThrownOut;
begin
  FTakeoff.Start(ShedLean, 1);
  var Ignites := 0;
  var RearAt := 0;
  var Spits := 0;
  var SpitAt := 0;
  var LastLift: Single := 0;
  for var i := 1 to ManyTicks do
  begin
    var Cue := FTakeoff.Tick;
    if Cue.Ignite then
      Inc(Ignites);
    if Cue.Ignite and (Cue.Jet = tjRear) then
      RearAt := i;
    if Cue.Spit then
    begin
      Inc(Spits);
      SpitAt := i;
      Assert.IsTrue(FTakeoff.LiftAt(1) >= SpitLift, 'Up as high');
      Assert.IsTrue(LastLift < SpitLift, 'Not a tick late');
    end;
    Assert.IsTrue(FTakeoff.Spat = (Spits > 0),
      Format('Out only from the throw on, tick %d', [Integer(i)]));
    LastLift := FTakeoff.LiftAt(1);
  end;
  Assert.AreEqual(2, Ignites, 'Two jets, each once');
  Assert.IsTrue((RearAt >= OpenTicks + RearJetAfterTicks) and
    (RearAt <= OpenTicks + RearJetAfterTicks + 1),
    Format('A while after the front, not at tick %d', [RearAt]));
  Assert.AreEqual(1, Spits, 'One wheel');
  Assert.IsTrue(SpitAt > RearAt, 'Thrown out after the rear jet catches');
end;

procedure TTakeoffTests.TestRisesToItsHeightNeverDown;
begin
  CatchTheRearJet(ShedLean);
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
  CatchTheRearJet(ShedLean);
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
  CatchTheRearJet(ShedLean);
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
  CatchTheRearJet(ShedLean);
  while not FTakeoff.Spat and FTakeoff.Running do
    FTakeoff.Tick;
  FTakeoff.Stop;
  Assert.IsFalse(FTakeoff.Spat, 'The wheel in again');
  Assert.IsFalse(FTakeoff.Running, 'Stopped');
  Assert.AreEqual(0.0, Double(FTakeoff.LeanAt(1)), Slop, 'Level');
  Assert.AreEqual(0.0, Double(FTakeoff.LiftAt(1)), Slop, 'On the road');
  Assert.AreEqual(0.0, Double(FTakeoff.JetAt(tjRear, 1)), Slop, 'No fire');
  Assert.AreEqual(0.0, Double(FTakeoff.BayAt(1)), Slop, 'No bay');
  Assert.AreEqual(0.0, Double(FTakeoff.NozzleAt(1)), Slop, 'No nozzle');
  Assert.IsFalse(FTakeoff.Tick.Ignite, 'Nothing catches');
end;

procedure TTakeoffTests.TestHungItIsSteadyFromTheStart;
begin
  FTakeoff.Hang;
  Assert.AreEqual(Ord(tkHanging), Ord(FTakeoff.Stage), 'Hanging');
  Assert.IsTrue(FTakeoff.Running, 'Running');
  Assert.IsTrue(FTakeoff.Spat, 'The rear wheel out of its well');
  Assert.AreEqual(Double(HangLift), Double(FTakeoff.LiftAt(1)), 0.001, 'At its height');
  Assert.AreEqual(Double(HangLift), Double(FTakeoff.LiftAt(0)), 0.001, 'And a tick ago');
  Assert.AreEqual(1.0, Double(FTakeoff.AirAt(1)), 0.001, 'Turning about its middle');
  Assert.AreEqual(1.0, Double(FTakeoff.BayAt(1)), 0.001, 'The bays out');
  Assert.AreEqual(1.0, Double(FTakeoff.NozzleAt(1)), 0.001, 'The nozzles out');
  Assert.AreEqual(1.0, Double(FTakeoff.JetAt(tjFront, 1)), 0.001, 'The front jet steady');
  Assert.AreEqual(1.0, Double(FTakeoff.JetAt(tjRear, 0)), 0.001, 'The rear jet steady a tick ago');
  var Cue := FTakeoff.Tick(0);
  Assert.IsFalse(Cue.Ignite or Cue.Spit or Cue.Steady, 'Nothing of the way up');
  Assert.IsTrue(Abs(FTakeoff.LiftAt(1) - HangLift) <= BobUnits + 0.001, 'Bobbing about its height');
end;

procedure TTakeoffTests.TestCarriedItIsWhereItIsTold;
const
  Corridor = 56.0;
  Bow = -10.0;
  RunPace = 20.0;
begin
  FTakeoff.Hang;
  FTakeoff.Tick;
  FTakeoff.Carry(RunPace, Corridor, Bow);
  Assert.AreEqual(Ord(tkCarried), Ord(FTakeoff.Stage), 'Carried');
  Assert.IsTrue(FTakeoff.Aloft, 'Aloft');
  Assert.AreEqual(Double(RunPace), Double(FTakeoff.Pace), Slop, 'Its pace');
  Assert.AreEqual(Double(Corridor), Double(FTakeoff.LiftAt(1)), Slop, 'Its height');
  Assert.AreEqual(Double(Bow), Double(FTakeoff.LeanAt(1)), Slop, 'Its lean');
  Assert.IsTrue(FTakeoff.LiftAt(0.5) > Corridor, 'Between the ticks, on its way there');
  // A tick with nothing told: it stays where it was put
  FTakeoff.Tick(200);
  Assert.AreEqual(Double(Corridor), Double(FTakeoff.LiftAt(1)), Slop, 'Deaf to the hero');
  Assert.AreEqual(Double(Bow), Double(FTakeoff.LeanAt(1)), Slop, 'Its lean kept');
end;

procedure TTakeoffTests.TestLetGoItHangsOnFromItsHeight;
begin
  FTakeoff.Hang;
  FTakeoff.Tick;
  FTakeoff.Carry(0, HangLift, 0);
  FTakeoff.Release;
  Assert.AreEqual(Ord(tkHanging), Ord(FTakeoff.Stage), 'Hanging');
  var Last := FTakeoff.LiftAt(1);
  for var i := 1 to 10 do
  begin
    FTakeoff.Tick(0);
    Assert.IsTrue(Abs(FTakeoff.LiftAt(1) - Last) < 0.5,
      Format('No jump at tick %d', [Integer(i)]));
    Last := FTakeoff.LiftAt(1);
  end;
  Assert.IsTrue(Abs(FTakeoff.LiftAt(1) - HangLift) <= BobUnits + Slop, 'About its height');
end;

procedure TTakeoffTests.TestOnItsWayUpItCannotBeCarried;
begin
  CatchTheRearJet(ShedLean);
  FTakeoff.Tick;
  var Lift := FTakeoff.LiftAt(1);
  FTakeoff.Carry(5, 100, 0);
  Assert.AreEqual(Ord(tkRising), Ord(FTakeoff.Stage), 'Still rising');
  Assert.AreEqual(Double(Lift), Double(FTakeoff.LiftAt(1)), Slop, 'Not moved');
  Assert.IsFalse(FTakeoff.Aloft, 'Not aloft yet');
  FTakeoff.Release;
  Assert.AreEqual(Ord(tkRising), Ord(FTakeoff.Stage), 'A release is nothing');
end;

procedure TTakeoffTests.TestGoingRightTheNozzlesSwingBackNeverPastTheirMost;
const
  RunPace = 20.0;
begin
  FTakeoff.Hang;
  for var i := 1 to 40 do
  begin
    FTakeoff.Tick;
    FTakeoff.Carry(RunPace, HangLift, 0);
    Assert.IsTrue(Abs(FTakeoff.SwivelAt(1)) <= SwivelMost + Slop,
      Format('Past its most at tick %d', [Integer(i)]));
  end;
  Assert.IsTrue(FTakeoff.SwivelAt(1) > SwivelMost / 2,
    'Swung clockwise, the fire thrown back');
end;

procedure TTakeoffTests.TestAHardBrakeThrowsTheNozzlesAhead;
const
  RunPace = 20.0;
  Loss = 0.8;
begin
  FTakeoff.Hang;
  for var i := 1 to 40 do
  begin
    FTakeoff.Tick;
    FTakeoff.Carry(RunPace, HangLift, 0);
  end;
  var Speed: Single := RunPace;
  for var i := 1 to 15 do
  begin
    Speed := Speed - Loss;
    FTakeoff.Tick;
    FTakeoff.Carry(Speed, HangLift, 0);
    Assert.IsTrue(Abs(FTakeoff.SwivelAt(1)) <= SwivelMost + Slop, 'Never past its most');
  end;
  Assert.IsTrue(Speed > 0, 'Still going right');
  Assert.IsTrue(FTakeoff.SwivelAt(1) < -SwivelMost / 2,
    'Swung the other way, the fire thrown ahead');
end;

procedure TTakeoffTests.TestOnTheRoadTheNozzlesDoNotSwivel;
begin
  FTakeoff.Start(ShedLean, 1);
  for var i := 1 to OpenTicks + 10 do
  begin
    FTakeoff.Tick(200);
    Assert.AreEqual(0.0, Double(FTakeoff.SwivelAt(1)), Slop, 'Straight down');
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTakeoffTests);

end.
