{
  Tests.Game.Bonus - what a spent reward leaves of the score: the cost is
  taken; a score under the cost, as a reward carried into a level where
  nothing is earned yet has, drops to zero and no lower.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Game.Bonus;

interface

uses
  DUnitX.TestFramework,
  Game.Bonus;

type
  [TestFixture]
  TBonusTests = class
  public
    [Test]
    procedure TestSpendingTakesTheCost;
    [Test]
    procedure TestSpendingTheExactCostLeavesZero;
    [Test]
    procedure TestSpendingBelowTheCostStopsAtZero;
  end;

implementation

procedure TBonusTests.TestSpendingTakesTheCost;
begin
  Assert.AreEqual(30, ScoreAfterSpend(BonusCost + 30), 'Only the cost is taken');
end;

procedure TBonusTests.TestSpendingTheExactCostLeavesZero;
begin
  Assert.AreEqual(0, ScoreAfterSpend(BonusCost), 'Nothing left over');
end;

procedure TBonusTests.TestSpendingBelowTheCostStopsAtZero;
begin
  Assert.AreEqual(0, ScoreAfterSpend(0), 'A carried reward at a fresh score');
  Assert.AreEqual(0, ScoreAfterSpend(BonusCost - 1), 'One point short of the cost');
end;

initialization
  TDUnitX.RegisterTestFixture(TBonusTests);

end.
