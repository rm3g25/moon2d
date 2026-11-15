{
  Tests.Render.Flare - the sun's flare of the titles, as the stand's
  flareNow and drawFlare have it: nothing before its cue; at the end of its
  attack all of it blown; settling to its hold with the burst gone over
  its settling; a sun the domes still cover flares only as far as it is
  free. Its mesh: nothing for no flare; a ring at every stop of each
  gradient - the bloom, the streak, four ghosts - and the veil over the
  frame; the bloom's middle on the sun at its first stop's alpha; the
  streak the frame's width each way and flat; the ghosts on the line from
  the sun through the frame's middle; the veil by the burst squared, over
  the whole frame.

  How it looks on the window is the card's: a live run.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Tests.Render.Flare;

interface

uses
  DUnitX.TestFramework,
  Render.Flare;

type
  [TestFixture]
  TFlareTests = class
  public
    [Test]
    procedure TestNothingBeforeTheCue;
    [Test]
    procedure TestAtTheEndOfItsAttackAllOfItBlows;
    [Test]
    procedure TestItSettlesToItsHold;
    [Test]
    procedure TestACoveredSunFlaresAsFarAsItIsFree;
    [Test]
    procedure TestNoFlareNoMesh;
    [Test]
    procedure TestARingAtEveryStopAndTheVeil;
    [Test]
    procedure TestTheBloomsMiddleIsOnTheSun;
    [Test]
    procedure TestTheStreakIsTheFramesWidthAndFlat;
    [Test]
    procedure TestTheGhostsLieOnTheLineThroughTheMiddle;
    [Test]
    procedure TestTheVeilIsTheBurstSquaredOverTheFrame;
  end;

implementation

uses
  Sdl2.Core;

const
  Slack = 1e-5;
  PlaceSlack = 0.001;
  FrameWidth = 512;
  FrameHeight = 384;
  SunX = 288;
  SunY = 208;
  // The stand's: its attack, its settling, what it holds
  Attack = 0.12;
  Settle = 1.4;
  Hold = 0.42;
  // A gradient: its middle and a ring of 64 corners at each of its two
  // stops past the first
  GradientCorners = 1 + 2 * 64;
  GradientIndices = 3 * (64 + 2 * 64);
  Gradients = 6;
  Ghosts: array [0..3] of Single = (0.55, 1.35, 1.8, 2.3);

function TheSun: TSdlFPoint;
begin
  Result.X := SunX;
  Result.Y := SunY;
end;

function Peak: TFlareState;
begin
  Result := FlareAt(Attack, 0);
end;

procedure TFlareTests.TestNothingBeforeTheCue;
begin
  Assert.IsTrue(FlareAt(-1, 0).Level = 0, 'Before');
  Assert.IsTrue(FlareAt(0, 0).Level = 0, 'On it');
  Assert.IsTrue(FlareAt(0, 0).Burst = 0, 'No burst');
end;

procedure TFlareTests.TestAtTheEndOfItsAttackAllOfItBlows;
begin
  Assert.IsTrue(Abs(Peak.Level - 1) < Slack, 'All of it');
  Assert.IsTrue(Abs(Peak.Burst - 1) < Slack, 'Blown');
  var Halfway := FlareAt(Attack / 2, 0);
  Assert.IsTrue(Abs(Halfway.Level - 0.5) < Slack, 'Halfway up its smooth attack');
end;

procedure TFlareTests.TestItSettlesToItsHold;
begin
  var Settled := FlareAt(Attack + Settle, 0);
  Assert.IsTrue(Abs(Settled.Burst - Exp(-3)) < Slack, 'The burst gone to e^-3');
  Assert.IsTrue(Abs(Settled.Level - (Hold + (1 - Hold) * Exp(-3))) < Slack, 'Nearly held');
  var Long := FlareAt(30, 0);
  Assert.IsTrue(Abs(Long.Level - Hold) < Slack, 'Held');
  Assert.IsTrue(Long.Burst < Slack, 'No burst left');
end;

procedure TFlareTests.TestACoveredSunFlaresAsFarAsItIsFree;
begin
  Assert.IsTrue(FlareAt(Attack, 1).Level = 0, 'Covered: none');
  Assert.IsTrue(Abs(FlareAt(Attack, 0.25).Level - 0.75) < Slack, 'Three quarters free');
end;

procedure TFlareTests.TestNoFlareNoMesh;
begin
  var Mesh := FlareMesh(FlareAt(0, 0), TheSun, FrameWidth, FrameHeight);
  Assert.AreEqual(0, Integer(Length(Mesh.Vertices)), 'No corners');
  Assert.AreEqual(0, Integer(Length(Mesh.Indices)), 'No triangles');
end;

procedure TFlareTests.TestARingAtEveryStopAndTheVeil;
begin
  var Mesh := FlareMesh(Peak, TheSun, FrameWidth, FrameHeight);
  Assert.AreEqual(Gradients * GradientCorners + 4, Integer(Length(Mesh.Vertices)), 'Corners');
  Assert.AreEqual(Gradients * GradientIndices + 6, Integer(Length(Mesh.Indices)), 'Triangles');
  for var Index in Mesh.Indices do
    Assert.IsTrue((Index >= 0) and (Index < Length(Mesh.Vertices)), 'A corner of the mesh');
end;

procedure TFlareTests.TestTheBloomsMiddleIsOnTheSun;
begin
  var Mesh := FlareMesh(Peak, TheSun, FrameWidth, FrameHeight);
  var Middle := Mesh.Vertices[0];
  Assert.IsTrue(Abs(Middle.Position.X - SunX) < PlaceSlack, 'Across');
  Assert.IsTrue(Abs(Middle.Position.Y - SunY) < PlaceSlack, 'Down');
  Assert.AreEqual(242, Integer(Middle.Color.A), 'The first stop''s 0.95');
  // The outer ring of the bloom: 150 units at the peak, clear
  var Outer := Mesh.Vertices[GradientCorners - 64];
  Assert.IsTrue(Abs(Outer.Position.X - (SunX + 150)) < PlaceSlack, 'Its reach');
  Assert.AreEqual(0, Integer(Outer.Color.A), 'Clear at its edge');
end;

procedure TFlareTests.TestTheStreakIsTheFramesWidthAndFlat;
begin
  var Mesh := FlareMesh(Peak, TheSun, FrameWidth, FrameHeight);
  var Widest: Single := 0;
  var Tallest: Single := 0;
  for var i := GradientCorners to 2 * GradientCorners - 1 do
  begin
    var Across: Single := Abs(Mesh.Vertices[i].Position.X - SunX);
    var Down: Single := Abs(Mesh.Vertices[i].Position.Y - SunY);
    if Across > Widest then
      Widest := Across;
    if Down > Tallest then
      Tallest := Down;
  end;
  Assert.IsTrue(Abs(Widest - FrameWidth) < PlaceSlack, 'The frame''s width each way');
  Assert.IsTrue(Abs(Tallest - FrameWidth * 0.035) < PlaceSlack, 'Flat');
end;

procedure TFlareTests.TestTheGhostsLieOnTheLineThroughTheMiddle;
begin
  var Mesh := FlareMesh(Peak, TheSun, FrameWidth, FrameHeight);
  for var i := 0 to High(Ghosts) do
  begin
    var Middle := Mesh.Vertices[(2 + i) * GradientCorners];
    var WantX: Single := SunX + (FrameWidth / 2 - SunX) * Ghosts[i];
    var WantY: Single := SunY + (FrameHeight / 2 - SunY) * Ghosts[i];
    Assert.IsTrue(Abs(Middle.Position.X - WantX) < PlaceSlack, 'Across');
    Assert.IsTrue(Abs(Middle.Position.Y - WantY) < PlaceSlack, 'Down');
  end;
end;

procedure TFlareTests.TestTheVeilIsTheBurstSquaredOverTheFrame;
begin
  var Mesh := FlareMesh(Peak, TheSun, FrameWidth, FrameHeight);
  var First := Gradients * GradientCorners;
  Assert.AreEqual(153, Integer(Mesh.Vertices[First].Color.A), '0.6 at the peak');
  Assert.IsTrue(Mesh.Vertices[First].Position.X = 0, 'From the frame''s left');
  Assert.IsTrue(Mesh.Vertices[First + 2].Position.X = FrameWidth, 'To its right');
  Assert.IsTrue(Mesh.Vertices[First + 2].Position.Y = FrameHeight, 'To its bottom');

  // A third of a second into the settling: the burst at e^-(0.3 / 1.4 * 3)
  var Settling := FlareMesh(FlareAt(Attack + 0.3, 0), TheSun, FrameWidth, FrameHeight);
  var Burst: Double := Exp(-0.3 / Settle * 3);
  Assert.AreEqual(Integer(Round(255 * 0.6 * Burst * Burst)),
    Integer(Settling.Vertices[First].Color.A), 'By the burst squared');
end;

initialization
  TDUnitX.RegisterTestFixture(TFlareTests);

end.
