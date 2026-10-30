{
  Tests.Game.HeroOrbs - the hero's orbs at their border: what they call
  up for the living and refuse the dead, the charge a new level, a new
  screen, a death and a restart leave, the charge that rises with no orb
  to carry it, and what its orbs and its burst strike through the targets
  the game hands in.

  The hero is a point in a walled room, his body has no points, and the
  targets are the fixture's: a bullet or a monster stands everywhere or
  nowhere, and the fixture counts what it is asked. The orbs themselves -
  how they fly, when they arm - are the Orbs.* tests'.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Game.HeroOrbs;

interface

uses
  DUnitX.TestFramework, Monsters, Tests.Rooms, Game.HeroOrbs;

type
  [TestFixture]
  THeroOrbsTests = class
  private
    FOrbs: THeroOrbs;
    FRoom: TRoom;
    FMonster: TMonster;
    FAlive: Boolean;
    FBulletsEverywhere: Boolean;
    FMonsterEverywhere: Boolean;
    FPops: Integer;
    FMonstersAsked: Integer;
    FWounds: Integer;
    procedure Run(ACount: Integer);
    // Asked of a Strike with nothing anywhere: no orb is spent
    function ArmedOrbs: Integer;
    // Ticks until an armed orb is out; past the limit the test fails
    procedure RunUntilArmed;
    // Ticks until nothing of the charge is on its way
    procedure RunUntilFed;
    // Ticks with a strike after each, until the burst is over
    procedure RunBurstOut;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestCorpseCallsUpNoOrbs;
    [Test]
    procedure TestCastAuraTellsWhetherItCast;
    [Test]
    procedure TestCorpseIsFedNothing;
    [Test]
    procedure TestFeedLandsAsEnergy;
    [Test]
    procedure TestFeedStopsAtFullCountingOrbsOnTheirWay;
    [Test]
    procedure TestChargeRisesAtOnce;
    [Test]
    procedure TestChargeStopsAtFullCountingOrbsOnTheirWay;
    [Test]
    procedure TestCorpseIsChargedNothing;
    [Test]
    procedure TestRewindGivesBackChargeOfEntry;
    [Test]
    procedure TestArriveKeepsOrbsOnTheirWayForTheRewind;
    [Test]
    procedure TestBeginLevelZeroesCharge;
    [Test]
    procedure TestFallTakesOrbsOnTheirWayAndKeepsCharge;
    [Test]
    procedure TestFallLeavesNoArmedOrb;
    [Test]
    procedure TestRewindLeavesNoOrb;
    [Test]
    procedure TestArriveClearsRain;
    [Test]
    procedure TestArriveKeepsAura;
    [Test]
    procedure TestTakesAtSpendsArmedOrbInReach;
    [Test]
    procedure TestTakesAtLeavesOrbOutOfReach;
    [Test]
    procedure TestOrbSpentOnBulletWoundsNothing;
    [Test]
    procedure TestOrbOnMonsterWoundsIt;
    [Test]
    procedure TestBurstHoldsTheWorldThroughItsInhale;
    [Test]
    procedure TestBurstWoundsMonsterOncePerBurst;
    [Test]
    procedure TestNextBurstWoundsAgain;
  end;

implementation

uses
  System.SysUtils, Sdl2.Core, Game.Space, Hud.Energy, Orbs.Harvest,
  Orbs.Patterns, Orbs.Rite, Orbs.Burst, Tests.Matter;

const
  // Longer than any orb takes to come out of matter or to arm
  ArmLimit = 300;
  // Two feeds joined, every orb out, risen, hung its longest and flown,
  // with room
  LongestFeed = 800;
  // The inhale, the flight of the rays to the walls, and room
  LongestBurst = 300;
  HeroX = 256;
  HeroY = 200;

procedure THeroOrbsTests.Setup;
var
  Probes: TOrbProbes;
  Targets: TOrbTargets;
begin
  // One fixture runs every test: what the last one left must not count
  FAlive := True;
  FBulletsEverywhere := False;
  FMonsterEverywhere := False;
  FPops := 0;
  FMonstersAsked := 0;
  FWounds := 0;
  FRoom := RoomFromRows(RoomRowsOf(0, 0, 0, 0));
  FMonster := FRoom.Place('gravel', 8, 11);
  Probes.Alive :=
    function: Boolean
    begin
      Result := FAlive;
    end;
  Probes.Center :=
    function: TSdlFPoint
    begin
      Result.X := HeroX;
      Result.Y := HeroY;
    end;
  Probes.Body :=
    function: TBodyPoints
    begin
      Result := nil;
    end;
  Probes.Matter :=
    function: TMatter
    begin
      Result := WalledMatter;
    end;
  Targets.PopBullet :=
    function(AX, AY: Single): Boolean
    begin
      Result := FBulletsEverywhere;
      if Result then
        Inc(FPops);
    end;
  Targets.MonsterAt :=
    function(AX, AY: Single): TMonster
    begin
      Inc(FMonstersAsked);
      Result := nil;
      if FMonsterEverywhere then
        Result := FMonster;
    end;
  Targets.Wound :=
    procedure(const AMonster: TMonster)
    begin
      Inc(FWounds);
    end;
  FOrbs := THeroOrbs.Create(Probes, Targets);
  FOrbs.BeginLevel(FindPattern(DefaultPatternName));
end;

procedure THeroOrbsTests.TearDown;
begin
  FreeAndNil(FOrbs);
  FreeAndNil(FRoom);
end;

procedure THeroOrbsTests.Run(ACount: Integer);
begin
  for var i := 1 to ACount do
  begin
    FOrbs.Tick;
    FOrbs.TickAfterCeremony;
  end;
end;

function THeroOrbsTests.ArmedOrbs: Integer;
begin
  var Bullets := FBulletsEverywhere;
  var Monster := FMonsterEverywhere;
  FBulletsEverywhere := False;
  FMonsterEverywhere := False;
  FMonstersAsked := 0;
  FOrbs.Strike;
  Result := FMonstersAsked;
  FBulletsEverywhere := Bullets;
  FMonsterEverywhere := Monster;
end;

procedure THeroOrbsTests.RunUntilArmed;
begin
  for var i := 1 to ArmLimit do
  begin
    Run(1);
    if ArmedOrbs > 0 then
      Exit;
  end;
  Assert.Fail(Format('No armed orb after %d ticks', [ArmLimit]));
end;

procedure THeroOrbsTests.RunUntilFed;
begin
  Run(LongestFeed);
end;

procedure THeroOrbsTests.RunBurstOut;
begin
  for var i := 1 to LongestBurst do
  begin
    Run(1);
    FOrbs.Strike;
  end;
end;

procedure THeroOrbsTests.TestCorpseCallsUpNoOrbs;
begin
  FAlive := False;
  Assert.IsFalse(FOrbs.CastAura, 'No aura cast');
  FOrbs.PourRain;
  FOrbs.BeginRite;
  FOrbs.ShedSuit;
  FOrbs.StartBurst(IceBurstLook);
  Assert.IsFalse(FOrbs.Holding, 'No burst holds the world');
  Run(ArmLimit);
  Assert.AreEqual(0, ArmedOrbs, 'No armed orb');
  Assert.AreEqual(0, FOrbs.Rite.Flock.Orbs.Count, 'No orb of the rite');
end;

procedure THeroOrbsTests.TestCastAuraTellsWhetherItCast;
begin
  Assert.IsTrue(FOrbs.CastAura, 'Cast for the living');
  RunUntilArmed;
end;

procedure THeroOrbsTests.TestCorpseIsFedNothing;
begin
  FAlive := False;
  FOrbs.FeedEnergy(10);
  RunUntilFed;
  Assert.AreEqual(0, FOrbs.Energy);
end;

procedure THeroOrbsTests.TestFeedLandsAsEnergy;
begin
  FOrbs.FeedEnergy(10);
  Assert.AreEqual(0, FOrbs.Energy, 'Nothing before it flies');
  RunUntilFed;
  Assert.AreEqual(10, FOrbs.Energy);
end;

procedure THeroOrbsTests.TestFeedStopsAtFullCountingOrbsOnTheirWay;
begin
  FOrbs.FeedEnergy(FullEnergy - 20);
  FOrbs.FeedEnergy(50);
  RunUntilFed;
  Assert.AreEqual(FullEnergy, FOrbs.Energy);
end;

procedure THeroOrbsTests.TestChargeRisesAtOnce;
begin
  FOrbs.Charge(2);
  Assert.AreEqual(2, FOrbs.Energy, 'No orb carries it');
end;

procedure THeroOrbsTests.TestChargeStopsAtFullCountingOrbsOnTheirWay;
begin
  FOrbs.FeedEnergy(FullEnergy - 10);
  FOrbs.Charge(25);
  Assert.AreEqual(10, FOrbs.Energy, 'Up to what the orbs leave room for');
  RunUntilFed;
  Assert.AreEqual(FullEnergy, FOrbs.Energy, 'Full, never past it');
end;

procedure THeroOrbsTests.TestCorpseIsChargedNothing;
begin
  FAlive := False;
  FOrbs.Charge(5);
  Assert.AreEqual(0, FOrbs.Energy);
end;

procedure THeroOrbsTests.TestRewindGivesBackChargeOfEntry;
begin
  FOrbs.FeedEnergy(10);
  RunUntilFed;
  FOrbs.Arrive;
  FOrbs.FeedEnergy(20);
  RunUntilFed;
  Assert.AreEqual(30, FOrbs.Energy, 'The screen gave its share');
  FOrbs.Rewind;
  Assert.AreEqual(10, FOrbs.Energy, 'A death takes it back');
end;

procedure THeroOrbsTests.TestArriveKeepsOrbsOnTheirWayForTheRewind;
begin
  FOrbs.FeedEnergy(10);
  Run(1);
  Assert.AreEqual(0, FOrbs.Energy, 'Still on its way');
  FOrbs.Arrive;
  FOrbs.Rewind;
  Assert.AreEqual(10, FOrbs.Energy);
end;

procedure THeroOrbsTests.TestBeginLevelZeroesCharge;
begin
  FOrbs.FeedEnergy(10);
  RunUntilFed;
  FOrbs.Arrive;
  FOrbs.BeginLevel(FindPattern(DefaultPatternName));
  Assert.AreEqual(0, FOrbs.Energy, 'No charge');
  FOrbs.Rewind;
  Assert.AreEqual(0, FOrbs.Energy, 'No charge of entry either');
end;

procedure THeroOrbsTests.TestFallTakesOrbsOnTheirWayAndKeepsCharge;
begin
  FOrbs.FeedEnergy(10);
  RunUntilFed;
  FOrbs.FeedEnergy(20);
  Run(1);
  FOrbs.Fall;
  RunUntilFed;
  Assert.AreEqual(10, FOrbs.Energy);
end;

procedure THeroOrbsTests.TestFallLeavesNoArmedOrb;
begin
  FOrbs.CastAura;
  FOrbs.PourRain;
  RunUntilArmed;
  FOrbs.Fall;
  Assert.AreEqual(0, ArmedOrbs);
end;

procedure THeroOrbsTests.TestRewindLeavesNoOrb;
begin
  FOrbs.CastAura;
  FOrbs.PourRain;
  FOrbs.BeginRite;
  RunUntilArmed;
  FOrbs.Rewind;
  Assert.AreEqual(0, ArmedOrbs, 'No armed orb');
  Assert.AreEqual(0, FOrbs.Rite.Flock.Orbs.Count, 'No orb of the rite');
  Run(ArmLimit);
  Assert.AreEqual(0, ArmedOrbs, 'Nothing left to be born');
end;

procedure THeroOrbsTests.TestArriveClearsRain;
begin
  FOrbs.PourRain;
  RunUntilArmed;
  FOrbs.Arrive;
  Assert.AreEqual(0, ArmedOrbs, 'No drop');
  Run(ArmLimit);
  Assert.AreEqual(0, ArmedOrbs, 'None left to be born');
end;

procedure THeroOrbsTests.TestArriveKeepsAura;
begin
  FOrbs.CastAura;
  RunUntilArmed;
  var Before := ArmedOrbs;
  FOrbs.Arrive;
  Assert.AreEqual(Before, ArmedOrbs);
end;

procedure THeroOrbsTests.TestTakesAtSpendsArmedOrbInReach;
begin
  FOrbs.CastAura;
  RunUntilArmed;
  var Before := ArmedOrbs;
  var Taken := False;
  var Y := -OrbReach;
  while not Taken and (Y < ScreenHeight + OrbReach) do
  begin
    Taken := FOrbs.TakesAt(0, ScreenWidth, Y);
    Inc(Y, OrbReach);
  end;
  Assert.IsTrue(Taken, 'An orb took it');
  Assert.AreEqual(Before - 1, ArmedOrbs, 'That one is spent');
end;

procedure THeroOrbsTests.TestTakesAtLeavesOrbOutOfReach;
begin
  FOrbs.CastAura;
  RunUntilArmed;
  var Before := ArmedOrbs;
  Assert.IsFalse(FOrbs.TakesAt(0, ScreenWidth, -10 * ScreenHeight));
  Assert.AreEqual(Before, ArmedOrbs);
end;

procedure THeroOrbsTests.TestOrbSpentOnBulletWoundsNothing;
begin
  FOrbs.CastAura;
  RunUntilArmed;
  var Armed := ArmedOrbs;
  FBulletsEverywhere := True;
  FMonsterEverywhere := True;
  FOrbs.Strike;
  Assert.AreEqual(Armed, FPops, 'Every armed orb took a bullet');
  Assert.AreEqual(0, FWounds, 'None went on to the monster');
  Assert.AreEqual(0, ArmedOrbs, 'Every one is spent');
end;

procedure THeroOrbsTests.TestOrbOnMonsterWoundsIt;
begin
  FOrbs.CastAura;
  RunUntilArmed;
  var Armed := ArmedOrbs;
  FMonsterEverywhere := True;
  FOrbs.Strike;
  Assert.AreEqual(Armed, FWounds, 'A wound an orb');
  Assert.AreEqual(0, ArmedOrbs, 'Every one is spent');
end;

procedure THeroOrbsTests.TestBurstHoldsTheWorldThroughItsInhale;
begin
  FOrbs.StartBurst(IceBurstLook);
  Assert.IsTrue(FOrbs.Holding, 'The world stands');
  Assert.IsTrue(FOrbs.Inhaling, 'The hero is a bare figure');
  RunBurstOut;
  Assert.IsFalse(FOrbs.Holding, 'The world goes on');
end;

procedure THeroOrbsTests.TestBurstWoundsMonsterOncePerBurst;
begin
  FMonsterEverywhere := True;
  FOrbs.StartBurst(IceBurstLook);
  RunBurstOut;
  Assert.AreEqual(1, FWounds);
end;

procedure THeroOrbsTests.TestNextBurstWoundsAgain;
begin
  FMonsterEverywhere := True;
  FOrbs.StartBurst(IceBurstLook);
  RunBurstOut;
  FOrbs.StartBurst(IceBurstLook);
  RunBurstOut;
  Assert.AreEqual(2, FWounds);
end;

initialization
  TDUnitX.RegisterTestFixture(THeroOrbsTests);

end.
