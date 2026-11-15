{
  Tests.Render.Target - how many times a banked frame is grown to cover its
  own unbanked place: not at all unbanked; 1.293 times at the 14 degrees of
  the titles' flight for the game's frame; alike either way; more for a
  steeper bank; an upright frame as the same one on its side; and grown so,
  it covers the unbanked frame's corners with nothing to spare.

  Where a point of the frame lands on the window: unturned where it
  stands; lowered by the drop; banked clockwise, as SDL turns a copy, about
  the frame's middle, the point the drop brings there standing still; and
  the sun of the titles where the stand's turned canvas has it at 23.2 and
  29.2 s of the flight.

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

  [TestFixture]
  TFrameTurnTests = class
  public
    [Test]
    procedure TestUnturnedAPointStandsWhereItIs;
    [Test]
    procedure TestTheDropLowersAPoint;
    [Test]
    procedure TestABankTurnsClockwiseAboutTheMiddle;
    [Test]
    procedure TestTheSunStandsWhereTheStandHasIt;
  end;

implementation

uses
  Sdl2.Core;

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

// TFrameTurnTests

const
  PointSlack = 0.001;
  SunX = 288;
  SunY = 208;

function Turned(ABankDegrees, ADrop: Single): TFrameTurn;
begin
  Result.Width := FrameWide;
  Result.Height := FrameTall;
  Result.BankDegrees := ABankDegrees;
  Result.Drop := ADrop;
  Result.Cover := BankCover(ABankDegrees, FrameWide, FrameTall);
end;

function Lands(const ATurn: TFrameTurn; AX, AY, AWantX, AWantY: Single): Boolean;
begin
  var At := ATurn.PointAt(AX, AY);
  Result := (Abs(At.X - AWantX) < PointSlack) and (Abs(At.Y - AWantY) < PointSlack);
end;

procedure TFrameTurnTests.TestUnturnedAPointStandsWhereItIs;
begin
  Assert.IsTrue(Lands(Turned(0, 0), SunX, SunY, SunX, SunY), 'The sun');
  Assert.IsTrue(Lands(Turned(0, 0), 0, 0, 0, 0), 'A corner');
end;

procedure TFrameTurnTests.TestTheDropLowersAPoint;
begin
  Assert.IsTrue(Lands(Turned(0, 30), SunX, SunY, SunX, SunY + 30), 'Thirty units down');
end;

procedure TFrameTurnTests.TestABankTurnsClockwiseAboutTheMiddle;
begin
  var Quarter := Turned(90, 0);
  Quarter.Cover := 1;
  Assert.IsTrue(Lands(Quarter, FrameWide / 2 + 100, FrameTall / 2,
    FrameWide / 2, FrameTall / 2 + 100), 'Right of the middle goes down');
  var Flight := Turned(14, 40);
  Assert.IsTrue(Lands(Flight, FrameWide / 2, FrameTall / 2 - 40, FrameWide / 2, FrameTall / 2),
    'What the drop brings to the middle stands still');
end;

// The stand's turnFrame on its canvas, the sun put through its transform
procedure TFrameTurnTests.TestTheSunStandsWhereTheStandHasIt;
const
  // 23.2 s: banked 14, level
  BankedX = 291.13822331338326;
  BankedY = 222.0799404361714;
  // 29.2 s: banked 0.5, the nose up 7 - the frame lowered 1024 tan 7
  ClimbBank = 0.5;
  ClimbDrop = 125.73139036457431;
  ClimbX = 287.1187132935531;
  ClimbY = 335.6521207353218;
begin
  Assert.IsTrue(Lands(Turned(FlightBank, 0), SunX, SunY, BankedX, BankedY), 'Out of the dome');
  Assert.IsTrue(Lands(Turned(ClimbBank, ClimbDrop), SunX, SunY, ClimbX, ClimbY), 'Climbing');
end;

initialization
  TDUnitX.RegisterTestFixture(TBankCoverTests);
  TDUnitX.RegisterTestFixture(TFrameTurnTests);

end.
