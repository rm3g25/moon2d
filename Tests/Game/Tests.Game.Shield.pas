{
  Tests.Game.Shield - a TEK shield broken and crumbling: a heavy blow
  breaks a piece off it, and it still holds; crumbled, it holds no more,
  and blows do nothing; it goes out from the pieces broken off outward -
  broken at one end, it takes longer than broken in its middle - and from
  its middle when none is; risen, it is whole again and the old breaks
  are forgotten; a shield already falling does not crumble.

  The look - the shards, the blinking - is checked live.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Game.Shield;

interface

uses
  DUnitX.TestFramework,
  Game.Shield;

type
  [TestFixture]
  TShieldCrumbleTests = class
  private
    FShield: TTekShield;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestABlowBreaksAPieceItStillHolds;
    [Test]
    procedure TestCrumbledItHoldsNoMore;
    [Test]
    procedure TestOutFromTheBreaksOutward;
    [Test]
    procedure TestNoBreakItCrumblesFromTheMiddle;
    [Test]
    procedure TestRisenItIsWholeAgain;
    [Test]
    procedure TestAFallingShieldDoesNotCrumble;
    [Test]
    procedure TestVanishedItIsDownAtOnce;
  end;

implementation

uses
  System.SysUtils,
  Sdl2.Core;

const
  RadiusX = 40.0;
  RadiusY = 20.0;
  ManyTicks = 1000;

function At(AX, AY: Single): TSdlFPoint;
begin
  Result.X := AX;
  Result.Y := AY;
end;

function LeftEnd: TSdlFPoint;
begin
  Result := At(-RadiusX + 2, 0);
end;

function TopMiddle: TSdlFPoint;
begin
  Result := At(0, -RadiusY + 1);
end;

// From the left, through the middle
function Holds(AShield: TTekShield): Boolean;
begin
  var Entry: TSdlFPoint;
  Result := AShield.TryEntry(At(-2 * RadiusX, 0), At(0, 0), Entry);
end;

function TicksTillDown(AShield: TTekShield): Integer;
begin
  Result := 0;
  while (AShield.State <> sdDown) and (Result < ManyTicks) do
  begin
    AShield.Tick;
    Inc(Result);
  end;
end;

// Broken at APoint, then crumbled: how long it takes to go out
function CrumbleTicks(const APoint: TSdlFPoint): Integer;
begin
  var Shield := TTekShield.Create(RadiusX, RadiusY);
  try
    Shield.Shatter(APoint);
    Shield.Crumble;
    Result := TicksTillDown(Shield);
  finally
    Shield.Free;
  end;
end;

procedure TShieldCrumbleTests.Setup;
begin
  FShield := TTekShield.Create(RadiusX, RadiusY);
end;

procedure TShieldCrumbleTests.TearDown;
begin
  FShield.Free;
end;

procedure TShieldCrumbleTests.TestABlowBreaksAPieceItStillHolds;
begin
  FShield.Shatter(LeftEnd);
  FShield.Tick;
  Assert.AreEqual<TShieldState>(sdUp, FShield.State, 'Up');
  Assert.IsTrue(Holds(FShield), 'Still holds, where it broke too');
end;

procedure TShieldCrumbleTests.TestCrumbledItHoldsNoMore;
begin
  FShield.Shatter(LeftEnd);
  FShield.Crumble;
  Assert.AreEqual<TShieldState>(sdCrumbling, FShield.State, 'Crumbling');
  Assert.IsFalse(Holds(FShield), 'Holds no more');
  FShield.Shatter(TopMiddle);
  FShield.Crumble;
  Assert.AreEqual<TShieldState>(sdCrumbling, FShield.State, 'A blow does nothing');
  Assert.IsTrue(TicksTillDown(FShield) < ManyTicks, 'Goes out');
end;

procedure TShieldCrumbleTests.TestOutFromTheBreaksOutward;
begin
  var FromTheEnd := CrumbleTicks(LeftEnd);
  var FromTheMiddle := CrumbleTicks(TopMiddle);
  Assert.IsTrue(FromTheEnd > FromTheMiddle,
    Format('From the end %d ticks, from the middle %d', [FromTheEnd, FromTheMiddle]));
end;

procedure TShieldCrumbleTests.TestNoBreakItCrumblesFromTheMiddle;
begin
  FShield.Crumble;
  var Unbroken := TicksTillDown(FShield);
  Assert.IsTrue(Unbroken < ManyTicks, 'Goes out');
  Assert.IsTrue(Unbroken < CrumbleTicks(LeftEnd),
    Format('From the middle %d ticks, longer from the end', [Unbroken]));
end;

procedure TShieldCrumbleTests.TestRisenItIsWholeAgain;
begin
  FShield.Crumble;
  var Fresh := TicksTillDown(FShield);
  var Broken := TTekShield.Create(RadiusX, RadiusY);
  try
    Broken.Shatter(LeftEnd);
    Broken.Crumble;
    TicksTillDown(Broken);
    Broken.Rise;
    Assert.AreEqual<TShieldState>(sdUp, Broken.State, 'Up');
    Assert.IsTrue(Holds(Broken), 'Holds');
    Broken.Crumble;
    Assert.AreEqual(Fresh, TicksTillDown(Broken), 'The old break forgotten');
  finally
    Broken.Free;
  end;
end;

procedure TShieldCrumbleTests.TestAFallingShieldDoesNotCrumble;
begin
  FShield.Fall;
  FShield.Crumble;
  Assert.AreEqual<TShieldState>(sdFalling, FShield.State, 'Falling');
  Assert.IsTrue(TicksTillDown(FShield) < ManyTicks, 'Down as a fall');
end;

procedure TShieldCrumbleTests.TestVanishedItIsDownAtOnce;
begin
  FShield.Shatter(LeftEnd);
  FShield.Vanish;
  Assert.AreEqual<TShieldState>(sdDown, FShield.State, 'Down with no tick');
  Assert.IsFalse(Holds(FShield), 'Holds nothing');
  FShield.Tick;
  Assert.AreEqual<TShieldState>(sdDown, FShield.State, 'And stays down');
end;

initialization
  TDUnitX.RegisterTestFixture(TShieldCrumbleTests);

end.
