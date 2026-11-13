{
  Tests.Game.Gate - the facade with the gate on the road come back: sealed,
  its lamp is red and stays red; promised, it turns amber over its ticks
  and stops there; a second promise does not start the turn again; a turn
  between the ticks lies between them; a clear seals it again at once. The
  facade ends at the right edge of the screen once the road stands at its
  stop, starts beyond the edge as the road comes in, and rides with the
  road. The lamp's color goes from red to amber.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Game.Gate;

interface

uses
  DUnitX.TestFramework,
  Game.Gate;

type
  [TestFixture]
  TGateTests = class
  private
    FGate: TGate;
    procedure Run(ATicks: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestSealedTheLampStaysRed;
    [Test]
    procedure TestPromisedTheLampTurnsAmberOverItsTicks;
    [Test]
    procedure TestTheTurnStopsAtAmber;
    [Test]
    procedure TestASecondPromiseDoesNotStartTheTurnAgain;
    [Test]
    procedure TestATurnBetweenTicksLiesBetweenThem;
    [Test]
    procedure TestClearSealsItAgainAtOnce;
    [Test]
    procedure TestTheFacadeEndsAtTheRightEdgeOnceTheRoadStands;
    [Test]
    procedure TestTheFacadeComesInAfterTheRoadAndRidesWithIt;
    [Test]
    procedure TestTheLampColorGoesFromRedToAmber;
  end;

implementation

uses
  Render.Brush, Game.Space, Game.Road, Game.Landing;

const
  TurnSlack = 0.0001;
  UnitSlack = 0.001;

procedure TGateTests.Setup;
begin
  FGate := TGate.Create;
end;

procedure TGateTests.TearDown;
begin
  FGate.Free;
end;

procedure TGateTests.Run(ATicks: Integer);
begin
  for var i := 1 to ATicks do
    FGate.Tick;
end;

procedure TGateTests.TestSealedTheLampStaysRed;
begin
  Assert.AreEqual<TGateLamp>(glSealed, FGate.Lamp, 'Sealed');
  Run(GateLampTurnTicks * 2);
  Assert.AreEqual<TGateLamp>(glSealed, FGate.Lamp, 'Still sealed');
  Assert.AreEqual(0.0, Double(FGate.LampTurn(1)), TurnSlack, 'Red');
end;

procedure TGateTests.TestPromisedTheLampTurnsAmberOverItsTicks;
begin
  FGate.Promise;
  Assert.AreEqual<TGateLamp>(glSoon, FGate.Lamp, 'Promised');
  Assert.AreEqual(0.0, Double(FGate.LampTurn(1)), TurnSlack, 'Red till the next tick');
  Run(GateLampTurnTicks div 2);
  Assert.AreEqual(0.5, Double(FGate.LampTurn(1)), TurnSlack, 'Halfway');
  Run(GateLampTurnTicks div 2);
  Assert.AreEqual(1.0, Double(FGate.LampTurn(1)), TurnSlack, 'Amber');
end;

procedure TGateTests.TestTheTurnStopsAtAmber;
begin
  FGate.Promise;
  Run(GateLampTurnTicks * 3);
  Assert.AreEqual(1.0, Double(FGate.LampTurn(1)), TurnSlack, 'No farther than amber');
  Assert.AreEqual(1.0, Double(FGate.LampTurn(0)), TurnSlack, 'And at rest there');
end;

procedure TGateTests.TestASecondPromiseDoesNotStartTheTurnAgain;
begin
  FGate.Promise;
  Run(GateLampTurnTicks div 2);
  FGate.Promise;
  Assert.AreEqual(0.5, Double(FGate.LampTurn(1)), TurnSlack, 'Where it was');
  Run(GateLampTurnTicks div 2);
  Assert.AreEqual(1.0, Double(FGate.LampTurn(1)), TurnSlack, 'Amber in its own time');
end;

procedure TGateTests.TestATurnBetweenTicksLiesBetweenThem;
const
  Step = 1 / GateLampTurnTicks;
begin
  FGate.Promise;
  Run(3);
  Assert.AreEqual(2 * Step, Double(FGate.LampTurn(0)), TurnSlack, 'The last tick');
  Assert.AreEqual(3 * Step, Double(FGate.LampTurn(1)), TurnSlack, 'This tick');
  Assert.AreEqual(2.5 * Step, Double(FGate.LampTurn(0.5)), TurnSlack, 'Halfway');
end;

procedure TGateTests.TestClearSealsItAgainAtOnce;
begin
  FGate.Promise;
  Run(GateLampTurnTicks);

  FGate.Clear;

  Assert.AreEqual<TGateLamp>(glSealed, FGate.Lamp, 'Sealed');
  Assert.AreEqual(0.0, Double(FGate.LampTurn(0)), TurnSlack, 'Red, not turning back');
  Assert.AreEqual(0.0, Double(FGate.LampTurn(1)), TurnSlack, 'Red');
  Run(GateLampTurnTicks);
  Assert.AreEqual(0.0, Double(FGate.LampTurn(1)), TurnSlack, 'And stays red');
end;

procedure TGateTests.TestTheFacadeEndsAtTheRightEdgeOnceTheRoadStands;
const
  // Where the stand has it: clear of the logo's place, which ends at 376
  StandLeft: Double = 392.0;
begin
  var Left := GateLeft(LandingRoadStop);
  Assert.AreEqual(StandLeft, Left, UnitSlack, 'Its left side');
  Assert.AreEqual(Double(ScreenWidth), Left + GateWidth, UnitSlack,
    'Its right side at the right edge');
end;

procedure TGateTests.TestTheFacadeComesInAfterTheRoadAndRidesWithIt;
const
  Way: Double = -2.0;
  Ticks = 30;
begin
  var Road := TRoadEnd.Create;
  try
    Road.Arrive(ScreenWidth + LandingRoadEnterGap);
    var Before := GateLeft(Road.PierLeft);
    Assert.IsTrue(Before > ScreenWidth, 'Beyond the right edge as the road comes in');
    for var i := 1 to Ticks do
      Road.Tick(Way);
    Assert.AreEqual(Before + Ticks * Way, GateLeft(Road.PierLeft), UnitSlack,
      'Riding with the road');
    Assert.AreEqual(GateLeft(Road.PierLeft) - Way / 2,
      GateLeft(Road.LeftAt(0.5)), UnitSlack, 'And between the ticks');
  finally
    Road.Free;
  end;
end;

procedure TGateTests.TestTheLampColorGoesFromRedToAmber;
begin
  var Red := GateLampColor(0);
  var Amber := GateLampColor(1);
  var Halfway := GateLampColor(0.5);
  Assert.IsTrue(Red.G < Halfway.G, 'Warmer halfway');
  Assert.IsTrue(Halfway.G < Amber.G, 'Warmest at amber');
  Assert.AreEqual(Integer(Red.R), Integer(Amber.R), 'The red of it stays');
  Assert.IsTrue(Amber.B < Amber.G, 'Amber, not white');
end;

initialization
  TDUnitX.RegisterTestFixture(TGateTests);

end.
