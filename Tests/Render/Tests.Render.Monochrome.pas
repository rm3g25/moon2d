{
  Tests.Render.Monochrome - a pixel made monochrome: its three channels
  one grey; a colour goes to the grey the eye sees in it; the middle grey
  stays, what is lighter goes lighter and what is darker darker, never
  past white or black; with no contrast added the grey is as it was; the
  alpha is kept; pure black, which the cache keys out, is clear.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Render.Monochrome;

interface

uses
  DUnitX.TestFramework,
  Render.Monochrome;

type
  [TestFixture]
  TMonochromeTests = class
  public
    [Test]
    procedure TestOneGreyInAllThree;
    [Test]
    procedure TestTheGreyTheEyeSees;
    [Test]
    procedure TestTheMiddleStaysTheRestSpreads;
    [Test]
    procedure TestNeverPastWhiteOrBlack;
    [Test]
    procedure TestNoContrastAddedTheGreyAsItWas;
    [Test]
    procedure TestTheAlphaKept;
    [Test]
    procedure TestPureBlackClear;
  end;

implementation

const
  Contrast = 1.6;
  NoContrast = 1.0;

function Rgba(AR, AG, AB, AA: Byte): TRgbaBytes;
begin
  Result[0] := AR;
  Result[1] := AG;
  Result[2] := AB;
  Result[3] := AA;
end;

procedure TMonochromeTests.TestOneGreyInAllThree;
begin
  var Mono := MonochromeOf(Rgba(30, 120, 220, 255), Contrast);
  Assert.AreEqual(Mono[0], Mono[1], 'Green as red');
  Assert.AreEqual(Mono[0], Mono[2], 'Blue as red');
end;

// Pure green looks lighter than pure blue of the same strength
procedure TMonochromeTests.TestTheGreyTheEyeSees;
begin
  var Green := MonochromeOf(Rgba(0, 200, 1, 255), NoContrast);
  var Blue := MonochromeOf(Rgba(1, 0, 200, 255), NoContrast);
  Assert.IsTrue(Green[0] > Blue[0], 'Green the lighter');
  Assert.AreEqual(Integer(Round(0.587 * 200 + 0.114)), Integer(Green[0]),
    'Its weights');
end;

procedure TMonochromeTests.TestTheMiddleStaysTheRestSpreads;
begin
  var Middle := MonochromeOf(Rgba(128, 128, 128, 255), Contrast);
  Assert.IsTrue(Abs(Integer(Middle[0]) - 128) <= 1, 'The middle stays');
  var Light := MonochromeOf(Rgba(180, 180, 180, 255), Contrast);
  Assert.IsTrue(Light[0] > 180, 'Lighter goes lighter');
  var Dark := MonochromeOf(Rgba(80, 80, 80, 255), Contrast);
  Assert.IsTrue(Dark[0] < 80, 'Darker goes darker');
end;

procedure TMonochromeTests.TestNeverPastWhiteOrBlack;
begin
  var White := MonochromeOf(Rgba(250, 250, 250, 255), Contrast);
  Assert.AreEqual(Byte(255), White[0], 'White');
  var Black := MonochromeOf(Rgba(10, 10, 10, 255), Contrast);
  Assert.AreEqual(Byte(0), Black[0], 'Black');
end;

procedure TMonochromeTests.TestNoContrastAddedTheGreyAsItWas;
begin
  for var Level := 1 to 255 do
  begin
    var Mono := MonochromeOf(Rgba(Level, Level, Level, 255), NoContrast);
    Assert.AreEqual(Byte(Level), Mono[0], 'As it was');
  end;
end;

procedure TMonochromeTests.TestTheAlphaKept;
begin
  Assert.AreEqual(Byte(90), MonochromeOf(Rgba(200, 40, 40, 90), Contrast)[3],
    'Half clear');
  Assert.AreEqual(Byte(255), MonochromeOf(Rgba(1, 1, 1, 255), Contrast)[3],
    'All but black is solid');
end;

procedure TMonochromeTests.TestPureBlackClear;
begin
  Assert.AreEqual(Byte(0), MonochromeOf(Rgba(0, 0, 0, 255), Contrast)[3],
    'Keyed out');
end;

initialization
  TDUnitX.RegisterTestFixture(TMonochromeTests);

end.
