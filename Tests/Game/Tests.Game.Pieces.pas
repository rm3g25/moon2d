{
  Tests.Game.Pieces - what is left of a barge that breaks: nothing till
  one does; it breaks into several pieces that make up its whole picture,
  each starting where it was in the barge, turned as the barge was; they
  tumble, keep a share of the barge's way, fall and are gone within a few
  seconds, and the air is empty again; a second barge breaks while the
  first one's pieces fall; a clear takes them away; the same dice, the
  same flight.

  The pieces fly in no picture here: the rules need none.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Game.Pieces;

interface

uses
  DUnitX.TestFramework,
  Game.Pieces;

type
  [TestFixture]
  TBargePiecesTests = class
  private
    FPieces: TBargePieces;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestNothingTillABargeBreaks;
    [Test]
    procedure TestItBreaksIntoPiecesOfItsWholePicture;
    [Test]
    procedure TestEachPieceStartsWhereItWasInTheBarge;
    [Test]
    procedure TestATurnedBargeBreaksTurned;
    [Test]
    procedure TestTheyTumble;
    [Test]
    procedure TestTheyKeepAShareOfTheBargesWay;
    [Test]
    procedure TestTheyFallAndAreGoneSoon;
    [Test]
    procedure TestASecondBargeBreaksWhileTheFirstFalls;
    [Test]
    procedure TestAClearTakesThemAway;
    [Test]
    procedure TestSameDiceSameFlight;
  end;

implementation

uses
  System.Math,
  System.SysUtils,
  Sdl2.Core,
  Game.Space;

const
  Seed = 11;
  // A middle barge of the flock, over the main barge's deck
  BargeWidth = 104.0;
  BargeHeight = 14.0;
  MiddleX = 256.0;
  MiddleY = 330.0;
  // Six seconds
  GoneTicks = 200;
  Slack = 0.01;

function BargeGoing(ASpeedX, ASpeedY: Single; ASpin: Single = 0): TBrokenBarge;
begin
  Result := Default(TBrokenBarge);
  Result.Middle.X := MiddleX;
  Result.Middle.Y := MiddleY;
  Result.Width := BargeWidth;
  Result.Height := BargeHeight;
  Result.Spin := ASpin;
  Result.Speed.X := ASpeedX;
  Result.Speed.Y := ASpeedY;
end;

procedure TBargePiecesTests.Setup;
begin
  FPieces := TBargePieces.Create(Seed);
end;

procedure TBargePiecesTests.TearDown;
begin
  FPieces.Free;
end;

procedure TBargePiecesTests.TestNothingTillABargeBreaks;
begin
  Assert.AreEqual(0, FPieces.Count, 'None');
  Assert.IsFalse(FPieces.Falling, 'None in the air');
  FPieces.Tick;
  Assert.AreEqual(0, FPieces.Count, 'Still none');
end;

procedure TBargePiecesTests.TestItBreaksIntoPiecesOfItsWholePicture;
begin
  FPieces.Shatter(BargeGoing(0, 0));
  Assert.IsTrue(FPieces.Count >= 4, 'Several pieces');
  Assert.IsTrue(FPieces.Falling, 'In the air');
  var PictureShare: Single := 0;
  var Area: Single := 0;
  for var i := 0 to FPieces.Count - 1 do
  begin
    var Piece := FPieces[i];
    Assert.IsTrue((Piece.Part.X >= -Slack) and (Piece.Part.Y >= -Slack) and
      (Piece.Part.X + Piece.Part.W <= 1 + Slack) and
      (Piece.Part.Y + Piece.Part.H <= 1 + Slack),
      'Piece ' + i.ToString + ': a part out of the picture');
    PictureShare := PictureShare + Piece.Part.W * Piece.Part.H;
    Area := Area + Piece.Width * Piece.Height;
  end;
  Assert.AreEqual(1.0, Double(PictureShare), Slack, 'The whole picture, once');
  Assert.AreEqual(Double(BargeWidth * BargeHeight), Double(Area), 1.0,
    'As much of it as the barge was');
end;

procedure TBargePiecesTests.TestEachPieceStartsWhereItWasInTheBarge;
begin
  FPieces.Shatter(BargeGoing(0, 0));
  for var i := 0 to FPieces.Count - 1 do
  begin
    var Piece := FPieces[i];
    Assert.IsTrue(Abs(Piece.Middle.X - MiddleX) <= BargeWidth / 2,
      'Piece ' + i.ToString + ': beside the barge');
    Assert.IsTrue(Abs(Piece.Middle.Y - MiddleY) <= BargeHeight / 2,
      'Piece ' + i.ToString + ': over or under the barge');
    // The left of the picture is the left of the barge, its top the top
    var Along := (Piece.Part.X + Piece.Part.W / 2 - 0.5) * BargeWidth;
    var Down := (Piece.Part.Y + Piece.Part.H / 2 - 0.5) * BargeHeight;
    Assert.AreEqual(Double(MiddleX + Along), Double(Piece.Middle.X), Slack,
      'Piece ' + i.ToString + ': across');
    Assert.AreEqual(Double(MiddleY + Down), Double(Piece.Middle.Y), Slack,
      'Piece ' + i.ToString + ': down');
  end;
end;

// A quarter turn clockwise: what was along the barge is down the screen
procedure TBargePiecesTests.TestATurnedBargeBreaksTurned;
begin
  FPieces.Shatter(BargeGoing(0, 0, 90));
  for var i := 0 to FPieces.Count - 1 do
  begin
    var Piece := FPieces[i];
    Assert.AreEqual(90.0, Double(Piece.Spin), Slack, 'Turned as the barge was');
    Assert.IsTrue(Abs(Piece.Middle.X - MiddleX) <= BargeHeight / 2 + Slack,
      'Piece ' + i.ToString + ': across');
    Assert.IsTrue(Abs(Piece.Middle.Y - MiddleY) <= BargeWidth / 2 + Slack,
      'Piece ' + i.ToString + ': down');
    var Along := (Piece.Part.X + Piece.Part.W / 2 - 0.5) * BargeWidth;
    Assert.AreEqual(Double(MiddleY + Along), Double(Piece.Middle.Y), Slack,
      'Piece ' + i.ToString + ': the barge''s length runs down');
  end;
end;

procedure TBargePiecesTests.TestTheyTumble;
begin
  FPieces.Shatter(BargeGoing(0, 0));
  FPieces.Tick;
  for var i := 0 to FPieces.Count - 1 do
    Assert.IsTrue(Abs(FPieces[i].Spin - FPieces[i].LastSpin) > 1,
      'Piece ' + i.ToString + ' does not turn');
end;

// Two barges of the same dice, one going right and one still: each piece
// of the first goes farther right than its twin, by less than the barge
// went
procedure TBargePiecesTests.TestTheyKeepAShareOfTheBargesWay;
const
  BargePace = 10.0;
begin
  var Still := TBargePieces.Create(Seed);
  try
    FPieces.Shatter(BargeGoing(BargePace, 0));
    Still.Shatter(BargeGoing(0, 0));
    FPieces.Tick;
    Still.Tick;
    for var i := 0 to FPieces.Count - 1 do
    begin
      var Carried := FPieces[i].Middle.X - Still[i].Middle.X;
      Assert.IsTrue(Carried > 0, 'Piece ' + i.ToString + ': not carried on');
      Assert.IsTrue(Carried < BargePace, 'Piece ' + i.ToString + ': as fast as the barge');
    end;
  finally
    Still.Free;
  end;
end;

procedure TBargePiecesTests.TestTheyFallAndAreGoneSoon;
begin
  FPieces.Shatter(BargeGoing(-6, 8));
  var Lowest: Single := 0;
  for var Tick := 1 to GoneTicks do
  begin
    for var i := 0 to FPieces.Count - 1 do
      Lowest := Max(Lowest, FPieces[i].Middle.Y);
    FPieces.Tick;
  end;
  Assert.IsFalse(FPieces.Falling, 'None in the air');
  Assert.AreEqual(0, FPieces.Count, 'The air is empty for the next');
  Assert.IsTrue(Lowest > ScreenHeight - 1, 'They went down, under the screen');
end;

procedure TBargePiecesTests.TestASecondBargeBreaksWhileTheFirstFalls;
begin
  FPieces.Shatter(BargeGoing(0, 0));
  var First := FPieces.Count;
  FPieces.Tick;
  FPieces.Shatter(BargeGoing(0, 0));
  Assert.AreEqual(2 * First, FPieces.Count, 'Both barges'' pieces');
end;

procedure TBargePiecesTests.TestAClearTakesThemAway;
begin
  FPieces.Shatter(BargeGoing(0, 0));
  FPieces.Tick;
  FPieces.Clear;
  Assert.AreEqual(0, FPieces.Count, 'None');
  Assert.IsFalse(FPieces.Falling, 'None in the air');
end;

procedure TBargePiecesTests.TestSameDiceSameFlight;
begin
  var Twin := TBargePieces.Create(Seed);
  try
    FPieces.Shatter(BargeGoing(3, 5, 40));
    Twin.Shatter(BargeGoing(3, 5, 40));
    for var Tick := 1 to 20 do
    begin
      FPieces.Tick;
      Twin.Tick;
    end;
    Assert.AreEqual(Twin.Count, FPieces.Count, 'As many');
    for var i := 0 to FPieces.Count - 1 do
    begin
      Assert.AreEqual(Double(Twin[i].Middle.X), Double(FPieces[i].Middle.X), Slack,
        'Piece ' + i.ToString + ': across');
      Assert.AreEqual(Double(Twin[i].Middle.Y), Double(FPieces[i].Middle.Y), Slack,
        'Piece ' + i.ToString + ': down');
      Assert.AreEqual(Double(Twin[i].Spin), Double(FPieces[i].Spin), Slack,
        'Piece ' + i.ToString + ': its turn');
    end;
  finally
    Twin.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TBargePiecesTests);

end.
