{
  Tests.Levels.Dynamics - the craft, the one dynamic object that never
  moves by itself: where it stands until a scene moves it, how each of its
  axes heads where it is sent, and what its file says it may do. And the
  two looks of a beam, as far as the file reads them.

  A craft is made from JSON, as the level reads it, and ticked by the test
  with its origin at the corner of the screen: it hangs on nothing. Its
  corner (CornerAt) is all a test sees of it; the parts that turn and
  slide are drawn, never read.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Levels.Dynamics;

interface

uses
  DUnitX.TestFramework,
  Levels.Dynamics;

type
  [TestFixture]
  TCraftTests = class
  private
    FCraft: TCraft;
    procedure UseCraft;
    procedure TickCraft(ATimes: Integer);
  public
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestCraftStandsWhereTheFileSaysUntilMoved;
    [Test]
    procedure TestCraftMovesEachAxisOnItsOwn;
    [Test]
    procedure TestCraftMovedInNoTicksIsThereAtOnce;
    [Test]
    procedure TestCraftGetsThereByItsTicksAndStays;
    [Test]
    procedure TestEaseShapesTheWayNotTheEnd;
    [Test]
    procedure TestCornerBetweenTicksLiesBetweenThem;
    [Test]
    procedure TestRewindPutsTheCraftBackAtOnce;
    [Test]
    procedure TestCraftKnowsWhichPartsFollow;
    [Test]
    procedure TestBadCraftRaises;
    [Test]
    procedure TestBeamReadsItsLook;
  end;

implementation

uses
  System.JSON,
  System.SysUtils;

const
  LevelId = 'test';
  // Where the file puts the craft's corner
  FileX = 10;
  FileY = -50;
  SingleSlack = 0.001;
  Eases: array [0..3] of TMotionEase = (meLinear, meIn, meOut, meInOut);
  // A beam's look as a file gives it: none, then the two words
  BeamLooks: array [0..2] of string = ('', ',"look":"scan"',
    ',"look":"tractor"');
  CraftJson = '{"kind":"craft","tag":"ship","screen":1,"body":"hull",' +
    '"width":100,"x":10,"y":-50,"parts":[' +
    '{"sprite":"gun","tag":"gun","at":[10,20],"width":8,"anchor":"pivot",' +
    '"pivot":[4,0],"turns":30},' +
    '{"sprite":"iris","tag":"iris","at":[50,20],"width":4,' +
    '"anchor":"center","reach":3},' +
    '{"sprite":"plate","tag":"plate","at":[0,0],"width":20}]}';

function IsNear(AValue: Single; AExpected: Double): Boolean;
begin
  Result := Abs(AValue - AExpected) < SingleSlack;
end;

function DynamicOf(const AJson: string): TDynamicObject;
begin
  var Obj := TJSONObject.ParseJSONValue(AJson) as TJSONObject;
  try
    Result := ParseDynamic(Obj, LevelId, '#1');
  finally
    Obj.Free;
  end;
end;

// By value, not const: an anonymous method captures it
procedure ExpectRaises(AJson, AWhat: string);
begin
  Assert.WillRaise(
    procedure
    begin
      DynamicOf(AJson).Free;
    end, EDynamicError, AWhat);
end;

procedure TCraftTests.TearDown;
begin
  FreeAndNil(FCraft);
end;

procedure TCraftTests.UseCraft;
begin
  FreeAndNil(FCraft);
  FCraft := DynamicOf(CraftJson) as TCraft;
end;

procedure TCraftTests.TickCraft(ATimes: Integer);
begin
  for var i := 1 to ATimes do
    FCraft.Tick(0, 0, True);
end;

procedure TCraftTests.TestCraftStandsWhereTheFileSaysUntilMoved;
begin
  UseCraft;

  for var i := 1 to 50 do
  begin
    TickCraft(1);
    var Corner := FCraft.CornerAt(1);
    Assert.IsTrue(IsNear(Corner.X, FileX) and IsNear(Corner.Y, FileY),
      Format('Tick %d: the craft at %g, %g', [i, Corner.X, Corner.Y]));
  end;
end;

procedure TCraftTests.TestCraftMovesEachAxisOnItsOwn;
begin
  UseCraft;

  FCraft.MoveX(200, 20, meLinear);
  FCraft.MoveY(100, 40, meLinear);
  TickCraft(20);
  var Corner := FCraft.CornerAt(1);
  Assert.IsTrue(IsNear(Corner.X, 200), 'Across: there after its 20 ticks');
  Assert.IsTrue((Corner.Y > FileY) and (Corner.Y < 100),
    Format('Down: on the way after 20 of its 40 ticks, at %g', [Corner.Y]));

  TickCraft(20);
  Corner := FCraft.CornerAt(1);
  Assert.IsTrue(IsNear(Corner.X, 200), 'Across: stays');
  Assert.IsTrue(IsNear(Corner.Y, 100), 'Down: there after its 40 ticks');

  UseCraft;
  FCraft.MoveX(200, 20, meLinear);
  TickCraft(30);
  Assert.IsTrue(IsNear(FCraft.CornerAt(1).Y, FileY),
    'A move across leaves the craft''s height alone');
end;

procedure TCraftTests.TestCraftMovedInNoTicksIsThereAtOnce;
begin
  UseCraft;
  TickCraft(1);

  FCraft.MoveX(300, 0, meOut);
  TickCraft(1);

  Assert.IsTrue(IsNear(FCraft.CornerAt(0).X, 300) and
    IsNear(FCraft.CornerAt(1).X, 300),
    'A move of no ticks jumps: nothing is drawn on the way');
end;

procedure TCraftTests.TestCraftGetsThereByItsTicksAndStays;
const
  Ticks = 30;
  Target = 200;
begin
  for var Ease in Eases do
  begin
    UseCraft;
    FCraft.MoveX(Target, Ticks, Ease);
    var Before: Single := FileX;
    for var i := 1 to 2 * Ticks do
    begin
      TickCraft(1);
      var X := FCraft.CornerAt(1).X;
      Assert.IsTrue((X >= Before - SingleSlack) and (X <= Target + SingleSlack),
        Format('Ease %s, tick %d: %g after %g', [MotionEaseIds[Ease], i, X,
        Before]));
      if i >= Ticks then
        Assert.IsTrue(IsNear(X, Target), Format('Ease %s, tick %d: at %g, ' +
          'not there', [MotionEaseIds[Ease], i, X]));
      Before := X;
    end;
  end;
end;

procedure TCraftTests.TestEaseShapesTheWayNotTheEnd;
const
  Ticks = 40;
var
  HalfWay: array [TMotionEase] of Single;
begin
  for var Ease in Eases do
  begin
    UseCraft;
    FCraft.MoveX(FileX + 100, Ticks, Ease);
    TickCraft(Ticks div 2);
    HalfWay[Ease] := FCraft.CornerAt(1).X;
  end;

  Assert.IsTrue(HalfWay[meOut] > HalfWay[meLinear],
    'Losing speed, the craft has come further by half its time');
  Assert.IsTrue(HalfWay[meIn] < HalfWay[meLinear],
    'Gathering speed, it has come less far');
  Assert.IsTrue(HalfWay[meInOut] < HalfWay[meOut],
    'Both ways, it lags the one that sets off at speed');
end;

procedure TCraftTests.TestCornerBetweenTicksLiesBetweenThem;
begin
  UseCraft;
  FCraft.MoveX(FileX + 100, 20, meLinear);

  for var i := 1 to 20 do
  begin
    TickCraft(1);
    var Last := FCraft.CornerAt(0).X;
    var Current := FCraft.CornerAt(1).X;
    var Between := FCraft.CornerAt(0.5).X;
    Assert.IsTrue((Between > Last) and (Between < Current),
      Format('Tick %d: %g is not between %g and %g', [i, Between, Last,
      Current]));
  end;
end;

procedure TCraftTests.TestRewindPutsTheCraftBackAtOnce;
begin
  UseCraft;
  FCraft.MoveX(300, 40, meLinear);
  FCraft.MoveY(100, 40, meLinear);
  TickCraft(20);

  FCraft.Rewind;
  var Corner := FCraft.CornerAt(1);
  Assert.IsTrue(IsNear(Corner.X, FileX) and IsNear(Corner.Y, FileY),
    'Back where the file puts it');
  TickCraft(30);
  Corner := FCraft.CornerAt(1);
  Assert.IsTrue(IsNear(Corner.X, FileX) and IsNear(Corner.Y, FileY),
    'And it stays: the move it was in is gone');
end;

procedure TCraftTests.TestCraftKnowsWhichPartsFollow;
begin
  UseCraft;

  Assert.IsTrue(FCraft.HasFollower('gun'), 'A part that turns');
  Assert.IsTrue(FCraft.HasFollower('iris'), 'A part that slides');
  Assert.IsFalse(FCraft.HasFollower('plate'), 'A part that does neither');
  Assert.IsFalse(FCraft.HasFollower('ghost'), 'A tag no part carries');
end;

procedure TCraftTests.TestBadCraftRaises;
const
  Head = '{"kind":"craft","tag":"ship","screen":1,"body":"hull",' +
    '"width":100,"x":0,"y":0,"parts":[%s]}';
begin
  ExpectRaises(Format(Head, ['{"sprite":"gun","at":[1,1],"width":8,' +
    '"anchor":"pivot","pivot":[4,0],"turns":30,"reach":3}']),
    'A part that turns and slides');
  ExpectRaises(Format(Head, ['{"sprite":"gun","at":[1,1],"width":8,' +
    '"turns":30}']), 'A part that turns and hangs by no pivot');
  ExpectRaises(Format(Head, ['{"sprite":"gun","width":8}']),
    'A part with no point to hang on');
  ExpectRaises('{"kind":"craft","tag":"ship","screen":1,"width":100,' +
    '"x":0,"y":0}', 'A craft with no body');
  ExpectRaises('{"kind":"craft","tag":"ship","screen":1,"body":"hull",' +
    '"x":0,"y":0}', 'A craft of no width');
end;

procedure TCraftTests.TestBeamReadsItsLook;
const
  Beam = '{"kind":"beam","tag":"lift","screen":1,"x":0,"y":0%s}';
begin
  for var Look in BeamLooks do
  begin
    var Parsed := DynamicOf(Format(Beam, [Look]));
    try
      Assert.IsTrue(Parsed is TBeam, 'A beam of look "' + Look + '"');
    finally
      Parsed.Free;
    end;
  end;
  ExpectRaises(Format(Beam, [',"look":"spiral"']), 'A look not there');
end;

initialization
  TDUnitX.RegisterTestFixture(TCraftTests);

end.
