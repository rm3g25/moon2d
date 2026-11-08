{
  Tests.Orbs.Shots - the look of the orb launcher's shots: an orb for every
  orb-look bullet in flight and none for another bullet; one orb a bullet,
  however many ticks; the orb where the bullet's picture is, going where
  the bullet goes; a bullet spent, or gone from the burst, leaves its orb
  to dust; none is armed; a clear takes them all.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Orbs.Shots;

interface

uses
  System.Generics.Collections,
  DUnitX.TestFramework,
  Bullets,
  Orbs.Flock,
  Orbs.Shots;

type
  [TestFixture]
  TOrbShotsTests = class
  private
    FShots: TOrbShots;
    FBullets: TObjectList<TBullet>;
    function Fire(AX, AY: Double; ALook: TBulletLook = blOrb): TBullet;
    // Every bullet a tick on, as the burst moves them, and the orbs after
    procedure TickAll;
    function Living: Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestAnOrbForEveryOrbBulletInFlight;
    [Test]
    procedure TestOneOrbABullet;
    [Test]
    procedure TestTheOrbRidesItsBulletsPicture;
    [Test]
    procedure TestASpentBulletLeavesItsOrbToDust;
    [Test]
    procedure TestABulletGoneTakesItsOrb;
    [Test]
    procedure TestNoneIsArmed;
    [Test]
    procedure TestAClearTakesThemAll;
  end;

implementation

uses
  Render.Sprites;

const
  Slop = 0.001;
  Speed = 10;
  Level = 0;
  NoGravity = 0;

procedure TOrbShotsTests.Setup;
begin
  FShots := TOrbShots.Create;
  FBullets := TObjectList<TBullet>.Create(True);
end;

procedure TOrbShotsTests.TearDown;
begin
  FShots.Free;
  FBullets.Free;
end;

function TOrbShotsTests.Fire(AX, AY: Double; ALook: TBulletLook): TBullet;
begin
  Result := TBullet.Create(Speed, AX, AY, Level, NoGravity, True, ALook);
  FBullets.Add(Result);
end;

procedure TOrbShotsTests.TickAll;
begin
  for var Bullet in FBullets do
    Bullet.Move;
  FShots.Tick(FBullets);
end;

function TOrbShotsTests.Living: Integer;
begin
  Result := 0;
  for var Orb in FShots.Flock.Orbs do
    if Orb.State = osAlive then
      Inc(Result);
end;

procedure TOrbShotsTests.TestAnOrbForEveryOrbBulletInFlight;
begin
  Fire(100, 200);
  Fire(150, 220);
  Fire(200, 240, blPlain);
  Fire(250, 260, blRed);
  FShots.Tick(FBullets);
  Assert.AreEqual(2, Living, 'Two orbs');
end;

procedure TOrbShotsTests.TestOneOrbABullet;
begin
  Fire(100, 200);
  for var i := 1 to 10 do
    TickAll;
  Assert.AreEqual(1, FShots.Flock.Orbs.Count, 'One');
end;

procedure TOrbShotsTests.TestTheOrbRidesItsBulletsPicture;
begin
  var Bullet := Fire(100, 200);
  FShots.Tick(FBullets);
  for var i := 1 to 5 do
  begin
    TickAll;
    var Orb := FShots.Flock.Orbs[0];
    Assert.AreEqual(Bullet.X, Double(Orb.X), Slop, 'Across');
    Assert.AreEqual(Bullet.Y - SpriteSize, Double(Orb.Y), Slop,
      'A sprite over its point');
  end;
  Assert.IsTrue(FShots.Flock.Orbs[0].X > 100 + Speed, 'Gone on with it');
end;

procedure TOrbShotsTests.TestASpentBulletLeavesItsOrbToDust;
begin
  var Spent := Fire(100, 200);
  var Bursting := Fire(150, 200);
  Fire(200, 200);
  FShots.Tick(FBullets);
  Spent.Status := bsInactive;
  Bursting.StartBurst;
  FShots.Tick(FBullets);
  Assert.AreEqual(1, Living, 'The one in flight');
  Assert.AreEqual(1, FShots.Flock.Orbs.Count, 'The spent gone at once');
end;

procedure TOrbShotsTests.TestABulletGoneTakesItsOrb;
begin
  var Gone := Fire(100, 200);
  Fire(200, 200);
  FShots.Tick(FBullets);
  FBullets.Remove(Gone);
  FShots.Tick(FBullets);
  Assert.AreEqual(1, FShots.Flock.Orbs.Count, 'One left');
end;

procedure TOrbShotsTests.TestNoneIsArmed;
begin
  Fire(100, 200);
  Fire(200, 200);
  FShots.Tick(FBullets);
  for var Orb in FShots.Flock.Orbs do
    Assert.IsFalse(Orb.Armed, 'Armed');
end;

procedure TOrbShotsTests.TestAClearTakesThemAll;
begin
  Fire(100, 200);
  FShots.Tick(FBullets);
  FShots.Clear;
  Assert.AreEqual(0, FShots.Flock.Orbs.Count, 'No orb');
  FBullets.Clear;
  FShots.Tick(FBullets);
  Assert.AreEqual(0, FShots.Flock.Orbs.Count, 'Still none');
end;

initialization
  TDUnitX.RegisterTestFixture(TOrbShotsTests);

end.
