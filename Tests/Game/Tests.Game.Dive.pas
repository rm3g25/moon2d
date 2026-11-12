{
  Tests.Game.Dive - the Ram's dive: not begun, it does nothing. Begun, it
  tells the silence once and flashes through it, its way across dying out,
  only sagging a little, nothing low or hot; then it tells the fall once
  and falls straight down, ever faster, never past its floor, striking a
  hero only while it falls; it tells the blow once, on its floor. Low, it
  rides the floor as it moves; its jets catch again once, a few ticks on,
  and from then it is hot, cooling as it holds, cold as it rises. It rises
  to its height, level, told once, and is done. No small barge comes in
  from the silence till it is up again. A start while it dives is nothing;
  a clear stops it.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Game.Dive;

interface

uses
  DUnitX.TestFramework,
  Game.Dive;

type
  // The cues of the ticks stepped, added up
  TDiveCuesSeen = record
    Hushes, Drops, Lands, Relights, Done: Integer;
  end;

  [TestFixture]
  TDiveTests = class
  private
    FDive: TDive;
    FSeen: TDiveCuesSeen;
    FFloor: Single;
    procedure Step;
    // Begun from where it hangs, drifting right
    procedure StartFromItsHang;
    // Steps till it is at AStage; the ticks it took. Fails past ALimit.
    function StepTill(AStage: TDiveStage; ALimit: Integer): Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestNotBegunItDoesNothing;
    [Test]
    procedure TestTheSilenceFlashesAndOnlySags;
    [Test]
    procedure TestItFallsEverFasterNeverPastItsFloor;
    [Test]
    procedure TestItStrikesOnlyWhileItFalls;
    [Test]
    procedure TestLowItRidesTheFloor;
    [Test]
    procedure TestItsJetsCatchAFewTicksOnThenItIsHotAndCools;
    [Test]
    procedure TestItRisesToItsHeightLevelAndIsDone;
    [Test]
    procedure TestLowFromTheFallTillItRises;
    [Test]
    procedure TestItHoldsTheFlockFromTheSilenceTillItIsUp;
    [Test]
    procedure TestAStartWhileItDivesIsNothing;
    [Test]
    procedure TestAClearStopsIt;
  end;

implementation

uses
  System.SysUtils,
  Game.Takeoff;

const
  // Over the head of a hero on the main barge at its line
  Floor = 40.0;
  HangPace = 1.5;
  HangBow = 3.0;
  // A whole dive is over well within this: ten seconds
  DiveTicks = 330;
  Slack = 0.01;

procedure TDiveTests.Setup;
begin
  FDive := TDive.Create;
  FSeen := Default(TDiveCuesSeen);
  FFloor := Floor;
end;

procedure TDiveTests.TearDown;
begin
  FDive.Free;
end;

procedure TDiveTests.Step;
begin
  var Cue := FDive.Tick(FFloor);
  if Cue.Hushes then
    Inc(FSeen.Hushes);
  if Cue.Drops then
    Inc(FSeen.Drops);
  if Cue.Lands then
    Inc(FSeen.Lands);
  if Cue.Relights then
    Inc(FSeen.Relights);
  if Cue.Done then
    Inc(FSeen.Done);
end;

procedure TDiveTests.StartFromItsHang;
begin
  FDive.Start(HangPace, HangLift, HangBow);
end;

function TDiveTests.StepTill(AStage: TDiveStage; ALimit: Integer): Integer;
begin
  Result := 0;
  while FDive.Stage <> AStage do
  begin
    Step;
    Inc(Result);
    if Result > ALimit then
      Assert.Fail(Format('Not at stage %d in %d ticks', [Ord(AStage), ALimit]));
  end;
end;

procedure TDiveTests.TestNotBegunItDoesNothing;
begin
  for var i := 1 to DiveTicks do
    Step;
  Assert.IsFalse(FDive.Running, 'Not running');
  Assert.AreEqual(0, FSeen.Hushes + FSeen.Drops + FSeen.Lands + FSeen.Relights +
    FSeen.Done, 'No cue');
  Assert.IsFalse(FDive.Flashes or FDive.Slams or FDive.RunsLow or FDive.Soft or
    FDive.HoldsFlock, 'Nothing of a dive');
end;

procedure TDiveTests.TestTheSilenceFlashesAndOnlySags;
begin
  StartFromItsHang;
  Assert.IsTrue(FDive.Running, 'Running');
  var LastPace := Abs(FDive.Pace);
  while FDive.Stage = dvHush do
  begin
    Step;
    if FDive.Stage <> dvHush then
      Break;
    Assert.IsTrue(FDive.Flashes, 'Its eye flashes');
    Assert.IsTrue(Abs(FDive.Pace) <= LastPace + Slack, 'Its way across dying out');
    Assert.IsTrue(FDive.Lift <= HangLift + Slack, 'Never up');
    Assert.IsTrue(FDive.Lift >= HangLift - DiveSag - Slack, 'Only a sag');
    Assert.IsFalse(FDive.RunsLow or FDive.Soft or FDive.Slams, 'Not low, not hot');
    LastPace := Abs(FDive.Pace);
  end;
  Assert.AreEqual(1, FSeen.Hushes, 'The silence told once');
  Assert.AreEqual(1, FSeen.Drops, 'Then the fall');
  Assert.AreEqual(0.0, Double(FDive.Pace), Slack, 'Straight down from here');
  Assert.IsFalse(FDive.Flashes, 'The flash over as it falls');
end;

procedure TDiveTests.TestItFallsEverFasterNeverPastItsFloor;
begin
  StartFromItsHang;
  StepTill(dvFalling, DiveTicks);
  var LastFall: Single := 0;
  while FDive.Stage = dvFalling do
  begin
    Step;
    Assert.IsTrue(FDive.Lift >= FFloor - Slack, 'Never past its floor');
    if FDive.Stage <> dvFalling then
      Break;
    Assert.IsTrue(FDive.Fall > LastFall, 'Ever faster');
    Assert.AreEqual(0.0, Double(FDive.Pace), Slack, 'Straight down');
    LastFall := FDive.Fall;
  end;
  Assert.AreEqual(1, FSeen.Lands, 'The blow told once');
  Assert.AreEqual(Double(FFloor), Double(FDive.Lift), Slack, 'On its floor');
  Assert.IsTrue(LastFall > 10, 'Like a stone at the end');
end;

procedure TDiveTests.TestItStrikesOnlyWhileItFalls;
begin
  StartFromItsHang;
  for var i := 1 to DiveTicks do
  begin
    Step;
    Assert.AreEqual<Boolean>(FDive.Stage = dvFalling, FDive.Slams,
      Format('Stage %d', [Ord(FDive.Stage)]));
  end;
end;

procedure TDiveTests.TestLowItRidesTheFloor;
const
  Raised = 20.0;
begin
  StartFromItsHang;
  StepTill(dvHolding, DiveTicks);
  FFloor := Floor + Raised;
  for var i := 1 to 30 do
    Step;
  Assert.AreEqual(Double(FFloor), Double(FDive.Lift), 0.1, 'Up with its floor');
  FFloor := Floor;
  for var i := 1 to 30 do
    Step;
  Assert.AreEqual(Double(FFloor), Double(FDive.Lift), 0.1, 'And down with it');
end;

procedure TDiveTests.TestItsJetsCatchAFewTicksOnThenItIsHotAndCools;
begin
  StartFromItsHang;
  StepTill(dvHolding, DiveTicks);
  Assert.IsFalse(FDive.Soft, 'Not the tick it lands');
  var Ticks := 0;
  while FSeen.Relights = 0 do
  begin
    Assert.IsFalse(FDive.Soft, 'Cold before they catch');
    Step;
    Inc(Ticks);
  end;
  Assert.AreEqual(DiveRelightTicks, Ticks, 'A few ticks after the blow');
  Assert.IsTrue(FDive.Soft, 'Hot as they catch');
  Assert.AreEqual(1.0, Double(FDive.HeatAt(1)), Slack, 'Full heat');
  var LastHeat := FDive.HeatAt(1);
  while FDive.Stage = dvHolding do
  begin
    Step;
    if FDive.Stage <> dvHolding then
      Break;
    Assert.IsTrue(FDive.Soft, 'Hot while it holds');
    Assert.IsTrue(FDive.HeatAt(1) <= LastHeat + Slack, 'Cooling');
    LastHeat := FDive.HeatAt(1);
  end;
  Assert.AreEqual(1, FSeen.Relights, 'Caught once');
  Assert.IsFalse(FDive.Soft, 'Hard as it rises');
  Assert.AreEqual(0.0, Double(FDive.HeatAt(1)), Slack, 'Cold');
end;

procedure TDiveTests.TestItRisesToItsHeightLevelAndIsDone;
begin
  StartFromItsHang;
  StepTill(dvRising, DiveTicks);
  var LastLift := FDive.Lift;
  while FDive.Stage = dvRising do
  begin
    Step;
    Assert.IsTrue(FDive.Lift >= LastLift - Slack, 'Never down on the way');
    LastLift := FDive.Lift;
  end;
  Assert.AreEqual(1, FSeen.Done, 'Done once');
  Assert.IsFalse(FDive.Running, 'Not running');
  Assert.AreEqual(Double(HangLift), Double(FDive.Lift), Slack, 'At its height');
  Assert.AreEqual(0.0, Double(FDive.Bow), Slack, 'Level');
end;

procedure TDiveTests.TestLowFromTheFallTillItRises;
begin
  StartFromItsHang;
  for var i := 1 to DiveTicks do
  begin
    Step;
    Assert.AreEqual<Boolean>(FDive.Stage in [dvFalling, dvHolding], FDive.RunsLow,
      Format('Stage %d', [Ord(FDive.Stage)]));
  end;
end;

procedure TDiveTests.TestItHoldsTheFlockFromTheSilenceTillItIsUp;
begin
  StartFromItsHang;
  Assert.IsTrue(FDive.HoldsFlock, 'From its start');
  for var i := 1 to DiveTicks do
  begin
    Step;
    Assert.AreEqual<Boolean>(FDive.Running, FDive.HoldsFlock,
      Format('Stage %d', [Ord(FDive.Stage)]));
  end;
  Assert.IsFalse(FDive.HoldsFlock, 'Not once it is up');
end;

procedure TDiveTests.TestAStartWhileItDivesIsNothing;
begin
  StartFromItsHang;
  StepTill(dvHolding, DiveTicks);
  var Lift := FDive.Lift;
  FDive.Start(0, HangLift, 0);
  Assert.AreEqual<TDiveStage>(dvHolding, FDive.Stage, 'Still low');
  Assert.AreEqual(Double(Lift), Double(FDive.Lift), Slack, 'Where it was');
end;

procedure TDiveTests.TestAClearStopsIt;
begin
  StartFromItsHang;
  StepTill(dvHolding, DiveTicks);
  for var i := 1 to DiveRelightTicks + 2 do
    Step;
  FDive.Clear;
  Assert.IsFalse(FDive.Running, 'Stopped');
  Assert.IsFalse(FDive.Soft or FDive.RunsLow or FDive.HoldsFlock or FDive.Flashes,
    'Nothing of it');
  Assert.AreEqual(0.0, Double(FDive.HeatAt(1)), Slack, 'Cold');
end;

initialization
  TDUnitX.RegisterTestFixture(TDiveTests);

end.
