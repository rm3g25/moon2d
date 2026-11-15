{
  Tests.Render.Target - how many times a banked frame is grown to cover its
  own unbanked place: not at all unbanked; 1.293 times at the 14 degrees of
  the titles' flight for the game's frame; alike either way; more for a
  steeper bank; an upright frame as the same one on its side; and grown so,
  it covers the unbanked frame's corners with nothing to spare.

  The texture, the viewport and the copy are the card's: a live run.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Render.Target;

interface

uses
  DUnitX.TestFramework,
  Render.Target;

type
  [TestFixture]
  TBankCoverTests = class
  public
    [Test]
    procedure TestUnbankedNotGrown;
    [Test]
    procedure TestTheFlightsBankOfTheGamesFrame;
    [Test]
    procedure TestEitherWayAlike;
    [Test]
    procedure TestASteeperBankGrowsMore;
    [Test]
    procedure TestAnUprightFrameAsOneOnItsSide;
    [Test]
    procedure TestTheGrownFrameCoversTheCornersAndNoMore;
  end;

implementation

const
  FrameWide = 512;
  FrameTall = 384;
  FlightBank = 14;
  Slack = 0.00001;
  // Units of the frame: the cover is a Single
  CornerSlack = 0.01;

// A corner of the unbanked frame, from its middle, seen from the frame
// grown ACover times and banked: how far past the grown frame's edge it
// lies. Over none - the corner is bare
function BaredBy(ABankDegrees, ACover, ACornerX, ACornerY: Double): Double;
begin
  var Turn: Double := ABankDegrees * Pi / 180;
  var Along: Double := Abs(ACornerX * Cos(Turn) + ACornerY * Sin(Turn));
  var Across: Double := Abs(ACornerY * Cos(Turn) - ACornerX * Sin(Turn));
  var PastSide: Double := Along - ACover * FrameWide / 2;
  var PastTop: Double := Across - ACover * FrameTall / 2;
  if PastSide > PastTop then
    Result := PastSide
  else
    Result := PastTop;
end;

procedure TBankCoverTests.TestUnbankedNotGrown;
begin
  var Cover: Double := BankCover(0, FrameWide, FrameTall);
  Assert.IsTrue(Abs(Cover - 1) < Slack, 'As it is');
end;

procedure TBankCoverTests.TestTheFlightsBankOfTheGamesFrame;
begin
  var Cover: Double := BankCover(FlightBank, FrameWide, FrameTall);
  Assert.IsTrue(Abs(Cover - 1.2929) < 0.0001, 'The stand''s 1.293');
end;

procedure TBankCoverTests.TestEitherWayAlike;
begin
  var Clockwise: Double := BankCover(FlightBank, FrameWide, FrameTall);
  var Counter: Double := BankCover(-FlightBank, FrameWide, FrameTall);
  Assert.IsTrue(Abs(Clockwise - Counter) < Slack, 'The same growth');
end;

procedure TBankCoverTests.TestASteeperBankGrowsMore;
begin
  var Slight: Double := BankCover(5, FrameWide, FrameTall);
  var Flight: Double := BankCover(FlightBank, FrameWide, FrameTall);
  var Steep: Double := BankCover(25, FrameWide, FrameTall);
  Assert.IsTrue(Slight > 1, 'A slight bank grows it');
  Assert.IsTrue(Flight > Slight, 'The flight''s more');
  Assert.IsTrue(Steep > Flight, 'A steep one more still');
end;

procedure TBankCoverTests.TestAnUprightFrameAsOneOnItsSide;
begin
  var OnItsSide: Double := BankCover(FlightBank, FrameWide, FrameTall);
  var Upright: Double := BankCover(FlightBank, FrameTall, FrameWide);
  Assert.IsTrue(Abs(OnItsSide - Upright) < Slack, 'The same growth');
end;

procedure TBankCoverTests.TestTheGrownFrameCoversTheCornersAndNoMore;
begin
  var Cover: Double := BankCover(FlightBank, FrameWide, FrameTall);
  var LowerCorner: Double := BaredBy(FlightBank, Cover, FrameWide / 2, FrameTall / 2);
  var UpperCorner: Double := BaredBy(FlightBank, Cover, FrameWide / 2, -FrameTall / 2);
  Assert.IsTrue(LowerCorner <= CornerSlack, 'The lower corner is covered');
  Assert.IsTrue(UpperCorner <= CornerSlack, 'The upper corner is covered');
  Assert.IsTrue(UpperCorner >= -CornerSlack, 'With nothing to spare: it lies on the edge');
end;

initialization
  TDUnitX.RegisterTestFixture(TBankCoverTests);

end.
