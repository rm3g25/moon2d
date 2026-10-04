{
  Pads.Formations - the dice, the judge and the assignment of a pad group
  rebuild (Levels.Pads): the cells the group's pads stand on next, and
  which pad flies to which. Pure functions on cells; the flights are
  Pads.Flights', the pads themselves Pads.World's.

  A formation puts every pad of the group on a cell of the zone. It is
  thrown pairs first - two pads side by side - then the rest one by one,
  and the judge keeps it only when it plays:
  - no pad right over another: the hero on the lower one would stand in
    the upper one's body;
  - no run of three side by side, and the group's pairs at least;
  - every third of the zone, across and down, holds a pad;
  - the hero reaches every pad with a plain jump, from the ground under
    the zone - the tops of the walls and the pads that stay there.
  The assignment flies every pad, at least FarShare of them FarFlight
  cells or more, never puts an old pair side by side again and, of the
  assignments it tries, takes the one whose shortest flights are the
  longest.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Pads.Formations;
{$I ..\..\Moon2D.inc}

interface

uses
  Render.Brush, Levels.Pads, Levels.Defs;

type
  // A cell of a screen, 0-based
  TPadCell = record
    Col, Row: Integer;
  end;

  TPadCells = TArray<TPadCell>;

  // Ground the hero stands on: cells Left..Right of a row, the row of the
  // feet line
  TPadSpan = record
    Left, Right, Row: Integer;
  end;

  TPadSpans = TArray<TPadSpan>;

  // The most empty cells a jump crosses sideways to land ARise rows up
  // (down when below zero); -1 when no jump makes it
  TJumpReach = reference to function(ARise: Integer): Integer;

// 0..ACount - 1
function Roll(var ARandom: TXorShift; ACount: Integer): Integer;

// Where a climb into the zone starts: the tops of the grid's walls under
// the zone, and AStill - the screen's pads that are not rebuilt - under
// it too
function LaunchSpans(const ALevel: TLevel; const AGroup: TPadGroup;
  const AStill: TPadSpans): TPadSpans;

// ACount cells of the zone, the group's pairs first. False when the zone
// gave no room for them in the tries a throw has.
function TryThrowFormation(var ARandom: TXorShift; const AGroup: TPadGroup;
  ACount: Integer; out ACells: TPadCells): Boolean;

function JudgeFormation(const ACells: TPadCells; const AGroup: TPadGroup;
  const ALaunch: TPadSpans; const AReach: TJumpReach): Boolean;

// ATarget[i] - the cell of ACells the pad on AStart[i] flies to. False
// when no assignment tried holds.
function TryAssignFormation(var ARandom: TXorShift;
  const AStart, ACells: TPadCells; const AGroup: TPadGroup;
  out ATarget: TPadCells): Boolean;

// The cells a flight of two legs, across and down, goes
function FlightCells(const AFrom, ATo: TPadCell): Integer;

implementation

uses
  System.Math, System.Generics.Collections, Game.Space;

const
  // A throw that cannot place its cells gives up: a zone too tight for
  // the group must not hang the game. On screen 17 a throw places its
  // nine cells in about eight tries; seven are the least - two pairs and
  // five single pads.
  ThrowTriesPerCell = 100;
  // Assignments tried, and how many of those that hold are compared. On
  // screen 17 about half of them hold: the 64 come within some 130
  // tries, the rest is room for a tighter zone.
  AssignTries = 512;
  AssignKept = 64;

type
  // JumpReach for every rise between two rows of a screen
  TReachTable = array [-ScreenRows..ScreenRows] of Integer;

function Roll(var ARandom: TXorShift; ACount: Integer): Integer;
begin
  Result := Trunc(ARandom.NextUnit * ACount);
end;

function CellAt(ACol, ARow: Integer): TPadCell;
begin
  Result.Col := ACol;
  Result.Row := ARow;
end;

function Holds(const ACells: TPadCells; ACol, ARow: Integer): Boolean;
begin
  for var Cell in ACells do
    if (Cell.Col = ACol) and (Cell.Row = ARow) then
      Exit(True);
  Result := False;
end;

function FlightCells(const AFrom, ATo: TPadCell): Integer;
begin
  Result := Abs(ATo.Col - AFrom.Col) + Abs(ATo.Row - AFrom.Row);
end;

// ---------------------------------------------------------------------------
// The ground under the zone
// ---------------------------------------------------------------------------

// A wall cell with air over it: the hero stands on its top
function WallTop(const ALevel: TLevel; AScreen, ACol, ARow: Integer): Boolean;
begin
  Result := ALevel.SolidAt(AScreen, ACol, ARow) and
    not ALevel.SolidAt(AScreen, ACol, ARow - 1);
end;

function WallTopsOfRow(const ALevel: TLevel; AScreen, ARow: Integer): TPadSpans;
begin
  Result := [];
  var Col := 0;
  while Col < ALevel.GridWidth do
  begin
    if not WallTop(ALevel, AScreen, Col, ARow) then
    begin
      Inc(Col);
      Continue;
    end;
    var Span: TPadSpan;
    Span.Left := Col;
    Span.Row := ARow;
    while (Col + 1 < ALevel.GridWidth) and
      WallTop(ALevel, AScreen, Col + 1, ARow) do
      Inc(Col);
    Span.Right := Col;
    Result := Result + [Span];
    Inc(Col);
  end;
end;

function LaunchSpans(const ALevel: TLevel; const AGroup: TPadGroup;
  const AStill: TPadSpans): TPadSpans;
begin
  Result := [];
  for var Row := AGroup.Zone.Bottom + 1 to ALevel.GridHeight - 1 do
    Result := Result + WallTopsOfRow(ALevel, AGroup.Screen, Row);
  for var Still in AStill do
    if Still.Row > AGroup.Zone.Bottom then
      Result := Result + [Still];
end;

// ---------------------------------------------------------------------------
// The dice
// ---------------------------------------------------------------------------

function TryThrowFormation(var ARandom: TXorShift; const AGroup: TPadGroup;
  ACount: Integer; out ACells: TPadCells): Boolean;
begin
  var Zone := AGroup.Zone;
  ACells := [];
  var Tries := ThrowTriesPerCell * ACount;
  while (Length(ACells) < 2 * AGroup.Pairs) and (Tries > 0) do
  begin
    Dec(Tries);
    var Col := Zone.Left + Roll(ARandom, Zone.Right - Zone.Left);
    var Row := Zone.Top + Roll(ARandom, Zone.Bottom - Zone.Top + 1);
    if Holds(ACells, Col, Row) or Holds(ACells, Col + 1, Row) then
      Continue;
    ACells := ACells + [CellAt(Col, Row), CellAt(Col + 1, Row)];
  end;
  while (Length(ACells) < ACount) and (Tries > 0) do
  begin
    Dec(Tries);
    var Col := Zone.Left + Roll(ARandom, Zone.Right - Zone.Left + 1);
    var Row := Zone.Top + Roll(ARandom, Zone.Bottom - Zone.Top + 1);
    if Holds(ACells, Col, Row) then
      Continue;
    ACells := ACells + [CellAt(Col, Row)];
  end;
  Result := Length(ACells) = ACount;
end;

// ---------------------------------------------------------------------------
// The judge
// ---------------------------------------------------------------------------

function NoneStacked(const ACells: TPadCells): Boolean;
begin
  for var Cell in ACells do
    if Holds(ACells, Cell.Col, Cell.Row + 1) then
      Exit(False);
  Result := True;
end;

// The runs of two side by side; -1 when a run is longer
function PairsOf(const ACells: TPadCells): Integer;
begin
  Result := 0;
  for var Cell in ACells do
  begin
    if Holds(ACells, Cell.Col - 1, Cell.Row) then
      Continue;
    var Run := 1;
    while Holds(ACells, Cell.Col + Run, Cell.Row) do
      Inc(Run);
    if Run > 2 then
      Exit(-1);
    if Run = 2 then
      Inc(Result);
  end;
end;

// Third APart (0..2) of AFirst..ALast, as even as whole cells go
procedure ThirdOf(AFirst, ALast, APart: Integer; out ALow, AHigh: Integer);
begin
  var Size := ALast - AFirst + 1;
  ALow := AFirst + Round(APart * Size / 3);
  AHigh := AFirst + Round((APart + 1) * Size / 3) - 1;
end;

function AnyInCols(const ACells: TPadCells; ALow, AHigh: Integer): Boolean;
begin
  for var Cell in ACells do
    if InRange(Cell.Col, ALow, AHigh) then
      Exit(True);
  Result := False;
end;

function AnyInRows(const ACells: TPadCells; ALow, AHigh: Integer): Boolean;
begin
  for var Cell in ACells do
    if InRange(Cell.Row, ALow, AHigh) then
      Exit(True);
  Result := False;
end;

// Every third of the zone across and every third down holds a pad
function Spread(const ACells: TPadCells; const AZone: TPadZone): Boolean;
var
  First, Last: Integer;
begin
  for var Part := 0 to 2 do
  begin
    ThirdOf(AZone.Left, AZone.Right, Part, First, Last);
    if not AnyInCols(ACells, First, Last) then
      Exit(False);
    ThirdOf(AZone.Top, AZone.Bottom, Part, First, Last);
    if not AnyInRows(ACells, First, Last) then
      Exit(False);
  end;
  Result := True;
end;

// The empty cells between two spans across; 0 when they meet or overlap
function GapAcross(const AFrom, ATo: TPadSpan): Integer;
begin
  Result := 0;
  if ATo.Left > AFrom.Right then
    Result := ATo.Left - AFrom.Right - 1
  else if AFrom.Left > ATo.Right then
    Result := AFrom.Left - ATo.Right - 1;
end;

function Jumps(const AFrom, ATo: TPadSpan; const AReach: TReachTable): Boolean;
begin
  var MostGap := AReach[AFrom.Row - ATo.Row];
  Result := (MostGap >= 0) and (GapAcross(AFrom, ATo) <= MostGap);
end;

function SpanOf(const ACell: TPadCell): TPadSpan;
begin
  Result.Left := ACell.Col;
  Result.Right := ACell.Col;
  Result.Row := ACell.Row;
end;

// Every pad, from the launch spans, jump by jump
function AllReachable(const ACells: TPadCells; const ALaunch: TPadSpans;
  const AReach: TJumpReach): Boolean;
var
  Reach: TReachTable;
  Nodes: TPadSpans;
  Reached: TArray<Boolean>;
  Pending: TArray<Integer>;

  // Every node a jump from AFrom lands on, not reached before, is reached
  // now and waits to be jumped from
  procedure ReachFrom(const AFrom: TPadSpan);
  begin
    for var i := 0 to High(Nodes) do
    begin
      if Reached[i] or not Jumps(AFrom, Nodes[i], Reach) then
        Continue;
      Reached[i] := True;
      Pending := Pending + [i];
    end;
  end;

begin
  for var Rise := Low(Reach) to High(Reach) do
    Reach[Rise] := AReach(Rise);

  Nodes := [];
  for var Cell in ACells do
    Nodes := Nodes + [SpanOf(Cell)];
  Nodes := Nodes + ALaunch;
  SetLength(Reached, Length(Nodes));
  Pending := [];
  for var i := Length(ACells) to High(Nodes) do
  begin
    Reached[i] := True;
    Pending := Pending + [i];
  end;

  while Length(Pending) > 0 do
  begin
    var From := Nodes[Pending[High(Pending)]];
    SetLength(Pending, High(Pending));
    ReachFrom(From);
  end;

  for var i := 0 to High(ACells) do
    if not Reached[i] then
      Exit(False);
  Result := True;
end;

function JudgeFormation(const ACells: TPadCells; const AGroup: TPadGroup;
  const ALaunch: TPadSpans; const AReach: TJumpReach): Boolean;
begin
  Result := NoneStacked(ACells) and (PairsOf(ACells) >= AGroup.Pairs) and
    Spread(ACells, AGroup.Zone) and AllReachable(ACells, ALaunch, AReach);
end;

// ---------------------------------------------------------------------------
// The assignment
// ---------------------------------------------------------------------------

function Shuffled(var ARandom: TXorShift; const ACells: TPadCells): TPadCells;
begin
  Result := Copy(ACells);
  for var i := High(Result) downto 1 do
  begin
    var j := Roll(ARandom, i + 1);
    var Swap := Result[i];
    Result[i] := Result[j];
    Result[j] := Swap;
  end;
end;

function SideBySide(const ACells: TPadCells; AFirst, ASecond: Integer): Boolean;
begin
  Result := (ACells[AFirst].Row = ACells[ASecond].Row) and
    (Abs(ACells[AFirst].Col - ACells[ASecond].Col) = 1);
end;

// The pad on AStart[APad] and one of its old neighbours after it stand
// side by side again
function PairedAgain(const AStart, ATarget: TPadCells; APad: Integer): Boolean;
begin
  for var Other := APad + 1 to High(AStart) do
    if SideBySide(AStart, APad, Other) and SideBySide(ATarget, APad, Other) then
      Exit(True);
  Result := False;
end;

function AssignmentHolds(const AStart, ATarget: TPadCells;
  const AGroup: TPadGroup): Boolean;
begin
  var FarFlights := 0;
  for var i := 0 to High(AStart) do
  begin
    var Flown := FlightCells(AStart[i], ATarget[i]);
    if Flown = 0 then
      Exit(False);
    if Flown >= AGroup.FarFlight then
      Inc(FarFlights);
  end;
  if FarFlights < AGroup.FarShare then
    Exit(False);

  for var i := 0 to High(AStart) do
    if PairedAgain(AStart, ATarget, i) then
      Exit(False);
  Result := True;
end;

function SortedFlights(const AStart, ATarget: TPadCells): TArray<Integer>;
begin
  SetLength(Result, Length(AStart));
  for var i := 0 to High(AStart) do
    Result[i] := FlightCells(AStart[i], ATarget[i]);
  TArray.Sort<Integer>(Result);
end;

// The shortest flights of AFlights longer than those of AThan: both
// sorted, compared from the shortest up
function ShortestLonger(const AFlights, AThan: TArray<Integer>): Boolean;
begin
  for var i := 0 to High(AFlights) do
    if AFlights[i] <> AThan[i] then
      Exit(AFlights[i] > AThan[i]);
  Result := False;
end;

function TryAssignFormation(var ARandom: TXorShift;
  const AStart, ACells: TPadCells; const AGroup: TPadGroup;
  out ATarget: TPadCells): Boolean;
var
  Best: TArray<Integer>;
begin
  Result := False;
  ATarget := nil;
  var Kept := 0;
  for var Attempt := 1 to AssignTries do
  begin
    var Target := Shuffled(ARandom, ACells);
    if not AssignmentHolds(AStart, Target, AGroup) then
      Continue;
    var Flights := SortedFlights(AStart, Target);
    if not Result or ShortestLonger(Flights, Best) then
    begin
      ATarget := Target;
      Best := Flights;
      Result := True;
    end;
    Inc(Kept);
    if Kept = AssignKept then
      Exit;
  end;
end;

end.
