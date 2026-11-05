{
  Tests.Game.Heartbeat - the heartbeat of the last of the charge: its
  tempo is 60 a minute at 97, 90 at full, straight between, and holds
  outside them; the first tick strikes, then a beat once a minute's worth
  of the tempo is gathered - once a second at 60, every 22 ticks at 90 -
  and a change of tempo keeps what was gathered; a stop strikes again at
  once; the pulse peaks on the beat, the second thump comes DubTicks
  later and weaker, and both are gone before the next beat; a still heart
  has no pulse. The tempo of the rite of the eclipse is 90 with its ring
  empty, 140 with it full, straight between, held outside; the ticks since
  a beat count from it, and a still heart has none.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Game.Heartbeat;

interface

uses
  DUnitX.TestFramework,
  Game.Heartbeat;

type
  [TestFixture]
  THeartbeatTempoTests = class
  public
    [Test]
    procedure TestSixtyAtTheHeartbeatsCharge;
    [Test]
    procedure TestNinetyAtFull;
    [Test]
    procedure TestStraightBetween;
    [Test]
    procedure TestHoldsOutsideTheLastPercents;
    [Test]
    procedure TestTheRiteStartsWhereTheChargeLeftIt;
    [Test]
    procedure TestTheRiteBeatsAtHundredFortyWithTheRingFull;
    [Test]
    procedure TestTheRiteGoesStraightBetween;
    [Test]
    procedure TestTheRiteHoldsOutsideItsRing;
  end;

  [TestFixture]
  THeartbeatTests = class
  private
    FHeart: THeartbeat;
    // The ticks that struck over ATicks at ATempo, counted from 0
    function Strikes(ATicks: Integer; ATempo: Single): TArray<Integer>;
    // The ticks till the next strike at ATempo
    function TicksToStrike(ATempo: Single): Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestTheFirstTickStrikes;
    [Test]
    procedure TestSixtyStrikesOnceASecond;
    [Test]
    procedure TestNinetyStrikesEveryTwentyTwoTicks;
    [Test]
    procedure TestAFasterTempoKeepsWhatWasGathered;
    [Test]
    procedure TestAStopStrikesAgainAtOnce;
    [Test]
    procedure TestThePulsePeaksOnTheBeat;
    [Test]
    procedure TestTheSecondThumpIsWeaker;
    [Test]
    procedure TestThePulseDiesBeforeTheNextBeat;
    [Test]
    procedure TestAStillHeartHasNoPulse;
    [Test]
    procedure TestTheTicksSinceABeatCountFromIt;
    [Test]
    procedure TestAStillHeartHasNoBeatToCountFrom;
  end;

implementation

uses
  System.Generics.Collections;

const
  TempoSlop: Double = 0.001;
  PulseSlop: Double = 0.001;
  SecondTicks = 33;
  // A beat at the fastest tempo of the last percents
  FastBeatTicks = 22;

procedure THeartbeatTempoTests.TestSixtyAtTheHeartbeatsCharge;
begin
  Assert.AreEqual(60.0, Double(ChargeTempo(HeartbeatCharge)), TempoSlop);
end;

procedure THeartbeatTempoTests.TestNinetyAtFull;
begin
  Assert.AreEqual(90.0, Double(ChargeTempo(100)), TempoSlop);
end;

procedure THeartbeatTempoTests.TestStraightBetween;
begin
  Assert.AreEqual(70.0, Double(ChargeTempo(98)), TempoSlop, '98');
  Assert.AreEqual(80.0, Double(ChargeTempo(99)), TempoSlop, '99');
end;

procedure THeartbeatTempoTests.TestHoldsOutsideTheLastPercents;
begin
  Assert.AreEqual(60.0, Double(ChargeTempo(50)), TempoSlop, 'Below');
  Assert.AreEqual(90.0, Double(ChargeTempo(120)), TempoSlop, 'Above');
end;

procedure THeartbeatTempoTests.TestTheRiteStartsWhereTheChargeLeftIt;
begin
  Assert.AreEqual(Double(ChargeTempo(100)), Double(RiteTempo(0)), TempoSlop);
end;

procedure THeartbeatTempoTests.TestTheRiteBeatsAtHundredFortyWithTheRingFull;
begin
  Assert.AreEqual(140.0, Double(RiteTempo(1)), TempoSlop);
end;

procedure THeartbeatTempoTests.TestTheRiteGoesStraightBetween;
begin
  Assert.AreEqual(115.0, Double(RiteTempo(0.5)), TempoSlop, 'Half');
  Assert.AreEqual(100.0, Double(RiteTempo(0.2)), TempoSlop, 'A fifth');
end;

procedure THeartbeatTempoTests.TestTheRiteHoldsOutsideItsRing;
begin
  Assert.AreEqual(90.0, Double(RiteTempo(-1)), TempoSlop, 'Below');
  Assert.AreEqual(140.0, Double(RiteTempo(2)), TempoSlop, 'Above');
end;

procedure THeartbeatTests.Setup;
begin
  FHeart := THeartbeat.Create;
end;

procedure THeartbeatTests.TearDown;
begin
  FHeart.Free;
end;

function THeartbeatTests.Strikes(ATicks: Integer;
  ATempo: Single): TArray<Integer>;
begin
  var Struck := TList<Integer>.Create;
  try
    for var i := 0 to ATicks - 1 do
    begin
      FHeart.Tick(ATempo);
      if FHeart.Struck then
        Struck.Add(i);
    end;
    Result := Struck.ToArray;
  finally
    Struck.Free;
  end;
end;

function THeartbeatTests.TicksToStrike(ATempo: Single): Integer;
const
  GiveUpTicks = 1000;
begin
  for var i := 1 to GiveUpTicks do
  begin
    FHeart.Tick(ATempo);
    if FHeart.Struck then
      Exit(i);
  end;
  Result := -1;
end;

procedure THeartbeatTests.TestTheFirstTickStrikes;
begin
  FHeart.Tick(60);
  Assert.IsTrue(FHeart.Struck, 'Struck at once');
  Assert.IsTrue(FHeart.Running, 'Beating');
  FHeart.Tick(60);
  Assert.IsFalse(FHeart.Struck, 'Not again the next tick');
end;

procedure THeartbeatTests.TestSixtyStrikesOnceASecond;
begin
  var Struck := Strikes(3 * SecondTicks, 60);
  Assert.AreEqual(3, Length(Struck), 'Three beats in three seconds');
  Assert.AreEqual(0, Struck[0], 'The first at once');
  Assert.AreEqual(SecondTicks, Struck[1], 'A second later');
  Assert.AreEqual(2 * SecondTicks, Struck[2], 'Another second later');
end;

procedure THeartbeatTests.TestNinetyStrikesEveryTwentyTwoTicks;
begin
  var Struck := Strikes(3 * FastBeatTicks, 90);
  Assert.AreEqual(3, Length(Struck), 'Three beats');
  Assert.AreEqual(FastBeatTicks, Struck[1], 'The second');
  Assert.AreEqual(2 * FastBeatTicks, Struck[2], 'The third');
end;

// Half a beat gathered at 60 leaves half a beat at 90 to go: 11 ticks and
// a third, struck on the twelfth - not a whole new beat of 22, not the
// 17 left at the old tempo
procedure THeartbeatTests.TestAFasterTempoKeepsWhatWasGathered;
const
  HalfASlowBeat = 16;
  RestAtNinety = 12;
begin
  FHeart.Tick(60);
  for var i := 1 to HalfASlowBeat do
    FHeart.Tick(60);
  Assert.AreEqual(RestAtNinety, TicksToStrike(90));
end;

procedure THeartbeatTests.TestAStopStrikesAgainAtOnce;
begin
  Strikes(10, 60);
  FHeart.Stop;
  Assert.IsFalse(FHeart.Running, 'Still');
  Assert.IsFalse(FHeart.Struck, 'No beat stays struck');
  FHeart.Tick(60);
  Assert.IsTrue(FHeart.Struck, 'At once again');
end;

procedure THeartbeatTests.TestThePulsePeaksOnTheBeat;
begin
  FHeart.Tick(60);
  Assert.AreEqual(1.0, Double(FHeart.Pulse(0)), PulseSlop, 'On the beat');
  Assert.IsTrue(FHeart.Pulse(0.5) < 1, 'Fading between ticks');
end;

procedure THeartbeatTests.TestTheSecondThumpIsWeaker;
begin
  FHeart.Tick(60);
  for var i := 1 to DubTicks - 1 do
    FHeart.Tick(60);
  var Before := FHeart.Pulse(0);
  FHeart.Tick(60);
  var Dub := FHeart.Pulse(0);
  Assert.IsTrue(Dub > Before, 'The second thump rises out of the first');
  Assert.IsTrue((Dub > 0.3) and (Dub < 1), 'Weaker than the first');
end;

procedure THeartbeatTests.TestThePulseDiesBeforeTheNextBeat;
begin
  FHeart.Tick(90);
  for var i := 1 to FastBeatTicks - 1 do
    FHeart.Tick(90);
  Assert.IsFalse(FHeart.Struck, 'The next beat still to come');
  Assert.AreEqual(0.0, Double(FHeart.Pulse(0)), PulseSlop, 'Quiet before it');
end;

procedure THeartbeatTests.TestAStillHeartHasNoPulse;
begin
  Assert.AreEqual(0.0, Double(FHeart.Pulse(0)), PulseSlop, 'Never beat');
  Strikes(5, 60);
  FHeart.Stop;
  Assert.AreEqual(0.0, Double(FHeart.Pulse(0)), PulseSlop, 'Stopped');
end;

procedure THeartbeatTests.TestTheTicksSinceABeatCountFromIt;
const
  Between = 5;
begin
  FHeart.Tick(60);
  Assert.AreEqual(0.0, Double(FHeart.SinceBeat(0)), PulseSlop, 'On the beat');
  Assert.AreEqual(0.5, Double(FHeart.SinceBeat(0.5)), PulseSlop,
    'Between ticks');
  for var i := 1 to Between do
    FHeart.Tick(60);
  Assert.AreEqual(Double(Between), Double(FHeart.SinceBeat(0)), PulseSlop,
    'Ticks on');
  Strikes(SecondTicks, 60);
  Assert.IsTrue(FHeart.SinceBeat(0) < SecondTicks - Between,
    'From the next beat on, counted anew');
end;

procedure THeartbeatTests.TestAStillHeartHasNoBeatToCountFrom;
begin
  Assert.AreEqual(-1.0, Double(FHeart.SinceBeat(0)), PulseSlop, 'Never beat');
  Strikes(5, 60);
  FHeart.Stop;
  Assert.AreEqual(-1.0, Double(FHeart.SinceBeat(0.5)), PulseSlop, 'Stopped');
end;

initialization
  TDUnitX.RegisterTestFixture(THeartbeatTempoTests);
  TDUnitX.RegisterTestFixture(THeartbeatTests);

end.
