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
  seconds and stands where the world stood before it. The path is flown
  from the second the titles' file has it flown to, the frame gone dark
  over the second before, and from there the clock leans again; a clear
  ends the flight. Titles without a path never fly. The sign's stutter and
  the sun's flare count the flight's seconds from their own cues, below
  zero before them.

  Titles that end at the stars: the sky comes once, on its cue; its stars
  come in over a fade, its nebula slower; it stands high till it comes,
  as high as the pitch rose there makes it, and comes down to its rest by
  its cue, first as fast as the pitch rose, then ever slower. The phrases
  come on their cues and go as the credits come; the lines of the credits
  come one after another and share the time to the last screen. The last
  screen comes once, on its cue; titles that fly with no stars have theirs
  where the path is flown. The track's end comes once. The next cue walks
  them all.

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
    procedure TestThePathIsFlownFromWhereItIsFlownTo;
    [Test]
    procedure TestPastThePathTheClockLeansAgain;
    [Test]
    procedure TestTheFrameGoesDarkOverTheLastSecond;
    [Test]
    procedure TestClearEndsTheFlight;
    [Test]
    procedure TestTheSignAndTheFlareCountFromTheirCues;
    [Test]
    procedure TestWithoutTheStarsTheLastScreenComesWhereThePathIsFlown;
  end;

  [TestFixture]
  TTitlesStarsTests = class
  private
    FTitles: TTitles;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestTheSkyComesOnceAtItsCue;
    [Test]
    procedure TestTheStarsComeInOverAFadeTheNebulaSlower;
    [Test]
    procedure TestTheSkyStandsHighAndComesDownToItsRest;
    [Test]
    procedure TestTheSkyComesDownAsFastAsThePitchRose;
    [Test]
    procedure TestThePhrasesComeOnTheirCuesAndGoWithTheCredits;
    [Test]
    procedure TestTheCreditsComeOneAfterAnotherToTheLastScreen;
    [Test]
    procedure TestTheLastScreenComesOnceAtItsCue;
    [Test]
    procedure TestTheTracksEndComesOnce;
    [Test]
    procedure TestTheNextCueWalksTheStars;
    [Test]
    procedure TestTitlesThatDoNotEndAtTheStarsShowNoneOfThem;
  end;

implementation

uses
  System.Math;

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
  // The titles' file has the path flown short of its end
  FlownTill = 8.0;
  // The sign stutters three seconds into the flight, the sun flares at five
  SignCue = FlightCue + 3;
  FlareCue = FlightCue + 5;
  // Where the world of the tests stands
  Stand = 2400.0;
  // The titles that end at the stars: the path's nose comes up from four
  // seconds to its end at ten, the sky comes at eight of the flight, stands
  // still at sixteen; the phrases, the credits, the last screen, the end
  PitchFrom = 4.0;
  PathEnd = 10.0;
  EndPitch = 20.0;
  StarsCue = FlightCue + 8;
  StillCue = FlightCue + 16;
  MissionCue = FlightCue + 17;
  PromiseCue = FlightCue + 19;
  CreditsCue = FlightCue + 23;
  LastCue = FlightCue + 32;
  TrackEnd = FlightCue + 41;
  // The flight as many seconds before the cue as after it, for a pace
  PaceSpan = 0.01;

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
  Result.Cues.Neon := SignCue;
  Result.Cues.Flare := FlareCue;
  Result.Path.Keys := [KeyFromStand(0, 0, 0),
    KeyFromStand(CastOffSeconds, CastOffWay, 0),
    KeyFromStand(RestTill, RestTillWay, 0),
    KeyFromStand(LiftedSeconds, LiftedWay, Lifted)];
  Result.FlightTill := FlownTill;
end;

// A key at ASeconds on the strip's place 0, pitched APitch
function PitchedKey(ASeconds, APitch: Double): TEyeKey;
begin
  Result := Default(TEyeKey);
  Result.Seconds := ASeconds;
  Result.Placing := epFromStand;
  Result.Pitch := APitch;
end;

function StarsTitles: TTitlesDef;
begin
  Result := TestTitles;
  Result.Cues.Flight := FlightCue;
  Result.Cues.Neon := SignCue;
  Result.Cues.Flare := FlareCue;
  Result.Path.Keys := [PitchedKey(0, 0), PitchedKey(PitchFrom, 0),
    PitchedKey(PathEnd, EndPitch)];
  Result.FlightTill := PathEnd;
  Result.Cues.Stars := StarsCue;
  Result.Cues.Still := StillCue;
  Result.Cues.Mission := MissionCue;
  Result.Cues.Promise := PromiseCue;
  Result.Cues.Credits := CreditsCue;
  Result.Cues.Last := LastCue;
  Result.TrackSeconds := TrackEnd;
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
  Assert.IsTrue(Abs(Double(FTitles.DarkLevel(1))) < LevelSlack, 'No dark');
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

