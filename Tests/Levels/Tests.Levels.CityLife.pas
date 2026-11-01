{
  Tests.Levels.CityLife - the clock of the chase city's lights against the
  stand's own: the tables below are the stand's functions
  (tools/chase/stand.template.html) run under node over numbers of the
  tests' own - the shipped layout's of the day they were made - so tuning
  the layout breaks nothing here. Each table holds every tick a level
  changes on and the level there, and the sum of the levels over the run:
  a sign that stutters a tick early or late on either side fails it.

  The hash is the stand's to the bit; a roll stays in its range and reaches
  both ends. A sign breathes within its depth while no fault comes; a
  window is lit about its share of the time; the emblem is lit when the
  chase starts, and its frame catches before its small triangle; a beacon
  flashes for its flash ticks once a period. A node's place rounds half up,
  as the stand's does.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Levels.CityLife;

interface

uses
  DUnitX.TestFramework, Levels.FarPlane;

type
  [TestFixture]
  TCityLifeTests = class
  private
    FLights: TCityLights;
    FEmblem: TCityEmblem;
    FBeacons: TCityBeacons;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure TestMixMatchesTheStand;
    [Test]
    procedure TestRollMatchesTheStand;
    [Test]
    procedure TestRollIntReachesBothEndsAndNoFurther;
    [Test]
    procedure TestLightSeedMatchesTheStand;
    [Test]
    procedure TestNeonStuttersOnTheStandsTicks;
    [Test]
    procedure TestNeonBreathesWithinItsDepthWithoutFaults;
    [Test]
    procedure TestWindowWakesOnTheStandsTicks;
    [Test]
    procedure TestWindowsLitAboutTheirShare;
    [Test]
    procedure TestEmblemCyclesAsOnTheStand;
    [Test]
    procedure TestEmblemFrameLightsOnTheStandsTicks;
    [Test]
    procedure TestEmblemSmallTriangleLightsOnTheStandsTicks;
    [Test]
    procedure TestEmblemLitWhenTheChaseStarts;
    [Test]
    procedure TestEmblemFrameCatchesBeforeTheLastPart;
    [Test]
    procedure TestBeaconFlashesOnTheStandsTicks;
    [Test]
    procedure TestBeaconFlashesForItsFlashTicks;
    [Test]
    procedure TestBeaconSeedMatchesTheStand;
    [Test]
    procedure TestBeaconSeedRoundsHalfUpAsTheStand;
    [Test]
    procedure TestBeaconSeedIsThePlaceOnItsFrame;
  end;

implementation

uses
  System.SysUtils, Levels.CityLife;

type
  TTickLevel = record
    Tick: Integer;
    Level: Double;
  end;

const
  // A level changes by less than this from a tick to the next unless it
  // flips: a breath is slow
  FlipStep = 0.05;
  Slack = 1E-6;
  // The stand's sums over the same runs
  SumSlack = 1E-4;
  NeonSeedElement = 37;
  NeonSeedLight = 2;
  WindowSeedElement = 12;
  NeonTicks = 3000;
  WindowTicks = 20000;
  EmblemTicks = 3000;
  BeaconTicks = 300;
  NeonSum = 2802.237726866243;
  WindowSum = 5180.48;
  FrameSum = 2756.3617376889365;
  SmallTriangleSum = 2694.108469053789;
  BeaconSum = 96.59999999999951;
  BeaconNodeX = 0.2763932;
  BeaconNodeZ = -0.4472136;
  BeaconNodeSeed = 3801423874;
  // x 2.5 and z -3.5 thousandths: half up gives 3 and -3, to the even 2
  // and -4
  HalfwayNodeX = 0.0025;
  HalfwayNodeZ = -0.0035;
  HalfwayNodeSeed = 4242788731;
  EmblemParts = 6;
  SmallTriangle = EmblemParts - 1;
  NeonChanges: array [0..12] of TTickLevel = (
    (Tick: 0; Level: 0.8845618536794366), (Tick: 111; Level: 0.11435869233000431),
    (Tick: 115; Level: 0.9425263036647964), (Tick: 1259; Level: 0.11239973202183397),
    (Tick: 1262; Level: 0.9288044350924674), (Tick: 1267; Level: 0.10994446890946855),
    (Tick: 1271; Level: 0.9069227322068328), (Tick: 2151; Level: 0.10561086287674219),
    (Tick: 2154; Level: 0.8810461253323704), (Tick: 2157; Level: 0.10596342677436657),
    (Tick: 2161; Level: 0.8872069037551632), (Tick: 2164; Level: 0.10697054919859947),
    (Tick: 2168; Level: 0.898341713164063));
  WindowChanges: array [0..11] of TTickLevel = (
    (Tick: 0; Level: 1.0), (Tick: 1583; Level: 0.12), (Tick: 1584; Level: 1.0),
    (Tick: 1585; Level: 0.12), (Tick: 1586; Level: 1.0), (Tick: 3296; Level: 0.0),
    (Tick: 7661; Level: 1.0), (Tick: 7662; Level: 0.12), (Tick: 7663; Level: 1.0),
    (Tick: 7664; Level: 0.12), (Tick: 7665; Level: 1.0), (Tick: 9549; Level: 0.0));
  FrameChanges: array [0..13] of TTickLevel = (
    (Tick: 0; Level: 0.9121435467407814), (Tick: 332; Level: 0.11221086046826648),
    (Tick: 337; Level: 0.9523902031863472), (Tick: 1312; Level: 0.11418131524045572),
    (Tick: 1314; Level: 0.9582470969497705), (Tick: 1317; Level: 0.11614371584019441),
    (Tick: 1321; Level: 0.9793323243824928), (Tick: 2185; Level: 0.0),
    (Tick: 2239; Level: 1.0), (Tick: 2243; Level: 0.12), (Tick: 2246; Level: 1.0),
    (Tick: 2249; Level: 0.12), (Tick: 2252; Level: 1.0),
    (Tick: 2255; Level: 0.8803404362277811));
  SmallTriangleChanges: array [0..16] of TTickLevel = (
    (Tick: 0; Level: 0.9612689235629015), (Tick: 478; Level: 0.11765641701763485),
    (Tick: 483; Level: 0.9875952030900608), (Tick: 485; Level: 0.11880540794770686),
    (Tick: 487; Level: 0.992247441710647), (Tick: 492; Level: 0.1195922764096363),
    (Tick: 494; Level: 0.9978612030128422), (Tick: 736; Level: 0.11006914625765903),
    (Tick: 740; Level: 0.9096836200172066), (Tick: 745; Level: 0.10813118757855252),
    (Tick: 747; Level: 0.8979793805984589), (Tick: 751; Level: 0.10708673599146071),
    (Tick: 756; Level: 0.8867360327972448), (Tick: 2185; Level: 0.0), (Tick: 2297; Level: 1.0),
    (Tick: 2299; Level: 0.12), (Tick: 2302; Level: 0.9930733557631644));
  BeaconChanges: array [0..8] of TTickLevel = (
    (Tick: 0; Level: 0.3), (Tick: 49; Level: 0.85), (Tick: 52; Level: 0.3),
    (Tick: 116; Level: 0.85), (Tick: 119; Level: 0.3), (Tick: 183; Level: 0.85),
    (Tick: 186; Level: 0.3), (Tick: 250; Level: 0.85), (Tick: 253; Level: 0.3));

type
  TLevelAt = reference to function(ATick: Integer): Double;

// Tick by tick: the level is the table's on each tick it lists, and moves
// less than a flip on every other; the levels add up to the stand's sum
procedure AssertFollows(const ATable: array of TTickLevel; ATicks: Integer;
  ASum: Double; const ALevelAt: TLevelAt);
begin
  var Next := 0;
  var Was: Double := 0;
  var Sum: Double := 0;
  for var Tick := 0 to ATicks - 1 do
  begin
    var Level := ALevelAt(Tick);
    Sum := Sum + Level;
    if (Next <= High(ATable)) and (ATable[Next].Tick = Tick) then
    begin
      Assert.AreEqual(ATable[Next].Level, Level, Slack, Format('Tick %d', [Tick]));
      Inc(Next);
    end
    else if Tick > 0 then
      Assert.IsTrue(Abs(Level - Was) < FlipStep, Format('No change at tick %d', [Tick]));
    Was := Level;
  end;
  Assert.AreEqual(ASum, Sum, SumSlack, 'The sum of the levels');
end;

procedure TCityLifeTests.Setup;
begin
  FLights := Default(TCityLights);
  FLights.Present := True;
  FLights.Flicker.BreathDepth := 0.12;
  FLights.Flicker.BreathLeast := 90;
  FLights.Flicker.BreathMost := 200;
  FLights.Flicker.WindowLeast := 200;
  FLights.Flicker.WindowMost := 660;
  FLights.Flicker.FaultShare := 0.6;
  FLights.Flicker.FlipsLeast := 2;
  FLights.Flicker.FlipsMost := 6;
  FLights.Flicker.FlipLeast := 2;
  FLights.Flicker.FlipMost := 5;
  FLights.Flicker.FaultLow := 0.12;
  FLights.Windows.OnShare := 0.25;
  FLights.Windows.SpanLeast := 600;
  FLights.Windows.SpanMost := 3000;

  FEmblem := Default(TCityEmblem);
  FEmblem.Present := True;
  FEmblem.FaultShare := 0.25;
  FEmblem.RelightLeast := 2400;
  FEmblem.RelightMost := 4800;
  FEmblem.DarkLeast := 25;
  FEmblem.DarkMost := 45;
  FEmblem.PartLeast := 8;
  FEmblem.PartMost := 20;
  SetLength(FEmblem.Parts, EmblemParts);
  SetLength(FEmblem.Halos, EmblemParts);

  FBeacons := Default(TCityBeacons);
  FBeacons.Present := True;
  FBeacons.GlowLevel := 0.3;
  FBeacons.FlashLevel := 0.85;
  FBeacons.FlashTicks := 3;
  FBeacons.PeriodLeast := 56;
  FBeacons.PeriodMost := 96;
end;

procedure TCityLifeTests.TestMixMatchesTheStand;
begin
  Assert.AreEqual<Cardinal>(1753845952, Mix(1), 'mix(1)');
  Assert.AreEqual<Cardinal>(2834422664, Mix(123456789), 'mix(123456789)');
end;

procedure TCityLifeTests.TestRollMatchesTheStand;
begin
  Assert.AreEqual(0.6766494906041771, Roll(7, 1000), 1E-15, 'roll(7, 1000)');
  Assert.AreEqual(6, RollInt(7, 1000, 0, 9), 'rollInt(7, 1000, 0, 9)');
end;

procedure TCityLifeTests.TestRollIntReachesBothEndsAndNoFurther;
const
  Least = 3;
  Most = 5;
begin
  var SawLeast := False;
  var SawMost := False;
  for var Key := 0 to 999 do
  begin
    var Value := RollInt(42, Key, Least, Most);
    Assert.IsTrue((Value >= Least) and (Value <= Most), Format('Key %d: %d', [Key, Value]));
    SawLeast := SawLeast or (Value = Least);
    SawMost := SawMost or (Value = Most);
  end;
  Assert.IsTrue(SawLeast, 'The least comes up');
  Assert.IsTrue(SawMost, 'The most comes up');
end;

procedure TCityLifeTests.TestLightSeedMatchesTheStand;
begin
  Assert.AreEqual<Cardinal>(1687751718, LightSeed(NeonSeedElement, NeonSeedLight));
end;

procedure TCityLifeTests.TestNeonStuttersOnTheStandsTicks;
begin
  var Seed := LightSeed(NeonSeedElement, NeonSeedLight);
  var Flicker := FLights.Flicker;
  AssertFollows(NeonChanges, NeonTicks, NeonSum,
    function(ATick: Integer): Double
    begin
      Result := NeonLevel(Flicker, Seed, ATick, Flicker.FaultShare);
    end);
end;

procedure TCityLifeTests.TestNeonBreathesWithinItsDepthWithoutFaults;
begin
  var Seed := LightSeed(NeonSeedElement, NeonSeedLight);
  for var Tick := 0 to NeonTicks - 1 do
  begin
    var Level := NeonLevel(FLights.Flicker, Seed, Tick, 0);
    Assert.IsTrue(Level >= 1 - FLights.Flicker.BreathDepth - Slack, 'Not below its depth');
    Assert.IsTrue(Level <= 1 + Slack, 'Not above full');
  end;
end;

procedure TCityLifeTests.TestWindowWakesOnTheStandsTicks;
begin
  var Seed := LightSeed(WindowSeedElement, 0);
  var Lights := FLights;
  AssertFollows(WindowChanges, WindowTicks, WindowSum,
    function(ATick: Integer): Double
    begin
      Result := WindowLevel(Lights, Seed, ATick);
    end);
end;

procedure TCityLifeTests.TestWindowsLitAboutTheirShare;
const
  Windows = 400;
  AtTick = 5000;
begin
  var Lit := 0;
  for var Element := 0 to Windows - 1 do
    if WindowLevel(FLights, LightSeed(Element, 0), AtTick) > 0 then
      Inc(Lit);
  var Share := Lit / Windows;
  Assert.IsTrue(Abs(Share - FLights.Windows.OnShare) < 0.1, Format('%.2f lit', [Share]));
end;

procedure TCityLifeTests.TestEmblemCyclesAsOnTheStand;
begin
  var Cycle := EmblemCycle(FEmblem, 0);
  Assert.AreEqual(0, Cycle.Index, 'At the start: the first');
  Assert.AreEqual(-1393, Cycle.Start, 'Begun before the chase');
  Cycle := EmblemCycle(FEmblem, 5000);
  Assert.AreEqual(1, Cycle.Index, 'Later: the second');
  Assert.AreEqual(2185, Cycle.Start);
  Cycle := EmblemCycle(FEmblem, 12000);
  Assert.AreEqual(3, Cycle.Index, 'Later still: the fourth');
  Assert.AreEqual(10261, Cycle.Start);
end;

procedure TCityLifeTests.TestEmblemFrameLightsOnTheStandsTicks;
begin
  var Emblem := FEmblem;
  var Flicker := FLights.Flicker;
  AssertFollows(FrameChanges, EmblemTicks, FrameSum,
    function(ATick: Integer): Double
    begin
      Result := EmblemPartLevel(Emblem, Flicker, 0, ATick);
    end);
end;

procedure TCityLifeTests.TestEmblemSmallTriangleLightsOnTheStandsTicks;
begin
  var Emblem := FEmblem;
  var Flicker := FLights.Flicker;
  AssertFollows(SmallTriangleChanges, EmblemTicks, SmallTriangleSum,
    function(ATick: Integer): Double
    begin
      Result := EmblemPartLevel(Emblem, Flicker, SmallTriangle, ATick);
    end);
end;

procedure TCityLifeTests.TestEmblemLitWhenTheChaseStarts;
begin
  for var Part := 0 to EmblemParts - 1 do
    Assert.IsTrue(EmblemPartLevel(FEmblem, FLights.Flicker, Part, 0) > 0,
      Format('Part %d', [Part + 1]));
end;

procedure TCityLifeTests.TestEmblemFrameCatchesBeforeTheLastPart;
const
  Cycles = 5;
begin
  var Tick := 0;
  for var i := 1 to Cycles do
  begin
    var Cycle := EmblemCycle(FEmblem, Tick);
    var Next := Cycle;
    while Next.Index = Cycle.Index do
    begin
      Inc(Tick);
      Next := EmblemCycle(FEmblem, Tick);
    end;
    var FrameLit := Tick;
    while EmblemPartLevel(FEmblem, FLights.Flicker, 0, FrameLit) = 0 do
      Inc(FrameLit);
    var LastLit := Tick;
    while EmblemPartLevel(FEmblem, FLights.Flicker, SmallTriangle, LastLit) = 0 do
      Inc(LastLit);
    Assert.IsTrue(FrameLit > Tick, Format('Cycle %d goes out first', [Next.Index]));
    Assert.IsTrue(FrameLit < LastLit, Format('Cycle %d: the frame first', [Next.Index]));
  end;
end;

procedure TCityLifeTests.TestBeaconFlashesOnTheStandsTicks;
begin
  var Beacons := FBeacons;
  AssertFollows(BeaconChanges, BeaconTicks, BeaconSum,
    function(ATick: Integer): Double
    begin
      Result := BeaconLevel(Beacons, BeaconNodeSeed, ATick);
    end);
end;

procedure TCityLifeTests.TestBeaconFlashesForItsFlashTicks;
const
  Seeds = 20;
  Ticks = 1000;
begin
  for var Seed := 1 to Seeds do
  begin
    var Run := 0;
    for var Tick := 0 to Ticks - 1 do
    begin
      if BeaconLevel(FBeacons, Mix(Seed), Tick) = FBeacons.FlashLevel then
      begin
        Inc(Run);
        Continue;
      end;
      Assert.IsTrue((Run = 0) or (Run = FBeacons.FlashTicks) or (Run = Tick),
        Format('Seed %d: a flash of %d ticks', [Seed, Run]));
      Run := 0;
    end;
  end;
end;

procedure TCityLifeTests.TestBeaconSeedMatchesTheStand;
begin
  Assert.AreEqual<Cardinal>(BeaconNodeSeed, BeaconSeed(0, BeaconNodeX, BeaconNodeZ));
end;

procedure TCityLifeTests.TestBeaconSeedRoundsHalfUpAsTheStand;
begin
  Assert.AreEqual<Cardinal>(HalfwayNodeSeed, BeaconSeed(1, HalfwayNodeX, HalfwayNodeZ));
end;

procedure TCityLifeTests.TestBeaconSeedIsThePlaceOnItsFrame;
begin
  Assert.AreEqual<Cardinal>(BeaconSeed(0, BeaconNodeX, BeaconNodeZ),
    BeaconSeed(0, BeaconNodeX + 1E-5, BeaconNodeZ - 1E-5), 'A hair off: the same place');
  Assert.AreNotEqual<Cardinal>(BeaconSeed(0, BeaconNodeX, BeaconNodeZ),
    BeaconSeed(1, BeaconNodeX, BeaconNodeZ), 'The same place on another frame');
  Assert.AreNotEqual<Cardinal>(BeaconSeed(0, BeaconNodeX, BeaconNodeZ),
    BeaconSeed(0, BeaconNodeZ, BeaconNodeX), 'Another place on the same frame');
end;

initialization
  TDUnitX.RegisterTestFixture(TCityLifeTests);

end.
