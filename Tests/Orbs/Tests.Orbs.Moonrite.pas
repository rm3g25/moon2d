{
  Tests.Orbs.Moonrite - the rite of the eclipse ticked without a window: it
  stands till started; its rings have sixty seats; the calls come one at a
  time at an even gap between two heartbeats, each beat shortens the gap
  and none makes it shorter than the last; every orb sits, the ring is full
  once and stands full until it is told to draw in; what has gathered only
  grows; an orb off a face is born in the matter, never near the hero and
  from far off as well, every fourth comes out of the depth a speck behind
  him, the calls come from all sides; the
  ring beats with the heart and keeps to the hero as he moves; no orb is
  ever armed; told to draw in, the orbs go into his body and the rite is
  over; with no matter about him they come out of thin air; a collapse ends
  it with nothing told, a clear takes it all away.

  The rite is handed what the heart does each tick, so a test beats where
  it likes. The hero is a point the test moves; his body is five points
  about it. How it all looks - the spiral of a flight, the swell on a
  thump, the speck growing out of the depth - is for the eye.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Orbs.Moonrite;

interface

uses
  DUnitX.TestFramework, System.Generics.Collections, Sdl2.Core, Orbs.Flock,
  Orbs.Harvest, Orbs.Patterns, Orbs.Rite, Orbs.Moonrite;

type
  [TestFixture]
  TMoonRiteTests = class
  private
    FRite: TMoonRite;
    FMatter: TMatter;
    FDeep: TArray<TSdlFPoint>;
    // The hero's middle, where the next tick finds it
    FCenter: TSdlFPoint;
    // Ticks gone by since the start: the number of the next one, from 0
    FTicks: Integer;
    FTold: TList<TMoonRiteEvent>;
    function BodyAboutHero: TBodyPoints;
    procedure Start;
    procedure Tick(AStruck: Boolean = False; APulse: Single = 0);
    // Ticks with a beat on every ABeatEvery-th, none for 0
    procedure Run(ACount, ABeatEvery: Integer);
    // Till the ring is told full; the ticks it took
    function RunToFull(ABeatEvery: Integer): Integer;
    function Told(AEvent: TMoonRiteEvent): Integer;
    function Orbs: TObjectList<TOrb>;
    // The ticks the calls came on over ACount ticks; AStruckAt - the ticks
    // the heart beats on
    function CallTicks(ACount: Integer;
      const AStruckAt: array of Integer): TArray<Integer>;
    // The orbs born in the next tick
    function BornInTick(AStruck: Boolean): TArray<TOrb>;
    function FromChest(const AOrb: TOrb): Single;
    // How far from the chest the orbs sit, in the order of the flock
    function Distances: TArray<Single>;
    function FromCenter(const AOrb: TOrb): Single;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestStandsTillStarted;
    [Test]
    procedure TestTheRingsHaveSixtySeats;
    [Test]
    procedure TestCallsOneAtATimeAtAnEvenGapBetweenBeats;
    [Test]
    procedure TestABeatShortensTheGap;
    [Test]
    procedure TestTheGapIsNeverShorterThanTheLast;
    [Test]
    procedure TestEveryOrbSitsAndTheRingIsFullOnce;
    [Test]
    procedure TestNotToldItStandsRinged;
    [Test]
    procedure TestWhatHasGatheredOnlyGrows;
    [Test]
    procedure TestAnOrbOffAFaceIsBornInTheMatter;
    [Test]
    procedure TestNoOrbComesOffAFaceNearHim;
    [Test]
    procedure TestEveryFourthComesOutOfTheDeep;
    [Test]
    procedure TestTheCallsComeFromAllSides;
    [Test]
    procedure TestTheRingBeatsWithTheHeart;
    [Test]
    procedure TestTheRingKeepsToTheHero;
    [Test]
    procedure TestNoOrbIsEverArmed;
    [Test]
    procedure TestToldToDrawInTheOrbsGoIntoHim;
    [Test]
    procedure TestOutOfThinAirWithNoMatter;
    [Test]
    procedure TestACollapseEndsItWithNothingTold;
    [Test]
    procedure TestAClearTakesItAllAway;
  end;

implementation

uses
  System.SysUtils, System.Math, Tests.Matter;

const
  // Ticks
  TestScore: TMoonRiteScore = (FirstGap: 12; LastGap: 2; GapStep: 0.75;
    DeepEvery: 4; Nearest: 112; CollapseTicks: 20);
  RingSeats = 60;
  // The middle of the room, and the middle of the rings from his
  Middle: TSdlFPoint = (X: 256; Y: 192);
  ChestY = -2;
  // Long enough for any ring to fill at the slowest pace and stand a while
  LongRun = 600;
  // The heart at about the rite's pace, a beat every this many ticks
  BeatEvery = 15;
  PlaceSlack = 0.01;
  // His body, from his middle
  BodyOffsets: array [0..4] of TSdlFPoint = ((X: 0; Y: -12), (X: -6; Y: -2),
    (X: 6; Y: -2), (X: -4; Y: 12), (X: 4; Y: 12));

function PointAt(AX, AY: Single): TSdlFPoint;
begin
  Result.X := AX;
  Result.Y := AY;
end;

procedure TMoonRiteTests.Setup;
begin
  FRite := TMoonRite.Create(
    function: TBodyPoints
    begin
      Result := BodyAboutHero;
    end);
  FTold := TList<TMoonRiteEvent>.Create;
  FMatter := WalledMatter;
  FDeep := [];
  FCenter := Middle;
  FTicks := 0;
end;

procedure TMoonRiteTests.TearDown;
begin
  FTold.Free;
  FRite.Free;
end;

function TMoonRiteTests.BodyAboutHero: TBodyPoints;
begin
  SetLength(Result, Length(BodyOffsets));
  for var i := 0 to High(BodyOffsets) do
  begin
    Result[i].X := FCenter.X + BodyOffsets[i].X;
    Result[i].Y := FCenter.Y + BodyOffsets[i].Y;
  end;
end;

procedure TMoonRiteTests.Start;
begin
  FRite.Start(FindPattern(EclipsePatternName), TestScore, FCenter, FMatter,
    FDeep);
  FTicks := 0;
  FTold.Clear;
end;

procedure TMoonRiteTests.Tick(AStruck: Boolean; APulse: Single);
begin
  var Beat: TRiteBeat;
  Beat.Struck := AStruck;
  Beat.Pulse := APulse;
  FRite.Tick(FCenter, Beat);
  var Event := FRite.DrainEvent;
  while Event <> mvNone do
  begin
    FTold.Add(Event);
    Event := FRite.DrainEvent;
  end;
  Inc(FTicks);
end;

procedure TMoonRiteTests.Run(ACount, ABeatEvery: Integer);
begin
  for var i := 1 to ACount do
    Tick((ABeatEvery > 0) and (FTicks mod ABeatEvery = 0));
end;

function TMoonRiteTests.RunToFull(ABeatEvery: Integer): Integer;
begin
  while (Told(mvFull) = 0) and (FTicks < LongRun) do
    Run(1, ABeatEvery);
  Assert.AreEqual(1, Told(mvFull), 'The ring never filled');
  Result := FTicks;
end;

function TMoonRiteTests.Told(AEvent: TMoonRiteEvent): Integer;
begin
  Result := 0;
  for var Event in FTold do
    if Event = AEvent then
      Inc(Result);
end;

function TMoonRiteTests.Orbs: TObjectList<TOrb>;
begin
  Result := FRite.Flock.Orbs;
end;

function TMoonRiteTests.CallTicks(ACount: Integer;
  const AStruckAt: array of Integer): TArray<Integer>;
begin
  Result := [];
  for var i := 0 to ACount - 1 do
  begin
    var Struck := False;
    for var At in AStruckAt do
      if At = FTicks then
        Struck := True;
    var Before := Orbs.Count;
    var ThisTick := FTicks;
    Tick(Struck);
    if Orbs.Count > Before then
      Result := Result + [ThisTick];
    Assert.IsTrue(Orbs.Count - Before <= 1,
      Format('%d orbs called on tick %d', [Orbs.Count - Before, ThisTick]));
  end;
end;

function TMoonRiteTests.BornInTick(AStruck: Boolean): TArray<TOrb>;
begin
  var Before := Orbs.Count;
  Tick(AStruck);
  Result := [];
  for var i := Before to Orbs.Count - 1 do
    Result := Result + [Orbs[i]];
end;

function TMoonRiteTests.FromChest(const AOrb: TOrb): Single;
begin
  Result := Hypot(AOrb.X - FCenter.X, AOrb.Y - (FCenter.Y + ChestY));
end;

function TMoonRiteTests.Distances: TArray<Single>;
begin
  SetLength(Result, Orbs.Count);
  for var i := 0 to Orbs.Count - 1 do
    Result[i] := FromChest(Orbs[i]);
end;

function TMoonRiteTests.FromCenter(const AOrb: TOrb): Single;
begin
  Result := Hypot(AOrb.X - FCenter.X, AOrb.Y - FCenter.Y);
end;

procedure TMoonRiteTests.TestStandsTillStarted;
begin
  Run(LongRun, BeatEvery);
  Assert.AreEqual(0, Orbs.Count, 'No orb');
  Assert.AreEqual(0, FTold.Count, 'Nothing told');
  Assert.IsTrue(FRite.Stage = mgIdle, 'Idle');
  Assert.AreEqual(0, FRite.Count, 'No seats');
end;

procedure TMoonRiteTests.TestTheRingsHaveSixtySeats;
begin
  Start;
  Assert.AreEqual(RingSeats, FRite.Count);
end;

procedure TMoonRiteTests.TestCallsOneAtATimeAtAnEvenGapBetweenBeats;
const
  Gap = 12;
begin
  Start;
  var Calls := CallTicks(5 * Gap, []);
  Assert.AreEqual(5, Length(Calls), 'Calls');
  for var i := 0 to High(Calls) do
    Assert.AreEqual(i * Gap, Calls[i], Format('Call %d', [i]));
end;

procedure TMoonRiteTests.TestABeatShortensTheGap;
const
  // 12, and three quarters of it after the beat
  Expected: array [0..3] of Integer = (0, 12, 21, 30);
  BeatAt = 13;
begin
  Start;
  var Calls := CallTicks(31, [BeatAt]);
  Assert.AreEqual(Length(Expected), Length(Calls), 'Calls');
  for var i := 0 to High(Expected) do
    Assert.AreEqual(Expected[i], Calls[i], Format('Call %d', [i]));
end;

procedure TMoonRiteTests.TestTheGapIsNeverShorterThanTheLast;
const
  Shortest = 2;
  // A beat every tick: the gap is at its shortest after a few
  Settle = 40;
  Look = 20;
begin
  Start;
  var EveryTick: TArray<Integer> := [];
  for var i := 0 to Settle + Look do
    EveryTick := EveryTick + [i];
  var Calls := CallTicks(Settle + Look, EveryTick);
  var Late := 0;
  for var i := 1 to High(Calls) do
  begin
    Assert.IsTrue(Calls[i] - Calls[i - 1] >= Shortest,
      Format('Calls %d ticks apart at %d', [Calls[i] - Calls[i - 1], Calls[i]]));
    if Calls[i] > Settle then
    begin
      Assert.AreEqual(Shortest, Calls[i] - Calls[i - 1],
        Format('At its shortest by %d', [Calls[i]]));
      Inc(Late);
    end;
  end;
  Assert.IsTrue(Late > 0, 'No call after the gap settled');
end;

procedure TMoonRiteTests.TestEveryOrbSitsAndTheRingIsFullOnce;
begin
  Start;
  RunToFull(BeatEvery);
  Assert.AreEqual(RingSeats, FRite.Gathered, 'Gathered');
  Assert.IsTrue(FRite.Stage = mgRinged, 'Ringed');
  Assert.AreEqual(RingSeats, Orbs.Count, 'Orbs');
  var Pattern := FindPattern(EclipsePatternName);
  var Inner := Hypot(Pattern.Seat(0, 0, Pattern.PerWave, 0).X,
    Pattern.Seat(0, 0, Pattern.PerWave, 0).Y - ChestY);
  var Outer := Hypot(Pattern.Seat(1, 0, Pattern.PerWave, 0).X,
    Pattern.Seat(1, 0, Pattern.PerWave, 0).Y - ChestY);
  var OnInner := 0;
  for var i := 0 to Orbs.Count - 1 do
  begin
    var Away := FromChest(Orbs[i]);
    var OnARing := (Abs(Away - Inner) < PlaceSlack) or
      (Abs(Away - Outer) < PlaceSlack);
    Assert.IsTrue(OnARing, Format('Orb %d is off the rings: %g', [i, Away]));
    if Abs(Away - Inner) < PlaceSlack then
      Inc(OnInner);
    for var j := i + 1 to Orbs.Count - 1 do
      Assert.IsTrue(Hypot(Orbs[i].X - Orbs[j].X, Orbs[i].Y - Orbs[j].Y) > 1,
        Format('Orbs %d and %d share a seat', [i, j]));
  end;
  Assert.AreEqual(RingSeats div 2, OnInner, 'Half on the inner ring');
  Run(LongRun, BeatEvery);
  Assert.AreEqual(1, Told(mvFull), 'Told once');
end;

procedure TMoonRiteTests.TestNotToldItStandsRinged;
begin
  Start;
  RunToFull(BeatEvery);
  Run(LongRun, BeatEvery);
  Assert.IsTrue(FRite.Stage = mgRinged, 'Ringed');
  Assert.AreEqual(RingSeats, Orbs.Count, 'Orbs');
  Assert.AreEqual(1, FTold.Count, 'Nothing told but the full ring');
end;

procedure TMoonRiteTests.TestWhatHasGatheredOnlyGrows;
begin
  Start;
  var Last := 0;
  for var i := 1 to LongRun do
  begin
    Run(1, BeatEvery);
    Assert.IsTrue(FRite.Gathered >= Last, Format('Fewer at %d', [i]));
    Assert.IsTrue(FRite.Gathered <= FRite.Count, Format('Too many at %d', [i]));
    Last := FRite.Gathered;
    if Told(mvFull) > 0 then
      FRite.DrawIn;
  end;
  Assert.AreEqual(RingSeats, Last, 'Kept through the drawing in');
end;

procedure TMoonRiteTests.TestAnOrbOffAFaceIsBornInTheMatter;
begin
  Start;
  var Born := 0;
  while FTicks < LongRun do
  begin
    for var Orb in BornInTick(FTicks mod BeatEvery = 0) do
    begin
      Assert.IsTrue(SolidAt(FMatter, Orb.X, Orb.Y),
        Format('Born in the open at %g, %g', [Orb.X, Orb.Y]));
      Inc(Born);
    end;
  end;
  Assert.AreEqual(RingSeats, Born, 'All of them off the faces');
end;

// He stands by the floor, its faces under him and to his sides within
// reach: none of them gives an orb, the far walls and the ceiling do
procedure TMoonRiteTests.TestNoOrbComesOffAFaceNearHim;
const
  // A face orb is born a little under its face
  Sunk = 3;
begin
  FCenter := PointAt(256, 336);
  Start;
  var Farthest: Single := 0;
  while FTicks < LongRun do
    for var Orb in BornInTick(FTicks mod BeatEvery = 0) do
    begin
      var Away := FromCenter(Orb);
      Assert.IsTrue(Away > TestScore.Nearest - Sunk,
        Format('Born %g units from him', [Away]));
      if Away > Farthest then
        Farthest := Away;
    end;
  // Some come from twice as far as the nearest an orb may
  Assert.IsTrue(Farthest > 2 * TestScore.Nearest,
    Format('None farther than %g', [Farthest]));
end;

procedure TMoonRiteTests.TestEveryFourthComesOutOfTheDeep;
const
  // A flight just begun has gone about nowhere yet
  NearItsPoint = 2;
  Speck = 0.2;
begin
  FDeep := [PointAt(96, 250), PointAt(300, 240), PointAt(420, 246)];
  Start;
  var Called := 0;
  while FTicks < LongRun do
    for var Orb in BornInTick(FTicks mod BeatEvery = 0) do
    begin
      Inc(Called);
      var Nearest: Single := MaxSingle;
      for var Point in FDeep do
      begin
        var Away: Single := Hypot(Orb.X - Point.X, Orb.Y - Point.Y);
        if Away < Nearest then
          Nearest := Away;
      end;
      if Called mod TestScore.DeepEvery = 0 then
      begin
        Assert.IsTrue(Nearest < NearItsPoint,
          Format('Call %d is %g units from the depth', [Called, Nearest]));
        Assert.IsTrue(Orb.Size < Speck, Format('Call %d is born big', [Called]));
        Assert.IsTrue(Orb.Depth < 0, Format('Call %d is not born behind him', [Called]));
      end
      else
        Assert.IsTrue(SolidAt(FMatter, Orb.X, Orb.Y),
          Format('Call %d is not born in the matter', [Called]));
    end;
  Assert.AreEqual(RingSeats, Called, 'Calls');
end;

// One after another they come from far round the hero, left and right
procedure TMoonRiteTests.TestTheCallsComeFromAllSides;
const
  Looked = 8;
  LeastTurn = Pi / 4;
begin
  Start;
  var Turns: TArray<Single> := [];
  while Length(Turns) < Looked do
    for var Orb in BornInTick(False) do
    begin
      var Turn: Single := ArcTan2(Orb.Y - FCenter.Y, Orb.X - FCenter.X);
      Turns := Turns + [Turn];
    end;

  var Lefts := 0;
  for var i := 0 to High(Turns) do
  begin
    if Cos(Turns[i]) < 0 then
      Inc(Lefts);
    if i = 0 then
      Continue;
    var Turned := Turns[i] - Turns[i - 1];
    var Apart := Abs(ArcTan2(Sin(Turned), Cos(Turned)));
    Assert.IsTrue(Apart > LeastTurn,
      Format('Calls %d and %d come from one side: %g apart', [i - 1, i, Apart]));
  end;
  Assert.IsTrue((Lefts > 0) and (Lefts < Looked), 'All from one half');
end;

procedure TMoonRiteTests.TestTheRingBeatsWithTheHeart;
const
  // The ring draws in by an eighth or so on a thump
  LeastDrawIn = 0.05;
begin
  Start;
  RunToFull(BeatEvery);
  Tick(False, 0);
  var Still: Single := 0;
  for var Orb in Orbs do
    Still := Still + FromCenter(Orb) / Orbs.Count;
  Tick(True, 1);
  var Thump: Single := 0;
  for var Orb in Orbs do
    Thump := Thump + FromCenter(Orb) / Orbs.Count;
  Assert.IsTrue(Thump < Still * (1 - LeastDrawIn),
    Format('%g units on the thump, %g still', [Thump, Still]));
  Tick(False, 0);
  var After: Single := 0;
  for var Orb in Orbs do
    After := After + FromCenter(Orb) / Orbs.Count;
  Assert.AreEqual(Double(Still), Double(After), PlaceSlack, 'Out again');
end;

procedure TMoonRiteTests.TestTheRingKeepsToTheHero;
const
  Steps = 20;
begin
  Start;
  RunToFull(BeatEvery);
  var Before := Distances;
  for var i := 1 to Steps do
  begin
    FCenter.X := FCenter.X + 1.5;
    FCenter.Y := FCenter.Y - 1;
    Tick;
    var After := Distances;
    for var j := 0 to High(After) do
      Assert.AreEqual(Double(Before[j]), Double(After[j]), PlaceSlack,
        Format('Orb %d left behind on step %d', [j, i]));
  end;
end;

procedure TMoonRiteTests.TestNoOrbIsEverArmed;
begin
  FDeep := [PointAt(96, 250)];
  Start;
  for var i := 1 to LongRun do
  begin
    Run(1, BeatEvery);
    if (Told(mvFull) > 0) and (FRite.Stage = mgRinged) then
      FRite.DrawIn;
    for var Orb in Orbs do
      Assert.IsFalse(Orb.Armed, Format('Armed at %d', [i]));
  end;
end;

procedure TMoonRiteTests.TestToldToDrawInTheOrbsGoIntoHim;
begin
  Start;
  RunToFull(BeatEvery);
  FRite.DrawIn;
  Tick;
  Assert.AreEqual(1, Told(mvDrawingIn), 'Told it draws in');
  Assert.IsTrue(FRite.Stage = mgDrawingIn, 'Drawing in');
  var Body := BodyAboutHero;
  Run(TestScore.CollapseTicks, 0);
  Assert.AreEqual(1, Told(mvFinished), 'Over by its time');
  Assert.IsTrue(FRite.Stage = mgIdle, 'Idle');
  for var Orb in Orbs do
  begin
    var Nearest: Single := MaxSingle;
    for var Point in Body do
    begin
      var Away: Single := Hypot(Orb.X - Point.X, Orb.Y - Point.Y);
      if Away < Nearest then
        Nearest := Away;
    end;
    Assert.IsTrue(Nearest < PlaceSlack,
      Format('An orb ends %g units off his body', [Nearest]));
  end;
  Tick;
  Assert.AreEqual(0, Orbs.Count, 'All gone');
  Run(LongRun, BeatEvery);
  Assert.AreEqual(1, Told(mvFinished), 'Over once');
  Assert.AreEqual(0, Orbs.Count, 'Nothing called after');
end;

procedure TMoonRiteTests.TestOutOfThinAirWithNoMatter;
begin
  FMatter := EmptyMatter;
  Start;
  RunToFull(BeatEvery);
  Assert.AreEqual(RingSeats, FRite.Gathered);
end;

procedure TMoonRiteTests.TestACollapseEndsItWithNothingTold;
const
  // An imploding orb is gone in under this many ticks
  ImplodeWait = 12;
begin
  Start;
  Run(LongRun div 10, BeatEvery);
  Assert.IsTrue(Orbs.Count > 0, 'Orbs called');
  FRite.Collapse;
  Assert.IsTrue(FRite.Stage = mgIdle, 'Idle');
  Run(ImplodeWait, BeatEvery);
  Assert.AreEqual(0, Orbs.Count, 'All gone');
  Assert.AreEqual(0, FTold.Count, 'Nothing told');
end;

procedure TMoonRiteTests.TestAClearTakesItAllAway;
begin
  Start;
  RunToFull(BeatEvery);
  FRite.DrawIn;
  FRite.Clear;
  FTold.Clear;
  Assert.AreEqual(0, Orbs.Count, 'No orb');
  Assert.AreEqual(0, FRite.Gathered, 'Nothing gathered');
  Assert.AreEqual(0, FRite.Count, 'No seats');
  Assert.IsTrue(FRite.Stage = mgIdle, 'Idle');
  Run(LongRun, BeatEvery);
  Assert.AreEqual(0, FTold.Count, 'Nothing told after');
  Assert.AreEqual(0, Orbs.Count, 'Nothing called after');
end;

initialization
  TDUnitX.RegisterTestFixture(TMoonRiteTests);

end.