procedure TTitlesFlightTests.TestThePathIsFlownFromWhereItIsFlownTo;
begin
  Assert.IsFalse(FTitles.PathFlown, 'Not before the flight');
  RunToFlight;
  FlyPast(FlownTill - 2 * Tick);
  Assert.IsFalse(FTitles.PathFlown, 'Not short of the second');
  FlyPast(FlownTill);
  Assert.IsTrue(FTitles.PathFlown, 'From the second it is flown to');
  FTitles.Tick(NoTrackSeconds);
  Assert.IsTrue(FTitles.PathFlown, 'And on');
end;

procedure TTitlesFlightTests.TestPastThePathTheClockLeansAgain;
const
  Ahead = 0.3;
begin
  RunToFlight;
  FlyPast(FlownTill);
  var Before := FTitles.Seconds;
  FTitles.Tick(Before + Tick + Ahead);
  Assert.IsTrue(Abs(FTitles.Seconds - (Before + 1.5 * Tick)) < ClockSlack,
    'A tick and half a tick more: the eye stands, the lines want the beat');
end;

procedure TTitlesFlightTests.TestTheFrameGoesDarkOverTheLastSecond;
begin
  RunToFlight;
  FlyPast(FlownTill - TitlesDarkSeconds - 2 * Tick);
  Assert.IsTrue(Abs(Double(FTitles.DarkLevel(1))) < LevelSlack, 'None before the last second');

  FlyPast(FlownTill - TitlesDarkSeconds / 2);
  var Halfway: Double := FTitles.DarkLevel(1);
  Assert.IsTrue((Halfway > 0.45) and (Halfway < 0.6), 'Half dark halfway');

  FlyPast(FlownTill);
  Assert.IsTrue(Abs(Double(FTitles.DarkLevel(1)) - 1) < LevelSlack, 'Dark at its end');
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

procedure TTitlesFlightTests.TestTheSignAndTheFlareCountFromTheirCues;
begin
  Assert.IsTrue(Abs(FTitles.SignSince(1) + 3) < ClockSlack, 'Three seconds before the sign');
  Assert.IsTrue(Abs(FTitles.FlareSince(1) + 5) < ClockSlack, 'Five before the flare');

  RunToFlight;
  FlyPast(4);
  var Flown := FTitles.FlightSeconds(1);
  Assert.IsTrue(Abs(FTitles.SignSince(1) - (Flown - 3)) < ClockSlack, 'Past the sign''s cue');
  Assert.IsTrue(Abs(FTitles.FlareSince(1) - (Flown - 5)) < ClockSlack, 'Not yet the flare''s');
  Assert.IsTrue(FTitles.FlareSince(1) < 0, 'The sun not out yet');
end;

// As Levels.Titles reads it: no stars, the last screen where the path is
// flown
procedure TTitlesFlightTests.TestWithoutTheStarsTheLastScreenComesWhereThePathIsFlown;
begin
  var Def := FlyingTitles;
  Def.Cues.Last := FlightCue + FlownTill;
  FTitles.Arm(Def);
  FTitles.Start;
  var Comes := 0;
  var CameAt: Double := 0;
  while FTitles.Seconds <= LongAfter do
    if FTitles.Tick(NoTrackSeconds).LastComes then
    begin
      Inc(Comes);
      CameAt := FTitles.FlightSeconds(1);
    end;
  Assert.AreEqual(1, Comes, 'Once');
  Assert.IsTrue(CameAt >= FlownTill, 'Not before the path is flown');
  Assert.IsTrue(CameAt < FlownTill + Tick + ClockSlack, 'On that tick');
  Assert.IsFalse(FTitles.AtTheStars, 'No sky');
end;

// TTitlesStarsTests

procedure TTitlesStarsTests.Setup;
begin
  FTitles := TTitles.Create;
  FTitles.Arm(StarsTitles);
  FTitles.Start;
end;

procedure TTitlesStarsTests.TearDown;
begin
  FTitles.Free;
end;

procedure TTitlesStarsTests.TestTheSkyComesOnceAtItsCue;
begin
  var Comes := 0;
  var CameAt: Double := 0;
  while FTitles.Seconds <= LongAfter do
    if FTitles.Tick(NoTrackSeconds).SkyComes then
    begin
      Inc(Comes);
      CameAt := FTitles.Seconds;
    end;
  Assert.AreEqual(1, Comes, 'Once');
  Assert.IsTrue(CameAt >= StarsCue, 'Not before its cue');
  Assert.IsTrue(CameAt < StarsCue + Tick + ClockSlack, 'On the tick of its cue');
end;

