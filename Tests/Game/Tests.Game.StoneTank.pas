{
  Tests.Game.StoneTank - the hidden tank between the Ram's heads and the
  gauge: nothing runs before the fight; a wound reaches the gauge only a
  while later, and in pulses of a percent or two at uneven gaps; the
  gauge never passes the ceiling of the head that lives - 30 while the
  hunter does, 55 after it; a head's death pours what is left up to its
  ceiling, and nothing of it spills into the next head's quarter; the
  trickle keeps the gauge alive with no hit; a clear stops it all.

  The gauge is a number here: each tick it takes what the tank gives.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Game.StoneTank;

interface

uses
  DUnitX.TestFramework,
  Game.StoneTank;

type
  [TestFixture]
  TStoneTankTests = class
  private
    FTank: TStoneTank;
    FEnergy: Integer;
    // The ticks the gauge rose on, over ATicks
    function Run(ATicks: Integer): TArray<Integer>;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestNothingBeforeTheFight;
    [Test]
    procedure TestAWoundReachesTheGaugeLate;
    [Test]
    procedure TestRisesInUnevenPulses;
    [Test]
    procedure TestNeverPastTheHuntersCeiling;
    [Test]
    procedure TestAHeadDownPoursUpToItsCeiling;
    [Test]
    procedure TestNothingSpillsIntoTheNextQuarter;
    [Test]
    procedure TestTheSecondHeadStopsAtItsCeiling;
    [Test]
    procedure TestTheTrickleKeepsItAlive;
    [Test]
    procedure TestClearStopsIt;
  end;

implementation

uses
  System.SysUtils;

const
  Seed = 7;
  // The charge the moon stone gives
  StoneCharge = 5;
  HunterCeiling = 30;
  SweeperCeiling = 55;
  TicksPerSecond = 33;
  // Long enough for any pour to come in whole
  ManyTicks = 1500;

procedure TStoneTankTests.Setup;
begin
  FTank := TStoneTank.Create(Seed);
  FEnergy := StoneCharge;
end;

procedure TStoneTankTests.TearDown;
begin
  FTank.Free;
end;

function TStoneTankTests.Run(ATicks: Integer): TArray<Integer>;
begin
  Result := [];
  for var i := 1 to ATicks do
  begin
    var Rise := FTank.Tick(FEnergy);
    Assert.IsTrue((Rise >= 0) and (Rise <= 2),
      Format('Tick %d: a pulse is a percent or two, not %d', [i, Rise]));
    if Rise > 0 then
      Result := Result + [i];
    Inc(FEnergy, Rise);
  end;
end;

procedure TStoneTankTests.TestNothingBeforeTheFight;
begin
  FTank.Wound(1);
  Run(ManyTicks);
  Assert.IsFalse(FTank.Running, 'Not started');
  Assert.AreEqual(StoneCharge, FEnergy, 'The gauge stands');
end;

procedure TStoneTankTests.TestAWoundReachesTheGaugeLate;
const
  // A pulse comes at least this often once there is something to drink
  WidestGap = 31;
begin
  FTank.Start;
  FTank.Wound(0.5);
  var Rises := Run(LateTicks - 1);
  Assert.AreEqual(0, Length(Rises), 'Nothing while the wound is on its way');
  Rises := Run(WidestGap);
  Assert.IsTrue(Length(Rises) > 0, 'Then it comes');
end;

procedure TStoneTankTests.TestRisesInUnevenPulses;
begin
  FTank.Start;
  FTank.Wound(1);
  var Rises := Run(ManyTicks);
  Assert.IsTrue(Length(Rises) >= 3, 'Several pulses');
  var Gaps: TArray<Integer> := [];
  for var i := 1 to High(Rises) do
    Gaps := Gaps + [Rises[i] - Rises[i - 1]];
  var AllAlike := True;
  for var Gap in Gaps do
    AllAlike := AllAlike and (Gap = Gaps[0]);
  Assert.IsFalse(AllAlike, 'No even beat to read a hit in');
end;

procedure TStoneTankTests.TestNeverPastTheHuntersCeiling;
begin
  FTank.Start;
  FTank.Wound(3);
  for var i := 1 to ManyTicks do
  begin
    Inc(FEnergy, FTank.Tick(FEnergy));
    Assert.IsTrue(FEnergy <= HunterCeiling,
      Format('Tick %d: %d past the hunter''s ceiling', [i, FEnergy]));
  end;
  Assert.AreEqual(HunterCeiling, FEnergy, 'Up to it');
end;

procedure TStoneTankTests.TestAHeadDownPoursUpToItsCeiling;
const
  // What the trickle may add over ManyTicks, and a percent of slack
  TrickleMost = 6;
begin
  FTank.Start;
  FEnergy := 10;
  FTank.HeadDown(FEnergy);
  Assert.AreEqual(SweeperCeiling, FTank.Ceiling, 'The sweeper''s ceiling now');
  var Rises := Run(LateTicks - 1);
  Assert.AreEqual(0, Length(Rises), 'Late, as any wound');
  Run(ManyTicks);
  Assert.IsTrue(FEnergy >= HunterCeiling, 'Poured up to the old ceiling');
  Assert.IsTrue(FEnergy <= HunterCeiling + TrickleMost,
    Format('And no more than the trickle past it: %d', [FEnergy]));
end;

procedure TStoneTankTests.TestNothingSpillsIntoTheNextQuarter;
const
  TrickleMost = 6;
begin
  FTank.Start;
  FEnergy := 28;
  FTank.Wound(1);
  FTank.HeadDown(FEnergy);
  Run(ManyTicks);
  Assert.IsTrue(FEnergy <= HunterCeiling + TrickleMost,
    Format('The hunter''s wound stays in its quarter: %d', [FEnergy]));
end;

procedure TStoneTankTests.TestTheSecondHeadStopsAtItsCeiling;
begin
  FTank.Start;
  FEnergy := HunterCeiling;
  FTank.HeadDown(FEnergy);
  FTank.Wound(3);
  for var i := 1 to 3 * ManyTicks do
  begin
    Inc(FEnergy, FTank.Tick(FEnergy));
    Assert.IsTrue(FEnergy <= SweeperCeiling,
      Format('Tick %d: %d past the sweeper''s ceiling', [i, FEnergy]));
  end;
  Assert.AreEqual(SweeperCeiling, FEnergy, 'Up to it');
end;

procedure TStoneTankTests.TestTheTrickleKeepsItAlive;
const
  Minute = 60 * TicksPerSecond;
  TrickleMost = 7;
begin
  FTank.Start;
  Run(Minute);
  Assert.IsTrue(FEnergy > StoneCharge, 'It rises with no hit');
  Assert.IsTrue(FEnergy <= StoneCharge + TrickleMost,
    Format('But slowly: %d in a minute', [FEnergy]));
end;

procedure TStoneTankTests.TestClearStopsIt;
begin
  FTank.Start;
  FTank.Wound(1);
  FTank.HeadDown(FEnergy);
  FTank.Clear;
  Assert.IsFalse(FTank.Running, 'Stopped');
  Assert.AreEqual(HunterCeiling, FTank.Ceiling, 'No head down');
  Run(ManyTicks);
  Assert.AreEqual(StoneCharge, FEnergy, 'Nothing on its way');
end;

initialization
  TDUnitX.RegisterTestFixture(TStoneTankTests);

end.
