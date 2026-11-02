{
  Tests.Levels.Monorail - the chase city's train against the stand's own:
  the tables below are the stand's functions (tools/chase/stand.template.html)
  run under node over a train and a line of the tests' own - the shipped
  layout's numbers of the day they were made, the stops set by hand - so
  tuning the layout breaks nothing here.

  A run pushes up to cruise and down again as the stand's does, and one
  too short for cruise turns halfway; a run is the same read from either
  end. The train leaves and reaches its stops on the stand's ticks and
  stands where the stand has it, between ticks too; it never goes faster
  than its cruise, never leaves its stops' span, dwells within its ticks
  and lies between two ticks between them. The line sets a stop inside
  each station by its mouth, the mouth on the side the beam enters, at
  the stations' depth as the camera has it, whatever their order in the
  city; stations at two depths and stops with no run between them raise.
  The train is shown whole between the mouths and cut at a mouth.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Levels.Monorail;

interface

uses
  DUnitX.TestFramework, Levels.FarPlane, Levels.Monorail;

type
  [TestFixture]
  TTrainRunTests = class
  private
    FTrain: TCityTrain;
    FLine: TMonorailLine;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure TestRunMatchesTheStand;
    [Test]
    procedure TestRunPlacesMatchTheStand;
    [Test]
    procedure TestAShortRunTurnsHalfway;
    [Test]
    procedure TestARunReadsTheSameFromEitherEnd;
    [Test]
    procedure TestLeavesAndStopsOnTheStandsTicks;
    [Test]
    procedure TestStandsWhereTheStandHasIt;
    [Test]
    procedure TestNeverFasterThanCruise;
    [Test]
    procedure TestStaysBetweenItsStops;
    [Test]
    procedure TestDwellsWithinItsTicks;
    [Test]
    procedure TestBetweenTicksLiesBetweenThem;
  end;

  [TestFixture]
  TMonorailLineTests = class
  private
    FDef: TFarPlaneDef;
    procedure PlaceStations(AY: Single; ALeftMirror: Boolean);
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure TestStopsInsideTheMouths;
    [Test]
    procedure TestTheMouthFacesTheBeam;
    [Test]
    procedure TestAtDepthTheLineDrawsToTheMiddle;
    [Test]
    procedure TestStationsListedRightToLeft;
    [Test]
    procedure TestStationsAtTwoDepthsRaise;
    [Test]
    procedure TestStopsWithoutARunRaise;
    [Test]
    procedure TestShownWholeBetweenTheMouths;
    [Test]
    procedure TestCutAtTheLeftMouth;
    [Test]
    procedure TestCutAtTheRightMouth;
  end;

implementation

uses
  System.SysUtils;

type
  TTrainEvent = record
    Tick: Integer;
    Leaves: Boolean;
    Stop: Double;
  end;

  TTrainAt = record
    Time: Double;
    Left: Double;
  end;

const
  Slack = 1E-9;
  // The stand's sum of the left edges over the first EventTicks ticks
  SumSlack = 1E-3;
  // Past the last event of the table, short of the next one
  EventTicks = 8900;
  LeftStop = 100;
  RightStop = 523;
  ShortRun = 30;
  StandRamp = 132.0;
  StandPeak = 0.48484848484848486;
  StandRoll = 740.4375;
  StandTicks = 1004.4375;
  StandSum = 2711993.187500001;
  RunPlaces: array [0..6] of TTrainAt = (
    (Time: 0; Left: 0), (Time: 50; Left: 4.591368227731864),
    (Time: 131.5; Left: 31.75803489439853), (Time: 132; Left: 32),
    (Time: 500; Left: 210.42424242424244), (Time: 872.4; Left: 390.9818181818182),
    (Time: 1004; Left: 422.9996484733701));
  StandLefts: array [0..8] of TTrainAt = (
    (Time: 0; Left: 100), (Time: 1; Left: 100), (Time: 377; Left: 174.66666666666669),
    (Time: 1234.5; Left: 523), (Time: 2000; Left: 407.3333333333333),
    (Time: 3333.25; Left: 166.12121212121212), (Time: 5000; Left: 356.3636363636364),
    (Time: 7777.75; Left: 418.969696969697), (Time: 9999; Left: 523));
  StandEvents: array [0..11] of TTrainEvent = (
    (Tick: 158; Leaves: True; Stop: LeftStop), (Tick: 1163; Leaves: False; Stop: RightStop),
    (Tick: 1696; Leaves: True; Stop: RightStop), (Tick: 2701; Leaves: False; Stop: LeftStop),
    (Tick: 3131; Leaves: True; Stop: LeftStop), (Tick: 4137; Leaves: False; Stop: RightStop),
    (Tick: 4591; Leaves: True; Stop: RightStop), (Tick: 5596; Leaves: False; Stop: LeftStop),
    (Tick: 6188; Leaves: True; Stop: LeftStop), (Tick: 7194; Leaves: False; Stop: RightStop),
    (Tick: 7498; Leaves: True; Stop: RightStop), (Tick: 8503; Leaves: False; Stop: LeftStop));
  // A hair over a tick's worth of cruise, for the arithmetic
  SpeedSlack = 1E-9;

// TTrainRunTests

procedure TTrainRunTests.Setup;
begin
  FTrain := Default(TCityTrain);
  FTrain.Present := True;
  FTrain.W := 81.9;
  FTrain.Cruise := 16;
  FTrain.AccelTicks := 132;
  FTrain.DwellLeast := 300;
  FTrain.DwellMost := 600;
  FLine := Default(TMonorailLine);
  FLine.LeftStop := LeftStop;
  FLine.RightStop := RightStop;
end;

procedure TTrainRunTests.TestRunMatchesTheStand;
begin
  var Run := TrainRun(FTrain, RightStop - LeftStop);
  Assert.AreEqual(StandRamp, Run.Ramp, Slack, 'Pushes for its push ticks');
  Assert.AreEqual(StandPeak, Run.Peak, Slack, 'Reaches cruise');
  Assert.AreEqual(StandRoll, Run.Roll, 1E-6, 'Rolls the rest');
  Assert.AreEqual(StandTicks, Run.Ticks, 1E-6, 'The whole run');
end;

procedure TTrainRunTests.TestRunPlacesMatchTheStand;
begin
  var Run := TrainRun(FTrain, RightStop - LeftStop);
  for var At in RunPlaces do
    Assert.AreEqual(At.Left, Run.Place(At.Time), 1E-6, Format('%g ticks in', [At.Time]));
  Assert.AreEqual(Run.Distance, Run.Place(Run.Ticks), 1E-6, 'At its end');
end;

procedure TTrainRunTests.TestAShortRunTurnsHalfway;
begin
  var Run := TrainRun(FTrain, ShortRun);
  Assert.AreEqual(0.0, Run.Roll, Slack, 'No roll');
  Assert.IsTrue(Run.Peak < FTrain.Cruise / 33, 'Short of cruise');
  Assert.AreEqual(ShortRun / 2, Run.Place(Run.Ticks / 2), 1E-6, 'Halfway at half the time');
end;

procedure TTrainRunTests.TestARunReadsTheSameFromEitherEnd;
begin
  var Run := TrainRun(FTrain, RightStop - LeftStop);
  var Step := Run.Ticks / 40;
  for var i := 0 to 40 do
  begin
    var Time := i * Step;
    Assert.AreEqual(Run.Distance, Run.Place(Time) + Run.Place(Run.Ticks - Time), 1E-6,
      Format('%g ticks from each end', [Time]));
  end;
end;

procedure TTrainRunTests.TestLeavesAndStopsOnTheStandsTicks;
begin
  var Next := 0;
  var Was := TrainLeft(FTrain, FLine, 0);
  var Moving := False;
  var Sum: Double := Was;
  for var Tick := 1 to EventTicks - 1 do
  begin
    var Left := TrainLeft(FTrain, FLine, Tick);
    Sum := Sum + Left;
    var Moves := Left <> Was;
    if Moves <> Moving then
    begin
      Assert.IsTrue(Next <= High(StandEvents), Format('An event at tick %d too many', [Tick]));
      if Next <= High(StandEvents) then
      begin
        var Event := StandEvents[Next];
        Assert.AreEqual(Event.Tick, Integer(Tick), Format('Event %d', [Next]));
        Assert.IsTrue(Event.Leaves = Moves, Format('Event %d leaves', [Next]));
        var AtStop := Left;
        if Moves then
          AtStop := Was;
        Assert.AreEqual(Event.Stop, AtStop, Slack, Format('Event %d stop', [Next]));
      end;
      Inc(Next);
      Moving := Moves;
    end;
    Was := Left;
  end;
  Assert.AreEqual(Integer(Length(StandEvents)), Next, 'Every event of the stand');
  Assert.AreEqual(StandSum, Sum, SumSlack, 'The sum of the left edges');
end;

procedure TTrainRunTests.TestStandsWhereTheStandHasIt;
begin
  for var At in StandLefts do
    Assert.AreEqual(At.Left, TrainLeft(FTrain, FLine, At.Time), 1E-6,
      Format('At %g', [At.Time]));
end;

procedure TTrainRunTests.TestNeverFasterThanCruise;
begin
  var Cruise: Double := FTrain.Cruise / 33;
  var Was := TrainLeft(FTrain, FLine, 0);
  for var Tick := 1 to EventTicks do
  begin
    var Left := TrainLeft(FTrain, FLine, Tick);
    Assert.IsTrue(Abs(Left - Was) <= Cruise + SpeedSlack, Format('Tick %d', [Tick]));
    Was := Left;
  end;
end;

procedure TTrainRunTests.TestStaysBetweenItsStops;
begin
  for var Tick := 0 to EventTicks do
  begin
    var Left := TrainLeft(FTrain, FLine, Tick);
    Assert.IsTrue((Left >= LeftStop - Slack) and (Left <= RightStop + Slack),
      Format('Tick %d: %g', [Tick, Left]));
  end;
end;

// The first dwell begins before the clock, so only the ones after it
procedure TTrainRunTests.TestDwellsWithinItsTicks;
begin
  for var i := 1 to High(StandEvents) div 2 do
  begin
    var Dwell := StandEvents[2 * i].Tick - StandEvents[2 * i - 1].Tick;
    Assert.IsTrue((Dwell >= FTrain.DwellLeast) and (Dwell <= FTrain.DwellMost + 1),
      Format('Dwell %d: %d ticks', [i, Dwell]));
  end;
end;

procedure TTrainRunTests.TestBetweenTicksLiesBetweenThem;
begin
  for var Tick := 150 to 1200 do
  begin
    var Before := TrainLeft(FTrain, FLine, Tick);
    var After := TrainLeft(FTrain, FLine, Tick + 1);
    var Between := TrainLeft(FTrain, FLine, Tick + 0.5);
    Assert.IsTrue((Between >= Before - Slack) and (Between <= After + Slack),
      Format('Tick %d and a half', [Tick]));
  end;
end;

// TMonorailLineTests

const
  StationW = 80;
  StationLeftX = 100;
  StationRightX = 400;
  MouthShare = 0.25;
  TrainW = 60;
  TrainInside = 30;
  BaseLine = 266;
  // Halfway between the horizon and the base line
  HalfwayY = 252;

procedure TMonorailLineTests.Setup;
begin
  FDef := Default(TFarPlaneDef);
  FDef.ScreenWidth := 512;
  FDef.Camera.Present := True;
  FDef.Camera.Horizon := 238;
  FDef.Camera.BaseY := BaseLine;
  FDef.Camera.Focal := 1024;
  FDef.Train.Present := True;
  FDef.Train.Piece := 'car';
  FDef.Train.Station := 'stop';
  FDef.Train.Mouth := MouthShare;
  FDef.Train.W := TrainW;
  FDef.Train.Inside := TrainInside;
  FDef.Train.Cruise := 16;
  FDef.Train.AccelTicks := 132;
  FDef.Train.DwellLeast := 300;
  FDef.Train.DwellMost := 600;
  PlaceStations(BaseLine, True);
end;

function Station(AX, AY: Single; AMirror: Boolean): TFarPlaneElement;
begin
  Result := Default(TFarPlaneElement);
  Result.Id := 'stop';
  Result.X := AX;
  Result.Y := AY;
  Result.W := StationW;
  Result.DepthY := AY;
  Result.Mirror := AMirror;
end;

// The left one mirrored as the shipped city has it, its mouth on its right;
// a building between them
procedure TMonorailLineTests.PlaceStations(AY: Single; ALeftMirror: Boolean);
begin
  SetLength(FDef.Layers, 1);
  FDef.Layers[0].Id := 'city';
  FDef.Layers[0].Motion := fmCity;
  FDef.Layers[0].Length := 2688;
  var Tower := Station(250, BaseLine, False);
  Tower.Id := 'tower';
  FDef.Layers[0].Elements := [Station(StationLeftX, AY, ALeftMirror), Tower,
    Station(StationRightX, AY, False)];
end;

procedure TMonorailLineTests.TestStopsInsideTheMouths;
begin
  var Line := MonorailLine(FDef);
  Assert.AreEqual(160.0, Line.LeftMouth, Slack, 'The left mouth, three quarters in');
  Assert.AreEqual(420.0, Line.RightMouth, Slack, 'The right mouth, a quarter in');
  Assert.AreEqual(130.0, Line.LeftStop, Slack, 'The nose inside the left station');
  Assert.AreEqual(390.0, Line.RightStop, Slack, 'The nose inside the right station');
  Assert.AreEqual(266.0, Line.Depth, Slack, 'At the stations'' depth');
end;

procedure TMonorailLineTests.TestTheMouthFacesTheBeam;
begin
  PlaceStations(BaseLine, False);
  var Line := MonorailLine(FDef);
  Assert.AreEqual(120.0, Line.LeftMouth, Slack, 'Unmirrored, a quarter in from its left');
end;

procedure TMonorailLineTests.TestAtDepthTheLineDrawsToTheMiddle;
begin
  PlaceStations(HalfwayY, True);
  var Line := MonorailLine(FDef);
  Assert.AreEqual(0.5, Line.Nearness, Slack, 'Halfway to the horizon');
  // Its centre at 140, halfway to the middle at 256: 198, less half its width
  Assert.AreEqual(158.0 + 60, Line.LeftMouth, Slack, 'The left mouth');
  Assert.AreEqual(308.0 + 20, Line.RightMouth, Slack, 'The right mouth');
end;

procedure TMonorailLineTests.TestStationsListedRightToLeft;
begin
  var Elements := FDef.Layers[0].Elements;
  FDef.Layers[0].Elements := [Elements[2], Elements[1], Elements[0]];
  var Line := MonorailLine(FDef);
  Assert.AreEqual(130.0, Line.LeftStop, Slack, 'The left stop still at the left');
  Assert.AreEqual(390.0, Line.RightStop, Slack, 'The right stop still at the right');
end;

// Called straight, not through Assert.WillRaise: the anonymous method
// that drops the line's record finds no overload of it
procedure TMonorailLineTests.TestStationsAtTwoDepthsRaise;
begin
  FDef.Layers[0].Elements[2].DepthY := HalfwayY;
  var Raised := False;
  try
    MonorailLine(FDef);
  except
    on EFarPlaneError do
      Raised := True;
  end;
  Assert.IsTrue(Raised, 'Two depths raise');
end;

procedure TMonorailLineTests.TestStopsWithoutARunRaise;
begin
  FDef.Train.Inside := -200;
  var Raised := False;
  try
    MonorailLine(FDef);
  except
    on EFarPlaneError do
      Raised := True;
  end;
  Assert.IsTrue(Raised, 'No run raises');
end;

procedure TMonorailLineTests.TestShownWholeBetweenTheMouths;
begin
  var Line := MonorailLine(FDef);
  var Shown := TrainShown(FDef.Train, Line, 250);
  Assert.AreEqual(0.0, Shown.From, Slack, 'From its left end');
  Assert.AreEqual(1.0, Shown.Till, Slack, 'To its right end');
end;

procedure TMonorailLineTests.TestCutAtTheLeftMouth;
begin
  var Line := MonorailLine(FDef);
  var Shown := TrainShown(FDef.Train, Line, Line.LeftStop);
  Assert.AreEqual(TrainInside / TrainW, Shown.From, Slack, 'What is inside is not shown');
  Assert.AreEqual(1.0, Shown.Till, Slack, 'Its tail out on the beam');
  Assert.IsTrue(Shown.Any, 'Shown');
end;

procedure TMonorailLineTests.TestCutAtTheRightMouth;
begin
  var Line := MonorailLine(FDef);
  var Shown := TrainShown(FDef.Train, Line, Line.RightStop);
  Assert.AreEqual(0.0, Shown.From, Slack, 'Its tail out on the beam');
  Assert.AreEqual(1 - TrainInside / TrainW, Shown.Till, Slack, 'What is inside is not shown');
  Assert.IsFalse(TrainShown(FDef.Train, Line, Line.RightMouth + 1).Any,
    'Nothing past the right mouth');
end;

initialization
  TDUnitX.RegisterTestFixture(TTrainRunTests);
  TDUnitX.RegisterTestFixture(TMonorailLineTests);

end.
