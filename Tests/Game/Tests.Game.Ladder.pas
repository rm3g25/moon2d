{
  Tests.Game.Ladder - the ladder of the air fight: the rung follows the
  share of the hull's lives spent, and the finisher's stretch closes the
  last. No turn on the first rung; on the second the mortar every time; on
  the third the charge first, then the two by turns; on the last the dive
  first, then any of the three, never the same twice in a row, each of
  them now and then; on the finisher's stretch the finisher first, then
  among the rest. Chains come only on the last rung once the dive has
  been seen, not on the finisher's stretch before the finisher, now and
  then but not always, no shield in a lift, and a chain counts as its
  weapon's turn. A clear forgets what was seen. The door of point C is on
  its rung; the mortar's shells go by the rung.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Game.Ladder;

interface

uses
  DUnitX.TestFramework,
  Game.Ladder;

type
  TAirChains = set of TAirChain;

  [TestFixture]
  TAirLadderTests = class
  private
    FLadder: TAirLadder;
    // Turns asked one after another at ASpent, as many as ACount
    function TurnsAt(ASpent: Single; ACount: Integer): TArray<TAirTurn>;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestTheRungFollowsTheSpentLives;
    [Test]
    procedure TestTheFinishersStretchClosesTheLastRung;
    [Test]
    procedure TestOnTheFirstRungNoTurn;
    [Test]
    procedure TestOnTheSecondRungTheMortarEveryTime;
    [Test]
    procedure TestOnTheThirdRungTheChargeFirstThenByTurns;
    [Test]
    procedure TestOnTheLastRungTheDiveFirstThenNeverTwiceInARow;
    [Test]
    procedure TestOnTheLastRungEachWeaponComesNowAndThen;
    [Test]
    procedure TestOnItsStretchTheFinisherFirstThenAmongTheRest;
    [Test]
    procedure TestNoChainBeforeTheLastRung;
    [Test]
    procedure TestNoChainBeforeTheDiveIsSeen;
    [Test]
    procedure TestOnTheLastRungChainsComeNowAndThen;
    [Test]
    procedure TestNoShieldChainInALift;
    [Test]
    procedure TestAChainCountsAsItsWeaponsTurn;
    [Test]
    procedure TestNoChainOnTheStretchTillTheFinisherIsSeen;
    [Test]
    procedure TestAClearForgetsWhatWasSeen;
    [Test]
    procedure TestTheDoorOfPointCIsOnItsRung;
    [Test]
    procedure TestTheMortarsShellsGoByTheRung;
  end;

implementation

uses
  System.SysUtils;

const
  Seed = 7;
  // Enough tries for a chance of a half or a third to show both ways
  Tries = 200;
  SecondRung = 0.2;
  ThirdRung = 0.45;
  LastRung = 0.7;
  Stretch = 0.9;

procedure TAirLadderTests.Setup;
begin
  FLadder := TAirLadder.Create(Seed);
end;

procedure TAirLadderTests.TearDown;
begin
  FLadder.Free;
end;

function TAirLadderTests.TurnsAt(ASpent: Single; ACount: Integer): TArray<TAirTurn>;
begin
  SetLength(Result, ACount);
  for var i := 0 to ACount - 1 do
    Result[i] := FLadder.NextTurn(ASpent);
end;

procedure TAirLadderTests.TestTheRungFollowsTheSpentLives;
begin
  Assert.AreEqual(1, AirTierOf(0), 'Untouched');
  for var Tier: Integer := Low(AirTierSpent) to High(AirTierSpent) do
  begin
    var Door: Single := AirTierSpent[Tier];
    Assert.AreEqual(Tier - 1, AirTierOf(Door - 0.01), Format('Short of %d', [Tier]));
    Assert.AreEqual(Tier, AirTierOf(Door), Format('At the door of %d', [Tier]));
  end;
  Assert.AreEqual(AirTopTier, AirTierOf(1), 'All spent');
end;

procedure TAirLadderTests.TestTheFinishersStretchClosesTheLastRung;
begin
  Assert.IsFalse(OnFinisherStretch(FinisherSpent - 0.01), 'Short of it');
  Assert.IsTrue(OnFinisherStretch(FinisherSpent), 'At its door');
  Assert.AreEqual(AirTopTier, AirTierOf(FinisherSpent), 'On the last rung');
end;

procedure TAirLadderTests.TestOnTheFirstRungNoTurn;
begin
  for var Turn in TurnsAt(0.1, 5) do
    Assert.AreEqual<TAirTurn>(atNone, Turn, 'None');
end;

procedure TAirLadderTests.TestOnTheSecondRungTheMortarEveryTime;
begin
  for var Turn in TurnsAt(SecondRung, 5) do
    Assert.AreEqual<TAirTurn>(atMortar, Turn, 'The mortar');
end;

procedure TAirLadderTests.TestOnTheThirdRungTheChargeFirstThenByTurns;
begin
  var Turns := TurnsAt(ThirdRung, 6);
  Assert.AreEqual<TAirTurn>(atCharge, Turns[0], 'The charge first');
  for var i := 1 to High(Turns) do
  begin
    Assert.IsTrue(Turns[i] in [atMortar, atCharge], 'One of the two');
    Assert.AreNotEqual<TAirTurn>(Turns[i - 1], Turns[i], Format('Turn %d by turns', [i]));
  end;
end;

procedure TAirLadderTests.TestOnTheLastRungTheDiveFirstThenNeverTwiceInARow;
begin
  var Turns := TurnsAt(LastRung, Tries);
  Assert.AreEqual<TAirTurn>(atDive, Turns[0], 'The dive first');
  for var i := 1 to High(Turns) do
  begin
    Assert.IsTrue(Turns[i] in [atMortar, atCharge, atDive], 'One of the three');
    Assert.AreNotEqual<TAirTurn>(Turns[i - 1], Turns[i], Format('Turn %d', [i]));
  end;
end;

procedure TAirLadderTests.TestOnTheLastRungEachWeaponComesNowAndThen;
begin
  var Seen: TAirTurns := [];
  for var Turn in TurnsAt(LastRung, Tries) do
    Include(Seen, Turn);
  Assert.IsTrue(Seen = [atMortar, atCharge, atDive], 'All three came');
end;

procedure TAirLadderTests.TestOnItsStretchTheFinisherFirstThenAmongTheRest;
begin
  FLadder.NextTurn(LastRung);
  var Turns := TurnsAt(Stretch, Tries);
  Assert.AreEqual<TAirTurn>(atFinisher, Turns[0], 'The finisher first');
  var Seen: TAirTurns := [];
  for var i := 1 to High(Turns) do
  begin
    Include(Seen, Turns[i]);
    Assert.AreNotEqual<TAirTurn>(Turns[i - 1], Turns[i], Format('Turn %d', [i]));
  end;
  Assert.IsTrue(Seen = [atMortar, atCharge, atDive, atFinisher], 'All four came');
end;

procedure TAirLadderTests.TestNoChainBeforeTheLastRung;
const
  Spents: array [0..2] of Single = (0, SecondRung, ThirdRung);
begin
  for var Spent in Spents do
  begin
    FLadder.NextTurn(Spent);
    for var i := 1 to Tries do
      Assert.AreEqual<TAirChain>(acNone, FLadder.ChainAt(Spent, False),
        Format('At %g spent', [Spent]));
  end;
end;

procedure TAirLadderTests.TestNoChainBeforeTheDiveIsSeen;
begin
  for var i := 1 to Tries do
    Assert.AreEqual<TAirChain>(acNone, FLadder.ChainAt(LastRung, False),
      'The dive not seen alone yet');
end;

procedure TAirLadderTests.TestOnTheLastRungChainsComeNowAndThen;
begin
  FLadder.NextTurn(LastRung);
  var Chains := 0;
  var Seen: TAirChains := [];
  for var i := 1 to Tries do
  begin
    var Chain := FLadder.ChainAt(LastRung, False);
    Include(Seen, Chain);
    if Chain <> acNone then
      Inc(Chains);
  end;
  Assert.IsTrue((Chains > Tries div 5) and (Chains < Tries - Tries div 5),
    Format('Now and then: %d of %d', [Chains, Tries]));
  Assert.IsTrue(acThrowDive in Seen, 'The throw and the dive');
  Assert.IsTrue(acShieldShells in Seen, 'The shield and the shells');
end;

procedure TAirLadderTests.TestNoShieldChainInALift;
begin
  FLadder.NextTurn(LastRung);
  for var i := 1 to Tries do
    Assert.AreNotEqual<TAirChain>(acShieldShells, FLadder.ChainAt(LastRung, True),
      'No shells in a lift');
end;

procedure TAirLadderTests.TestAChainCountsAsItsWeaponsTurn;
begin
  FLadder.NextTurn(LastRung);
  var Chained := 0;
  for var i := 1 to Tries do
  begin
    var Chain := FLadder.ChainAt(LastRung, False);
    if Chain = acNone then
      Continue;
    Inc(Chained);
    var Weapon := atMortar;
    if Chain = acThrowDive then
      Weapon := atDive;
    Assert.AreEqual<TAirTurn>(Weapon, FLadder.LastTurn, 'Its weapon''s turn');
    Assert.AreNotEqual<TAirTurn>(Weapon, FLadder.NextTurn(LastRung),
      'Not that weapon right after it');
  end;
  Assert.IsTrue(Chained > 0, 'Some chained');
end;

procedure TAirLadderTests.TestNoChainOnTheStretchTillTheFinisherIsSeen;
begin
  FLadder.NextTurn(LastRung);
  for var i := 1 to Tries do
    Assert.AreEqual<TAirChain>(acNone, FLadder.ChainAt(Stretch, False),
      'The finisher not seen yet');
  Assert.AreEqual<TAirTurn>(atFinisher, FLadder.NextTurn(Stretch), 'The finisher');
  var Chains := 0;
  for var i := 1 to Tries do
    if FLadder.ChainAt(Stretch, False) <> acNone then
      Inc(Chains);
  Assert.IsTrue(Chains > 0, 'Chains after it');
end;

procedure TAirLadderTests.TestAClearForgetsWhatWasSeen;
begin
  TurnsAt(LastRung, 5);
  FLadder.Clear;
  Assert.AreEqual<TAirTurn>(atNone, FLadder.LastTurn, 'No last turn');
  Assert.AreEqual<TAirTurn>(atDive, FLadder.NextTurn(LastRung), 'The dive first again');
end;

procedure TAirLadderTests.TestTheDoorOfPointCIsOnItsRung;
const
  Fulls: array [0..4] of Integer = (50, 240, 300, 360, 361);
begin
  for var Full in Fulls do
  begin
    var Lives := AirDoorLives(Full);
    var Spent: Single := 1 - Lives / Full;
    Assert.AreEqual(AirDoorTier, AirTierOf(Spent), Format('On its rung, of %d', [Full]));
    var OneMore: Single := 1 - (Lives + 1) / Full;
    Assert.IsTrue(AirTierOf(OneMore) < AirDoorTier,
      Format('A life more is the rung below, of %d', [Full]));
  end;
end;

procedure TAirLadderTests.TestTheMortarsShellsGoByTheRung;
begin
  Assert.AreEqual(2, MortarShells[BombsFromTier], 'Two where it is learned');
  Assert.AreEqual(1, MortarShells[ChargeFromTier], 'One where it is mixed');
  Assert.AreEqual(1, MortarShells[DiveFromTier], 'One on the last rung');
end;

initialization
  TDUnitX.RegisterTestFixture(TAirLadderTests);

end.
