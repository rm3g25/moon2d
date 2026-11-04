{
  Tests.Hud.Energy - the reading of the form's charge: no slot without a
  charge; the first of it opens the slot, which folds back once the
  charge is gone; the arc eases up to a rise and flashes, and stands on a
  fall at once. The ride of the last of the charge: in the slot until it
  is lifted, from the slot to the top centre where the level's title
  stands, growing to three times its size, eased so that halfway is half
  of both; there it stays, a dock is at once, and a lift starts the way
  over. And the words of the event that gives the charge - the
  energy action and its value - and the moon stone of level 2, which
  gives five.

  The reading is ticked and read, the gauge is not drawn: that needs a
  renderer. Level 2 is read from level2.json beside the executable.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Hud.Energy;

interface

uses
  DUnitX.TestFramework,
  Sdl2.Core,
  Hud.Energy;

type
  [TestFixture]
  TEnergyReadingTests = class
  private
    FReading: TEnergyReading;
    procedure TickTimes(ACount, ACharge: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestNoChargeNoSlot;
    [Test]
    procedure TestFirstChargeOpensSlotSlowly;
    [Test]
    procedure TestArcEasesUpToCharge;
    [Test]
    procedure TestRiseFlashesAndFades;
    [Test]
    procedure TestFallIsShownAtOnceWithoutFlash;
    [Test]
    procedure TestChargeGoneFoldsSlot;
  end;

  [TestFixture]
  TGaugeRideTests = class
  private
    FRide: TGaugeRide;
    procedure TickTimes(ACount: Integer);
    procedure ExpectAt(const APoint: TSdlFPoint; AScale: Single;
      const AWhere: string);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestDockedItSitsInTheSlot;
    [Test]
    procedure TestLiftedItStartsFromTheSlot;
    [Test]
    procedure TestItRidesToTheTitleThreeTimesAsBig;
    [Test]
    procedure TestHalfwayIsHalfOfTheWayAndTheGrowth;
    [Test]
    procedure TestUpItStays;
    [Test]
    procedure TestADockIsAtOnce;
    [Test]
    procedure TestALiftAfterTheRideStartsOver;
  end;

  [TestFixture]
  TEnergyLevelTests = class
  public
    [Test]
    procedure TestEnergyActionIsRead;
    [Test]
    procedure TestEnergyOutsideOneToHundredRaises;
    [Test]
    procedure TestMoonStoneGivesFive;
  end;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  System.JSON,
  Game.Space,
  Render.Font,
  Hud.Messages,
  Levels.Defs,
  Levels.Events;

const
  WingTicks = 8;
  FlashTicks = 14;
  RideTicks = 66;
  RideScale = 3;
  PlaceSlop: Double = 0.01;
  // Long enough for the arc to stand on any charge
  SettleTicks = 200;

procedure TEnergyReadingTests.Setup;
begin
  FReading := TEnergyReading.Create;
end;

procedure TEnergyReadingTests.TearDown;
begin
  FReading.Free;
end;

procedure TEnergyReadingTests.TickTimes(ACount, ACharge: Integer);
begin
  for var i := 1 to ACount do
    FReading.Tick(ACharge);
end;

procedure TEnergyReadingTests.TestNoChargeNoSlot;
begin
  TickTimes(SettleTicks, 0);
  Assert.AreEqual<Single>(0, FReading.Wing, 'No slot');
  Assert.AreEqual<Single>(0, FReading.Arc, 'No arc');
  Assert.AreEqual<Single>(0, FReading.Flash, 'No flash');
end;

procedure TEnergyReadingTests.TestFirstChargeOpensSlotSlowly;
begin
  FReading.Tick(1);
  var First := FReading.Wing;
  TickTimes(WingTicks - 2, 1);
  var Before := FReading.Wing;
  FReading.Tick(1);
  Assert.IsTrue((First > 0) and (First < 0.5), 'Opening, not open');
  Assert.IsTrue(Before < 1, 'Not yet open a tick before');
  Assert.AreEqual<Single>(1, FReading.Wing, 'Open after its ticks');
end;

procedure TEnergyReadingTests.TestArcEasesUpToCharge;
begin
  FReading.Tick(5);
  var First := FReading.Arc;
  TickTimes(SettleTicks, 5);
  Assert.IsTrue((First > 0) and (First < 5), 'Eased, not jumped');
  Assert.AreEqual<Single>(5, FReading.Arc, 'Stands on the charge');
  Assert.AreEqual(5, FReading.Charge, 'The charge read');
end;

procedure TEnergyReadingTests.TestRiseFlashesAndFades;
begin
  FReading.Tick(0);
  FReading.Tick(5);
  var Flashed := FReading.Flash;
  TickTimes(FlashTicks, 5);
  Assert.AreEqual<Single>(1, Flashed, 'Full at the rise');
  Assert.AreEqual<Single>(0, FReading.Flash, 'Gone after its ticks');
end;

procedure TEnergyReadingTests.TestFallIsShownAtOnceWithoutFlash;
begin
  TickTimes(SettleTicks, 50);
  FReading.Tick(5);
  Assert.AreEqual<Single>(5, FReading.Arc, 'At once');
  Assert.AreEqual<Single>(0, FReading.Flash, 'No flash for a fall');
end;

procedure TEnergyReadingTests.TestChargeGoneFoldsSlot;
begin
  TickTimes(SettleTicks, 5);
  FReading.Tick(0);
  var Folding := FReading.Wing;
  TickTimes(WingTicks, 0);
  Assert.IsTrue((Folding > 0) and (Folding < 1), 'Folding, not gone');
  Assert.AreEqual<Single>(0, FReading.Wing, 'Folded');
  Assert.AreEqual<Single>(0, FReading.Arc, 'No arc');
end;

function TitleMiddle: TSdlFPoint;
begin
  Result.X := FrameWidth / 2;
  Result.Y := BigMessageY + BigGlyphHeight / 2;
end;

function Halfway(const AFrom, ATo: TSdlFPoint): TSdlFPoint;
begin
  Result.X := (AFrom.X + ATo.X) / 2;
  Result.Y := (AFrom.Y + ATo.Y) / 2;
end;

procedure TGaugeRideTests.Setup;
begin
  FRide := TGaugeRide.Create;
end;

procedure TGaugeRideTests.TearDown;
begin
  FRide.Free;
end;

procedure TGaugeRideTests.TickTimes(ACount: Integer);
begin
  for var i := 1 to ACount do
    FRide.Tick;
end;

procedure TGaugeRideTests.ExpectAt(const APoint: TSdlFPoint; AScale: Single;
  const AWhere: string);
begin
  var Center := FRide.Center(0);
  Assert.AreEqual(Double(APoint.X), Double(Center.X), PlaceSlop, AWhere + ': across');
  Assert.AreEqual(Double(APoint.Y), Double(Center.Y), PlaceSlop, AWhere + ': down');
  Assert.AreEqual(Double(AScale), Double(FRide.Scale(0)), PlaceSlop, AWhere + ': size');
end;

procedure TGaugeRideTests.TestDockedItSitsInTheSlot;
begin
  TickTimes(RideTicks);
  ExpectAt(THudEnergy.Heart, 1, 'In the slot');
  Assert.IsFalse(FRide.Lifted, 'Not lifted');
  Assert.IsFalse(FRide.Up, 'Not up');
end;

procedure TGaugeRideTests.TestLiftedItStartsFromTheSlot;
begin
  FRide.Lift;
  ExpectAt(THudEnergy.Heart, 1, 'At the lift');
  Assert.IsTrue(FRide.Lifted, 'Lifted');
  Assert.IsFalse(FRide.Up, 'Its way ahead of it');
end;

procedure TGaugeRideTests.TestItRidesToTheTitleThreeTimesAsBig;
begin
  FRide.Lift;
  TickTimes(RideTicks - 1);
  var Before := FRide.Up;
  FRide.Tick;
  Assert.IsFalse(Before, 'Still on its way a tick before');
  Assert.IsTrue(FRide.Up, 'Up after its ticks');
  ExpectAt(TitleMiddle, RideScale, 'Up');
end;

procedure TGaugeRideTests.TestHalfwayIsHalfOfTheWayAndTheGrowth;
begin
  FRide.Lift;
  TickTimes(RideTicks div 2);
  ExpectAt(Halfway(THudEnergy.Heart, TitleMiddle), (1 + RideScale) / 2,
    'Halfway');
end;

procedure TGaugeRideTests.TestUpItStays;
begin
  FRide.Lift;
  TickTimes(10 * RideTicks);
  ExpectAt(TitleMiddle, RideScale, 'Long after');
  Assert.AreEqual(Double(RideScale), Double(FRide.Scale(0.9)), PlaceSlop,
    'No growth past the way between ticks');
end;

procedure TGaugeRideTests.TestADockIsAtOnce;
begin
  FRide.Lift;
  TickTimes(RideTicks);
  FRide.Dock;
  ExpectAt(THudEnergy.Heart, 1, 'Docked');
  Assert.IsFalse(FRide.Up, 'Not up');
end;

procedure TGaugeRideTests.TestALiftAfterTheRideStartsOver;
begin
  FRide.Lift;
  TickTimes(RideTicks);
  FRide.Lift;
  ExpectAt(THudEnergy.Heart, 1, 'From the slot again');
  TickTimes(RideTicks);
  ExpectAt(TitleMiddle, RideScale, 'Up again');
end;

function EventsOf(const AJson: string): TArray<TLevelEvent>;
begin
  var Root := TJSONObject.ParseJSONValue(AJson) as TJSONObject;
  try
    Result := ParseLevelEvents(Root, 'test');
  finally
    Root.Free;
  end;
end;

// By value, not const: an anonymous method captures it
procedure ExpectRefused(AJson, AWhy: string);
begin
  Assert.WillRaise(
    procedure
    begin
      EventsOf(AJson);
    end, ELevelEventError, AWhy);
end;

procedure TEnergyLevelTests.TestEnergyActionIsRead;
begin
  var Events := EventsOf('{"events":[{"id":"e","screen":3,"when":"enterScreen",' +
    '"then":[{"action":"energy","value":5},{"action":"energy","value":100}]}]}');
  Assert.AreEqual<TEventActionKind>(eaEnergy, Events[0].Actions[0].Kind,
    'The action');
  Assert.AreEqual(5, Events[0].Actions[0].Amount, 'Its value');
  Assert.AreEqual(100, Events[0].Actions[1].Amount, 'A full charge');
end;

procedure TEnergyLevelTests.TestEnergyOutsideOneToHundredRaises;
begin
  ExpectRefused('{"events":[{"id":"n","screen":1,"when":"enterScreen",' +
    '"then":[{"action":"energy"}]}]}', 'No value');
  ExpectRefused('{"events":[{"id":"z","screen":1,"when":"enterScreen",' +
    '"then":[{"action":"energy","value":0}]}]}', 'Nothing to give');
  ExpectRefused('{"events":[{"id":"o","screen":1,"when":"enterScreen",' +
    '"then":[{"action":"energy","value":101}]}]}', 'Past full');
end;

// Taken, the stone opens the way on and gives the first of the charge -
// both in the one event that waits for the taking
procedure TEnergyLevelTests.TestMoonStoneGivesFive;
const
  LevelTwoFile = 'level2.json';
  StoneScreen = 11;
  StoneTag = 's11-stone';
  StoneCharge = 5;
begin
  var Level := TLevel.Create;
  try
    Level.LoadFromFile(TPath.Combine(ExtractFilePath(ParamStr(0)),
      LevelTwoFile));

    var Given := 0;
    var OpensDoor := False;
    for var Event in Level.Events do
    begin
      if (Event.Screen <> StoneScreen) or (Event.Condition <> ecAllDead) or
        (Event.Tag <> StoneTag) then
        Continue;
      for var Action in Event.Actions do
      begin
        if Action.Kind = eaEnergy then
          Inc(Given, Action.Amount);
        if Action.Kind = eaOpenDoor then
          OpensDoor := True;
      end;
    end;
    Assert.AreEqual(StoneCharge, Given, 'Five percent for the stone');
    Assert.IsTrue(OpensDoor, 'In the event of the taking');
  finally
    Level.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TEnergyReadingTests);
  TDUnitX.RegisterTestFixture(TGaugeRideTests);
  TDUnitX.RegisterTestFixture(TEnergyLevelTests);

end.
