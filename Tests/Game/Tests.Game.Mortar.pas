{
  Tests.Game.Mortar - the stern mortar of the Ram: folded it does nothing;
  given a turn it rises and tells it once, turns to his feet and lobs at
  them once he stands on a deck; one shell at a time - the next only once
  the last is gone and a gap is out; one who stays in the air costs it the
  shell; its shells spent it folds and tells it; it leans toward his feet,
  never past its most; a lob kicks it and the kick dies; a turn is not
  begun twice, nor with no shells; a clear folds it.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Game.Mortar;

interface

uses
  DUnitX.TestFramework,
  Sdl2.Core,
  Game.Mortar;

type
  // The cues of the ticks stepped, added up
  TMortarCuesSeen = record
    Rises, Lobs, Folded: Integer;
    // Of the last lob
    LobAt: TSdlFPoint;
  end;

  [TestFixture]
  TMortarTests = class
  private
    FMortar: TMortar;
    FSight: TMortarSight;
    FSeen: TMortarCuesSeen;
    procedure Step;
    // Steps till the mortar is at AStage; the ticks it took. Fails past
    // ALimit.
    function StepTill(AStage: TMortarStage; ALimit: Integer): Integer;
    // Steps till it lobs; the ticks it took. Fails past ALimit.
    function StepTillLob(ALimit: Integer): Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestFoldedItDoesNothing;
    [Test]
    procedure TestGivenATurnItRisesAndTellsItOnce;
    [Test]
    procedure TestOutItLobsAtHisFeetOnceAimed;
    [Test]
    procedure TestOneShellAtATime;
    [Test]
    procedure TestTheNextShellComesAGapAfterTheLastIsGone;
    [Test]
    procedure TestHeStandsLateItLobsThen;
    [Test]
    procedure TestHeStaysInTheAirTheShellIsGivenUp;
    [Test]
    procedure TestItsShellsSpentItFoldsAndTellsIt;
    [Test]
    procedure TestBusyThroughItsTurn;
    [Test]
    procedure TestItLeansTowardHisFeetNeverPastItsMost;
    [Test]
    procedure TestALobKicksItAndTheKickDies;
    [Test]
    procedure TestATurnIsNotBegunTwiceNorWithNoShells;
    [Test]
    procedure TestAClearFoldsIt;
  end;

implementation

uses
  System.SysUtils;

const
  // A turn of two shells is over well within this: ten seconds
  TurnTicks = 330;
  PivotX = 300.0;
  PivotY = 60.0;
  Slack = 0.01;

function At(AX, AY: Single): TSdlFPoint;
begin
  Result.X := AX;
  Result.Y := AY;
end;

procedure TMortarTests.Setup;
begin
  FMortar := TMortar.Create;
  FSight := Default(TMortarSight);
  FSight.Pivot := At(PivotX, PivotY);
  FSight.Feet := At(PivotX - 60, 240);
  FSight.OnDeck := True;
  FSeen := Default(TMortarCuesSeen);
end;

procedure TMortarTests.TearDown;
begin
  FMortar.Free;
end;

procedure TMortarTests.Step;
begin
  var Cue := FMortar.Tick(FSight);
  if Cue.Rises then
    Inc(FSeen.Rises);
  if Cue.Lob then
  begin
    Inc(FSeen.Lobs);
    FSeen.LobAt := Cue.LobAt;
  end;
  if Cue.Folded then
    Inc(FSeen.Folded);
end;

function TMortarTests.StepTill(AStage: TMortarStage; ALimit: Integer): Integer;
begin
  Result := 0;
  while FMortar.Stage <> AStage do
  begin
    Step;
    Inc(Result);
    if Result > ALimit then
      Assert.Fail(Format('Not at stage %d in %d ticks', [Ord(AStage), ALimit]));
  end;
end;

function TMortarTests.StepTillLob(ALimit: Integer): Integer;
begin
  Result := 0;
  var Lobs := FSeen.Lobs;
  while FSeen.Lobs = Lobs do
  begin
    Step;
    Inc(Result);
    if Result > ALimit then
      Assert.Fail(Format('No lob in %d ticks', [ALimit]));
  end;
end;

procedure TMortarTests.TestFoldedItDoesNothing;
begin
  for var i := 1 to TurnTicks do
    Step;
  Assert.AreEqual<TMortarStage>(msStowed, FMortar.Stage, 'Folded');
  Assert.AreEqual(0.0, Double(FMortar.OutAt(1)), Slack, 'Behind the block');
  Assert.AreEqual(0, FSeen.Rises + FSeen.Lobs + FSeen.Folded, 'It told nothing');
  Assert.IsFalse(FMortar.Busy, 'No turn');
end;

procedure TMortarTests.TestGivenATurnItRisesAndTellsItOnce;
begin
  FMortar.BeginTurn(2);
  var LastOut: Single := 0;
  var Ticks := 0;
  while FMortar.Stage = msRising do
  begin
    Step;
    Inc(Ticks);
    Assert.IsTrue(FMortar.OutAt(1) >= LastOut, 'It only rises');
    LastOut := FMortar.OutAt(1);
    if Ticks > TurnTicks then
      Assert.Fail('It never stood out');
  end;
  Assert.AreEqual(MortarRiseTicks, Ticks, 'Out in its rise');
  Assert.AreEqual(1.0, Double(FMortar.OutAt(1)), Slack, 'All out');
  Assert.AreEqual(1, FSeen.Rises, 'Its rise told once');
  Assert.AreEqual(0, FSeen.Lobs, 'No shell while it rises');
end;

procedure TMortarTests.TestOutItLobsAtHisFeetOnceAimed;
begin
  FMortar.BeginTurn(2);
  StepTill(msAiming, TurnTicks);
  var Ticks := StepTillLob(TurnTicks);
  Assert.AreEqual(MortarAimTicks, Ticks, 'Lobbed as soon as it is aimed');
  Assert.AreEqual(Double(FSight.Feet.X), Double(FSeen.LobAt.X), Slack, 'At his feet across');
  Assert.AreEqual(Double(FSight.Feet.Y), Double(FSeen.LobAt.Y), Slack, 'At his feet down');
  Assert.AreEqual(1, FMortar.ShellsLeft, 'One shell of the turn left');
end;

procedure TMortarTests.TestOneShellAtATime;
begin
  FMortar.BeginTurn(2);
  StepTillLob(TurnTicks);
  FSight.ShellsAloft := 1;
  for var i := 1 to TurnTicks do
    Step;
  Assert.AreEqual(1, FSeen.Lobs, 'No second shell while the first flies');
  Assert.AreEqual<TMortarStage>(msWaiting, FMortar.Stage, 'It waits');
end;

procedure TMortarTests.TestTheNextShellComesAGapAfterTheLastIsGone;
begin
  FMortar.BeginTurn(2);
  StepTillLob(TurnTicks);
  FSight.ShellsAloft := 1;
  for var i := 1 to 40 do
    Step;
  FSight.ShellsAloft := 0;
  var Ticks := StepTillLob(TurnTicks);
  Assert.AreEqual(MortarGapTicks + MortarAimTicks, Ticks,
    'The gap, the aim, then the next');
  Assert.AreEqual(2, FSeen.Lobs, 'The second shell');
end;

procedure TMortarTests.TestHeStandsLateItLobsThen;
begin
  FMortar.BeginTurn(1);
  StepTill(msAiming, TurnTicks);
  FSight.OnDeck := False;
  for var i := 1 to MortarAimTicks + MortarWaitTicks div 2 do
    Step;
  Assert.AreEqual(0, FSeen.Lobs, 'Not at a hero in the air');
  FSight.OnDeck := True;
  Step;
  Assert.AreEqual(1, FSeen.Lobs, 'As soon as he stands');
end;

procedure TMortarTests.TestHeStaysInTheAirTheShellIsGivenUp;
begin
  FMortar.BeginTurn(2);
  StepTill(msAiming, TurnTicks);
  FSight.OnDeck := False;
  for var i := 1 to MortarAimTicks + MortarWaitTicks - 1 do
    Step;
  Assert.AreEqual(2, FMortar.ShellsLeft, 'Still waiting for him');
  Step;
  Assert.AreEqual(1, FMortar.ShellsLeft, 'The shell given up');
  Assert.AreEqual(0, FSeen.Lobs, 'Nothing lobbed');
  Assert.AreEqual<TMortarStage>(msAiming, FMortar.Stage, 'Aiming the next');
end;

procedure TMortarTests.TestItsShellsSpentItFoldsAndTellsIt;
begin
  FMortar.BeginTurn(1);
  StepTillLob(TurnTicks);
  StepTill(msFolding, TurnTicks);
  Assert.AreEqual(0, FSeen.Folded, 'Not while it folds');
  var Ticks := StepTill(msStowed, TurnTicks);
  Assert.AreEqual(MortarFoldTicks, Ticks, 'Folded in its fold');
  Assert.AreEqual(1, FSeen.Folded, 'Told once');
  Assert.AreEqual(0.0, Double(FMortar.OutAt(1)), Slack, 'Behind the block');
  Assert.AreEqual(1, FSeen.Lobs, 'One shell, as given');
end;

procedure TMortarTests.TestBusyThroughItsTurn;
begin
  FMortar.BeginTurn(2);
  var Ticks := 0;
  while FMortar.Stage <> msStowed do
  begin
    Assert.IsTrue(FMortar.Busy, 'Busy');
    Step;
    Inc(Ticks);
    if Ticks > TurnTicks then
      Assert.Fail('The turn never ended');
  end;
  Assert.IsFalse(FMortar.Busy, 'Its turn over');
  Assert.AreEqual(2, FSeen.Lobs, 'Both shells');
end;

procedure TMortarTests.TestItLeansTowardHisFeetNeverPastItsMost;
begin
  Assert.AreEqual(0.0, Double(MortarTilt(At(PivotX, PivotY), At(PivotX, 300))),
    Slack, 'Upright over him');
  Assert.AreEqual(Double(MortarTiltMost),
    Double(MortarTilt(At(PivotX, PivotY), At(PivotX + 500, 300))), Slack,
    'Right, its most');
  Assert.AreEqual(Double(-MortarTiltMost),
    Double(MortarTilt(At(PivotX, PivotY), At(PivotX - 500, 300))), Slack,
    'Left, its most');
  FSight.Feet := At(PivotX + 500, 300);
  FMortar.BeginTurn(1);
  StepTill(msAiming, TurnTicks);
  FSight.OnDeck := False;
  for var i := 1 to MortarAimTicks + 10 do
  begin
    Step;
    Assert.IsTrue(FMortar.TiltAt(1) <= MortarTiltMost + Slack, 'Never past its most');
  end;
  Assert.IsTrue(FMortar.TiltAt(1) > MortarTiltMost * 0.9, 'Leaning right to him');
end;

procedure TMortarTests.TestALobKicksItAndTheKickDies;
begin
  FMortar.BeginTurn(1);
  StepTillLob(TurnTicks);
  Assert.AreEqual(1.0, Double(FMortar.KickAt(1)), Slack, 'Kicked as it lobs');
  for var i := 1 to MortarKickTicks do
    Step;
  Assert.AreEqual(0.0, Double(FMortar.KickAt(1)), Slack, 'The kick died');
end;

procedure TMortarTests.TestATurnIsNotBegunTwiceNorWithNoShells;
begin
  FMortar.BeginTurn(0);
  Assert.IsFalse(FMortar.Busy, 'No turn with no shells');
  FMortar.BeginTurn(1);
  StepTill(msAiming, TurnTicks);
  FMortar.BeginTurn(3);
  Assert.AreEqual(1, FMortar.ShellsLeft, 'The turn under way kept');
  Assert.AreEqual<TMortarStage>(msAiming, FMortar.Stage, 'Not risen anew');
end;

procedure TMortarTests.TestAClearFoldsIt;
begin
  FMortar.BeginTurn(2);
  StepTillLob(TurnTicks);
  FMortar.Clear;
  Assert.AreEqual<TMortarStage>(msStowed, FMortar.Stage, 'Folded');
  Assert.IsFalse(FMortar.Busy, 'No turn');
  Assert.AreEqual(0, FMortar.ShellsLeft, 'No shells left');
  Assert.AreEqual(0.0, Double(FMortar.OutAt(1)), Slack, 'Behind the block');
  Assert.AreEqual(0.0, Double(FMortar.TiltAt(1)), Slack, 'Upright');
end;

initialization
  TDUnitX.RegisterTestFixture(TMortarTests);

end.
