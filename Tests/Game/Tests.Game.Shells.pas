{
  Tests.Game.Shells - the bunker's shells: a shell lobbed at a point comes
  down on it, along a low arc that climbs and stays on the screen; on a
  road that slides it comes down where the point has been carried, so a
  hero standing gets it. The ring marks where it will come down: on a
  deck under the arc before the road, and on down to the road once the
  deck is gone. It bursts on a deck it comes down on, never on one it
  rises through. Missing every deck it lands on the road and rolls left,
  faster than the road; in the air or rolling, it is spent on a body it
  touches, and not on one it passes by; past the left edge it is gone. As many as its slots at
  once; a clear takes them all.

  Aloft: a shell lobbed at a barge rides that barge's way and bursts on it
  where it was aimed on the deck - another barge's way is not its own;
  with no road it falls past the bottom edge and has a ring only while a
  deck lies under it; the ring is drawn between two ticks as its deck
  flies; an arc may be lobbed lower than the bunker's.

  The second shell of a pair: at the pad the hero stands on, wherever it
  is; else at the nearest pad a plain jump up that has ridden past the
  middle of the screen - never one still on the right half, nor one too
  high; else onto the road ahead of him, never past the right edge.

  The second shell of the hunt: at the nearest pad ahead of the hero along
  his row - not the one under him, not one behind him, not one of another
  row; else onto the road ahead of him.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Game.Shells;

interface

uses
  DUnitX.TestFramework,
  Game.Shells;

type
  [TestFixture]
  TBunkerShellTests = class
  private
    FShells: TBunkerShells;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestComesDownOnItsTarget;
    [Test]
    procedure TestTheArcClimbsAndStaysOnTheScreen;
    [Test]
    procedure TestOnASlidingRoadAStandingHeroGetsIt;
    [Test]
    procedure TestTheRingMarksWhereItComesDown;
    [Test]
    procedure TestBurstsOnTheDeckItComesDownOn;
    [Test]
    procedure TestRisesThroughADeckWithoutBursting;
    [Test]
    procedure TestTheRingGoesDownWhenTheDeckIsGone;
    [Test]
    procedure TestRollsLeftFasterThanTheRoad;
    [Test]
    procedure TestLobbedRightItRollsRight;
    [Test]
    procedure TestTheRoadMarkIsTheRoadWithNoDeckInTheWay;
    [Test]
    procedure TestTheRoadMarkStepsAsideFromADeckOverIt;
    [Test]
    procedure TestRollingItIsSpentOnABody;
    [Test]
    procedure TestInTheAirItIsSpentOnABody;
    [Test]
    procedure TestGonePastTheLeftEdge;
    [Test]
    procedure TestAsManyAsItsSlots;
    [Test]
    procedure TestClearTakesThemAll;
  end;

  [TestFixture]
  TShellsAloftTests = class
  private
    FShells: TBunkerShells;
    // The barge ACarrier flies AWayX, AWayY this tick: its deck moves, the
    // shells that ride it are told
    procedure Fly(var ADeck: TShellDeck; AWayX, AWayY: Single; ACarrier: Integer);
    // The top of an arc of ARise from AFromY onto the barge, nothing under it
    function HighestOf(AFromY, ARise: Single): Single;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestItRidesItsBargeAndBurstsOnIt;
    [Test]
    procedure TestAnotherBargesWayIsNotItsOwn;
    [Test]
    procedure TestWithNoRoadItFallsPastTheBottom;
    [Test]
    procedure TestWithNoRoadTheRingLiesOnlyOnADeck;
    [Test]
    procedure TestTheRingIsDrawnBetweenTicksAsItsDeckFlies;
    [Test]
    procedure TestALowerArcOfItsOwn;
  end;

  [TestFixture]
  TSecondShellMarkTests = class
  public
    [Test]
    procedure TestThePadHeStandsOn;
    [Test]
    procedure TestTheNearestPadPastTheMiddleAJumpUp;
    [Test]
    procedure TestNotAPadStillOnTheRightHalf;
    [Test]
    procedure TestNotOneTooHigh;
    [Test]
    procedure TestNoneTheRoadAheadNeverPastTheEdge;
  end;

  [TestFixture]
  TAheadShellMarkTests = class
  public
    [Test]
    procedure TestTheNearestPadAheadAlongHisRow;
    [Test]
    procedure TestNotUnderHimBehindHimNorOnAnotherRow;
    [Test]
    procedure TestNoneTheRoadAhead;
  end;

implementation

uses
  System.Math,
  System.SysUtils,
  Sdl2.Core,
  Game.Space;

const
  RoadY = 352.0;
  // The bunker's muzzle with the Ram at the right wall
  MuzzleX = 409.0;
  MuzzleY = 217.0;
  // A high pad of the chase
  DeckLeft = 230.0;
  DeckWidth = 64.0;
  DeckTop = 128.0;
  Still = 0.0;
  Road = -1.0;
  // Longer than any arc
  ManyTicks = 300;
  Near = 2.0;

function At(AX, AY: Single): TSdlFPoint;
begin
  Result.X := AX;
  Result.Y := AY;
end;

function Deck(ALeft, AWidth, ATop: Single): TShellDeck;
begin
  Result.Left := ALeft;
  Result.Right := ALeft + AWidth;
  Result.Top := ATop;
end;

// No pad on the screen
function NoDecks: TArray<TShellDeck>;
begin
  Result := nil;
end;

function Box(AX, AY, AW, AH: Single): TSdlFRect;
begin
  Result.X := AX;
  Result.Y := AY;
  Result.W := AW;
  Result.H := AH;
end;

procedure TBunkerShellTests.Setup;
begin
  FShells := TBunkerShells.Create(RoadY);
end;

procedure TBunkerShellTests.TearDown;
begin
  FShells.Free;
end;

// The first slot's shell until it lands on the road; -1 when it does not
function LandsWithin(AShells: TBunkerShells; const ADecks: TArray<TShellDeck>;
  AWay: Single; out AAt: TSdlFPoint): Integer;
begin
  for var i := 1 to ManyTicks do
    if AShells.Tick(ADecks, AWay).Landed then
    begin
      AAt := AShells[0].Middle;
      Exit(i);
    end;
  Result := -1;
end;

procedure TBunkerShellTests.TestComesDownOnItsTarget;
begin
  Assert.IsTrue(FShells.Lob(At(MuzzleX, MuzzleY), At(100, RoadY)), 'Lobbed');
  var Landed: TSdlFPoint;
  Assert.IsTrue(LandsWithin(FShells, NoDecks, Still, Landed) > 0, 'Lands');
  Assert.AreEqual(100.0, Double(Landed.X), Near, 'On its target');
end;

procedure TBunkerShellTests.TestTheArcClimbsAndStaysOnTheScreen;
const
  // Climbs at least this far over the higher end
  LeastClimb = 20.0;
begin
  FShells.Lob(At(MuzzleX, MuzzleY), At(DeckLeft + 32, DeckTop));
  var Highest: Single := MuzzleY;
  for var i := 1 to ManyTicks do
  begin
    FShells.Tick(NoDecks, Still);
    if FShells[0].State <> ssFlying then
      Break;
    Highest := Min(Highest, FShells[0].Middle.Y);
  end;
  Assert.IsTrue(Highest <= DeckTop - LeastClimb, Format('Climbs to %g', [Highest]));
  Assert.IsTrue(Highest > 0, 'Seen whole');
end;

procedure TBunkerShellTests.TestOnASlidingRoadAStandingHeroGetsIt;
begin
  FShells.Lob(At(MuzzleX, MuzzleY), At(200, RoadY));
  var Flight := FShells[0].FlightTicks;
  var Landed: TSdlFPoint;
  var Ticks := LandsWithin(FShells, NoDecks, Road, Landed);
  Assert.IsTrue(Ticks > 0, 'Lands');
  Assert.AreEqual(Double(200 + Flight * Road), Double(Landed.X), Near,
    'Where his feet have been carried');
end;

procedure TBunkerShellTests.TestTheRingMarksWhereItComesDown;
begin
  FShells.Lob(At(MuzzleX, MuzzleY), At(150, RoadY));
  FShells.Tick(NoDecks, Still);
  var Ring := FShells[0].Ring;
  Assert.IsFalse(FShells[0].RingOnDeck, 'On the road');
  var Landed: TSdlFPoint;
  Assert.IsTrue(LandsWithin(FShells, NoDecks, Still, Landed) > 0, 'Lands');
  Assert.AreEqual(Double(Ring.X), Double(Landed.X), Near, 'Where the ring was');
end;

procedure TBunkerShellTests.TestBurstsOnTheDeckItComesDownOn;
begin
  var Decks: TArray<TShellDeck> := [Deck(DeckLeft, DeckWidth, DeckTop)];
  FShells.Lob(At(MuzzleX, MuzzleY), At(DeckLeft + 32, DeckTop));
  FShells.Tick(Decks, Still);
  Assert.IsTrue(FShells[0].RingOnDeck, 'The ring on the deck');
  for var i := 1 to ManyTicks do
  begin
    var Cue := FShells.Tick(Decks, Still);
    Assert.IsFalse(Cue.Landed, 'Not on the road');
    if Length(Cue.Bursts) = 0 then
      Continue;
    Assert.AreEqual(0, Cue.Bursts[0].Deck, 'On the deck');
    Assert.AreEqual(Double(DeckLeft + 32), Double(Cue.Bursts[0].At.X), Near,
      'Where it was lobbed at');
    Assert.AreEqual(DeckTop, Double(Cue.Bursts[0].At.Y), 0.001, 'On its top');
    Assert.AreEqual(0, FShells.Active, 'Spent');
    Exit;
  end;
  Assert.Fail('No burst');
end;

procedure TBunkerShellTests.TestRisesThroughADeckWithoutBursting;
begin
  // Right over the muzzle, in the way of its climb
  var Decks: TArray<TShellDeck> := [Deck(MuzzleX - 40, 64, MuzzleY - 12)];
  FShells.Lob(At(MuzzleX, MuzzleY), At(100, RoadY));
  var Landed: TSdlFPoint;
  Assert.IsTrue(LandsWithin(FShells, Decks, Still, Landed) > 0,
    'On down to the road');
end;

procedure TBunkerShellTests.TestTheRingGoesDownWhenTheDeckIsGone;
begin
  var Decks: TArray<TShellDeck> := [Deck(DeckLeft, DeckWidth, DeckTop)];
  FShells.Lob(At(MuzzleX, MuzzleY), At(DeckLeft + 32, DeckTop));
  FShells.Tick(Decks, Still);
  Assert.IsTrue(FShells[0].RingOnDeck, 'On the deck while it stands');
  FShells.Tick(NoDecks, Still);
  Assert.IsFalse(FShells[0].RingOnDeck, 'Then on the road');
  Assert.AreEqual(RoadY, Double(FShells[0].Ring.Y), 0.001, 'Down there');
  var Landed: TSdlFPoint;
  Assert.IsTrue(LandsWithin(FShells, NoDecks, Still, Landed) > 0, 'And lands');
end;

procedure TBunkerShellTests.TestRollsLeftFasterThanTheRoad;
begin
  FShells.Lob(At(MuzzleX, MuzzleY), At(300, RoadY));
  var Landed: TSdlFPoint;
  Assert.IsTrue(LandsWithin(FShells, NoDecks, Road, Landed) > 0, 'Lands');
  Assert.IsTrue(FShells[0].State = ssRolling, 'Rolls');
  for var i := 1 to 10 do
  begin
    var Before := FShells[0].Middle.X;
    FShells.Tick(NoDecks, Road);
    Assert.IsTrue(FShells[0].Middle.X < Before + Road - 0.5,
      'Left, faster than the road');
    Assert.AreEqual(Double(RoadY - ShellRadius), Double(FShells[0].Middle.Y),
      0.001, 'On the road');
  end;
end;

procedure TBunkerShellTests.TestLobbedRightItRollsRight;
const
  // Right of the muzzle: the hull turned round shoots this way
  RightX = 470.0;
begin
  FShells.Lob(At(MuzzleX, MuzzleY), At(RightX, RoadY));
  var Landed: TSdlFPoint;
  Assert.IsTrue(LandsWithin(FShells, NoDecks, Road, Landed) > 0, 'Lands');
  Assert.IsTrue(FShells[0].State = ssRolling, 'Rolls');
  for var i := 1 to 10 do
  begin
    var Before := FShells[0].Middle.X;
    FShells.Tick(NoDecks, Road);
    if FShells[0].State <> ssRolling then
      Break;
    Assert.IsTrue(FShells[0].Middle.X > Before + 0.5,
      'Right, against the road');
  end;
end;

procedure TBunkerShellTests.TestTheRoadMarkIsTheRoadWithNoDeckInTheWay;
const
  MarkX = 250.0;
begin
  var Mark := FShells.RoadMark(At(MuzzleX, MuzzleY), MarkX, NoDecks);
  Assert.AreEqual(MarkX, Double(Mark.X), 0.001, 'Where it was asked');
  Assert.AreEqual(RoadY, Double(Mark.Y), 0.001, 'On the road');
end;

procedure TBunkerShellTests.TestTheRoadMarkStepsAsideFromADeckOverIt;
const
  // A low pad over the road at the mark: a shell aimed straight at the
  // road there bursts on it
  LowLeft = 220.0;
  LowWidth = 64.0;
  LowTop = 272.0;
  MarkX = 250.0;
  // Its search reaches no farther
  Reach = 64.0;
begin
  var Decks: TArray<TShellDeck> := [Deck(LowLeft, LowWidth, LowTop)];
  FShells.Lob(At(MuzzleX, MuzzleY), At(MarkX, RoadY));
  var Cue := FShells.Tick(Decks, Still);
  var Burst := Length(Cue.Bursts) > 0;
  for var i := 1 to ManyTicks do
  begin
    if Burst or (FShells[0].State <> ssFlying) then
      Break;
    Cue := FShells.Tick(Decks, Still);
    Burst := Length(Cue.Bursts) > 0;
  end;
  Assert.IsTrue(Burst, 'Straight at the road there, the pad takes it');

  var Mark := FShells.RoadMark(At(MuzzleX, MuzzleY), MarkX, Decks);
  Assert.IsTrue(Abs(Mark.X - MarkX) <= Reach, Format('Aside to %g', [Mark.X]));
  Assert.IsTrue(Abs(Mark.X - MarkX) > 0, 'Not where the pad is');
  FShells.Clear;
  FShells.Lob(At(MuzzleX, MuzzleY), Mark);
  var Landed: TSdlFPoint;
  Assert.IsTrue(LandsWithin(FShells, Decks, Still, Landed) > 0,
    'It comes down on the road');
end;

procedure TBunkerShellTests.TestRollingItIsSpentOnABody;
begin
  FShells.Lob(At(MuzzleX, MuzzleY), At(300, RoadY));
  var Landed: TSdlFPoint;
  LandsWithin(FShells, NoDecks, Still, Landed);
  var Hero := Box(240, RoadY - 32, 16, 32);
  var Struck := False;
  for var i := 1 to ManyTicks do
  begin
    var Where: TSdlFPoint;
    if FShells.Strikes(Hero, Where) then
    begin
      Struck := True;
      Assert.IsTrue(Abs(Where.X - 248) <= 8 + ShellRadius + Near, 'At him');
      Break;
    end;
    FShells.Tick(NoDecks, Still);
  end;
  Assert.IsTrue(Struck, 'It runs into him');
  Assert.AreEqual(0, FShells.Active, 'Spent on him');
  var Again: TSdlFPoint;
  Assert.IsFalse(FShells.Strikes(Hero, Again), 'Once');
end;

procedure TBunkerShellTests.TestInTheAirItIsSpentOnABody;
begin
  FShells.Lob(At(MuzzleX, MuzzleY), At(100, RoadY));
  for var i := 1 to 10 do
    FShells.Tick(NoDecks, Still);
  Assert.IsTrue(FShells[0].State = ssFlying, 'Still flying');
  var Middle := FShells[0].Middle;
  var Where: TSdlFPoint;
  Assert.IsFalse(FShells.Strikes(Box(Middle.X + 40, Middle.Y - 16, 16, 32),
    Where), 'Not one it passes by');
  Assert.IsTrue(FShells.Strikes(Box(Middle.X - 8, Middle.Y - 16, 16, 32),
    Where), 'Caught in the air');
  Assert.AreEqual(Double(Middle.X), Double(Where.X), 0.001, 'Where it was');
  Assert.AreEqual(0, FShells.Active, 'Spent on him');
end;

procedure TBunkerShellTests.TestGonePastTheLeftEdge;
begin
  FShells.Lob(At(MuzzleX, MuzzleY), At(60, RoadY));
  for var i := 1 to ManyTicks do
    FShells.Tick(NoDecks, Road);
  Assert.AreEqual(0, FShells.Active, 'Gone');
end;

procedure TBunkerShellTests.TestAsManyAsItsSlots;
begin
  for var i := 1 to ShellSlots do
    Assert.IsTrue(FShells.Lob(At(MuzzleX, MuzzleY), At(100 + i, RoadY)),
      Format('Shell %d', [i]));
  Assert.IsFalse(FShells.Lob(At(MuzzleX, MuzzleY), At(100, RoadY)), 'No more');
  Assert.AreEqual(ShellSlots, FShells.Active, 'All of them');
end;

procedure TBunkerShellTests.TestClearTakesThemAll;
begin
  FShells.Lob(At(MuzzleX, MuzzleY), At(100, RoadY));
  FShells.Lob(At(MuzzleX, MuzzleY), At(300, RoadY));
  FShells.Clear;
  Assert.AreEqual(0, FShells.Active, 'None');
end;

// ---------------------------------------------------------------------------
// Aloft
// ---------------------------------------------------------------------------

const
  // The mortar's muzzle on the hanging Ram, near the top of the screen
  MortarX = 300.0;
  MortarY = 12.0;
  // A small barge on a lane
  BargeLeft = 160.0;
  BargeWidth = 104.0;
  BargeTop = 230.0;
  AloftRise = 20.0;
  Carrier = 3;

procedure TShellsAloftTests.Setup;
begin
  FShells := TBunkerShells.Create(RoadY);
  FShells.HasRoad := False;
end;

procedure TShellsAloftTests.TearDown;
begin
  FShells.Free;
end;

procedure TShellsAloftTests.Fly(var ADeck: TShellDeck; AWayX, AWayY: Single;
  ACarrier: Integer);
begin
  ADeck.Left := ADeck.Left + AWayX;
  ADeck.Right := ADeck.Right + AWayX;
  ADeck.Top := ADeck.Top + AWayY;
  FShells.Carry(ACarrier, AWayX, AWayY);
end;

procedure TShellsAloftTests.TestItRidesItsBargeAndBurstsOnIt;
const
  WayX = -1.5;
  WayY = 0.4;
  AimX = BargeLeft + 40;
begin
  var Decks: TArray<TShellDeck> := [Deck(BargeLeft, BargeWidth, BargeTop)];
  Assert.IsTrue(FShells.Lob(At(MortarX, MortarY), At(AimX, BargeTop), Carrier,
    AloftRise), 'Lobbed');
  for var i := 1 to ManyTicks do
  begin
    Fly(Decks[0], WayX, WayY, Carrier);
    var Cue := FShells.Tick(Decks, Still);
    if Length(Cue.Bursts) = 0 then
      Continue;
    Assert.AreEqual(0, Cue.Bursts[0].Deck, 'On its barge');
    Assert.AreEqual(Double(AimX + i * WayX), Double(Cue.Bursts[0].At.X), Near,
      'Where it was aimed on the deck');
    Assert.AreEqual(Double(Decks[0].Top), Double(Cue.Bursts[0].At.Y), 0.001,
      'On the deck as it flies');
    Exit;
  end;
  Assert.Fail('No burst');
end;

procedure TShellsAloftTests.TestAnotherBargesWayIsNotItsOwn;
const
  AimX = BargeLeft + 40;
begin
  var Decks: TArray<TShellDeck> := [Deck(BargeLeft, BargeWidth, BargeTop)];
  FShells.Lob(At(MortarX, MortarY), At(AimX, BargeTop), Carrier, AloftRise);
  for var i := 1 to ManyTicks do
  begin
    FShells.Carry(Carrier + 1, -3, 0);
    FShells.Carry(NoCarrier, -3, 0);
    var Cue := FShells.Tick(Decks, Still);
    if Length(Cue.Bursts) = 0 then
      Continue;
    Assert.AreEqual(Double(AimX), Double(Cue.Bursts[0].At.X), Near,
      'Where it was aimed, carried by nothing');
    Exit;
  end;
  Assert.Fail('No burst');
end;

procedure TShellsAloftTests.TestWithNoRoadItFallsPastTheBottom;
begin
  FShells.Lob(At(MortarX, MortarY), At(200, RoadY), Carrier, AloftRise);
  FShells.Tick(NoDecks, Still);
  Assert.IsFalse(FShells[0].Marked, 'No ring over the abyss');
  var Lowest: Single := 0;
  for var i := 1 to ManyTicks do
  begin
    var Cue := FShells.Tick(NoDecks, Still);
    Assert.IsFalse(Cue.Landed, 'No road to land on');
    Assert.AreEqual(0, Integer(Length(Cue.Bursts)), 'Nothing to burst on');
    if FShells.Active = 0 then
      Break;
    Lowest := Max(Lowest, FShells[0].Middle.Y);
  end;
  Assert.AreEqual(0, FShells.Active, 'Gone');
  Assert.IsTrue(Lowest > ScreenHeight, Format('Past the bottom: %g', [Lowest]));
end;

procedure TShellsAloftTests.TestWithNoRoadTheRingLiesOnlyOnADeck;
begin
  var Decks: TArray<TShellDeck> := [Deck(BargeLeft, BargeWidth, BargeTop)];
  FShells.Lob(At(MortarX, MortarY), At(BargeLeft + 40, BargeTop), Carrier,
    AloftRise);
  FShells.Tick(Decks, Still);
  Assert.IsTrue(FShells[0].Marked, 'A ring');
  Assert.IsTrue(FShells[0].RingOnDeck, 'On the deck');
  FShells.Tick(NoDecks, Still);
  Assert.IsFalse(FShells[0].Marked, 'None once the deck is gone');
end;

procedure TShellsAloftTests.TestTheRingIsDrawnBetweenTicksAsItsDeckFlies;
const
  WayX = -2.0;
begin
  var Decks: TArray<TShellDeck> := [Deck(BargeLeft, BargeWidth, BargeTop)];
  FShells.Lob(At(MortarX, MortarY), At(BargeLeft + 40, BargeTop), Carrier,
    AloftRise);
  for var i := 1 to 5 do
  begin
    Fly(Decks[0], WayX, 0, Carrier);
    FShells.Tick(Decks, Still);
  end;
  var Shell := FShells[0];
  Assert.AreEqual(Double(WayX), Double(Shell.Ring.X - Shell.LastRing.X), 0.1,
    'The ring went its deck''s way this tick');
end;

function TShellsAloftTests.HighestOf(AFromY, ARise: Single): Single;
begin
  FShells.Clear;
  FShells.Lob(At(MortarX, AFromY), At(BargeLeft + 40, BargeTop), Carrier, ARise);
  Result := AFromY;
  for var i := 1 to ManyTicks do
  begin
    FShells.Tick(NoDecks, Still);
    if FShells.Active = 0 then
      Break;
    Result := Min(Result, FShells[0].Middle.Y);
  end;
end;

procedure TShellsAloftTests.TestALowerArcOfItsOwn;
const
  FromY = 100.0;
begin
  var Low := HighestOf(FromY, 10);
  var High := HighestOf(FromY, LobRise);
  Assert.IsTrue(Low > High + 15, Format('A rise of 10 tops at %g, of %g at %g',
    [Low, Double(LobRise), High]));
end;

// ---------------------------------------------------------------------------
// The second shell's mark
// ---------------------------------------------------------------------------

const
  // The chase's low and middle decks, a plain jump's step apart
  LowDeckTop = 280.0;
  MiddleDeckTop = 200.0;
  PadWidth = 64.0;
  FeetX = 100.0;
  // A pad still on the right half of the screen
  RightHalfLeft = 300.0;
  // The road ahead of him when no pad will do
  AheadX = 164.0;

procedure TSecondShellMarkTests.TestThePadHeStandsOn;
begin
  var Mark := SecondShellMark([Deck(FeetX + 40, PadWidth, DeckTop),
    Deck(RightHalfLeft, PadWidth, MiddleDeckTop)],
    At(RightHalfLeft + 10, MiddleDeckTop), RoadY);
  Assert.AreEqual(RightHalfLeft + PadWidth / 2, Double(Mark.X), 0.001,
    'His own, on the right half too');
  Assert.AreEqual(MiddleDeckTop, Double(Mark.Y), 0.001, 'On its deck');
end;

procedure TSecondShellMarkTests.TestTheNearestPadPastTheMiddleAJumpUp;
begin
  var Mark := SecondShellMark([Deck(190, PadWidth, LowDeckTop),
    Deck(150, PadWidth, LowDeckTop)], At(FeetX, RoadY), RoadY);
  Assert.AreEqual(150 + PadWidth / 2, Double(Mark.X), 0.001, 'The nearer one');
  Assert.AreEqual(LowDeckTop, Double(Mark.Y), 0.001, 'On its deck');
end;

procedure TSecondShellMarkTests.TestNotAPadStillOnTheRightHalf;
begin
  var Mark := SecondShellMark([Deck(RightHalfLeft, PadWidth, LowDeckTop)],
    At(FeetX, RoadY), RoadY);
  Assert.AreEqual(AheadX, Double(Mark.X), 0.001, 'Let in: the road ahead');
  Assert.AreEqual(RoadY, Double(Mark.Y), 0.001, 'On the road');
end;

procedure TSecondShellMarkTests.TestNotOneTooHigh;
begin
  var Mark := SecondShellMark([Deck(150, PadWidth, DeckTop)],
    At(FeetX, RoadY), RoadY);
  Assert.AreEqual(AheadX, Double(Mark.X), 0.001,
    'Out of a jump''s reach: the road ahead');
end;

procedure TSecondShellMarkTests.TestNoneTheRoadAheadNeverPastTheEdge;
begin
  var Mark := SecondShellMark(NoDecks, At(FeetX, RoadY), RoadY);
  Assert.AreEqual(AheadX, Double(Mark.X), 0.001, 'Ahead of him');
  Assert.AreEqual(RoadY, Double(Mark.Y), 0.001, 'On the road');
  Mark := SecondShellMark(NoDecks, At(ScreenWidth - 10, RoadY), RoadY);
  var RightEdge: Double := ScreenWidth;
  Assert.AreEqual(RightEdge, Double(Mark.X), 0.001, 'Never past the right edge');
end;

procedure TAheadShellMarkTests.TestTheNearestPadAheadAlongHisRow;
begin
  var Mark := AheadShellMark([Deck(FeetX - 20, PadWidth, DeckTop),
    Deck(FeetX + 140, PadWidth, DeckTop), Deck(FeetX + 60, PadWidth, DeckTop)],
    At(FeetX, DeckTop), RoadY);
  Assert.AreEqual(FeetX + 60 + PadWidth / 2, Double(Mark.X), 0.001,
    'The nearer one ahead');
  Assert.AreEqual(DeckTop, Double(Mark.Y), 0.001, 'On his row');
end;

procedure TAheadShellMarkTests.TestNotUnderHimBehindHimNorOnAnotherRow;
begin
  var Mark := AheadShellMark([Deck(FeetX - 20, PadWidth, DeckTop),
    Deck(FeetX - 90, PadWidth, DeckTop), Deck(FeetX + 40, PadWidth, MiddleDeckTop)],
    At(FeetX, DeckTop), RoadY);
  Assert.AreEqual(AheadX, Double(Mark.X), 0.001, 'The road ahead');
  Assert.AreEqual(RoadY, Double(Mark.Y), 0.001, 'On the road');
end;

procedure TAheadShellMarkTests.TestNoneTheRoadAhead;
begin
  var Mark := AheadShellMark(NoDecks, At(FeetX, RoadY), RoadY);
  Assert.AreEqual(AheadX, Double(Mark.X), 0.001, 'Ahead of him');
  Assert.AreEqual(RoadY, Double(Mark.Y), 0.001, 'On the road');
end;

initialization
  TDUnitX.RegisterTestFixture(TBunkerShellTests);
  TDUnitX.RegisterTestFixture(TShellsAloftTests);
  TDUnitX.RegisterTestFixture(TSecondShellMarkTests);
  TDUnitX.RegisterTestFixture(TAheadShellMarkTests);

end.
