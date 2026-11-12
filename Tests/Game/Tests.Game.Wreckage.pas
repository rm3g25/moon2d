{
  Tests.Game.Wreckage - what is left of the Ram's hull: nothing till it
  bursts. Burst, each part flies from its own place, as many as there
  were, out from the heart of the burst - those over it up first - then
  falling - slow,
  the moon's pull, still on the screen two seconds on - tumbling; the
  flight's wind takes them back toward the world's pace; between two
  ticks a piece lies between them; all are gone under the screen in the
  end. A new burst puts its pieces in place of the old; a clear empties
  the air; the same dice give the same flight.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Game.Wreckage;

interface

uses
  DUnitX.TestFramework,
  Sdl2.Core,
  Game.Wreckage;

type
  [TestFixture]
  TWreckageTests = class
  private
    FWreckage: TWreckage;
    // A hull cut Cols by Rows about AHeart, as the painter cuts it: no
    // pictures
    function Parts(const AHeart: TSdlFPoint): TArray<TWreckPart>;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestNothingTillItBursts;
    [Test]
    procedure TestEachPartFliesFromItsPlace;
    [Test]
    procedure TestOutFromTheHeart;
    [Test]
    procedure TestUpFirstThenFallingSlowly;
    [Test]
    procedure TestTheyTumble;
    [Test]
    procedure TestTheWindTakesThemBack;
    [Test]
    procedure TestBetweenTicksAPieceLiesBetweenThem;
    [Test]
    procedure TestAllGoneUnderTheScreenInTheEnd;
    [Test]
    procedure TestANewBurstReplacesTheOld;
    [Test]
    procedure TestAClearEmptiesTheAir;
    [Test]
    procedure TestSameDiceSameFlight;
  end;

implementation

uses
  System.SysUtils;

const
  Seed = 11;
  Cols = 3;
  Rows = 2;
  HullWidth = 169.0;
  HullHeight = 128.0;
  HeartX = 256.0;
  HeartY = 104.0;
  // The flight's wind at its pace
  FlightWind = 4.0;
  // Long enough for anything to fall under the screen
  ManyTicks = 1000;

function UnitAt(AX, AY: Single): TSdlFPoint;
begin
  Result.X := AX;
  Result.Y := AY;
end;

procedure TWreckageTests.Setup;
begin
  FWreckage := TWreckage.Create(Seed);
end;

procedure TWreckageTests.TearDown;
begin
  FWreckage.Free;
end;

function TWreckageTests.Parts(const AHeart: TSdlFPoint): TArray<TWreckPart>;
begin
  Result := nil;
  for var Row := 0 to Rows - 1 do
    for var Col := 0 to Cols - 1 do
    begin
      var Part := Default(TWreckPart);
      Part.Part.X := Col / Cols;
      Part.Part.Y := Row / Rows;
      Part.Part.W := 1 / Cols;
      Part.Part.H := 1 / Rows;
      Part.Width := HullWidth / Cols;
      Part.Height := HullHeight / Rows;
      Part.Middle := UnitAt(AHeart.X - HullWidth / 2 + (Col + 0.5) * Part.Width,
        AHeart.Y - HullHeight / 2 + (Row + 0.5) * Part.Height);
      Part.Spin := 3;
      Result := Result + [Part];
    end;
end;

procedure TWreckageTests.TestNothingTillItBursts;
begin
  FWreckage.Tick(FlightWind);
  Assert.AreEqual(0, FWreckage.Count, 'None');
  Assert.IsFalse(FWreckage.Falling, 'Nothing falls');
end;

procedure TWreckageTests.TestEachPartFliesFromItsPlace;
begin
  var Heart := UnitAt(HeartX, HeartY);
  var Given := Parts(Heart);
  FWreckage.Shatter(Given, Heart, UnitAt(0, 0));
  Assert.AreEqual(Length(Given), FWreckage.Count, 'As many as the parts');
  for var i := 0 to High(Given) do
  begin
    Assert.AreEqual(Double(Given[i].Middle.X), Double(FWreckage[i].Middle.X),
      0.001, 'From its place across');
    Assert.AreEqual(Double(Given[i].Middle.Y), Double(FWreckage[i].Middle.Y),
      0.001, 'From its place down');
    Assert.AreEqual(Double(Given[i].Spin), Double(FWreckage[i].Spin), 0.001,
      'Turned as the hull was');
  end;
  Assert.IsTrue(FWreckage.Falling, 'On the screen');
end;

procedure TWreckageTests.TestOutFromTheHeart;
const
  Ticks = 20;
begin
  var Heart := UnitAt(HeartX, HeartY);
  FWreckage.Shatter(Parts(Heart), Heart, UnitAt(0, 0));
  for var i := 1 to Ticks do
    FWreckage.Tick(0);
  // The left column went left, the right one right
  for var Row := 0 to Rows - 1 do
  begin
    var Left := FWreckage[Row * Cols];
    var Right := FWreckage[Row * Cols + Cols - 1];
    Assert.IsTrue(Left.Middle.X < Left.Shape.Middle.X, 'The left one left');
    Assert.IsTrue(Right.Middle.X > Right.Shape.Middle.X, 'The right one right');
  end;
end;

procedure TWreckageTests.TestUpFirstThenFallingSlowly;
const
  TwoSeconds = 66;
begin
  var Heart := UnitAt(HeartX, HeartY);
  FWreckage.Shatter(Parts(Heart), Heart, UnitAt(0, 0));
  FWreckage.Tick(0);
  // The top row: over the heart, out and up both
  for var i := 0 to Cols - 1 do
    Assert.IsTrue(FWreckage[i].Speed.Y < 0, 'Up first: piece ' + IntToStr(i));
  for var i := 2 to TwoSeconds do
    FWreckage.Tick(0);
  for var i := 0 to FWreckage.Count - 1 do
    Assert.IsFalse(FWreckage[i].Gone, 'On the screen two seconds on: piece ' +
      IntToStr(i));
  for var i := 1 to TwoSeconds do
    FWreckage.Tick(0);
  for var i := 0 to FWreckage.Count - 1 do
    Assert.IsTrue(FWreckage[i].Speed.Y > 0, 'Falling: piece ' + IntToStr(i));
end;

procedure TWreckageTests.TestTheyTumble;
begin
  var Heart := UnitAt(HeartX, HeartY);
  FWreckage.Shatter(Parts(Heart), Heart, UnitAt(0, 0));
  for var i := 1 to 10 do
    FWreckage.Tick(0);
  for var i := 0 to FWreckage.Count - 1 do
    Assert.IsTrue(Abs(FWreckage[i].Spin - FWreckage[i].Shape.Spin) > 1,
      'Turning: piece ' + IntToStr(i));
end;

procedure TWreckageTests.TestTheWindTakesThemBack;
const
  Ticks = 150;
begin
  var Heart := UnitAt(HeartX, HeartY);
  var Calm := TWreckage.Create(Seed);
  try
    FWreckage.Shatter(Parts(Heart), Heart, UnitAt(0, 0));
    Calm.Shatter(Parts(Heart), Heart, UnitAt(0, 0));
    for var i := 1 to Ticks do
    begin
      FWreckage.Tick(FlightWind);
      Calm.Tick(0);
    end;
    for var i := 0 to FWreckage.Count - 1 do
    begin
      Assert.IsTrue(FWreckage[i].Speed.X < Calm[i].Speed.X - 1,
        'Taken back: piece ' + IntToStr(i));
      Assert.IsTrue(FWreckage[i].Speed.X > -FlightWind,
        'Never faster than the world: piece ' + IntToStr(i));
    end;
  finally
    Calm.Free;
  end;
end;

procedure TWreckageTests.TestBetweenTicksAPieceLiesBetweenThem;
begin
  var Heart := UnitAt(HeartX, HeartY);
  FWreckage.Shatter(Parts(Heart), Heart, UnitAt(1, 0));
  FWreckage.Tick(FlightWind);
  var Before := FWreckage[0].Middle;
  FWreckage.Tick(FlightWind);
  var After := FWreckage[0].Middle;
  var Half := FWreckage.MiddleAt(0, 0.5);
  Assert.AreEqual(Double(Before.X + After.X) / 2, Double(Half.X), 0.001, 'Across');
  Assert.AreEqual(Double(Before.Y + After.Y) / 2, Double(Half.Y), 0.001, 'Down');
  var Spin := (FWreckage[0].LastSpin + FWreckage[0].Spin) / 2;
  Assert.AreEqual(Double(Spin), Double(FWreckage.SpinAt(0, 0.5)), 0.001, 'Turned');
end;

procedure TWreckageTests.TestAllGoneUnderTheScreenInTheEnd;
begin
  var Heart := UnitAt(HeartX, HeartY);
  FWreckage.Shatter(Parts(Heart), Heart, UnitAt(0, 0));
  var Ticks := 0;
  while FWreckage.Falling do
  begin
    FWreckage.Tick(FlightWind);
    Inc(Ticks);
    if Ticks > ManyTicks then
      Assert.Fail('Still falling');
  end;
  for var i := 0 to FWreckage.Count - 1 do
    Assert.IsTrue(FWreckage[i].Gone, 'Gone: piece ' + IntToStr(i));
end;

procedure TWreckageTests.TestANewBurstReplacesTheOld;
begin
  var Heart := UnitAt(HeartX, HeartY);
  FWreckage.Shatter(Parts(Heart), Heart, UnitAt(0, 0));
  var One := Parts(Heart);
  SetLength(One, 1);
  FWreckage.Shatter(One, Heart, UnitAt(0, 0));
  Assert.AreEqual(1, FWreckage.Count, 'Only the new one');
end;

procedure TWreckageTests.TestAClearEmptiesTheAir;
begin
  var Heart := UnitAt(HeartX, HeartY);
  FWreckage.Shatter(Parts(Heart), Heart, UnitAt(0, 0));
  FWreckage.Clear;
  Assert.AreEqual(0, FWreckage.Count, 'None');
  Assert.IsFalse(FWreckage.Falling, 'Nothing falls');
end;

procedure TWreckageTests.TestSameDiceSameFlight;
begin
  var Heart := UnitAt(HeartX, HeartY);
  var Other := TWreckage.Create(Seed);
  try
    FWreckage.Shatter(Parts(Heart), Heart, UnitAt(0, 0));
    Other.Shatter(Parts(Heart), Heart, UnitAt(0, 0));
    for var i := 1 to 30 do
    begin
      FWreckage.Tick(FlightWind);
      Other.Tick(FlightWind);
    end;
    for var i := 0 to FWreckage.Count - 1 do
    begin
      Assert.AreEqual(Double(Other[i].Middle.X), Double(FWreckage[i].Middle.X),
        0.0001, 'Across');
      Assert.AreEqual(Double(Other[i].Middle.Y), Double(FWreckage[i].Middle.Y),
        0.0001, 'Down');
    end;
  finally
    Other.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TWreckageTests);

end.