procedure TTitlesStarsTests.TestTheStarsComeInOverAFadeTheNebulaSlower;
begin
  FTitles.JumpTo(StarsCue - 1);
  FTitles.Tick(NoTrackSeconds);
  Assert.IsTrue(Abs(Double(FTitles.StarsLevel(1))) < LevelSlack, 'No stars before');
  Assert.IsTrue(Abs(Double(FTitles.NebulaLevel(1))) < LevelSlack, 'No nebula before');

  FTitles.JumpTo(StarsCue + TitlesFadeSeconds / 2);
  FTitles.Tick(NoTrackSeconds);
  var Halfway: Double := TitlesFadeSeconds / 2 + Tick;
  Assert.IsTrue(Abs(FTitles.StarsLevel(1) - Halfway / TitlesFadeSeconds) < LevelSlack,
    'The stars coming in');
  Assert.IsTrue(Abs(FTitles.NebulaLevel(1) - Halfway / TitlesNebulaSeconds) < LevelSlack,
    'The nebula slower');

  FTitles.JumpTo(StarsCue + TitlesNebulaSeconds);
  FTitles.Tick(NoTrackSeconds);
  Assert.IsTrue(Abs(FTitles.StarsLevel(1) - 1) < LevelSlack, 'All the stars');
  Assert.IsTrue(Abs(FTitles.NebulaLevel(1) - 1) < LevelSlack, 'All the nebula');
end;

procedure TTitlesStarsTests.TestTheSkyStandsHighAndComesDownToItsRest;
begin
  FTitles.JumpTo(StarsCue - 1);
  var Highest := FTitles.SkyRise(1);
  Assert.IsTrue(Highest > 0, 'Above its rest before it comes');

  FTitles.JumpTo(StarsCue);
  Assert.IsTrue(Abs(FTitles.SkyRise(1) - Highest) < ClockSlack, 'All of it as it comes');
  var Before := Highest;
  for var i := 1 to 15 do
  begin
    FTitles.JumpTo(StarsCue + i * (StillCue - StarsCue) / 16);
    var Lower := FTitles.SkyRise(1);
    Assert.IsTrue(Lower < Before, 'Down, all the way');
    Before := Lower;
  end;
  FTitles.JumpTo(StillCue);
  Assert.IsTrue(Abs(FTitles.SkyRise(1)) < ClockSlack, 'At its rest by its cue');
  FTitles.JumpTo(LongAfter);
  Assert.IsTrue(Abs(FTitles.SkyRise(1)) < ClockSlack, 'And after');
end;

// The pace the tangent of the path's pitch rose at as the sky came, worked
// out from the path itself
procedure TTitlesStarsTests.TestTheSkyComesDownAsFastAsThePitchRose;
const
  Step = 0.001;
  PaceSlack = 0.02;
begin
  var Path := StarsTitles.Path;
  var At: Double := StarsCue - FlightCue;
  var Pace: Double := (Tan(DegToRad(Path.EyeAt(At + PaceSpan, 0).Pitch)) -
    Tan(DegToRad(Path.EyeAt(At - PaceSpan, 0).Pitch))) / (2 * PaceSpan);
  Assert.IsTrue(Pace > 0, 'The nose comes up there');

  FTitles.JumpTo(StarsCue);
  var Start := FTitles.SkyRise(1);
  FTitles.JumpTo(StarsCue + Step);
  var Fall: Double := (Start - FTitles.SkyRise(1)) / Step;
  Assert.IsTrue(Abs(Fall / Pace - 1) < PaceSlack, 'As fast as the pitch rose');
end;

procedure TTitlesStarsTests.TestThePhrasesComeOnTheirCuesAndGoWithTheCredits;
begin
  FTitles.JumpTo(MissionCue - 0.1);
  Assert.IsTrue(Abs(Double(FTitles.MissionLevel(1))) < LevelSlack, 'No mission yet');
  FTitles.JumpTo(PromiseCue);
  Assert.IsTrue(Abs(FTitles.MissionLevel(1) - 1) < LevelSlack, 'The mission whole');
  Assert.IsTrue(Abs(Double(FTitles.PromiseLevel(1))) < LevelSlack, 'The promise on its cue');
  FTitles.JumpTo(PromiseCue + TitlesFadeSeconds);
  Assert.IsTrue(Abs(FTitles.PromiseLevel(1) - 1) < LevelSlack, 'The promise whole');
  FTitles.JumpTo(CreditsCue - TitlesFadeSeconds / 2);
  Assert.IsTrue(Abs(FTitles.MissionLevel(1) - 0.5) < LevelSlack, 'The mission going');
  Assert.IsTrue(Abs(FTitles.PromiseLevel(1) - 0.5) < LevelSlack, 'The promise going');
  FTitles.JumpTo(CreditsCue);
  Assert.IsTrue(Abs(Double(FTitles.MissionLevel(1))) < LevelSlack, 'Gone as the credits come');
  Assert.IsTrue(Abs(Double(FTitles.PromiseLevel(1))) < LevelSlack, 'Both');
