{
  Tests.Game.Charge - the Ram's charge: not begun, it does nothing. Begun,
  it tells it falls back, once, and drifts off past the left edge ever
  faster, never faster than its most; out there it tells the band, drops
  to its corridor unseen, and the band blinks there for its while; then it
  rushes in at speed, told once, and runs on at its pace; it brakes short
  of the right edge, told once, slowing all the way, never past where it
  stops, and stops with its right edge just inside the screen's. It rams
  in the pass and the fast part of the brake only; it is low from the pass
  till it climbs; its nozzles are hot from the brake, cooling as it holds,
  cold as it climbs. Its bow dips in the pass and is thrown up in the
  brake. It climbs to its height, level, told once, and is done. No small
  barge comes in from the band till it is up again. A start while it
  charges is nothing; a clear stops it. Begun to go through, it never
  brakes nor holds nor climbs, is never hot, runs on at its pace and is
  gone past the right edge, told once.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Game.Charge;

interface

uses
  DUnitX.TestFramework,
  Game.Charge;

type
  // The cues of the ticks stepped, added up
  TChargeCuesSeen = record
    Leaves, Warns, Rushes, Brakes, Done, Gone: Integer;
  end;

  [TestFixture]
  TChargeTests = class
  private
    FCharge: TCharge;
    FSeen: TChargeCuesSeen;
    procedure Step;
    // Begun from where it hangs, at rest
    procedure StartFromItsHang;
    // Steps till it is at AStage; the ticks it took. Fails past ALimit.
    function StepTill(AStage: TChargeStage; ALimit: Integer): Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestNotBegunItDoesNothing;
    [Test]
    procedure TestItFallsBackPastTheLeftEdgeEverFaster;
    [Test]
    procedure TestOutThereTheBandBlinksAtItsCorridor;
    [Test]
    procedure TestItRushesInAtItsPace;
    [Test]
    procedure TestItBrakesShortOfTheRightEdgeSlowingAllTheWay;
    [Test]
    procedure TestItRamsInThePassAndTheFastPartOfTheBrakeOnly;
    [Test]
    procedure TestLowFromThePassTillItClimbs;
    [Test]
    procedure TestHotFromTheBrakeCoolingAsItHolds;
    [Test]
    procedure TestItsBowDipsInThePassAndIsThrownUpInTheBrake;
    [Test]
    procedure TestItClimbsToItsHeightLevelAndIsDone;
    [Test]
    procedure TestItHoldsTheFlockFromTheBandTillItIsUp;
    [Test]
    procedure TestAStartWhileItChargesIsNothing;
    [Test]
    procedure TestAClearStopsIt;
    [Test]
    procedure TestThroughItIsGonePastTheRightEdgeAtItsPace;
  end;

implementation

uses
  System.SysUtils,
  Game.Space,
  Game.Takeoff;

const
  HullWidth = 169.0;
  HangLeft = 170.0;
  LowLift = 56.0;
  // A whole charge is over well within this: fifteen seconds
  ChargeTicks = 500;
  Slack = 0.01;

procedure TChargeTests.Setup;
begin
  FCharge := TCharge.Create(HullWidth);
  FSeen := Default(TChargeCuesSeen);
end;

procedure TChargeTests.TearDown;
begin
  FCharge.Free;
end;

procedure TChargeTests.Step;
begin
  var Cue := FCharge.Tick;
  if Cue.Leaves then
    Inc(FSeen.Leaves);
  if Cue.Warns then
    Inc(FSeen.Warns);
  if Cue.Rushes then
    Inc(FSeen.Rushes);
  if Cue.Brakes then
    Inc(FSeen.Brakes);
  if Cue.Done then
    Inc(FSeen.Done);
  if Cue.Gone then
    Inc(FSeen.Gone);
end;

procedure TChargeTests.StartFromItsHang;
begin
  FCharge.Start(HangLeft, 0, HangLift, LowLift);
end;

function TChargeTests.StepTill(AStage: TChargeStage; ALimit: Integer): Integer;
begin
  Result := 0;
  while FCharge.Stage <> AStage do
  begin
    Step;
    Inc(Result);
    if Result > ALimit then
      Assert.Fail(Format('Not at stage %d in %d ticks', [Ord(AStage), ALimit]));
  end;
end;

procedure TChargeTests.TestNotBegunItDoesNothing;
begin
  for var i := 1 to ChargeTicks do
    Step;
  Assert.IsFalse(FCharge.Running, 'Not running');
  Assert.AreEqual(0, FSeen.Leaves + FSeen.Warns + FSeen.Rushes + FSeen.Brakes +
    FSeen.Done, 'Nothing told');
  Assert.IsFalse(FCharge.RunsLow or FCharge.Rams or FCharge.Soft or
    FCharge.HoldsFlock, 'Nothing of a charge');
end;

procedure TChargeTests.TestItFallsBackPastTheLeftEdgeEverFaster;
begin
  StartFromItsHang;
  Assert.IsTrue(FCharge.Running, 'Running');
  var LastPace: Single := 0;
  while FCharge.Stage = csLeaving do
  begin
    Step;
    if FCharge.Stage <> csLeaving then
      Break;
    Assert.IsTrue(FCharge.Pace <= LastPace + Slack, 'Ever faster to the left');
    Assert.IsTrue(FCharge.Pace >= -ChargeLeaveMost - Slack, 'Never past its most');
    Assert.AreEqual(Double(HangLift), Double(FCharge.Lift), Slack,
      'At its height while it is seen');
    LastPace := FCharge.Pace;
  end;
  Assert.AreEqual(1, FSeen.Leaves, 'Told once');
  Assert.IsTrue(FCharge.Left + HullWidth < 0, 'Off past the left edge');
end;

procedure TChargeTests.TestOutThereTheBandBlinksAtItsCorridor;
begin
  StartFromItsHang;
  StepTill(csWarning, ChargeTicks);
  Assert.AreEqual(1, FSeen.Warns, 'The band told once');
  Assert.AreEqual(Double(LowLift), Double(FCharge.Lift), Slack, 'Down to its corridor');
  Assert.AreEqual(Double(LowLift), Double(FCharge.LowLift), Slack, 'The corridor told');
  var Left := FCharge.Left;
  var Lit := 0;
  var Dark := 0;
  for var i := 1 to ChargeWarnTicks - 1 do
  begin
    Step;
    Assert.AreEqual<TChargeStage>(csWarning, FCharge.Stage, 'Still out there');
    Assert.AreEqual(Double(Left), Double(FCharge.Left), Slack, 'Standing off the screen');
    if FCharge.WarnAt(1) > 0.5 then
      Inc(Lit)
    else
      Inc(Dark);
  end;
  Assert.IsTrue((Lit > 0) and (Dark > 0), 'It blinks');
  Step;
  Assert.AreEqual<TChargeStage>(csPassing, FCharge.Stage, 'In after the band''s while');
  Assert.AreEqual(0.0, Double(FCharge.WarnAt(1)), Slack, 'Gone as it comes');
end;

procedure TChargeTests.TestItRushesInAtItsPace;
begin
  StartFromItsHang;
  StepTill(csPassing, ChargeTicks);
  Assert.AreEqual(1, FSeen.Rushes, 'Told once');
  Assert.AreEqual(Double(ChargePace), Double(FCharge.Pace), Slack, 'At speed at once');
  Assert.IsTrue(FCharge.Left + HullWidth > -ChargeBeyond, 'Coming in');
  while FCharge.Stage = csPassing do
  begin
    Step;
    if FCharge.Stage = csPassing then
      Assert.AreEqual(Double(ChargePace), Double(FCharge.Pace), Slack, 'At its pace');
  end;
end;

procedure TChargeTests.TestItBrakesShortOfTheRightEdgeSlowingAllTheWay;
begin
  var Stops: Single := ScreenWidth - ChargeHoldInset - HullWidth;
  StartFromItsHang;
  StepTill(csBraking, ChargeTicks);
  Assert.AreEqual(1, FSeen.Brakes, 'Told once');
  var LastPace := FCharge.Pace;
  Assert.IsTrue(LastPace > ChargePace / 2, 'Fast as it starts to brake');
  while FCharge.Stage = csBraking do
  begin
    Step;
    Assert.IsTrue(FCharge.Pace <= LastPace + Slack, 'Slowing all the way');
    Assert.IsTrue(FCharge.Pace >= -Slack, 'Never back');
    Assert.IsTrue(FCharge.Left <= Stops + Slack, 'Never past where it stops');
    LastPace := FCharge.Pace;
  end;
  Assert.AreEqual(Double(Stops), Double(FCharge.Left), Slack,
    'Its right edge just inside the screen''s');
  Assert.AreEqual(1, FSeen.Brakes, 'Still once');
end;

procedure TChargeTests.TestItRamsInThePassAndTheFastPartOfTheBrakeOnly;
begin
  StartFromItsHang;
  var Rammed := 0;
  for var i := 1 to ChargeTicks do
  begin
    Step;
    if not FCharge.Rams then
      Continue;
    Inc(Rammed);
    Assert.IsTrue(FCharge.Stage in [csPassing, csBraking], 'In the run only');
    Assert.IsTrue(FCharge.Pace >= ChargeRamPace - Slack, 'Fast');
  end;
  Assert.IsTrue(Rammed > 0, 'It rams');
end;

procedure TChargeTests.TestLowFromThePassTillItClimbs;
begin
  StartFromItsHang;
  for var i := 1 to ChargeTicks do
  begin
    Step;
    Assert.IsTrue((FCharge.Stage in [csPassing, csBraking, csHolding]) = FCharge.RunsLow,
      Format('Stage %d', [Ord(FCharge.Stage)]));
    if FCharge.RunsLow then
      Assert.AreEqual(Double(LowLift), Double(FCharge.Lift), Slack, 'In its corridor');
  end;
end;

procedure TChargeTests.TestHotFromTheBrakeCoolingAsItHolds;
begin
  StartFromItsHang;
  StepTill(csBraking, ChargeTicks);
  Assert.IsTrue(FCharge.Soft, 'Soft as it brakes');
  StepTill(csHolding, ChargeTicks);
  Assert.AreEqual(1.0, Double(FCharge.HeatAt(1)), Slack, 'Hot as it stops');
  var LastHeat := FCharge.HeatAt(1);
  while FCharge.Stage = csHolding do
  begin
    Assert.IsTrue(FCharge.Soft, 'Soft while it holds');
    Step;
    Assert.IsTrue(FCharge.HeatAt(1) <= LastHeat + Slack, 'Cooling');
    LastHeat := FCharge.HeatAt(1);
  end;
  Assert.IsFalse(FCharge.Soft, 'Hard as it climbs');
  Assert.AreEqual(0.0, Double(FCharge.HeatAt(1)), Slack, 'Cold');
end;

procedure TChargeTests.TestItsBowDipsInThePassAndIsThrownUpInTheBrake;
begin
  StartFromItsHang;
  StepTill(csPassing, ChargeTicks);
  Assert.IsTrue(FCharge.Bow > 0, 'Bow down in the pass');
  StepTill(csHolding, ChargeTicks);
  Assert.IsTrue(FCharge.Bow < ChargeBrakeBow / 2, 'Bow thrown up by the brake');
end;

procedure TChargeTests.TestItClimbsToItsHeightLevelAndIsDone;
begin
  StartFromItsHang;
  StepTill(csClimbing, ChargeTicks);
  var LastLift := FCharge.Lift;
  while FCharge.Stage = csClimbing do
  begin
    Step;
    Assert.IsTrue(FCharge.Lift >= LastLift - Slack, 'Never down on the way');
    Assert.AreEqual(0.0, Double(FCharge.Pace), Slack, 'Straight up');
    LastLift := FCharge.Lift;
  end;
  Assert.AreEqual(1, FSeen.Done, 'Told once');
  Assert.IsFalse(FCharge.Running, 'Done');
  Assert.AreEqual(Double(HangLift), Double(FCharge.Lift), Slack, 'At its height');
  Assert.AreEqual(0.0, Double(FCharge.Bow), Slack, 'Level');
  for var i := 1 to ChargeTicks do
    Step;
  Assert.AreEqual(1, FSeen.Done, 'Still once');
end;

procedure TChargeTests.TestItHoldsTheFlockFromTheBandTillItIsUp;
begin
  StartFromItsHang;
  for var i := 1 to ChargeTicks do
  begin
    Step;
    Assert.IsTrue((FCharge.Stage in [csWarning..csClimbing]) = FCharge.HoldsFlock,
      Format('Stage %d', [Ord(FCharge.Stage)]));
  end;
end;

procedure TChargeTests.TestAStartWhileItChargesIsNothing;
begin
  StartFromItsHang;
  StepTill(csPassing, ChargeTicks);
  var Left := FCharge.Left;
  FCharge.Start(HangLeft, 0, HangLift, LowLift);
  Assert.AreEqual<TChargeStage>(csPassing, FCharge.Stage, 'Still in the pass');
  Assert.AreEqual(Double(Left), Double(FCharge.Left), Slack, 'Where it was');
end;

procedure TChargeTests.TestAClearStopsIt;
begin
  StartFromItsHang;
  StepTill(csBraking, ChargeTicks);
  FCharge.Clear;
  Assert.IsFalse(FCharge.Running, 'Stopped');
  Assert.IsFalse(FCharge.Soft or FCharge.RunsLow or FCharge.HoldsFlock, 'Nothing of it');
  Assert.AreEqual(0.0, Double(FCharge.HeatAt(1)), Slack, 'Cold');
end;

procedure TChargeTests.TestThroughItIsGonePastTheRightEdgeAtItsPace;
begin
  FCharge.Start(HangLeft, 0, HangLift, LowLift, ceThrough);
  StepTill(csPassing, ChargeTicks);
  var Ticks := 0;
  while FCharge.Running do
  begin
    Step;
    Assert.IsFalse(FCharge.Stage in [csBraking..csClimbing], 'Never brakes');
    Assert.IsFalse(FCharge.Soft, 'Never hot');
    if FCharge.Running then
      Assert.AreEqual(Double(ChargePace), Double(FCharge.Pace), Slack, 'At its pace');
    Inc(Ticks);
    if Ticks > ChargeTicks then
      Assert.Fail('Never gone');
  end;
  Assert.IsTrue(FCharge.Left >= ScreenWidth, 'Past the right edge');
  Assert.AreEqual(1, FSeen.Gone, 'Gone, told once');
  Assert.AreEqual(0, FSeen.Brakes + FSeen.Done, 'No brake, no climb');
  Assert.IsFalse(FCharge.HoldsFlock, 'The flock let go');
  for var i := 1 to ChargeTicks do
    Step;
  Assert.AreEqual(1, FSeen.Gone, 'Still once');
end;

initialization
  TDUnitX.RegisterTestFixture(TChargeTests);

end.
