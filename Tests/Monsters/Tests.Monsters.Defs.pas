{
  Tests.Monsters.Defs - what the monster registry makes of the sentry
  word of an attack: the mount of monsters.json is a sentry, the other
  attackers are not, and a sentry that watches a strip of no width is
  turned down at load.

  The sentry word is tried on a one-monster file of the test's own,
  beside the real one, which is read as the game reads it.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Monsters.Defs;

interface

uses
  DUnitX.TestFramework,
  Monsters.Defs;

type
  [TestFixture]
  TMonsterDefsTests = class
  private
    FRegistry: TMonsterRegistry;
    procedure UseGameRegistry;
    procedure UsePost(const ASentry: string);
  public
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestMountIsASentryWithAReach;
    [Test]
    procedure TestOtherAttackersAreNoSentries;
    [Test]
    procedure TestSentryReadsItsReach;
    [Test]
    procedure TestAttackWithoutSentryIsNoSentry;
    [Test]
    procedure TestSentryWithNoReachRaises;
  end;

implementation

uses
  System.IOUtils,
  System.SysUtils;

// The attack of the mount with the sentry word as given; '' leaves it out
function PostJson(const ASentry: string): string;
begin
  var Sentry := '';
  if ASentry <> '' then
    Sentry := ',"sentry":' + ASentry;
  Result := '{"monsters":[{"id":"post","category":"enemy",'
    + '"stats":{"lives":1},"movement":{"kind":"static"},'
    + '"attack":{"pattern":"rainVolley","fireEveryTicks":45,'
    + '"bulletSpeed":12,"volleyCount":7,"volleySpacingX":4,"angleDeg":270'
    + Sentry + '}}]}';
end;

// By value, not const: an anonymous method captures it
procedure ExpectPostRefused(ASentry: string);
begin
  var Registry := TMonsterRegistry.Create;
  try
    Assert.WillRaise(
      procedure
      begin
        Registry.LoadFromString(PostJson(ASentry));
      end, EMonsterDefError, 'A sentry word ' + ASentry);
  finally
    Registry.Free;
  end;
end;

procedure TMonsterDefsTests.TearDown;
begin
  FreeAndNil(FRegistry);
end;

procedure TMonsterDefsTests.UseGameRegistry;
begin
  FreeAndNil(FRegistry);
  FRegistry := TMonsterRegistry.Create;
  FRegistry.LoadFromFile(
    TPath.Combine(ExtractFilePath(ParamStr(0)), 'monsters.json'));
end;

procedure TMonsterDefsTests.UsePost(const ASentry: string);
begin
  FreeAndNil(FRegistry);
  FRegistry := TMonsterRegistry.Create;
  FRegistry.LoadFromString(PostJson(ASentry));
end;

procedure TMonsterDefsTests.TestMountIsASentryWithAReach;
begin
  UseGameRegistry;
  var Sentry := FRegistry.Find('mount').Attack.Sentry;
  Assert.IsTrue(Sentry.Enabled, 'The mount watches for the hero');
  Assert.IsTrue(Sentry.Reach > 0, 'over a strip that has a width');
end;

procedure TMonsterDefsTests.TestOtherAttackersAreNoSentries;
const
  Shooters: array [0..3] of string = ('gravel', 'platform', 'tank',
    'zombieShooter');
begin
  UseGameRegistry;
  for var Id in Shooters do
    Assert.IsFalse(FRegistry.Find(Id).Attack.Sentry.Enabled,
      Id + ' shoots whenever it is on the hero''s screen');
end;

procedure TMonsterDefsTests.TestSentryReadsItsReach;
begin
  UsePost('{"reach":30}');
  var Sentry := FRegistry.Find('post').Attack.Sentry;
  Assert.IsTrue(Sentry.Enabled, 'A monster with the sentry word');
  Assert.AreEqual(30, Sentry.Reach, 'watches the reach it is given');
end;

procedure TMonsterDefsTests.TestAttackWithoutSentryIsNoSentry;
begin
  UsePost('');
  Assert.IsFalse(FRegistry.Find('post').Attack.Sentry.Enabled,
    'An attack with no sentry word');
end;

procedure TMonsterDefsTests.TestSentryWithNoReachRaises;
begin
  ExpectPostRefused('{"reach":0}');
  ExpectPostRefused('{"reach":-5}');
  ExpectPostRefused('{}');
end;

initialization
  TDUnitX.RegisterTestFixture(TMonsterDefsTests);

end.
