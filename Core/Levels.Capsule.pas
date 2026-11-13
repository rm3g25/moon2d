{
  Levels.Capsule - the shape of a capsule frame (Levels.FarPlane, "kind":
  "capsule"): a barrel vault with a quarter dome at each end, the farm's
  long dome.

  Its frame is a diagrid. Rows of nodes go round the arch from the far foot
  over the crown to the near one, every other row shifted by half a cell,
  each node tied to its two neighbours in the row above: triangles in a
  slant, a purlin along each row. At the ends the rows run on into the
  quarter domes and close onto the ends' feet, so the ribs fan out of the
  two poles at the dome's foot. Every BeltEvery cells a heavy arch - a belt
  - crosses the barrel, at its ends too; the ring at the foot is thicker.

  The feet, the crown and the end of an end's turn are exact: a cos(Pi / 2)
  of the arithmetic carries a sign of its own, and the FPU's differs from
  the stand's - the crown would change halves and a foot would throw a
  shadow. The stand (tools/chase/stand.template.html, capsule) is the
  reference, edge for edge and in their order.

  No SDL: Render.DomeFrames draws the ribs, Levels.Farm lights the air.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Levels.Capsule;
{$I ..\Moon2D.inc}

interface

uses
  Levels.FarPlane;

type
  // An edge in units from the frame's centre on its base line, its
  // thickness in ribs
  TCapsuleEdge = record
    A, B: TFramePoint;
    Thickening: Single;
  end;

  // A node above the feet; its beacon's seed is taken from KeyX and KeyZ
  TCapsuleNode = record
    At: TFramePoint;
    KeyX, KeyZ: Double;
  end;

  TCapsuleShape = record
    Edges: TArray<TCapsuleEdge>;
    Nodes: TArray<TCapsuleNode>;
  end;

// AAlong - units along from the centre, out to the tips of the ends
// (CapsuleEnd); ARow - from 0 at the far foot over the crown at Rows / 2 to
// the near foot at Rows, fractions too
function CapsulePoint(const AFrame: TDomeFrame; AAlong, ARow: Double): TFramePoint;
// Units from the centre to the tip of an end
function CapsuleEnd(const AFrame: TDomeFrame): Double;
// Half the barrel's length: where the ends begin to turn
function CapsuleBarrel(const AFrame: TDomeFrame): Double;
function CapsuleShape(const AFrame: TDomeFrame): TCapsuleShape;

implementation

uses
  System.Math, System.Generics.Collections;

const
  BeltThickening = 2.2;
  // Steps of a row along a belt and along an end's foot
  BeltSteps = 4;
  // Two nodes nearer than this are one: no edge between them
  LeastEdge = 1E-6;
  // A node at the end of a row this far past the tip is still on it
  AlongSlack = 1E-9;

type
  // The sine and the cosine of a quarter turn
  TTurn = record
    Sine, Cosine: Double;
  end;

function QuarterTurn(AShare: Double): TTurn;
begin
  if AShare <= 0 then
  begin
    Result.Sine := 0;
    Result.Cosine := 1;
  end
  else if AShare >= 1 then
  begin
    Result.Sine := 1;
    Result.Cosine := 0;
  end
  else
  begin
    Result.Sine := Sin(Pi / 2 * AShare);
    Result.Cosine := Cos(Pi / 2 * AShare);
  end;
end;

function Point(AX, AY, AZ: Double): TFramePoint;
begin
  Result.X := AX;
  Result.Y := AY;
  Result.Z := AZ;
end;

function CapsuleBarrel(const AFrame: TDomeFrame): Double;
begin
  Result := AFrame.W / 2 - AFrame.D / 2;
end;

function CellOf(const AFrame: TDomeFrame): Double;
begin
  Result := 2 * CapsuleBarrel(AFrame) / AFrame.Cells;
end;

function CapsuleEnd(const AFrame: TDomeFrame): Double;
begin
  Result := CapsuleBarrel(AFrame) + AFrame.CapCells * CellOf(AFrame);
end;

function CapsulePoint(const AFrame: TDomeFrame; AAlong, ARow: Double): TFramePoint;
begin
  var Radius: Double := AFrame.D / 2;
  var Barrel := CapsuleBarrel(AFrame);
  var Cap: Double := AFrame.CapCells * CellOf(AFrame);
  // The arch from the far foot over the crown to the near one: two quarter
  // turns
  var Up: TTurn;
  var Depth: Double;
  if 2 * ARow <= AFrame.Rows then
  begin
    Up := QuarterTurn(2 * ARow / AFrame.Rows);
    Depth := Radius * Up.Cosine;
  end
  else
  begin
    Up := QuarterTurn(2 - 2 * ARow / AFrame.Rows);
    Depth := -Radius * Up.Cosine;
  end;
  var Along := Abs(AAlong);
  if Along <= Barrel then
    Exit(Point(AAlong, AFrame.H * Up.Sine, Depth));
  var Turn := QuarterTurn((Along - Barrel) / Cap);
  Result := Point(Sign(AAlong) * (Barrel + Radius * Up.Sine * Turn.Sine),
    AFrame.H * Up.Sine * Turn.Cosine, Depth);
end;

function CapsuleShape(const AFrame: TDomeFrame): TCapsuleShape;
var
  Edges: TList<TCapsuleEdge>;
  Nodes: TList<TCapsuleNode>;

  procedure Add(const AFrom, ATo: TFramePoint; AThickening: Single);
  begin
    var Length := Sqrt(Sqr(AFrom.X - ATo.X) + Sqr(AFrom.Y - ATo.Y) + Sqr(AFrom.Z - ATo.Z));
    if Length <= LeastEdge then
      Exit;
    var Edge: TCapsuleEdge;
    Edge.A := AFrom;
    Edge.B := ATo;
    Edge.Thickening := AThickening;
    Edges.Add(Edge);
  end;

  // An arch of the frame across AAlong from foot to foot, BeltSteps a row
  procedure AddArch(AAlong: Double; AThickening: Single);
  begin
    for var k := 0 to AFrame.Rows * BeltSteps - 1 do
      Add(CapsulePoint(AFrame, AAlong, k / BeltSteps),
        CapsulePoint(AFrame, AAlong, (k + 1) / BeltSteps), AThickening);
  end;

begin
  var Cell := CellOf(AFrame);
  var Tip := CapsuleEnd(AFrame);
  var CellCount := AFrame.Cells + 2 * AFrame.CapCells;
  // To the two neighbours in the row above
  var Steps: TArray<Double> := [-Cell / 2, Cell / 2];
  Edges := TList<TCapsuleEdge>.Create;
  Nodes := TList<TCapsuleNode>.Create;
  try
    for var j := 0 to AFrame.Rows do
    begin
      // An even row runs from tip to tip, an odd one between
      var Shift: Double := (j mod 2) / 2;
      var Row: TArray<Double> := [];
      var i := 0;
      while i + Shift <= CellCount + AlongSlack do
      begin
        Row := Row + [-Tip + (i + Shift) * Cell];
        Inc(i);
      end;

      var Thickening: Single := 1;
      if (j = 0) or (j = AFrame.Rows) then
        Thickening := FrameRingThickening;
      for var n := 0 to High(Row) - 1 do
        Add(CapsulePoint(AFrame, Row[n], j), CapsulePoint(AFrame, Row[n + 1], j), Thickening);

      for var Along in Row do
      begin
        var At := CapsulePoint(AFrame, Along, j);
        if (j > 0) and (j < AFrame.Rows) then
        begin
          var Node: TCapsuleNode;
          Node.At := At;
          Node.KeyX := Along / AFrame.W;
          Node.KeyZ := j / AFrame.Rows;
          Nodes.Add(Node);
        end;
        if j = AFrame.Rows then
          Continue;
        for var Step in Steps do
          if Abs(Along + Step) <= Tip + AlongSlack then
            Add(At, CapsulePoint(AFrame, Along + Step, j + 1), 1);
      end;
    end;

    // The ends' feet: an arc on the ground through the ends of the even rows
    AddArch(-Tip, FrameRingThickening);
    AddArch(Tip, FrameRingThickening);
    // The belts, the barrel's ends among them
    var Belt := 0;
    while Belt * AFrame.BeltEvery <= AFrame.Cells do
    begin
      AddArch(-CapsuleBarrel(AFrame) + Belt * AFrame.BeltEvery * Cell, BeltThickening);
      Inc(Belt);
    end;

    Result.Edges := Edges.ToArray;
    Result.Nodes := Nodes.ToArray;
  finally
    Nodes.Free;
    Edges.Free;
  end;
end;

end.
