{
  Tests.Game.Hoist - the way the orbs carry the hero at the throw: it
  starts where he was caught and ends at his place, where he stays; a
  short way takes the least time, a long one longer, at the pace on
  average; it is eased - slow, fast, slow; the middle of it is bowed over
  the straight line, the ends are not.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Game.Hoist;

interface

uses
  DUnitX.TestFramework,
  Sdl2.Core,
  Game.Hoist;

type
  [TestFixture]
  THoistPathTests = class
  public
    [Test]
    procedure TestItStartsWhereHeWasCaught;
    [Test]
    procedure TestItEndsAtHisPlaceAndStays;
    [Test]
    procedure TestAShortWayTakesTheLeastTime;
    [Test]
    procedure TestALongWayTakesLongerAtThePace;
    [Test]
    procedure TestSlowFastSlow;
    [Test]
    procedure TestTheMiddleIsBowedUp;
  end;

implementation

uses
  System.Math,
  System.SysUtils;

const
  Slop = 0.001;
  Road = 352.0;
  // A little over the road by the right edge
  Place: TSdlFPoint = (X: 432; Y: 344);

function At(AX, AY: Single): TSdlFPoint;
begin
  Result.X := AX;
  Result.Y := AY;
end;

procedure ExpectPoint(const AExpected, AActual: TSdlFPoint; const AWhat: string);
begin
  Assert.AreEqual(Double(AExpected.X), Double(AActual.X), Slop, AWhat + ': across');
  Assert.AreEqual(Double(AExpected.Y), Double(AActual.Y), Slop, AWhat + ': down');
end;

procedure THoistPathTests.TestItStartsWhereHeWasCaught;
begin
  var Path := PlanHoist(At(100, 200), Place);
  ExpectPoint(At(100, 200), Path.At(0), 'At the catch');
end;

procedure THoistPathTests.TestItEndsAtHisPlaceAndStays;
begin
  var Path := PlanHoist(At(100, 200), Place);
  ExpectPoint(Place, Path.At(Path.Ticks), 'At the end');
  ExpectPoint(Place, Path.At(Path.Ticks + 100), 'And on');
end;

procedure THoistPathTests.TestAShortWayTakesTheLeastTime;
begin
  var Path := PlanHoist(At(Place.X - 10, Road), Place);
  Assert.AreEqual(HoistLeastTicks, Path.Ticks);
end;

procedure THoistPathTests.TestALongWayTakesLongerAtThePace;
begin
  var From := At(20, 120);
  var Path := PlanHoist(From, Place);
  var Way := Hypot(Place.X - From.X, Place.Y - From.Y);
  Assert.AreEqual(Ceil(Way / HoistPace), Path.Ticks);
end;

procedure THoistPathTests.TestSlowFastSlow;
begin
  var Path := PlanHoist(At(20, Road), Place);
  var Steps: TArray<Single> := [];
  for var i := 1 to Path.Ticks do
    Steps := Steps + [Single(Path.At(i).X - Path.At(i - 1).X)];
  var Middle := Steps[Length(Steps) div 2];
  Assert.IsTrue(Steps[0] < Middle, 'Slow at first');
  Assert.IsTrue(Steps[High(Steps)] < Middle, 'Slow at the end');
end;

procedure THoistPathTests.TestTheMiddleIsBowedUp;
begin
  var From := At(100, Place.Y);
  var Path := PlanHoist(From, Place);
  var Middle := Path.At(Path.Ticks div 2);
  Assert.IsTrue(Middle.Y < Place.Y - HoistBow / 2, Format('At %.1f', [Middle.Y]));
  Assert.AreEqual(Double(Place.Y), Double(Path.At(1).Y), HoistBow / 4, 'Low at the start');
end;

initialization
  TDUnitX.RegisterTestFixture(THoistPathTests);

end.
