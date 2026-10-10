{
  Tests.Orbs.Patterns - the figures the rite of orbs builds about the hero,
  tried as figures: the snowflake has six rays behind him and a hexagon in
  front that walks against their turn; the vortex has an arm to a wave,
  goes round him, flares toward the top and leaps from its top to its foot
  only with its light out. And the names: a word of a level file finds its
  pattern, a word unknown raises.

  A pattern is a function of a wave, a number and the pattern's clock, so a
  test asks for seats and looks at them. Whether a figure is beautiful is
  for the eye.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Orbs.Patterns;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TOrbPatternsTests = class
  public
    [Test]
    procedure TestGamePatternsAreFoundByTheirWords;
    [Test]
    procedure TestUnknownPatternRaises;
    [Test]
    procedure TestLevelFileNamesItsPattern;
    [Test]
    procedure TestSnowflakeRaysAreBehindAndHexagonInFront;
    [Test]
    procedure TestSnowflakeSeatsAreApartAndWithinReach;
    [Test]
    procedure TestSnowflakeHasSixRays;
    [Test]
    procedure TestSnowflakeTurnsAndItsHexagonWalksAgainst;
    [Test]
    procedure TestVortexGivesEachWaveAnArmOfItsOwn;
    [Test]
    procedure TestVortexOrbGoesRoundTheHero;
    [Test]
    procedure TestVortexIsNarrowAtTheFeetAndWideOverTheHead;
    [Test]
    procedure TestVortexSeatLeapsOnlyWithItsLightOut;
  end;

implementation

uses
  System.SysUtils, System.Math, Sdl2.Core, Levels.Defs, Orbs.Patterns,
  Tests.Rooms;

type
  // The seats of a pattern at one moment: wave after wave, each by number
  TSeats = TArray<TPatternSeat>;

const
  SnowflakeName = 'snowflake';
  VortexName = 'vortex';
  // Three waves of 24
  OrbsOfARite = 72;
  PlaceSlack = 0.01; // units
  // Moments of a pattern's clock to look at a figure at, ticks
  Flows: array [0..7] of Single = (0, 1, 37.5, 100, 131.25, 250, 419, 1000.5);
  // A rite's clock goes a tick a tick and, through the hover, up to twice
  // that
  EvenPace = 1;
  QuickPace = 2;
  // Long enough for every seat of either figure to come round
  ClockSpan = 500; // ticks
  SixthOfATurn = Pi / 3;

function SeatsOf(const APattern: TOrbPattern; AFlow: Single): TSeats;
begin
  SetLength(Result, PatternWaves * APattern.PerWave);
  for var Wave := 0 to PatternWaves - 1 do
    for var Number := 0 to APattern.PerWave - 1 do
      Result[Wave * APattern.PerWave + Number] :=
        APattern.Seat(Wave, Number, APattern.PerWave, AFlow);
end;

function Apart(const ALeft, ARight: TPatternSeat): Single;
begin
  Result := Sqrt(Sqr(ALeft.X - ARight.X) + Sqr(ALeft.Y - ARight.Y));
end;

// How far the seat lies from the middle of the hero's body
function Reach(const ASeat: TPatternSeat): Single;
begin
  Result := Sqrt(Sqr(ASeat.X) + Sqr(ASeat.Y));
end;

// The middle of the seats AFrom..ATo
function MiddleOf(const ASeats: TSeats; AFrom, ATo: Integer): TSdlFPoint;
begin
  Result.X := 0;
  Result.Y := 0;
  for var i := AFrom to ATo do
  begin
    Result.X := Result.X + ASeats[i].X / (ATo - AFrom + 1);
    Result.Y := Result.Y + ASeats[i].Y / (ATo - AFrom + 1);
  end;
end;

// The seat turned about the point by ATurn radians
function TurnedAbout(const ASeat: TPatternSeat; APoint: TSdlFPoint;
  ATurn: Single): TPatternSeat;
begin
  var OffX: Single := ASeat.X - APoint.X;
  var OffY: Single := ASeat.Y - APoint.Y;
  Result := ASeat;
  Result.X := APoint.X + OffX * Cos(ATurn) - OffY * Sin(ATurn);
  Result.Y := APoint.Y + OffX * Sin(ATurn) + OffY * Cos(ATurn);
end;

// How far from ASeat the nearest of the seats AFrom..ATo lies
function NearestTo(const ASeat: TPatternSeat; const ASeats: TSeats;
  AFrom, ATo: Integer): Single;
begin
  Result := Apart(ASeat, ASeats[AFrom]);
  for var i := AFrom + 1 to ATo do
    if Apart(ASeat, ASeats[i]) < Result then
      Result := Apart(ASeat, ASeats[i]);
end;

// The turn about the point a seat has made from where it was, radians,
// the short way round
function TurnMade(APoint: TSdlFPoint; const ABefore,
  AAfter: TPatternSeat): Single;
begin
  var BeforeX: Single := ABefore.X - APoint.X;
  var BeforeY: Single := ABefore.Y - APoint.Y;
  var AfterX: Single := AAfter.X - APoint.X;
  var AfterY: Single := AAfter.Y - APoint.Y;
  // The sine and the cosine of the turn between the two, times their
  // lengths
  var Cross: Single := BeforeX * AfterY - BeforeY * AfterX;
  var Dot: Single := BeforeX * AfterX + BeforeY * AfterY;
  Result := ArcTan2(Cross, Dot);
end;

procedure ExpectAllApart(const ASeats: TSeats);
const
  // Two orbs nearer than this are drawn as one
  LeastApart = 1; // units
begin
  for var i := 0 to High(ASeats) do
    for var j := i + 1 to High(ASeats) do
      Assert.IsTrue(Apart(ASeats[i], ASeats[j]) > LeastApart,
        Format('Seats %d and %d are one seat', [i, j]));
end;

// By value, not const: an anonymous method captures it
procedure ExpectUnknown(AName: string);
begin
  Assert.WillRaise(
    procedure
    begin
      FindPattern(AName);
    end, EOrbPatternError, Format('The name "%s" found a pattern', [AName]));
end;

// The word a level of one room gives for its pattern; ASections - the
// members of its root, as LevelFromRows takes them
function PatternWordOf(const ASections: string): string;
begin
  var Level := LevelFromRows(RoomRowsOf(0, 0, 0, 0), ASections);
  try
    Result := Level.HenshinPattern;
  finally
    Level.Free;
  end;
end;

procedure TOrbPatternsTests.TestGamePatternsAreFoundByTheirWords;
const
  Names: array [0..1] of string = (SnowflakeName, VortexName);
begin
  for var Name in Names do
  begin
    var Pattern := FindPattern(Name);
    Assert.AreEqual(Name, Pattern.Name);
    Assert.IsTrue(Assigned(Pattern.Seat), Name + ' has no seats');
    Assert.AreEqual(OrbsOfARite, PatternWaves * Pattern.PerWave,
      'Orbs of ' + Name);
  end;
  Assert.AreEqual(SnowflakeName, FindPattern(DefaultPatternName).Name,
    'The pattern of a level that names none');
end;

procedure TOrbPatternsTests.TestUnknownPatternRaises;
begin
  ExpectUnknown('blizzard');
  ExpectUnknown('');
end;

procedure TOrbPatternsTests.TestLevelFileNamesItsPattern;
begin
  var Written := PatternWordOf('"henshinPattern":"vortex"');
  Assert.AreEqual(VortexName, Written, 'The word of the level file');
  Assert.AreEqual(VortexName, FindPattern(Written).Name);

  Assert.AreEqual('', PatternWordOf(''),
    'A level that names no pattern leaves the choice to the game');
end;

procedure TOrbPatternsTests.TestSnowflakeRaysAreBehindAndHexagonInFront;
begin
  var Snowflake := FindPattern(SnowflakeName);
  var FirstOfHexagon := 2 * Snowflake.PerWave;

  for var Flow in Flows do
  begin
    var Seats := SeatsOf(Snowflake, Flow);
    for var i := 0 to FirstOfHexagon - 1 do
      Assert.IsTrue(Seats[i].Depth < 0,
        Format('Seat %d of the rays is not behind the hero', [i]));
    for var i := FirstOfHexagon to High(Seats) do
      Assert.IsTrue(Seats[i].Depth > 0,
        Format('Seat %d of the hexagon is not in front of the hero', [i]));
  end;
end;

procedure TOrbPatternsTests.TestSnowflakeSeatsAreApartAndWithinReach;
const
  FarthestReach = 50; // units
begin
  var Snowflake := FindPattern(SnowflakeName);

  for var Flow in Flows do
  begin
    var Seats := SeatsOf(Snowflake, Flow);
    ExpectAllApart(Seats);
    for var i := 0 to High(Seats) do
    begin
      Assert.IsTrue(Reach(Seats[i]) < FarthestReach,
        Format('Seat %d lies %g units from the hero', [i, Reach(Seats[i])]));
      var IsLightAShare := (Seats[i].Level >= 0) and (Seats[i].Level <= 1);
      Assert.IsTrue(IsLightAShare,
        Format('Seat %d burns at %g', [i, Seats[i].Level]));
    end;
  end;
end;

procedure TOrbPatternsTests.TestSnowflakeHasSixRays;
begin
  var Snowflake := FindPattern(SnowflakeName);
  var PerWave := Snowflake.PerWave;

  for var Flow in Flows do
  begin
    var Seats := SeatsOf(Snowflake, Flow);
    var Heart := MiddleOf(Seats, 0, PerWave - 1);
    for var i := 0 to High(Seats) do
    begin
      // A sixth of a turn about the heart lands every seat on a seat of
      // its own wave
      var Turned := TurnedAbout(Seats[i], Heart, SixthOfATurn);
      var FirstOfWave := (i div PerWave) * PerWave;
      var Off := NearestTo(Turned, Seats, FirstOfWave,
        FirstOfWave + PerWave - 1);
      Assert.IsTrue(Off < PlaceSlack,
        Format('Seat %d has no twin on the next ray: %g units off',
        [i, Off]));
    end;
  end;
end;

procedure TOrbPatternsTests.TestSnowflakeTurnsAndItsHexagonWalksAgainst;
const
  // A seat that keeps to its figure goes no farther in a tick of the clock
  LongestStep = 3; // units
begin
  var Snowflake := FindPattern(SnowflakeName);
  var PerWave := Snowflake.PerWave;
  var FirstOfHexagon := 2 * PerWave;

  for var Tick := 0 to ClockSpan - 1 do
  begin
    var Before := SeatsOf(Snowflake, Tick);
    var After := SeatsOf(Snowflake, Tick + EvenPace);
    var Heart := MiddleOf(Before, 0, PerWave - 1);

    var RayTurn := TurnMade(Heart, Before[0], After[0]);
    Assert.IsTrue(RayTurn <> 0, 'The rays stand still');
    for var i := 1 to PerWave - 1 do
      Assert.IsTrue(TurnMade(Heart, Before[i], After[i]) * RayTurn > 0,
        Format('Seat %d of the rays turns against the others', [i]));
    for var i := FirstOfHexagon to High(Before) do
      Assert.IsTrue(TurnMade(Heart, Before[i], After[i]) * RayTurn < 0,
        Format('Seat %d of the hexagon goes with the rays on tick %d',
        [i, Tick]));

    var Quick := SeatsOf(Snowflake, Tick + QuickPace);
    for var i := 0 to High(Before) do
      Assert.IsTrue(Apart(Before[i], Quick[i]) < LongestStep,
        Format('Seat %d leaps on tick %d', [i, Tick]));
  end;
end;

procedure TOrbPatternsTests.TestVortexGivesEachWaveAnArmOfItsOwn;
begin
  var Vortex := FindPattern(VortexName);
  var PerWave := Vortex.PerWave;

  for var Flow in Flows do
  begin
    var Seats := SeatsOf(Vortex, Flow);
    for var Number := 0 to PerWave - 1 do
    begin
      var First := Seats[Number];
      var Second := Seats[PerWave + Number];
      var Third := Seats[2 * PerWave + Number];
      // A third of a lap apart about the hero's upright, they balance
      // across it and in depth
      var IsBalanced := (Abs(First.X + Second.X + Third.X) < PlaceSlack) and
        (Abs(First.Depth + Second.Depth + Third.Depth) < PlaceSlack);
      Assert.IsTrue(IsBalanced,
        Format('The three arms do not balance at number %d', [Number]));
      var IsThreeSeats := (Apart(First, Second) > PlaceSlack) and
        (Apart(Second, Third) > PlaceSlack) and
        (Apart(First, Third) > PlaceSlack);
      Assert.IsTrue(IsThreeSeats,
        Format('Two waves share a seat at number %d', [Number]));
    end;
  end;
end;

procedure TOrbPatternsTests.TestVortexOrbGoesRoundTheHero;
const
  // Well behind him and well in front
  DeepEnough = 0.5;
  // Two climbs of an arm: long enough for any orb to have gone round
  RoundTicks = 128;
begin
  var Vortex := FindPattern(VortexName);
  var Farthest: TArray<Single>;
  var Nearest: TArray<Single>;
  SetLength(Farthest, PatternWaves * Vortex.PerWave);
  SetLength(Nearest, PatternWaves * Vortex.PerWave);

  for var Tick := 0 to RoundTicks - 1 do
  begin
    var Seats := SeatsOf(Vortex, Tick);
    for var i := 0 to High(Seats) do
    begin
      if Seats[i].Depth < Farthest[i] then
        Farthest[i] := Seats[i].Depth;
      if Seats[i].Depth > Nearest[i] then
        Nearest[i] := Seats[i].Depth;
    end;
  end;

  for var i := 0 to High(Farthest) do
  begin
    var IsRound := (Farthest[i] < -DeepEnough) and (Nearest[i] > DeepEnough);
    Assert.IsTrue(IsRound,
      Format('Seat %d keeps to depths %g..%g', [i, Farthest[i], Nearest[i]]));
  end;
end;

procedure TOrbPatternsTests.TestVortexIsNarrowAtTheFeetAndWideOverTheHead;
const
  // Rows of the hero's frame, from the middle of his body: his feet are
  // under it, and a seat this far over it is over his head
  OverTheHead = -32;
  FarthestReach = 60; // units
  // The top of the funnel is this many times wider than its foot
  Flare = 1.5;
  FunnelTicks = 128;
begin
  var Vortex := FindPattern(VortexName);
  var WidestLow: Single := 0;
  var WidestHigh: Single := 0;

  for var Tick := 0 to FunnelTicks - 1 do
    for var Seat in SeatsOf(Vortex, Tick) do
    begin
      Assert.IsTrue(Reach(Seat) < FarthestReach,
        Format('A seat lies %g units from the hero', [Reach(Seat)]));
      var IsLightAShare := (Seat.Level >= 0) and (Seat.Level <= 1);
      Assert.IsTrue(IsLightAShare, Format('A seat burns at %g', [Seat.Level]));
      if (Seat.Y > 0) and (Abs(Seat.X) > WidestLow) then
        WidestLow := Abs(Seat.X);
      if (Seat.Y < OverTheHead) and (Abs(Seat.X) > WidestHigh) then
        WidestHigh := Abs(Seat.X);
    end;

  Assert.IsTrue(WidestLow > 0, 'No seat lies by the feet');
  Assert.IsTrue(WidestHigh > Flare * WidestLow,
    Format('The funnel is %g wide by the feet and %g over the head',
    [WidestLow, WidestHigh]));
end;

procedure TOrbPatternsTests.TestVortexSeatLeapsOnlyWithItsLightOut;
const
  // A seat either keeps to its figure, a short step, or runs off its end
  // and begins anew, a long leap; nothing lies between the two
  LongestStep = 12; // units
  ShortestLeap = 40; // units
  // An orb this dim is as good as out
  LightOut = 0.2;
var
  Leaps: Integer;

  procedure TryPace(APace: Integer);
  begin
    var Vortex := FindPattern(VortexName);
    for var Tick := 0 to ClockSpan - 1 do
    begin
      var Before := SeatsOf(Vortex, Tick);
      var After := SeatsOf(Vortex, Tick + APace);
      for var i := 0 to High(Before) do
      begin
        var Moved := Apart(Before[i], After[i]);
        if Moved < LongestStep then
          Continue;
        Inc(Leaps);
        Assert.IsTrue(Moved > ShortestLeap,
          Format('Seat %d goes %g units in a tick: no step and no leap',
          [i, Moved]));
        var IsOut := (Before[i].Level < LightOut) and
          (After[i].Level < LightOut);
        Assert.IsTrue(IsOut,
          Format('Seat %d leaps with its light on: %g, then %g',
          [i, Before[i].Level, After[i].Level]));
      end;
    end;
  end;

begin
  Leaps := 0;
  TryPace(EvenPace);
  TryPace(QuickPace);
  Assert.IsTrue(Leaps > 0, 'No seat ever came to the end of its arm');
end;

initialization
  TDUnitX.RegisterTestFixture(TOrbPatternsTests);

end.
