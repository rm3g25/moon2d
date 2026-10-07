{
  Tests.Monsters.Damage - the damage cap of a monster: the window that
  lets a blow's lives through while the last second holds less than the
  cap, and the boss that wears it.

  The window is tried alone, with the blows of the hero's guns as
  numbers, so the cap's size is held to what it was set for: no gun of
  the hero is ever throttled, a bigger blow is cut. The boss is tried
  on one tick: the lives a hundred blows take, and the shove of a blow
  that took none.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Monsters.Damage;

interface

uses
  DUnitX.TestFramework,
  Monsters.Damage,
  Tests.Rooms;

type
  [TestFixture]
  TDamageWindowTests = class
  private
    FWindow: TDamageWindow;
    // The hits a gun fires over ATicks that the cap cuts, a volley of
    // AHits every AEveryTicks
    function HitsCut(AEveryTicks, AHits, ATicks: Integer): Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestBlowsOverTheCapAreCutAtTheCap;
    [Test]
    procedure TestSingleHitsLandUpToTheCapThenNone;
    [Test]
    procedure TestHitsLeaveTheWindowWhenItsTickIsOver;
    [Test]
    procedure TestNoRunOfTicksTakesMoreThanTheCap;
    [Test]
    procedure TestSteadyFireIsLetThroughAtTheCapRate;
    [Test]
    procedure TestChainGunIsNeverThrottled;
    [Test]
    procedure TestGrenadeVolleyIsNeverThrottled;
  end;

  [TestFixture]
  TCappedBossTests = class
  private
    FRoom: TRoom;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestHundredBlowsOnOneTickTakeNoMoreThanTheCap;
    [Test]
    procedure TestBlowOverTheCapStillShovesTheBoss;
  end;

implementation

uses
  System.SysUtils,
  Monsters,
  Monsters.Defs;

const
  CapLives = 30;
  CapTicks = 33;
  // The hero's guns, the best of them: three bullets every 5 ticks, a
  // volley of 22 pellets every 40
  ChainBullets = 3;
  ChainEveryTicks = 5;
  GrenadePellets = 22;
  GrenadeEveryTicks = 40;
  // The seconds a gun fires for in the tests below
  Seconds = 10;
  // A blow of this size moves a body half of it
  Blow = 8;
  BlowsPastTheCap = 100;

function TDamageWindowTests.HitsCut(AEveryTicks, AHits,
  ATicks: Integer): Integer;
begin
  Result := 0;
  for var i := 0 to ATicks - 1 do
  begin
    if i > 0 then
      FWindow.Advance;
    if i mod AEveryTicks = 0 then
      Inc(Result, AHits - FWindow.Admit(AHits));
  end;
end;

procedure TDamageWindowTests.Setup;
begin
  var Cap := Default(TDamageCap);
  Cap.Lives := CapLives;
  Cap.Ticks := CapTicks;
  FWindow := TDamageWindow.Create(Cap);
end;

procedure TDamageWindowTests.TearDown;
begin
  FreeAndNil(FWindow);
end;

procedure TDamageWindowTests.TestBlowsOverTheCapAreCutAtTheCap;
begin
  Assert.AreEqual(CapLives, FWindow.Admit(BlowsPastTheCap), 'the first blow');
  Assert.AreEqual(0, FWindow.Admit(1), 'the next one');
end;

procedure TDamageWindowTests.TestSingleHitsLandUpToTheCapThenNone;
begin
  var Landed := 0;
  for var i := 1 to BlowsPastTheCap do
    Inc(Landed, FWindow.Admit(1));

  Assert.AreEqual(CapLives, Landed);
end;

procedure TDamageWindowTests.TestHitsLeaveTheWindowWhenItsTickIsOver;
begin
  FWindow.Admit(CapLives);

  for var i := 1 to CapTicks - 1 do
    FWindow.Advance;
  Assert.AreEqual(0, FWindow.Admit(1), 'the last tick of the window');

  FWindow.Advance;
  Assert.AreEqual(CapLives, FWindow.Admit(BlowsPastTheCap),
    'the first tick after the window');
end;

procedure TDamageWindowTests.TestNoRunOfTicksTakesMoreThanTheCap;
begin
  var Landed: TArray<Integer>;
  SetLength(Landed, CapTicks * Seconds);
  for var i := 0 to High(Landed) do
  begin
    if i > 0 then
      FWindow.Advance;
    Landed[i] := FWindow.Admit(5);
  end;

  for var i := 0 to High(Landed) - CapTicks + 1 do
  begin
    var Sum := 0;
    for var j := i to i + CapTicks - 1 do
      Inc(Sum, Landed[j]);
    Assert.IsTrue(Sum <= CapLives,
      Format('%d lives landed in the %d ticks from tick %d',
        [Sum, CapTicks, i]));
  end;
end;

procedure TDamageWindowTests.TestSteadyFireIsLetThroughAtTheCapRate;
begin
  var Total := 0;
  for var i := 0 to CapTicks * Seconds - 1 do
  begin
    if i > 0 then
      FWindow.Advance;
    Inc(Total, FWindow.Admit(5));
  end;

  Assert.AreEqual(CapLives * Seconds, Total,
    'the cap lets less through than it says');
end;

procedure TDamageWindowTests.TestChainGunIsNeverThrottled;
begin
  Assert.AreEqual(0,
    HitsCut(ChainEveryTicks, ChainBullets, CapTicks * Seconds));
end;

procedure TDamageWindowTests.TestGrenadeVolleyIsNeverThrottled;
begin
  Assert.AreEqual(0,
    HitsCut(GrenadeEveryTicks, GrenadePellets, CapTicks * Seconds));
end;

procedure TCappedBossTests.Setup;
begin
  FRoom := RoomFromRows(RoomRowsOf(0, 0, 0, 0));
end;

procedure TCappedBossTests.TearDown;
begin
  FreeAndNil(FRoom);
end;

procedure TCappedBossTests.TestHundredBlowsOnOneTickTakeNoMoreThanTheCap;
begin
  var Boss := FRoom.Place('boss1', 8, 5);
  var Before := Boss.Lives;

  for var i := 1 to BlowsPastTheCap do
    Boss.TakeDamage(0, 1, nil);

  Assert.AreEqual(Before - Boss.Def.DamageCap.Lives, Boss.Lives);
  Assert.AreEqual<TMonsterLife>(mlAlive, Boss.Life);
end;

procedure TCappedBossTests.TestBlowOverTheCapStillShovesTheBoss;
begin
  var Boss := FRoom.Place('boss1', 8, 5);
  for var i := 1 to BlowsPastTheCap do
    Boss.TakeDamage(0, 1, nil);
  var LivesLeft := Boss.Lives;
  var StartX: Integer := Round(Boss.X);

  Boss.TakeDamage(Blow, 1, nil);

  var ShovedX: Integer := Round(Boss.X);
  Assert.AreEqual(LivesLeft, Boss.Lives, 'the blow took a life');
  Assert.AreEqual(StartX + Blow div 2, ShovedX, 'the blow did not shove');
end;

initialization
  TDUnitX.RegisterTestFixture(TDamageWindowTests);
  TDUnitX.RegisterTestFixture(TCappedBossTests);

end.
