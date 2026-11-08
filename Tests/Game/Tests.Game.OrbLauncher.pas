{
  Tests.Game.OrbLauncher - the orb launcher coming once the Ram hangs: nothing till
  started; started, it appears after the breath, once; it lies on the road
  only once its shroud has put it together, once; a start under way
  changes nothing; it is taken only while it lies; a clear takes it all.
  Where it appears: the middle of the screen, or the next cell when he
  stands there, on the side the screen is wider - never within a cell of
  him.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Game.OrbLauncher;

interface

uses
  DUnitX.TestFramework,
  Game.OrbLauncher;

type
  [TestFixture]
  TOrbLauncherArrivalTests = class
  private
    FArrival: TOrbLauncherArrival;
    // Started and ticked till it appears; the ticks it took
    function TickTillAppear: Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestNothingTillStarted;
    [Test]
    procedure TestAppearsAfterTheBreathOnce;
    [Test]
    procedure TestLiesOnlyOncePutTogether;
    [Test]
    procedure TestAStartUnderWayChangesNothing;
    [Test]
    procedure TestTakenOnlyWhileItLies;
    [Test]
    procedure TestAClearTakesItAll;
    [Test]
    procedure TestInTheMiddleWhenHeStandsAside;
    [Test]
    procedure TestTheNextCellWhenHeStandsThere;
    [Test]
    procedure TestNeverWithinACellOfHim;
  end;

implementation

uses
  System.SysUtils,
  Game.Space;

const
  ManyTicks = 1000;
  Slop = 0.0001;
  Assembling = True;
  PutTogether = False;

procedure TOrbLauncherArrivalTests.Setup;
begin
  FArrival := TOrbLauncherArrival.Create;
end;

procedure TOrbLauncherArrivalTests.TearDown;
begin
  FArrival.Free;
end;

function TOrbLauncherArrivalTests.TickTillAppear: Integer;
begin
  FArrival.Start;
  for var i := 1 to ManyTicks do
    if FArrival.Tick(PutTogether).Appear then
      Exit(i);
  Assert.Fail('It never appeared');
  Result := -1;
end;

procedure TOrbLauncherArrivalTests.TestNothingTillStarted;
begin
  for var i := 1 to ManyTicks do
  begin
    var Cue := FArrival.Tick(PutTogether);
    Assert.IsFalse(Cue.Appear or Cue.Lay, Format('A cue at tick %d', [i]));
  end;
  Assert.IsTrue(FArrival.Stage = olNone, 'Not started');
end;

procedure TOrbLauncherArrivalTests.TestAppearsAfterTheBreathOnce;
begin
  Assert.AreEqual(OrbLauncherBreathTicks, TickTillAppear, 'After the breath');
  Assert.IsTrue(FArrival.Stage = olAppearing, 'Appearing');
  for var i := 1 to ManyTicks do
    Assert.IsFalse(FArrival.Tick(Assembling).Appear, Format('Again at %d', [i]));
end;

procedure TOrbLauncherArrivalTests.TestLiesOnlyOncePutTogether;
begin
  TickTillAppear;
  for var i := 1 to ManyTicks do
    Assert.IsFalse(FArrival.Tick(Assembling).Lay, Format('Lies at %d', [i]));
  Assert.IsTrue(FArrival.Tick(PutTogether).Lay, 'Lies once put together');
  Assert.IsTrue(FArrival.Stage = olLying, 'On the road');
  for var i := 1 to ManyTicks do
    Assert.IsFalse(FArrival.Tick(PutTogether).Lay, Format('Again at %d', [i]));
end;

procedure TOrbLauncherArrivalTests.TestAStartUnderWayChangesNothing;
begin
  FArrival.Start;
  for var i := 1 to OrbLauncherBreathTicks - 1 do
    FArrival.Tick(PutTogether);
  FArrival.Start;
  Assert.IsTrue(FArrival.Tick(PutTogether).Appear, 'The breath not begun again');
  FArrival.Start;
  Assert.IsTrue(FArrival.Stage = olAppearing, 'Still appearing');
end;

procedure TOrbLauncherArrivalTests.TestTakenOnlyWhileItLies;
begin
  FArrival.Start;
  FArrival.Take;
  Assert.IsTrue(FArrival.Stage = olWaiting, 'Not in the breath');
  TickTillAppear;
  FArrival.Take;
  Assert.IsTrue(FArrival.Stage = olAppearing, 'Not while it appears');
  FArrival.Tick(PutTogether);
  FArrival.Take;
  Assert.IsTrue(FArrival.Stage = olTaken, 'Taken off the road');
  for var i := 1 to ManyTicks do
  begin
    var Cue := FArrival.Tick(PutTogether);
    Assert.IsFalse(Cue.Appear or Cue.Lay, Format('A cue at tick %d', [i]));
  end;
end;

procedure TOrbLauncherArrivalTests.TestAClearTakesItAll;
begin
  TickTillAppear;
  FArrival.Tick(PutTogether);
  FArrival.Take;
  FArrival.Clear;
  Assert.IsTrue(FArrival.Stage = olNone, 'None of it');
  Assert.AreEqual(OrbLauncherBreathTicks, TickTillAppear, 'The breath again');
end;

procedure TOrbLauncherArrivalTests.TestInTheMiddleWhenHeStandsAside;
begin
  var Middle: Single := ScreenWidth / 2;
  Assert.AreEqual(Double(Middle), Double(OrbLauncherSpotX(100)), Slop, 'He is left');
  Assert.AreEqual(Double(Middle), Double(OrbLauncherSpotX(400)), Slop, 'He is right');
  Assert.AreEqual(Double(Middle), Double(OrbLauncherSpotX(Middle - OrbLauncherClearance)),
    Slop, 'A cell off');
end;

procedure TOrbLauncherArrivalTests.TestTheNextCellWhenHeStandsThere;
begin
  var Middle: Single := ScreenWidth / 2;
  Assert.AreEqual(Double(Middle + OrbLauncherClearance), Double(OrbLauncherSpotX(Middle)),
    Slop, 'In the middle: to the right');
  Assert.AreEqual(Double(Middle - 10 + OrbLauncherClearance),
    Double(OrbLauncherSpotX(Middle - 10)), Slop, 'A little left: the wider right');
  Assert.AreEqual(Double(Middle + 10 - OrbLauncherClearance),
    Double(OrbLauncherSpotX(Middle + 10)), Slop, 'A little right: the wider left');
end;

procedure TOrbLauncherArrivalTests.TestNeverWithinACellOfHim;
begin
  for var X := 0 to ScreenWidth do
  begin
    var Spot := OrbLauncherSpotX(X);
    Assert.IsTrue(Abs(Spot - X) >= OrbLauncherClearance - Slop,
      Format('He at %d, it at %.1f', [X, Spot]));
    Assert.IsTrue((Spot >= 0) and (Spot <= ScreenWidth),
      Format('On the screen, he at %d', [X]));
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TOrbLauncherArrivalTests);

end.
