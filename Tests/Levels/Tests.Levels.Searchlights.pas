{
  Tests.Levels.Searchlights - the chase city's searchlights against the
  stand's own: the tables below are the stand's functions
  (tools/chase/stand.template.html) run under node over lamps and a dome of
  the tests' own - the shipped layout's numbers of the day they were made,
  and a third lamp outside the dome - so tuning the layout breaks nothing
  here.

  A lamp's clock and its angle are the stand's, between ticks too; the
  clock never runs back and never outruns the far plane's, holds still for
  no longer than the longest hold, and without pauses is the far plane's.
  The angle stays within the aim and the two sweeps. A beam stands where
  the stand has it: its lamp rides at its nearness, the glass lies on the
  dome's half-ellipse, a lamp outside every dome has none. A beam is
  brightest at its lamp, falls to the glass's level there, steps down to
  its tail and fades out with it; nothing is lit past the tail or behind
  the lamp.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Levels.Searchlights;

interface

uses
  DUnitX.TestFramework, Levels.FarPlane, Levels.Searchlights;

type
  [TestFixture]
  TSearchlightClockTests = class
  private
    FLights: TCitySearchlights;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure TestClockMatchesTheStand;
    [Test]
    procedure TestClockNeverRunsBack;
    [Test]
    procedure TestClockNeverOutrunsTheFarPlane;
    [Test]
    procedure TestHoldsNoLongerThanTheLongestHold;
    [Test]
    procedure TestWithoutPausesTheClockIsTheFarPlanes;
    [Test]
    procedure TestAngleMatchesTheStand;
    [Test]
    procedure TestAngleStaysWithinItsSweep;
  end;

  [TestFixture]
  TSearchlightBeamTests = class
  private
    FDef: TFarPlaneDef;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure TestBeamMatchesTheStand;
    [Test]
    procedure TestTheLampRidesAtItsNearness;
    [Test]
    procedure TestTheGlassLiesOnTheDome;
    [Test]
    procedure TestALampOutsideTheDomeHasNoGlass;
    [Test]
    procedure TestBrightestAtTheLamp;
    [Test]
    procedure TestStepsDownAtTheGlass;
    [Test]
    procedure TestTheTailFadesOut;
    [Test]
    procedure TestNothingPastTheTailOrBehindTheLamp;
  end;

implementation

uses
  System.SysUtils, System.Math;

type
  TClockAt = record
    Lamp: Integer;
    Time, Value: Double;
  end;

  TBeamAt = record
    Lamp: Integer;
    Offset, Time: Double;
    FromX, FromY, DirX, DirY, Glass: Double;
  end;

const
  Slack = 1E-9;
  LongRunTicks = 20000;
  LongestHold = 90;
  StandClocks: array [0..17] of TClockAt = (
    (Lamp: 0; Time: 0; Value: -71.02730691456263),
    (Lamp: 0; Time: 1; Value: -70.33616185303414),
    (Lamp: 0; Time: 57.5; Value: -14.5),
    (Lamp: 0; Time: 333; Value: 214),
    (Lamp: 0; Time: 1000.25; Value: 842.25),
    (Lamp: 0; Time: 2468; Value: 2146),
    (Lamp: 0; Time: 5000; Value: 4337),
    (Lamp: 0; Time: 7777.75; Value: 6720.75),
    (Lamp: 0; Time: 12345; Value: 10632),
    (Lamp: 1; Time: 0; Value: 0),
    (Lamp: 1; Time: 1; Value: 1),
    (Lamp: 1; Time: 57.5; Value: 57.5),
    (Lamp: 1; Time: 333; Value: 333),
    (Lamp: 1; Time: 1000.25; Value: 913.25),
    (Lamp: 1; Time: 2468; Value: 2202),
    (Lamp: 1; Time: 5000; Value: 4424),
    (Lamp: 1; Time: 7777.75; Value: 6658.930329717678),
    (Lamp: 1; Time: 12345; Value: 10563));
  StandAngles: array [0..17] of TClockAt = (
    (Lamp: 0; Time: 0; Value: -1.436361828294817),
    (Lamp: 0; Time: 1; Value: -1.4352398084130642),
    (Lamp: 0; Time: 57.5; Value: -1.3807250623238099),
    (Lamp: 0; Time: 333; Value: -2.289552074804113),
    (Lamp: 0; Time: 1000.25; Value: -1.6940515303683652),
    (Lamp: 0; Time: 2468; Value: -1.2573668197169308),
    (Lamp: 0; Time: 5000; Value: -1.414110220355512),
    (Lamp: 0; Time: 7777.75; Value: -1.2878760052549545),
    (Lamp: 0; Time: 12345; Value: -1.5447320975309737),
    (Lamp: 1; Time: 0; Value: -1.7081985414562),
    (Lamp: 1; Time: 1; Value: -1.709197965921086),
    (Lamp: 1; Time: 57.5; Value: -1.646969287621312),
    (Lamp: 1; Time: 333; Value: -1.0981995503750328),
    (Lamp: 1; Time: 1000.25; Value: -0.8865269473179976),
    (Lamp: 1; Time: 2468; Value: -0.871869266555839),
    (Lamp: 1; Time: 5000; Value: -1.9496160420133635),
    (Lamp: 1; Time: 7777.75; Value: -0.8612739435126865),
    (Lamp: 1; Time: 12345; Value: -0.9483429862295828));
  StandBeams: array [0..4] of TBeamAt = (
    (Lamp: 0; Offset: 460; Time: 0; FromX: 216; FromY: 256;
      DirX: 0.1340299333276971; DirY: -0.9909772837821123; Glass: 160.53635690938097),
    (Lamp: 0; Offset: 460; Time: 2468; FromX: 216; FromY: 256;
      DirX: 0.30832287078501486; DirY: -0.9512817707445502; Glass: 168.17388974203394),
    (Lamp: 1; Offset: 600; Time: 333; FromX: 258; FromY: 256;
      DirX: 0.4551999593231947; DirY: -0.8903892390590544; Glass: 118.43228880197752),
    (Lamp: 0; Offset: 200; Time: 5000; FromX: 476; FromY: 256;
      DirX: 0.15604577165824546; DirY: -0.9877498251822587; Glass: 161.2985775946908),
    (Lamp: 2; Offset: 0; Time: 1000.25; FromX: 278; FromY: 248;
      DirX: 0.3329741884803268; DirY: -0.9429359415176981; Glass: 0));
  // Two in the dome as the shipped city has them, a third outside it,
  // halfway back to the horizon
  TestLamps: array [0..2] of TSearchlightLamp = (
    (X: 676; Y: 266; Lift: 10; Aim: -105;
      Waves: ((Degrees: 28; PeriodTicks: 760), (Degrees: 8; PeriodTicks: 270))),
    (X: 858; Y: 266; Lift: 10; Aim: -78;
      Waves: ((Degrees: 26; PeriodTicks: 640), (Degrees: 8; PeriodTicks: 230))),
    (X: 300; Y: 252; Lift: 4; Aim: -90;
      Waves: ((Degrees: 20; PeriodTicks: 500), (Degrees: 5; PeriodTicks: 200))));

function TestLights: TCitySearchlights;
begin
  Result := Default(TCitySearchlights);
  Result.Present := True;
  Result.Level := 0.42;
  Result.GlassLevel := 0.26;
  Result.TailShare := 0.25;
  Result.Tail := 150;
  Result.RootHalf := 1.5;
  Result.Spread := 0.15;
  Result.Pause.WindowLeast := 200;
  Result.Pause.WindowMost := 330;
  Result.Pause.Share := 0.45;
  Result.Pause.EaseTicks := 20;
  Result.Pause.HoldLeast := 40;
  Result.Pause.HoldMost := LongestHold;
  Result.Lamps := [TestLamps[0], TestLamps[1], TestLamps[2]];
end;

// TSearchlightClockTests

procedure TSearchlightClockTests.Setup;
begin
  FLights := TestLights;
end;

procedure TSearchlightClockTests.TestClockMatchesTheStand;
begin
  for var At in StandClocks do
    Assert.AreEqual(At.Value, SearchlightClock(FLights.Pause, SearchlightSeed(At.Lamp),
      At.Time), Slack, Format('Lamp %d at %g', [At.Lamp, At.Time]));
end;

procedure TSearchlightClockTests.TestClockNeverRunsBack;
begin
  var Seed := SearchlightSeed(0);
  var Was := SearchlightClock(FLights.Pause, Seed, 0);
  for var i := 1 to LongRunTicks * 3 do
  begin
    var Time: Double := i / 3;
    var Own := SearchlightClock(FLights.Pause, Seed, Time);
    Assert.IsTrue(Own >= Was - Slack, Format('At %g', [Time]));
    Was := Own;
  end;
end;

procedure TSearchlightClockTests.TestClockNeverOutrunsTheFarPlane;
begin
  var Seed := SearchlightSeed(1);
  var Was := SearchlightClock(FLights.Pause, Seed, 0);
  for var Tick := 1 to LongRunTicks do
  begin
    var Own := SearchlightClock(FLights.Pause, Seed, Tick);
    Assert.IsTrue(Own - Was <= 1 + Slack, Format('Tick %d', [Tick]));
    Was := Own;
  end;
end;

procedure TSearchlightClockTests.TestHoldsNoLongerThanTheLongestHold;
begin
  var Seed := SearchlightSeed(0);
  var Was := SearchlightClock(FLights.Pause, Seed, 0);
  var Still := 0;
  var Holds := 0;
  for var Tick := 1 to LongRunTicks do
  begin
    var Own := SearchlightClock(FLights.Pause, Seed, Tick);
    if Own = Was then
      Inc(Still)
    else
    begin
      if Still > 0 then
        Inc(Holds);
      Still := 0;
    end;
    Assert.IsTrue(Still <= LongestHold, Format('Still at tick %d', [Tick]));
    Was := Own;
  end;
  Assert.IsTrue(Holds > 0, 'It holds now and then');
end;

procedure TSearchlightClockTests.TestWithoutPausesTheClockIsTheFarPlanes;
begin
  FLights.Pause.Share := 0;
  for var Tick := 0 to 2000 do
    Assert.AreEqual(Double(Tick), SearchlightClock(FLights.Pause, SearchlightSeed(0), Tick),
      Slack, Format('Tick %d', [Tick]));
end;

procedure TSearchlightClockTests.TestAngleMatchesTheStand;
begin
  for var At in StandAngles do
    Assert.AreEqual(At.Value, SearchlightAngle(FLights, At.Lamp, At.Time), Slack,
      Format('Lamp %d at %g', [At.Lamp, At.Time]));
end;

procedure TSearchlightClockTests.TestAngleStaysWithinItsSweep;
begin
  for var i := 0 to High(FLights.Lamps) do
  begin
    var Swept := FLights.Lamps[i];
    var Reach := Swept.Waves[0].Degrees + Swept.Waves[1].Degrees;
    for var Tick := 0 to LongRunTicks div 4 do
    begin
      var Degrees := RadToDeg(SearchlightAngle(FLights, i, Tick));
      Assert.IsTrue(Abs(Degrees - Swept.Aim) <= Reach + Slack,
        Format('Lamp %d, tick %d: %g', [i, Tick, Degrees]));
    end;
  end;
end;

// TSearchlightBeamTests

const
  DomeX = 468;
  DomeW = 512;
  DomeH = 170;
  BaseLine = 266;
  // The step at the glass and a hair either side of it
  Hair = 1E-6;

procedure TSearchlightBeamTests.Setup;
begin
  FDef := Default(TFarPlaneDef);
  FDef.ScreenWidth := 512;
  FDef.Camera.Present := True;
  FDef.Camera.Horizon := 238;
  FDef.Camera.BaseY := BaseLine;
  FDef.Camera.Focal := 1024;
  SetLength(FDef.Frames, 1);
  FDef.Frames[0].Id := 'dome';
  FDef.Frames[0].X := DomeX;
  FDef.Frames[0].W := DomeW;
  FDef.Frames[0].H := DomeH;
  FDef.Searchlights := TestLights;
end;

procedure TSearchlightBeamTests.TestBeamMatchesTheStand;
begin
  for var At in StandBeams do
  begin
    var Beam := SearchlightBeam(FDef, At.Lamp, At.Offset, At.Time);
    var Where := Format('Lamp %d at %g, offset %g', [At.Lamp, At.Time, At.Offset]);
    Assert.AreEqual(At.FromX, Beam.FromX, Slack, Where + ': lamp x');
    Assert.AreEqual(At.FromY, Beam.FromY, Slack, Where + ': lamp y');
    Assert.AreEqual(At.DirX, Beam.DirX, Slack, Where + ': direction x');
    Assert.AreEqual(At.DirY, Beam.DirY, Slack, Where + ': direction y');
    Assert.AreEqual(At.Glass, Beam.Glass, 1E-6, Where + ': glass');
  end;
end;

// The third lamp stands halfway to the horizon: half the city's ride
procedure TSearchlightBeamTests.TestTheLampRidesAtItsNearness;
begin
  var Near := SearchlightBeam(FDef, 0, 100, 0);
  var NearLater := SearchlightBeam(FDef, 0, 140, 0);
  Assert.AreEqual(-40.0, Double(NearLater.FromX - Near.FromX), Slack,
    'On the base line, with the city');
  var Far := SearchlightBeam(FDef, 2, 100, 0);
  var FarLater := SearchlightBeam(FDef, 2, 140, 0);
  Assert.AreEqual(-20.0, Double(FarLater.FromX - Far.FromX), Slack,
    'Halfway back, at half its pace');
end;

procedure TSearchlightBeamTests.TestTheGlassLiesOnTheDome;
begin
  for var Tick := 0 to 200 do
  begin
    var Offset: Double := 400 + Tick;
    var Beam := SearchlightBeam(FDef, Tick mod 2, Offset, Tick * 37);
    var CentreX := DomeX + DomeW / 2 - Offset;
    var X := (Beam.AtX(Beam.Glass) - CentreX) / (DomeW / 2);
    var Y := (Beam.AtY(Beam.Glass) - BaseLine) / DomeH;
    Assert.AreEqual(1.0, Double(X * X + Y * Y), 1E-6, Format('Tick %d', [Tick]));
    Assert.IsTrue(Beam.Glass > 0, Format('Tick %d: inside the dome', [Tick]));
  end;
end;

procedure TSearchlightBeamTests.TestALampOutsideTheDomeHasNoGlass;
begin
  var Beam := SearchlightBeam(FDef, 2, 0, 0);
  Assert.AreEqual(0.0, Beam.Glass, Slack, 'No glass');
  var Lights := FDef.Searchlights;
  var TailStart := Double(Lights.GlassLevel * Lights.TailShare);
  Assert.AreEqual(TailStart, BeamLevel(Lights, Beam, 0), Slack, 'Only its tail, from the lamp');
end;

procedure TSearchlightBeamTests.TestBrightestAtTheLamp;
begin
  var Lights := FDef.Searchlights;
  var Beam := SearchlightBeam(FDef, 0, 460, 0);
  Assert.AreEqual(Double(Lights.Level), BeamLevel(Lights, Beam, 0), Slack, 'At the lamp');
  var Was := BeamLevel(Lights, Beam, 0);
  for var i := 1 to 100 do
  begin
    var Level := BeamLevel(Lights, Beam, Beam.Glass * i / 100);
    Assert.IsTrue(Level <= Was + Slack, Format('%d%% of the way', [i]));
    Was := Level;
  end;
end;

procedure TSearchlightBeamTests.TestStepsDownAtTheGlass;
begin
  var Lights := FDef.Searchlights;
  var Beam := SearchlightBeam(FDef, 1, 600, 333);
  Assert.AreEqual(Double(Lights.GlassLevel), BeamLevel(Lights, Beam, Beam.Glass), Slack,
    'The glass''s level on the inner side');
  Assert.AreEqual(Double(Lights.GlassLevel * Lights.TailShare),
    BeamLevel(Lights, Beam, Beam.Glass + Hair), 1E-6, 'The tail''s past it');
end;

procedure TSearchlightBeamTests.TestTheTailFadesOut;
begin
  var Lights := FDef.Searchlights;
  var Beam := SearchlightBeam(FDef, 0, 460, 0);
  var Was := BeamLevel(Lights, Beam, Beam.Glass + Hair);
  for var i := 1 to 100 do
  begin
    var Level := BeamLevel(Lights, Beam, Beam.Glass + Lights.Tail * i / 100);
    Assert.IsTrue(Level <= Was + Slack, Format('%d%% of the tail', [i]));
    Was := Level;
  end;
  Assert.AreEqual(0.0, Was, Slack, 'Out at its end');
  Assert.AreEqual(0.0, TailLevel(Lights, 1), Slack, 'The tail''s end');
end;

procedure TSearchlightBeamTests.TestNothingPastTheTailOrBehindTheLamp;
begin
  var Lights := FDef.Searchlights;
  var Beam := SearchlightBeam(FDef, 0, 460, 0);
  Assert.AreEqual(0.0, BeamLevel(Lights, Beam, Beam.Glass + Lights.Tail + 1), Slack,
    'Past the tail');
  Assert.AreEqual(0.0, BeamLevel(Lights, Beam, -1), Slack, 'Behind the lamp');
end;

initialization
  TDUnitX.RegisterTestFixture(TSearchlightClockTests);
  TDUnitX.RegisterTestFixture(TSearchlightBeamTests);

end.
