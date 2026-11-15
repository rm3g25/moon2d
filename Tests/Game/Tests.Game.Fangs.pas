{
  Tests.Game.Fangs - the fangs of the chase over a kit and numbers of the
  tests' own, so tuning the shipped layout breaks nothing here. The first
  waits at the right edge and none shows while the road stands; each comes
  in at the right edge, the road between two within its range, and goes
  past the left one; a tall one is of a kind that may be, never two on the
  screen at once; a top stands in its corridor unless the kit cannot reach
  the bottom edge from there, and no fang ever floats; the scale stays the
  kit's; the same dice give the same row, a clear starts it again; a far
  plane without fangs sends none, and their layer runs at its own speed.
  A fang is dark in the tunnel and lighter out of it. The layout reads its
  fangs; a kit or a range that makes no sense raises.

  Flown back over, the row is rolled on to its left: nothing comes up on
  the screen as the eye turns back, each new fang comes in at the left
  edge, the road between two stays within its range and no two tall ones
  share a screen, the ones kept among them; none is let go; the same dice
  give the same row; a far plane without fangs sends none.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Game.Fangs;

interface

uses
  DUnitX.TestFramework,
  Levels.FarPlane, Game.Fangs;

type
  [TestFixture]
  TFangRowTests = class
  private
    FDef: TFarPlaneDef;
    FRow: TFangRow;
    FTravel: Double;
    // Every fang sent so far, in the order sent
    FSent: TArray<TFang>;
    // Where on the screen each was when it was sent
    FCameIn: TArray<Double>;
    procedure Ride(ATicks: Integer);
    // The eye back over the row a tick's way at a time; where the right
    // edge of each fang that came stood on the screen as it came
    function FlyBack(ATicks: Integer): TArray<Double>;
    // How many fangs of the row stand right of the left edge
    function RightOfTheLeftEdge: Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestTheFirstWaitsAtTheRightEdge;
    [Test]
    procedure TestNoneShowsWhileTheRoadStands;
    [Test]
    procedure TestEachComesInAtTheRightEdge;
    [Test]
    procedure TestTheRoadBetweenTwoIsWithinItsRange;
    [Test]
    procedure TestGoesPastTheLeftEdge;
    [Test]
    procedure TestTallOnlyOfTheKindsThatMayBe;
    [Test]
    procedure TestNeverTwoTallOnTheScreen;
    [Test]
    procedure TestSomeTallSomeLow;
    [Test]
    procedure TestATopStandsInItsCorridor;
    [Test]
    procedure TestNoFangFloats;
    [Test]
    procedure TestTheScaleStaysTheKits;
    [Test]
    procedure TestTheSameDiceGiveTheSameRow;
    [Test]
    procedure TestClearStartsTheRowAgain;
    [Test]
    procedure TestNoFangsSendsNone;
    [Test]
    procedure TestTheirLayerRunsAtItsSpeed;
    [Test]
    procedure TestTurnedBackNothingComesUpOnTheScreen;
    [Test]
    procedure TestFlownBackEachComesInAtTheLeftEdge;
    [Test]
    procedure TestFlownBackTheRoadBetweenTwoIsWithinItsRange;
    [Test]
    procedure TestFlownBackNeverTwoTallOnTheScreen;
    [Test]
    procedure TestFlownBackNoneIsLetGo;
    [Test]
    procedure TestFlownBackTheSameDiceGiveTheSameRow;
    [Test]
    procedure TestNoFangsFlownBackSendsNone;
  end;

  [TestFixture]
  TFangTintTests = class
  private
    FDef: TFarPlaneDef;
    function TintWithTunnelAt(AOffset: Double; AJitter: Integer): Integer;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure TestDarkWhileTheTunnelIsAllOnTheScreen;
    [Test]
    procedure TestTheCommonTintOnceTheTunnelHasLeft;
    [Test]
    procedure TestTheJitterStraysWithinAPercent;
  end;

  [TestFixture]
  TFangReadTests = class
  public
    [Test]
    procedure TestLevelTwoRidesFangs;
    [Test]
    procedure TestNoSectionNoFangs;
    [Test]
    procedure TestAnEmptyKitRaises;
    [Test]
    procedure TestAFangWithoutHeightRaises;
    [Test]
    procedure TestARangeTheWrongWayRaises;
    [Test]
    procedure TestAScaleOfZeroRaises;
  end;

implementation

uses
  System.SysUtils, System.IOUtils, System.JSON, System.Math,
  Levels.Defs, Game.Belt, Game.FarPlane;

const
  LevelTwoFile = 'level2.json';
  TestSeed = 12345;
  Speed = 20;
  // The fangs' layer a tick at that speed
  Step = Speed / FarPlaneTicksPerSecond;
  // About ten minutes of chase
  LongRide = 20000;
  // The eye's way back over the row, as long
  BackRide = LongRide;
  ScaleLeast = 0.5;
  ScaleMost = 0.8;
  GapLeast = 50;
  GapMost = 150;
  LowTopHighest = 260;
  LowTopLowest = 300;
  TallTopHighest = 150;
  TallTopLowest = 190;
  DarkInTunnel = 30;
  Outside = 60;
  Slack = 0.001;

function BinDir: string;
begin
  Result := ExtractFilePath(ParamStr(0));
end;

function ReadFromLayout(const ALayout: string): TFarPlaneDef;
begin
  var Dir := TPath.GetTempPath;
  var Name := 'moon2d-fangs-' + TGUID.NewGuid.ToString + '.json';
  TFile.WriteAllText(TPath.Combine(Dir, Name), ALayout, TEncoding.ASCII);
  var Root := TJSONObject.ParseJSONValue(
    '{"farPlane": {"screen": 1, "layout": "' + Name + '"}}') as TJSONObject;
  try
    Result := ReadFarPlane(Root, 'test', Dir);
  finally
    Root.Free;
    TFile.Delete(TPath.Combine(Dir, Name));
  end;
end;

// A city to make the layout whole, a tunnel of one screen for the tint,
// AFangs after them
function FangLayout(const AFangs: string): string;
begin
  Result := '{"screen": {"w": 512, "h": 384},'
    + '"sun": {"x": 288, "y": 208, "disc": 7, "halo": 120,'
    + ' "white": [255, 250, 240], "tint": [255, 128, 112]},'
    + '"speeds": {"tunnelPeak": 6, "tunnelCruise": 6, "easeSec": 3,'
    + ' "cityShareInTunnel": 0.5, "cityCruise": 3, "cityBrakeZone": 512,'
    + ' "cityLeast": 0.3, "ridgeShareOfCity": 0.35, "ground": 14, "fangs": 20},'
    + '"layers": ['
    + '{"id": "city", "speed": "city", "length": 2688},'
    + '{"id": "tunnel", "speed": "tunnel", "elements": ['
    + ' {"id": "wall", "x": 0, "y": 384, "w": 512, "existing": "wall"}]}]'
    + AFangs + '}';
end;

// A thin tall kind and a broad low one
function FangSection(const AKit, AScale, AGap: string): string;
begin
  Result := ', "fangs": {"kit": [' + AKit + '],'
    + ' "scale": ' + AScale + ', "gap": ' + AGap + ','
    + ' "lowTop": [260, 300], "tallTop": [150, 190], "tallShare": 0.5,'
    + ' "tintInTunnel": [30, 30, 30], "tint": [60, 60, 60], "tintJitter": 4}';
end;

const
  TestKit = '{"sprite": "kit:thin", "w": 40, "h": 300, "tall": true},'
    + '{"sprite": "kit:broad", "w": 200, "h": 100}';

function FangFarPlane: TFarPlaneDef;
begin
  Result := ReadFromLayout(FangLayout(FangSection(TestKit, '[0.5, 0.8]', '[50, 150]')));
end;

function SameFang(const A, B: TFang): Boolean;
begin
  Result := (A.Kind = B.Kind) and SameValue(A.X, B.X) and SameValue(A.Top, B.Top)
    and SameValue(A.W, B.W) and (A.Tall = B.Tall) and (A.Mirror = B.Mirror)
    and (A.Jitter = B.Jitter);
end;

// TFangRowTests

procedure TFangRowTests.Setup;
begin
  FDef := FangFarPlane;
  FRow := TFangRow.Create(FDef, TestSeed);
  FTravel := 0;
  FSent := [];
  FCameIn := [];
end;

procedure TFangRowTests.TearDown;
begin
  FRow.Free;
end;

// The fangs' layer at its speed, every new fang noted as it comes
procedure TFangRowTests.Ride(ATicks: Integer);
begin
  for var i := 1 to ATicks do
  begin
    FTravel := FTravel + Step;
    FRow.Tick(FTravel);
    for var Fang in FRow.Fangs do
      if (Length(FSent) = 0) or (Fang.X > FSent[High(FSent)].X) then
      begin
        FSent := FSent + [Fang];
        FCameIn := FCameIn + [Fang.X - FTravel];
      end;
  end;
end;

function TFangRowTests.FlyBack(ATicks: Integer): TArray<Double>;
begin
  Result := [];
  for var i := 1 to ATicks do
  begin
    var Before := Length(FRow.Fangs);
    FTravel := FTravel - Step;
    FRow.FlyBack(FTravel);
    for var j := 0 to Length(FRow.Fangs) - Before - 1 do
    begin
      var Came := FRow.Fangs[j];
      var RightEdge: Double := Came.X + Came.W - FTravel;
      Result := Result + [RightEdge];
    end;
  end;
end;

function TFangRowTests.RightOfTheLeftEdge: Integer;
begin
  Result := 0;
  for var Fang in FRow.Fangs do
    if Fang.X + Fang.W - FTravel > Slack then
      Inc(Result);
end;

procedure TFangRowTests.TestTheFirstWaitsAtTheRightEdge;
begin
  FRow.Tick(0);
  Assert.IsTrue(Length(FRow.Fangs) > 0, 'One is sent at once');
  Assert.AreEqual(Double(FDef.ScreenWidth), Double(FRow.Fangs[0].X), Slack);
end;

procedure TFangRowTests.TestNoneShowsWhileTheRoadStands;
begin
  for var i := 1 to 100 do
    FRow.Tick(0);
  for var Fang in FRow.Fangs do
    Assert.IsTrue(Fang.X >= FDef.ScreenWidth, 'Beyond the right edge');
end;

procedure TFangRowTests.TestEachComesInAtTheRightEdge;
begin
  Ride(LongRide);
  for var Place in FCameIn do
  begin
    Assert.IsTrue(Place <= FDef.ScreenWidth, 'Not sent ahead of its time');
    Assert.IsTrue(Place > FDef.ScreenWidth - Step - Slack, 'Not sent late, inside');
  end;
end;

procedure TFangRowTests.TestTheRoadBetweenTwoIsWithinItsRange;
begin
  Ride(LongRide);
  for var i := 1 to High(FSent) do
  begin
    var Gap := FSent[i].X - (FSent[i - 1].X + FSent[i - 1].W);
    Assert.IsTrue((Gap >= GapLeast - Slack) and (Gap <= GapMost + Slack),
      Format('Fang %d: %g', [i, Gap]));
  end;
end;

procedure TFangRowTests.TestGoesPastTheLeftEdge;
begin
  Ride(LongRide);
  for var Fang in FRow.Fangs do
    Assert.IsTrue(Fang.X + Fang.W - FTravel > 0, 'None kept past the left edge');
  Assert.IsTrue(Length(FRow.Fangs) < Length(FSent), 'The passed are let go');
end;

procedure TFangRowTests.TestTallOnlyOfTheKindsThatMayBe;
begin
  Ride(LongRide);
  for var Fang in FSent do
    if Fang.Tall then
      Assert.IsTrue(FDef.Fangs.Kinds[Fang.Kind].Tall, 'A kind that may be tall');
end;

procedure TFangRowTests.TestNeverTwoTallOnTheScreen;
begin
  Ride(LongRide);
  var LastTallEnd: Double := -MaxInt;
  for var Fang in FSent do
  begin
    if not Fang.Tall then
      Continue;
    Assert.IsTrue(Fang.X - LastTallEnd >= FDef.ScreenWidth - Slack,
      'A screen of road after the last tall one');
    LastTallEnd := Fang.X + Fang.W;
  end;
end;

procedure TFangRowTests.TestSomeTallSomeLow;
begin
  Ride(LongRide);
  var Tall := 0;
  for var Fang in FSent do
    if Fang.Tall then
      Inc(Tall);
  Assert.IsTrue(Tall > 0, 'Some tall');
  Assert.IsTrue(Tall < Length(FSent), 'Some low');
end;

procedure TFangRowTests.TestATopStandsInItsCorridor;
begin
  Ride(LongRide);
  for var Fang in FSent do
  begin
    var Highest: Single := LowTopHighest;
    var Lowest: Single := LowTopLowest;
    if Fang.Tall then
    begin
      Highest := TallTopHighest;
      Lowest := TallTopLowest;
    end;
    var Sunk := SameValue(Fang.Top, FDef.ScreenHeight - Fang.H, Slack);
    Assert.IsTrue(Fang.Top >= Highest - Slack, 'Not over its corridor');
    Assert.IsTrue((Fang.Top <= Lowest + Slack) or Sunk,
      'Under its corridor only when the kit could not reach the bottom edge');
  end;
end;

procedure TFangRowTests.TestNoFangFloats;
begin
  Ride(LongRide);
  for var Fang in FSent do
    Assert.IsTrue(Fang.Top + Fang.H >= FDef.ScreenHeight - Slack, 'Feet below the edge');
end;

procedure TFangRowTests.TestTheScaleStaysTheKits;
begin
  Ride(LongRide);
  for var Fang in FSent do
  begin
    var Scale := Fang.W / FDef.Fangs.Kinds[Fang.Kind].W;
    Assert.IsTrue((Scale >= ScaleLeast - Slack) and (Scale <= ScaleMost + Slack),
      Format('Scale %g', [Scale]));
  end;
end;

procedure TFangRowTests.TestTheSameDiceGiveTheSameRow;
begin
  var Other := TFangRow.Create(FDef, TestSeed);
  try
    Ride(LongRide);
    Other.Tick(FTravel);
    Assert.AreEqual(Integer(Length(FRow.Fangs)), Integer(Length(Other.Fangs)), 'As many');
    for var i := 0 to High(FRow.Fangs) do
      Assert.IsTrue(SameFang(FRow.Fangs[i], Other.Fangs[i]), Format('Fang %d', [i]));
  finally
    Other.Free;
  end;
end;

procedure TFangRowTests.TestClearStartsTheRowAgain;
begin
  var Fresh := TFangRow.Create(FDef, TestSeed);
  try
    Ride(LongRide);
    FRow.Clear(TestSeed);
    Assert.AreEqual(0, Integer(Length(FRow.Fangs)), 'None left');
    FRow.Tick(0);
    Fresh.Tick(0);
    Assert.AreEqual(Integer(Length(Fresh.Fangs)), Integer(Length(FRow.Fangs)),
      'As many as a new row');
    for var i := 0 to High(FRow.Fangs) do
      Assert.IsTrue(SameFang(Fresh.Fangs[i], FRow.Fangs[i]), Format('Fang %d', [i]));
  finally
    Fresh.Free;
  end;
end;

procedure TFangRowTests.TestNoFangsSendsNone;
begin
  var Row := TFangRow.Create(ReadFromLayout(FangLayout('')), TestSeed);
  try
    var Travel: Double := 0;
    for var i := 1 to 1000 do
    begin
      Travel := Travel + Step;
      Row.Tick(Travel);
    end;
    Assert.AreEqual(0, Integer(Length(Row.Fangs)));
  finally
    Row.Free;
  end;
end;

procedure TFangRowTests.TestTheirLayerRunsAtItsSpeed;
const
  Seconds = 10;
begin
  var Belt := TBelt.Create;
  var Plane := TFarPlane.Create(FDef);
  try
    Belt.Start;
    for var i := 1 to BeltRampTicks + FarPlaneTicksPerSecond do
    begin
      Belt.Tick;
      Plane.Tick(Belt.Speed / BeltCruise);
    end;
    var Before := Plane.Offsets[fmFangs];
    for var i := 1 to Seconds * FarPlaneTicksPerSecond do
    begin
      Belt.Tick;
      Plane.Tick(Belt.Speed / BeltCruise);
    end;
    Assert.AreEqual(Double(Speed * Seconds), Plane.Offsets[fmFangs] - Before, 0.01);
  finally
    Plane.Free;
    Belt.Free;
  end;
end;

// The first one back may not be due yet: what is counted is the fangs
// right of the left edge, before and after
procedure TFangRowTests.TestTurnedBackNothingComesUpOnTheScreen;
begin
  Ride(LongRide);
  var Before := RightOfTheLeftEdge;
  FRow.FlyBack(FTravel);
  Assert.AreEqual(Before, RightOfTheLeftEdge, 'None new right of the left edge');
end;

procedure TFangRowTests.TestFlownBackEachComesInAtTheLeftEdge;
begin
  Ride(LongRide);
  FRow.FlyBack(FTravel);
  var CameIn := FlyBack(BackRide);
  Assert.IsTrue(Length(CameIn) > 0, 'Some came');
  for var RightEdge in CameIn do
  begin
    Assert.IsTrue(RightEdge >= -Slack, 'Not sent ahead of its time');
    Assert.IsTrue(RightEdge < Step + Slack, 'Not sent late, inside');
  end;
end;

procedure TFangRowTests.TestFlownBackTheRoadBetweenTwoIsWithinItsRange;
begin
  Ride(LongRide);
  FlyBack(BackRide);
  // The row keeps its fangs left to right
  var Row := FRow.Fangs;
  for var i := 1 to High(Row) do
  begin
    var Gap := Row[i].X - (Row[i - 1].X + Row[i - 1].W);
    Assert.IsTrue((Gap >= GapLeast - Slack) and (Gap <= GapMost + Slack),
      Format('Fang %d: %g', [i, Gap]));
  end;
end;

procedure TFangRowTests.TestFlownBackNeverTwoTallOnTheScreen;
begin
  Ride(LongRide);
  FlyBack(BackRide);
  var Tall := 0;
  var LastTallEnd: Double := -MaxInt;
  for var Fang in FRow.Fangs do
  begin
    if not Fang.Tall then
      Continue;
    Inc(Tall);
    Assert.IsTrue(Fang.X - LastTallEnd >= FDef.ScreenWidth - Slack,
      'A screen of road between two tall ones');
    LastTallEnd := Fang.X + Fang.W;
  end;
  Assert.IsTrue(Tall > 1, 'Tall ones among them');
end;

procedure TFangRowTests.TestFlownBackNoneIsLetGo;
begin
  Ride(LongRide);
  var Kept := Length(FRow.Fangs);
  for var i := 1 to BackRide do
  begin
    FTravel := FTravel - Step;
    FRow.FlyBack(FTravel);
    Assert.IsTrue(Length(FRow.Fangs) >= Kept, 'None gone');
    Kept := Length(FRow.Fangs);
  end;
end;

procedure TFangRowTests.TestFlownBackTheSameDiceGiveTheSameRow;
begin
  var Other := TFangRow.Create(FDef, TestSeed);
  try
    Ride(LongRide);
    Other.Tick(FTravel);
    // Both turned back at the same place: the first one back stands by it
    FRow.FlyBack(FTravel);
    Other.FlyBack(FTravel);
    FlyBack(BackRide);
    Other.FlyBack(FTravel);
    Assert.AreEqual(Integer(Length(FRow.Fangs)), Integer(Length(Other.Fangs)), 'As many');
    for var i := 0 to High(FRow.Fangs) do
      Assert.IsTrue(SameFang(FRow.Fangs[i], Other.Fangs[i]), Format('Fang %d', [i]));
  finally
    Other.Free;
  end;
end;

procedure TFangRowTests.TestNoFangsFlownBackSendsNone;
begin
  var Row := TFangRow.Create(ReadFromLayout(FangLayout('')), TestSeed);
  try
    Row.FlyBack(-LongRide);
    Assert.AreEqual(0, Integer(Length(Row.Fangs)));
  finally
    Row.Free;
  end;
end;

// TFangTintTests

procedure TFangTintTests.Setup;
begin
  FDef := FangFarPlane;
end;

function TFangTintTests.TintWithTunnelAt(AOffset: Double; AJitter: Integer): Integer;
begin
  var Offsets := Default(TFarPlaneOffsets);
  Offsets[fmTunnel] := AOffset;
  Result := FDef.FangTint(AJitter, Offsets).R;
end;

procedure TFangTintTests.TestDarkWhileTheTunnelIsAllOnTheScreen;
begin
  Assert.AreEqual(DarkInTunnel, TintWithTunnelAt(0, 0));
end;

procedure TFangTintTests.TestTheCommonTintOnceTheTunnelHasLeft;
begin
  Assert.AreEqual(Outside, TintWithTunnelAt(FDef.TunnelEnd, 0), 'As it leaves');
  Assert.AreEqual((DarkInTunnel + Outside) div 2, TintWithTunnelAt(FDef.TunnelEnd / 2, 0),
    'Halfway');
end;

procedure TFangTintTests.TestTheJitterStraysWithinAPercent;
begin
  Assert.AreEqual(Outside + 4, TintWithTunnelAt(FDef.TunnelEnd, 4), 'Up');
  Assert.AreEqual(Outside - 4, TintWithTunnelAt(FDef.TunnelEnd, -4), 'Down');
  Assert.AreEqual(100, TintWithTunnelAt(FDef.TunnelEnd, 60), 'Never past the full');
end;

// TFangReadTests

procedure TFangReadTests.TestLevelTwoRidesFangs;
begin
  var Level := TLevel.Create;
  try
    Level.LoadFromFile(TPath.Combine(BinDir, LevelTwoFile));
    var Plane := Level.FarPlane;
    Assert.IsTrue(Plane.Fangs.Present, 'A kit');
    Assert.IsTrue(Plane.Speeds.Fangs > Plane.Speeds.Ground, 'In front of the near ground');
    var AnyTall := False;
    for var Kind in Plane.Fangs.Kinds do
      AnyTall := AnyTall or Kind.Tall;
    Assert.IsTrue(AnyTall, 'A kind that may stand tall');
  finally
    Level.Free;
  end;
end;

procedure TFangReadTests.TestNoSectionNoFangs;
begin
  Assert.IsFalse(ReadFromLayout(FangLayout('')).Fangs.Present);
end;

procedure TFangReadTests.TestAnEmptyKitRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      ReadFromLayout(FangLayout(FangSection('', '[0.5, 0.8]', '[50, 150]')));
    end, EFarPlaneError);
end;

procedure TFangReadTests.TestAFangWithoutHeightRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      ReadFromLayout(FangLayout(FangSection('{"sprite": "kit:flat", "w": 40}',
        '[0.5, 0.8]', '[50, 150]')));
    end, EFarPlaneError);
end;

procedure TFangReadTests.TestARangeTheWrongWayRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      ReadFromLayout(FangLayout(FangSection(TestKit, '[0.5, 0.8]', '[150, 50]')));
    end, EFarPlaneError);
end;

procedure TFangReadTests.TestAScaleOfZeroRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      ReadFromLayout(FangLayout(FangSection(TestKit, '[0, 0.8]', '[50, 150]')));
    end, EFarPlaneError);
end;

initialization
  TDUnitX.RegisterTestFixture(TFangRowTests);
  TDUnitX.RegisterTestFixture(TFangTintTests);
  TDUnitX.RegisterTestFixture(TFangReadTests);

end.
