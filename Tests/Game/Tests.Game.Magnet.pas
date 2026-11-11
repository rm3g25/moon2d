{
  Tests.Game.Magnet - the magnet under the Ram's belly: stowed and idle
  till deployed; deployed it waits a breath, slides out and tells its
  start once; it takes the nearest barge in reach, or the hero's first
  when its rule says so, never one out of sight; one out of reach it only
  wants, and catches once its face is over it; a caught barge is drawn up
  smoothly to hang just under the face - a rider's height lower in a
  lift - and rides with the face while held; then it is seized - pressed,
  in a lift - and thrown, at the hero or, with none, at the harbour; one
  barge at a time; soft from the hold till it is cold, heating as it
  holds and cooling through its window; cold again it tells its window
  over, once, and takes the next - unless told to wait, when it takes
  none till the wait is lifted; a clear stows it.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Game.Magnet;

interface

uses
  DUnitX.TestFramework,
  Sdl2.Core,
  Game.Magnet;

type
  // The cues of the ticks stepped, added up
  TCuesSeen = record
    Started, Caught, Seized, Thrown, Cooled: Integer;
    // Of the last cue of its kind
    Barge: Integer;
    Pressed: Boolean;
    Snug, Aim: TSdlFPoint;
  end;

  [TestFixture]
  TMagnetTests = class
  private
    FMagnet: TMagnet;
    FSight: TMagnetSight;
    FSeen: TCuesSeen;
    procedure See(const ABarges: array of TMagnetBarge);
    procedure Step;
    // Steps till the magnet is at AStage; the ticks it took. Fails past
    // ALimit.
    function StepTill(AStage: TMagnetStage; ALimit: Integer): Integer;
    // Deployed and out, cold, looking for its first barge
    procedure BringOut;
    // Out, the near barge caught: on its way up
    procedure CatchNear(AHeroAboard: Boolean);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestStowedItDoesNothing;
    [Test]
    procedure TestDeployedItWaitsThenSlidesOutAndTellsItsStartOnce;
    [Test]
    procedure TestDeployedTwiceItComesOutOnce;
    [Test]
    procedure TestItCatchesTheNearestBargeInReach;
    [Test]
    procedure TestByItsRuleItTakesHisBargeFirst;
    [Test]
    procedure TestABargeOutOfSightIsNotTaken;
    [Test]
    procedure TestOutOfReachItOnlyWantsTillItsFaceIsOverIt;
    [Test]
    procedure TestTheBargeIsDrawnUpSmoothlyToJustUnderTheFace;
    [Test]
    procedure TestInALiftItStopsARidersHeightLower;
    [Test]
    procedure TestTheHeldBargeRidesWithTheFace;
    [Test]
    procedure TestItSeizesThenThrowsAtTheHero;
    [Test]
    procedure TestALiftEndsInAPress;
    [Test]
    procedure TestWithNoHeroItThrowsAtTheHarbour;
    [Test]
    procedure TestOneBargeAtATime;
    [Test]
    procedure TestSoftFromTheHoldTillItIsCold;
    [Test]
    procedure TestItHeatsAsItHoldsAndCoolsThroughItsWindow;
    [Test]
    procedure TestColdAgainItTakesTheNext;
    [Test]
    procedure TestItTellsItsWindowOverOnce;
    [Test]
    procedure TestToldToWaitItTakesNoBargeTillTheWaitIsLifted;
    [Test]
    procedure TestAClearStowsIt;
    [Test]
    procedure TestDeckDistanceIsToTheNearestPointOfTheDeck;
  end;

implementation

uses
  System.Math,
  System.SysUtils,
  Game.Space;

const
  // The face of a magnet under the hanging hull, over the middle of the
  // screen
  FaceX = 256.0;
  FaceY = 190.0;
  BargeWidth = 67.0;
  // The caller's numbers of the barges
  NearIndex = 3;
  LowIndex = 5;
  FarIndex = 7;
  // A cycle is over well within this: ten seconds
  CycleTicks = 330;
  Slack = 0.01;

function At(AX, AY: Single): TSdlFPoint;
begin
  Result.X := AX;
  Result.Y := AY;
end;

function BargeAt(AIndex: Integer; ALeft, ATop: Single;
  AHeroAboard: Boolean = False): TMagnetBarge;
begin
  Result.Index := AIndex;
  Result.Left := ALeft;
  Result.Top := ATop;
  Result.Width := BargeWidth;
  Result.HeroAboard := AHeroAboard;
end;

// Under the face, a lane below it
function NearBarge(AHeroAboard: Boolean = False): TMagnetBarge;
begin
  Result := BargeAt(NearIndex, FaceX - BargeWidth / 2, FaceY + 40, AHeroAboard);
end;

// Under the face too, lower: in reach, farther than the near one
function LowBarge(AHeroAboard: Boolean = False): TMagnetBarge;
begin
  Result := BargeAt(LowIndex, FaceX - BargeWidth / 2, FaceY + 90, AHeroAboard);
end;

// At the left edge of the screen: in sight, out of reach
function FarBarge: TMagnetBarge;
begin
  Result := BargeAt(FarIndex, 8, FaceY + 50);
end;

procedure TMagnetTests.Setup;
begin
  FMagnet := TMagnet.Create;
  FSight := Default(TMagnetSight);
  FSight.Face := At(FaceX, FaceY);
  FSight.HeroAlive := True;
  FSight.Hero := At(200, 320);
  FSight.Harbour := At(256, 352);
  FSeen := Default(TCuesSeen);
end;

procedure TMagnetTests.TearDown;
begin
  FMagnet.Free;
end;

procedure TMagnetTests.See(const ABarges: array of TMagnetBarge);
begin
  FSight.Barges := [];
  for var Barge in ABarges do
    FSight.Barges := FSight.Barges + [Barge];
end;

procedure TMagnetTests.Step;
begin
  var Cue := FMagnet.Tick(FSight);
  if Cue.Started then
    Inc(FSeen.Started);
  if Cue.Caught then
  begin
    Inc(FSeen.Caught);
    FSeen.Barge := Cue.Barge;
  end;
  if Cue.Seized then
  begin
    Inc(FSeen.Seized);
    FSeen.Barge := Cue.Barge;
    FSeen.Pressed := Cue.Pressed;
    FSeen.Snug := Cue.Snug;
  end;
  if Cue.Thrown then
  begin
    Inc(FSeen.Thrown);
    FSeen.Aim := Cue.Aim;
  end;
  if Cue.Cooled then
    Inc(FSeen.Cooled);
end;

function TMagnetTests.StepTill(AStage: TMagnetStage; ALimit: Integer): Integer;
begin
  Result := 0;
  while FMagnet.Stage <> AStage do
  begin
    Step;
    Inc(Result);
    if Result > ALimit then
      Assert.Fail(Format('Not at stage %d in %d ticks', [Ord(AStage), ALimit]));
  end;
end;

procedure TMagnetTests.BringOut;
begin
  FMagnet.Deploy;
  StepTill(mgSeeking, CycleTicks);
end;

procedure TMagnetTests.CatchNear(AHeroAboard: Boolean);
begin
  BringOut;
  See([NearBarge(AHeroAboard)]);
  StepTill(mgReaching, CycleTicks);
end;

procedure TMagnetTests.TestStowedItDoesNothing;
begin
  See([NearBarge()]);
  for var i := 1 to CycleTicks do
    Step;
  Assert.AreEqual<TMagnetStage>(mgStowed, FMagnet.Stage, 'Stowed');
  Assert.AreEqual(0.0, Double(FMagnet.OutAt(1)), Slack, 'In the belly');
  Assert.AreEqual(0, FSeen.Started + FSeen.Caught, 'It told nothing');
  Assert.IsFalse(FMagnet.Soft, 'Not soft');
  Assert.IsFalse(FMagnet.Holds, 'It holds nothing');
end;

procedure TMagnetTests.TestDeployedItWaitsThenSlidesOutAndTellsItsStartOnce;
begin
  FMagnet.Deploy;
  var LastOut: Single := 0;
  var WaitedTicks := 0;
  while FMagnet.Stage <> mgSeeking do
  begin
    Step;
    var Shown := FMagnet.OutAt(1);
    Assert.IsTrue(Shown >= LastOut - Slack, 'It slid back');
    if FSeen.Started = 0 then
    begin
      Inc(WaitedTicks);
      Assert.AreEqual(0.0, Double(Shown), Slack, 'It moved before it told its start');
    end;
    LastOut := Shown;
    Assert.IsTrue(WaitedTicks <= CycleTicks, 'It never started');
  end;
  Assert.IsTrue(WaitedTicks > 1, 'A breath before it moves');
  Assert.AreEqual(1, FSeen.Started, 'Its start told once');
  Assert.AreEqual(1.0, Double(FMagnet.OutAt(1)), Slack, 'Out of the belly');
  for var i := 1 to CycleTicks do
    Step;
  Assert.AreEqual(1, FSeen.Started, 'And never again');
end;

procedure TMagnetTests.TestDeployedTwiceItComesOutOnce;
begin
  FMagnet.Deploy;
  var Alone := StepTill(mgSeeking, CycleTicks);
  FMagnet.Clear;
  FMagnet.Deploy;
  for var i := 1 to 10 do
    Step;
  FMagnet.Deploy;
  Assert.AreEqual(Alone, 10 + StepTill(mgSeeking, CycleTicks),
    'A second word does not start it anew');
end;

procedure TMagnetTests.TestItCatchesTheNearestBargeInReach;
begin
  BringOut;
  See([LowBarge(), NearBarge()]);
  StepTill(mgReaching, CycleTicks);
  Assert.AreEqual(1, FSeen.Caught, 'A catch told');
  Assert.AreEqual(NearIndex, FSeen.Barge, 'The nearer one');
  Assert.AreEqual(NearIndex, FMagnet.Load, 'Its load');
  Assert.IsTrue(FMagnet.Holds, 'It holds it');
  Assert.IsFalse(FMagnet.Lifts, 'Nobody aboard: no lift');
end;

procedure TMagnetTests.TestByItsRuleItTakesHisBargeFirst;
begin
  FMagnet.Rule := mrHisBarge;
  BringOut;
  See([NearBarge(), LowBarge(True)]);
  StepTill(mgReaching, CycleTicks);
  Assert.AreEqual(LowIndex, FSeen.Barge, 'His barge, though another is nearer');
  Assert.IsTrue(FMagnet.Lifts, 'With him aboard: a lift');

  FMagnet.Clear;
  FMagnet.Rule := mrNearest;
  BringOut;
  StepTill(mgReaching, CycleTicks);
  Assert.AreEqual(NearIndex, FSeen.Barge, 'The nearest by the other rule');
end;

procedure TMagnetTests.TestABargeOutOfSightIsNotTaken;
var
  Over: Single;
begin
  BringOut;
  See([BargeAt(NearIndex, ScreenWidth - BargeWidth / 4, FaceY + 40)]);
  FSight.Face.X := ScreenWidth - BargeWidth;
  for var i := 1 to CycleTicks do
  begin
    Step;
    Assert.IsFalse(FMagnet.Wants(Over), 'Tick ' + i.ToString + ': it wants it');
  end;
  Assert.AreEqual(0, FSeen.Caught, 'Not caught');
end;

procedure TMagnetTests.TestOutOfReachItOnlyWantsTillItsFaceIsOverIt;
var
  Over: Single;
begin
  BringOut;
  See([FarBarge()]);
  for var i := 1 to CycleTicks do
    Step;
  Assert.AreEqual(0, FSeen.Caught, 'Not caught from afar');
  Assert.IsTrue(FMagnet.Wants(Over), 'It wants it');
  var Middle: Single := FarBarge().Left + BargeWidth / 2;
  Assert.AreEqual(Double(Middle), Double(Over), Slack, 'Over the middle of its deck');

  FSight.Face.X := Middle;
  Step;
  Assert.AreEqual(1, FSeen.Caught, 'Caught once the face is over it');
  Assert.IsFalse(FMagnet.Wants(Over), 'It wants no more');
end;

procedure TMagnetTests.TestTheBargeIsDrawnUpSmoothlyToJustUnderTheFace;
const
  // A cell a tick would be a jump
  MostWay = 8.0;
begin
  CatchNear(False);
  var Start := NearBarge();
  Assert.AreEqual(Double(Start.Top), Double(FMagnet.LoadTop), Slack,
    'From where it was caught');
  var Left := FMagnet.LoadLeft;
  var Top := FMagnet.LoadTop;
  while FMagnet.Stage = mgReaching do
  begin
    Step;
    Assert.AreEqual(Double(FMagnet.LoadLeft - Left), Double(FMagnet.WayX), Slack,
      'The way across is what it went');
    Assert.AreEqual(Double(FMagnet.LoadTop - Top), Double(FMagnet.WayY), Slack,
      'The way down is what it went');
    Assert.IsTrue(Hypot(FMagnet.WayX, FMagnet.WayY) < MostWay, 'A jump');
    Assert.IsTrue(FMagnet.LoadTop <= Top + Slack, 'It sank');
    Left := FMagnet.LoadLeft;
    Top := FMagnet.LoadTop;
  end;
  Assert.AreEqual<TMagnetStage>(mgHolding, FMagnet.Stage, 'Held');
  Assert.AreEqual(Double(FaceX), Double(FMagnet.LoadLeft + BargeWidth / 2), Slack,
    'Its middle under the face');
  Assert.IsTrue(FMagnet.LoadTop > FaceY, 'Under the face');
  Assert.IsTrue(FMagnet.LoadTop < FaceY + RiderHeight / 2, 'Close under it');
end;

procedure TMagnetTests.TestInALiftItStopsARidersHeightLower;
begin
  CatchNear(True);
  Assert.IsTrue(FMagnet.Lifts, 'A lift');
  StepTill(mgHolding, CycleTicks);
  var Head := FMagnet.LoadTop - RiderHeight;
  Assert.IsTrue(Head > FaceY, 'His head clear of the face');
  Assert.IsTrue(Head < FaceY + RiderHeight / 2, 'And close under it');
end;

procedure TMagnetTests.TestTheHeldBargeRidesWithTheFace;
const
  HullWayX = 1.5;
  HullWayY = -0.5;
begin
  CatchNear(False);
  StepTill(mgHolding, CycleTicks);
  for var i := 1 to 10 do
  begin
    FSight.Face.X := FSight.Face.X + HullWayX;
    FSight.Face.Y := FSight.Face.Y + HullWayY;
    Step;
    Assert.AreEqual(Double(HullWayX), Double(FMagnet.WayX), Slack,
      'Tick ' + i.ToString + ': across with the face');
    Assert.AreEqual(Double(HullWayY), Double(FMagnet.WayY), Slack,
      'Tick ' + i.ToString + ': up with the face');
  end;
end;

procedure TMagnetTests.TestItSeizesThenThrowsAtTheHero;
begin
  CatchNear(False);
  while FSeen.Seized = 0 do
  begin
    Step;
    Assert.IsTrue(FMagnet.Stage <> mgSeeking, 'It let the barge go unseized');
  end;
  Assert.AreEqual(0, FSeen.Thrown, 'Seized before it is thrown');
  Assert.AreEqual(NearIndex, FSeen.Barge, 'The barge it held');
  Assert.IsFalse(FSeen.Pressed, 'Nobody aboard: no press');
  Assert.AreEqual(Double(FaceX), Double(FSeen.Snug.X), Slack, 'Snug under the face');
  Assert.IsTrue((FSeen.Snug.Y > FaceY) and (FSeen.Snug.Y < FaceY + RiderHeight / 2),
    'Snug close under it');
  Assert.IsFalse(FMagnet.Holds, 'The barge is the magnet''s no more');
  Assert.AreEqual(NoBarge, FMagnet.Load, 'No load');
  Assert.AreEqual(0.0, Double(Hypot(FMagnet.WayX, FMagnet.WayY)), Slack,
    'No way left to carry it');

  FSight.Hero := At(140, 300);
  StepTill(mgCooling, CycleTicks);
  Assert.AreEqual(1, FSeen.Thrown, 'Thrown once');
  Assert.AreEqual(140.0, Double(FSeen.Aim.X), Slack, 'At where the hero is now');
  Assert.AreEqual(300.0, Double(FSeen.Aim.Y), Slack, 'At where the hero is now');
  Assert.AreEqual(1, FSeen.Seized, 'Seized once');
end;

procedure TMagnetTests.TestALiftEndsInAPress;
begin
  CatchNear(True);
  StepTill(mgCooling, CycleTicks);
  Assert.AreEqual(1, FSeen.Seized, 'Seized');
  Assert.IsTrue(FSeen.Pressed, 'Pressed');
end;

procedure TMagnetTests.TestWithNoHeroItThrowsAtTheHarbour;
begin
  CatchNear(False);
  FSight.HeroAlive := False;
  StepTill(mgCooling, CycleTicks);
  Assert.AreEqual(Double(FSight.Harbour.X), Double(FSeen.Aim.X), Slack, 'Across');
  Assert.AreEqual(Double(FSight.Harbour.Y), Double(FSeen.Aim.Y), Slack, 'Down');
end;

procedure TMagnetTests.TestOneBargeAtATime;
begin
  BringOut;
  See([NearBarge(), LowBarge()]);
  StepTill(mgReaching, CycleTicks);
  // The caught one is the caller's no more to tell of
  See([LowBarge()]);
  while FSeen.Thrown = 0 do
  begin
    Step;
    Assert.AreEqual(1, FSeen.Caught, 'A second catch before the throw');
  end;
end;

procedure TMagnetTests.TestSoftFromTheHoldTillItIsCold;
begin
  BringOut;
  Assert.IsFalse(FMagnet.Soft, 'Cold and empty: armour');
  See([NearBarge()]);
  StepTill(mgReaching, CycleTicks);
  while FMagnet.Stage = mgReaching do
  begin
    Assert.IsFalse(FMagnet.Soft, 'The barge on its way: armour still');
    Step;
  end;
  See([]);
  while FMagnet.Stage <> mgSeeking do
  begin
    Assert.IsTrue(FMagnet.Soft, Format('Stage %d: soft', [Ord(FMagnet.Stage)]));
    Step;
  end;
  Assert.IsFalse(FMagnet.Soft, 'Cold again: armour');
end;

procedure TMagnetTests.TestItHeatsAsItHoldsAndCoolsThroughItsWindow;
const
  // The window is about three seconds: no shorter than one, no longer
  // than six
  SecondTicks = 33;
begin
  CatchNear(False);
  Assert.AreEqual(0.0, Double(FMagnet.HeatAt(1)), Slack, 'Cold on the way up');
  StepTill(mgHolding, CycleTicks);
  var Heat: Single := 0;
  while FMagnet.Stage = mgHolding do
  begin
    Step;
    Assert.IsTrue(FMagnet.HeatAt(1) >= Heat - Slack, 'It cooled in the hold');
    Heat := FMagnet.HeatAt(1);
  end;
  Assert.AreEqual(1.0, Double(Heat), Slack, 'Hot by the end of the hold');

  StepTill(mgCooling, CycleTicks);
  var Lasted := 0;
  while FMagnet.Stage = mgCooling do
  begin
    Step;
    Inc(Lasted);
    Assert.IsTrue(FMagnet.HeatAt(1) <= Heat + Slack, 'It heated in the window');
    Heat := FMagnet.HeatAt(1);
  end;
  Assert.AreEqual(0.0, Double(Heat), Slack, 'Cold at the window''s end');
  Assert.IsTrue(Lasted > SecondTicks, 'A window to strike in');
  Assert.IsTrue(Lasted < 6 * SecondTicks, 'And not an endless one');
end;

procedure TMagnetTests.TestColdAgainItTakesTheNext;
begin
  BringOut;
  See([NearBarge(), LowBarge()]);
  StepTill(mgCooling, CycleTicks);
  See([LowBarge()]);
  StepTill(mgSeeking, CycleTicks);
  StepTill(mgReaching, CycleTicks);
  Assert.AreEqual(2, FSeen.Caught, 'A second catch');
  Assert.AreEqual(LowIndex, FSeen.Barge, 'The barge left');
end;

procedure TMagnetTests.TestItTellsItsWindowOverOnce;
begin
  CatchNear(False);
  StepTill(mgCooling, CycleTicks);
  Assert.AreEqual(0, FSeen.Cooled, 'Not while it cools');
  StepTill(mgSeeking, CycleTicks);
  Assert.AreEqual(1, FSeen.Cooled, 'Told as it is cold again');
  See([]);
  for var i := 1 to CycleTicks do
    Step;
  Assert.AreEqual(1, FSeen.Cooled, 'Once a window');
end;

procedure TMagnetTests.TestToldToWaitItTakesNoBargeTillTheWaitIsLifted;
begin
  BringOut;
  See([NearBarge()]);
  FSight.Waits := True;
  for var i := 1 to CycleTicks do
    Step;
  Assert.AreEqual<TMagnetStage>(mgSeeking, FMagnet.Stage, 'Still looking');
  Assert.AreEqual(0, FSeen.Caught, 'Nothing caught while it waits');
  Assert.IsFalse(FMagnet.Soft, 'Cold while it waits');
  FSight.Waits := False;
  Step;
  Assert.AreEqual(1, FSeen.Caught, 'Caught at once once the wait is lifted');
end;

procedure TMagnetTests.TestAClearStowsIt;
begin
  CatchNear(False);
  StepTill(mgHolding, CycleTicks);
  Step;
  FMagnet.Clear;
  Assert.AreEqual<TMagnetStage>(mgStowed, FMagnet.Stage, 'Stowed');
  Assert.AreEqual(0.0, Double(FMagnet.OutAt(1)), Slack, 'In the belly');
  Assert.AreEqual(0.0, Double(FMagnet.HeatAt(1)), Slack, 'Cold');
  Assert.IsFalse(FMagnet.Soft, 'Not soft');
  Assert.IsFalse(FMagnet.Holds, 'It holds nothing');
  Assert.AreEqual(NoBarge, FMagnet.Load, 'No load');
  var Before := FSeen;
  for var i := 1 to CycleTicks do
    Step;
  Assert.AreEqual(Before.Caught + Before.Seized + Before.Thrown,
    FSeen.Caught + FSeen.Seized + FSeen.Thrown, 'It tells nothing more');
end;

procedure TMagnetTests.TestDeckDistanceIsToTheNearestPointOfTheDeck;
begin
  var Face := At(100, 50);
  Assert.AreEqual(30.0, Double(DeckDistance(Face, BargeAt(0, 80, 80))), Slack,
    'Over the deck: the drop to it');
  Assert.AreEqual(50.0, Double(DeckDistance(Face, BargeAt(0, 140, 80))), Slack,
    'Left of it: to its left end');
  Assert.AreEqual(50.0, Double(DeckDistance(Face, BargeAt(0, 60 - BargeWidth, 80))),
    Slack, 'Right of it: to its right end');
end;

initialization
  TDUnitX.RegisterTestFixture(TMagnetTests);

end.
