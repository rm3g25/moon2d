{
  Tests.Game.Titles - the titles' clock and what it tells: it runs only
  once started, and never without titles to play; by the ticks alone a
  second is thirty-three of them; it leans toward the track by half a tick
  at the most, comes to it, never goes back, and a track far off takes it at
  once. The flash comes once, on the tick the clock reaches its cue, a jump
  past the cue included; the logo stands from then on, and the white of
  the flash is gone in its ticks. The card comes in and is gone by its
  out, before the flash. A clear stops it, and it can start again.

  Titles with a path fly: the flight starts once, on the tick the clock
  reaches its cue - a jump past the flash and the cue gives both - and its
  own seconds run from the cue, zero before it. In the flight the clock
  goes by the ticks alone, a track close by leaning it no more, and a
  track far off takes it still. The eye goes the path by the flight's
  seconds and stands where the world stood before it. The flight ends
  once, where the eye leaves its rest, the frame gone dark over the second
  before; a clear ends it. Titles without a path never fly.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Game.Titles;

interface

uses
  DUnitX.TestFramework,
  Levels.EyePath, Levels.Titles, Game.Titles;

type
  [TestFixture]
  TTitlesTests = class
  private
    FTitles: TTitles;
    procedure Run(ATicks: Integer);
    // Ticks by the ticks alone till the clock is past ASeconds; how many
    // times the flash came
    function RunPast(ASeconds: Double): Integer;
    // Ticks on to the tick the flash comes
    procedure RunToFlash;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestNotStartedItDoesNotRun;
    [Test]
    procedure TestWithoutTitlesStartStartsNothing;
    [Test]
    procedure TestStartingTwiceDoesNotSetTheClockBack;
    [Test]
    procedure TestByTicksASecondIsThirtyThreeTicks;
    [Test]
    procedure TestBetweenTicksTheClockLiesBetweenThem;
    [Test]
    procedure TestTheClockLeansTowardTheTrackByHalfATickAtTheMost;
    [Test]
    procedure TestTheClockComesToATrackCloseBy;
    [Test]
    procedure TestTheClockNeverGoesBack;
    [Test]
    procedure TestATrackFarOffTakesTheClockAtOnce;
    [Test]
    procedure TestTheFlashComesOnceAtItsCue;
    [Test]
    procedure TestAJumpPastTheFlashStillFlashes;
    [Test]
    procedure TestTheLogoStandsFromTheFlash;
    [Test]
    procedure TestTheWhiteOfTheFlashIsGoneInItsTicks;
    [Test]
    procedure TestTheCardComesInAndIsGoneByItsOut;
    [Test]
    procedure TestNotRunningNothingShows;
    [Test]
    procedure TestClearStopsItAndItCanStartAgain;
    [Test]
    procedure TestTheNextCueIsTheFirstPastASecond;
    [Test]
    procedure TestWithoutAPathTheTitlesNeverFly;
  end;

  [TestFixture]
  TTitlesFlightTests = class
  private
    FTitles: TTitles;
    // Ticks by the ticks alone till the flight starts; how many ticks
    function RunToFlight: Integer;
    // Ticks by the ticks alone till the flight's own clock is past ASeconds
    procedure FlyPast(ASeconds: Double);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestTheFlightStartsOnceAtItsCue;
    [Test]
    procedure TestAJumpPastTheFlashAndTheFlightGivesBoth;
    [Test]
    procedure TestBeforeTheFlightItsSecondsAreZero;
    [Test]
    procedure TestTheFlightsSecondsRunFromItsCue;
    [Test]
    procedure TestInTheFlightTheClockLeansNoMore;
    [Test]
    procedure TestInTheFlightATrackFarOffTakesTheClockStill;
    [Test]
    procedure TestBeforeTheFlightTheEyeStandsWhereTheWorldStood;
    [Test]
    procedure TestTheEyeGoesThePathByTheFlightsSeconds;
    [Test]
    procedure TestTheFlightEndsOnceWhereTheEyeLeavesItsRest;
    [Test]
    procedure TestTheFrameGoesDarkOverTheLastSecond;
    [Test]
    procedure TestClearEndsTheFlight;
  end;

implementation

const
  Tick = 1 / TitlesTicksPerSecond;
  ClockSlack = 1e-9;
  LevelSlack = 0.0001;
  // The titles of the tests, on whole seconds
  CardCue = 10.0;
  CardOutCue = 16.0;
  FlashCue = 17.0;
  // Well past the last of the cues
  LongAfter = 180.0;
  // The flight of the tests: the camera leaves two seconds after the
  // flash, casts off to the left at its rest and lifts from RestTill on
  FlightCue = 19.0;
  CastOffSeconds = 4.0;
  CastOffWay = -100.0;
  RestTill = 6.0;
  RestTillWay = -300.0;
  LiftedSeconds = 9.0;
  LiftedWay = -500.0;
  Lifted = 40.0;
  // Where the world of the tests stands
  Stand = 2400.0;

function TestTitles: TTitlesDef;
begin
  Result := Default(TTitlesDef);
  Result.Present := True;
  Result.Cues.Card := CardCue;
  Result.Cues.CardOut := CardOutCue;
  Result.Cues.Flash := FlashCue;
end;

// A key so far from where the world stood, lifted ALift
function KeyFromStand(ASeconds, AWay, ALift: Double): TEyeKey;
begin
  Result := Default(TEyeKey);
  Result.Seconds := ASeconds;
  Result.Placing := epFromStand;
  Result.Place := AWay;
  Result.Lift := ALift;
end;

function FlyingTitles: TTitlesDef;
begin
  Result := TestTitles;
  Result.Cues.Flight := FlightCue;
  Result.Path.Keys := [KeyFromStand(0, 0, 0),
    KeyFromStand(CastOffSeconds, CastOffWay, 0),
    KeyFromStand(RestTill, RestTillWay, 0),
    KeyFromStand(LiftedSeconds, LiftedWay, Lifted)];
end;

procedure TTitlesTests.Setup;
begin
  FTitles := TTitles.Create;
  FTitles.Arm(TestTitles);
end;

procedure TTitlesTests.TearDown;
begin
  FTitles.Free;
end;

procedure TTitlesTests.Run(ATicks: Integer);
begin
  for var i := 1 to ATicks do
    FTitles.Tick(NoTrackSeconds);
end;

function TTitlesTests.RunPast(ASeconds: Double): Integer;
begin
  Result := 0;
  while FTitles.Seconds <= ASeconds do
    if FTitles.Tick(NoTrackSeconds).Flashes then
      Inc(Result);
end;

procedure TTitlesTests.RunToFlash;
begin
  repeat
  until FTitles.Tick(NoTrackSeconds).Flashes;
end;

procedure TTitlesTests.TestNotStartedItDoesNotRun;
begin
  Assert.IsFalse(FTitles.Running, 'Armed is not running');
  Run(TitlesTicksPerSecond);
  Assert.AreEqual(0.0, FTitles.Seconds, ClockSlack, 'The clock stands');
end;

procedure TTitlesTests.TestWithoutTitlesStartStartsNothing;
begin
  FTitles.Arm(Default(TTitlesDef));
  FTitles.Start;
  Assert.IsFalse(FTitles.Running, 'A level without titles');
end;

procedure TTitlesTests.TestStartingTwiceDoesNotSetTheClockBack;
begin
  FTitles.Start;
  Run(10);
  FTitles.Start;
  Assert.AreEqual(10 * Tick, FTitles.Seconds, ClockSlack, 'Where it was');
end;

procedure TTitlesTests.TestByTicksASecondIsThirtyThreeTicks;
begin
  FTitles.Start;
  Assert.IsTrue(FTitles.Running, 'Started');
  Run(TitlesTicksPerSecond);
  Assert.AreEqual(1.0, FTitles.Seconds, ClockSlack, 'A second');
end;

procedure TTitlesTests.TestBetweenTicksTheClockLiesBetweenThem;
begin
  FTitles.Start;
  Run(5);
  Assert.AreEqual(4 * Tick, FTitles.SecondsAt(0), ClockSlack, 'The last tick');
  Assert.AreEqual(5 * Tick, FTitles.SecondsAt(1), ClockSlack, 'This tick');
  Assert.AreEqual(4.5 * Tick, FTitles.SecondsAt(0.5), ClockSlack, 'Halfway');
end;

procedure TTitlesTests.TestTheClockLeansTowardTheTrackByHalfATickAtTheMost;
const
  Ahead = 0.3;
begin
  FTitles.Start;
  // A second in: a track behind the clock still tells a place, none below
  // zero
  Run(TitlesTicksPerSecond);
  var Before := FTitles.Seconds;
  FTitles.Tick(Before + Tick + Ahead);
  Assert.AreEqual(Before + 1.5 * Tick, FTitles.Seconds, ClockSlack,
    'A tick and half a tick more');
  Before := FTitles.Seconds;
  FTitles.Tick(Before + Tick - Ahead);
  Assert.AreEqual(Before + 0.5 * Tick, FTitles.Seconds, ClockSlack,
    'A tick less half a tick');
end;

procedure TTitlesTests.TestTheClockComesToATrackCloseBy;
const
  Ahead = 0.05;
  Ticks = 200;
  Millisecond = 0.001;
begin
  FTitles.Start;
  for var i := 1 to Ticks do
    FTitles.Tick(i * Tick + Ahead);
  Assert.AreEqual(Ticks * Tick + Ahead, FTitles.Seconds, Millisecond, 'On the track');
end;

procedure TTitlesTests.TestTheClockNeverGoesBack;
const
  Behind = 0.4;
begin
  FTitles.Start;
  Run(TitlesTicksPerSecond);
  for var i := 1 to 60 do
  begin
    var Before := FTitles.Seconds;
    FTitles.Tick(Before + Tick - Behind * (60 - i) / 60);
    Assert.IsTrue(FTitles.Seconds > Before, 'On, however little');
  end;
end;

procedure TTitlesTests.TestATrackFarOffTakesTheClockAtOnce;
const
  TrackAt = 30.0;
begin
  FTitles.Start;
  Run(3);
  FTitles.Tick(TrackAt);
  Assert.AreEqual(TrackAt, FTitles.Seconds, ClockSlack, 'On the track');
  Assert.AreEqual(TrackAt, FTitles.SecondsAt(0), ClockSlack, 'Nothing between');
end;

procedure TTitlesTests.TestTheFlashComesOnceAtItsCue;
begin
  FTitles.Start;
  Assert.AreEqual(0, RunPast(FlashCue - 2 * Tick), 'None before the cue');
  Assert.IsFalse(FTitles.LogoShown, 'No logo yet');
  Assert.AreEqual(1, RunPast(FlashCue + Tick), 'On the cue');
  Assert.AreEqual(0, RunPast(LongAfter), 'And never again');
end;

procedure TTitlesTests.TestAJumpPastTheFlashStillFlashes;
begin
  FTitles.Start;
  FTitles.JumpTo(FlashCue + 1);
  Assert.IsTrue(FTitles.Tick(NoTrackSeconds).Flashes, 'On the next tick');
  Assert.IsFalse(FTitles.Tick(NoTrackSeconds).Flashes, 'Once');
end;

procedure TTitlesTests.TestTheLogoStandsFromTheFlash;
begin
  FTitles.Start;
  RunPast(FlashCue + Tick);
  Assert.IsTrue(FTitles.LogoShown, 'From the flash');
  RunPast(LongAfter);
  Assert.IsTrue(FTitles.LogoShown, 'And on');
end;

procedure TTitlesTests.TestTheWhiteOfTheFlashIsGoneInItsTicks;
begin
  FTitles.Start;
  RunPast(FlashCue - 2 * Tick);
  Assert.AreEqual(0.0, Double(FTitles.FlashLevel(1)), LevelSlack, 'None before');
  RunToFlash;
  Assert.AreEqual(1.0, Double(FTitles.FlashLevel(0)), LevelSlack, 'White on its tick');
  Run(TitlesFlashTicks - 1);
  Assert.IsTrue(FTitles.FlashLevel(0) > 0, 'Fading still');
  Run(1);
  Assert.AreEqual(0.0, Double(FTitles.FlashLevel(0)), LevelSlack, 'Gone');
end;

procedure TTitlesTests.TestTheCardComesInAndIsGoneByItsOut;
begin
  FTitles.Start;
  FTitles.JumpTo(CardCue - 0.1);
  Assert.AreEqual(0.0, Double(FTitles.CardLevel(1)), LevelSlack, 'Before its cue');
  FTitles.JumpTo(CardCue + TitlesFadeSeconds / 2);
  Assert.AreEqual(0.5, Double(FTitles.CardLevel(1)), LevelSlack, 'Coming in');
  FTitles.JumpTo((CardCue + CardOutCue) / 2);
  Assert.AreEqual(1.0, Double(FTitles.CardLevel(1)), LevelSlack, 'Whole');
  FTitles.JumpTo(CardOutCue - TitlesFadeSeconds / 2);
  Assert.AreEqual(0.5, Double(FTitles.CardLevel(1)), LevelSlack, 'Going out');
  FTitles.JumpTo(CardOutCue);
  Assert.AreEqual(0.0, Double(FTitles.CardLevel(1)), LevelSlack, 'Gone by its out');
  FTitles.JumpTo(FlashCue);
  Assert.AreEqual(0.0, Double(FTitles.CardLevel(1)), LevelSlack, 'Gone at the flash');
end;

procedure TTitlesTests.TestNotRunningNothingShows;
begin
  FTitles.JumpTo((CardCue + CardOutCue) / 2);
  Assert.AreEqual(0.0, Double(FTitles.CardLevel(1)), LevelSlack, 'No card');
  FTitles.JumpTo(LongAfter);
  Assert.IsFalse(FTitles.LogoShown, 'No logo');
  Assert.AreEqual(0.0, Double(FTitles.FlashLevel(1)), LevelSlack, 'No flash');
end;

procedure TTitlesTests.TestClearStopsItAndItCanStartAgain;
begin
  FTitles.Start;
  RunPast(FlashCue + 1);
  FTitles.Clear;
  Assert.IsFalse(FTitles.Running, 'Stopped');
  Assert.IsFalse(FTitles.LogoShown, 'The logo gone');
  Assert.AreEqual(0.0, FTitles.Seconds, ClockSlack, 'The clock at zero');
  FTitles.Start;
  Assert.AreEqual(1, RunPast(FlashCue + 1), 'The flash comes again');
end;

procedure TTitlesTests.TestTheNextCueIsTheFirstPastASecond;
begin
  Assert.AreEqual(CardCue, FTitles.CueAfter(0), ClockSlack, 'The card');
  Assert.AreEqual(FlashCue, FTitles.CueAfter(CardCue), ClockSlack, 'The flash');
  Assert.IsTrue(FTitles.CueAfter(FlashCue) < 0, 'None past the last');
end;

procedure TTitlesTests.TestWithoutAPathTheTitlesNeverFly;
begin
  FTitles.Start;
  var Starts := 0;
  while FTitles.Seconds <= LongAfter do
    if FTitles.Tick(NoTrackSeconds).FlightStarts then
      Inc(Starts);
  Assert.AreEqual(0, Starts, 'No cue of a flight');
  Assert.IsFalse(FTitles.Flying, 'Not flying');
  Assert.IsTrue(Abs(FTitles.EyeAt(1, Stand).Along - Stand) < ClockSlack,
    'The eye where the world stood');
end;

// TTitlesFlightTests

procedure TTitlesFlightTests.Setup;
begin
  FTitles := TTitles.Create;
  FTitles.Arm(FlyingTitles);
  FTitles.Start;
end;

procedure TTitlesFlightTests.TearDown;
begin
  FTitles.Free;
end;

function TTitlesFlightTests.RunToFlight: Integer;
begin
  Result := 0;
  repeat
    Inc(Result);
  until FTitles.Tick(NoTrackSeconds).FlightStarts;
end;

procedure TTitlesFlightTests.FlyPast(ASeconds: Double);
begin
  while FTitles.FlightSeconds(1) <= ASeconds do
    FTitles.Tick(NoTrackSeconds);
end;

procedure TTitlesFlightTests.TestTheFlightStartsOnceAtItsCue;
begin
  RunToFlight;
  Assert.IsTrue(FTitles.Flying, 'Flying');
  Assert.IsTrue(FTitles.Seconds >= FlightCue, 'Not before its cue');
  Assert.IsTrue(FTitles.Seconds < FlightCue + Tick + ClockSlack, 'On the tick of its cue');
  Assert.IsTrue(FTitles.LogoShown, 'The logo has flared by then');
  for var i := 1 to 10 * TitlesTicksPerSecond do
    Assert.IsFalse(FTitles.Tick(NoTrackSeconds).FlightStarts, 'Never again');
end;

procedure TTitlesFlightTests.TestAJumpPastTheFlashAndTheFlightGivesBoth;
begin
  FTitles.JumpTo(FlightCue + 1);
  var Cue := FTitles.Tick(NoTrackSeconds);
  Assert.IsTrue(Cue.Flashes, 'The flash');
  Assert.IsTrue(Cue.FlightStarts, 'And the flight');
end;

procedure TTitlesFlightTests.TestBeforeTheFlightItsSecondsAreZero;
begin
  FTitles.JumpTo(FlightCue - 1);
  FTitles.Tick(NoTrackSeconds);
  Assert.IsFalse(FTitles.Flying, 'Not yet');
  Assert.IsTrue(Abs(FTitles.FlightSeconds(1)) < ClockSlack, 'Zero');
  Assert.IsTrue(Abs(Double(FTitles.TailLevel(1))) < LevelSlack, 'No dark');
end;

procedure TTitlesFlightTests.TestTheFlightsSecondsRunFromItsCue;
const
  Ticks = 50;
begin
  RunToFlight;
  var AtStart: Double := FTitles.Seconds - FlightCue;
  Assert.IsTrue(Abs(FTitles.FlightSeconds(1) - AtStart) < ClockSlack, 'From its cue');
  Assert.IsTrue(Abs(FTitles.FlightSeconds(0)) < ClockSlack,
    'The last tick lay before the cue: zero');
  for var i := 1 to Ticks do
    FTitles.Tick(NoTrackSeconds);
  Assert.IsTrue(Abs(FTitles.FlightSeconds(1) - (AtStart + Ticks * Tick)) < ClockSlack,
    'A tick a tick');
  Assert.IsTrue(Abs(FTitles.FlightSeconds(0) - (AtStart + (Ticks - 1) * Tick)) < ClockSlack,
    'Between the ticks');
end;

procedure TTitlesFlightTests.TestInTheFlightTheClockLeansNoMore;
const
  Ahead = 0.3;
begin
  RunToFlight;
  var Before := FTitles.Seconds;
  FTitles.Tick(Before + Tick + Ahead);
  Assert.IsTrue(Abs(FTitles.Seconds - (Before + Tick)) < ClockSlack,
    'A tick and no more: the camera wants an even clock');
end;

procedure TTitlesFlightTests.TestInTheFlightATrackFarOffTakesTheClockStill;
const
  Ahead = 2.0;
begin
  RunToFlight;
  var TrackAt: Double := FTitles.Seconds + Tick + Ahead;
  FTitles.Tick(TrackAt);
  Assert.IsTrue(Abs(FTitles.Seconds - TrackAt) < ClockSlack, 'On the track');
  Assert.IsTrue(Abs(FTitles.FlightSeconds(1) - (TrackAt - FlightCue)) < ClockSlack,
    'The flight with it');
end;

procedure TTitlesFlightTests.TestBeforeTheFlightTheEyeStandsWhereTheWorldStood;
begin
  FTitles.JumpTo(FlightCue - 1);
  FTitles.Tick(NoTrackSeconds);
  var Eye := FTitles.EyeAt(1, Stand);
  Assert.IsTrue(Abs(Eye.Along - Stand) < ClockSlack, 'Where the world stood');
  Assert.IsTrue(Abs(Eye.Lift) < ClockSlack, 'At its rest');
end;

procedure TTitlesFlightTests.TestTheEyeGoesThePathByTheFlightsSeconds;
begin
  RunToFlight;
  FlyPast(CastOffSeconds / 2);
  var Flown := FTitles.FlightSeconds(1);
  var Eye := FTitles.EyeAt(1, Stand);
  var ByThePath := FlyingTitles.Path.EyeAt(Flown, Stand);
  Assert.IsTrue(Abs(Eye.Along - ByThePath.Along) < ClockSlack, 'The path''s place');
  Assert.IsTrue(Eye.Along < Stand, 'Cast off to the left');
  Assert.IsTrue(Eye.Along > Stand + CastOffWay, 'Not at the cast-off''s end yet');

  FlyPast((RestTill + LiftedSeconds) / 2);
  Assert.IsTrue(FTitles.EyeAt(1, Stand).Lift > 0, 'Lifted past its rest');
end;

procedure TTitlesFlightTests.TestTheFlightEndsOnceWhereTheEyeLeavesItsRest;
begin
  RunToFlight;
  var Ends := 0;
  var EndedAt: Double := 0;
  for var i := 1 to 20 * TitlesTicksPerSecond do
    if FTitles.Tick(NoTrackSeconds).FlightEnds then
    begin
      Inc(Ends);
      EndedAt := FTitles.FlightSeconds(1);
    end;
  Assert.AreEqual(1, Ends, 'Once');
  Assert.IsTrue(EndedAt >= RestTill, 'Not before the eye leaves its rest');
  Assert.IsTrue(EndedAt < RestTill + Tick + ClockSlack, 'On that tick');
end;

procedure TTitlesFlightTests.TestTheFrameGoesDarkOverTheLastSecond;
begin
  RunToFlight;
  FlyPast(RestTill - TitlesTailSeconds - 2 * Tick);
  Assert.IsTrue(Abs(Double(FTitles.TailLevel(1))) < LevelSlack, 'None before the last second');

  FlyPast(RestTill - TitlesTailSeconds / 2);
  var Halfway: Double := FTitles.TailLevel(1);
  Assert.IsTrue((Halfway > 0.45) and (Halfway < 0.6), 'Half dark halfway');

  FlyPast(RestTill);
  Assert.IsTrue(Abs(Double(FTitles.TailLevel(1)) - 1) < LevelSlack, 'Dark at its end');
end;

procedure TTitlesFlightTests.TestClearEndsTheFlight;
begin
  RunToFlight;
  FlyPast(1);
  FTitles.Clear;
  Assert.IsFalse(FTitles.Flying, 'Not flying');
  Assert.IsTrue(Abs(FTitles.FlightSeconds(1)) < ClockSlack, 'Its seconds at zero');
  FTitles.Start;
  RunToFlight;
  Assert.IsTrue(FTitles.Flying, 'It flies again');
end;

initialization
  TDUnitX.RegisterTestFixture(TTitlesTests);
  TDUnitX.RegisterTestFixture(TTitlesFlightTests);

end.
