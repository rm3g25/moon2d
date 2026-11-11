{
  Tests.Game.Shield - a TEK shield broken and crumbling: a heavy blow
  breaks a piece off it, and it still holds; crumbled, it holds no more,
  and blows do nothing; it goes out from the pieces broken off outward -
  broken at one end, it takes longer than broken in its middle - and from
  its middle when none is; risen, it is whole again and the old breaks
  are forgotten; a shield already falling does not crumble.

  Restored: only from down, it holds at once, rises and is up; it may
  fall while it rises. Over a body afloat it holds under the body's
  bottom, where over a standing body it does not; hidden cells hold.

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

  [TestFixture]
  TShieldRestoreTests = class
  private
    FShield: TTekShield;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestRestoredItHoldsAtOnceAndComesUp;
    [Test]
    procedure TestOnlyADownShieldIsRestored;
    [Test]
    procedure TestARisingShieldFalls;
    [Test]
    procedure TestAfloatItHoldsUnderTheBody;
    [Test]
    procedure TestHiddenCellsHold;
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

{ TShieldRestoreTests }

const
  RestoreTicks = 12;
  BodyWidth = 40;
  BodyHeight = 20;

function SolidBody: TShieldMask;
begin
  Result.Width := BodyWidth;
  Result.Height := BodyHeight;
  Result.Middle.X := BodyWidth / 2;
  Result.Middle.Y := BodyHeight / 2;
  SetLength(Result.Solid, BodyWidth * BodyHeight);
  for var i := 0 to High(Result.Solid) do
    Result.Solid[i] := True;
end;

// Straight up into the body from just under its bottom
function HoldsJustUnder(AShield: TTekShield): Boolean;
begin
  var Entry: TSdlFPoint;
  var Under: Single := BodyHeight / 2 + 1;
  Result := AShield.TryEntry(At(0, Under + 0.5), At(0, Under), Entry);
end;

procedure TShieldRestoreTests.Setup;
begin
  FShield := TTekShield.Create(RadiusX, RadiusY);
  FShield.Vanish;
end;

procedure TShieldRestoreTests.TearDown;
begin
  FShield.Free;
end;

procedure TShieldRestoreTests.TestRestoredItHoldsAtOnceAndComesUp;
begin
  FShield.Restore(LeftEnd, RestoreTicks);
  Assert.AreEqual<TShieldState>(sdRising, FShield.State, 'Rising');
  Assert.IsTrue(Holds(FShield), 'Holds before a tick');
  var Ticks := 0;
  while (FShield.State = sdRising) and (Ticks < ManyTicks) do
  begin
    FShield.Tick;
    Inc(Ticks);
  end;
  Assert.AreEqual<TShieldState>(sdUp, FShield.State, 'Up');
  Assert.IsTrue(Ticks >= RestoreTicks, Format('Up in %d ticks', [Ticks]));
end;

procedure TShieldRestoreTests.TestOnlyADownShieldIsRestored;
begin
  FShield.Rise;
  FShield.Restore(LeftEnd, RestoreTicks);
  Assert.AreEqual<TShieldState>(sdUp, FShield.State, 'Up stays up');
  FShield.Fall;
  FShield.Restore(LeftEnd, RestoreTicks);
  Assert.AreEqual<TShieldState>(sdFalling, FShield.State, 'Falling goes on');
end;

procedure TShieldRestoreTests.TestARisingShieldFalls;
begin
  FShield.Restore(LeftEnd, RestoreTicks);
  FShield.Tick;
  FShield.Fall;
  Assert.AreEqual<TShieldState>(sdFalling, FShield.State, 'Falling');
  Assert.IsFalse(Holds(FShield), 'Holds no more');
  Assert.IsTrue(TicksTillDown(FShield) < ManyTicks, 'Down');
end;

procedure TShieldRestoreTests.TestAfloatItHoldsUnderTheBody;
begin
  var Standing := TTekShield.CreateOver(SolidBody);
  try
    Assert.IsFalse(HoldsJustUnder(Standing), 'Standing: the floor, no shield');
  finally
    Standing.Free;
  end;
  var Afloat := TTekShield.CreateAfloat(SolidBody);
  try
    Assert.IsTrue(HoldsJustUnder(Afloat), 'Afloat: shielded under it');
  finally
    Afloat.Free;
  end;
end;

procedure TShieldRestoreTests.TestHiddenCellsHold;
var
  Whole: TSdlFRect;
begin
  Whole.X := -2 * RadiusX;
  Whole.Y := -2 * RadiusY;
  Whole.W := 4 * RadiusX;
  Whole.H := 4 * RadiusY;
  FShield.Rise;
  FShield.Hide(Whole);
  Assert.IsTrue(Holds(FShield), 'All hidden, it holds');
end;

initialization
  TDUnitX.RegisterTestFixture(TShieldCrumbleTests);
  TDUnitX.RegisterTestFixture(TShieldRestoreTests);

end.
