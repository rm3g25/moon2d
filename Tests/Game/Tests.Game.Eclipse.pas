{
  Tests.Game.Eclipse - the henshin's scene from the brake to the beam: it
  stands till started and spares the hero from the start to its clear;
  he is caught once, as the road stands, and held from then on, the lift
  counting from the catch; the light goes once he is up - the dark comes
  in, never lightens and holds at its depth, the gauge going out with it
  and the track fading over the same time; the beam starts down once the
  dark is in, falls from the top of the screen onto him and stays, its
  landing flashing and the flash dying; a clear takes it all away.

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
    procedure TestCaughtOnceAsTheRoadStands;
    [Test]
    procedure TestHeldFromTheCatchToTheClear;
    [Test]
    procedure TestTheLiftCountsFromTheCatch;
    [Test]
    procedure TestTheLightGoesOnceHeIsUp;
    [Test]
    procedure TestTheDarkComesInAndHolds;
    [Test]
    procedure TestTheGaugeGoesOutWithTheLight;
    [Test]
    procedure TestTheTrackFadesOverTheDarksTime;
    [Test]
    procedure TestTheBeamStartsOnceTheDarkIsIn;
    [Test]
    procedure TestTheBeamFallsOntoHimAndStays;
    [Test]
    procedure TestTheLandingFlashesAndDies;
    [Test]
    procedure TestAClearTakesItAllAway;
  end;

implementation

uses
  System.SysUtils,
  Game.Belt;

const
  // Enough for the whole scene and well past it
  WholeScene = 300;
  Slop = 0.001;

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
    Assert.IsFalse(Cue.Caught or Cue.Dim or Cue.Beam, 'No cue');
  end;
  Assert.IsFalse(FEclipse.Running, 'Not running');
  Assert.IsFalse(FEclipse.Holds, 'Not held');
  Assert.AreEqual(0.0, Double(FEclipse.Darkness(0)), Slop, 'No dark');
  Assert.AreEqual(0.0, Double(FEclipse.Beam(0)), Slop, 'No beam');
end;

procedure TEclipseTests.TestSparesFromTheStartToTheClear;
begin
  Assert.IsFalse(FEclipse.Spares, 'Not before the brake');
  FEclipse.Start;
  Assert.IsTrue(FEclipse.Spares, 'From the brake on');
  TickTimes(WholeScene);
  Assert.IsTrue(FEclipse.Spares, 'Still, in the beam');
  FEclipse.Clear;
  Assert.IsFalse(FEclipse.Spares, 'Not after a clear');
end;

procedure TEclipseTests.TestCaughtOnceAsTheRoadStands;
begin
  FEclipse.Start;
  var Heard: TArray<Integer> := [];
  for var i := 1 to WholeScene do
    if FEclipse.Tick.Caught then
      Heard := Heard + [i];
  Assert.AreEqual(1, Length(Heard), 'Once');
  Assert.AreEqual(BeltRampTicks, Heard[0], 'As the road stands');
end;

procedure TEclipseTests.TestHeldFromTheCatchToTheClear;
begin
  FEclipse.Start;
  for var i := 1 to WholeScene do
  begin
    FEclipse.Tick;
    if i >= CatchAt then
      Assert.IsTrue(FEclipse.Holds, Format('Held at %d', [i]))
    else
      Assert.IsFalse(FEclipse.Holds, Format('Free at %d', [i]));
  end;
  FEclipse.Clear;
  Assert.IsFalse(FEclipse.Holds, 'Not after a clear');
end;

procedure TEclipseTests.TestTheLiftCountsFromTheCatch;
begin
  Assert.AreEqual(-1, FEclipse.Hoisted, 'Not before the brake');
  FEclipse.Start;
  for var i := 1 to WholeScene do
  begin
    FEclipse.Tick;
    if i < CatchAt then
      Assert.AreEqual(-1, FEclipse.Hoisted, Format('Not caught at %d', [i]))
    else
      Assert.AreEqual(i - CatchAt, FEclipse.Hoisted, Format('At %d', [i]));
  end;
end;

procedure TEclipseTests.TestTheLightGoesOnceHeIsUp;
begin
  FEclipse.Start;
  var Heard: TArray<Integer> := [];
  for var i := 1 to WholeScene do
    if FEclipse.Tick.Dim then
      Heard := Heard + [i];
  Assert.AreEqual(1, Length(Heard), 'Once');
  Assert.AreEqual(DimAt, Heard[0], 'At its tick');
  Assert.IsTrue(DimAt > CatchAt, 'After the catch');
end;

procedure TEclipseTests.TestTheDarkComesInAndHolds;
begin
  FEclipse.Start;
  var Last: Single := 0;
  for var i := 1 to WholeScene do
  begin
    FEclipse.Tick;
    var Dark := FEclipse.Darkness(0);
    if i <= DimAt then
      Assert.AreEqual(0.0, Double(Dark), Slop, Format('Light at %d', [i]));
    Assert.IsTrue(Dark >= Last - Slop, Format('Never lighter, at %d', [i]));
    if i >= DimAt + DarkTicks then
      Assert.AreEqual(Double(DarkDepth), Double(Dark), Slop,
        Format('At its depth at %d', [i]));
    Last := Dark;
  end;
end;

procedure TEclipseTests.TestTheGaugeGoesOutWithTheLight;
begin
  FEclipse.Start;
  for var i := 1 to WholeScene do
  begin
    FEclipse.Tick;
    Assert.AreEqual(Double(FEclipse.Darkness(0) / DarkDepth),
      Double(FEclipse.Fade(0)), Slop, Format('With the dark at %d', [i]));
  end;
  Assert.AreEqual(1.0, Double(FEclipse.Fade(0)), Slop, 'Out');
end;

procedure TEclipseTests.TestTheTrackFadesOverTheDarksTime;
begin
  Assert.AreEqual(Double(DarkTicks),
    Double(EclipseFadeSeconds * LogicTicksPerSecond), Slop,
    'The silence comes as the dark does');
end;

procedure TEclipseTests.TestTheBeamStartsOnceTheDarkIsIn;
begin
  FEclipse.Start;
  var Heard: TArray<Integer> := [];
  for var i := 1 to WholeScene do
    if FEclipse.Tick.Beam then
    begin
      Heard := Heard + [i];
      Assert.AreEqual(Double(DarkDepth), Double(FEclipse.Darkness(0)), Slop,
        'The dark is in');
    end;
  Assert.AreEqual(1, Length(Heard), 'Once');
  Assert.AreEqual(BeamAt, Heard[0], 'At its tick');
end;

procedure TEclipseTests.TestTheBeamFallsOntoHimAndStays;
begin
  FEclipse.Start;
  var Last: Single := 0;
  for var i := 1 to WholeScene do
  begin
    FEclipse.Tick;
    var Reach := FEclipse.Beam(0);
    if i <= BeamAt then
      Assert.AreEqual(0.0, Double(Reach), Slop, Format('No beam at %d', [i]));
    if (i > BeamAt) and (i < BeamAt + BeamFallTicks) then
      Assert.IsTrue((Reach > 0) and (Reach < 1),
        Format('On its way down at %d: %.2f', [i, Reach]));
    Assert.IsTrue(Reach >= Last - Slop, Format('Never back up, at %d', [i]));
    if i >= BeamAt + BeamFallTicks then
      Assert.AreEqual(1.0, Double(Reach), Slop, Format('On him at %d', [i]));
    Last := Reach;
  end;
end;

procedure TEclipseTests.TestTheLandingFlashesAndDies;
begin
  FEclipse.Start;
  TickTimes(BeamAt + BeamFallTicks - 1);
  Assert.AreEqual(0.0, Double(FEclipse.BeamFlash(0)), Slop, 'Not before it lands');
  FEclipse.Tick;
  Assert.AreEqual(1.0, Double(FEclipse.BeamFlash(0)), Slop, 'As it lands');
  TickTimes(BeamFlashTicks div 2);
  var Half := FEclipse.BeamFlash(0);
  Assert.IsTrue((Half > 0) and (Half < 1), Format('Dying: %.2f', [Half]));
  TickTimes(BeamFlashTicks);
  Assert.AreEqual(0.0, Double(FEclipse.BeamFlash(0)), Slop, 'Gone');
end;

procedure TEclipseTests.TestAClearTakesItAllAway;
begin
  FEclipse.Start;
  TickTimes(WholeScene);
  FEclipse.Clear;
  Assert.IsFalse(FEclipse.Running, 'Stands');
  Assert.IsFalse(FEclipse.Holds, 'Not held');
  Assert.AreEqual(-1, FEclipse.Hoisted, 'Not caught');
  Assert.AreEqual(0.0, Double(FEclipse.Darkness(0)), Slop, 'No dark');
  Assert.AreEqual(0.0, Double(FEclipse.Fade(0)), Slop, 'The gauge back');
  Assert.AreEqual(0.0, Double(FEclipse.Beam(0)), Slop, 'No beam');
  Assert.AreEqual(0.0, Double(FEclipse.BeamFlash(0)), Slop, 'No flash');
end;

initialization
  TDUnitX.RegisterTestFixture(TEclipseTests);

end.
