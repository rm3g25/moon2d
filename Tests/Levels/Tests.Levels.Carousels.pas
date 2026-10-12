{
  Tests.Levels.Carousels - the track of a carousel, the way a pad goes
  round it, and the carousels section of level JSON.

  The track starts on the right of its middle and runs clockwise on the
  screen - down from there - at one even pace; a pad is a share of the
  lap ahead of the one before it in file order, and a lap takes the
  carousel's period. The track and the orbit keep no state, so the tests
  ask them about any distance and any tick, in any order. The section is
  parsed from a JSON root made in the test; what the level makes of it at
  load is tried in Tests.Levels.Pads.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Levels.Carousels;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TCarouselTrackTests = class
  public
    [Test]
    procedure TestOvalStartsRightOfItsMiddleAndGoesDown;
    [Test]
    procedure TestOvalLiesOnItsCurve;
    [Test]
    procedure TestOvalIsWalkedAtAnEvenPace;
    [Test]
    procedure TestBoxGoesDownItsRightSideFirst;
    [Test]
    procedure TestRoundedBoxCutsItsCornersAndKeepsItsSides;
    [Test]
    procedure TestBoxRoundedAllTheWayIsACircle;
    [Test]
    procedure TestPlaceWrapsPastALapAndBelowZero;
  end;

  [TestFixture]
  TCarouselOrbitTests = class
  public
    [Test]
    procedure TestOrbitOfNoCarouselDoesNotRide;
    [Test]
    procedure TestFirstPadStartsAtItsShareOfTheLap;
    [Test]
    procedure TestPadsShareTheLapInFileOrder;
    [Test]
    procedure TestLapTakesThePeriod;
    [Test]
    procedure TestPadMovesBetweenTicksToo;
    [Test]
    procedure TestCounterClockwiseMirrorsClockwise;
  end;

  [TestFixture]
  TLevelsCarouselsTests = class
  public
    [Test]
    procedure TestNoSectionIsNoCarousels;
    [Test]
    procedure TestCarouselReadsWhatItIsGiven;
    [Test]
    procedure TestCarouselLeftOutComesToItsDefaults;
    [Test]
    procedure TestWordsAreReadInAnyCase;
    [Test]
    procedure TestBadCarouselRaises;
    [Test]
    procedure TestCarouselIsFoundByItsTag;
    [Test]
    procedure TestLapIsATickAtTheLeast;
  end;

implementation

uses
  System.JSON,
  System.Math,
  System.SysUtils,
  Levels.Carousels,
  Levels.Pads;

const
  // The world ticks 33 times a second
  TicksPerSecond = 33;
  // The middle of the circle of the orbit tests and its radius
  CircleX = 256;
  CircleY = 160;
  CircleRadius = 80;
  // The circle goes round in 4 seconds: 132 ticks, a quarter in 33
  CirclePeriod = 4;
  CircleLapTicks = CirclePeriod * TicksPerSecond;
  QuarterTicks = CircleLapTicks div 4;
  // The points of the track are Single: a place is compared within this
  PlaceSlack = 0.01;

// ---------------------------------------------------------------------------
// Shared
// ---------------------------------------------------------------------------

function CarouselOf(AShape: TCarouselShape; ACenterX, ACenterY, AWidth,
  AHeight: Single; ACorner: Single = 0): TCarousel;
begin
  Result := Default(TCarousel);
  Result.Tag := 'wheel';
  Result.Screen := 1;
  Result.Shape := AShape;
  Result.CenterX := ACenterX;
  Result.CenterY := ACenterY;
  Result.Width := AWidth;
  Result.Height := AHeight;
  Result.Corner := ACorner;
  Result.Period := CirclePeriod;
  Result.Turn := ctClockwise;
  Result.Start := 0;
end;

// The circle of the orbit tests, turning AWay, its first pad at AStart
function CircleOf(AWay: TCarouselTurn = ctClockwise;
  AStart: Single = 0): TCarousel;
begin
  Result := CarouselOf(csOval, CircleX, CircleY, 2 * CircleRadius,
    2 * CircleRadius);
  Result.Turn := AWay;
  Result.Start := AStart;
end;

function TrackOf(const ACarousel: TCarousel): TCarouselTrack;
begin
  Result := Default(TCarouselTrack);
  Result.Build(ACarousel);
end;

function OrbitOfSlot(const ACarousel: TCarousel; ASlot,
  ASlots: Integer): TCarouselOrbit;
begin
  Result := Default(TCarouselOrbit);
  Result.Build(ACarousel, ASlot, ASlots);
end;

function IsNear(AValue, AExpected: Double): Boolean;
begin
  Result := Abs(AValue - AExpected) < PlaceSlack;
end;

procedure ExpectPoint(AX, AY, AExpectedX, AExpectedY: Double;
  const AWhat: string; ASlack: Double = PlaceSlack);
begin
  Assert.IsTrue((Abs(AX - AExpectedX) < ASlack) and
    (Abs(AY - AExpectedY) < ASlack), Format('%s: at (%g, %g), not (%g, %g)',
    [AWhat, AX, AY, AExpectedX, AExpectedY]));
end;

procedure ExpectTrackAt(const ATrack: TCarouselTrack; ADistance, AExpectedX,
  AExpectedY: Double; const AWhat: string);
var
  X, Y: Double;
begin
  ATrack.PointAt(ADistance, X, Y);
  ExpectPoint(X, Y, AExpectedX, AExpectedY, AWhat);
end;

procedure ExpectOrbitAt(const AOrbit: TCarouselOrbit; ATime: Double;
  AExpectedX, AExpectedY: Double; const AWhat: string);
var
  X, Y: Double;
begin
  AOrbit.Place(ATime, X, Y);
  ExpectPoint(X, Y, AExpectedX, AExpectedY, AWhat);
end;

function DistanceBetween(const AOrbit: TCarouselOrbit;
  AFrom, ATo: Double): Double;
var
  FromX, FromY, ToX, ToY: Double;
begin
  AOrbit.Place(AFrom, FromX, FromY);
  AOrbit.Place(ATo, ToX, ToY);
  Result := Hypot(ToX - FromX, ToY - FromY);
end;

function PadOn(const ACarousel: string): TPadPlacement;
begin
  Result := Default(TPadPlacement);
  Result.Sprite := 's16-platform';
  Result.Screen := 1;
  Result.Width := 32;
  Result.Carousel := ACarousel;
end;

// ---------------------------------------------------------------------------
// TCarouselTrackTests
// ---------------------------------------------------------------------------

// An oval 200 across and 100 down: a quarter of the way round from the
// right of its middle it is at the bottom, not at the top
procedure TCarouselTrackTests.TestOvalStartsRightOfItsMiddleAndGoesDown;
begin
  var Track := TrackOf(CarouselOf(csOval, 256, 192, 200, 100));
  ExpectTrackAt(Track, 0, 356, 192, 'The start');
  ExpectTrackAt(Track, Track.Length / 4, 256, 242, 'A quarter round');
  ExpectTrackAt(Track, Track.Length / 2, 156, 192, 'Half round');
  ExpectTrackAt(Track, 3 * Track.Length / 4, 256, 142, 'Three quarters round');
end;

// Every point is on the ellipse of the size, and the track is as long as
// the ellipse within a hair
procedure TCarouselTrackTests.TestOvalLiesOnItsCurve;
const
  HalfAcross = 100;
  HalfDown = 50;
  Samples = 100;
var
  X, Y: Double;
begin
  var Track := TrackOf(CarouselOf(csOval, 256, 192, 2 * HalfAcross,
    2 * HalfDown));
  for var i := 0 to Samples - 1 do
  begin
    Track.PointAt(Track.Length * i / Samples, X, Y);
    var OnCurve := Sqr((X - 256) / HalfAcross) + Sqr((Y - 192) / HalfDown);
    Assert.IsTrue(Abs(OnCurve - 1) < 0.001, Format('At (%g, %g) the oval is ' +
      'off its curve by %g', [X, Y, OnCurve - 1]));
  end;

  // Ramanujan's length of the ellipse
  var Ratio := Sqr((HalfAcross - HalfDown) / (HalfAcross + HalfDown));
  var Perimeter := Pi * (HalfAcross + HalfDown) *
    (1 + 3 * Ratio / (10 + Sqrt(4 - 3 * Ratio)));
  Assert.IsTrue(Abs(Track.Length - Perimeter) < Perimeter * 0.001,
    Format('The oval is %g long, its curve %g', [Track.Length, Perimeter]));
end;

// Equal steps along the track are equal steps on the screen: an oval is
// not walked by its angle, which would bunch the pads at its ends
procedure TCarouselTrackTests.TestOvalIsWalkedAtAnEvenPace;
const
  Steps = 40;
var
  FromX, FromY, ToX, ToY: Double;
begin
  var Track := TrackOf(CarouselOf(csOval, 256, 192, 200, 100));
  var Shortest: Double := MaxDouble;
  var Longest: Double := 0;
  for var i := 0 to Steps - 1 do
  begin
    Track.PointAt(Track.Length * i / Steps, FromX, FromY);
    Track.PointAt(Track.Length * (i + 1) / Steps, ToX, ToY);
    var Step := Hypot(ToX - FromX, ToY - FromY);
    Shortest := Min(Shortest, Step);
    Longest := Max(Longest, Step);
  end;
  Assert.IsTrue(Longest / Shortest < 1.02, Format('Steps of one length ' +
    'cover %g to %g units', [Shortest, Longest]));
end;

// A box 200 across and 100 down with sharp corners is 600 long: down to
// the bottom right corner, left along the bottom, up the left side,
// right along the top and down to the start
procedure TCarouselTrackTests.TestBoxGoesDownItsRightSideFirst;
begin
  var Track := TrackOf(CarouselOf(csBox, 256, 192, 200, 100));
  Assert.IsTrue(Abs(Track.Length - 600) < PlaceSlack,
    Format('The box is %g long', [Track.Length]));
  ExpectTrackAt(Track, 0, 356, 192, 'The start');
  ExpectTrackAt(Track, 50, 356, 242, 'The bottom right corner');
  ExpectTrackAt(Track, 150, 256, 242, 'The middle of the bottom');
  ExpectTrackAt(Track, 250, 156, 242, 'The bottom left corner');
  ExpectTrackAt(Track, 350, 156, 142, 'The top left corner');
  ExpectTrackAt(Track, 450, 256, 142, 'The middle of the top');
  ExpectTrackAt(Track, 575, 356, 167, 'On the way back down');
end;

// Corners of 20: the track still touches every side of the box, never
// leaves it, keeps away from its corners, and is shorter than the sharp
// box by about what a circle saves over its square (8 - 2 Pi) * 20
procedure TCarouselTrackTests.TestRoundedBoxCutsItsCornersAndKeepsItsSides;
const
  Corner = 20;
  Samples = 2000;
  Corners: array [0 .. 3, 0 .. 1] of Double =
    ((356, 242), (156, 242), (156, 142), (356, 142));
var
  X, Y: Double;
begin
  var Track := TrackOf(CarouselOf(csBox, 256, 192, 200, 100, Corner));
  var Saved := 600 - Track.Length;
  Assert.IsTrue(Abs(Saved - (8 - 2 * Pi) * Corner) < 0.5,
    Format('The corners save %g units', [Saved]));

  var Left: Double := MaxDouble;
  var Right: Double := -MaxDouble;
  var Top: Double := MaxDouble;
  var Bottom: Double := -MaxDouble;
  var NearestCorner: Double := MaxDouble;
  for var i := 0 to Samples - 1 do
  begin
    Track.PointAt(Track.Length * i / Samples, X, Y);
    Left := Min(Left, X);
    Right := Max(Right, X);
    Top := Min(Top, Y);
    Bottom := Max(Bottom, Y);
    for var c := 0 to 3 do
      NearestCorner := Min(NearestCorner,
        Hypot(X - Corners[c, 0], Y - Corners[c, 1]));
  end;
  ExpectPoint(Left, Top, 156, 142, 'The left and the top it reaches');
  ExpectPoint(Right, Bottom, 356, 242, 'The right and the bottom it reaches');
  // A quarter of a circle of 20 passes 20 * (Sqrt(2) - 1), 8.3, from the
  // corner of its square
  Assert.IsTrue(NearestCorner > 7, Format('The track comes %g units near ' +
    'a corner', [NearestCorner]));
end;

// A square 100 a side with corners of 50 has sides of no length: it is a
// circle, and the legs of no length between its quarters do not break it
procedure TCarouselTrackTests.TestBoxRoundedAllTheWayIsACircle;
const
  Samples = 1000;
var
  X, Y: Double;
begin
  var Track := TrackOf(CarouselOf(csBox, 256, 192, 100, 100, 50));
  for var i := 0 to Samples - 1 do
  begin
    Track.PointAt(Track.Length * i / Samples, X, Y);
    var Radius := Hypot(X - 256, Y - 192);
    Assert.IsTrue(Abs(Radius - 50) < 0.5, Format('At (%g, %g) the circle ' +
      'is %g from its middle', [X, Y, Radius]));
  end;
  ExpectTrackAt(Track, 0, 306, 192, 'The start');
  ExpectTrackAt(Track, Track.Length / 4, 256, 242, 'A quarter round');
end;

// The track is closed: any distance past a lap, or below zero, is the
// same as that distance folded into the lap
procedure TCarouselTrackTests.TestPlaceWrapsPastALapAndBelowZero;
const
  Distances: array [0 .. 4] of Double = (0, 0.3, 37.5, 123.25, 299.9);
  LapsOn: array [0 .. 3] of Integer = (-3, -1, 1, 5);
var
  X, Y: Double;
begin
  var Track := TrackOf(CarouselOf(csBox, 256, 192, 200, 100, 10));
  for var Distance in Distances do
  begin
    Track.PointAt(Distance, X, Y);
    for var Laps in LapsOn do
      ExpectTrackAt(Track, Distance + Laps * Track.Length, X, Y,
        Format('%g units %d laps on', [Distance, Laps]));
  end;
  // Below zero is the end of the lap, not its start
  ExpectTrackAt(Track, -25, 356, 167, 'Twenty-five units back from the start');
end;

// ---------------------------------------------------------------------------
// TCarouselOrbitTests
// ---------------------------------------------------------------------------

procedure TCarouselOrbitTests.TestOrbitOfNoCarouselDoesNotRide;
begin
  var Nothing := Default(TCarouselOrbit);
  Assert.IsFalse(Nothing.Rides, 'An orbit made of nothing');

  var Carousels: TArray<TCarousel> := [CircleOf];
  var Pads: TArray<TPadPlacement> := [PadOn(''), PadOn('nowhere'),
    PadOn('wheel')];
  Assert.IsFalse(OrbitOf(Carousels, Pads, 0).Rides, 'A pad on no carousel');
  Assert.IsFalse(OrbitOf(Carousels, Pads, 1).Rides,
    'A pad on a carousel the level does not have');
  Assert.IsTrue(OrbitOf(Carousels, Pads, 2).Rides, 'A pad on the carousel');
end;

// The start is a share of the lap the way the carousel turns: a quarter
// clockwise is the bottom, a quarter counter-clockwise the top
procedure TCarouselOrbitTests.TestFirstPadStartsAtItsShareOfTheLap;
begin
  ExpectOrbitAt(OrbitOfSlot(CircleOf, 0, 1), 0, CircleX + CircleRadius,
    CircleY, 'Start 0');
  ExpectOrbitAt(OrbitOfSlot(CircleOf(ctClockwise, 0.25), 0, 1), 0, CircleX,
    CircleY + CircleRadius, 'Start 0.25 clockwise');
  ExpectOrbitAt(OrbitOfSlot(CircleOf(ctClockwise, 0.75), 0, 1), 0, CircleX,
    CircleY - CircleRadius, 'Start 0.75 clockwise');
  ExpectOrbitAt(OrbitOfSlot(CircleOf(ctCounterClockwise, 0.25), 0, 1), 0,
    CircleX, CircleY - CircleRadius, 'Start 0.25 counter-clockwise');
end;

// Three pads of the carousel among pads of none and of another: they are
// a third of the lap apart, in their own order, and the others are not
// counted
procedure TCarouselOrbitTests.TestPadsShareTheLapInFileOrder;
begin
  var Other := CircleOf;
  Other.Tag := 'other';
  var Carousels: TArray<TCarousel> := [CircleOf, Other];
  var Pads: TArray<TPadPlacement> := [PadOn('wheel'), PadOn(''),
    PadOn('other'), PadOn('wheel'), PadOn('wheel')];

  // A third round is 120 degrees, two thirds 240
  var Across: Double := CircleRadius * Cos(2 * Pi / 3);
  var Down: Double := CircleRadius * Sin(2 * Pi / 3);
  ExpectOrbitAt(OrbitOf(Carousels, Pads, 0), 0, CircleX + CircleRadius,
    CircleY, 'The first pad of the carousel');
  ExpectOrbitAt(OrbitOf(Carousels, Pads, 3), 0, CircleX + Across,
    CircleY + Down, 'The second, a third round');
  ExpectOrbitAt(OrbitOf(Carousels, Pads, 4), 0, CircleX + Across,
    CircleY - Down, 'The third, two thirds round');
  ExpectOrbitAt(OrbitOf(Carousels, Pads, 2), 0, CircleX + CircleRadius,
    CircleY, 'The only pad of the other carousel');
end;

// A lap of 4 seconds is 132 ticks: a quarter of it takes a pad from the
// right to the bottom, and the place repeats a lap on
procedure TCarouselOrbitTests.TestLapTakesThePeriod;
const
  Ticks: array [0 .. 3] of Integer = (0, 7, 50, CircleLapTicks - 1);
var
  X, Y: Double;
begin
  var Orbit := OrbitOfSlot(CircleOf, 0, 1);
  ExpectOrbitAt(Orbit, QuarterTicks, CircleX, CircleY + CircleRadius,
    'A quarter of the period on');
  ExpectOrbitAt(Orbit, 2 * QuarterTicks, CircleX - CircleRadius, CircleY,
    'Half the period on');
  for var Tick in Ticks do
  begin
    Orbit.Place(Tick, X, Y);
    ExpectOrbitAt(Orbit, Tick + CircleLapTicks, X, Y,
      Format('Tick %d a lap on', [Tick]));
  end;
end;

// The game draws the pad between ticks: half a tick on it is half the
// way to the next tick, and on the circle all the same
procedure TCarouselOrbitTests.TestPadMovesBetweenTicksToo;
var
  X, Y: Double;
begin
  var Orbit := OrbitOfSlot(CircleOf, 0, 1);
  var Tick := DistanceBetween(Orbit, 10, 11);
  // A lap is the length of the circle, a tick a lap's 132nd share
  Assert.IsTrue(Abs(Tick - 2 * Pi * CircleRadius / CircleLapTicks) < 0.05,
    Format('A tick takes the pad %g units', [Tick]));
  var FirstHalf := DistanceBetween(Orbit, 10, 10.5);
  var SecondHalf := DistanceBetween(Orbit, 10.5, 11);
  Assert.IsTrue(Abs(FirstHalf - Tick / 2) < PlaceSlack,
    Format('Half a tick takes it %g units of %g', [FirstHalf, Tick]));
  Assert.IsTrue(Abs(SecondHalf - Tick / 2) < PlaceSlack,
    Format('The other half takes it %g units of %g', [SecondHalf, Tick]));
  Orbit.Place(10.5, X, Y);
  Assert.IsTrue(Abs(Hypot(X - CircleX, Y - CircleY) - CircleRadius) < 0.05,
    'Between ticks the pad is on the circle');
end;

// An oval with the first pad a tenth round: counter-clockwise the pad is
// where the clockwise one is, mirrored over the middle line
procedure TCarouselOrbitTests.TestCounterClockwiseMirrorsClockwise;
const
  Ticks: array [0 .. 3] of Integer = (0, 17, 50, 98);
var
  X, Y: Double;
begin
  var Clockwise := CarouselOf(csOval, 256, 192, 200, 100);
  Clockwise.Start := 0.1;
  Clockwise.Period := 3;
  var Counter := Clockwise;
  Counter.Turn := ctCounterClockwise;
  var ClockwiseOrbit := OrbitOfSlot(Clockwise, 0, 1);
  var CounterOrbit := OrbitOfSlot(Counter, 0, 1);
  for var Tick in Ticks do
  begin
    ClockwiseOrbit.Place(Tick, X, Y);
    ExpectOrbitAt(CounterOrbit, Tick, X, 2 * 192 - Y,
      Format('Tick %d counter-clockwise', [Tick]));
  end;
end;

// ---------------------------------------------------------------------------
// TLevelsCarouselsTests
// ---------------------------------------------------------------------------

// The caller frees the root
function RootOf(const AMembers: string): TJSONObject;
begin
  Result := TJSONObject.ParseJSONValue('{' + AMembers + '}') as TJSONObject;
  Assert.IsNotNull(Result, 'The text of the test is JSON');
end;

// A carousels section of one carousel: the members it must have, as they
// stand in a file ('' leaves one out), and AExtra beside them. A member
// is never given twice: of two keys alike the first wins, and the second
// tries nothing.
function SectionOf(const AExtra: string; const ACenter: string = '[288,179]';
  const ASize: string = '[150,120]'; const APeriod: string = '12'): string;
begin
  Result := '"carousels":[{"tag":"wheel","screen":3';
  if ACenter <> '' then
    Result := Result + ',"center":' + ACenter;
  if ASize <> '' then
    Result := Result + ',"size":' + ASize;
  if APeriod <> '' then
    Result := Result + ',"period":' + APeriod;
  if AExtra <> '' then
    Result := Result + ',' + AExtra;
  Result := Result + '}]';
end;

function ParseText(const AMembers: string): TArray<TCarousel>;
begin
  var Root := RootOf(AMembers);
  try
    Result := ParseCarousels(Root, 'test');
  finally
    Root.Free;
  end;
end;

function OnlyCarousel(const AMembers: string): TCarousel;
begin
  var Carousels := ParseText(AMembers);
  Assert.AreEqual(1, Integer(Length(Carousels)), 'The section holds one');
  Result := Carousels[0];
end;

// By value, not const: an anonymous method captures it
procedure ExpectRaises(ASection, AWhat: string);
begin
  Assert.WillRaise(
    procedure
    begin
      ParseText(ASection);
    end, ECarouselError, AWhat);
end;

procedure TLevelsCarouselsTests.TestNoSectionIsNoCarousels;
begin
  Assert.AreEqual(0, Integer(Length(ParseText('"pads":[]'))),
    'A level with no section');
  Assert.AreEqual(0, Integer(Length(ParseText('"carousels":[]'))),
    'An empty section');
end;

procedure TLevelsCarouselsTests.TestCarouselReadsWhatItIsGiven;
begin
  var Carousel := OnlyCarousel(SectionOf('"shape":"box","corner":10,' +
    '"turn":"ccw","start":0.5'));
  Assert.AreEqual('wheel', Carousel.Tag);
  Assert.AreEqual(3, Carousel.Screen);
  Assert.AreEqual<TCarouselShape>(csBox, Carousel.Shape);
  ExpectPoint(Carousel.CenterX, Carousel.CenterY, 288, 179, 'The center');
  ExpectPoint(Carousel.Width, Carousel.Height, 150, 120, 'The size');
  Assert.IsTrue(IsNear(Carousel.Corner, 10), 'The corner');
  Assert.IsTrue(IsNear(Carousel.Period, 12), 'The period');
  Assert.AreEqual<TCarouselTurn>(ctCounterClockwise, Carousel.Turn);
  Assert.IsTrue(IsNear(Carousel.Start, 0.5), 'The start');
end;

procedure TLevelsCarouselsTests.TestCarouselLeftOutComesToItsDefaults;
begin
  var Carousel := OnlyCarousel(SectionOf(''));
  Assert.AreEqual<TCarouselShape>(csOval, Carousel.Shape);
  Assert.IsTrue(IsNear(Carousel.Corner, 0), 'No corner');
  Assert.AreEqual<TCarouselTurn>(ctClockwise, Carousel.Turn);
  Assert.IsTrue(IsNear(Carousel.Start, 0),
    'The first pad starts on the right of the middle');
end;

procedure TLevelsCarouselsTests.TestWordsAreReadInAnyCase;
begin
  var Carousel := OnlyCarousel(SectionOf('"shape":"BOX","turn":"Ccw"'));
  Assert.AreEqual<TCarouselShape>(csBox, Carousel.Shape);
  Assert.AreEqual<TCarouselTurn>(ctCounterClockwise, Carousel.Turn);
  Carousel := OnlyCarousel(SectionOf('"shape":"Oval","turn":"CW"'));
  Assert.AreEqual<TCarouselShape>(csOval, Carousel.Shape);
  Assert.AreEqual<TCarouselTurn>(ctClockwise, Carousel.Turn);
end;

// Each alone; a box of 150 by 120 takes corners up to 60
procedure TLevelsCarouselsTests.TestBadCarouselRaises;
begin
  ExpectRaises(SectionOf('"shape":"circle"'),
    'A shape that is neither oval nor box');
  ExpectRaises(SectionOf('"turn":"left"'), 'A turn that is neither cw nor ccw');
  ExpectRaises(SectionOf('', '[288]'), 'A center of one number');
  ExpectRaises(SectionOf('', '[288,179,0]'), 'A center of three numbers');
  ExpectRaises(SectionOf('', '["a",179]'), 'A center that is not numbers');
  ExpectRaises(SectionOf('', ''), 'No center');
  ExpectRaises(SectionOf('', '[288,179]', '[0,120]'), 'A width of 0');
  ExpectRaises(SectionOf('', '[288,179]', '[150,-1]'), 'A height below 0');
  ExpectRaises(SectionOf('', '[288,179]', ''), 'No size');
  ExpectRaises(SectionOf('"shape":"box","corner":-1'), 'A corner below 0');
  ExpectRaises(SectionOf('"shape":"box","corner":60.5'),
    'A corner over half the box');
  ExpectRaises(SectionOf('', '[288,179]', '[150,120]', '0'), 'A period of 0');
  ExpectRaises(SectionOf('', '[288,179]', '[150,120]', '-1'),
    'A period below 0');
  ExpectRaises(SectionOf('', '[288,179]', '[150,120]', ''),
    'No period: the carousel never turns');
  ExpectRaises(SectionOf('"start":-0.1'), 'A start below 0');
  ExpectRaises(SectionOf('"start":1'), 'A start of a whole lap');

  Assert.AreEqual(1, Integer(Length(ParseText(SectionOf(
    '"shape":"box","corner":60,"start":0.99')))),
    'A corner of half the box and a start just short of a lap load');
end;

procedure TLevelsCarouselsTests.TestCarouselIsFoundByItsTag;
var
  Found: TCarousel;
begin
  var First := CircleOf;
  First.Tag := 'first';
  var Second := CircleOf;
  Second.Tag := 'second';
  Second.Screen := 5;
  var Carousels: TArray<TCarousel> := [First, Second];

  Assert.IsTrue(TryFindCarousel(Carousels, 'second', Found), 'The second');
  Assert.AreEqual(5, Found.Screen, 'and it is the second that is found');
  Assert.IsFalse(TryFindCarousel(Carousels, 'third', Found), 'No third');
end;

procedure TLevelsCarouselsTests.TestLapIsATickAtTheLeast;
begin
  var Carousel := CircleOf;
  Carousel.Period := 12;
  Assert.AreEqual(12 * TicksPerSecond, LapTicks(Carousel), 'Twelve seconds');
  Carousel.Period := 1 / TicksPerSecond;
  Assert.AreEqual(1, LapTicks(Carousel), 'A tick');
  Carousel.Period := 0.001;
  Assert.AreEqual(1, LapTicks(Carousel), 'Less than a tick');
end;

initialization
  TDUnitX.RegisterTestFixture(TCarouselTrackTests);
  TDUnitX.RegisterTestFixture(TCarouselOrbitTests);
  TDUnitX.RegisterTestFixture(TLevelsCarouselsTests);

end.
