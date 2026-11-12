{
  Tests.Game.Breakup - the end of the Ram's hull: whole, it does nothing.
  Started, it cracks once, at once; in its throe it is taken to where it
  bursts, the whole way and no farther, shuddering; the small blasts of
  the throe come once each, at their places; its jets cough - they catch
  again and die more than once - and are dead the last ticks before the
  burst. It bursts once, as the throe ends, and is broken from then on.
  Then every piece blows up once, in no order of their numbers, one at a
  time with gaps between them, and the series is over once; with no
  pieces it is over at the burst. A start while it runs is nothing; a
  clear makes it whole; the same dice give the same series.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Game.Breakup;

interface

uses
  DUnitX.TestFramework,
  Game.Breakup;

type
  [TestFixture]
  TBreakupTests = class
  private
    FBreakup: TBreakup;
    procedure StartIt(APieces: Integer = 8);
    // Ticks through the throe; the cues, a tick each
    function Throe: TArray<TBreakupCue>;
    // Ticks through the series till it is over; the cues, a tick each
    function Series: TArray<TBreakupCue>;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestWholeItDoesNothing;
    [Test]
    procedure TestItCracksOnceAtOnce;
    [Test]
    procedure TestTheThroeTakesItToWhereItBursts;
    [Test]
    procedure TestItShuddersInItsThroe;
    [Test]
    procedure TestTheSmallBlastsComeOnceEachAtTheirPlaces;
    [Test]
    procedure TestTheJetsCoughThenAreDeadBeforeTheBurst;
    [Test]
    procedure TestItBurstsOnceAsTheThroeEnds;
    [Test]
    procedure TestEveryPieceBlowsUpOnce;
    [Test]
    procedure TestTheBlastsComeOneAtATimeWithGaps;
    [Test]
    procedure TestNoPiecesItIsOverAtTheBurst;
    [Test]
    procedure TestAStartWhileItRunsIsNothing;
    [Test]
    procedure TestAClearMakesItWhole;
    [Test]
    procedure TestSameDiceSameSeries;
  end;

implementation

uses
  System.SysUtils;

const
  Seed = 7;
  FromLeft = 40.0;
  FromLift = 60.0;
  FromLean = 6.0;
  ToLeft = 171.5;
  ToLift = 184.0;
  Pieces = 8;
  // A whole series is over well within this
  SeriesLimit = 400;

procedure TBreakupTests.Setup;
begin
  FBreakup := TBreakup.Create(Seed);
end;

procedure TBreakupTests.TearDown;
begin
  FBreakup.Free;
end;

procedure TBreakupTests.StartIt(APieces: Integer);
begin
  FBreakup.Start(FromLeft, FromLift, FromLean, ToLeft, ToLift, APieces);
end;

function TBreakupTests.Throe: TArray<TBreakupCue>;
begin
  SetLength(Result, ThroeTicks);
  for var i := 0 to ThroeTicks - 1 do
    Result[i] := FBreakup.Tick;
end;

function TBreakupTests.Series: TArray<TBreakupCue>;
begin
  Result := nil;
  while FBreakup.Running do
  begin
    Result := Result + [FBreakup.Tick];
    if Length(Result) > SeriesLimit then
      Assert.Fail('The series is not over in time');
  end;
end;

procedure TBreakupTests.TestWholeItDoesNothing;
begin
  for var i := 1 to ThroeTicks * 2 do
  begin
    var Cue := FBreakup.Tick;
    Assert.IsFalse(Cue.Cracks or Cue.Pops or Cue.Breaks or Cue.PieceBlows or
      Cue.Over or Cue.JetsCatch or Cue.JetsDie, 'No cue');
  end;
  Assert.AreEqual<TBreakupStage>(buIdle, FBreakup.Stage, 'Whole');
  Assert.IsFalse(FBreakup.Running or FBreakup.Broken, 'Nothing of an end');
end;

procedure TBreakupTests.TestItCracksOnceAtOnce;
begin
  StartIt;
  Assert.IsTrue(FBreakup.Running, 'Running from the start');
  Assert.IsFalse(FBreakup.Broken, 'Not burst yet');
  var Cues := Throe;
  Assert.IsTrue(Cues[0].Cracks, 'It cracks on the first tick');
  for var i := 1 to High(Cues) do
    Assert.IsFalse(Cues[i].Cracks, 'Once: tick ' + IntToStr(i + 1));
end;

procedure TBreakupTests.TestTheThroeTakesItToWhereItBursts;
begin
  StartIt;
  var LastLeft := FromLeft;
  var LastLift := FromLift;
  for var i := 1 to ThroeTicks do
  begin
    FBreakup.Tick;
    Assert.IsTrue(FBreakup.Left >= LastLeft - 0.001, 'Never back across');
    Assert.IsTrue(FBreakup.Lift >= LastLift - 0.001, 'Never back down');
    Assert.IsTrue(FBreakup.Left <= ToLeft + 0.001, 'Never past its place');
    LastLeft := FBreakup.Left;
    LastLift := FBreakup.Lift;
  end;
  Assert.AreEqual(Double(ToLeft), Double(FBreakup.Left), 0.001, 'Across there');
  Assert.AreEqual(Double(ToLift), Double(FBreakup.Lift), 0.001, 'Up there');
end;

procedure TBreakupTests.TestItShuddersInItsThroe;
const
  ShudderMost = 4.0;
begin
  StartIt;
  var Lefts := 0;
  var Rights := 0;
  for var i := 1 to ThroeTicks do
  begin
    FBreakup.Tick;
    Assert.IsTrue(Abs(FBreakup.Lean) <= FromLean + ShudderMost + 0.001,
      'Within its lean and the shudder');
    if i > ThroeTicks div 2 then
    begin
      if FBreakup.Lean < -0.5 then
        Inc(Lefts);
      if FBreakup.Lean > 0.5 then
        Inc(Rights);
    end;
  end;
  Assert.IsTrue((Lefts > 0) and (Rights > 0), 'Either way, its lean gone');
end;

procedure TBreakupTests.TestTheSmallBlastsComeOnceEachAtTheirPlaces;
var
  Seen: array [Low(ThroePops)..High(ThroePops)] of Integer;
begin
  StartIt;
  for var Place := Low(Seen) to High(Seen) do
    Seen[Place] := 0;
  var Cues := Throe;
  for var i := 0 to High(Cues) do
    if Cues[i].Pops then
    begin
      Inc(Seen[Cues[i].PopPlace]);
      Assert.AreEqual(ThroePops[Cues[i].PopPlace], i + 1, 'At its tick');
    end;
  for var Place := Low(Seen) to High(Seen) do
    Assert.AreEqual(1, Seen[Place], 'Once: place ' + IntToStr(Place));
end;

procedure TBreakupTests.TestTheJetsCoughThenAreDeadBeforeTheBurst;
const
  DeadTicks = 8;
begin
  StartIt;
  var Catches := 0;
  var Deaths := 0;
  for var i := 1 to ThroeTicks do
  begin
    var Cue := FBreakup.Tick;
    if Cue.JetsCatch then
      Inc(Catches);
    if Cue.JetsDie then
      Inc(Deaths);
    if i > ThroeTicks - DeadTicks then
      Assert.IsFalse(FBreakup.JetsLit, 'Dead before the burst: tick ' +
        IntToStr(i));
  end;
  Assert.IsTrue(Catches >= 2, 'They catch again more than once');
  Assert.IsTrue(Deaths >= 3, 'And die more than once');
end;

procedure TBreakupTests.TestItBurstsOnceAsTheThroeEnds;
begin
  StartIt;
  var Cues := Throe;
  for var i := 0 to High(Cues) - 1 do
    Assert.IsFalse(Cues[i].Breaks, 'Not in the throe');
  Assert.IsTrue(Cues[High(Cues)].Breaks, 'As it ends');
  Assert.IsTrue(FBreakup.Broken, 'Broken from then');
  for var Cue in Series do
    Assert.IsFalse(Cue.Breaks, 'Once');
  Assert.IsTrue(FBreakup.Broken, 'Broken still, the series over');
end;

procedure TBreakupTests.TestEveryPieceBlowsUpOnce;
begin
  StartIt(Pieces);
  Throe;
  var Seen: TArray<Integer>;
  SetLength(Seen, Pieces);
  var Order: TArray<Integer> := nil;
  var Overs := 0;
  for var Cue in Series do
  begin
    if Cue.PieceBlows then
    begin
      Inc(Seen[Cue.Piece]);
      Order := Order + [Cue.Piece];
    end;
    if Cue.Over then
      Inc(Overs);
  end;
  for var Piece := 0 to Pieces - 1 do
    Assert.AreEqual(1, Seen[Piece], 'Once: piece ' + IntToStr(Piece));
  Assert.AreEqual(1, Overs, 'Over once');
  var InOrder := True;
  for var i := 0 to High(Order) do
    if Order[i] <> i then
      InOrder := False;
  Assert.IsFalse(InOrder, 'Not in the order of their numbers');
  Assert.AreEqual<TBreakupStage>(buOver, FBreakup.Stage, 'Over');
  Assert.IsFalse(FBreakup.Running, 'Not running');
end;

procedure TBreakupTests.TestTheBlastsComeOneAtATimeWithGaps;
begin
  StartIt(Pieces);
  Throe;
  var Ticks: TArray<Integer> := nil;
  var Cues := Series;
  for var i := 0 to High(Cues) do
    if Cues[i].PieceBlows then
      Ticks := Ticks + [i + 1];
  Assert.AreEqual(SeriesFirstTicks, Ticks[0], 'The first a little after');
  for var i := 1 to High(Ticks) do
  begin
    var Gap := Ticks[i] - Ticks[i - 1];
    Assert.IsTrue((Gap >= SeriesGapLeast) and (Gap <= SeriesGapMost),
      Format('Gap %d of %d ticks', [i, Gap]));
  end;
end;

procedure TBreakupTests.TestNoPiecesItIsOverAtTheBurst;
begin
  StartIt(0);
  var Cues := Throe;
  Assert.IsTrue(Cues[High(Cues)].Breaks and Cues[High(Cues)].Over,
    'Burst and over at once');
  Assert.IsFalse(FBreakup.Running, 'Not running');
  Assert.IsTrue(FBreakup.Broken, 'Broken');
end;

procedure TBreakupTests.TestAStartWhileItRunsIsNothing;
begin
  StartIt;
  for var i := 1 to 10 do
    FBreakup.Tick;
  var Left := FBreakup.Left;
  FBreakup.Start(0, 0, 0, 0, 0, Pieces);
  var Cue := FBreakup.Tick;
  Assert.IsFalse(Cue.Cracks, 'No second crack');
  Assert.IsTrue(FBreakup.Left >= Left, 'On its way as it was');
end;

procedure TBreakupTests.TestAClearMakesItWhole;
begin
  StartIt;
  Throe;
  FBreakup.Clear;
  Assert.AreEqual<TBreakupStage>(buIdle, FBreakup.Stage, 'Whole');
  Assert.IsFalse(FBreakup.Running or FBreakup.Broken, 'Nothing of an end');
  StartIt;
  Assert.IsTrue(FBreakup.Tick.Cracks, 'It can crack again');
end;

procedure TBreakupTests.TestSameDiceSameSeries;
begin
  var Other := TBreakup.Create(Seed);
  try
    StartIt;
    Other.Start(FromLeft, FromLift, FromLean, ToLeft, ToLift, Pieces);
    while FBreakup.Running do
    begin
      var Mine := FBreakup.Tick;
      var Theirs := Other.Tick;
      Assert.AreEqual<Boolean>(Mine.PieceBlows, Theirs.PieceBlows, 'Blasts together');
      if Mine.PieceBlows then
        Assert.AreEqual(Mine.Piece, Theirs.Piece, 'On the same piece');
    end;
  finally
    Other.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TBreakupTests);

end.
