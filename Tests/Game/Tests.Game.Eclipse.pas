{
  Tests.Game.Eclipse - the henshin's scene from the brake to the diamond
  ring: it stands till started and spares the hero from the start to its
  clear; the corona waits for the road to run down, flares and settles
  lower; the darkness comes in with it, never lightens and holds at its
  depth, the track fading out over the same time; the diamond comes
  after the corona, blinks three times and stays lit from the third; a
  clear takes it all away, and outside the scene the gauge is as ever.
  And the diamond's place on the rim: on the side of the hero.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Game.Eclipse;

interface

uses
  DUnitX.TestFramework,
  Game.Eclipse;

type
  [TestFixture]
  TEclipseTests = class
  private
    FEclipse: TEclipseScene;
    procedure TickTimes(ACount: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestStandsTillStarted;
    [Test]
    procedure TestSparesFromTheStartToTheClear;
    [Test]
    procedure TestTheCoronaWaitsForTheRoadToRunDown;
    [Test]
    procedure TestTheCoronaFlaresThenSettlesLower;
    [Test]
    procedure TestTheDarkComesInWithTheCoronaAndHolds;
    [Test]
    procedure TestTheTrackFadesOverTheDarksTime;
    [Test]
    procedure TestTheDiamondComesAfterTheCorona;
    [Test]
    procedure TestTheDiamondBlinksThreeTimesAndStaysLit;
    [Test]
    procedure TestAClearTakesItAllAway;
    [Test]
    procedure TestOutsideTheSceneTheGaugeIsAsEver;
  end;

  [TestFixture]
  TDiamondAngleTests = class
  public
    [Test]
    procedure TestStraightBelowIsDown;
    [Test]
    procedure TestOnTheHerosSide;
  end;

implementation

uses
  System.SysUtils,
  System.Math,
  Sdl2.Core,
  Game.Belt;

const
  // Enough for the whole scene and well past it
  WholeScene = 200;
  Slop = 0.001;
  // The corona at its flare is all but full, settled it is well under it
  FlareLeast = 0.95;
  SettledMost = 0.8;

procedure TEclipseTests.Setup;
begin
  FEclipse := TEclipseScene.Create;
end;

procedure TEclipseTests.TearDown;
begin
  FEclipse.Free;
end;

procedure TEclipseTests.TickTimes(ACount: Integer);
begin
  for var i := 1 to ACount do
    FEclipse.Tick;
end;

procedure TEclipseTests.TestStandsTillStarted;
begin
  for var i := 1 to WholeScene do
  begin
    var Cue := FEclipse.Tick;
    Assert.IsFalse(Cue.Corona or Cue.Diamond, 'No cue');
  end;
  Assert.IsFalse(FEclipse.Running, 'Not running');
  Assert.AreEqual(0.0, Double(FEclipse.Darkness(0)), Slop, 'No dark');
end;

procedure TEclipseTests.TestSparesFromTheStartToTheClear;
begin
  Assert.IsFalse(FEclipse.Spares, 'Not before the brake');
  FEclipse.Start;
  Assert.IsTrue(FEclipse.Spares, 'From the brake on');
  TickTimes(WholeScene);
  Assert.IsTrue(FEclipse.Spares, 'Still, the diamond lit');
  FEclipse.Clear;
  Assert.IsFalse(FEclipse.Spares, 'Not after a clear');
end;

procedure TEclipseTests.TestTheCoronaWaitsForTheRoadToRunDown;
begin
  FEclipse.Start;
  var Heard: TArray<Integer> := [];
  for var i := 1 to WholeScene do
  begin
    if FEclipse.Tick.Corona then
      Heard := Heard + [i];
    if i < BeltRampTicks then
      Assert.AreEqual(0.0, Double(FEclipse.Corona(0)), Slop,
        Format('No corona at %d, the road still running', [i]));
  end;
  Assert.AreEqual(1, Length(Heard), 'Once');
  Assert.AreEqual(BeltRampTicks, Heard[0], 'As the road stands');
end;

procedure TEclipseTests.TestTheCoronaFlaresThenSettlesLower;
begin
  FEclipse.Start;
  var Peak: Single := 0;
  for var i := 1 to WholeScene do
  begin
    FEclipse.Tick;
    Peak := Max(Peak, FEclipse.Corona(0));
  end;
  var Settled := FEclipse.Corona(0);
  Assert.IsTrue(Peak >= FlareLeast, Format('A flare: %.2f', [Peak]));
  Assert.IsTrue(Settled > 0, 'It stays');
  Assert.IsTrue(Settled <= SettledMost, Format('Settled lower: %.2f',
    [Settled]));
end;

procedure TEclipseTests.TestTheDarkComesInWithTheCoronaAndHolds;
begin
  FEclipse.Start;
  var Last: Single := 0;
  for var i := 1 to WholeScene do
  begin
    FEclipse.Tick;
    var Dark := FEclipse.Darkness(0);
    if i <= CoronaAt then
      Assert.AreEqual(0.0, Double(Dark), Slop,
        Format('Light at %d, before the corona', [i]));
    Assert.IsTrue(Dark >= Last - Slop, Format('Never lighter, at %d', [i]));
    if i >= CoronaAt + DarkTicks then
      Assert.AreEqual(Double(DarkDepth), Double(Dark), Slop,
        Format('At its depth at %d', [i]));
    Last := Dark;
  end;
end;

procedure TEclipseTests.TestTheTrackFadesOverTheDarksTime;
begin
  Assert.AreEqual(Double(DarkTicks),
    Double(EclipseFadeSeconds * LogicTicksPerSecond), Slop,
    'The silence comes as the dark does');
end;

procedure TEclipseTests.TestTheDiamondComesAfterTheCorona;
begin
  FEclipse.Start;
  var Heard: TArray<Integer> := [];
  for var i := 1 to WholeScene do
  begin
    if FEclipse.Tick.Diamond then
      Heard := Heard + [i];
    if i < DiamondAt then
      Assert.AreEqual(0.0, Double(FEclipse.Diamond), Slop,
        Format('Dark at %d', [i]));
  end;
  Assert.AreEqual(1, Length(Heard), 'Once');
  Assert.AreEqual(DiamondAt, Heard[0], 'At its tick');
  Assert.IsTrue(DiamondAt > CoronaAt, 'After the corona');
end;

procedure TEclipseTests.TestTheDiamondBlinksThreeTimesAndStaysLit;
begin
  FEclipse.Start;
  var Lightings := 0;
  var Lit := False;
  for var i := 1 to WholeScene do
  begin
    FEclipse.Tick;
    var LitNow := FEclipse.Diamond > 0;
    if LitNow and not Lit then
      Inc(Lightings);
    Lit := LitNow;
  end;
  Assert.AreEqual(DiamondBlinks, Lightings, 'Three blinks');
  Assert.IsTrue(Lit, 'Lit from the third on');
end;

procedure TEclipseTests.TestAClearTakesItAllAway;
begin
  FEclipse.Start;
  TickTimes(WholeScene);
  FEclipse.Clear;
  Assert.IsFalse(FEclipse.Running, 'Stands');
  Assert.AreEqual(0.0, Double(FEclipse.Darkness(0)), Slop, 'No dark');
  Assert.AreEqual(0.0, Double(FEclipse.Corona(0)), Slop, 'No corona');
  Assert.AreEqual(0.0, Double(FEclipse.Diamond), Slop, 'No diamond');
end;

procedure TEclipseTests.TestOutsideTheSceneTheGaugeIsAsEver;
begin
  var Gauge := FEclipse.Gauge(0.5);
  Assert.AreEqual(0.0, Double(Gauge.Corona), Slop, 'No corona');
  Assert.AreEqual(0.0, Double(Gauge.Covered), Slop, 'Its own light');
  Assert.AreEqual(0.0, Double(Gauge.Diamond), Slop, 'No diamond');
end;

function At(AX, AY: Single): TSdlFPoint;
begin
  Result.X := AX;
  Result.Y := AY;
end;

procedure TDiamondAngleTests.TestStraightBelowIsDown;
begin
  Assert.AreEqual(Double(Pi / 2),
    Double(DiamondAngleToward(At(256, 40), At(256, 300))), Slop);
end;

procedure TDiamondAngleTests.TestOnTheHerosSide;
begin
  var Left := DiamondAngleToward(At(256, 40), At(60, 330));
  var Right := DiamondAngleToward(At(256, 40), At(450, 330));
  Assert.IsTrue((Left > Pi / 2) and (Left < Pi), 'Lower left');
  Assert.IsTrue((Right > 0) and (Right < Pi / 2), 'Lower right');
end;

initialization
  TDUnitX.RegisterTestFixture(TEclipseTests);
  TDUnitX.RegisterTestFixture(TDiamondAngleTests);

end.
