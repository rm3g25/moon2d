{
  Tests.Effects.Lightning - what a bolt is made of, and how a field of
  bolts lives.

  The shape: the trunk first and the branches after their parents, every
  limb pinned at both ends and never far from its axis, a branch thinner,
  dimmer and ending in a point, the same seeds making the same bolt, and a
  second stroke along the channel keeping its branches and its big picture.
  The field: a bolt lasts its life in ticks past its leader and its last
  stroke, strikes as many times as its look asks, one to four ticks apart
  and each after the first a little weaker, and every stroke adds to the
  jolt of the screen until someone asks for it.

  What a bolt looks like - the band, the lights, the bloom, the glow of the
  room - and where a bolt that struck a wall ends (ShiftFrame) have no test
  here: none of it shows without drawing.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Effects.Lightning;

interface

uses
  DUnitX.TestFramework, Effects.Lightning;

type
  [TestFixture]
  TBoltShapeTests = class
  public
    [Test]
    procedure TestSameSeedsGiveSameShape;
    [Test]
    procedure TestOtherSeedsGiveOtherShape;
    [Test]
    procedure TestTrunkComesFirstAtFullStrength;
    [Test]
    procedure TestLongerBoltIsCutIntoMorePiecesWithinLimits;
    [Test]
    procedure TestEveryLimbIsPinnedAtBothEnds;
    [Test]
    procedure TestChannelStaysNearItsAxis;
    [Test]
    procedure TestNoForkChanceGivesJustTheTrunk;
    [Test]
    procedure TestSureForkGivesAsManyBranchesAsTriesAllow;
    [Test]
    procedure TestBranchesComeAfterTheirParents;
    [Test]
    procedure TestBranchesOfBranchesAreOneDeepNoMore;
    [Test]
    procedure TestBranchIsNarrowerDimmerAndTapers;
    [Test]
    procedure TestBranchesLeanBothWaysWithinTheirBand;
    [Test]
    procedure TestBranchLengthIsAShareOfWhatIsLeftOfItsParent;
    [Test]
    procedure TestNoBranchIsShorterThanThreeUnits;
    [Test]
    procedure TestBranchLeavesItsParentBetweenItsEnds;
    [Test]
    procedure TestOtherFineSeedKeepsBranchesAndBigPicture;
  end;

  [TestFixture]
  TBoltFieldTests = class
  private
    FField: TBoltField;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestBoltLivesExactlyItsLifeInTicks;
    [Test]
    procedure TestLeaderHoldsBackTheFirstStroke;
    [Test]
    procedure TestBoltOutlivesItsLeader;
    [Test]
    procedure TestBoltLivesItsLifePastTheLastStroke;
    [Test]
    procedure TestStrokesCountIsWhatTheLookAsks;
    [Test]
    procedure TestStrokesAreHeldToOneThroughEight;
    [Test]
    procedure TestRestrokesComeOneToFourTicksApart;
    [Test]
    procedure TestRestrokesAreWeakerThanTheFirst;
    [Test]
    procedure TestTakeJoltGivesTheLooksJoltOnceAndEmpties;
    [Test]
    procedure TestJoltsOfTwoShotsAddUp;
    [Test]
    procedure TestLaterStrokesPileUpUntilAsked;
    [Test]
    procedure TestSameSeedsGiveSameStrokes;
    [Test]
    procedure TestFullFieldDropsItsOldest;
    [Test]
    procedure TestTickDropsOnlyTheSpent;
    [Test]
    procedure TestClearEmptiesTheFieldAndItsPendingJolt;
  end;

implementation

uses
  System.SysUtils, System.Math;

const
  Slack = 0.0001;
  ShapeJag: Single = 0.3;
  FineSalt: Cardinal = $5A5A5A5A;
  SeedStride: Cardinal = 40503;
  SeedBase: Cardinal = $1234567;
  Seeds = 30;
  FieldCapacity = 8;
  FieldSeed = 91;
  ShotSeed = 17;
  ShotLength = 100;
  PlentyOfTicks = 60;
  LookJag = 0.24;
  LookFork = 0.12;

  // Decided in the design: when one of them changes, a red test is the
  // right answer
  MaxStrokes = 8;
  TriesCeiling = 5;
  BranchWidthShare = 0.55;
  BranchLevelShare = 0.6;
  LeanMinDegrees: Single = 18;
  LeanMaxDegrees: Single = 44;
  BranchShareMin = 0.3;
  BranchShareMax = 0.7;
  AlongMin = 0.12;
  AlongMax = 0.75;
  MinBranchLength: Single = 3;
  RestrikeGapMin = 1;
  RestrikeGapMax = 4;
  RestrikeLevelMin = 0.6;
  RestrikeLevelMax = 0.95;

// DUnitX has no Assert.AreEqual for two Singles: they are compared here
procedure ExpectNear(AExpected, AActual: Single; const AWhat: string);
begin
  Assert.IsTrue(Abs(AExpected - AActual) < Slack,
    Format('%s is %g, not %g', [AWhat, AActual, AExpected]));
end;

procedure ExpectBetween(AValue, AFrom, ATo: Single; const AWhat: string);
begin
  var IsBetween := (AValue >= AFrom - Slack) and (AValue <= ATo + Slack);
  Assert.IsTrue(IsBetween,
    Format('%s is %g, not between %g and %g', [AWhat, AValue, AFrom, ATo]));
end;

// Seeds that stay different after the unit sets their low bit
function SeedOf(AIndex: Integer): Cardinal;
begin
  Result := Cardinal(AIndex) * SeedStride + SeedBase;
end;

function ShapeOf(ALength, AForkChance: Single; ASeed: Cardinal): TBoltShape;
begin
  Result := BuildBoltShape(ALength, ShapeJag, AForkChance, ASeed,
    ASeed xor FineSalt, False);
end;

function ShapesOver(ALength, AForkChance: Single): TArray<TBoltShape>;
begin
  SetLength(Result, Seeds);
  for var i := 0 to Seeds - 1 do
    Result[i] := ShapeOf(ALength, AForkChance, SeedOf(i + 1));
end;

function PiecesOf(const ALimb: TBoltLimb): Integer;
begin
  Result := Length(ALimb.Offsets) - 1;
end;

function TrunkPieces(ALength: Single): Integer;
begin
  var Shape := ShapeOf(ALength, 0, SeedOf(1));
  Result := PiecesOf(Shape[0]);
end;

function BranchesOffTrunk(const AShape: TBoltShape): Integer;
begin
  Result := 0;
  for var i := 1 to High(AShape) do
    if AShape[i].Parent = 0 then
      Inc(Result);
end;

function DepthOf(const AShape: TBoltShape; AIndex: Integer): Integer;
begin
  Result := 0;
  var Index := AIndex;
  while (AShape[Index].Parent >= 0) and (Result < Length(AShape)) do
  begin
    Inc(Result);
    Index := AShape[Index].Parent;
  end;
end;

function WidestOffset(const ALimb: TBoltLimb): Single;
begin
  Result := 0;
  for var Offset in ALimb.Offsets do
    Result := Max(Result, Abs(Offset));
end;

// A branch lifted to the shortest length is no share of anything, so it
// is passed over
procedure ExpectBranchShare(const AShape: TBoltShape; AIndex: Integer);
begin
  var Limb := AShape[AIndex];
  if Limb.Length <= MinBranchLength then
    Exit;
  var Parent := AShape[Limb.Parent];
  var Rest: Single := Parent.Length * (1 - Limb.Base / PiecesOf(Parent));
  ExpectBetween(Limb.Length / Rest, BranchShareMin, BranchShareMax,
    'The share of what is left of the parent');
end;

function SameLimb(const AFirst, ASecond: TBoltLimb): Boolean;
begin
  Result := (AFirst.Parent = ASecond.Parent) and (AFirst.Base = ASecond.Base) and
    (AFirst.Lean = ASecond.Lean) and (AFirst.Length = ASecond.Length) and
    (AFirst.Width = ASecond.Width) and (AFirst.Level = ASecond.Level) and
    (AFirst.Tapers = ASecond.Tapers) and
    (Length(AFirst.Offsets) = Length(ASecond.Offsets));
end;

function SameOffsets(const AFirst, ASecond: TBoltLimb): Boolean;
begin
  if Length(AFirst.Offsets) <> Length(ASecond.Offsets) then
    Exit(False);
  for var i := 0 to High(AFirst.Offsets) do
    if AFirst.Offsets[i] <> ASecond.Offsets[i] then
      Exit(False);
  Result := True;
end;

// Every limb but its offsets
function SameLimbs(const AFirst, ASecond: TBoltShape): Boolean;
begin
  if Length(AFirst) <> Length(ASecond) then
    Exit(False);
  for var i := 0 to High(AFirst) do
    if not SameLimb(AFirst[i], ASecond[i]) then
      Exit(False);
  Result := True;
end;

function SameShape(const AFirst, ASecond: TBoltShape): Boolean;
begin
  if not SameLimbs(AFirst, ASecond) then
    Exit(False);
  for var i := 0 to High(AFirst) do
    if not SameOffsets(AFirst[i], ASecond[i]) then
      Exit(False);
  Result := True;
end;

function ShotOf(ASeed: Cardinal): TBoltShot;
begin
  Result := Default(TBoltShot);
  Result.EndX := ShotLength;
  Result.Ending := beBridge;
  Result.Seed := ASeed;
end;

function LookOf(ALifeTicks, AStrokes, ALeaderTicks: Integer;
  AJolt: Single): TBoltLook;
begin
  Result := Default(TBoltLook);
  Result.Jag := LookJag;
  Result.ForkChance := LookFork;
  Result.Jolt := AJolt;
  Result.LifeTicks := ALifeTicks;
  Result.LeaderTicks := ALeaderTicks;
  Result.Strokes := AStrokes;
end;

// What TakeJolt gives now and after each of ATicks ticks
function JoltsOf(AField: TBoltField; ATicks: Integer): TArray<Single>;
begin
  SetLength(Result, ATicks + 1);
  Result[0] := AField.TakeJolt;
  for var i := 1 to ATicks do
  begin
    AField.Tick;
    Result[i] := AField.TakeJolt;
  end;
end;

function JoltsOfFreshShot(AFieldSeed: Cardinal;
  const ALook: TBoltLook): TArray<Single>;
begin
  var Field := TBoltField.Create(FieldCapacity, AFieldSeed);
  try
    Field.Shoot(ShotOf(ShotSeed), ALook);
    Result := JoltsOf(Field, PlentyOfTicks);
  finally
    Field.Free;
  end;
end;

// Each stroke gives a jolt on the tick it begins, and no two begin on one
function StrokeTicksOf(const AJolts: TArray<Single>): TArray<Integer>;
begin
  Result := nil;
  for var i := 0 to High(AJolts) do
    if AJolts[i] > 0 then
      Result := Result + [i];
end;

function StrokesOf(AAsked: Integer): Integer;
begin
  var Jolts := JoltsOfFreshShot(FieldSeed, LookOf(3, AAsked, 0, 1));
  Result := Length(StrokeTicksOf(Jolts));
end;

function SameJolts(const AFirst, ASecond: TArray<Single>): Boolean;
begin
  if Length(AFirst) <> Length(ASecond) then
    Exit(False);
  for var i := 0 to High(AFirst) do
    if AFirst[i] <> ASecond[i] then
      Exit(False);
  Result := True;
end;

// ---------------------------------------------------------------------------
// TBoltShapeTests
// ---------------------------------------------------------------------------

procedure TBoltShapeTests.TestSameSeedsGiveSameShape;
begin
  var First := BuildBoltShape(120, ShapeJag, 1, 11, 13, False);
  var Second := BuildBoltShape(120, ShapeJag, 1, 11, 13, False);

  Assert.IsTrue(SameShape(First, Second), 'The same seeds gave another shape');
end;

procedure TBoltShapeTests.TestOtherSeedsGiveOtherShape;
begin
  var First := BuildBoltShape(120, ShapeJag, 1, 11, 13, False);
  var OtherCoarse := BuildBoltShape(120, ShapeJag, 1, 33, 13, False);
  var OtherFine := BuildBoltShape(120, ShapeJag, 1, 11, 31, False);

  Assert.IsFalse(SameShape(First, OtherCoarse), 'The coarse seed changed nothing');
  Assert.IsFalse(SameShape(First, OtherFine), 'The fine seed changed nothing');
end;

procedure TBoltShapeTests.TestTrunkComesFirstAtFullStrength;
begin
  var Plain := BuildBoltShape(100, ShapeJag, 1, 11, 13, False);
  var Pointed := BuildBoltShape(100, ShapeJag, 1, 11, 13, True);

  Assert.AreEqual(-1, Plain[0].Parent, 'The trunk hangs on nothing');
  ExpectNear(100, Plain[0].Length, 'The length of the trunk');
  ExpectNear(1, Plain[0].Width, 'The width of the trunk');
  ExpectNear(1, Plain[0].Level, 'The light of the trunk');
  Assert.IsFalse(Plain[0].Tapers, 'The trunk tapers though it was not asked to');
  Assert.IsTrue(Pointed[0].Tapers, 'The trunk does not taper though it was asked to');
end;

procedure TBoltShapeTests.TestLongerBoltIsCutIntoMorePiecesWithinLimits;
begin
  Assert.AreEqual(2, TrunkPieces(1), 'A bolt of one unit');
  Assert.AreEqual(4, TrunkPieces(10), 'A bolt of ten units');
  Assert.AreEqual(128, TrunkPieces(380), 'A bolt of 380 units');
  Assert.AreEqual(128, TrunkPieces(5000), 'A bolt far longer than the screen');
end;

procedure TBoltShapeTests.TestEveryLimbIsPinnedAtBothEnds;
begin
  for var Shape in ShapesOver(380, 1) do
    for var Limb in Shape do
    begin
      ExpectNear(0, Limb.Offsets[0], 'The offset at the root');
      ExpectNear(0, Limb.Offsets[High(Limb.Offsets)], 'The offset at the tip');
    end;
end;

procedure TBoltShapeTests.TestChannelStaysNearItsAxis;
begin
  for var Shape in ShapesOver(380, 1) do
    for var Limb in Shape do
    begin
      var Widest := WidestOffset(Limb);
      var Reach: Single := 2 * ShapeJag * Limb.Length;
      Assert.IsTrue(Widest <= Reach,
        Format('A limb of %g units strays %g from its axis, more than %g',
        [Limb.Length, Widest, Reach]));
    end;
end;

procedure TBoltShapeTests.TestNoForkChanceGivesJustTheTrunk;
begin
  for var Shape in ShapesOver(380, 0) do
    Assert.AreEqual(1, Length(Shape), 'A bolt that cannot fork has branches');
end;

procedure TBoltShapeTests.TestSureForkGivesAsManyBranchesAsTriesAllow;
begin
  for var Shape in ShapesOver(10, 1) do
    Assert.AreEqual(1, BranchesOffTrunk(Shape), 'A trunk of ten units');
  for var Shape in ShapesOver(80, 1) do
    Assert.AreEqual(3, BranchesOffTrunk(Shape), 'A trunk of eighty units');
  for var Shape in ShapesOver(380, 1) do
    Assert.AreEqual(TriesCeiling, BranchesOffTrunk(Shape), 'A long trunk');
end;

procedure TBoltShapeTests.TestBranchesComeAfterTheirParents;
begin
  for var Shape in ShapesOver(380, 1) do
    for var i := 1 to High(Shape) do
      Assert.IsTrue((Shape[i].Parent >= 0) and (Shape[i].Parent < i),
        Format('Limb %d hangs on limb %d', [i, Shape[i].Parent]));
end;

procedure TBoltShapeTests.TestBranchesOfBranchesAreOneDeepNoMore;
begin
  var Deepest := 0;
  for var Shape in ShapesOver(380, 1) do
    for var i := 0 to High(Shape) do
      Deepest := Max(Deepest, DepthOf(Shape, i));

  Assert.AreEqual(2, Deepest, 'A branch may have a branch, and no more');
end;

procedure TBoltShapeTests.TestBranchIsNarrowerDimmerAndTapers;
begin
  for var Shape in ShapesOver(380, 1) do
    for var i := 1 to High(Shape) do
    begin
      var Parent := Shape[Shape[i].Parent];
      ExpectNear(Parent.Width * BranchWidthShare, Shape[i].Width,
        'The width of a branch');
      ExpectNear(Parent.Level * BranchLevelShare, Shape[i].Level,
        'The light of a branch');
      Assert.IsTrue(Shape[i].Tapers, 'A branch does not end in a point');
    end;
end;

procedure TBoltShapeTests.TestBranchesLeanBothWaysWithinTheirBand;
begin
  var SawLeft := False;
  var SawRight := False;
  for var Shape in ShapesOver(380, 1) do
    for var i := 1 to High(Shape) do
    begin
      var Lean := Shape[i].Lean;
      ExpectBetween(Abs(Lean), DegToRad(LeanMinDegrees), DegToRad(LeanMaxDegrees),
        'The lean of a branch');
      SawLeft := SawLeft or (Lean < 0);
      SawRight := SawRight or (Lean > 0);
    end;

  Assert.IsTrue(SawLeft and SawRight, 'Branches leave to one side only');
end;

procedure TBoltShapeTests.TestBranchLengthIsAShareOfWhatIsLeftOfItsParent;
begin
  for var Shape in ShapesOver(380, 1) do
    for var i := 1 to High(Shape) do
      ExpectBranchShare(Shape, i);
end;

procedure TBoltShapeTests.TestNoBranchIsShorterThanThreeUnits;
begin
  for var Shape in ShapesOver(30, 1) do
    for var i := 1 to High(Shape) do
      Assert.IsTrue(Shape[i].Length >= MinBranchLength - Slack,
        Format('Limb %d is %g units long', [i, Shape[i].Length]));
end;

procedure TBoltShapeTests.TestBranchLeavesItsParentBetweenItsEnds;
begin
  for var Shape in ShapesOver(380, 1) do
    for var i := 1 to High(Shape) do
    begin
      var Base := Shape[i].Base;
      var Pieces := PiecesOf(Shape[Shape[i].Parent]);
      Assert.IsTrue((Base >= 1) and (Base <= Pieces - 1),
        Format('Limb %d leaves point %d of %d', [i, Base, Pieces]));
      var Half: Single := 0.5 / Pieces;
      ExpectBetween(Base / Pieces, AlongMin - Half, AlongMax + Half,
        'Where a branch leaves its parent');
    end;
end;

procedure TBoltShapeTests.TestOtherFineSeedKeepsBranchesAndBigPicture;
begin
  var First := BuildBoltShape(100, ShapeJag, 1, 11, 13, False);
  var Again := BuildBoltShape(100, ShapeJag, 1, 11, 31, False);

  Assert.IsTrue(SameLimbs(First, Again), 'A fine seed moved or reshaped a limb');
  var Pieces := PiecesOf(First[0]);
  for var Quarter := 0 to 4 do
  begin
    var Spot := Pieces * Quarter div 4;
    ExpectNear(First[0].Offsets[Spot], Again[0].Offsets[Spot],
      'The offset at a quarter of the trunk');
  end;
  Assert.IsFalse(SameShape(First, Again), 'The channel did not shiver');
end;

// ---------------------------------------------------------------------------
// TBoltFieldTests
// ---------------------------------------------------------------------------

procedure TBoltFieldTests.Setup;
begin
  FField := TBoltField.Create(FieldCapacity, FieldSeed);
end;

procedure TBoltFieldTests.TearDown;
begin
  FreeAndNil(FField);
end;

procedure TBoltFieldTests.TestBoltLivesExactlyItsLifeInTicks;
const
  Life = 5;
begin
  FField.Shoot(ShotOf(ShotSeed), LookOf(Life, 1, 0, 0));
  Assert.AreEqual(1, FField.Count, 'A shot is in the field at once');

  for var i := 1 to Life - 1 do
    FField.Tick;
  Assert.AreEqual(1, FField.Count, 'The bolt is gone before its life is spent');

  FField.Tick;
  Assert.AreEqual(0, FField.Count, 'The bolt outlives its life');
end;

procedure TBoltFieldTests.TestLeaderHoldsBackTheFirstStroke;
const
  Leader = 4;
begin
  FField.Shoot(ShotOf(ShotSeed), LookOf(3, 1, Leader, 0.5));

  var Ticks := StrokeTicksOf(JoltsOf(FField, PlentyOfTicks));

  Assert.AreEqual(1, Length(Ticks), 'One stroke gives one jolt');
  Assert.AreEqual(Leader, Ticks[0], 'The tick of the first stroke');
end;

procedure TBoltFieldTests.TestBoltOutlivesItsLeader;
const
  Leader = 4;
  Life = 3;
begin
  FField.Shoot(ShotOf(ShotSeed), LookOf(Life, 1, Leader, 0));
  Assert.AreEqual(1, FField.Count, 'A bolt in its leader is in the field');

  for var i := 1 to Leader + Life - 1 do
    FField.Tick;
  Assert.AreEqual(1, FField.Count, 'The bolt is gone before its stroke is spent');

  FField.Tick;
  Assert.AreEqual(0, FField.Count, 'The bolt outlives its stroke');
end;

procedure TBoltFieldTests.TestBoltLivesItsLifePastTheLastStroke;
const
  Life = 4;
begin
  FField.Shoot(ShotOf(ShotSeed), LookOf(Life, MaxStrokes, 0, 1));

  var LastStroke := 0;
  var Counts: TArray<Integer>;
  SetLength(Counts, PlentyOfTicks + 1);
  for var i := 0 to PlentyOfTicks do
  begin
    if FField.TakeJolt > 0 then
      LastStroke := i;
    Counts[i] := FField.Count;
    FField.Tick;
  end;

  Assert.AreEqual(1, Counts[LastStroke + Life - 1],
    'The bolt is gone before the life of its last stroke is spent');
  Assert.AreEqual(0, Counts[LastStroke + Life],
    'The bolt outlives its last stroke');
end;

procedure TBoltFieldTests.TestStrokesCountIsWhatTheLookAsks;
begin
  Assert.AreEqual(1, StrokesOf(1), 'One asked');
  Assert.AreEqual(2, StrokesOf(2), 'Two asked');
  Assert.AreEqual(5, StrokesOf(5), 'Five asked');
end;

procedure TBoltFieldTests.TestStrokesAreHeldToOneThroughEight;
begin
  Assert.AreEqual(1, StrokesOf(0), 'None asked');
  Assert.AreEqual(MaxStrokes, StrokesOf(20), 'Twenty asked');
end;

procedure TBoltFieldTests.TestRestrokesComeOneToFourTicksApart;
begin
  var Shortest := MaxInt;
  var Longest := 0;
  for var i := 1 to Seeds do
  begin
    var Jolts := JoltsOfFreshShot(SeedOf(i), LookOf(3, MaxStrokes, 0, 1));
    var Ticks := StrokeTicksOf(Jolts);
    for var k := 1 to High(Ticks) do
    begin
      var Gap := Ticks[k] - Ticks[k - 1];
      Shortest := Min(Shortest, Gap);
      Longest := Max(Longest, Gap);
    end;
  end;

  Assert.AreEqual(RestrikeGapMin, Shortest, 'The shortest wait between strokes');
  Assert.AreEqual(RestrikeGapMax, Longest, 'The longest wait between strokes');
end;

procedure TBoltFieldTests.TestRestrokesAreWeakerThanTheFirst;
begin
  for var i := 1 to Seeds do
  begin
    var Jolts := JoltsOfFreshShot(SeedOf(i), LookOf(3, MaxStrokes, 0, 1));
    var Ticks := StrokeTicksOf(Jolts);
    ExpectNear(1, Jolts[Ticks[0]], 'The first stroke');
    for var k := 1 to High(Ticks) do
      ExpectBetween(Jolts[Ticks[k]], RestrikeLevelMin, RestrikeLevelMax,
        'A later stroke');
  end;
end;

procedure TBoltFieldTests.TestTakeJoltGivesTheLooksJoltOnceAndEmpties;
const
  LookJolt = 0.14;
begin
  FField.Shoot(ShotOf(ShotSeed), LookOf(3, 1, 0, LookJolt));

  ExpectNear(LookJolt, FField.TakeJolt, 'The jolt of the first stroke');
  ExpectNear(0, FField.TakeJolt, 'The jolt asked for again');
end;

procedure TBoltFieldTests.TestJoltsOfTwoShotsAddUp;
begin
  FField.Shoot(ShotOf(ShotSeed), LookOf(3, 1, 0, 0.1));
  FField.Shoot(ShotOf(ShotSeed + 2), LookOf(3, 1, 0, 0.2));

  ExpectNear(0.3, FField.TakeJolt, 'The jolt of two shots asked for once');
end;

procedure TBoltFieldTests.TestLaterStrokesPileUpUntilAsked;
begin
  FField.Shoot(ShotOf(ShotSeed), LookOf(3, 3, 0, 1));
  for var i := 1 to PlentyOfTicks do
    FField.Tick;

  var Piled := FField.TakeJolt;

  ExpectBetween(Piled, 1 + 2 * RestrikeLevelMin, 1 + 2 * RestrikeLevelMax,
    'The jolt of three strokes nobody asked for');
end;

procedure TBoltFieldTests.TestSameSeedsGiveSameStrokes;
begin
  var Look := LookOf(3, MaxStrokes, 0, 1);
  var First := JoltsOfFreshShot(101, Look);
  var Again := JoltsOfFreshShot(101, Look);
  var Other := JoltsOfFreshShot(303, Look);

  Assert.IsTrue(SameJolts(First, Again), 'The same seed gave other strokes');
  Assert.IsFalse(SameJolts(First, Other), 'The seed of the field changed nothing');
end;

procedure TBoltFieldTests.TestFullFieldDropsItsOldest;
const
  Capacity = 3;
begin
  var Field := TBoltField.Create(Capacity, FieldSeed);
  try
    Field.Shoot(ShotOf(ShotSeed), LookOf(20, 1, 0, 0));
    for var i := 1 to Capacity do
      Field.Shoot(ShotOf(ShotSeed), LookOf(3, 1, 0, 0));
    Assert.AreEqual(Capacity, Field.Count, 'A full field holds no more');

    for var i := 1 to 3 do
      Field.Tick;
    Assert.AreEqual(0, Field.Count, 'The oldest bolt was kept, not dropped');
  finally
    Field.Free;
  end;
end;

procedure TBoltFieldTests.TestTickDropsOnlyTheSpent;
begin
  FField.Shoot(ShotOf(ShotSeed), LookOf(2, 1, 0, 0));
  FField.Shoot(ShotOf(ShotSeed), LookOf(6, 1, 0, 0));
  FField.Shoot(ShotOf(ShotSeed), LookOf(2, 1, 0, 0));

  for var i := 1 to 2 do
    FField.Tick;
  Assert.AreEqual(1, FField.Count, 'Two bolts were spent and one was not');

  for var i := 3 to 5 do
    FField.Tick;
  Assert.AreEqual(1, FField.Count, 'The long bolt was dropped with the short');

  FField.Tick;
  Assert.AreEqual(0, FField.Count, 'The long bolt outlives its life');
end;

procedure TBoltFieldTests.TestClearEmptiesTheFieldAndItsPendingJolt;
begin
  FField.Shoot(ShotOf(ShotSeed), LookOf(3, 1, 0, 0.5));
  FField.Shoot(ShotOf(ShotSeed), LookOf(3, 1, 0, 0.5));

  FField.Clear;

  Assert.AreEqual(0, FField.Count, 'Clear left bolts in the field');
  ExpectNear(0, FField.TakeJolt, 'The jolt of bolts that are gone');
  FField.Tick;
  Assert.AreEqual(0, FField.Count, 'A cleared bolt came back');
end;

initialization
  TDUnitX.RegisterTestFixture(TBoltShapeTests);
  TDUnitX.RegisterTestFixture(TBoltFieldTests);

end.
