{
  Tests.Orbs.Flock - what a flock does with the orbs it is given: keeps
  them in the owner's order, ages them tick by tick and lets each one go
  the way it ends - an implosion takes its time, a strike and a release
  are at once, and the gone are dropped at the tick.

  What a flock draws - the breath, the dust, the mark on a face - has no
  test here: that is for the eye.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Orbs.Flock;

interface

uses
  DUnitX.TestFramework, Orbs.Flock;

type
  [TestFixture]
  TOrbFlockTests = class
  private
    FFlock: TOrbFlock;
    function AddOrbAt(AX, AY: Single): TOrb;
    // Ticks the flock until it has dropped the orb; how many ticks it took
    function TicksUntilDropped(const AOrb: TOrb): Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestNewOrbIsAliveArmedAndFull;
    [Test]
    procedure TestAddKeepsOwnersOrder;
    [Test]
    procedure TestInsertPutsOrbBeforeIndex;
    [Test]
    procedure TestTickAgesEveryOrb;
    [Test]
    procedure TestMovedOrbStaysPutThroughTicks;
    [Test]
    procedure TestMoveBesidePutsOrbWhereMoveToWould;
    [Test]
    procedure TestImplodingOrbLingersThenIsDropped;
    [Test]
    procedure TestSecondImplodeDoesNotStartOver;
    [Test]
    procedure TestSpentOrbIsGoneAtOnceAndDroppedAtTick;
    [Test]
    procedure TestReleasedOrbIsGoneAtOnceAndDroppedAtTick;
    [Test]
    procedure TestSpendTakesImplodingOrbAtOnce;
    [Test]
    procedure TestGoneOrbDoesNotImplode;
    [Test]
    procedure TestTickDropsOnlyTheGone;
    [Test]
    procedure TestShiftCarriesEveryOrbByTheStep;
    [Test]
    procedure TestClearEmptiesTheFlock;
  end;

implementation

uses
  System.SysUtils;

const
  PlaceSlack = 0.001; // units
  // No orb takes a second to go
  LongestGoodbye = 33; // ticks

procedure ExpectAt(const AOrb: TOrb; AX, AY: Single);
begin
  var IsThere := (Abs(AOrb.X - AX) < PlaceSlack) and
    (Abs(AOrb.Y - AY) < PlaceSlack);
  Assert.IsTrue(IsThere, Format('The orb is at (%g, %g), not at (%g, %g)',
    [AOrb.X, AOrb.Y, AX, AY]));
end;

procedure TOrbFlockTests.Setup;
begin
  FFlock := TOrbFlock.Create(IceOrbTint);
end;

procedure TOrbFlockTests.TearDown;
begin
  FreeAndNil(FFlock);
end;

function TOrbFlockTests.AddOrbAt(AX, AY: Single): TOrb;
begin
  Result := TOrb.Create(AX, AY);
  FFlock.Add(Result);
end;

function TOrbFlockTests.TicksUntilDropped(const AOrb: TOrb): Integer;
begin
  Result := 0;
  while FFlock.Orbs.Contains(AOrb) do
  begin
    if Result = LongestGoodbye then
      Assert.Fail(Format('The orb is still in the flock after %d ticks',
        [Result]));
    FFlock.Tick;
    Inc(Result);
  end;
end;

procedure TOrbFlockTests.TestNewOrbIsAliveArmedAndFull;
begin
  var Orb := AddOrbAt(40, 60);

  ExpectAt(Orb, 40, 60);
  Assert.AreEqual<TOrbState>(osAlive, Orb.State);
  Assert.AreEqual(0, Orb.Age);
  Assert.IsTrue(Orb.Armed, 'A new orb is armed');
  var IsFull := (Orb.Size = 1) and (Orb.Level = 1);
  Assert.IsTrue(IsFull, 'A new orb is at its full size and light');
end;

procedure TOrbFlockTests.TestAddKeepsOwnersOrder;
begin
  var Head := AddOrbAt(10, 10);
  var Middle := AddOrbAt(20, 10);
  var Tail := AddOrbAt(30, 10);

  Assert.AreSame(Head, FFlock.Orbs[0]);
  Assert.AreSame(Middle, FFlock.Orbs[1]);
  Assert.AreSame(Tail, FFlock.Orbs[2]);
end;

procedure TOrbFlockTests.TestInsertPutsOrbBeforeIndex;
begin
  var Head := AddOrbAt(10, 10);
  var Tail := AddOrbAt(30, 10);
  var Newcomer := TOrb.Create(20, 10);

  FFlock.Insert(1, Newcomer);

  Assert.AreSame(Head, FFlock.Orbs[0]);
  Assert.AreSame(Newcomer, FFlock.Orbs[1]);
  Assert.AreSame(Tail, FFlock.Orbs[2]);
end;

procedure TOrbFlockTests.TestTickAgesEveryOrb;
begin
  var Elder := AddOrbAt(10, 10);
  FFlock.Tick;
  var Younger := AddOrbAt(20, 10);
  FFlock.Tick;
  FFlock.Tick;

  Assert.AreEqual(3, Elder.Age);
  Assert.AreEqual(2, Younger.Age);
end;

procedure TOrbFlockTests.TestMovedOrbStaysPutThroughTicks;
begin
  var Orb := AddOrbAt(10, 20);

  Orb.MoveTo(70, 90);
  FFlock.Tick;
  FFlock.Tick;

  ExpectAt(Orb, 70, 90);
end;

procedure TOrbFlockTests.TestMoveBesidePutsOrbWhereMoveToWould;
begin
  var Orb := AddOrbAt(10, 20);

  Orb.MoveBeside(70, 90, 4, -2);

  ExpectAt(Orb, 70, 90);
end;

procedure TOrbFlockTests.TestImplodingOrbLingersThenIsDropped;
begin
  var Orb := AddOrbAt(40, 60);

  FFlock.Implode(Orb);
  Assert.AreEqual<TOrbState>(osImploding, Orb.State);

  var Ticks := TicksUntilDropped(Orb);
  Assert.IsTrue(Ticks > 1, 'An implosion takes more than a tick');
end;

procedure TOrbFlockTests.TestSecondImplodeDoesNotStartOver;
begin
  var Twin := AddOrbAt(10, 10);
  var Recalled := AddOrbAt(20, 10);
  FFlock.Implode(Twin);
  FFlock.Implode(Recalled);
  FFlock.Tick;
  Assert.IsTrue(FFlock.Orbs.Contains(Recalled),
    'An implosion takes more than a tick');

  FFlock.Implode(Recalled);
  TicksUntilDropped(Twin);

  Assert.IsFalse(FFlock.Orbs.Contains(Recalled),
    'The second implode started the orb over');
end;

procedure TOrbFlockTests.TestSpentOrbIsGoneAtOnceAndDroppedAtTick;
begin
  var Orb := AddOrbAt(40, 60);

  FFlock.Spend(Orb);
  Assert.AreEqual<TOrbState>(osGone, Orb.State);
  Assert.AreEqual(1, FFlock.Orbs.Count,
    'The gone stay in the flock until its tick: the game spends orbs ' +
    'while it walks them');

  FFlock.Tick;
  Assert.AreEqual(0, FFlock.Orbs.Count);
end;

procedure TOrbFlockTests.TestReleasedOrbIsGoneAtOnceAndDroppedAtTick;
begin
  var Orb := AddOrbAt(40, 60);

  FFlock.Release(Orb);
  Assert.AreEqual<TOrbState>(osGone, Orb.State);
  Assert.AreEqual(1, FFlock.Orbs.Count,
    'The gone stay in the flock until its tick: an owner releases orbs ' +
    'while it walks them');

  FFlock.Tick;
  Assert.AreEqual(0, FFlock.Orbs.Count);
end;

procedure TOrbFlockTests.TestSpendTakesImplodingOrbAtOnce;
begin
  var Orb := AddOrbAt(40, 60);
  FFlock.Implode(Orb);

  FFlock.Spend(Orb);
  Assert.AreEqual<TOrbState>(osGone, Orb.State);

  FFlock.Tick;
  Assert.AreEqual(0, FFlock.Orbs.Count);
end;

procedure TOrbFlockTests.TestGoneOrbDoesNotImplode;
begin
  var Orb := AddOrbAt(40, 60);
  FFlock.Spend(Orb);

  FFlock.Implode(Orb);

  Assert.AreEqual<TOrbState>(osGone, Orb.State);
end;

procedure TOrbFlockTests.TestTickDropsOnlyTheGone;
begin
  var Head := AddOrbAt(10, 10);
  var Struck := AddOrbAt(20, 10);
  var Tail := AddOrbAt(30, 10);
  FFlock.Spend(Struck);

  FFlock.Tick;

  Assert.AreEqual(2, FFlock.Orbs.Count);
  Assert.AreSame(Head, FFlock.Orbs[0]);
  Assert.AreSame(Tail, FFlock.Orbs[1]);
end;

procedure TOrbFlockTests.TestShiftCarriesEveryOrbByTheStep;
begin
  var Near := AddOrbAt(10, 20);
  var Far := AddOrbAt(300, 150);

  FFlock.Shift(-512, 32);

  ExpectAt(Near, -502, 52);
  ExpectAt(Far, -212, 182);
end;

procedure TOrbFlockTests.TestClearEmptiesTheFlock;
begin
  AddOrbAt(10, 10);
  AddOrbAt(20, 10);

  FFlock.Clear;

  Assert.AreEqual(0, FFlock.Orbs.Count);
end;

initialization
  TDUnitX.RegisterTestFixture(TOrbFlockTests);

end.
