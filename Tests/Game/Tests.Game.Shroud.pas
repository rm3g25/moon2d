{
  Tests.Game.Shroud - the hero's shroud counted without a window: when it
  runs and when it stops, the clock of its halo and of every place along
  the body, the strips the body is put together of, the motes that drift
  off him and the mist that settles where a band slid off his feet.

  The hero's pose is built by hand with no texture, the matter is a
  function, the dice are seeded. What TShroudPainter draws has no test
  here: that is for the eye.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Game.Shroud;

interface

uses
  DUnitX.TestFramework, Game.Shroud;

type
  [TestFixture]
  THeroShroudTests = class
  private
    FShroud: THeroShroud;
    FTwin: THeroShroud;
  public
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestNewShroudIsStillAndDark;
    [Test]
    procedure TestStartSetsShroudGoingForItsLife;
    [Test]
    procedure TestAssemblingNeedsRevealAndRunning;
    [Test]
    procedure TestStartOnTheRunBeginsTheClockAgain;
    [Test]
    procedure TestTimeIsTheShareOfLifeGone;
    [Test]
    procedure TestClearStopsAndTakesMotesAndMist;
    [Test]
    procedure TestLeaveMotesTakesMotesAndMistAndKeepsRunning;
    [Test]
    procedure TestStartDoesNotEraseMotesOrMist;
    [Test]
    procedure TestGlowRisesToFlashAtItsPeakAndFalls;
    [Test]
    procedure TestGlowWithPeakAtStartOnlyFalls;
    [Test]
    procedure TestGlowIsNearlyOutAtTheEnd;
    [Test]
    procedure TestLookWithNoFlashHasNoGlow;
    [Test]
    procedure TestPartTimeTogetherIsOneTimeForTheWholeBody;
    [Test]
    procedure TestPartTimeTopDownLetsTheHeadLead;
    [Test]
    procedure TestPartTimeBottomUpLetsTheFeetLead;
    [Test]
    procedure TestPartTimeStartsAtZeroAndEndsAtOne;
    [Test]
    procedure TestStripShiftIsZeroOnceTheBodyIsHome;
    [Test]
    procedure TestNeighbouringStripsStartOnOppositeSides;
    [Test]
    procedure TestStripShiftIsZeroWhenTheLookShiftsNothing;
    [Test]
    procedure TestZeroSeedStillRollsTheStrips;
    [Test]
    procedure TestStartPlacesBandsInTheirSlotsOnAlternateSides;
    [Test]
    procedure TestMotesAreBornAtTheSeedsOnly;
    [Test]
    procedure TestMirroredPoseBornOnTheReflectedSide;
    [Test]
    procedure TestNoMotesWithoutSeedsOrFlashOrMotes;
    [Test]
    procedure TestMotesDieOutAfterTheShroudIsOver;
    [Test]
    procedure TestSinkingMotesStayOutOfMatter;
    [Test]
    procedure TestLooksThatDoNotSinkLeaveNoMist;
    [Test]
    procedure TestBandAtTheFeetStaysOnTheBodyWhenTravelIsNotDown;
    [Test]
    procedure TestIceOnLeavesOneCloudPerBandOverItsLife;
    [Test]
    procedure TestRestartedIceOnDropsItsMistAgain;
    [Test]
    procedure TestMistIsBornOnTheFeetLineAtTheHerosMiddle;
    [Test]
    procedure TestMistStandsWhereTheHeroFellNotWhereHeGoes;
    [Test]
    procedure TestMistSinksEvenlyWhereThereIsNoMatter;
    [Test]
    procedure TestMistSettlesOntoAFloorAndStops;
    [Test]
    procedure TestMistWithNoProbeStands;
    [Test]
    procedure TestMistDiesByTheAgeOfItsOwnLook;
    [Test]
    procedure TestSameSeedGivesTheSameRun;
    [Test]
    procedure TestOtherSeedGivesAnotherRun;
  end;

implementation

uses
  System.SysUtils, Sdl2.Core, Render.Silhouette, Effects.Emitter,
  Effects.Sparks, Hero;

const
  DefaultSeed = 7;
  OtherSeed = 1234567;
  // Seeds 1..SeedsTried, where a test must hold for any dice
  SeedsTried = 20;
  StandLeft = 100;
  StandTop = 50;
  // The row of the frame the feet stand on: where a band leaves the body
  FeetLine = HeroSize - 1;
  ShortLife = 10;
  BandCount = 5;
  PlaceSlack = 0.001; // units
  // Deep into the ice look's life: its mist has fallen, its motes fly
  IcedTicks = 80;
  // A mote is born within this of its point, and flies less in its first tick
  BirthReach = 1; // units
  // A sinking mote may not lie deeper in matter than this
  SinkSlack = 0.05; // units
  SinkTicks = 100;
  // No mote lives two seconds
  LongestMote = 66; // ticks
  // Settled mist lies within one step of the floor, and no step is longer
  LongestMistStep = 4; // units
  FloorBelowFeet = 4; // units
  WalkStep = 3; // units a tick
  EndGlowShare = 0.02;
  // The least number of strips that start at another distance than the first
  MinSpread = 4;
  WaitLimit = 200; // ticks

// ---------------------------------------------------------------------------
// Poses, seeds and matter
// ---------------------------------------------------------------------------

procedure ExpectNear(AExpected, AActual: Single; const AWhat: string);
begin
  Assert.IsTrue(Abs(AExpected - AActual) < PlaceSlack,
    Format('%s: %g, not %g', [AWhat, AActual, AExpected]));
end;

function PointAt(AX, AY: Single): TSdlFPoint;
begin
  Result.X := AX;
  Result.Y := AY;
end;

function PoseAt(ALeft, ATop: Integer): THeroPose;
begin
  Result := Default(THeroPose);
  Result.Frame := 1;
  Result.Left := ALeft;
  Result.Top := ATop;
end;

function MirroredPoseAt(ALeft, ATop: Integer): THeroPose;
begin
  Result := PoseAt(ALeft, ATop);
  Result.Mirrored := True;
end;

function Standing: THeroPose;
begin
  Result := PoseAt(StandLeft, StandTop);
end;

function TwoSeeds: TSeedList;
begin
  Result := [PointAt(4, 6), PointAt(28, 26)];
end;

// Two points on the row of the feet, for motes that sink onto a floor
function FootSeeds: TSeedList;
begin
  Result := [PointAt(4, FeetLine), PointAt(28, FeetLine)];
end;

function NoSeeds: TSeedList;
begin
  Result := nil;
end;

function EverywhereOpen(AX, AY: Single): Boolean;
begin
  Result := False;
end;

function EverywhereMatter(AX, AY: Single): Boolean;
begin
  Result := True;
end;

// Solid from the line AFloorY down
function MatterFrom(AFloorY: Single): TSolidProbe;
begin
  Result :=
    function(AX, ASampleY: Single): Boolean
    begin
      Result := ASampleY >= AFloorY;
    end;
end;

// ---------------------------------------------------------------------------
// Looks of the tests' own: all numbers zero but the ones a test is about
// ---------------------------------------------------------------------------

function BareLook(ALife: Integer): TShroudLook;
begin
  Result := Default(TShroudLook);
  Result.Life := ALife;
end;

// A halo that flashes from the first tick and sheds four motes a tick
function MoteLook: TShroudLook;
begin
  Result := BareLook(20);
  Result.Flash := 1;
  Result.Motes := 4;
end;

// Motes that fall, as the frost does
function SinkLook: TShroudLook;
begin
  Result := MoteLook;
  Result.Life := 40;
  Result.Motes := 3;
  Result.Lift := 0.12;
end;

function ShiftLook(AShift: Single): TShroudLook;
begin
  Result := BareLook(ShortLife);
  Result.Reveal := True;
  Result.Shift := AShift;
end;

function StaggeredLook(AOrder: TShroudOrder; AStagger: Single): TShroudLook;
begin
  Result := BareLook(ShortLife);
  Result.Order := AOrder;
  Result.Stagger := AStagger;
end;

// Forty narrow bands over a look that lasts a second, sinking ATravel units
function BandedLook(ATravel: Single): TShroudLook;
begin
  Result := BareLook(20);
  Result.Bands := 40;
  Result.WidthFrom := 20;
  Result.WidthTo := 20;
  Result.Travel := ATravel;
end;

function AllLooks: TArray<TShroudLook>;
begin
  Result := [PitLook, EntryLook, ReviveLook, IceOnLook, HeatOnLook, IceOffLook];
end;

// The looks that put the body together out of strips
function AssemblingLooks: TArray<TShroudLook>;
begin
  Result := [PitLook, EntryLook, ReviveLook];
end;

// The looks that leave the body whole
function SuitLooks: TArray<TShroudLook>;
begin
  Result := [IceOnLook, IceOffLook, HeatOnLook];
end;

// The looks whose bands do not sink down the body
function NonSinkingLooks: TArray<TShroudLook>;
begin
  Result := [PitLook, EntryLook, ReviveLook, IceOffLook, HeatOnLook];
end;

// ---------------------------------------------------------------------------
// Reading a shroud. Mist and Bands hand out the array the shroud works in,
// and a mote is a pointer into its swarm: what a test wants to compare
// across a tick is copied before it.
// ---------------------------------------------------------------------------

function MistOf(const AShroud: THeroShroud): TArray<TShroudCloud>;
begin
  Result := Copy(AShroud.Mist, 0, Length(AShroud.Mist));
end;

function MotesOf(const AShroud: THeroShroud): TArray<TParticle>;
begin
  var Swarm := AShroud.Motes;
  SetLength(Result, Swarm.Count);
  for var i := 0 to High(Result) do
    Result[i] := Swarm[i]^;
end;

procedure TickTimes(AShroud: THeroShroud; ACount: Integer);
begin
  for var i := 1 to ACount do
    AShroud.Tick(Standing, TwoSeeds);
end;

// Ticks the shroud until a band has fallen; how many ticks it took
function TicksUntilMist(AShroud: THeroShroud; const APose: THeroPose): Integer;
begin
  Result := 0;
  while Length(AShroud.Mist) = 0 do
  begin
    if Result = WaitLimit then
      Assert.Fail(Format('No mist after %d ticks', [Result]));
    AShroud.Tick(APose, TwoSeeds);
    Inc(Result);
  end;
end;

// The mist counted tick by tick over a whole run of the look, on many seeds
function MistSeenOver(const ALook: TShroudLook): Integer;
begin
  Result := 0;
  for var Seed := 1 to SeedsTried do
  begin
    var Shroud := THeroShroud.Create(EverywhereMatter, Seed);
    try
      Shroud.Start(ALook);
      for var i := 1 to ALook.Life + 2 do
      begin
        Shroud.Tick(Standing, TwoSeeds);
        Result := Result + Length(Shroud.Mist);
      end;
    finally
      Shroud.Free;
    end;
  end;
end;

// The motes counted tick by tick over a whole run of the look
function MotesShedBy(const ALook: TShroudLook; const ASeeds: TSeedList): Integer;
begin
  Result := 0;
  var Shroud := THeroShroud.Create(nil, DefaultSeed);
  try
    Shroud.Start(ALook);
    for var i := 1 to ALook.Life + 2 do
    begin
      Shroud.Tick(Standing, ASeeds);
      Result := Result + Shroud.Motes.Count;
    end;
  finally
    Shroud.Free;
  end;
end;

// The index of the seed, placed at the standing pose, that the mote is
// within reach of; -1 for a mote that is near none
function NearestSeed(const AMote: TParticle; const ASeeds: TSeedList): Integer;
begin
  Result := -1;
  for var i := 0 to High(ASeeds) do
  begin
    var OffX: Single := Abs(AMote.X - (StandLeft + ASeeds[i].X));
    var OffY: Single := Abs(AMote.Y - (StandTop + ASeeds[i].Y));
    if (OffX <= BirthReach) and (OffY <= BirthReach) then
      Exit(i);
  end;
end;

procedure ExpectMotesNear(const AShroud: THeroShroud; AX, AY: Single;
  const AWhat: string);
begin
  var Motes := MotesOf(AShroud);
  Assert.IsTrue(Length(Motes) > 0, AWhat + ': no mote was born');
  for var Mote in Motes do
  begin
    var OffX: Single := Abs(Mote.X - AX);
    var OffY: Single := Abs(Mote.Y - AY);
    Assert.IsTrue((OffX <= BirthReach) and (OffY <= BirthReach),
      Format('%s: a mote is at (%g, %g), not near (%g, %g)',
        [AWhat, Mote.X, Mote.Y, AX, AY]));
  end;
end;

// Motes that lie in matter deeper than the slack, by the probe
function MotesInMatter(const AShroud: THeroShroud;
  const AProbe: TSolidProbe): Integer;
begin
  Result := 0;
  for var Mote in MotesOf(AShroud) do
    if AProbe(Mote.X, Mote.Y - SinkSlack) then
      Inc(Result);
end;

// Motes within a unit above the floor line, or below it
function MotesNearFloor(const AShroud: THeroShroud; AFloorY: Single): Integer;
begin
  Result := 0;
  for var Mote in MotesOf(AShroud) do
    if Mote.Y >= AFloorY - 1 then
      Inc(Result);
end;

function MistHasBand(const AMist: TArray<TShroudCloud>;
  const ABand: TShroudBand): Boolean;
begin
  Result := False;
  for var Cloud in AMist do
    if (Abs(Cloud.Band.At - ABand.At) < PlaceSlack) and
      (Cloud.Band.Side = ABand.Side) then
      Exit(True);
end;

procedure ExpectEveryBandFell(const AShroud: THeroShroud);
begin
  Assert.IsTrue(Length(AShroud.Bands) > 0, 'The look has bands to fall');
  var Mist := MistOf(AShroud);
  for var Band in AShroud.Bands do
  begin
    Assert.IsTrue(Band.Fallen, 'Every band has gone off the body');
    Assert.IsTrue(MistHasBand(Mist, Band),
      'and lives on as a cloud of the same place and side');
  end;
end;

// How far each cloud of the tick before went down in the tick after
function FallSteps(const ABefore, AAfter: TArray<TShroudCloud>): TArray<Single>;
begin
  Assert.IsTrue(Length(AAfter) >= Length(ABefore),
    'No cloud dies before its look is out');
  SetLength(Result, Length(ABefore));
  for var i := 0 to High(ABefore) do
    Result[i] := AAfter[i].Y - ABefore[i].Y;
end;

// Over every place along the body the own time of a part starts at nothing,
// ends at one and never turns back
procedure ExpectPartRunsFromZeroToOne(const AShroud: THeroShroud;
  APlace: Single; const AWhat: string);
begin
  ExpectNear(0, AShroud.PartTime(0, APlace), AWhat + ' at the start');
  ExpectNear(1, AShroud.PartTime(1, APlace), AWhat + ' at the end');
  var Before: Single := 0;
  for var Moment := 1 to 20 do
  begin
    var Part := AShroud.PartTime(Moment / 20, APlace);
    Assert.IsTrue(Part >= Before,
      Format('%s turns back at %d of 20', [AWhat, Moment]));
    Before := Part;
  end;
end;

// Whether two shrouds are in the same state: bands, motes and mist
function SameBands(const ALeft, ARight: THeroShroud): Boolean;
begin
  if Length(ALeft.Bands) <> Length(ARight.Bands) then
    Exit(False);
  Result := True;
  for var i := 0 to High(ALeft.Bands) do
    if ALeft.Bands[i].At <> ARight.Bands[i].At then
      Result := False;
end;

function SameMotes(const ALeft, ARight: THeroShroud): Boolean;
begin
  var LeftMotes := MotesOf(ALeft);
  var RightMotes := MotesOf(ARight);
  if Length(LeftMotes) <> Length(RightMotes) then
    Exit(False);
  Result := True;
  for var i := 0 to High(LeftMotes) do
    if (LeftMotes[i].X <> RightMotes[i].X) or
      (LeftMotes[i].Y <> RightMotes[i].Y) then
      Result := False;
end;

function SameMist(const ALeft, ARight: THeroShroud): Boolean;
begin
  var LeftMist := MistOf(ALeft);
  var RightMist := MistOf(ARight);
  if Length(LeftMist) <> Length(RightMist) then
    Exit(False);
  Result := True;
  for var i := 0 to High(LeftMist) do
    if (LeftMist[i].X <> RightMist[i].X) or
      (LeftMist[i].Y <> RightMist[i].Y) or
      (LeftMist[i].Age <> RightMist[i].Age) then
      Result := False;
end;

function SameState(const ALeft, ARight: THeroShroud): Boolean;
begin
  Result := SameBands(ALeft, ARight) and SameMotes(ALeft, ARight) and
    SameMist(ALeft, ARight);
end;

// ---------------------------------------------------------------------------
// The clock
// ---------------------------------------------------------------------------

procedure THeroShroudTests.TearDown;
begin
  FreeAndNil(FTwin);
  FreeAndNil(FShroud);
end;

procedure THeroShroudTests.TestNewShroudIsStillAndDark;
begin
  FShroud := THeroShroud.Create(nil, DefaultSeed);

  Assert.IsFalse(FShroud.Active, 'A new shroud is not running');
  Assert.IsFalse(FShroud.Assembling, 'and puts no body together');
  ExpectNear(0, FShroud.Glow(FShroud.Time(0)), 'The glow of a new shroud');

  TickTimes(FShroud, 10);

  Assert.IsFalse(FShroud.Active, 'Ticks alone do not start a shroud');
  Assert.AreEqual(0, FShroud.Motes.Count, 'and shed no motes');
  Assert.AreEqual(0, Length(FShroud.Mist), 'and leave no mist');
  Assert.AreEqual(0, Length(FShroud.Bands), 'and have no bands');
end;

procedure THeroShroudTests.TestStartSetsShroudGoingForItsLife;
begin
  FShroud := THeroShroud.Create(nil, DefaultSeed);

  FShroud.Start(BareLook(ShortLife));
  Assert.IsTrue(FShroud.Active, 'A started shroud is running');

  TickTimes(FShroud, ShortLife - 1);
  Assert.IsTrue(FShroud.Active, 'and still is a tick before its life is out');

  TickTimes(FShroud, 1);
  Assert.IsFalse(FShroud.Active, 'and is over when its life is spent');
end;

procedure THeroShroudTests.TestAssemblingNeedsRevealAndRunning;
begin
  FShroud := THeroShroud.Create(nil, DefaultSeed);
  Assert.IsFalse(FShroud.Assembling, 'Nothing is put together before a start');

  var Revealing := BareLook(ShortLife);
  Revealing.Reveal := True;
  FShroud.Start(Revealing);
  Assert.IsTrue(FShroud.Assembling, 'A look with a reveal puts the body together');

  TickTimes(FShroud, ShortLife);
  Assert.IsFalse(FShroud.Assembling, 'and the body is whole when it is over');

  FShroud.Start(BareLook(ShortLife));
  Assert.IsTrue(FShroud.Active, 'A look with no reveal is running');
  Assert.IsFalse(FShroud.Assembling, 'and leaves the body whole');

  for var Look in AssemblingLooks do
  begin
    FShroud.Start(Look);
    Assert.IsTrue(FShroud.Assembling, 'The looks of an appearance assemble');
  end;
  for var Look in SuitLooks do
  begin
    FShroud.Start(Look);
    Assert.IsFalse(FShroud.Assembling, 'The looks of a suit do not');
  end;
end;

procedure THeroShroudTests.TestStartOnTheRunBeginsTheClockAgain;
begin
  FShroud := THeroShroud.Create(nil, DefaultSeed);
  FShroud.Start(BareLook(ShortLife));
  TickTimes(FShroud, 6);

  FShroud.Start(BareLook(ShortLife + 2));

  ExpectNear(0, FShroud.Time(0), 'A restarted shroud is at its start');
  Assert.AreEqual(ShortLife + 2, FShroud.Look.Life, 'and has the new look');
  TickTimes(FShroud, ShortLife + 1);
  Assert.IsTrue(FShroud.Active, 'It is not over before its new life is');
  TickTimes(FShroud, 1);
  Assert.IsFalse(FShroud.Active, 'but is when it is');
end;

procedure THeroShroudTests.TestTimeIsTheShareOfLifeGone;
begin
  FShroud := THeroShroud.Create(nil, DefaultSeed);
  FShroud.Start(BareLook(ShortLife));
  ExpectNear(0, FShroud.Time(0), 'A new shroud is at the start of its life');

  TickTimes(FShroud, 4);

  ExpectNear(0.4, FShroud.Time(0), 'Four ticks of ten');
  var Between := FShroud.Time(0.5);
  Assert.IsTrue((Between > FShroud.Time(0)) and (Between < FShroud.Time(1)),
    'The step between two ticks lies between the ticks');

  TickTimes(FShroud, ShortLife);
  ExpectNear(1, FShroud.Time(0), 'A shroud that is over is at the end of its life');
end;

procedure THeroShroudTests.TestClearStopsAndTakesMotesAndMist;
begin
  FShroud := THeroShroud.Create(EverywhereMatter, DefaultSeed);
  FShroud.Start(IceOnLook);
  TickTimes(FShroud, IcedTicks);
  Assert.IsTrue(FShroud.Motes.Count > 0, 'There are motes to clear');
  Assert.IsTrue(Length(FShroud.Mist) > 0, 'and mist');

  FShroud.Clear;

  Assert.IsFalse(FShroud.Active, 'A cleared shroud is not running');
  Assert.AreEqual(0, FShroud.Motes.Count, 'and has no motes');
  Assert.AreEqual(0, Length(FShroud.Mist), 'and no mist');
  TickTimes(FShroud, 5);
  Assert.IsFalse(FShroud.Active, 'Ticks do not bring it back');
  Assert.AreEqual(0, FShroud.Motes.Count, 'nor shed motes over a body that is gone');
end;

procedure THeroShroudTests.TestLeaveMotesTakesMotesAndMistAndKeepsRunning;
begin
  FShroud := THeroShroud.Create(EverywhereMatter, DefaultSeed);
  FShroud.Start(IceOnLook);
  TickTimes(FShroud, IcedTicks);
  Assert.IsTrue(FShroud.Motes.Count > 0, 'There are motes to leave behind');
  Assert.IsTrue(Length(FShroud.Mist) > 0, 'and mist');
  var TimeBefore := FShroud.Time(0);

  FShroud.LeaveMotes;

  Assert.AreEqual(0, FShroud.Motes.Count, 'The motes stay behind the door');
  Assert.AreEqual(0, Length(FShroud.Mist), 'and so does the mist');
  Assert.IsTrue(FShroud.Active, 'The light goes on with the hero');
  ExpectNear(TimeBefore, FShroud.Time(0), 'and its clock is not touched');
  TickTimes(FShroud, 1);
  Assert.IsTrue(FShroud.Active, 'It goes on running after the door');
end;

procedure THeroShroudTests.TestStartDoesNotEraseMotesOrMist;
begin
  FShroud := THeroShroud.Create(EverywhereMatter, DefaultSeed);
  FShroud.Start(IceOnLook);
  TickTimes(FShroud, IcedTicks);
  var MistBefore := MistOf(FShroud);
  var MotesBefore := FShroud.Motes.Count;
  Assert.IsTrue(Length(MistBefore) > 0, 'There is mist for a new shroud to leave be');
  Assert.IsTrue(MotesBefore > 0, 'and there are motes');

  FShroud.Start(IceOffLook);

  Assert.AreEqual(Length(MistBefore), Length(FShroud.Mist),
    'A new shroud leaves the mist of the old one');
  Assert.AreEqual(MotesBefore, FShroud.Motes.Count,
    'and its motes');
  TickTimes(FShroud, 1);
  var MistAfter := MistOf(FShroud);
  Assert.AreEqual(Length(MistBefore), Length(MistAfter),
    'and the mist is still there a tick on');
  for var i := 0 to High(MistBefore) do
  begin
    ExpectNear(MistBefore[i].X, MistAfter[i].X, 'The mist stands where it stood');
    ExpectNear(MistBefore[i].Y, MistAfter[i].Y, 'on the same row');
  end;
  Assert.IsTrue(FShroud.Motes.Count > 0, 'and the motes fly on');
end;

// ---------------------------------------------------------------------------
// The halo
// ---------------------------------------------------------------------------

procedure THeroShroudTests.TestGlowRisesToFlashAtItsPeakAndFalls;
begin
  var Look := BareLook(ShortLife);
  Look.Flash := 1;
  Look.FlashAt := 0.5;
  FShroud := THeroShroud.Create(nil, DefaultSeed);
  FShroud.Start(Look);

  ExpectNear(0, FShroud.Glow(0), 'No halo at the start');
  var Level := FShroud.Glow(0);
  for var i := 1 to 10 do
  begin
    var Next := FShroud.Glow(i / 20);
    Assert.IsTrue(Next > Level,
      Format('The halo is still growing at %d of 20', [i]));
    Level := Next;
  end;
  ExpectNear(Look.Flash, Level, 'The halo peaks at the flash, half way through');
  for var i := 11 to 20 do
  begin
    var Next := FShroud.Glow(i / 20);
    Assert.IsTrue(Next < Level,
      Format('The halo is already falling at %d of 20', [i]));
    Level := Next;
  end;
end;

procedure THeroShroudTests.TestGlowWithPeakAtStartOnlyFalls;
begin
  var Look := BareLook(ShortLife);
  Look.Flash := 1.3;
  FShroud := THeroShroud.Create(nil, DefaultSeed);
  FShroud.Start(Look);

  var Level := FShroud.Glow(0);
  ExpectNear(Look.Flash, Level, 'The halo starts at the flash');
  for var i := 1 to 20 do
  begin
    var Next := FShroud.Glow(i / 20);
    Assert.IsTrue(Next < Level,
      Format('The halo is still falling at %d of 20', [i]));
    Level := Next;
  end;
end;

procedure THeroShroudTests.TestGlowIsNearlyOutAtTheEnd;
begin
  FShroud := THeroShroud.Create(nil, DefaultSeed);
  for var Look in AllLooks do
  begin
    FShroud.Start(Look);
    Assert.IsTrue(FShroud.Glow(1) < EndGlowShare * Look.Flash,
      Format('A look of flash %g still glows at the end: %g',
        [Look.Flash, FShroud.Glow(1)]));
  end;
end;

procedure THeroShroudTests.TestLookWithNoFlashHasNoGlow;
begin
  var Look := BareLook(ShortLife);
  Look.FlashAt := 0.5;
  FShroud := THeroShroud.Create(nil, DefaultSeed);
  FShroud.Start(Look);

  ExpectNear(0, FShroud.Glow(0), 'No halo at the start');
  ExpectNear(0, FShroud.Glow(0.5), 'none at the peak');
  ExpectNear(0, FShroud.Glow(1), 'none at the end');
end;

// ---------------------------------------------------------------------------
// The own time of a place along the body
// ---------------------------------------------------------------------------

procedure THeroShroudTests.TestPartTimeTogetherIsOneTimeForTheWholeBody;
begin
  FShroud := THeroShroud.Create(nil, DefaultSeed);
  FShroud.Start(StaggeredLook(soTogether, 0.2));

  for var i := 0 to 20 do
  begin
    var Moment: Single := i / 20;
    var Head := FShroud.PartTime(Moment, 0);
    ExpectNear(Head, FShroud.PartTime(Moment, 0.5),
      Format('The middle and the head at %d of 20', [i]));
    ExpectNear(Head, FShroud.PartTime(Moment, 1),
      Format('The feet and the head at %d of 20', [i]));
  end;
  var Midway := FShroud.PartTime(0.4, 0);
  Assert.IsTrue((Midway > 0) and (Midway < 1), 'and the time does pass');
end;

procedure THeroShroudTests.TestPartTimeTopDownLetsTheHeadLead;
begin
  FShroud := THeroShroud.Create(nil, DefaultSeed);
  FShroud.Start(StaggeredLook(soTopDown, 0.5));

  var HeadAhead := 0;
  for var i := 0 to 20 do
  begin
    var Moment: Single := i / 20;
    var Head := FShroud.PartTime(Moment, 0);
    var Feet := FShroud.PartTime(Moment, 1);
    Assert.IsTrue(Head >= Feet,
      Format('The feet are ahead of the head at %d of 20', [i]));
    if Head > Feet then
      Inc(HeadAhead);
  end;
  Assert.IsTrue(HeadAhead > 0, 'and the head is ahead of the feet at some moment');
end;

procedure THeroShroudTests.TestPartTimeBottomUpLetsTheFeetLead;
begin
  FShroud := THeroShroud.Create(nil, DefaultSeed);
  FShroud.Start(StaggeredLook(soBottomUp, 0.5));

  var FeetAhead := 0;
  for var i := 0 to 20 do
  begin
    var Moment: Single := i / 20;
    var Head := FShroud.PartTime(Moment, 0);
    var Feet := FShroud.PartTime(Moment, 1);
    Assert.IsTrue(Feet >= Head,
      Format('The head is ahead of the feet at %d of 20', [i]));
    if Feet > Head then
      Inc(FeetAhead);
  end;
  Assert.IsTrue(FeetAhead > 0, 'and the feet are ahead of the head at some moment');
end;

procedure THeroShroudTests.TestPartTimeStartsAtZeroAndEndsAtOne;
begin
  FShroud := THeroShroud.Create(nil, DefaultSeed);
  for var Order := Low(TShroudOrder) to High(TShroudOrder) do
  begin
    FShroud.Start(StaggeredLook(Order, 0.7));
    for var Slice := 0 to 4 do
    begin
      var Place: Single := Slice / 4;
      ExpectPartRunsFromZeroToOne(FShroud, Place,
        Format('Order %d, place %g', [Ord(Order), Place]));
    end;
  end;
end;

// ---------------------------------------------------------------------------
// The strips
// ---------------------------------------------------------------------------

procedure THeroShroudTests.TestStripShiftIsZeroOnceTheBodyIsHome;
begin
  var Look := ShiftLook(20);
  Look.Order := soTopDown;
  Look.Stagger := 0.5;
  FShroud := THeroShroud.Create(nil, DefaultSeed);
  FShroud.Start(Look);

  for var Strip := 0 to ShroudStrips - 1 do
    ExpectNear(0, FShroud.StripShift(Strip, 1),
      Format('Strip %d at the end', [Strip]));
end;

procedure THeroShroudTests.TestNeighbouringStripsStartOnOppositeSides;
begin
  FShroud := THeroShroud.Create(nil, DefaultSeed);
  FShroud.Start(ShiftLook(20));

  for var Strip := 0 to ShroudStrips - 2 do
  begin
    var Here := FShroud.StripShift(Strip, 0);
    var Next := FShroud.StripShift(Strip + 1, 0);
    Assert.IsTrue(Here * Next < 0,
      Format('Strips %d and %d start at %g and %g, not on opposite sides',
        [Strip, Strip + 1, Here, Next]));
  end;
end;

procedure THeroShroudTests.TestStripShiftIsZeroWhenTheLookShiftsNothing;
begin
  FShroud := THeroShroud.Create(nil, DefaultSeed);
  FShroud.Start(ShiftLook(0));

  var Total: Single := 0;
  for var Moment := 0 to 10 do
    for var Strip := 0 to ShroudStrips - 1 do
      Total := Total + Abs(FShroud.StripShift(Strip, Moment / 10));
  ExpectNear(0, Total, 'The strips of a look with no shift, all together');
end;

procedure THeroShroudTests.TestZeroSeedStillRollsTheStrips;
begin
  FShroud := THeroShroud.Create(nil, 0);
  FShroud.Start(ShiftLook(20));

  var First := Abs(FShroud.StripShift(0, 0));
  var Differing := 0;
  for var Strip := 1 to ShroudStrips - 1 do
    if Abs(FShroud.StripShift(Strip, 0)) <> First then
      Inc(Differing);
  Assert.IsTrue(Differing >= MinSpread,
    'A zero seed must not freeze the dice: the strips start at different distances');
end;

// ---------------------------------------------------------------------------
// The bands
// ---------------------------------------------------------------------------

procedure THeroShroudTests.TestStartPlacesBandsInTheirSlotsOnAlternateSides;
begin
  var Look := BareLook(ShortLife);
  Look.Bands := BandCount;
  FShroud := THeroShroud.Create(nil, DefaultSeed);

  FShroud.Start(Look);

  Assert.AreEqual(BandCount, Length(FShroud.Bands), 'A band for each of the look');
  for var i := 0 to BandCount - 1 do
  begin
    var Band := FShroud.Bands[i];
    var SlotStart: Single := i / BandCount;
    var SlotEnd: Single := (i + 1) / BandCount;
    Assert.IsTrue((Band.At >= SlotStart - PlaceSlack) and
      (Band.At <= SlotEnd + PlaceSlack),
      Format('Band %d is at %g, outside its place along the body', [i, Band.At]));
    Assert.IsFalse(Band.Fallen, 'No band is off the body at the start');
  end;
  for var i := 0 to BandCount - 2 do
  begin
    Assert.IsTrue(FShroud.Bands[i].Side <> FShroud.Bands[i + 1].Side,
      Format('Bands %d and %d come from the same side', [i, i + 1]));
    Assert.IsTrue(FShroud.Bands[i].InFront <> FShroud.Bands[i + 1].InFront,
      Format('Bands %d and %d lie in the same layer', [i, i + 1]));
  end;

  FShroud.Start(BareLook(ShortLife));
  Assert.AreEqual(0, Length(FShroud.Bands), 'A look with no bands has none');
end;

// ---------------------------------------------------------------------------
// The motes
// ---------------------------------------------------------------------------

procedure THeroShroudTests.TestMotesAreBornAtTheSeedsOnly;
begin
  var Seeds := TwoSeeds;
  var Tally: TArray<Integer>;
  SetLength(Tally, Length(Seeds) + 1);
  for var Seed := 1 to 2 * SeedsTried do
  begin
    FreeAndNil(FShroud);
    FShroud := THeroShroud.Create(nil, Seed);
    FShroud.Start(MoteLook);
    FShroud.Tick(Standing, Seeds);
    for var Mote in MotesOf(FShroud) do
      Inc(Tally[NearestSeed(Mote, Seeds) + 1]);
  end;

  Assert.AreEqual(0, Tally[0], 'Every mote is born at a point of the list');
  Assert.IsTrue(Tally[1] > 0, 'and the first point gets motes');
  Assert.IsTrue(Tally[2] > 0, 'and so does the second');
end;

procedure THeroShroudTests.TestMirroredPoseBornOnTheReflectedSide;
begin
  var Seeds: TSeedList := [PointAt(4, 6)];
  FShroud := THeroShroud.Create(nil, DefaultSeed);
  FTwin := THeroShroud.Create(nil, DefaultSeed);
  FShroud.Start(MoteLook);
  FTwin.Start(MoteLook);

  FShroud.Tick(PoseAt(StandLeft, StandTop), Seeds);
  FTwin.Tick(MirroredPoseAt(StandLeft, StandTop), Seeds);

  ExpectMotesNear(FShroud, StandLeft + 4, StandTop + 6, 'Facing one way');
  ExpectMotesNear(FTwin, StandLeft + HeroSize - 4, StandTop + 6, 'Facing the other');
end;

procedure THeroShroudTests.TestNoMotesWithoutSeedsOrFlashOrMotes;
begin
  Assert.IsTrue(MotesShedBy(MoteLook, TwoSeeds) > 0,
    'The look sheds motes when it has all it needs');

  Assert.AreEqual(0, MotesShedBy(MoteLook, NoSeeds), 'No points, no motes');
  var Still := MoteLook;
  Still.Motes := 0;
  Assert.AreEqual(0, MotesShedBy(Still, TwoSeeds), 'No motes asked, none born');
  var Dark := MoteLook;
  Dark.Flash := 0;
  Assert.AreEqual(0, MotesShedBy(Dark, TwoSeeds), 'No flash, no motes');
end;

procedure THeroShroudTests.TestMotesDieOutAfterTheShroudIsOver;
begin
  var Look := MoteLook;
  FShroud := THeroShroud.Create(nil, DefaultSeed);
  FShroud.Start(Look);
  TickTimes(FShroud, Look.Life);
  Assert.IsFalse(FShroud.Active, 'The shroud is over');
  Assert.IsTrue(FShroud.Motes.Count > 0, 'with motes still in the air');

  var Waited := 0;
  while FShroud.Motes.Count > 0 do
  begin
    if Waited = LongestMote then
      Assert.Fail(Format('Motes still fly %d ticks after the shroud', [Waited]));
    var Before := FShroud.Motes.Count;
    TickTimes(FShroud, 1);
    Assert.IsFalse(FShroud.Motes.Count > Before,
      'A shroud that is over sheds no new motes');
    Inc(Waited);
  end;
end;

procedure THeroShroudTests.TestSinkingMotesStayOutOfMatter;
begin
  var FloorY: Single := StandTop + FeetLine + 2;
  var FloorProbe := MatterFrom(FloorY);
  var Inside := 0;
  var Reached := 0;
  for var Seed := 1 to SeedsTried do
  begin
    FreeAndNil(FShroud);
    FShroud := THeroShroud.Create(FloorProbe, Seed);
    FShroud.Start(SinkLook);
    for var i := 1 to SinkTicks do
    begin
      FShroud.Tick(Standing, FootSeeds);
      Inside := Inside + MotesInMatter(FShroud, FloorProbe);
      Reached := Reached + MotesNearFloor(FShroud, FloorY);
    end;
  end;

  Assert.AreEqual(0, Inside, 'A sinking mote lies in matter');
  Assert.IsTrue(Reached > 0, 'The motes do come down to the floor');
end;

// ---------------------------------------------------------------------------
// The mist
// ---------------------------------------------------------------------------

procedure THeroShroudTests.TestLooksThatDoNotSinkLeaveNoMist;
begin
  for var Look in NonSinkingLooks do
    Assert.AreEqual(0, MistSeenOver(Look),
      Format('A look of life %d leaves mist', [Look.Life]));
end;

procedure THeroShroudTests.TestBandAtTheFeetStaysOnTheBodyWhenTravelIsNotDown;
begin
  Assert.AreEqual(0, MistSeenOver(BandedLook(0)), 'Bands that do not travel leave mist');
  Assert.AreEqual(0, MistSeenOver(BandedLook(-5)), 'Bands that rise leave mist');
  Assert.IsTrue(MistSeenOver(BandedLook(30)) > 0,
    'The same bands, sinking, do leave mist');
end;

procedure THeroShroudTests.TestIceOnLeavesOneCloudPerBandOverItsLife;
begin
  for var Seed := 1 to SeedsTried do
  begin
    FreeAndNil(FShroud);
    FShroud := THeroShroud.Create(EverywhereMatter, Seed);
    FShroud.Start(IceOnLook);

    TickTimes(FShroud, IceOnLook.Life - 1);

    Assert.AreEqual(IceOnLook.Bands, Length(FShroud.Mist),
      Format('Clouds on seed %d, a tick before the end', [Seed]));
    ExpectEveryBandFell(FShroud);
    TickTimes(FShroud, 1);
    Assert.IsFalse(FShroud.Active, 'The shroud is over at the end of its life');
    Assert.AreEqual(0, Length(FShroud.Mist), 'and its mist with it');
  end;
end;

procedure THeroShroudTests.TestRestartedIceOnDropsItsMistAgain;
begin
  FShroud := THeroShroud.Create(EverywhereMatter, DefaultSeed);
  FShroud.Start(IceOnLook);
  TickTimes(FShroud, IceOnLook.Life * 3 div 4);
  Assert.AreEqual(IceOnLook.Bands, Length(FShroud.Mist),
    'The first run has dropped all its mist');

  FShroud.Start(IceOnLook);
  TickTimes(FShroud, IceOnLook.Life - 1);

  Assert.AreEqual(IceOnLook.Bands, Length(FShroud.Mist),
    'The second run drops its own, and the first is gone by then');
  ExpectEveryBandFell(FShroud);
end;

procedure THeroShroudTests.TestMistIsBornOnTheFeetLineAtTheHerosMiddle;
begin
  FShroud := THeroShroud.Create(EverywhereMatter, DefaultSeed);
  FShroud.Start(IceOnLook);
  var Pose := PoseAt(200, 80);

  TicksUntilMist(FShroud, Pose);

  var Cloud := FShroud.Mist[0];
  ExpectNear(200 + HeroSize div 2, Cloud.X, 'The cloud stands at the middle of the frame');
  ExpectNear(80 + FeetLine, Cloud.Y, 'on the row of the feet');
  Assert.AreEqual(IceOnLook.Life, Cloud.Look.Life, 'and carries the look it fell from');
end;

procedure THeroShroudTests.TestMistStandsWhereTheHeroFellNotWhereHeGoes;
begin
  FShroud := THeroShroud.Create(EverywhereMatter, DefaultSeed);
  FShroud.Start(IceOnLook);

  var Expected: TArray<Single> := [];
  for var Step := 1 to IceOnLook.Life - 1 do
  begin
    var Pose := PoseAt(StandLeft + WalkStep * Step, StandTop);
    FShroud.Tick(Pose, TwoSeeds);
    var Known := Length(Expected);
    SetLength(Expected, Length(FShroud.Mist));
    for var i := Known to High(Expected) do
      Expected[i] := Pose.Left + HeroSize div 2;
  end;

  Assert.AreEqual(IceOnLook.Bands, Length(Expected), 'Every band fell');
  var Mist := MistOf(FShroud);
  for var i := 0 to High(Mist) do
  begin
    ExpectNear(Expected[i], Mist[i].X, 'A cloud stays where the hero was when it fell');
    ExpectNear(StandTop + FeetLine, Mist[i].Y, 'and on the floor it lies on');
  end;
end;

procedure THeroShroudTests.TestMistSinksEvenlyWhereThereIsNoMatter;
begin
  FShroud := THeroShroud.Create(EverywhereOpen, DefaultSeed);
  FShroud.Start(IceOnLook);

  var Steps: TArray<Single> := [];
  var Before := MistOf(FShroud);
  for var i := 1 to IceOnLook.Life - 1 do
  begin
    FShroud.Tick(Standing, TwoSeeds);
    var After := MistOf(FShroud);
    Steps := Steps + FallSteps(Before, After);
    Before := After;
  end;

  Assert.IsTrue(Length(Steps) > 0, 'Some mist was seen to move');
  var Step := Steps[0];
  Assert.IsTrue((Step > 0) and (Step <= LongestMistStep),
    Format('Mist sinks by %g a tick', [Step]));
  for var Fall in Steps do
    ExpectNear(Step, Fall, 'Every cloud sinks by the same step on every tick');
  for var Cloud in Before do
    Assert.IsTrue(Cloud.Y >= StandTop + FeetLine - PlaceSlack,
      'No cloud rises above the feet line');
end;

procedure THeroShroudTests.TestMistSettlesOntoAFloorAndStops;
begin
  var FloorY: Single := StandTop + FeetLine + FloorBelowFeet;
  FShroud := THeroShroud.Create(MatterFrom(FloorY), DefaultSeed);
  FShroud.Start(IceOnLook);
  TickTimes(FShroud, IceOnLook.Life * 3 div 4);

  var Settled := MistOf(FShroud);
  Assert.AreEqual(IceOnLook.Bands, Length(Settled), 'All the mist is down');
  for var Cloud in Settled do
    Assert.IsTrue((Cloud.Y >= FloorY) and (Cloud.Y < FloorY + LongestMistStep),
      Format('A cloud lies at %g, the floor is at %g', [Cloud.Y, FloorY]));

  TickTimes(FShroud, 5);
  var Later := MistOf(FShroud);
  Assert.AreEqual(Length(Settled), Length(Later), 'and none has gone');
  for var i := 0 to High(Settled) do
    ExpectNear(Settled[i].Y, Later[i].Y, 'Mist lying on the floor stands');
end;

procedure THeroShroudTests.TestMistWithNoProbeStands;
begin
  FShroud := THeroShroud.Create(nil, DefaultSeed);
  FShroud.Start(IceOnLook);

  TickTimes(FShroud, IceOnLook.Life - 1);

  Assert.AreEqual(IceOnLook.Bands, Length(FShroud.Mist), 'Every band fell');
  for var Cloud in FShroud.Mist do
    ExpectNear(StandTop + FeetLine, Cloud.Y, 'With no matter to ask, mist stays on its row');
end;

procedure THeroShroudTests.TestMistDiesByTheAgeOfItsOwnLook;
begin
  FShroud := THeroShroud.Create(EverywhereMatter, DefaultSeed);
  FShroud.Start(IceOnLook);
  TicksUntilMist(FShroud, Standing);
  Assert.AreEqual(1, Length(FShroud.Mist), 'One cloud has fallen');
  var AgeWhenFallen := FShroud.Mist[0].Age;

  FShroud.Start(IceOffLook);
  var Lived := 0;
  while Length(FShroud.Mist) > 0 do
  begin
    if Lived = IceOnLook.Life then
      Assert.Fail(Format('The cloud is still there %d ticks on', [Lived]));
    TickTimes(FShroud, 1);
    Inc(Lived);
  end;

  Assert.IsTrue(Lived > IceOffLook.Life, 'The cloud outlives the look that replaced its own');
  Assert.AreEqual(IceOnLook.Life - AgeWhenFallen, Lived, 'and goes when its own look is out');
end;

// ---------------------------------------------------------------------------
// The dice
// ---------------------------------------------------------------------------

procedure THeroShroudTests.TestSameSeedGivesTheSameRun;
begin
  FShroud := THeroShroud.Create(EverywhereOpen, DefaultSeed);
  FTwin := THeroShroud.Create(EverywhereOpen, DefaultSeed);
  FShroud.Start(IceOnLook);
  FTwin.Start(IceOnLook);

  var Diverged := 0;
  for var i := 1 to 100 do
  begin
    FShroud.Tick(Standing, TwoSeeds);
    FTwin.Tick(Standing, TwoSeeds);
    if not SameState(FShroud, FTwin) then
      Inc(Diverged);
  end;

  Assert.AreEqual(0, Diverged, 'Two shrouds of one seed part ways');
  Assert.IsTrue(FShroud.Motes.Count > 0, 'There were motes to compare');
  Assert.IsTrue(Length(FShroud.Mist) > 0, 'and mist');
end;

procedure THeroShroudTests.TestOtherSeedGivesAnotherRun;
begin
  FShroud := THeroShroud.Create(EverywhereOpen, DefaultSeed);
  FTwin := THeroShroud.Create(EverywhereOpen, OtherSeed);
  FShroud.Start(IceOnLook);
  FTwin.Start(IceOnLook);

  var Diverged := 0;
  for var i := 1 to 100 do
  begin
    FShroud.Tick(Standing, TwoSeeds);
    FTwin.Tick(Standing, TwoSeeds);
    if not SameState(FShroud, FTwin) then
      Inc(Diverged);
  end;

  Assert.IsTrue(Diverged > 0, 'The seed makes no difference to the run');
end;

initialization
  TDUnitX.RegisterTestFixture(THeroShroudTests);

end.