end;

procedure TTitlesStarsTests.TestTheCreditsComeOneAfterAnotherToTheLastScreen;
begin
  var Span: Double := (LastCue - CreditsCue) / TitlesCreditLines;
  for var Line := 0 to TitlesCreditLines - 1 do
  begin
    FTitles.JumpTo(CreditsCue + (Line + 0.5) * Span);
    for var Other := 0 to TitlesCreditLines - 1 do
      if Other = Line then
        Assert.IsTrue(Abs(FTitles.CreditLevel(Other, 1) - 1) < LevelSlack, 'Its line whole')
      else
        Assert.IsTrue(Abs(Double(FTitles.CreditLevel(Other, 1))) < LevelSlack,
          'The others not there');
  end;
  FTitles.JumpTo(LastCue);
  for var Line := 0 to TitlesCreditLines - 1 do
    Assert.IsTrue(Abs(Double(FTitles.CreditLevel(Line, 1))) < LevelSlack,
      'All gone by the last screen');
end;

procedure TTitlesStarsTests.TestTheLastScreenComesOnceAtItsCue;
begin
  var Comes := 0;
  while FTitles.Seconds <= LastCue - 2 * Tick do
    if FTitles.Tick(NoTrackSeconds).LastComes then
      Inc(Comes);
  Assert.AreEqual(0, Comes, 'None before its cue');
  Assert.IsFalse(FTitles.LastShown, 'Not shown');
  Assert.IsTrue(Abs(Double(FTitles.LastLevel(1))) < LevelSlack, 'Nothing of it');
  while FTitles.Seconds <= TrackEnd - 2 * Tick do
    if FTitles.Tick(NoTrackSeconds).LastComes then
      Inc(Comes);
  Assert.AreEqual(1, Comes, 'Once');
  Assert.IsTrue(FTitles.LastShown, 'Shown');
  Assert.IsTrue(Abs(FTitles.LastLevel(1) - 1) < LevelSlack, 'All of it');
end;

procedure TTitlesStarsTests.TestTheTracksEndComesOnce;
begin
  var Ends := 0;
  var EndedAt: Double := 0;
  while FTitles.Seconds <= LongAfter do
    if FTitles.Tick(NoTrackSeconds).TrackEnds then
    begin
      Inc(Ends);
      EndedAt := FTitles.Seconds;
    end;
  Assert.AreEqual(1, Ends, 'Once');
  Assert.IsTrue(EndedAt >= TrackEnd, 'Not before the track''s length');
  Assert.IsTrue(EndedAt < TrackEnd + Tick + ClockSlack, 'On that tick');
end;

procedure TTitlesStarsTests.TestTheNextCueWalksTheStars;
begin
  Assert.IsTrue(Abs(FTitles.CueAfter(FlashCue) - StarsCue) < ClockSlack, 'The sky');
  Assert.IsTrue(Abs(FTitles.CueAfter(StarsCue) - MissionCue) < ClockSlack, 'The mission');
  Assert.IsTrue(Abs(FTitles.CueAfter(MissionCue) - CreditsCue) < ClockSlack, 'The credits');
  Assert.IsTrue(Abs(FTitles.CueAfter(CreditsCue) - LastCue) < ClockSlack, 'The last screen');
  Assert.IsTrue(Abs(FTitles.CueAfter(LastCue) - TrackEnd) < ClockSlack, 'The track''s end');
  Assert.IsTrue(FTitles.CueAfter(TrackEnd) < 0, 'None past it');
end;

procedure TTitlesStarsTests.TestTitlesThatDoNotEndAtTheStarsShowNoneOfThem;
begin
  FTitles.Arm(FlyingTitles);
  FTitles.Start;
  var Comes := 0;
  while FTitles.Seconds <= LongAfter do
    if FTitles.Tick(NoTrackSeconds).SkyComes then
      Inc(Comes);
  Assert.AreEqual(0, Comes, 'No sky');
  Assert.IsTrue(Abs(Double(FTitles.StarsLevel(1))) < LevelSlack, 'No stars');
  Assert.IsTrue(Abs(FTitles.SkyRise(1)) < ClockSlack, 'No rise');
  Assert.IsTrue(Abs(Double(FTitles.MissionLevel(1))) < LevelSlack, 'No phrase');
  Assert.IsTrue(Abs(Double(FTitles.CreditLevel(0, 1))) < LevelSlack, 'No credits');
end;

initialization
  TDUnitX.RegisterTestFixture(TTitlesTests);
  TDUnitX.RegisterTestFixture(TTitlesFlightTests);
  TDUnitX.RegisterTestFixture(TTitlesStarsTests);

end.
