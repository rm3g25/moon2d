{
  Tests.Pads.Decks - a deck of the collision grid ('2') as the pad world
  sees it: a floor from above only, a body that bursts bullets, and no
  wall to the hero from below or the sides.

  The room is the empty one with a run of decks on its row 8, columns 5
  to 7 (from 1): a deck line at y = 224, a body down to y = 256, x from
  128 to 224.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Pads.Decks;

interface

uses
  DUnitX.TestFramework,
  Levels.Defs,
  Pads.World;

type
  [TestFixture]
  TDeckTests = class
  private
    FLevel: TLevel;
    FWorld: TPadWorld;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestDeckHoldsFeetStandingOnIt;
    [Test]
    procedure TestFeetFallingOntoDeckAreCaught;
    [Test]
    procedure TestFeetRisingFromBelowPassThrough;
    [Test]
    procedure TestDeckStopsBulletsInItsBodyOnly;
    [Test]
    procedure TestDeckIsNoWallToTheLevel;
    [Test]
    procedure TestDeckIsNotUnderFeetBesideIt;
  end;

implementation

uses
  System.SysUtils,
  Tests.Rooms;

const
  Screen = 1;
  DeckTop = 224;
  DeckBottom = 256;
  DeckLeft = 128;
  DeckRight = 224;
  DeckRowIndex = 7;
  DeckColIndex = 4;
  // A hero's feet span this wide
  FeetWidth = 16;
  MiddleOfDeck = 176;

function DeckRows: TArray<string>;
begin
  Result := RoomRowsOf(0, 0, 0, 0);
  Result[DeckRowIndex] := '....222.........';
end;

procedure TDeckTests.Setup;
begin
  FLevel := LevelFromRows(DeckRows, '');
  FWorld := TPadWorld.Create(nil, nil, FLevel, nil, 1);
end;

procedure TDeckTests.TearDown;
begin
  FreeAndNil(FWorld);
  FreeAndNil(FLevel);
end;

procedure TDeckTests.TestDeckHoldsFeetStandingOnIt;
begin
  Assert.IsNotNull(
    FWorld.DeckUnder(Screen, MiddleOfDeck, MiddleOfDeck + FeetWidth, DeckTop),
    'Feet on the deck line');
  Assert.IsNull(
    FWorld.DeckUnder(Screen, MiddleOfDeck, MiddleOfDeck + FeetWidth,
      DeckBottom),
    'Feet at the underside of the body');
end;

procedure TDeckTests.TestFeetFallingOntoDeckAreCaught;
begin
  Assert.IsNotNull(
    FWorld.DeckCrossed(Screen, MiddleOfDeck, MiddleOfDeck + FeetWidth,
      DeckTop - 4, DeckTop + 2, nil),
    'Feet from above to the deck line');
end;

procedure TDeckTests.TestFeetRisingFromBelowPassThrough;
begin
  Assert.IsNull(
    FWorld.DeckCrossed(Screen, MiddleOfDeck, MiddleOfDeck + FeetWidth,
      DeckBottom + 8, DeckTop - 2, nil),
    'Feet from below to over the deck');
end;

procedure TDeckTests.TestDeckStopsBulletsInItsBodyOnly;
begin
  Assert.IsTrue(FWorld.StopsBulletAt(Screen, MiddleOfDeck, DeckTop + 8),
    'In the body');
  Assert.IsFalse(FWorld.StopsBulletAt(Screen, MiddleOfDeck, DeckTop - 4),
    'Above the deck');
  Assert.IsFalse(FWorld.StopsBulletAt(Screen, MiddleOfDeck, DeckBottom + 4),
    'Below the body');
  Assert.IsFalse(FWorld.StopsBulletAt(Screen, DeckLeft - 4, DeckTop + 8),
    'Beside the deck');
  Assert.IsFalse(FWorld.StopsBulletAt(Screen, DeckRight + 4, DeckTop + 8),
    'Beside the deck on the other side');
end;

procedure TDeckTests.TestDeckIsNoWallToTheLevel;
begin
  for var Col := DeckColIndex to DeckColIndex + 2 do
    Assert.IsFalse(FLevel.SolidAt(Screen, Col, DeckRowIndex),
      'Deck cell ' + IntToStr(Col));
end;

procedure TDeckTests.TestDeckIsNotUnderFeetBesideIt;
begin
  Assert.IsNull(
    FWorld.DeckUnder(Screen, DeckRight + 40, DeckRight + 40 + FeetWidth,
      DeckTop),
    'Feet off to the right of the run');
end;

initialization
  TDUnitX.RegisterTestFixture(TDeckTests);

end.
