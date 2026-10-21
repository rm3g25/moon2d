{
  Tests.Pads.Flights - the flight a scene flies a single pad on
  (StraightFlight): one leg in front, from where the pad stands to where
  it is sent, its time stretched over the ticks the scene gives it. And
  the same leg shaped by an ease (EasedFlight): a rock thrown up out of
  the pit runs a little past its place and lands on it.

  The flights of a rebuild's plan are designed in the table of the unit
  and not written yet.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Pads.Flights;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPadFlightsTests = class
  public
    [Test]
    procedure TestStraightFlightGoesFromWhereItIsToWhereItIsSent;
    [Test]
    procedure TestStraightFlightKeepsToTheLine;
    [Test]
    procedure TestStraightFlightSetsOffAndStopsGently;
    [Test]
    procedure TestStraightFlightStaysInFront;
    [Test]
    procedure TestEasedFlightRunsPastItsPlaceAndLandsOnIt;
  end;

implementation

uses
  System.Math,
  System.SysUtils,
  Levels.Dynamics,
  Pads.Flights;

const
  // The pad of the cordon: from the hatch down to the dock
  FromX = 320.0;
  FromY = 118.0;
  ToX = 320.0;
  ToY = 256.0;
  // A slanted flight, both ways at once
  SlantToX = 224.0;
  SlantToY = 200.0;
  FlightTicks = 66;
  UnitSlack = 0.001;
  // A unit off the halfway point: the same rate both ways, as the pace says
  HalfwaySlack = 1.0;
  Afterwards = 50;
  // The same flight over its ticks and over twice as many
  StretchedTicks: array [0..1] of Integer = (FlightTicks, 2 * FlightTicks);

function DistanceTo(AX, AY, AToX, AToY: Double): Double;
begin
  Result := Hypot(AToX - AX, AToY - AY);
end;

procedure TPadFlightsTests.TestStraightFlightGoesFromWhereItIsToWhereItIsSent;
var
  X, Y: Double;
begin
  for var Ticks in StretchedTicks do
  begin
    var Flight := StraightFlight(FromX, FromY, ToX, ToY, Ticks, CalmPace);

    Flight.Place(0, X, Y);
    Assert.IsTrue(DistanceTo(X, Y, FromX, FromY) < UnitSlack,
      Format('%d ticks: at tick 0 it stands where it set off', [Ticks]));
    Flight.Place(Ticks - 1, X, Y);
    Assert.IsTrue(DistanceTo(X, Y, ToX, ToY) > UnitSlack,
      Format('%d ticks: a tick before the end it is still on the way',
      [Ticks]));
    for var Tick := Ticks to Ticks + Afterwards do
    begin
      Flight.Place(Tick, X, Y);
      Assert.IsTrue(DistanceTo(X, Y, ToX, ToY) < UnitSlack,
        Format('%d ticks: at tick %d it is not where it was sent',
        [Ticks, Tick]));
    end;
    Assert.AreEqual(Ticks, Flight.Arrive, 'It arrives on its last tick');
    Assert.AreEqual(Ticks, Flight.Done, 'And is done there');
  end;
end;

procedure TPadFlightsTests.TestStraightFlightKeepsToTheLine;
var
  X, Y: Double;
begin
  var Flight := StraightFlight(FromX, FromY, SlantToX, SlantToY, FlightTicks,
    CalmPace);
  var Span := DistanceTo(FromX, FromY, SlantToX, SlantToY);
  var LastLeft := Span;

  for var Tick := 0 to FlightTicks do
  begin
    Flight.Place(Tick, X, Y);
    var Gone := DistanceTo(FromX, FromY, X, Y);
    var Left := DistanceTo(X, Y, SlantToX, SlantToY);
    Assert.IsTrue(Abs(Gone + Left - Span) < UnitSlack,
      Format('Tick %d: off the line by %g', [Tick, Gone + Left - Span]));
    Assert.IsTrue(Left <= LastLeft + UnitSlack,
      Format('Tick %d: it turned back', [Tick]));
    LastLeft := Left;
  end;
end;

procedure TPadFlightsTests.TestStraightFlightSetsOffAndStopsGently;
var
  X, Y, LastX, LastY: Double;
begin
  var Flight := StraightFlight(FromX, FromY, ToX, ToY, FlightTicks, CalmPace);
  var Steps: TArray<Double>;
  Flight.Place(0, LastX, LastY);
  for var Tick := 1 to FlightTicks do
  begin
    Flight.Place(Tick, X, Y);
    Steps := Steps + [DistanceTo(LastX, LastY, X, Y)];
    LastX := X;
    LastY := Y;
  end;

  var Largest := MaxValue(Steps);
  var Mean := DistanceTo(FromX, FromY, ToX, ToY) / FlightTicks;
  Assert.IsTrue(Steps[0] < Mean, 'The first step is under the mean');
  Assert.IsTrue(Steps[High(Steps)] < Mean, 'The last step is under the mean');
  Assert.IsTrue(Steps[0] < Largest, 'It speeds up from the first step');
  Assert.IsTrue(Steps[High(Steps)] < Largest, 'It brakes onto the last');
  Flight.Place(FlightTicks div 2, X, Y);
  Assert.IsTrue(Abs(Y - (FromY + ToY) / 2) < HalfwaySlack,
    Format('Halfway in time it is at %g, not halfway', [Y]));
end;

procedure TPadFlightsTests.TestStraightFlightStaysInFront;
begin
  var Flight := StraightFlight(FromX, FromY, SlantToX, SlantToY, FlightTicks,
    CalmPace);

  Assert.IsFalse(Flight.Deep, 'Not into the depth');
  Assert.IsFalse(Flight.Idle, 'It has somewhere to go');
  Assert.AreEqual(0, Flight.Depart, 'It sets off at once');
  for var Tick := 0 to FlightTicks + Afterwards do
  begin
    Assert.IsFalse(Flight.Behind(Tick),
      Format('Tick %d: behind the others', [Tick]));
    Assert.IsFalse(Flight.TurnsCorner(Tick),
      Format('Tick %d: a corner on a single leg', [Tick]));
    Assert.IsTrue(Flight.Depth(Tick) = 0,
      Format('Tick %d: gone into the depth', [Tick]));
  end;
end;

procedure TPadFlightsTests.TestEasedFlightRunsPastItsPlaceAndLandsOnIt;
const
  // The step of screen 11: from under the bottom edge up to row 8
  PitY = 384.0;
  StepY = 256.0;
  // A few percent of the way past it, not a bounce
  MostPast = 8.0;
var
  X, Y: Double;
begin
  var Flight := EasedFlight(FromX, PitY, FromX, StepY, FlightTicks, meBack);
  var Highest := PitY;
  for var Tick := 0 to FlightTicks do
  begin
    Flight.Place(Tick, X, Y);
    Highest := Min(Highest, Y);
  end;

  Assert.IsTrue(Highest < StepY, Format('It runs past its place: %g', [Highest]));
  Assert.IsTrue(StepY - Highest < MostPast,
    Format('A little past, not a bounce: %g', [Highest]));
  Flight.Place(FlightTicks, X, Y);
  Assert.IsTrue(Abs(Y - StepY) < UnitSlack, 'It lands on its place');
  Flight.Place(FlightTicks + Afterwards, X, Y);
  Assert.IsTrue(Abs(Y - StepY) < UnitSlack, 'and stays');
  Assert.IsTrue(Abs(X - FromX) < UnitSlack, 'straight up, never aside');
end;

initialization
  TDUnitX.RegisterTestFixture(TPadFlightsTests);

end.
