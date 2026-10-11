{
  Tests.Levels.Graph - what a level makes of a graph in its dynamics
  section: the kind is known, every word of it is read, a missing word
  comes to a default, and the numbers and words the parser turns down.

  Each object is parsed from a JSON text of the test, placed on a screen
  of its own. How the trace is laid out and drawn has no test here: none
  of it shows without drawing, and what a trace answers for a moment is
  tried in Tests.Effects.Traces.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Levels.Graph;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TLevelGraphTests = class
  public
    [Test]
    procedure TestBareGraphComesToItsDefaults;
    [Test]
    procedure TestGraphReadsEveryWordItIsGiven;
    [Test]
    procedure TestEveryShapeWordIsRead;
    [Test]
    procedure TestShapeWordIsReadInAnyCase;
    [Test]
    procedure TestUnknownShapeRaises;
    [Test]
    procedure TestSizesAndRatesAtZeroRaise;
    [Test]
    procedure TestPercentagesOutOfRangeRaise;
    [Test]
    procedure TestBadGridOrPlateTintRaises;
    [Test]
    procedure TestGraphIsFoundInTheListByItsTag;
  end;

implementation

uses
  System.SysUtils, System.JSON, Levels.Dynamics, Levels.Tint;

const
  ShapeWords: array [0..6] of string = ('heartbeat', 'sine', 'square', 'saw',
    'noise', 'flat', 'bars');
  PositiveWords: array [0..5] of string = ('width', 'height', 'frequency',
    'sweep', 'thickness', 'gridStep');
  PercentWords: array [0..3] of string = ('amplitude', 'glow', 'grid', 'plate');
  OutOfRange: array [0..1] of string = ('101', '-1');
  FullGraph =
    ',"width":31,"height":15,"shape":"saw","tint":[30,100,50],"frequency":1.2,' +
    '"amplitude":70,"sweep":2.2,"thickness":1,"grid":18,"gridStep":4,' +
    '"gridTint":[20,70,35],"plate":10,"plateTint":[2,5,4],"glow":60,' +
    '"intensity":85,"layer":"front","tag":"scope"';

function GraphText(const AFields: string): string;
begin
  Result := '{"kind":"graph","screen":1,"x":4,"y":6' + AFields + '}';
end;

// The caller owns the result
function ParseGraph(const AFields: string): TDynamicObject;
begin
  var Root := TJSONObject.ParseJSONValue(GraphText(AFields)) as TJSONObject;
  Assert.IsNotNull(Root, 'The text of the test is JSON');
  try
    Result := ParseDynamic(Root, 'test', '#1');
  finally
    Root.Free;
  end;
end;

procedure ExpectParses(const AFields, AWhat: string);
begin
  var Parsed := ParseGraph(AFields);
  try
    Assert.IsTrue(Parsed is TGraph, AWhat);
  finally
    Parsed.Free;
  end;
end;

// By value, not const: an anonymous method captures them
procedure ExpectRaises(AClass: ExceptClass; AFields, AWhat: string);
begin
  Assert.WillRaise(
    procedure
    begin
      ParseGraph(AFields).Free;
    end, AClass, AWhat);
end;

// A graph with nothing but its place hangs on a screen by the back layer,
// like the other things that glow behind the hero
procedure TLevelGraphTests.TestBareGraphComesToItsDefaults;
begin
  var Parsed := ParseGraph('');
  try
    Assert.IsTrue(Parsed is TGraph, 'The kind "graph" builds a graph');
    Assert.AreEqual<TDynamicLayer>(dlBack, Parsed.Placement.Layer);
    Assert.AreEqual('', Parsed.Placement.Tag);
    Assert.IsTrue(Parsed.GoesOutWithParent, 'It goes out with its monitor');
  finally
    Parsed.Free;
  end;
end;

procedure TLevelGraphTests.TestGraphReadsEveryWordItIsGiven;
begin
  var Parsed := ParseGraph(FullGraph);
  try
    Assert.IsTrue(Parsed is TGraph, 'A graph with every word');
    Assert.AreEqual<TDynamicLayer>(dlFront, Parsed.Placement.Layer);
    Assert.AreEqual('scope', Parsed.Placement.Tag);
    Assert.AreEqual(30, Integer(Parsed.Placement.Tint.R));
    Assert.AreEqual(100, Integer(Parsed.Placement.Tint.G));
    Assert.AreEqual(50, Integer(Parsed.Placement.Tint.B));
  finally
    Parsed.Free;
  end;
end;

procedure TLevelGraphTests.TestEveryShapeWordIsRead;
begin
  for var Shape in ShapeWords do
    ExpectParses(',"shape":"' + Shape + '"', 'The shape ' + Shape);
end;

procedure TLevelGraphTests.TestShapeWordIsReadInAnyCase;
begin
  ExpectParses(',"shape":"HeartBeat"', 'The shape HeartBeat');
end;

procedure TLevelGraphTests.TestUnknownShapeRaises;
begin
  ExpectRaises(EDynamicError, ',"shape":"zigzag"', 'The shape zigzag');
end;

// A frame, a pace or a step of zero draws nothing, or never ends
procedure TLevelGraphTests.TestSizesAndRatesAtZeroRaise;
begin
  for var Key in PositiveWords do
    ExpectRaises(EDynamicError, ',"' + Key + '":0', Key + ' of 0');
end;

procedure TLevelGraphTests.TestPercentagesOutOfRangeRaise;
begin
  for var Key in PercentWords do
    for var Value in OutOfRange do
      ExpectRaises(EDynamicError, ',"' + Key + '":' + Value,
        Key + ' of ' + Value);
end;

// The grid and the plate have tints of their own, read as strictly as the
// tint of the trace
procedure TLevelGraphTests.TestBadGridOrPlateTintRaises;
begin
  ExpectRaises(ETintError, ',"gridTint":[20,70]', 'A grid tint of two numbers');
  ExpectRaises(ETintError, ',"plateTint":[2,5,101]', 'A plate tint over 100');
end;

procedure TLevelGraphTests.TestGraphIsFoundInTheListByItsTag;
begin
  var Root := TJSONObject.ParseJSONValue(
    '{"dynamics":[' + GraphText(',"tag":"scope"') + ']}') as TJSONObject;
  Assert.IsNotNull(Root, 'The text of the test is JSON');
  try
    var Objects := ParseDynamics(Root, 'test');
    try
      Assert.IsTrue(Objects.AnyTagged('scope', TGraph), 'Found as a graph');
      Assert.IsFalse(Objects.AnyTagged('scope', TBeacon), 'Not a beacon');
    finally
      Objects.Free;
    end;
  finally
    Root.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TLevelGraphTests);

end.
