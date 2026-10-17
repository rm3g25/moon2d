{
  Tests.Orbs.Burst - the burst of the suit ticked without a window: the
  inhale in which the world stands, the strike told once, the rays - how
  many, which way, alike, through matter and off the screen, curled in a
  vortex -, the stretches the game strikes along, the marks on the faces
  and the motes out of the body.

  The rays are watched by the stretches alone: a test joins every tick's
  stretches into the way of each head. The marks and the motes are read
  from their swarms. The hero is a point the test moves; his body is five
  points about it.

  What the game does along a stretch - the bullets put out, the monsters
  wounded once - is the game's. The look of it all - the veil, the figure,
  the bands of a ray, the ring, the flash - is for the eye.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Orbs.Burst;

interface

uses
  DUnitX.TestFramework, Sdl2.Core, Orbs.Harvest, Orbs.Rite, Orbs.Burst;

type
  // Where a ray's head stood, tick by tick, the first point at the chest
  TRayWay = TArray<TSdlFPoint>;
  TPlaces = TArray<TSdlFPoint>;

  [TestFixture]
  TOrbBurstTests = class
  private
    FBurst: TOrbBurst;
    // A second burst, for the tests that run two side by side
    FTwin: TOrbBurst;
    FMatter: TMatter;
    // The hero's middle, where the next tick finds it
    FCenter: TSdlFPoint;
    // Units the hero steps along X before every tick
    FWalk: Single;
    // The number of the next tick since the start, counted from 0
    FTicks: Integer;
    // The times a burst has asked for the hero's body
    FAsked: Integer;
    FWays: TArray<TRayWay>;
    function BodyAboutHero: TBodyPoints;
    function NoBody: TBodyPoints;
    procedure RemakeBurst(const ABody: TBodyProbe);
    procedure Start(ACurl: Boolean);
    // One tick, the hero stepped first; the twin, if any, ticks along
    procedure Tick;
    procedure Run(ACount: Integer);
    // Until the tick of this number is done
    procedure RunTo(ATick: Integer);
    // The ticks of the inhale before the strike
    procedure Inhale;
    // Tick by tick until a tick passes with no stretch, the ways followed;
    // the ticks that had stretches, or LongestFlight + 1 if they never end
    function FlyOut: Integer;
    procedure TakeStretches(const AStretches: TArray<TBurstStretch>;
      var AAlive: TArray<Boolean>);
    function HeadAt(AX, AY: Single; const AAlive,
      ATaken: TArray<Boolean>): Integer;
    // The way that passes the point, -1 for none
    function WayUnder(AX, AY: Single): Integer;
    function MarkPlaces: TPlaces;
    function MotePlaces: TPlaces;
    procedure ExpectQuietFor(ACount: Integer; const AWhen: string);
    procedure ExpectSameAsTwin(ATick: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestNewBurstIsIdle;
    [Test]
    procedure TestWorldStandsForTheInhaleOnly;
    [Test]
    procedure TestStrikeIsToldOnceAfterTheInhale;
    [Test]
    procedure TestUnheardStrikeWaitsToBeTold;
    [Test]
    procedure TestStrikeSendsTwentyFourRaysFromTheChest;
    [Test]
    procedure TestRaysGoEveryFifteenDegreesOneStraightUp;
    [Test]
    procedure TestRaysAreAlikeOnEveryTick;
    [Test]
    procedure TestStretchesJoinIntoTheWayOfEachHead;
    [Test]
    procedure TestStraightRayKeepsToItsLine;
    [Test]
    procedure TestVortexRaysCurlOneWayAndTheCurlDiesOff;
    [Test]
    procedure TestRaysGoThroughMatterAndOffTheScreen;
    [Test]
    procedure TestRayMarksTheFaceItGoesInto;
    [Test]
    procedure TestRayMarksAFaceAgainAfterCrossingASlab;
    [Test]
    procedure TestEmptyRoomTakesNoMarks;
    [Test]
    procedure TestMarksStayPutThenMeltAway;
    [Test]
    procedure TestMotesComeOutOfThePointsOfTheBody;
    [Test]
    procedure TestWithNoBodyMotesComeOutOfTheChest;
    [Test]
    procedure TestMotesLiveAWhileThenGo;
    [Test]
    procedure TestRaysLeaveFromTheHeroAtTheStrikeAndDoNotFollowHim;
    [Test]
    procedure TestClearLeavesNothingAndNothingComes;
    [Test]
    procedure TestStartDropsTheBurstAlreadyGoing;
    [Test]
    procedure TestMoonBurstFliesAsTheIceOne;
    [Test]
    procedure TestSameCallsGiveTheSameBurst;
  end;

implementation

uses
  System.SysUtils, System.Math, Effects.Emitter, Tests.Matter;

const
  PlaceSlack = 0.01; // units
  // The hero's middle as he stands on the floor of the walled room
  StandX = 256;
  StandY = 336;

  RaysAround = 24;
  RayApart = 15; // degrees
  AngleSlack = 0.01; // degrees
  // The rays leave from the chest: one point, this near the middle
  ChestReach = 4; // units
  // Rays alike: their stretches as long and their heads as far out, to
  // within these
  LengthSlack = 0.01; // units
  ReachSlack = 0.05; // units
  // A straight ray: every head on the line of its first stretch
  LineSlack = 0.05; // units
  // A mark stands on its ray's way, and matter is this near it
  WaySlack = 0.05; // units
  FaceReach = 3; // units

  // The rays are off the screen within two seconds
  LongestFlight = 66; // ticks
  // A burst that is over stays quiet: it is watched this long after
  QuietTicks = 100;
  // Marks and motes outlive half a second; nothing of the echo is left
  // after ten
  HalfSecond = 16; // ticks
  TwoSeconds = 66; // ticks
  TenSeconds = 330; // ticks

  // The hero leaps this far before every tick of a test that has him
  // jump away from where the burst began
  LeapStep = -20; // units

  // The walled room with a slab across it, a cell thick, above the hero.
  // A ray that leaves within 45 degrees of straight up crosses the slab
  // before it reaches the ceiling or a wall; the others never touch it.
  SlabRows: array [0..11] of string = (
    '################',
    '#..............#',
    '#..............#',
    '#..............#',
    '################',
    '#..............#',
    '#..............#',
    '#..............#',
    '#..............#',
    '#..............#',
    '#..............#',
    '################');
  SlabReach = 45; // degrees from straight up
  // Seven rays mark the slab and the wall or ceiling past it, seventeen
  // mark a wall or the floor alone
  SlabMarks = 31;

  // The points of the hero's body, from his middle
  BodyOffsets: array [0..4] of TSdlFPoint = ((X: -6; Y: -12), (X: 5; Y: -8),
    (X: -3; Y: 2), (X: 7; Y: 9), (X: 0; Y: 14));

function PointAt(AX, AY: Single): TSdlFPoint;
begin
  Result.X := AX;
  Result.Y := AY;
end;

function IsNear(AX, AY, AToX, AToY: Single): Boolean;
begin
  Result := (Abs(AX - AToX) < PlaceSlack) and (Abs(AY - AToY) < PlaceSlack);
end;

function Distance(AX, AY, AToX, AToY: Single): Single;
begin
  Result := Sqrt(Sqr(AToX - AX) + Sqr(AToY - AY));
end;

function IsOnScreen(const APoint: TSdlFPoint): Boolean;
begin
  Result := (APoint.X >= 0) and (APoint.X < 512) and (APoint.Y >= 0) and
    (APoint.Y < 384);
end;

function StretchLength(const AStretch: TBurstStretch): Single;
begin
  Result := Distance(AStretch.FromX, AStretch.FromY, AStretch.ToX,
    AStretch.ToY);
end;

// Degrees round from straight up, the way the picture turns, 0..360
function TurnFromUp(AFrom, ATo: TSdlFPoint): Single;
begin
  Result := RadToDeg(ArcTan2(ATo.Y - AFrom.Y, ATo.X - AFrom.X)) + 90;
  if Result < 0 then
    Result := Result + 360;
  if Result >= 360 then
    Result := Result - 360;
end;

// The turn from one step of a way to the next, radians
function TurnOfSteps(const AWay: TRayWay; AIndex: Integer): Single;
begin
  var BeforeX: Single := AWay[AIndex + 1].X - AWay[AIndex].X;
  var BeforeY: Single := AWay[AIndex + 1].Y - AWay[AIndex].Y;
  var AfterX: Single := AWay[AIndex + 2].X - AWay[AIndex + 1].X;
  var AfterY: Single := AWay[AIndex + 2].Y - AWay[AIndex + 1].Y;
  // The sine and the cosine of the turn, times the two lengths
  var Cross: Single := BeforeX * AfterY - BeforeY * AfterX;
  var Dot: Single := BeforeX * AfterX + BeforeY * AfterY;
  Result := ArcTan2(Cross, Dot);
end;

// How far the point is from the stretch between A and B
function ReachToStretch(const APoint, A, B: TSdlFPoint): Single;
begin
  var AlongX: Single := B.X - A.X;
  var AlongY: Single := B.Y - A.Y;
  var Span: Single := Sqr(AlongX) + Sqr(AlongY);
  var Share: Single := 0;
  if Span > 0 then
  begin
    var Raw: Single := ((APoint.X - A.X) * AlongX +
      (APoint.Y - A.Y) * AlongY) / Span;
    Share := EnsureRange(Raw, 0.0, 1.0);
  end;
  Result := Distance(APoint.X, APoint.Y, A.X + AlongX * Share,
    A.Y + AlongY * Share);
end;

// The way runs through matter: a point of it, looked at every unit, is
// solid
function GoesThroughMatter(const AMatter: TMatter;
  const AWay: TRayWay): Boolean;
begin
  for var i := 0 to High(AWay) - 1 do
  begin
    var Steps := Max(1, Trunc(Distance(AWay[i].X, AWay[i].Y, AWay[i + 1].X,
      AWay[i + 1].Y)));
    for var Step := 0 to Steps do
    begin
      var Share: Single := Step / Steps;
      if SolidAt(AMatter, AWay[i].X + (AWay[i + 1].X - AWay[i].X) * Share,
        AWay[i].Y + (AWay[i + 1].Y - AWay[i].Y) * Share) then
        Exit(True);
    end;
  end;
  Result := False;
end;

function MatterBeside(const AMatter: TMatter; AX, AY: Single): Boolean;
begin
  for var StepX := -FaceReach to FaceReach do
    for var StepY := -FaceReach to FaceReach do
      if SolidAt(AMatter, AX + StepX, AY + StepY) then
        Exit(True);
  Result := False;
end;

// ---------------------------------------------------------------------------
// The bench
// ---------------------------------------------------------------------------

procedure TOrbBurstTests.Setup;
begin
  FMatter := WalledMatter;
  FCenter := PointAt(StandX, StandY);
  FWalk := 0;
  FTicks := 0;
  FAsked := 0;
  FBurst := TOrbBurst.Create(BodyAboutHero);
end;

procedure TOrbBurstTests.TearDown;
begin
  FreeAndNil(FTwin);
  FreeAndNil(FBurst);
end;

function TOrbBurstTests.BodyAboutHero: TBodyPoints;
begin
  Inc(FAsked);
  SetLength(Result, Length(BodyOffsets));
  for var i := 0 to High(BodyOffsets) do
    Result[i] := PointAt(FCenter.X + BodyOffsets[i].X,
      FCenter.Y + BodyOffsets[i].Y);
end;

function TOrbBurstTests.NoBody: TBodyPoints;
begin
  Inc(FAsked);
  Result := nil;
end;

procedure TOrbBurstTests.RemakeBurst(const ABody: TBodyProbe);
begin
  FreeAndNil(FBurst);
  FBurst := TOrbBurst.Create(ABody);
end;

procedure TOrbBurstTests.Start(ACurl: Boolean);
begin
  FWays := nil;
  FTicks := 0;
  FBurst.Start(IceBurstLook, ACurl, FCenter, FMatter);
end;

procedure TOrbBurstTests.Tick;
begin
  FCenter.X := FCenter.X + FWalk;
  FBurst.Tick(FCenter);
  if Assigned(FTwin) then
    FTwin.Tick(FCenter);
  Inc(FTicks);
end;

procedure TOrbBurstTests.Run(ACount: Integer);
begin
  for var i := 1 to ACount do
    Tick;
end;

procedure TOrbBurstTests.RunTo(ATick: Integer);
begin
  while FTicks <= ATick do
    Tick;
end;

procedure TOrbBurstTests.Inhale;
begin
  Run(InhaleTicks - 1);
end;

function TOrbBurstTests.FlyOut: Integer;
begin
  var Alive: TArray<Boolean> := nil;
  Result := 0;
  while Result <= LongestFlight do
  begin
    Tick;
    var Stretches := FBurst.Stretches;
    if (Length(Stretches) = 0) and (Length(FWays) > 0) then
      Exit;
    TakeStretches(Stretches, Alive);
    Inc(Result);
  end;
end;

// The first stretches each begin a way; every later one carries on the
// way whose head stood where it begins
procedure TOrbBurstTests.TakeStretches(const AStretches: TArray<TBurstStretch>;
  var AAlive: TArray<Boolean>);
begin
  if Length(FWays) = 0 then
  begin
    SetLength(FWays, Length(AStretches));
    SetLength(AAlive, Length(AStretches));
    for var i := 0 to High(AStretches) do
    begin
      FWays[i] := [PointAt(AStretches[i].FromX, AStretches[i].FromY),
        PointAt(AStretches[i].ToX, AStretches[i].ToY)];
      AAlive[i] := True;
    end;
    Exit;
  end;

  var Taken: TArray<Boolean>;
  SetLength(Taken, Length(FWays));
  for var Stretch in AStretches do
  begin
    var Way := HeadAt(Stretch.FromX, Stretch.FromY, AAlive, Taken);
    Assert.IsTrue(Way >= 0, Format(
      'Tick %d: a stretch begins at (%.2f, %.2f), where no head stood',
      [FTicks - 1, Stretch.FromX, Stretch.FromY]));
    Taken[Way] := True;
    FWays[Way] := FWays[Way] + [PointAt(Stretch.ToX, Stretch.ToY)];
  end;
  AAlive := Taken;
end;

function TOrbBurstTests.HeadAt(AX, AY: Single; const AAlive,
  ATaken: TArray<Boolean>): Integer;
begin
  for var i := 0 to High(FWays) do
  begin
    var Head := FWays[i][High(FWays[i])];
    if AAlive[i] and not ATaken[i] and IsNear(AX, AY, Head.X, Head.Y) then
      Exit(i);
  end;
  Result := -1;
end;

function TOrbBurstTests.WayUnder(AX, AY: Single): Integer;
begin
  Result := -1;
  var Nearest: Single := WaySlack;
  for var i := 0 to High(FWays) do
    for var j := 0 to High(FWays[i]) - 1 do
    begin
      var Reach := ReachToStretch(PointAt(AX, AY), FWays[i][j],
        FWays[i][j + 1]);
      if Reach < Nearest then
      begin
        Nearest := Reach;
        Result := i;
      end;
    end;
end;

function TOrbBurstTests.MarkPlaces: TPlaces;
begin
  SetLength(Result, FBurst.Marks.Count);
  for var i := 0 to High(Result) do
    Result[i] := PointAt(FBurst.Marks.Particles[i]^.X,
      FBurst.Marks.Particles[i]^.Y);
end;

function TOrbBurstTests.MotePlaces: TPlaces;
begin
  SetLength(Result, FBurst.Motes.Count);
  for var i := 0 to High(Result) do
    Result[i] := PointAt(FBurst.Motes.Particles[i]^.X,
      FBurst.Motes.Particles[i]^.Y);
end;

procedure TOrbBurstTests.ExpectQuietFor(ACount: Integer; const AWhen: string);
begin
  for var i := 1 to ACount do
  begin
    Tick;
    Assert.IsFalse(FBurst.Holding, Format('%s, tick %d: the world stands',
      [AWhen, i]));
    Assert.AreEqual(0, Length(FBurst.Stretches),
      Format('%s, tick %d: stretches', [AWhen, i]));
    Assert.AreEqual<TBurstEvent>(beNone, FBurst.DrainEvent,
      Format('%s, tick %d: told', [AWhen, i]));
  end;
end;

procedure TOrbBurstTests.ExpectSameAsTwin(ATick: Integer);
begin
  Assert.AreEqual<Boolean>(FTwin.Holding, FBurst.Holding,
    Format('Tick %d: holding', [ATick]));

  var Mine := FBurst.Stretches;
  var Twins := FTwin.Stretches;
  Assert.AreEqual(Length(Twins), Length(Mine),
    Format('Tick %d: stretches', [ATick]));
  for var i := 0 to High(Mine) do
    Assert.IsTrue(IsNear(Mine[i].FromX, Mine[i].FromY, Twins[i].FromX,
      Twins[i].FromY) and IsNear(Mine[i].ToX, Mine[i].ToY, Twins[i].ToX,
      Twins[i].ToY), Format('Tick %d: stretch %d differs', [ATick, i]));

  Assert.AreEqual(FTwin.Marks.Count, FBurst.Marks.Count,
    Format('Tick %d: marks', [ATick]));
  for var i := 0 to FBurst.Marks.Count - 1 do
    Assert.IsTrue(IsNear(FBurst.Marks.Particles[i]^.X,
      FBurst.Marks.Particles[i]^.Y, FTwin.Marks.Particles[i]^.X,
      FTwin.Marks.Particles[i]^.Y),
      Format('Tick %d: mark %d differs', [ATick, i]));

  Assert.AreEqual(FTwin.Motes.Count, FBurst.Motes.Count,
    Format('Tick %d: motes', [ATick]));
  for var i := 0 to FBurst.Motes.Count - 1 do
    Assert.IsTrue(IsNear(FBurst.Motes.Particles[i]^.X,
      FBurst.Motes.Particles[i]^.Y, FTwin.Motes.Particles[i]^.X,
      FTwin.Motes.Particles[i]^.Y),
      Format('Tick %d: mote %d differs', [ATick, i]));
end;

// ---------------------------------------------------------------------------
// The inhale and the strike
// ---------------------------------------------------------------------------

procedure TOrbBurstTests.TestNewBurstIsIdle;
begin
  Assert.IsFalse(FBurst.Holding, 'Holding');
  Assert.IsFalse(FBurst.Inhaling, 'Inhaling');
  Assert.AreEqual(0, Length(FBurst.Stretches), 'Stretches');
  Assert.AreEqual(0, FBurst.Marks.Count, 'Marks');
  Assert.AreEqual(0, FBurst.Motes.Count, 'Motes');
  ExpectQuietFor(QuietTicks, 'Never started');
  Assert.AreEqual(0, FAsked, 'The body was asked for');
end;

procedure TOrbBurstTests.TestWorldStandsForTheInhaleOnly;
begin
  Start(False);
  for var i := 1 to InhaleTicks do
  begin
    Assert.IsTrue(FBurst.Holding,
      Format('Before tick %d of the inhale: the world goes on', [i]));
    Assert.IsTrue(FBurst.Inhaling,
      Format('Before tick %d of the inhale: the hero is not a figure', [i]));
    Tick;
    if i < InhaleTicks then
      Assert.AreEqual(0, Length(FBurst.Stretches),
        Format('Tick %d of the inhale: a ray is out', [i]));
  end;

  for var i := 1 to QuietTicks do
  begin
    Assert.IsFalse(FBurst.Holding,
      Format('%d ticks after the inhale: the world stands', [i - 1]));
    Assert.IsFalse(FBurst.Inhaling,
      Format('%d ticks after the inhale: the hero is a figure', [i - 1]));
    Tick;
  end;
end;

procedure TOrbBurstTests.TestStrikeIsToldOnceAfterTheInhale;
begin
  Start(False);
  var Told := 0;
  var ToldAt := -1;
  for var i := 0 to QuietTicks - 1 do
  begin
    Tick;
    if FBurst.DrainEvent = beStruck then
    begin
      Inc(Told);
      ToldAt := i;
      Assert.IsFalse(FBurst.Holding, 'The world stands on the strike');
      Assert.IsTrue(Length(FBurst.Stretches) > 0,
        'No ray is out on the strike');
    end;
  end;

  Assert.AreEqual(1, Told, 'Strikes told');
  Assert.AreEqual(InhaleTicks - 1, ToldAt, 'The tick of the strike');
end;

procedure TOrbBurstTests.TestUnheardStrikeWaitsToBeTold;
begin
  Start(False);
  Run(InhaleTicks + 10);

  Assert.AreEqual<TBurstEvent>(beStruck, FBurst.DrainEvent,
    'The strike unheard is lost');
  Assert.AreEqual<TBurstEvent>(beNone, FBurst.DrainEvent,
    'The strike is told twice');
end;

// ---------------------------------------------------------------------------
// The rays
// ---------------------------------------------------------------------------

procedure TOrbBurstTests.TestStrikeSendsTwentyFourRaysFromTheChest;
begin
  Start(False);
  Inhale;
  Tick;

  var Stretches := FBurst.Stretches;
  Assert.AreEqual(RaysAround, Length(Stretches), 'Rays');
  for var i := 0 to High(Stretches) do
  begin
    Assert.IsTrue(IsNear(Stretches[i].FromX, Stretches[i].FromY,
      Stretches[0].FromX, Stretches[0].FromY),
      Format('Ray %d leaves from another point', [i]));
    Assert.IsTrue(StretchLength(Stretches[i]) > 0,
      Format('Ray %d stands still', [i]));
  end;
  Assert.IsTrue(Distance(Stretches[0].FromX, Stretches[0].FromY, FCenter.X,
    FCenter.Y) <= ChestReach, 'The rays leave far from the chest');
end;

procedure TOrbBurstTests.TestRaysGoEveryFifteenDegreesOneStraightUp;
begin
  Start(False);
  Inhale;
  Tick;

  var Seen: TArray<Boolean>;
  SetLength(Seen, RaysAround);
  for var Stretch in FBurst.Stretches do
  begin
    var Turn := TurnFromUp(PointAt(Stretch.FromX, Stretch.FromY),
      PointAt(Stretch.ToX, Stretch.ToY));
    var Index := Round(Turn / RayApart);
    Assert.IsTrue(Abs(Turn - Index * RayApart) < AngleSlack, Format(
      'A ray goes %.3f degrees from up: not a multiple of %d',
      [Turn, RayApart]));
    Index := Index mod RaysAround;
    Assert.IsFalse(Seen[Index], Format('Two rays go %d degrees from up',
      [Index * RayApart]));
    Seen[Index] := True;
  end;
  Assert.IsTrue(Seen[0], 'No ray goes straight up');
end;

procedure TOrbBurstTests.TestRaysAreAlikeOnEveryTick;
begin
  for var Curl := False to True do
  begin
    Start(Curl);
    Inhale;
    Tick;
    var Chest := PointAt(FBurst.Stretches[0].FromX,
      FBurst.Stretches[0].FromY);
    var Ticks := 0;
    while (Length(FBurst.Stretches) > 0) and (Ticks <= LongestFlight) do
    begin
      var Stretches := FBurst.Stretches;
      var Reach := Distance(Chest.X, Chest.Y, Stretches[0].ToX,
        Stretches[0].ToY);
      for var i := 1 to High(Stretches) do
      begin
        Assert.IsTrue(Abs(StretchLength(Stretches[i]) -
          StretchLength(Stretches[0])) < LengthSlack, Format(
          'Curl %s, tick %d: ray %d flies at another speed',
          [BoolToStr(Curl, True), Ticks, i]));
        Assert.IsTrue(Abs(Distance(Chest.X, Chest.Y, Stretches[i].ToX,
          Stretches[i].ToY) - Reach) < ReachSlack, Format(
          'Curl %s, tick %d: ray %d is out farther or nearer',
          [BoolToStr(Curl, True), Ticks, i]));
      end;
      Tick;
      Inc(Ticks);
    end;
  end;
end;

procedure TOrbBurstTests.TestStretchesJoinIntoTheWayOfEachHead;
begin
  Start(True);
  Inhale;
  var Flight := FlyOut;

  Assert.IsTrue(Flight <= LongestFlight, 'The rays never leave');
  Assert.AreEqual(RaysAround, Length(FWays), 'Ways');
  for var i := 0 to High(FWays) do
  begin
    Assert.IsTrue(Length(FWays[i]) > 2,
      Format('Way %d has a stretch or none', [i]));
    for var j := 0 to High(FWays[i]) - 1 do
      Assert.IsTrue(Distance(FWays[i][j].X, FWays[i][j].Y, FWays[i][j + 1].X,
        FWays[i][j + 1].Y) > 0, Format('Way %d stands still at %d', [i, j]));
  end;
end;

procedure TOrbBurstTests.TestStraightRayKeepsToItsLine;
begin
  Start(False);
  Inhale;
  FlyOut;

  for var i := 0 to High(FWays) do
  begin
    var Origin := FWays[i][0];
    var AlongX: Single := FWays[i][1].X - Origin.X;
    var AlongY: Single := FWays[i][1].Y - Origin.Y;
    var Span := Sqrt(Sqr(AlongX) + Sqr(AlongY));
    for var j := 2 to High(FWays[i]) do
    begin
      var Aside: Single := Abs((FWays[i][j].X - Origin.X) * AlongY -
        (FWays[i][j].Y - Origin.Y) * AlongX) / Span;
      Assert.IsTrue(Aside < LineSlack, Format(
        'Way %d is %.3f units off its line at step %d', [i, Aside, j]));
    end;
  end;
end;

procedure TOrbBurstTests.TestVortexRaysCurlOneWayAndTheCurlDiesOff;
begin
  Start(True);
  Inhale;
  FlyOut;

  var Hand: Integer := Sign(TurnOfSteps(FWays[0], 0));
  Assert.IsTrue(Hand <> 0, 'The first ray does not curl');
  for var i := 0 to High(FWays) do
  begin
    var Turns: TArray<Single>;
    SetLength(Turns, Length(FWays[i]) - 2);
    var Whole: Single := 0;
    for var j := 0 to High(Turns) do
    begin
      Turns[j] := TurnOfSteps(FWays[i], j);
      Assert.IsTrue(Sign(Turns[j]) = Hand,
        Format('Way %d turns the other way at step %d', [i, j]));
      Whole := Whole + Abs(Turns[j]);
    end;

    var LateMost: Single := 0;
    for var j := Max(0, High(Turns) - 4) to High(Turns) do
      LateMost := Max(LateMost, Abs(Turns[j]));
    Assert.IsTrue(Abs(Turns[0]) > 2 * LateMost, Format(
      'Way %d: the curl does not die off (%.4f at first, %.4f at last)',
      [i, Abs(Turns[0]), LateMost]));
    Assert.IsTrue(Whole < Pi / 2,
      Format('Way %d turns a quarter or more', [i]));
  end;
end;

procedure TOrbBurstTests.TestRaysGoThroughMatterAndOffTheScreen;
begin
  for var Curl := False to True do
  begin
    var Kind := BoolToStr(Curl, True);
    Start(Curl);
    Inhale;
    var Flight := FlyOut;

    Assert.IsTrue(Flight <= LongestFlight,
      Format('Curl %s: the rays never leave', [Kind]));
    Assert.AreEqual(RaysAround, Length(FWays),
      Format('Curl %s: ways', [Kind]));
    for var i := 0 to High(FWays) do
    begin
      Assert.IsTrue(GoesThroughMatter(FMatter, FWays[i]),
        Format('Curl %s: way %d never goes into the walls', [Kind, i]));
      Assert.IsFalse(IsOnScreen(FWays[i][High(FWays[i])]),
        Format('Curl %s: way %d ends on the screen', [Kind, i]));
    end;
    FBurst.DrainEvent;
    ExpectQuietFor(QuietTicks, Format('Curl %s, the rays gone', [Kind]));
  end;
end;

// ---------------------------------------------------------------------------
// The marks
// ---------------------------------------------------------------------------

procedure TOrbBurstTests.TestRayMarksTheFaceItGoesInto;
begin
  Start(False);
  Inhale;
  FlyOut;

  var Marks := MarkPlaces;
  Assert.AreEqual(RaysAround, Length(Marks), 'Marks');
  var MarksOfWay: TArray<Integer>;
  SetLength(MarksOfWay, Length(FWays));
  for var i := 0 to High(Marks) do
  begin
    Assert.IsFalse(SolidAt(FMatter, Marks[i].X, Marks[i].Y),
      Format('Mark %d is in the matter', [i]));
    Assert.IsTrue(MatterBeside(FMatter, Marks[i].X, Marks[i].Y),
      Format('Mark %d is far from a face', [i]));
    var Way := WayUnder(Marks[i].X, Marks[i].Y);
    Assert.IsTrue(Way >= 0, Format('Mark %d is on no ray''s way', [i]));
    Inc(MarksOfWay[Way]);
  end;
  for var i := 0 to High(MarksOfWay) do
    Assert.AreEqual(1, MarksOfWay[i], Format('Marks of way %d', [i]));
end;

procedure TOrbBurstTests.TestRayMarksAFaceAgainAfterCrossingASlab;
begin
  FMatter := MatterFromRows(SlabRows);
  Start(False);
  Inhale;
  FlyOut;

  var Marks := MarkPlaces;
  Assert.AreEqual(SlabMarks, Length(Marks), 'Marks');
  var MarksOfWay: TArray<Integer>;
  SetLength(MarksOfWay, Length(FWays));
  for var Mark in Marks do
  begin
    var Way := WayUnder(Mark.X, Mark.Y);
    Assert.IsTrue(Way >= 0,
      Format('A mark at (%.1f, %.1f) is on no ray''s way', [Mark.X, Mark.Y]));
    Inc(MarksOfWay[Way]);
  end;

  for var i := 0 to High(FWays) do
  begin
    var Turn := TurnFromUp(FWays[i][0], FWays[i][1]);
    var FromUp: Single := Turn;
    if FromUp > 180 then
      FromUp := 360 - FromUp;
    var Expected := 1;
    if FromUp <= SlabReach + AngleSlack then
      Expected := 2;
    Assert.AreEqual(Expected, MarksOfWay[i], Format(
      'Marks of way %d, %.0f degrees from up', [i, FromUp]));
  end;
end;

procedure TOrbBurstTests.TestEmptyRoomTakesNoMarks;
begin
  FMatter := EmptyMatter;
  Start(False);
  Inhale;
  var Flight := FlyOut;

  Assert.IsTrue(Flight <= LongestFlight, 'The rays never leave');
  Assert.AreEqual(RaysAround, Length(FWays), 'Ways');
  Assert.AreEqual(0, FBurst.Marks.Count, 'Marks');
end;

procedure TOrbBurstTests.TestMarksStayPutThenMeltAway;
begin
  Start(False);
  Inhale;
  FlyOut;
  var Marks := MarkPlaces;
  Assert.AreEqual(RaysAround, Length(Marks), 'Marks as the rays are gone');

  var StrikeTick := InhaleTicks - 1;
  RunTo(StrikeTick + TwoSeconds);
  var Now := MarkPlaces;
  Assert.AreEqual(Length(Marks), Length(Now), 'Marks two seconds on');
  for var i := 0 to High(Now) do
    Assert.IsTrue(IsNear(Now[i].X, Now[i].Y, Marks[i].X, Marks[i].Y),
      Format('Mark %d has moved', [i]));

  RunTo(StrikeTick + TenSeconds);
  Assert.AreEqual(0, FBurst.Marks.Count, 'Marks ten seconds on');
end;

// ---------------------------------------------------------------------------
// The motes
// ---------------------------------------------------------------------------

procedure TOrbBurstTests.TestMotesComeOutOfThePointsOfTheBody;
begin
  Start(False);
  Inhale;
  Assert.AreEqual(0, FAsked, 'The body was asked for before the strike');
  Tick;
  Assert.AreEqual(1, FAsked, 'The body asked for at the strike');

  var Motes := MotePlaces;
  Assert.IsTrue(Length(Motes) > 0, 'No mote');
  var Used: TArray<Boolean>;
  SetLength(Used, Length(BodyOffsets));
  for var i := 0 to High(Motes) do
  begin
    var Point := -1;
    for var j := 0 to High(BodyOffsets) do
      if IsNear(Motes[i].X, Motes[i].Y, FCenter.X + BodyOffsets[j].X,
        FCenter.Y + BodyOffsets[j].Y) then
        Point := j;
    Assert.IsTrue(Point >= 0,
      Format('Mote %d is on no point of the body', [i]));
    Used[Point] := True;
  end;
  var UsedCount := 0;
  for var Flag in Used do
    if Flag then
      Inc(UsedCount);
  Assert.IsTrue(UsedCount > 1, 'Every mote comes out of one point');

  Run(TwoSeconds);
  Assert.AreEqual(1, FAsked, 'The body asked for again');
end;

procedure TOrbBurstTests.TestWithNoBodyMotesComeOutOfTheChest;
begin
  for var Probed := False to True do
  begin
    if Probed then
      RemakeBurst(NoBody)
    else
      RemakeBurst(nil);
    Start(False);
    Inhale;
    Tick;

    var Motes := MotePlaces;
    var Kind := 'no probe';
    if Probed then
      Kind := 'a probe of no points';
    Assert.IsTrue(Length(Motes) > 0, Format('With %s: no mote', [Kind]));
    for var i := 0 to High(Motes) do
    begin
      Assert.IsTrue(IsNear(Motes[i].X, Motes[i].Y, Motes[0].X, Motes[0].Y),
        Format('With %s: mote %d comes out of another point', [Kind, i]));
      Assert.IsTrue(Distance(Motes[i].X, Motes[i].Y, FCenter.X,
        FCenter.Y) <= ChestReach,
        Format('With %s: mote %d is far from the chest', [Kind, i]));
    end;
  end;
end;

procedure TOrbBurstTests.TestMotesLiveAWhileThenGo;
begin
  Start(False);
  Inhale;
  Tick;
  var Born := FBurst.Motes.Count;
  var Birth := MotePlaces;

  Tick;
  var Moved := MotePlaces;
  Assert.AreEqual(Born, Length(Moved), 'Motes a tick on');
  for var i := 0 to High(Moved) do
    Assert.IsFalse(IsNear(Moved[i].X, Moved[i].Y, Birth[i].X, Birth[i].Y),
      Format('Mote %d stands where it was born', [i]));

  var StrikeTick := InhaleTicks - 1;
  RunTo(StrikeTick + HalfSecond);
  Assert.AreEqual(Born, FBurst.Motes.Count, 'Motes half a second on');
  RunTo(StrikeTick + TenSeconds);
  Assert.AreEqual(0, FBurst.Motes.Count, 'Motes ten seconds on');
end;

// ---------------------------------------------------------------------------
// The hero, the restarts, the dice
// ---------------------------------------------------------------------------

procedure TOrbBurstTests.TestRaysLeaveFromTheHeroAtTheStrikeAndDoNotFollowHim;
begin
  Start(False);
  FWalk := LeapStep;
  Inhale;
  FlyOut;

  var StrikeX: Single := StandX + InhaleTicks * LeapStep;
  var Chest := FWays[0][0];
  Assert.IsTrue(Distance(Chest.X, Chest.Y, StrikeX, StandY) <= ChestReach,
    'The rays do not leave from the hero at the strike');
  Assert.IsTrue(Distance(Chest.X, Chest.Y, StandX, StandY) > ChestReach,
    'The rays leave from where the burst began');

  for var i := 0 to High(FWays) do
  begin
    var AlongX: Single := FWays[i][1].X - Chest.X;
    var AlongY: Single := FWays[i][1].Y - Chest.Y;
    var Span := Sqrt(Sqr(AlongX) + Sqr(AlongY));
    for var j := 2 to Min(High(FWays[i]), High(FWays[0])) do
    begin
      var Aside: Single := Abs((FWays[i][j].X - Chest.X) * AlongY -
        (FWays[i][j].Y - Chest.Y) * AlongX) / Span;
      Assert.IsTrue(Aside < LineSlack,
        Format('Way %d follows the hero at step %d', [i, j]));
      Assert.IsTrue(Abs(Distance(Chest.X, Chest.Y, FWays[i][j].X,
        FWays[i][j].Y) - Distance(Chest.X, Chest.Y, FWays[0][j].X,
        FWays[0][j].Y)) < ReachSlack,
        Format('Way %d is drawn by the hero at step %d', [i, j]));
    end;
  end;
end;

procedure TOrbBurstTests.TestClearLeavesNothingAndNothingComes;
begin
  Start(False);
  Inhale;
  Assert.IsTrue(FBurst.Holding, 'Before the clear in the inhale');
  FBurst.Clear;
  Assert.IsFalse(FBurst.Holding, 'Cleared in the inhale: holding');
  Assert.IsFalse(FBurst.Inhaling, 'Cleared in the inhale: inhaling');
  ExpectQuietFor(QuietTicks, 'Cleared in the inhale');
  Assert.AreEqual(0, FAsked, 'Cleared in the inhale: the body asked for');

  Start(False);
  Inhale;
  Run(6);
  Assert.IsTrue(FBurst.Marks.Count > 0, 'No mark before the clear in flight');
  Assert.IsTrue(FBurst.Motes.Count > 0, 'No mote before the clear in flight');
  FBurst.Clear;
  Assert.AreEqual(0, Length(FBurst.Stretches), 'Cleared in flight: stretches');
  Assert.AreEqual(0, FBurst.Marks.Count, 'Cleared in flight: marks');
  Assert.AreEqual(0, FBurst.Motes.Count, 'Cleared in flight: motes');
  Assert.AreEqual<TBurstEvent>(beNone, FBurst.DrainEvent,
    'Cleared in flight: the strike unheard is still told');
  ExpectQuietFor(QuietTicks, 'Cleared in flight');
  Assert.AreEqual(0, FBurst.Marks.Count, 'Cleared in flight: marks after');
  Assert.AreEqual(0, FBurst.Motes.Count, 'Cleared in flight: motes after');
end;

procedure TOrbBurstTests.TestStartDropsTheBurstAlreadyGoing;
begin
  Start(False);
  Inhale;
  Run(6);
  Assert.IsTrue(FBurst.Marks.Count > 0, 'No mark of the first burst');

  FCenter := PointAt(StandX - 100, StandY);
  Start(False);
  Assert.IsTrue(FBurst.Holding, 'The new burst does not inhale');
  Assert.AreEqual<TBurstEvent>(beNone, FBurst.DrainEvent,
    'The strike of the first burst is told');
  Assert.AreEqual(0, Length(FBurst.Stretches), 'Stretches of the first');
  Assert.AreEqual(0, FBurst.Marks.Count, 'Marks of the first');
  Assert.AreEqual(0, FBurst.Motes.Count, 'Motes of the first');

  Inhale;
  Assert.AreEqual(0, Length(FBurst.Stretches),
    'The rays of the first fly through the new inhale');
  Tick;
  var Stretches := FBurst.Stretches;
  Assert.AreEqual(RaysAround, Length(Stretches), 'Rays of the new burst');
  for var Stretch in Stretches do
    Assert.IsTrue(Distance(Stretch.FromX, Stretch.FromY, FCenter.X,
      FCenter.Y) <= ChestReach, 'A ray leaves from the first burst''s hero');
  Assert.AreEqual<TBurstEvent>(beStruck, FBurst.DrainEvent,
    'The new strike');
  Assert.AreEqual<TBurstEvent>(beNone, FBurst.DrainEvent,
    'A strike told twice');
end;

procedure TOrbBurstTests.TestMoonBurstFliesAsTheIceOne;
begin
  FMatter := MatterFromRows(SlabRows);
  FTwin := TOrbBurst.Create(BodyAboutHero);
  FBurst.Start(IceBurstLook, True, FCenter, FMatter);
  FTwin.Start(MoonBurstLook, True, FCenter, FMatter);

  for var i := 0 to InhaleTicks + LongestFlight do
  begin
    Tick;
    ExpectSameAsTwin(i);
    Assert.AreEqual<TBurstEvent>(FTwin.DrainEvent, FBurst.DrainEvent,
      Format('Tick %d: told', [i]));
  end;
end;

procedure TOrbBurstTests.TestSameCallsGiveTheSameBurst;
begin
  FMatter := MatterFromRows(SlabRows);
  FTwin := TOrbBurst.Create(BodyAboutHero);
  FWalk := 1;
  FBurst.Start(IceBurstLook, True, FCenter, FMatter);
  FTwin.Start(IceBurstLook, True, FCenter, FMatter);

  for var i := 0 to InhaleTicks + TenSeconds do
  begin
    Tick;
    ExpectSameAsTwin(i);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TOrbBurstTests);

end.
