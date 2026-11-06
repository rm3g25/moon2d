{
  Tests.Game.Eclipse - the henshin's scene from the brake to the beam, the
  ring of the rite handed in as the game hands it: it stands till started
  and spares the hero from the start to its clear; the rite is called once,
  as the road stands; the first orb in its seat is told once, and not
  before the call; the dark
  follows the ring, no quicker than its pace and never lighter, the gauge
  going out with it, and goes all the way once the ring is full; the beam
  waits for the full ring, falls onto him and stays, its landing flashing
  and the flash dying; the orbs are told to go in once, the ring's time in
  the beam after the landing; the heart's ripples run from the first seat
  till then; a clear takes it all away. The controls are the hero's all
  through the scene: it holds nothing. The burst's strike tears the dark
  off in one tick, takes the beam and the ripples, leaves the gauge out
  for good and cues nothing more; the scene spares him on till its clear,
  and a strike outside it is nothing. Told to spare him no more - at the
  wheel - it does not, running on, till it starts anew.

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
    procedure TestCalledOnceAsTheRoadStands;
    [Test]
    procedure TestNothingTillAnOrbSits;
    [Test]
    procedure TestTheFirstSeatIsToldOnce;
    [Test]
    procedure TestNoFirstSeatBeforeTheCall;
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
    procedure TestTheRipplesRunFromTheFirstSeatTillTheOrbsGoIn;
    [Test]
    procedure TestAClearTakesItAllAway;
    [Test]
    procedure TestTheStrikeTearsTheDarkOffInOneTick;
    [Test]
    procedure TestAfterTheStrikeTheGaugeStaysOut;
    [Test]
    procedure TestTheStrikeTakesTheBeamAndTheRipples;
    [Test]
    procedure TestNothingIsCuedAfterTheStrike;
    [Test]
    procedure TestStruckItSparesHimTillTheClear;
    [Test]
    procedure TestNoStrikeOutsideTheScene;
    [Test]
    procedure TestToldSoItSparesHimNoMoreTillANewStart;
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
  // call, as the rite's does
  FirstSeatAfterCall = 15;
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
    Assert.IsFalse(Cue.Called or Cue.FirstSeat or Cue.Beam or Cue.DrawIn,
      'No cue');
  end;
  Assert.IsFalse(FEclipse.Running, 'Not running');
  Assert.AreEqual(0.0, Double(FEclipse.Darkness(0)), Slop, 'No dark');
  Assert.AreEqual(0.0, Double(FEclipse.Beam(0)), Slop, 'No beam');
end;

procedure TEclipseTests.TestSparesFromTheStartToTheClear;
begin
  FillFrom(CallAt + FirstSeatAfterCall, QuickOrbs);
  Assert.IsFalse(FEclipse.Spares, 'Not before the brake');
  FEclipse.Start;
  Assert.IsTrue(FEclipse.Spares, 'From the brake on');
  TickTimes(WholeScene);
  Assert.IsTrue(FEclipse.Spares, 'Still, in the beam');
  FEclipse.Clear;
  Assert.IsFalse(FEclipse.Spares, 'Not after a clear');
end;

procedure TEclipseTests.TestCalledOnceAsTheRoadStands;
begin
  FEclipse.Start;
  var Heard: TArray<Integer> := [];
  for var i := 1 to WholeScene do
    if Tick.Called then
      Heard := Heard + [i];
  Assert.AreEqual(1, Length(Heard), 'Once');
  Assert.AreEqual(BeltRampTicks, Heard[0], 'As the road stands');
end;

procedure TEclipseTests.TestNothingTillAnOrbSits;
begin
  FEclipse.Start;
  for var i := 1 to WholeScene do
  begin
    var Cue := Tick;
    Assert.IsFalse(Cue.FirstSeat or Cue.Beam or Cue.DrawIn,
      Format('No cue at %d', [i]));
    Assert.AreEqual(0.0, Double(FEclipse.Darkness(1)), Slop,
      Format('Light at %d', [i]));
    Assert.AreEqual(0.0, Double(FEclipse.Ripple(1)), Slop,
      Format('No ripples at %d', [i]));
  end;
end;

procedure TEclipseTests.TestTheFirstSeatIsToldOnce;
begin
  FillFrom(CallAt + FirstSeatAfterCall, QuickOrbs);
  FEclipse.Start;
  var Heard: TArray<Integer> := [];
  for var i := 1 to WholeScene do
    if Tick.FirstSeat then
      Heard := Heard + [i];
  Assert.AreEqual(1, Length(Heard), 'Once');
  Assert.AreEqual(FFillFrom, Heard[0], 'As the first orb sits');
end;

procedure TEclipseTests.TestNoFirstSeatBeforeTheCall;
begin
  FillFrom(1, QuickOrbs);
  FEclipse.Start;
  var Heard: TArray<Integer> := [];
  for var i := 1 to WholeScene do
    if Tick.FirstSeat then
      Heard := Heard + [i];
  Assert.AreEqual(1, Length(Heard), 'Once');
  Assert.AreEqual(CallAt, Heard[0], 'At the call, not before');
end;

procedure TEclipseTests.TestTheDarkFollowsTheRing;
const
  HalfARing = RingSeats div 2;
begin
  FillFrom(CallAt + 1, 1);
  FEclipse.Start;
  TickTimes(CallAt);
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
  // The whole ring at once, as the call comes
  FillFrom(CallAt, 1);
  FEclipse.Start;
  TickTimes(CallAt - 1);
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
  FillFrom(CallAt + FirstSeatAfterCall, QuickOrbs);
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
  FillFrom(CallAt + FirstSeatAfterCall, QuickOrbs);
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
  FillFrom(CallAt + FirstSeatAfterCall, QuickOrbs);
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
  FillFrom(CallAt + FirstSeatAfterCall, QuickOrbs);
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
  FillFrom(CallAt + FirstSeatAfterCall, QuickOrbs);
  FEclipse.Start;
  TickTimes(FullAt);
  // The rite tells no more of its ring: the dark goes on to its depth
  FFillFrom := MaxInt;
  TickTimes(DarkTicks);
  Assert.AreEqual(Double(DarkDepth), Double(FEclipse.Darkness(1)), Slop);
end;

procedure TEclipseTests.TestTheBeamFallsOntoHimAndStays;
begin
  FillFrom(CallAt + FirstSeatAfterCall, QuickOrbs);
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
  FillFrom(CallAt + FirstSeatAfterCall, QuickOrbs);
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
  FillFrom(CallAt + FirstSeatAfterCall, QuickOrbs);
  FEclipse.Start;
  var Heard: TArray<Integer> := [];
  for var i := 1 to WholeScene do
    if Tick.DrawIn then
      Heard := Heard + [i];
  Assert.AreEqual(1, Length(Heard), 'Once');
  Assert.AreEqual(FullAt + BeamFallTicks + RingInBeamTicks, Heard[0],
    'The ring''s time in the beam after it lands');
end;

procedure TEclipseTests.TestTheRipplesRunFromTheFirstSeatTillTheOrbsGoIn;
begin
  FillFrom(CallAt + FirstSeatAfterCall, QuickOrbs);
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
  FillFrom(CallAt + FirstSeatAfterCall, QuickOrbs);
  FEclipse.Start;
  TickTimes(WholeScene);
  FEclipse.Clear;
  Assert.IsFalse(FEclipse.Running, 'Stands');
  Assert.AreEqual(0.0, Double(FEclipse.Darkness(0)), Slop, 'No dark');
  Assert.AreEqual(0.0, Double(FEclipse.Fade(0)), Slop, 'The gauge back');
  Assert.AreEqual(0.0, Double(FEclipse.Ripple(0)), Slop, 'No ripples');
  Assert.AreEqual(0.0, Double(FEclipse.Beam(0)), Slop, 'No beam');
  Assert.AreEqual(0.0, Double(FEclipse.BeamFlash(0)), Slop, 'No flash');
end;

procedure TEclipseTests.TestTheStrikeTearsTheDarkOffInOneTick;
begin
  FillFrom(CallAt + FirstSeatAfterCall, QuickOrbs);
  FEclipse.Start;
  TickTimes(WholeScene);
  Assert.AreEqual(Double(DarkDepth), Double(FEclipse.Darkness(0)), Slop,
    'In before the strike');
  FEclipse.Strike;
  for var Step := 0 to 2 do
    Assert.AreEqual(0.0, Double(FEclipse.Darkness(Step / 2)), Slop,
      Format('Gone at once, %d halves of the tick on', [Step]));
  TickTimes(DarkTicks);
  Assert.AreEqual(0.0, Double(FEclipse.Darkness(0.5)), Slop, 'And stays gone');
end;

procedure TEclipseTests.TestAfterTheStrikeTheGaugeStaysOut;
begin
  FillFrom(CallAt + FirstSeatAfterCall, QuickOrbs);
  FEclipse.Start;
  // Halfway into the dark
  TickTimes(FFillFrom + DarkTicks div 2);
  FEclipse.Strike;
  for var i := 1 to WholeScene do
  begin
    Tick;
    Assert.AreEqual(1.0, Double(FEclipse.Fade(0)), Slop,
      Format('Out at %d', [i]));
    Assert.AreEqual(1.0, Double(FEclipse.Fade(1)), Slop,
      Format('Out between the ticks at %d', [i]));
  end;
end;

procedure TEclipseTests.TestTheStrikeTakesTheBeamAndTheRipples;
begin
  FillFrom(CallAt + FirstSeatAfterCall, QuickOrbs);
  FEclipse.Start;
  // The beam landed, its flash still on, the ripples running
  TickTimes(FullAt + BeamFallTicks);
  Assert.AreEqual(1.0, Double(FEclipse.Beam(0)), Slop, 'The beam on him');
  Assert.IsTrue(FEclipse.Ripple(0) > 0, 'The ripples run');
  FEclipse.Strike;
  Assert.AreEqual(0.0, Double(FEclipse.Beam(0)), Slop, 'No beam');
  Assert.AreEqual(0.0, Double(FEclipse.BeamFlash(0)), Slop, 'No flash');
  Assert.AreEqual(0.0, Double(FEclipse.Ripple(0)), Slop, 'No ripples');
  TickTimes(WholeScene);
  Assert.AreEqual(0.0, Double(FEclipse.Beam(1)), Slop, 'Never again');
end;

procedure TEclipseTests.TestNothingIsCuedAfterTheStrike;
begin
  FillFrom(CallAt + FirstSeatAfterCall, QuickOrbs);
  FEclipse.Start;
  TickTimes(FullAt);
  FEclipse.Strike;
  for var i := 1 to WholeScene do
  begin
    var Cue := Tick;
    Assert.IsFalse(Cue.Called or Cue.FirstSeat or Cue.Beam or Cue.DrawIn,
      Format('A cue at %d after the strike', [i]));
  end;
end;

procedure TEclipseTests.TestStruckItSparesHimTillTheClear;
begin
  FillFrom(CallAt + FirstSeatAfterCall, QuickOrbs);
  FEclipse.Start;
  TickTimes(WholeScene);
  Assert.IsFalse(FEclipse.Struck, 'Not before the strike');
  FEclipse.Strike;
  Assert.IsTrue(FEclipse.Struck, 'Struck');
  TickTimes(WholeScene);
  Assert.IsTrue(FEclipse.Running and FEclipse.Spares, 'Still sparing him');
  FEclipse.Clear;
  Assert.IsFalse(FEclipse.Struck, 'A clear forgets it');
  Assert.IsFalse(FEclipse.Spares, 'Nor spares any more');
end;

procedure TEclipseTests.TestNoStrikeOutsideTheScene;
begin
  FEclipse.Strike;
  Assert.IsFalse(FEclipse.Struck, 'Nothing to strike');
  Assert.AreEqual(0.0, Double(FEclipse.Fade(0)), Slop, 'The gauge as it was');
end;

procedure TEclipseTests.TestToldSoItSparesHimNoMoreTillANewStart;
begin
  FillFrom(CallAt + FirstSeatAfterCall, QuickOrbs);
  FEclipse.Start;
  TickTimes(WholeScene);
  FEclipse.Strike;
  FEclipse.StopSparing;
  TickTimes(WholeScene);
  Assert.IsTrue(FEclipse.Running, 'Running on');
  Assert.IsFalse(FEclipse.Spares, 'Spares him no more');
  FEclipse.Start;
  Assert.IsTrue(FEclipse.Spares, 'Sparing him again from a new start');
end;

initialization
  TDUnitX.RegisterTestFixture(TEclipseTests);

end.
