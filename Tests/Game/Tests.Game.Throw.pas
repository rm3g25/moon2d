{
  Tests.Game.Throw - the scene of the throw: nothing till the burst
  starts it; a second on he is caught, once, and from then on he is held
  and the heart beats; he is carried along his way and hangs in his place
  once there, and the orbs go out then, once; still on his way, in his
  place he sways up and down, growing to its depth over the first swing
  and never past it; let go at the wheel, he is still; the spin waits for every
  pad to be held, then runs up once over four seconds and stays spun up,
  the hint coming in after it; a beat spins the pads faster, still pads
  not at all; with no pad to hold the spin runs up at once; a clear takes
  it all.

  The volley: a press is heard spun up and not before, and with none the
  pads go by themselves in three seconds; the heart stops at it and he
  stays held; every pad is let go once, within its small delay, not all
  on one tick; every pad struck, and the scene stands; with no pad, all
  is struck at once.

  The wheel: a breath after the honeycomb is down, and not before, the
  wheel is cued once and he is let go; then the scene stands, cueing
  nothing more. The honeycomb's fall is heard from the volley on. Told
  the wheel is gone off the screen, a breath on the Ram takes off, cued
  once, and the scene stands; told before the wheel is off, it is not
  heard.

  The arc of the pads: as many places as pads, all as far from the Ram's
  middle, the first up and left of it, the last right of it and over its
  middle, evenly apart, far enough apart that two of the widest spinning
  do not meet, on the screen, its top just under the top of the screen,
  as wide for a few pads as for many; one pad over the Ram. The places are taken
  by turn about the Ram, so no two ways cross.

  The pads it calls in: as many as are missing, on the decks of the
  hunt's rows inside the screen, clear of what is taken and of each other,
  each coming in from beyond the nearer edge; none where there is no room.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Game.Throw;

interface

uses
  DUnitX.TestFramework,
  Sdl2.Core,
  Game.Throw;

type
  [TestFixture]
  TThrowSceneTests = class
  private
    FScene: TThrowScene;
    // Started and ticked to the catch, the way handed in from AFrom
    procedure CatchAt(AFromX, AFromY: Single);
    // Then ticked till he is in his place, ACount pads handed in
    procedure CarryAndGrip(ACount: Integer);
    // Then every pad held, ticked to the spin's start
    procedure HoldThePads(ACount: Integer);
    // Then ticked till spun up
    procedure SpinUpThePads(ACount: Integer);
    // Then pressed, ticked to the volley, every pad struck
    procedure StrikeEveryPad(ACount: Integer);
    // Every pad struck, the honeycomb down, ticked till the wheel is off
    procedure LooseTheWheel;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestNothingTillStarted;
    [Test]
    procedure TestCaughtOnceASecondAfterTheBurst;
    [Test]
    procedure TestCarriedAlongHisWayThenInHisPlace;
    [Test]
    procedure TestTheOrbsGoOutOnceHeIsInHisPlace;
    [Test]
    procedure TestStillOnHisWaySwayingInHisPlace;
    [Test]
    procedure TestStillOnceLetGo;
    [Test]
    procedure TestTheSpinWaitsForEveryPad;
    [Test]
    procedure TestTheSpinRunsUpOnceAndStays;
    [Test]
    procedure TestTheHintComesInSpunUp;
    [Test]
    procedure TestABeatSpinsThemFaster;
    [Test]
    procedure TestNoPadTheSpinRunsUpAtOnce;
    [Test]
    procedure TestAClearTakesItAll;
    [Test]
    procedure TestThePressIsHeardSpunUpOnly;
    [Test]
    procedure TestWithNoPressTheyGoInThreeSeconds;
    [Test]
    procedure TestTheHeartStopsAtTheVolleyHeHangsOn;
    [Test]
    procedure TestEachPadLetGoOnceWithinItsDelay;
    [Test]
    procedure TestEveryPadStruckTheSceneStands;
    [Test]
    procedure TestNoPadAllStruckAtTheVolley;
    [Test]
    procedure TestTheWheelABreathAfterTheHoneycombIsDown;
    [Test]
    procedure TestLetGoAtTheWheelTheSceneStands;
    [Test]
    procedure TestTheHoneycombDownIsHeardFromTheVolleyOn;
    [Test]
    procedure TestTheWheelGoneABreathThenTheTakeoff;
    [Test]
    procedure TestTheWheelGoneIsHeardOnceItIsOff;
  end;

  [TestFixture]
  TArcTests = class
  public
    [Test]
    procedure TestAPlaceForEveryPadAllAsFar;
    [Test]
    procedure TestFromUpLeftOverTheTopToTheRight;
    [Test]
    procedure TestEvenlyApartAndNoTwoMeet;
    [Test]
    procedure TestOnTheScreen;
    [Test]
    procedure TestItsTopJustUnderTheTopOfTheScreen;
    [Test]
    procedure TestAsWideForAFewAsForMany;
    [Test]
    procedure TestOnePadOverTheRam;
    [Test]
    procedure TestTakenByTurnNoTwoWaysCross;
  end;

  [TestFixture]
  TCalledPadTests = class
  public
    [Test]
    procedure TestAsManyAsMissing;
    [Test]
    procedure TestOnTheRowsInsideTheScreen;
    [Test]
    procedure TestClearOfWhatIsTakenAndOfEachOther;
    [Test]
    procedure TestEachComesFromBeyondTheNearerEdge;
    [Test]
    procedure TestNoneWithoutRoom;
  end;

implementation

uses
  System.Math,
  System.SysUtils,
  Game.Space,
  Game.Hoist,
  Pads.Drift;

const
  Slop = 0.001;
  Road = 352.0;
  PadCount = 3;
  // Enough ticks for any stage to be over
  ManyTicks = 400;
  // The widest of the chase's pads
  Widest = 64.0;

function At(AX, AY: Single): TSdlFPoint;
begin
  Result.X := AX;
  Result.Y := AY;
end;

function Box(AX, AY, AW, AH: Single): TSdlFRect;
begin
  Result.X := AX;
  Result.Y := AY;
  Result.W := AW;
  Result.H := AH;
end;

function Overlap(const A, B: TSdlFRect): Boolean;
begin
  Result := (A.X < B.X + B.W) and (B.X < A.X + A.W) and (A.Y < B.Y + B.H) and
    (B.Y < A.Y + A.H);
end;

function CalledBody(const APad: TCalledPad): TSdlFRect;
const
  PadDepth = 12;
begin
  Result := Box(APad.Left, APad.Deck, APad.Width, PadDepth);
end;

function HeroPlace: TSdlFPoint;
begin
  Result := At(ScreenWidth - HeroPlaceEdge - 32, Road - HeroHover);
end;

function RamMiddle: TSdlFPoint;
begin
  Result := At(RamPlaceLeft + 84.5, 288);
end;

// Counter-clockwise from straight right, the screen's up being up
function TurnOf(const APoint: TSdlFPoint): Single;
begin
  Result := RadToDeg(ArcTan2(RamMiddle.Y - APoint.Y, APoint.X - RamMiddle.X));
end;

function FromRam(const APoint: TSdlFPoint): Single;
begin
  Result := Hypot(APoint.X - RamMiddle.X, APoint.Y - RamMiddle.Y);
end;

{ TThrowSceneTests }

procedure TThrowSceneTests.Setup;
begin
  FScene := TThrowScene.Create;
end;

procedure TThrowSceneTests.TearDown;
begin
  FScene.Free;
end;

procedure TThrowSceneTests.CatchAt(AFromX, AFromY: Single);
begin
  FScene.Start;
  for var i := 1 to ManyTicks do
    if FScene.Tick.Catch then
    begin
      FScene.Carry(PlanHoist(At(AFromX, AFromY), HeroPlace));
      Exit;
    end;
  Assert.Fail('Never caught');
end;

procedure TThrowSceneTests.CarryAndGrip(ACount: Integer);
begin
  CatchAt(200, Road);
  for var i := 1 to ManyTicks do
    if FScene.Tick.Grip then
    begin
      FScene.Grip(ACount);
      Exit;
    end;
  Assert.Fail('Never in his place');
end;

procedure TThrowSceneTests.HoldThePads(ACount: Integer);
begin
  CarryAndGrip(ACount);
  for var i := 1 to ACount do
    FScene.PadHeld;
  for var i := 1 to ManyTicks do
    if FScene.Tick.SpinUp then
      Exit;
  Assert.Fail('The spin never ran up');
end;

procedure TThrowSceneTests.SpinUpThePads(ACount: Integer);
begin
  HoldThePads(ACount);
  for var i := 1 to ManyTicks do
    if FScene.Tick.SpunUp then
      Exit;
  Assert.Fail('Never spun up');
end;

procedure TThrowSceneTests.StrikeEveryPad(ACount: Integer);
begin
  SpinUpThePads(ACount);
  FScene.Press;
  if not FScene.Tick.Volley then
    Assert.Fail('No volley');
  for var i := 1 to ACount do
    FScene.PadStruck;
  FScene.Tick;
end;

procedure TThrowSceneTests.TestNothingTillStarted;
begin
  for var i := 1 to ManyTicks do
  begin
    var Cue := FScene.Tick;
    Assert.IsFalse(Cue.Catch or Cue.Grip or Cue.SpinUp or Cue.SpunUp,
      Format('A cue at tick %d', [i]));
  end;
  Assert.IsFalse(FScene.Running, 'Not running');
  Assert.IsFalse(FScene.Holds, 'Not holding him');
  Assert.IsFalse(FScene.Beats, 'No heart');
end;

procedure TThrowSceneTests.TestCaughtOnceASecondAfterTheBurst;
begin
  FScene.Start;
  var Catches := 0;
  var CaughtAt := 0;
  for var i := 1 to ManyTicks do
  begin
    Assert.IsTrue(FScene.Holds = (Catches > 0), Format('Held at tick %d', [i]));
    Assert.IsTrue(FScene.Beats = (Catches > 0), Format('Beats at tick %d', [i]));
    var Cue := FScene.Tick;
    if Cue.Catch then
    begin
      Inc(Catches);
      CaughtAt := i;
    end;
    // With no way handed in and no pad, it runs on to the volley, where
    // the heart stops
    if Cue.Volley then
      Break;
  end;
  Assert.AreEqual(1, Catches, 'Once');
  Assert.AreEqual(CatchAfterTicks, CaughtAt, 'A second after the burst');
end;

procedure TThrowSceneTests.TestCarriedAlongHisWayThenInHisPlace;
begin
  CatchAt(60, 200);
  var Path := PlanHoist(At(60, 200), HeroPlace);
  for var i := 1 to Path.Ticks do
  begin
    FScene.Tick;
    var Hangs := FScene.HeroAt;
    var Expected := Path.At(i);
    Assert.AreEqual(Double(Expected.X), Double(Hangs.X), Slop, Format('Across, tick %d', [i]));
    Assert.AreEqual(Double(Expected.Y), Double(Hangs.Y), Slop, Format('Down, tick %d', [i]));
  end;
  for var i := 1 to ManyTicks do
    FScene.Tick;
  Assert.AreEqual(Double(HeroPlace.X), Double(FScene.HeroAt.X), Slop, 'In his place');
  Assert.AreEqual(Double(HeroPlace.Y), Double(FScene.HeroAt.Y), Slop, 'Over the road');
end;

procedure TThrowSceneTests.TestTheOrbsGoOutOnceHeIsInHisPlace;
begin
  CatchAt(200, Road);
  var Path := PlanHoist(At(200, Road), HeroPlace);
  var Sent := 0;
  var SentAt := 0;
  for var i := 1 to ManyTicks do
    if FScene.Tick.Grip then
    begin
      Inc(Sent);
      SentAt := i;
      FScene.Grip(PadCount);
    end;
  Assert.AreEqual(1, Sent, 'Once');
  Assert.AreEqual(Path.Ticks, SentAt, 'As he is in his place');
end;

procedure TThrowSceneTests.TestTheSpinWaitsForEveryPad;
begin
  CarryAndGrip(PadCount);
  for var Held := 1 to PadCount do
  begin
    for var i := 1 to ManyTicks do
      Assert.IsFalse(FScene.Tick.SpinUp, Format('Spun with %d held', [Held - 1]));
    Assert.AreEqual(0.0, Double(FScene.Spin), Slop, 'Still');
    FScene.PadHeld;
  end;
  Assert.IsTrue(FScene.Tick.SpinUp, 'Every pad held');
end;

procedure TThrowSceneTests.TestTheSpinRunsUpOnceAndStays;
begin
  HoldThePads(PadCount);
  var SpunUps := 0;
  var SpunAt := 0;
  var Last: Single := 0;
  for var i := 1 to ManyTicks do
  begin
    if FScene.Tick.SpunUp then
    begin
      Inc(SpunUps);
      SpunAt := i;
    end;
    Assert.IsTrue(FScene.Spin >= Last, Format('Never slower, tick %d', [i]));
    Last := FScene.Spin;
  end;
  Assert.AreEqual(1, SpunUps, 'Spun up once');
  Assert.AreEqual(SpinUpTicks, SpunAt, 'Over four seconds');
  Assert.AreEqual(1.0, Double(FScene.Spin), Slop, 'And stays');
end;

procedure TThrowSceneTests.TestTheHintComesInSpunUp;
begin
  HoldThePads(PadCount);
  for var i := 1 to SpinUpTicks - 1 do
  begin
    FScene.Tick;
    Assert.AreEqual(0.0, Double(FScene.Hint(1)), Slop, Format('No hint, tick %d', [i]));
  end;
  Assert.IsTrue(FScene.Tick.SpunUp, 'Spun up');
  var Last: Single := 0;
  for var i := 1 to ThrowAfterTicks - 1 do
  begin
    FScene.Tick;
    Assert.IsTrue(FScene.Hint(0) >= Last, 'Coming in');
    Last := FScene.Hint(0);
  end;
  Assert.AreEqual(1.0, Double(Last), Slop, 'In');
end;

procedure TThrowSceneTests.TestABeatSpinsThemFaster;
begin
  HoldThePads(PadCount);
  Assert.AreEqual(0.0, Double(FScene.SpinRate(1)), Slop, 'Still pads, beat or not');
  for var i := 1 to ManyTicks do
    FScene.Tick;
  Assert.AreEqual(Double(SpunUpSpin), Double(FScene.SpinRate(0)), Slop, 'Spun up');
  Assert.IsTrue(FScene.SpinRate(1) > FScene.SpinRate(0), 'Faster on a thump');
end;

procedure TThrowSceneTests.TestNoPadTheSpinRunsUpAtOnce;
begin
  CarryAndGrip(0);
  Assert.IsTrue(FScene.Tick.SpinUp, 'At once');
end;

procedure TThrowSceneTests.TestAClearTakesItAll;
begin
  HoldThePads(PadCount);
  FScene.Clear;
  Assert.IsFalse(FScene.Running, 'Not running');
  Assert.IsFalse(FScene.Holds, 'He is let go');
  Assert.IsFalse(FScene.Beats, 'No heart');
  Assert.AreEqual(0.0, Double(FScene.Spin), Slop, 'No spin');
  for var i := 1 to ManyTicks do
    Assert.IsFalse(FScene.Tick.SpunUp, 'Nothing more');
end;

procedure TThrowSceneTests.TestThePressIsHeardSpunUpOnly;
begin
  HoldThePads(PadCount);
  FScene.Press;
  for var i := 1 to SpinUpTicks - 1 do
    Assert.IsFalse(FScene.Tick.Volley, Format('Thrown spinning up, tick %d', [i]));
  Assert.IsTrue(FScene.Tick.SpunUp, 'Spun up');
  Assert.IsFalse(FScene.Tick.Volley, 'The press before it is not kept');

  FScene.Press;
  Assert.IsTrue(FScene.Tick.Volley, 'Thrown on the press');
  Assert.AreEqual(0.0, Double(FScene.Hint(1)), Slop, 'The hint gone');
  FScene.Press;
  for var i := 1 to ManyTicks do
    Assert.IsFalse(FScene.Tick.Volley, 'Once');
end;

procedure TThrowSceneTests.TestWithNoPressTheyGoInThreeSeconds;
begin
  SpinUpThePads(PadCount);
  var Volleys := 0;
  var ThrownAt := 0;
  for var i := 1 to ManyTicks do
    if FScene.Tick.Volley then
    begin
      Inc(Volleys);
      ThrownAt := i;
    end;
  Assert.AreEqual(1, Volleys, 'Once');
  Assert.AreEqual(ThrowAfterTicks, ThrownAt, 'Three seconds after the hint');
end;

procedure TThrowSceneTests.TestTheHeartStopsAtTheVolleyHeHangsOn;
begin
  SpinUpThePads(PadCount);
  Assert.IsTrue(FScene.Beats, 'Beating spun up');
  FScene.Press;
  FScene.Tick;
  Assert.IsFalse(FScene.Beats, 'Stopped at the volley');
  for var i := 1 to ManyTicks do
  begin
    FScene.Tick;
    Assert.IsFalse(FScene.Beats, Format('Still, tick %d', [i]));
    Assert.IsTrue(FScene.Holds, Format('Held, tick %d', [i]));
  end;
  Assert.AreEqual(Double(HeroPlace.X), Double(FScene.HeroAt.X), Slop, 'In his place');
end;

procedure TThrowSceneTests.TestEachPadLetGoOnceWithinItsDelay;
begin
  SpinUpThePads(ThrowMostPads);
  FScene.Press;
  var LetGo: TArray<Integer>;
  SetLength(LetGo, ThrowMostPads);
  for var i := 0 to ThrowMostPads - 1 do
    LetGo[i] := -1;
  var Ticks := 0;
  var Busiest := 0;
  for var i := 0 to ManyTicks do
  begin
    var Cue := FScene.Tick;
    if Cue.Volley then
      Ticks := 0;
    Busiest := Max(Busiest, Length(Cue.LetGo));
    for var Number in Cue.LetGo do
    begin
      Assert.AreEqual(-1, LetGo[Number], Format('Pad %d let go twice', [Number]));
      LetGo[Number] := Ticks;
    end;
    Inc(Ticks);
  end;
  for var i := 0 to ThrowMostPads - 1 do
  begin
    Assert.IsTrue(LetGo[i] >= 0, Format('Pad %d never let go', [Integer(i)]));
    Assert.IsTrue(LetGo[i] <= LetGoMostTicks, Format('Pad %d let go late', [Integer(i)]));
  end;
  Assert.IsTrue(Busiest < ThrowMostPads, 'Not all on one tick');
end;

procedure TThrowSceneTests.TestEveryPadStruckTheSceneStands;
begin
  SpinUpThePads(PadCount);
  FScene.PadStruck;
  FScene.Press;
  FScene.Tick;
  Assert.IsFalse(FScene.AllStruck, 'A strike before the volley counts nothing');
  for var i := 1 to PadCount do
  begin
    Assert.IsFalse(FScene.AllStruck, Format('%d struck', [i - 1]));
    FScene.PadStruck;
  end;
  Assert.IsTrue(FScene.AllStruck, 'Every pad struck');
  for var i := 1 to ManyTicks do
  begin
    var Cue := FScene.Tick;
    Assert.AreEqual(0, Length(Cue.LetGo), 'Nothing more let go');
    Assert.IsFalse(Cue.Volley, 'No second volley');
  end;
  Assert.IsTrue(FScene.Holds, 'He hangs on, till the wheel');
  Assert.AreEqual(0.0, Double(FScene.Spin), Slop, 'No spin left');
  Assert.AreEqual(0.0, Double(FScene.Hint(1)), Slop, 'No hint');
end;

procedure TThrowSceneTests.TestNoPadAllStruckAtTheVolley;
begin
  CarryAndGrip(0);
  for var i := 1 to ManyTicks do
    if FScene.Tick.SpunUp then
      Break;
  FScene.Press;
  Assert.IsTrue(FScene.Tick.Volley, 'The volley');
  Assert.IsTrue(FScene.AllStruck, 'Nothing to wait for');
end;

procedure TThrowSceneTests.TestTheWheelABreathAfterTheHoneycombIsDown;
begin
  StrikeEveryPad(PadCount);
  for var i := 1 to ManyTicks do
    Assert.IsFalse(FScene.Tick.Shed, Format('The wheel at tick %d, the honeycomb up',
      [Integer(i)]));
  FScene.HoneycombDown;
  var Sheds := 0;
  var ShedAt := 0;
  for var i := 1 to ManyTicks do
    if FScene.Tick.Shed then
    begin
      Inc(Sheds);
      ShedAt := i;
    end;
  Assert.AreEqual(1, Sheds, 'Once');
  Assert.IsTrue((ShedAt >= WheelAfterTicks) and (ShedAt <= WheelAfterTicks + 1),
    Format('A breath after, not at tick %d', [ShedAt]));
end;

procedure TThrowSceneTests.TestStillOnHisWaySwayingInHisPlace;
begin
  CatchAt(200, Road);
  for var i := 1 to ManyTicks do
  begin
    Assert.AreEqual(0.0, Double(FScene.Sway(1)), 0.0001,
      Format('Still on his way at tick %d', [Integer(i)]));
    if FScene.Tick.Grip then
      Break;
  end;
  var FirstSwing: Single := 0;
  for var i := 1 to HeroSwayTicks do
  begin
    FScene.Tick;
    FirstSwing := Max(FirstSwing, Abs(FScene.Sway(0)));
  end;
  var Deepest: Single := 0;
  for var i := 1 to HeroSwayTicks do
  begin
    FScene.Tick;
    Deepest := Max(Deepest, Abs(FScene.Sway(0)));
    Assert.IsTrue(Abs(FScene.Sway(0.5)) <= HeroSwayDepth + 0.0001,
      Format('Within its depth at tick %d', [Integer(i)]));
  end;
  Assert.IsTrue(FirstSwing < HeroSwayDepth, 'Growing over the first swing');
  Assert.IsTrue(Deepest > 0.95 * HeroSwayDepth, 'Its full depth after');
end;

procedure TThrowSceneTests.TestStillOnceLetGo;
begin
  LooseTheWheel;
  for var i := 1 to ManyTicks do
  begin
    FScene.Tick;
    Assert.AreEqual(0.0, Double(FScene.Sway(0.5)), 0.0001,
      Format('Still at tick %d', [Integer(i)]));
  end;
end;

procedure TThrowSceneTests.TestLetGoAtTheWheelTheSceneStands;
begin
  StrikeEveryPad(PadCount);
  FScene.HoneycombDown;
  for var i := 1 to ManyTicks do
  begin
    Assert.IsTrue(FScene.Holds, Format('Held at tick %d, before the wheel',
      [Integer(i)]));
    if FScene.Tick.Shed then
      Break;
  end;
  Assert.IsFalse(FScene.Holds, 'Let go at the wheel');
  Assert.IsTrue(FScene.Running, 'The scene stands');
  for var i := 1 to ManyTicks do
  begin
    var Cue := FScene.Tick;
    Assert.IsFalse(Cue.Catch or Cue.Grip or Cue.SpinUp or Cue.SpunUp or
      Cue.Volley or Cue.Shed, Format('A cue at tick %d', [Integer(i)]));
    Assert.IsFalse(FScene.Holds or FScene.Beats, 'Free, no heart');
  end;
end;

procedure TThrowSceneTests.TestTheHoneycombDownIsHeardFromTheVolleyOn;
begin
  SpinUpThePads(PadCount);
  FScene.HoneycombDown;
  FScene.Press;
  FScene.Tick;
  for var i := 1 to PadCount do
    FScene.PadStruck;
  for var i := 1 to ManyTicks do
    Assert.IsFalse(FScene.Tick.Shed, Format('The wheel at tick %d', [Integer(i)]));
  Assert.IsTrue(FScene.Holds, 'Held on');
end;

procedure TThrowSceneTests.LooseTheWheel;
begin
  StrikeEveryPad(PadCount);
  FScene.HoneycombDown;
  for var i := 1 to ManyTicks do
    if FScene.Tick.Shed then
      Exit;
  Assert.Fail('The wheel never came off');
end;

procedure TThrowSceneTests.TestTheWheelGoneABreathThenTheTakeoff;
begin
  LooseTheWheel;
  for var i := 1 to ManyTicks do
    Assert.IsFalse(FScene.Tick.TakeOff,
      Format('Off at tick %d, the wheel on the screen', [Integer(i)]));
  FScene.WheelGone;
  var TakeOffs := 0;
  var TakeOffAt := 0;
  for var i := 1 to ManyTicks do
    if FScene.Tick.TakeOff then
    begin
      Inc(TakeOffs);
      TakeOffAt := i;
    end;
  Assert.AreEqual(1, TakeOffs, 'Once');
  Assert.IsTrue((TakeOffAt >= TakeoffAfterTicks) and
    (TakeOffAt <= TakeoffAfterTicks + 1),
    Format('A breath after, not at tick %d', [TakeOffAt]));
  Assert.IsTrue(FScene.Running, 'The scene stands');
  Assert.IsFalse(FScene.Holds, 'Free');
end;

procedure TThrowSceneTests.TestTheWheelGoneIsHeardOnceItIsOff;
begin
  StrikeEveryPad(PadCount);
  FScene.HoneycombDown;
  FScene.WheelGone;
  for var i := 1 to ManyTicks do
    Assert.IsFalse(FScene.Tick.TakeOff, Format('Off at tick %d', [Integer(i)]));
end;

{ TArcTests }

procedure TArcTests.TestAPlaceForEveryPadAllAsFar;
begin
  for var Count := 2 to ThrowMostPads do
  begin
    var Places := PlanArc(RamMiddle, Count);
    Assert.AreEqual(Integer(Count), Length(Places), Format('%d pads', [Count]));
    for var Place in Places do
      Assert.AreEqual(Double(FromRam(Places[0])), Double(FromRam(Place)), Slop,
        Format('As far, %d pads', [Count]));
  end;
end;

procedure TArcTests.TestFromUpLeftOverTheTopToTheRight;
begin
  var Places := PlanArc(RamMiddle, ThrowMostPads);
  var First := Places[0];
  var Last := Places[High(Places)];
  Assert.IsTrue((First.X < RamMiddle.X) and (First.Y < RamMiddle.Y), 'First up and left');
  Assert.IsTrue((Last.X > RamMiddle.X) and (Last.Y < RamMiddle.Y), 'Last right, over the middle');
  for var i := 1 to High(Places) do
    Assert.IsTrue(TurnOf(Places[i]) < TurnOf(Places[i - 1]), 'Clockwise over the top');
end;

procedure TArcTests.TestEvenlyApartAndNoTwoMeet;
begin
  for var Count := 2 to ThrowMostPads do
  begin
    var Places := PlanArc(RamMiddle, Count);
    var Apart := Hypot(Places[1].X - Places[0].X, Places[1].Y - Places[0].Y);
    Assert.IsTrue(Apart >= Widest, Format('%.1f apart, %d pads', [Apart, Count]));
    for var i := 2 to High(Places) do
      Assert.AreEqual(Double(Apart), Double(Hypot(Places[i].X - Places[i - 1].X,
        Places[i].Y - Places[i - 1].Y)), Slop, Format('Evenly, %d pads', [Count]));
  end;
end;

procedure TArcTests.TestOnTheScreen;
begin
  for var Place in PlanArc(RamMiddle, ThrowMostPads) do
  begin
    Assert.IsTrue((Place.X - Widest / 2 >= 0) and (Place.X + Widest / 2 <= ScreenWidth),
      Format('Across at %.0f', [Place.X]));
    Assert.IsTrue((Place.Y - Widest / 2 >= 0) and (Place.Y + Widest / 2 <= Road),
      Format('Down at %.0f', [Place.Y]));
  end;
end;

procedure TArcTests.TestItsTopJustUnderTheTopOfTheScreen;
const
  JustUnder = 48.0;
begin
  var Top: Single := Road;
  for var Place in PlanArc(RamMiddle, ThrowMostPads) do
    Top := Min(Top, Place.Y);
  Assert.IsTrue(Top < JustUnder, Format('The top at %.0f', [Top]));
end;

// The first and the last place the same, however many pads
procedure TArcTests.TestAsWideForAFewAsForMany;
begin
  var Many := PlanArc(RamMiddle, ThrowMostPads);
  for var Count := 2 to ThrowMostPads - 1 do
  begin
    var Few := PlanArc(RamMiddle, Count);
    Assert.AreEqual(Double(Many[0].X), Double(Few[0].X), Slop, Format('First, %d', [Count]));
    Assert.AreEqual(Double(Many[High(Many)].X), Double(Few[High(Few)].X), Slop,
      Format('Last, %d', [Count]));
  end;
end;

procedure TArcTests.TestOnePadOverTheRam;
begin
  var Places := PlanArc(RamMiddle, 1);
  Assert.AreEqual(1, Length(Places), 'One');
  Assert.IsTrue(Places[0].Y < RamMiddle.Y, 'Over it');
end;

// The pads of either side go to the places of their side, in their order
procedure TArcTests.TestTakenByTurnNoTwoWaysCross;
begin
  var Points: TArray<TSdlFPoint> := [At(400, 250), At(60, 150), At(250, 100),
    At(120, 330)];
  var Order := ArcOrder(RamMiddle, Points);
  Assert.AreEqual(2, Order[0], 'The rightmost, low: the third place');
  Assert.AreEqual(0, Order[1], 'Up and left: the first');
  Assert.AreEqual(1, Order[2], 'Over it: the second');
  Assert.AreEqual(3, Order[3], 'Under the middle on the left: the last');
end;

{ TCalledPadTests }

// The Ram's hull as it stands at the throw, and the hero in his place
function Hull: TSdlFRect;
begin
  Result := Box(RamPlaceLeft, 224, 169, 128);
end;

function HeroUp: TSdlFRect;
begin
  Result := Box(HeroPlace.X, HeroPlace.Y - 32, 32, 32);
end;

procedure TCalledPadTests.TestAsManyAsMissing;
begin
  Assert.AreEqual(3, Length(PlaceCalledPads([Hull, HeroUp], 3)), 'Three');
  Assert.AreEqual(0, Length(PlaceCalledPads([Hull, HeroUp], 0)), 'None');
end;

procedure TCalledPadTests.TestOnTheRowsInsideTheScreen;
begin
  for var Called in PlaceCalledPads([Hull, HeroUp], ThrowLeastPads) do
  begin
    var OnARow := False;
    for var Deck in RowDecks do
      OnARow := OnARow or (Abs(Called.Deck - Deck) < Slop);
    Assert.IsTrue(OnARow, Format('A deck at %.0f', [Called.Deck]));
    Assert.IsTrue((Called.Left >= 0) and (Called.Left + Called.Width <= ScreenWidth),
      Format('Inside, at %.0f', [Called.Left]));
  end;
end;

procedure TCalledPadTests.TestClearOfWhatIsTakenAndOfEachOther;
begin
  var Taken: TArray<TSdlFRect> := [Hull, HeroUp, Box(40, 192, 64, 12)];
  var Called := PlaceCalledPads(Taken, ThrowLeastPads);
  Assert.AreEqual(ThrowLeastPads, Length(Called), 'Room for all');
  for var i := 0 to High(Called) do
  begin
    for var Other in Taken do
      Assert.IsFalse(Overlap(CalledBody(Called[i]), Other),
        Format('Pad %d in what is taken', [i]));
    for var j := 0 to i - 1 do
      Assert.IsFalse(Overlap(CalledBody(Called[i]), CalledBody(Called[j])),
        Format('Pads %d and %d', [i, j]));
  end;
end;

procedure TCalledPadTests.TestEachComesFromBeyondTheNearerEdge;
begin
  for var Called in PlaceCalledPads([Hull, HeroUp], ThrowLeastPads) do
  begin
    var Start := Called.Left + Called.From.X;
    if Called.Left + Called.Width / 2 < ScreenWidth / 2 then
      Assert.IsTrue(Start + Called.Width <= 0,
        Format('From beyond the left, at %.0f', [Start]))
    else
      Assert.IsTrue(Start >= ScreenWidth,
        Format('From beyond the right, at %.0f', [Start]));
    Assert.AreEqual(0.0, Double(Called.From.Y), Slop, 'Level');
  end;
end;

procedure TCalledPadTests.TestNoneWithoutRoom;
begin
  var Screen := Box(0, 0, ScreenWidth, ScreenHeight);
  Assert.AreEqual(0, Length(PlaceCalledPads([Screen], ThrowLeastPads)));
end;

initialization
  TDUnitX.RegisterTestFixture(TThrowSceneTests);
  TDUnitX.RegisterTestFixture(TArcTests);
  TDUnitX.RegisterTestFixture(TCalledPadTests);

end.
