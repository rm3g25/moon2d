{
  Tests.Game.Eclipse - the henshin's scene from the brake to the beam, the
  ring of the rite handed in as the game hands it: it stands till started
  and spares the hero from the start to its clear; he is caught once, as
  the road stands, and held from then on; he is lifted once, as the first
  orb sits, and not before the catch, the lift counting from then; the dark
  follows the ring, no quicker than its pace and never lighter, the gauge
  going out with it, and goes all the way once the ring is full; the beam
  waits for the full ring, falls onto him and stays, its landing flashing
  and the flash dying; the orbs are told to go in once, the ring's time in
  the beam after the landing; the heart's ripples run from the lift till
  then; a clear takes it all away.

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
    // The ring as the test makes it gather: empty till FFillFrom, then an
    // orb more every FEvery ticks, to FCount; the ticks of the scene so far
    FFillFrom: Integer;
    FEvery: Integer;
    FCount: Integer;
    FTicks: Integer;
    function Ring: TRingProgress;
    function Tick: TEclipseCue;
    procedure TickTimes(ACount: Integer);
    // The ring starts gathering at ATick, an orb every AEvery ticks
    procedure FillFrom(ATick, AEvery: Integer);
    // The tick the full ring is handed in, for the ring FillFrom made
    function FullAt: Integer;
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
    procedure TestNotLiftedTillAnOrbSits;
    [Test]
    procedure TestLiftedOnceAsTheFirstOrbSits;
    [Test]
    procedure TestNotLiftedBeforeTheCatch;
    [Test]
    procedure TestTheLiftCountsFromTheFirstOrb;
    [Test]
    procedure TestTheDarkFollowsTheRing;
    [Test]
    procedure TestTheDarkKeepsItsPace;
    [Test]
    procedure TestTheDarkNeverLightens;
    [Test]
    procedure TestTheGaugeGoesOutWithTheLight;
    [Test]
    procedure TestNoBeamTillTheRingIsFull;
    [Test]
    procedure TestTheBeamStartsOnceAsTheRingFills;
    [Test]
    procedure TestWithTheRingFullTheDarkGoesAllTheWay;
    [Test]
    procedure TestTheBeamFallsOntoHimAndStays;
    [Test]
    procedure TestTheLandingFlashesAndDies;
    [Test]
    procedure TestTheOrbsGoInOnceTheRingHasBeatenInTheBeam;
    [Test]
    procedure TestTheRipplesRunFromTheLiftTillTheOrbsGoIn;
    [Test]
    procedure TestAClearTakesItAllAway;
  end;

implementation

uses
  System.SysUtils,
  Game.Belt;

const
  // Enough for the whole scene and well past it
  WholeScene = 400;
  Slop = 0.001;
  // The rite's ring
  RingSeats = 30;
  // A ring that gathers an orb every few ticks from a little after the
  // catch, as the rite's does
  FirstSeatAfterCatch = 15;
  QuickOrbs = 4;

procedure TEclipseTests.Setup;
begin
  FEclipse := TEclipseScene.Create;
  FCount := RingSeats;
  FFillFrom := MaxInt;
  FEvery := 1;
  FTicks := 0;
end;

procedure TEclipseTests.TearDown;
begin
  FEclipse.Free;
end;

function TEclipseTests.Ring: TRingProgress;
begin
  Result.Count := FCount;
  Result.Gathered := 0;
  if FTicks >= FFillFrom then
    Result.Gathered := (FTicks - FFillFrom) div FEvery + 1;
  if Result.Gathered > FCount then
    Result.Gathered := FCount;
end;

// One tick of the scene with the ring as it stands at that tick; the
// ticks count from 1 after the start, as the scene's do
function TEclipseTests.Tick: TEclipseCue;
begin
  Inc(FTicks);
  Result := FEclipse.Tick(Ring);
end;

procedure TEclipseTests.TickTimes(ACount: Integer);
begin
  for var i := 1 to ACount do
    Tick;
end;

procedure TEclipseTests.FillFrom(ATick, AEvery: Integer);
begin
  FFillFrom := ATick;
  FEvery := AEvery;
end;

function TEclipseTests.FullAt: Integer;
begin
  Result := FFillFrom + (FCount - 1) * FEvery;
end;

procedure TEclipseTests.TestStandsTillStarted;
begin
  FillFrom(1, 1);
  for var i := 1 to WholeScene do
  begin
    var Cue := Tick;
    Assert.IsFalse(Cue.Caught or Cue.Lifted or Cue.Beam or Cue.DrawIn,
      'No cue');
  end;
  Assert.IsFalse(FEclipse.Running, 'Not running');
  Assert.IsFalse(FEclipse.Holds, 'Not held');
  Assert.AreEqual(-1, FEclipse.Hoisted, 'Not lifted');
  Assert.AreEqual(0.0, Double(FEclipse.Darkness(0)), Slop, 'No dark');
  Assert.AreEqual(0.0, Double(FEclipse.Beam(0)), Slop, 'No beam');
end;

procedure TEclipseTests.TestSparesFromTheStartToTheClear;
begin
  FillFrom(CatchAt + FirstSeatAfterCatch, QuickOrbs);
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
    if Tick.Caught then
      Heard := Heard + [i];
  Assert.AreEqual(1, Length(Heard), 'Once');
  Assert.AreEqual(BeltRampTicks, Heard[0], 'As the road stands');
end;

procedure TEclipseTests.TestHeldFromTheCatchToTheClear;
begin
  FEclipse.Start;
  for var i := 1 to WholeScene do
  begin
    Tick;
    if i >= CatchAt then
      Assert.IsTrue(FEclipse.Holds, Format('Held at %d', [i]))
    else
      Assert.IsFalse(FEclipse.Holds, Format('Free at %d', [i]));
  end;
  FEclipse.Clear;
  Assert.IsFalse(FEclipse.Holds, 'Not after a clear');
end;

procedure TEclipseTests.TestNotLiftedTillAnOrbSits;
begin
  FEclipse.Start;
  for var i := 1 to WholeScene do
  begin
    var Cue := Tick;
    Assert.IsFalse(Cue.Lifted or Cue.Beam, Format('No cue at %d', [i]));
    Assert.AreEqual(-1, FEclipse.Hoisted, Format('Not lifted at %d', [i]));
    Assert.AreEqual(0.0, Double(FEclipse.Darkness(0)), Slop,
      Format('Light at %d', [i]));
  end;
end;

procedure TEclipseTests.TestLiftedOnceAsTheFirstOrbSits;
begin
  FillFrom(CatchAt + FirstSeatAfterCatch, QuickOrbs);
  FEclipse.Start;
  var Heard: TArray<Integer> := [];
  for var i := 1 to WholeScene do
    if Tick.Lifted then
      Heard := Heard + [i];
  Assert.AreEqual(1, Length(Heard), 'Once');
  Assert.AreEqual(FFillFrom, Heard[0], 'As the first orb sits');
end;

procedure TEclipseTests.TestNotLiftedBeforeTheCatch;
begin
  FillFrom(1, QuickOrbs);
  FEclipse.Start;
  var Heard: TArray<Integer> := [];
  for var i := 1 to WholeScene do
    if Tick.Lifted then
      Heard := Heard + [i];
  Assert.AreEqual(1, Length(Heard), 'Once');
  Assert.AreEqual(CatchAt, Heard[0], 'At the catch, not before');
end;

procedure TEclipseTests.TestTheLiftCountsFromTheFirstOrb;
begin
  FillFrom(CatchAt + FirstSeatAfterCatch, QuickOrbs);
  FEclipse.Start;
  for var i := 1 to WholeScene do
  begin
    Tick;
    if i < FFillFrom then
      Assert.AreEqual(-1, FEclipse.Hoisted, Format('Not lifted at %d', [i]))
    else
      Assert.AreEqual(i - FFillFrom, FEclipse.Hoisted, Format('At %d', [i]));
  end;
end;

procedure TEclipseTests.TestTheDarkFollowsTheRing;
const
  HalfARing = RingSeats div 2;
begin
  FillFrom(CatchAt + 1, 1);
  FEclipse.Start;
  TickTimes(CatchAt);
  Assert.AreEqual(0.0, Double(FEclipse.Darkness(0)), Slop, 'Light till then');
  // Half the ring gathers, then nothing more comes
  TickTimes(HalfARing);
  var Half := Default(TRingProgress);
  Half.Count := RingSeats;
  Half.Gathered := HalfARing;
  for var i := 1 to WholeScene do
  begin
    Inc(FTicks);
    FEclipse.Tick(Half);
  end;
  Assert.AreEqual(Double(DarkDepth / 2), Double(FEclipse.Darkness(1)), Slop,
    'Half dark for half a ring');
end;

procedure TEclipseTests.TestTheDarkKeepsItsPace;
begin
  // The whole ring at once, as the lift comes
  FillFrom(CatchAt, 1);
  FEclipse.Start;
  TickTimes(CatchAt - 1);
  FFillFrom := 1 - RingSeats;
  var Last: Single := 0;
  for var i := 1 to DarkTicks do
  begin
    Tick;
    var Dark := FEclipse.Darkness(1);
    Assert.IsTrue(Dark - Last <= DarkDepth / DarkTicks + Slop,
      Format('No quicker than its pace at %d: %.3f', [i, Dark - Last]));
    Assert.IsTrue(Dark > Last, Format('Deeper at %d', [i]));
    Last := Dark;
  end;
  Assert.AreEqual(Double(DarkDepth), Double(Last), Slop, 'In by then');
end;

procedure TEclipseTests.TestTheDarkNeverLightens;
begin
  FillFrom(CatchAt + FirstSeatAfterCatch, QuickOrbs);
  FEclipse.Start;
  var Last: Single := 0;
  for var i := 1 to WholeScene do
  begin
    // The ring handed in shrinks to nothing halfway: as a rite whose orbs
    // went into him would tell it
    if i = WholeScene div 2 then
      FFillFrom := MaxInt;
    Tick;
    var Dark := FEclipse.Darkness(0);
    Assert.IsTrue(Dark >= Last - Slop, Format('Never lighter, at %d', [i]));
    Last := Dark;
  end;
end;

procedure TEclipseTests.TestTheGaugeGoesOutWithTheLight;
begin
  FillFrom(CatchAt + FirstSeatAfterCatch, QuickOrbs);
  FEclipse.Start;
  for var i := 1 to WholeScene do
  begin
    Tick;
    for var Step := 0 to 2 do
    begin
      var Alpha: Single := Step / 2;
      Assert.AreEqual(Double(FEclipse.Darkness(Alpha) / DarkDepth),
        Double(FEclipse.Fade(Alpha)), Slop, Format('With the dark at %d', [i]));
    end;
  end;
  Assert.AreEqual(1.0, Double(FEclipse.Fade(0)), Slop, 'Out');
end;

procedure TEclipseTests.TestNoBeamTillTheRingIsFull;
begin
  FillFrom(CatchAt + FirstSeatAfterCatch, QuickOrbs);
  FEclipse.Start;
  for var i := 1 to WholeScene do
  begin
    Inc(FTicks);
    // One seat short for good
    var Short := Ring;
    if Short.Gathered >= RingSeats then
      Short.Gathered := RingSeats - 1;
    var Cue := FEclipse.Tick(Short);
    Assert.IsFalse(Cue.Beam or Cue.DrawIn, Format('No cue at %d', [i]));
    Assert.AreEqual(0.0, Double(FEclipse.Beam(0)), Slop,
      Format('No beam at %d', [i]));
  end;
end;

procedure TEclipseTests.TestTheBeamStartsOnceAsTheRingFills;
begin
  FillFrom(CatchAt + FirstSeatAfterCatch, QuickOrbs);
  FEclipse.Start;
  var Heard: TArray<Integer> := [];
  for var i := 1 to WholeScene do
    if Tick.Beam then
      Heard := Heard + [i];
  Assert.AreEqual(1, Length(Heard), 'Once');
  Assert.AreEqual(FullAt, Heard[0], 'As the ring fills');
end;

procedure TEclipseTests.TestWithTheRingFullTheDarkGoesAllTheWay;
begin
  FillFrom(CatchAt + FirstSeatAfterCatch, QuickOrbs);
  FEclipse.Start;
  TickTimes(FullAt);
  // The rite tells no more of its ring: the dark goes on to its depth
  FFillFrom := MaxInt;
  TickTimes(DarkTicks);
  Assert.AreEqual(Double(DarkDepth), Double(FEclipse.Darkness(1)), Slop);
end;

procedure TEclipseTests.TestTheBeamFallsOntoHimAndStays;
begin
  FillFrom(CatchAt + FirstSeatAfterCatch, QuickOrbs);
  FEclipse.Start;
  var Last: Single := 0;
  for var i := 1 to WholeScene do
  begin
    Tick;
    var Reach := FEclipse.Beam(0);
    if i < FullAt then
      Assert.AreEqual(0.0, Double(Reach), Slop, Format('No beam at %d', [i]));
    if (i > FullAt) and (i < FullAt + BeamFallTicks) then
      Assert.IsTrue((Reach > 0) and (Reach < 1),
        Format('On its way down at %d: %.2f', [i, Reach]));
    Assert.IsTrue(Reach >= Last - Slop, Format('Never back up, at %d', [i]));
    if i >= FullAt + BeamFallTicks then
      Assert.AreEqual(1.0, Double(Reach), Slop, Format('On him at %d', [i]));
    Last := Reach;
  end;
end;

procedure TEclipseTests.TestTheLandingFlashesAndDies;
begin
  FillFrom(CatchAt + FirstSeatAfterCatch, QuickOrbs);
  FEclipse.Start;
  TickTimes(FullAt + BeamFallTicks - 1);
  Assert.AreEqual(0.0, Double(FEclipse.BeamFlash(0)), Slop, 'Not before it lands');
  Tick;
  Assert.AreEqual(1.0, Double(FEclipse.BeamFlash(0)), Slop, 'As it lands');
  TickTimes(BeamFlashTicks div 2);
  var Half := FEclipse.BeamFlash(0);
  Assert.IsTrue((Half > 0) and (Half < 1), Format('Dying: %.2f', [Half]));
  TickTimes(BeamFlashTicks);
  Assert.AreEqual(0.0, Double(FEclipse.BeamFlash(0)), Slop, 'Gone');
end;

procedure TEclipseTests.TestTheOrbsGoInOnceTheRingHasBeatenInTheBeam;
begin
  FillFrom(CatchAt + FirstSeatAfterCatch, QuickOrbs);
  FEclipse.Start;
  var Heard: TArray<Integer> := [];
  for var i := 1 to WholeScene do
    if Tick.DrawIn then
      Heard := Heard + [i];
  Assert.AreEqual(1, Length(Heard), 'Once');
  Assert.AreEqual(FullAt + BeamFallTicks + RingInBeamTicks, Heard[0],
    'The ring''s time in the beam after it lands');
end;

procedure TEclipseTests.TestTheRipplesRunFromTheLiftTillTheOrbsGoIn;
begin
  FillFrom(CatchAt + FirstSeatAfterCatch, QuickOrbs);
  FEclipse.Start;
  var DrawInAt := FullAt + BeamFallTicks + RingInBeamTicks;
  for var i := 1 to WholeScene do
  begin
    Tick;
    var Ripple := FEclipse.Ripple(0);
    if (i < FFillFrom) or (i >= DrawInAt) then
      Assert.AreEqual(0.0, Double(Ripple), Slop, Format('Still at %d', [i]))
    else
      Assert.AreEqual(Double(FEclipse.Fade(0)), Double(Ripple), Slop,
        Format('As dark as it is at %d', [i]));
  end;
  Assert.IsTrue(DrawInAt < WholeScene, 'The scene ran far enough');
end;

procedure TEclipseTests.TestAClearTakesItAllAway;
begin
  FillFrom(CatchAt + FirstSeatAfterCatch, QuickOrbs);
  FEclipse.Start;
  TickTimes(WholeScene);
  FEclipse.Clear;
  Assert.IsFalse(FEclipse.Running, 'Stands');
  Assert.IsFalse(FEclipse.Holds, 'Not held');
  Assert.AreEqual(-1, FEclipse.Hoisted, 'Not lifted');
  Assert.AreEqual(0.0, Double(FEclipse.Darkness(0)), Slop, 'No dark');
  Assert.AreEqual(0.0, Double(FEclipse.Fade(0)), Slop, 'The gauge back');
  Assert.AreEqual(0.0, Double(FEclipse.Ripple(0)), Slop, 'No ripples');
  Assert.AreEqual(0.0, Double(FEclipse.Beam(0)), Slop, 'No beam');
  Assert.AreEqual(0.0, Double(FEclipse.BeamFlash(0)), Slop, 'No flash');
end;

initialization
  TDUnitX.RegisterTestFixture(TEclipseTests);

end.
