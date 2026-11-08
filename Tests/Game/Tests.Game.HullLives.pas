{
  Tests.Game.HullLives - the lives of the Ram's bare hull and their bar:
  none till armed - no life to take, no bar, no key; armed, the lives
  follow the grade; the bar comes down into its place first, then lights
  a cell at a time, the terminal's key heard every few cells; an orb takes
  a life and flashes the bar, and the share follows; none is taken past
  the last; a clear takes it all.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Game.HullLives;

interface

uses
  DUnitX.TestFramework,
  Game.HullLives;

type
  [TestFixture]
  THullLivesTests = class
  private
    FLives: THullLives;
    procedure TickTimes(ACount: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestNothingTillArmed;
    [Test]
    procedure TestTheLivesFollowTheGrade;
    [Test]
    procedure TestTheBarComesDownThenLights;
    [Test]
    procedure TestTheKeyEveryFewCells;
    [Test]
    procedure TestAnOrbTakesALifeAndFlashesTheBar;
    [Test]
    procedure TestNoneTakenPastTheLast;
    [Test]
    procedure TestAClearTakesItAll;
  end;

implementation

uses
  System.SysUtils;

const
  Slop = 0.0001;
  ManyTicks = 1000;

procedure THullLivesTests.Setup;
begin
  FLives := THullLives.Create;
end;

procedure THullLivesTests.TearDown;
begin
  FLives.Free;
end;

procedure THullLivesTests.TickTimes(ACount: Integer);
begin
  for var i := 1 to ACount do
    FLives.Tick;
end;

procedure THullLivesTests.TestNothingTillArmed;
begin
  Assert.IsFalse(FLives.Wound, 'No life to take');
  for var i := 1 to ManyTicks do
    Assert.IsFalse(FLives.Tick, 'No key');
  Assert.IsFalse(FLives.Bar(1).Shown, 'No bar');
  Assert.IsFalse(FLives.Armed, 'Not armed');
end;

procedure THullLivesTests.TestTheLivesFollowTheGrade;
begin
  FLives.Arm(1);
  Assert.AreEqual(RamHullLives, FLives.FullLives, 'The first grade');
  Assert.AreEqual(RamHullLives, FLives.Lives, 'All of them');
  FLives.Arm(0.5);
  Assert.AreEqual(RamHullLives div 2, FLives.FullLives, 'Half');
  FLives.Arm(0);
  Assert.AreEqual(1, FLives.FullLives, 'One at least');
end;

procedure THullLivesTests.TestTheBarComesDownThenLights;
begin
  FLives.Arm(1);
  var Bar := FLives.Bar(0);
  Assert.IsTrue(Bar.Shown, 'Shown from the start');
  Assert.AreEqual(0.0, Double(Bar.Drop), Slop, 'Over the top edge');
  var Last: Single := 0;
  for var i := 1 to HullBarDropTicks do
  begin
    FLives.Tick;
    Bar := FLives.Bar(1);
    Assert.IsTrue(Bar.Drop >= Last, Format('Never up at tick %d', [i]));
    Assert.AreEqual(0, Bar.Lit, Format('No cell while it comes down, tick %d', [i]));
    Last := Bar.Drop;
  end;
  Assert.AreEqual(1.0, Double(Last), Slop, 'In its place');
  var LastLit := 0;
  for var i := 1 to HullBarBootTicks do
  begin
    FLives.Tick;
    Bar := FLives.Bar(1);
    Assert.IsTrue(Bar.Lit >= LastLit, Format('Never fewer at tick %d', [i]));
    LastLit := Bar.Lit;
  end;
  Assert.AreEqual(HullBarCells, LastLit, 'All lit');
  Assert.AreEqual(1.0, Double(Bar.Share), Slop, 'Full');
  TickTimes(ManyTicks);
  Assert.AreEqual(HullBarCells, FLives.Bar(1).Lit, 'Stays lit');
  Assert.AreEqual(1.0, Double(FLives.Bar(0).Drop), Slop, 'Stays in its place');
end;

procedure THullLivesTests.TestTheKeyEveryFewCells;
begin
  FLives.Arm(1);
  var Keys := 0;
  for var i := 1 to ManyTicks do
    if FLives.Tick then
      Inc(Keys);
  Assert.AreEqual(HullBarCells div HullBarKeyCells, Keys, 'A key every few cells');
end;

procedure THullLivesTests.TestAnOrbTakesALifeAndFlashesTheBar;
begin
  FLives.Arm(1);
  TickTimes(ManyTicks);
  Assert.IsTrue(FLives.Bar(1).HitTicks >= HullBarHitTicks, 'No flash before');
  Assert.IsTrue(FLives.Wound, 'Taken');
  Assert.AreEqual(RamHullLives - 1, FLives.Lives, 'A life gone');
  Assert.AreEqual(0, FLives.Bar(1).HitTicks, 'The flash');
  Assert.AreEqual(Double(RamHullLives - 1) / RamHullLives,
    Double(FLives.Bar(1).Share), Slop, 'The share follows');
  TickTimes(HullBarHitTicks);
  Assert.IsTrue(FLives.Bar(1).HitTicks >= HullBarHitTicks, 'The flash gone');
end;

procedure THullLivesTests.TestNoneTakenPastTheLast;
begin
  FLives.Arm(1);
  for var i := 1 to RamHullLives do
    Assert.IsTrue(FLives.Wound, Format('Life %d taken', [i]));
  Assert.AreEqual(0, FLives.Lives, 'None left');
  Assert.IsFalse(FLives.Wound, 'None to take');
  Assert.AreEqual(0, FLives.Lives, 'Still none');
  Assert.AreEqual(0.0, Double(FLives.Bar(1).Share), Slop, 'The bar empty');
  Assert.IsTrue(FLives.Bar(1).Shown, 'Still shown');
end;

procedure THullLivesTests.TestAClearTakesItAll;
begin
  FLives.Arm(1);
  TickTimes(ManyTicks);
  FLives.Wound;
  FLives.Clear;
  Assert.IsFalse(FLives.Armed, 'Not armed');
  Assert.IsFalse(FLives.Bar(1).Shown, 'No bar');
  Assert.IsFalse(FLives.Wound, 'No life to take');
  Assert.IsFalse(FLives.Tick, 'No key');
end;

initialization
  TDUnitX.RegisterTestFixture(THullLivesTests);

end.
