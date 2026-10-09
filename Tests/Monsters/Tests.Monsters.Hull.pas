{
  Tests.Monsters.Hull - the eye of a hull, asleep and awake: a hull born
  awake, a hull dozed off dark, and the two ways between, which come by
  degrees and not at a stroke.

  The hull is the mount's, made with no art: its ticks move numbers and
  never touch a picture. Drawing is not tried.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Monsters.Hull;

interface

uses
  DUnitX.TestFramework,
  Monsters.Hull;

type
  [TestFixture]
  THullTests = class
  private
    FHull: THull;
    procedure UseHull;
    procedure TickTimes(ATimes: Integer);
  public
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestHullIsBornAwakeAndLit;
    [Test]
    procedure TestDozedHullIsDarkAndStaysDark;
    [Test]
    procedure TestWakingHullComesUpByDegrees;
    [Test]
    procedure TestHullPutToSleepGoesDarkByDegrees;
  end;

implementation

uses
  System.IOUtils,
  System.SysUtils,
  Monsters.Defs;

const
  // The ramp is tuned by eye: a test asks only that it ends within a second
  AboutASecond = 33;
  SingleSlack = 0.0001;

function IsNear(AValue: Single; AExpected: Double): Boolean;
begin
  Result := Abs(AValue - AExpected) < SingleSlack;
end;

function MountHullDef: THullDef;
begin
  var Registry := TMonsterRegistry.Create;
  try
    Registry.LoadFromFile(
      TPath.Combine(ExtractFilePath(ParamStr(0)), 'monsters.json'));
    Result := Registry.Find('mount').Hull;
  finally
    Registry.Free;
  end;
end;

procedure THullTests.TearDown;
begin
  FreeAndNil(FHull);
end;

procedure THullTests.UseHull;
begin
  FreeAndNil(FHull);
  FHull := THull.Create(MountHullDef, nil);
end;

procedure THullTests.TickTimes(ATimes: Integer);
begin
  for var i := 1 to ATimes do
    FHull.Tick(0, 0, 0);
end;

procedure THullTests.TestHullIsBornAwakeAndLit;
begin
  UseHull;
  Assert.IsTrue(FHull.Awake, 'A new hull is awake');
  Assert.IsTrue(IsNear(FHull.Wake, 1), 'and its eye is up at once');
  TickTimes(AboutASecond);
  Assert.IsTrue(IsNear(FHull.Wake, 1), 'and stays up');
end;

procedure THullTests.TestDozedHullIsDarkAndStaysDark;
begin
  UseHull;
  FHull.Doze;
  Assert.IsFalse(FHull.Awake, 'A dozed hull is asleep');
  Assert.IsTrue(IsNear(FHull.Wake, 0), 'with its eye dark at once');
  TickTimes(AboutASecond);
  Assert.IsTrue(IsNear(FHull.Wake, 0), 'and it stays dark');
end;

procedure THullTests.TestWakingHullComesUpByDegrees;
begin
  UseHull;
  FHull.Doze;
  FHull.Awake := True;

  TickTimes(1);
  Assert.IsTrue((FHull.Wake > 0) and (FHull.Wake < 1),
    'After one tick the eye is on its way, not there');

  var Previous := FHull.Wake;
  for var i := 1 to AboutASecond do
  begin
    TickTimes(1);
    Assert.IsTrue(FHull.Wake >= Previous, 'The eye never dims on its way up');
    Previous := FHull.Wake;
  end;
  Assert.IsTrue(IsNear(FHull.Wake, 1), 'Within a second it is all the way up');
end;

procedure THullTests.TestHullPutToSleepGoesDarkByDegrees;
begin
  UseHull;
  FHull.Awake := False;

  TickTimes(1);
  Assert.IsTrue((FHull.Wake > 0) and (FHull.Wake < 1),
    'After one tick the eye is on its way down, not out');

  var Previous := FHull.Wake;
  for var i := 1 to AboutASecond do
  begin
    TickTimes(1);
    Assert.IsTrue(FHull.Wake <= Previous, 'The eye never lights on its way down');
    Previous := FHull.Wake;
  end;
  Assert.IsTrue(IsNear(FHull.Wake, 0), 'Within a second it is dark');
end;

initialization
  TDUnitX.RegisterTestFixture(THullTests);

end.
