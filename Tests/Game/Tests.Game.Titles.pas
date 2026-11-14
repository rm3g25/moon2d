{
  Tests.Game.Titles - the titles' clock and what it tells: it runs only
  once started, and never without titles to play; by the ticks alone a
  second is thirty-three of them; it leans toward the track by half a tick
  at the most, comes to it, never goes back, and a track far off takes it at
  once. The flash comes once, on the tick the clock reaches its cue, a jump
  past the cue included; the logo stands from then on, and the white of
  the flash is gone in its ticks. The card comes in and is gone by its
  out, before the flash. A clear stops it, and it can start again.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Game.Titles;

interface

uses
  DUnitX.TestFramework,
  Levels.Titles, Game.Titles;

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

function TestTitles: TTitlesDef;
begin
  Result := Default(TTitlesDef);
  Result.Present := True;
  Result.Cues.Card := CardCue;
  Result.Cues.CardOut := CardOutCue;
  Result.Cues.Flash := FlashCue;
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
  FTitles.Tick(Tick + Ahead);
  Assert.AreEqual(1.5 * Tick, FTitles.Seconds, ClockSlack,
    'A tick and half a tick more');
  FTitles.Tick(FTitles.Seconds + Tick - Ahead);
  Assert.AreEqual(2 * Tick, FTitles.Seconds, ClockSlack,
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

end.
