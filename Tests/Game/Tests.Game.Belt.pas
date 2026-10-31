{
  Tests.Game.Belt - the treadmill of the chase: it stands until started;
  it comes up to cruise in its ramp and runs down to a standstill in one,
  with no jerk either way, even when a stop comes in the middle of the
  climb; a second start changes nothing; what it has run is the sum of
  its speeds, and between two ticks it lies between them; a clear stands
  it and forgets the way. The road's picture on it wraps round the screen.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Game.Belt;

interface

uses
  DUnitX.TestFramework,
  Game.Belt;

type
  [TestFixture]
  TBeltTests = class
  private
    FBelt: TBelt;
    // The speeds of ATicks ticks
    function Run(ATicks: Integer): TArray<Single>;
    // The biggest change of the speed from one tick to the next
    function SteepestStep(const ASpeeds: TArray<Single>; AFrom: Single): Single;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestStandsBeforeTheStart;
    [Test]
    procedure TestReachesCruiseInItsRamp;
    [Test]
    procedure TestRunsDownToAStandstill;
    [Test]
    procedure TestNoJerkUpOrDown;
    [Test]
    procedure TestAStopInTheClimbIsSmooth;
    [Test]
    procedure TestASecondStartChangesNothing;
    [Test]
    procedure TestTravelIsTheSumOfTheSpeeds;
    [Test]
    procedure TestTravelBetweenTicksLiesBetweenThem;
    [Test]
    procedure TestClearStandsAndForgets;
  end;

  [TestFixture]
  TBeltRoadTests = class
  public
    [Test]
    procedure TestStandsWhereItIsBeforeTheRun;
    [Test]
    procedure TestGoesLeftAsTheRoadRuns;
    [Test]
    procedure TestOffTheLeftComesInOnTheRight;
    [Test]
    procedure TestAWholeSpanBringsItBack;
  end;

implementation

uses
  System.Math,
  Render.Objects;

const
  // Long enough for a ramp to be over
  PastTheRamp = BeltRampTicks + 10;
  // The steepest a smooth step over the ramp climbs a tick, with room for
  // the rounding of Single
  MostStep = 1.5 * BeltCruise / BeltRampTicks + 0.001;
  ScreenSpan = 512.0;

procedure TBeltTests.Setup;
begin
  FBelt := TBelt.Create;
end;

procedure TBeltTests.TearDown;
begin
  FBelt.Free;
end;

function TBeltTests.Run(ATicks: Integer): TArray<Single>;
begin
  SetLength(Result, ATicks);
  for var i := 0 to ATicks - 1 do
  begin
    FBelt.Tick;
    Result[i] := FBelt.Speed;
  end;
end;

function TBeltTests.SteepestStep(const ASpeeds: TArray<Single>;
  AFrom: Single): Single;
begin
  Result := 0;
  var Last := AFrom;
  for var Speed in ASpeeds do
  begin
    Result := Max(Result, Abs(Speed - Last));
    Last := Speed;
  end;
end;

procedure TBeltTests.TestStandsBeforeTheStart;
begin
  Run(PastTheRamp);
  Assert.AreEqual(0.0, Double(FBelt.Speed), 0.0001, 'No speed');
  Assert.AreEqual(0.0, FBelt.Travel, 0.0001, 'Nothing run');
  Assert.IsFalse(FBelt.Running, 'Not running');
end;

procedure TBeltTests.TestReachesCruiseInItsRamp;
begin
  FBelt.Start;
  Assert.IsTrue(FBelt.Running, 'Running from the start');
  var Speeds := Run(BeltRampTicks);
  Assert.IsTrue(Speeds[BeltRampTicks div 2] < BeltCruise,
    'Short of cruise halfway up');
  Assert.AreEqual(Double(BeltCruise), Double(FBelt.Speed), 0.0001,
    'At cruise when the ramp is over');
  Run(10);
  Assert.AreEqual(Double(BeltCruise), Double(FBelt.Speed), 0.0001,
    'And stays at it');
end;

procedure TBeltTests.TestRunsDownToAStandstill;
begin
  FBelt.Start;
  Run(PastTheRamp);
  FBelt.Stop;
  Assert.IsTrue(FBelt.Running, 'Still running as it runs down');
  Run(BeltRampTicks);
  Assert.AreEqual(0.0, Double(FBelt.Speed), 0.0001, 'At a standstill');
  Assert.IsFalse(FBelt.Running, 'Not running');
  var Stood := FBelt.Travel;
  Run(10);
  Assert.AreEqual(Stood, FBelt.Travel, 0.0001, 'Runs no farther');
end;

procedure TBeltTests.TestNoJerkUpOrDown;
begin
  FBelt.Start;
  var Up := Run(PastTheRamp);
  Assert.IsTrue(SteepestStep(Up, 0) <= MostStep, 'No jerk up');
  FBelt.Stop;
  var Down := Run(PastTheRamp);
  Assert.IsTrue(SteepestStep(Down, BeltCruise) <= MostStep, 'No jerk down');
end;

procedure TBeltTests.TestAStopInTheClimbIsSmooth;
const
  ClimbTicks = 20;
begin
  FBelt.Start;
  Run(ClimbTicks);
  var Reached := FBelt.Speed;
  Assert.IsTrue((Reached > 0) and (Reached < BeltCruise), 'Halfway up');
  FBelt.Stop;
  var Down := Run(PastTheRamp);
  Assert.IsTrue(SteepestStep(Down, Reached) <= MostStep,
    'Down from where it was, with no jerk');
  Assert.AreEqual(0.0, Double(FBelt.Speed), 0.0001, 'At a standstill');
end;

procedure TBeltTests.TestASecondStartChangesNothing;
begin
  FBelt.Start;
  Run(PastTheRamp);
  FBelt.Start;
  var Speeds := Run(10);
  for var Speed in Speeds do
    Assert.AreEqual(Double(BeltCruise), Double(Speed), 0.0001,
      'Cruise runs on');
end;

procedure TBeltTests.TestTravelIsTheSumOfTheSpeeds;
begin
  FBelt.Start;
  var Sum: Double := 0;
  for var Speed in Run(PastTheRamp) do
    Sum := Sum + Speed;
  Assert.AreEqual(Sum, FBelt.Travel, 0.001);
end;

procedure TBeltTests.TestTravelBetweenTicksLiesBetweenThem;
begin
  FBelt.Start;
  Run(PastTheRamp);
  var Before := FBelt.Travel;
  FBelt.Tick;
  var After := FBelt.Travel;
  Assert.AreEqual(Before, FBelt.TravelAt(0), 0.0001, 'The last tick');
  Assert.AreEqual(After, FBelt.TravelAt(1), 0.0001, 'This tick');
  Assert.AreEqual((Before + After) / 2, FBelt.TravelAt(0.5), 0.0001,
    'Halfway');
end;

procedure TBeltTests.TestClearStandsAndForgets;
begin
  FBelt.Start;
  Run(PastTheRamp);
  FBelt.Clear;
  Assert.AreEqual(0.0, Double(FBelt.Speed), 0.0001, 'No speed');
  Assert.AreEqual(0.0, FBelt.Travel, 0.0001, 'Nothing run');
  Assert.AreEqual(0.0, FBelt.TravelAt(0.5), 0.0001, 'Nowhere between ticks');
  Assert.IsFalse(FBelt.Running, 'Not running');
  Run(10);
  Assert.AreEqual(0.0, Double(FBelt.Speed), 0.0001, 'Stays standing');
end;

procedure TBeltRoadTests.TestStandsWhereItIsBeforeTheRun;
begin
  Assert.AreEqual(96.0, BeltX(96, 0, ScreenSpan), 0.0001);
end;

procedure TBeltRoadTests.TestGoesLeftAsTheRoadRuns;
begin
  Assert.AreEqual(85.5, BeltX(96, 10.5, ScreenSpan), 0.0001);
end;

procedure TBeltRoadTests.TestOffTheLeftComesInOnTheRight;
begin
  Assert.AreEqual(502.0, BeltX(0, 10, ScreenSpan), 0.0001);
end;

procedure TBeltRoadTests.TestAWholeSpanBringsItBack;
begin
  Assert.AreEqual(96.0, BeltX(96, 3 * ScreenSpan, ScreenSpan), 0.001);
end;

initialization
  TDUnitX.RegisterTestFixture(TBeltTests);
  TDUnitX.RegisterTestFixture(TBeltRoadTests);

end.
