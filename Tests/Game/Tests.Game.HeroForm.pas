{
  Tests.Game.HeroForm - the hero's form at its border: what it calls up
  for the living and refuses the dead, the charge a new level, a new
  screen, a death and a restart leave, and what its orbs and its burst
  strike through the targets the game hands in.

  The hero is a point in a walled room, his body has no points, and the
  targets are the fixture's: a bullet or a monster stands everywhere or
  nowhere, and the fixture counts what it is asked. The orbs themselves -
  how they fly, when they arm - are the Orbs.* tests'.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Game.HeroForm;

interface

uses
  DUnitX.TestFramework, Monsters, Tests.Rooms, Game.HeroForm;

type
  [TestFixture]
  THeroFormTests = class
  private
    FForm: THeroForm;
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

procedure THeroFormTests.Setup;
var
  Probes: TFormProbes;
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
  FForm := THeroForm.Create(Probes, Targets);
  FForm.BeginLevel(FindPattern(DefaultPatternName));
end;

procedure THeroFormTests.TearDown;
begin
  FreeAndNil(FForm);
  FreeAndNil(FRoom);
end;

procedure THeroFormTests.Run(ACount: Integer);
begin
  for var i := 1 to ACount do
  begin
    FForm.Tick;
    FForm.TickAfterCeremony;
  end;
end;

function THeroFormTests.ArmedOrbs: Integer;
begin
  var Bullets := FBulletsEverywhere;
  var Monster := FMonsterEverywhere;
  FBulletsEverywhere := False;
  FMonsterEverywhere := False;
  FMonstersAsked := 0;
  FForm.Strike;
  Result := FMonstersAsked;
  FBulletsEverywhere := Bullets;
  FMonsterEverywhere := Monster;
end;

procedure THeroFormTests.RunUntilArmed;
begin
  for var i := 1 to ArmLimit do
  begin
    Run(1);
    if ArmedOrbs > 0 then
      Exit;
  end;
  Assert.Fail(Format('No armed orb after %d ticks', [ArmLimit]));
end;

procedure THeroFormTests.RunUntilFed;
begin
  Run(LongestFeed);
end;

procedure THeroFormTests.RunBurstOut;
begin
  for var i := 1 to LongestBurst do
  begin
    Run(1);
    FForm.Strike;
  end;
end;

procedure THeroFormTests.TestCorpseCallsUpNoOrbs;
begin
  FAlive := False;
  Assert.IsFalse(FForm.CastAura, 'No aura cast');
  FForm.PourRain;
  FForm.BeginRite;
  FForm.ShedSuit;
  FForm.StartBurst(IceBurstLook);
  Assert.IsFalse(FForm.Holding, 'No burst holds the world');
  Run(ArmLimit);
  Assert.AreEqual(0, ArmedOrbs, 'No armed orb');
  Assert.AreEqual(0, FForm.Rite.Flock.Orbs.Count, 'No orb of the rite');
end;

procedure THeroFormTests.TestCastAuraTellsWhetherItCast;
begin
  Assert.IsTrue(FForm.CastAura, 'Cast for the living');
  RunUntilArmed;
end;

procedure THeroFormTests.TestCorpseIsFedNothing;
begin
  FAlive := False;
  FForm.FeedEnergy(10);
  RunUntilFed;
  Assert.AreEqual(0, FForm.Energy);
end;

procedure THeroFormTests.TestFeedLandsAsEnergy;
begin
  FForm.FeedEnergy(10);
  Assert.AreEqual(0, FForm.Energy, 'Nothing before it flies');
  RunUntilFed;
  Assert.AreEqual(10, FForm.Energy);
end;

procedure THeroFormTests.TestFeedStopsAtFullCountingOrbsOnTheirWay;
begin
  FForm.FeedEnergy(FullEnergy - 20);
  FForm.FeedEnergy(50);
  RunUntilFed;
  Assert.AreEqual(FullEnergy, FForm.Energy);
end;

procedure THeroFormTests.TestRewindGivesBackChargeOfEntry;
begin
  FForm.FeedEnergy(10);
  RunUntilFed;
  FForm.Arrive;
  FForm.FeedEnergy(20);
  RunUntilFed;
  Assert.AreEqual(30, FForm.Energy, 'The screen gave its share');
  FForm.Rewind;
  Assert.AreEqual(10, FForm.Energy, 'A death takes it back');
end;

procedure THeroFormTests.TestArriveKeepsOrbsOnTheirWayForTheRewind;
begin
  FForm.FeedEnergy(10);
  Run(1);
  Assert.AreEqual(0, FForm.Energy, 'Still on its way');
  FForm.Arrive;
  FForm.Rewind;
  Assert.AreEqual(10, FForm.Energy);
end;

procedure THeroFormTests.TestBeginLevelZeroesCharge;
begin
  FForm.FeedEnergy(10);
  RunUntilFed;
  FForm.Arrive;
  FForm.BeginLevel(FindPattern(DefaultPatternName));
  Assert.AreEqual(0, FForm.Energy, 'No charge');
  FForm.Rewind;
  Assert.AreEqual(0, FForm.Energy, 'No charge of entry either');
end;

procedure THeroFormTests.TestFallTakesOrbsOnTheirWayAndKeepsCharge;
begin
  FForm.FeedEnergy(10);
  RunUntilFed;
  FForm.FeedEnergy(20);
  Run(1);
  FForm.Fall;
  RunUntilFed;
  Assert.AreEqual(10, FForm.Energy);
end;

procedure THeroFormTests.TestFallLeavesNoArmedOrb;
begin
  FForm.CastAura;
  FForm.PourRain;
  RunUntilArmed;
  FForm.Fall;
  Assert.AreEqual(0, ArmedOrbs);
end;

procedure THeroFormTests.TestRewindLeavesNoOrb;
begin
  FForm.CastAura;
  FForm.PourRain;
  FForm.BeginRite;
  RunUntilArmed;
  FForm.Rewind;
  Assert.AreEqual(0, ArmedOrbs, 'No armed orb');
  Assert.AreEqual(0, FForm.Rite.Flock.Orbs.Count, 'No orb of the rite');
  Run(ArmLimit);
  Assert.AreEqual(0, ArmedOrbs, 'Nothing left to be born');
end;

procedure THeroFormTests.TestArriveClearsRain;
begin
  FForm.PourRain;
  RunUntilArmed;
  FForm.Arrive;
  Assert.AreEqual(0, ArmedOrbs, 'No drop');
  Run(ArmLimit);
  Assert.AreEqual(0, ArmedOrbs, 'None left to be born');
end;

procedure THeroFormTests.TestArriveKeepsAura;
begin
  FForm.CastAura;
  RunUntilArmed;
  var Before := ArmedOrbs;
  FForm.Arrive;
  Assert.AreEqual(Before, ArmedOrbs);
end;

procedure THeroFormTests.TestTakesAtSpendsArmedOrbInReach;
begin
  FForm.CastAura;
  RunUntilArmed;
  var Before := ArmedOrbs;
  var Taken := False;
  var Y := -OrbReach;
  while not Taken and (Y < ScreenHeight + OrbReach) do
  begin
    Taken := FForm.TakesAt(0, ScreenWidth, Y);
    Inc(Y, OrbReach);
  end;
  Assert.IsTrue(Taken, 'An orb took it');
  Assert.AreEqual(Before - 1, ArmedOrbs, 'That one is spent');
end;

procedure THeroFormTests.TestTakesAtLeavesOrbOutOfReach;
begin
  FForm.CastAura;
  RunUntilArmed;
  var Before := ArmedOrbs;
  Assert.IsFalse(FForm.TakesAt(0, ScreenWidth, -10 * ScreenHeight));
  Assert.AreEqual(Before, ArmedOrbs);
end;

procedure THeroFormTests.TestOrbSpentOnBulletWoundsNothing;
begin
  FForm.CastAura;
  RunUntilArmed;
  var Armed := ArmedOrbs;
  FBulletsEverywhere := True;
  FMonsterEverywhere := True;
  FForm.Strike;
  Assert.AreEqual(Armed, FPops, 'Every armed orb took a bullet');
  Assert.AreEqual(0, FWounds, 'None went on to the monster');
  Assert.AreEqual(0, ArmedOrbs, 'Every one is spent');
end;

procedure THeroFormTests.TestOrbOnMonsterWoundsIt;
begin
  FForm.CastAura;
  RunUntilArmed;
  var Armed := ArmedOrbs;
  FMonsterEverywhere := True;
  FForm.Strike;
  Assert.AreEqual(Armed, FWounds, 'A wound an orb');
  Assert.AreEqual(0, ArmedOrbs, 'Every one is spent');
end;

procedure THeroFormTests.TestBurstHoldsTheWorldThroughItsInhale;
begin
  FForm.StartBurst(IceBurstLook);
  Assert.IsTrue(FForm.Holding, 'The world stands');
  Assert.IsTrue(FForm.Inhaling, 'The hero is a bare figure');
  RunBurstOut;
  Assert.IsFalse(FForm.Holding, 'The world goes on');
end;

procedure THeroFormTests.TestBurstWoundsMonsterOncePerBurst;
begin
  FMonsterEverywhere := True;
  FForm.StartBurst(IceBurstLook);
  RunBurstOut;
  Assert.AreEqual(1, FWounds);
end;

procedure THeroFormTests.TestNextBurstWoundsAgain;
begin
  FMonsterEverywhere := True;
  FForm.StartBurst(IceBurstLook);
  RunBurstOut;
  FForm.StartBurst(IceBurstLook);
  RunBurstOut;
  Assert.AreEqual(2, FWounds);
end;

initialization
  TDUnitX.RegisterTestFixture(THeroFormTests);

end.
