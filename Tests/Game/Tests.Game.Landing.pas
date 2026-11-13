{
  Tests.Game.Landing - the end of the flight: idle, it tells nothing and
  spares no one. Begun, it runs from then on; the flight goes on at its
  pace a while, then it tells the slowdown once. Run with the belt as the
  game runs it - slowed over its ramp - the road's edge comes in once,
  from just beyond the right edge, and rides the slowing world to stop a
  barge's length from the left edge - the main barge docked against it
  stops against the left edge; once the world stands it tells so once,
  and a breath later the hand-over to the titles, once. A start while
  it runs is nothing; a clear makes it idle.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Game.Landing;

interface

uses
  DUnitX.TestFramework,
  Game.Belt,
  Game.Landing;

type
  // What the ticks told, added up, and when
  TLandingSeen = record
    SlowsDown, RoadIn, Stands, HandsOver: Integer;
    SlowTick, StandTick, HandTick: Integer;
    RoadLeft: Double;
    // Where the road's edge stood after the last tick, riding the belt
    // from where it came in
    RoadNow: Double;
  end;

  [TestFixture]
  TLandingTests = class
  private
    FLanding: TLanding;
    FBelt: TBelt;
    FSeen: TLandingSeen;
    FTicks: Integer;
    // A tick as the game has it: the belt first, the road riding it, then
    // the landing told what the belt has left to run and whether it
    // stands; its slowdown carried out on the belt
    procedure Step;
    procedure StepTicks(ACount: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestIdleItTellsNothing;
    [Test]
    procedure TestBegunItRunsTheFlightGoesOnThenSlowsOnce;
    [Test]
    procedure TestTheRoadComesInOnceFromBeyondTheRightEdge;
    [Test]
    procedure TestTheRoadStopsABargesLengthFromTheLeftEdge;
    [Test]
    procedure TestItTellsOnceThatTheWorldStands;
    [Test]
    procedure TestTheHandOverABreathAfterTheStand;
    [Test]
    procedure TestAStartWhileItRunsIsNothing;
    [Test]
    procedure TestAClearMakesItIdle;
  end;

implementation

uses
  Game.Space,
  Game.Barge;

const
  // The whole landing is over well within this
  ManyTicks = 600;

procedure TLandingTests.Setup;
begin
  FLanding := TLanding.Create;
  FBelt := TBelt.Create;
  FBelt.Run(BeltFlight);
  for var i := 1 to BeltRampTicks + 1 do
    FBelt.Tick;
  FSeen := Default(TLandingSeen);
  FTicks := 0;
end;

procedure TLandingTests.TearDown;
begin
  FBelt.Free;
  FLanding.Free;
end;

procedure TLandingTests.Step;
begin
  Inc(FTicks);
  FBelt.Tick;
  if FSeen.RoadIn > 0 then
    FSeen.RoadNow := FSeen.RoadNow - FBelt.Speed;
  var Stands := (FBelt.Speed = 0) and not FBelt.Running;
  var Cue := FLanding.Tick(FBelt.RampTravelLeft, Stands);
  if Cue.SlowsDown then
  begin
    Inc(FSeen.SlowsDown);
    FSeen.SlowTick := FTicks;
    FBelt.Run(0, LandingSlowTicks);
  end;
  if Cue.RoadIn then
  begin
    Inc(FSeen.RoadIn);
    FSeen.RoadLeft := Cue.RoadLeft;
    FSeen.RoadNow := Cue.RoadLeft;
  end;
  if Cue.Stands then
  begin
    Inc(FSeen.Stands);
    FSeen.StandTick := FTicks;
  end;
  if Cue.HandsOver then
  begin
    Inc(FSeen.HandsOver);
    FSeen.HandTick := FTicks;
  end;
end;

procedure TLandingTests.StepTicks(ACount: Integer);
begin
  for var i := 1 to ACount do
    Step;
end;

procedure TLandingTests.TestIdleItTellsNothing;
begin
  StepTicks(ManyTicks);
  Assert.IsFalse(FLanding.Running, 'Not running');
  Assert.AreEqual(0, FSeen.SlowsDown + FSeen.RoadIn + FSeen.Stands +
    FSeen.HandsOver, 'No cue');
  Assert.AreEqual(Double(BeltFlight), Double(FBelt.Speed), 0.0001,
    'The flight goes on');
end;

procedure TLandingTests.TestBegunItRunsTheFlightGoesOnThenSlowsOnce;
begin
  FLanding.Start;
  Assert.IsTrue(FLanding.Running, 'Running from the start');
  StepTicks(LandingSlowAfterTicks - 1);
  Assert.AreEqual(0, FSeen.SlowsDown, 'Not yet');
  Assert.AreEqual(Double(BeltFlight), Double(FBelt.Speed), 0.0001,
    'At the flight''s pace');
  StepTicks(ManyTicks);
  Assert.AreEqual(1, FSeen.SlowsDown, 'Once');
  Assert.AreEqual(LandingSlowAfterTicks, FSeen.SlowTick, 'When it is due');
  Assert.IsTrue(FLanding.Running, 'Running still');
end;

procedure TLandingTests.TestTheRoadComesInOnceFromBeyondTheRightEdge;
begin
  FLanding.Start;
  StepTicks(ManyTicks);
  Assert.AreEqual(1, FSeen.RoadIn, 'Once');
  Assert.IsTrue(FSeen.RoadLeft <= ScreenWidth + LandingRoadEnterGap,
    'No farther than the gap beyond the edge');
  Assert.IsTrue(FSeen.RoadLeft > ScreenWidth - BeltFlight,
    'From beyond the edge: not seen to pop up');
end;

procedure TLandingTests.TestTheRoadStopsABargesLengthFromTheLeftEdge;
begin
  FLanding.Start;
  StepTicks(ManyTicks);
  Assert.AreEqual(Double(BargeLength), FSeen.RoadNow, 0.01,
    'A barge docked against it is against the left edge');
  Assert.IsTrue(FSeen.RoadLeft - BargeLength > StationLeft + BargeLength,
    'It comes in right of the barge at its berth, to meet it on the way');
end;

procedure TLandingTests.TestItTellsOnceThatTheWorldStands;
begin
  FLanding.Start;
  StepTicks(ManyTicks);
  Assert.AreEqual(1, FSeen.Stands, 'Once');
  Assert.AreEqual(FSeen.SlowTick + LandingSlowTicks, FSeen.StandTick,
    'As the slowdown ends');
  Assert.AreEqual<TLandingStage>(lgStanding, FLanding.Stage, 'Standing');
end;

procedure TLandingTests.TestTheHandOverABreathAfterTheStand;
begin
  FLanding.Start;
  StepTicks(ManyTicks);
  Assert.AreEqual(1, FSeen.HandsOver, 'Once');
  Assert.AreEqual(FSeen.StandTick + LandingHandOverAfterTicks, FSeen.HandTick,
    'A breath after the stand');
  Assert.IsTrue(FLanding.HandedOver, 'Handed over');
end;

procedure TLandingTests.TestAStartWhileItRunsIsNothing;
begin
  FLanding.Start;
  StepTicks(LandingSlowAfterTicks - 10);
  FLanding.Start;
  StepTicks(10);
  Assert.AreEqual(1, FSeen.SlowsDown, 'The clock was not set back');
end;

procedure TLandingTests.TestAClearMakesItIdle;
begin
  FLanding.Start;
  StepTicks(ManyTicks);
  FLanding.Clear;
  Assert.IsFalse(FLanding.Running, 'Not running');
  Assert.AreEqual<TLandingStage>(lgIdle, FLanding.Stage, 'Idle');
  Assert.IsFalse(FLanding.HandedOver, 'Nothing handed over');
end;

initialization
  TDUnitX.RegisterTestFixture(TLandingTests);

end.
