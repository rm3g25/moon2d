{
  Monsters.Pilot - the one who flies a monster of the mkBossFly kind:
  where its body goes this tick and what it is up to. The monster keeps
  its place, its step and its guns; the pilot moves the place.

  The lap is the rectangle of 2008 with its top mark lowered clear of
  the HUD: four marks, every side overshooting its mark by what the step
  leaves, no wall asked. A maneuver (a 2026 addition) leaves the lap and
  comes back to it, the other way round. Every maneuver opens the same
  way, so there is one tell to learn: the body brakes onto a cell and
  ponders there. What follows is picked by the tactics the level's
  events set (TPilotTactics). Off the lap the pilot minds the walls: the
  level's grid, the body one cell big.

  Not here: what a maneuver looks like. The disc and the bullets are the
  monster's.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Monsters.Pilot;
{$I ..\Moon2D.inc}

interface

uses
  Levels.Defs, Monsters.Defs;

type
  THeading = (hdDown, hdLeft, hdUp, hdRight);

  TPilotState = (psLap, psBrake, psPonder, psDive, psReturn);

  // 0-based
  TCell = record
    Col, Row: Integer;
  end;

  // Screen units
  TPlace = record
    X, Y: Double;
  end;

  // What the monster tells its pilot every tick
  TPilotBrief = record
    Step: Integer; // the monster's own: its rage doubles it
    HeroX, HeroY: Integer; // the hero's feet point
    BodyAlive: Boolean;
  end;

  TPilot = class
  private
    FLevel: TLevel;
    FScreen: Integer;
    FBaseStep: Integer;
    FTactics: TPilotTactics;
    FState: TPilotState;
    FHeading: THeading;
    FClockwise: Boolean;
    FLapRestTicks: Integer;
    // New tactics open with a maneuver at once
    FRestWaived: Boolean;
    FTargetCell: TCell;
    FTicksLeft: Integer; // of the state that counts them
    FReturnPath: TArray<TCell>;
    FReturnIndex: Integer;
    FPortsDue: Boolean;
    function CellOpen(const ACell: TCell): Boolean;
    function CanGo(AHeading: THeading): Boolean;
    procedure Fly(var AFeet: TPlace; const ABrief: TPilotBrief);
    procedure FlyLap(var AFeet: TPlace; AStep: Integer);
    function LapCellAhead(const AFeet: TPlace): TCell;
    procedure Cruise(var AFeet: TPlace; const ABrief: TPilotBrief);
    procedure BeginBrake(const ACell: TCell);
    procedure Brake(var AFeet: TPlace; AStep: Integer);
    procedure Ponder(const ABrief: TPilotBrief);
    procedure BeginDive(const AHero: TCell);
    function HeroSide(const AHero: TCell): THeading;
    function CrossesHeroLine(const AHero: TCell): Boolean;
    function DiveHeading(const AHero: TCell): THeading;
    procedure Dive(var AFeet: TPlace; const ABrief: TPilotBrief);
    function PathToLap(const AFrom: TCell): TArray<TCell>;
    procedure BeginReturn(const AFeet: TPlace);
    procedure FlyBack(var AFeet: TPlace; AStep: Integer);
    procedure JoinLap(const ACell: TCell; AStep: Integer);
  public
    // ABaseStep - the step of the monster's definition: a dive is flown
    // by it whatever the rage has made of the monster's own
    constructor Create(const ALevel: TLevel; AScreen, ABaseStep: Integer);

    // One logic tick. AX, AY - the feet point of the body.
    procedure Tick(var AX, AY: Double; const ABrief: TPilotBrief);
    procedure SetTactics(ATactics: TPilotTactics);
    // In a maneuver
    function Busy: Boolean;
    // 0..1, for the sensor of the disc
    function Charge: Single;
    // ALapScale - the spin scale of the disc on the lap
    function SpinScale(ALapScale: Single): Single;
    // One tick only
    property PortsDue: Boolean read FPortsDue;
  end;

implementation

uses
  System.Math, Render.Sprites, Game.Space;

const
  // The marks a side of the lap is flown to, by the feet point of the
  // body. The top one keeps the boss in sight: the HUD panels reach y 36
  // and the body rises 32 above its Y.
  LapLeft = 32;
  LapRight = 448;
  LapTop = 96;
  LapBottom = 320;
  // The lanes of the lap in cells. Y is the feet line: the body stands
  // in the row above it.
  LapLeftCol = LapLeft div TileSize;
  LapRightCol = LapRight div TileSize;
  LapTopRow = LapTop div TileSize - 1;
  LapBottomRow = LapBottom div TileSize - 1;
  LapLength = 2 * (LapRight - LapLeft + LapBottom - LapTop);

  // Where a maneuver may take the body: the screen under the HUD and
  // above its bottom row - that one is floor and pits, nobody to chase
  ArenaTopRow = LapTopRow;
  ArenaBottomRow = ScreenRows - 2;

  MinRestLaps = 1.0;
  MaxRestLaps = 2.0;

  // A tick of braking covers this share of the distance left
  BrakeShare = 0.15;
  MinBrakeStride = 1.0;

  PonderTicks = 50; // a second and a half to read the tell
  // The ports fire on a beat, the last volley as the maneuver leaves
  PortVolleys = 5;
  PortsEveryTicks = 9;
  PortsLeadTicks = PonderTicks - (PortVolleys - 1) * PortsEveryTicks;
  ManeuverSpinBoost = 2.0;

  DiveTicks = 130; // about four seconds

  // Screen units and cells a heading moves by; Y runs down
  HeadingX: array [THeading] of Integer = (0, -1, 0, 1);
  HeadingY: array [THeading] of Integer = (1, 0, -1, 0);
  Opposite: array [THeading] of THeading = (hdUp, hdRight, hdDown, hdLeft);
  ClockwiseTurn: array [THeading] of THeading =
    (hdLeft, hdUp, hdRight, hdDown);
  CounterclockwiseTurn: array [THeading] of THeading =
    (hdRight, hdDown, hdLeft, hdUp);
  // The lane a heading is flown on: a column for the upright sides, a
  // row for the level ones
  ClockwiseLane: array [THeading] of Integer =
    (LapRightCol, LapBottomRow, LapLeftCol, LapTopRow);
  CounterclockwiseLane: array [THeading] of Integer =
    (LapLeftCol, LapTopRow, LapRightCol, LapBottomRow);

// Of a body standing in the cell
function FeetOf(const ACell: TCell): TPlace;
begin
  Result.X := ACell.Col * TileSize;
  Result.Y := (ACell.Row + 1) * TileSize;
end;

function MiddleOf(const AFeet: TPlace): TPlace;
begin
  Result.X := AFeet.X + SpriteSize / 2;
  Result.Y := AFeet.Y - SpriteSize / 2;
end;

// Under the middle of the body, kept on the grid
function CellAt(const AFeet: TPlace): TCell;
begin
  var Middle := MiddleOf(AFeet);
  Result.Col := EnsureRange(Floor(Middle.X / TileSize), 0, ScreenCols - 1);
  Result.Row := EnsureRange(Floor(Middle.Y / TileSize), 0, ScreenRows - 1);
end;

function HeroFeet(const ABrief: TPilotBrief): TPlace;
begin
  Result.X := ABrief.HeroX;
  Result.Y := ABrief.HeroY;
end;

function Neighbour(const ACell: TCell; AHeading: THeading): TCell;
begin
  Result.Col := ACell.Col + HeadingX[AHeading];
  Result.Row := ACell.Row + HeadingY[AHeading];
end;

function SameCell(const ALeft, ARight: TCell): Boolean;
begin
  Result := (ALeft.Col = ARight.Col) and (ALeft.Row = ARight.Row);
end;

function OnLap(const ACell: TCell): Boolean;
begin
  var Inside := (ACell.Col >= LapLeftCol) and (ACell.Col <= LapRightCol) and
    (ACell.Row >= LapTopRow) and (ACell.Row <= LapBottomRow);
  var OnEdge := (ACell.Col = LapLeftCol) or (ACell.Col = LapRightCol) or
    (ACell.Row = LapTopRow) or (ACell.Row = LapBottomRow);
  Result := Inside and OnEdge;
end;

function PastLapMark(AHeading: THeading; const AFeet: TPlace): Boolean;
begin
  case AHeading of
    hdDown:
      Result := AFeet.Y > LapBottom;
    hdLeft:
      Result := AFeet.X < LapLeft;
    hdUp:
      Result := AFeet.Y < LapTop;
  else
    Result := AFeet.X > LapRight;
  end;
end;

// A corner goes with the side that leaves it
function LapHeadingAt(const ACell: TCell; AClockwise: Boolean): THeading;
begin
  if AClockwise then
  begin
    if (ACell.Row = LapTopRow) and (ACell.Col < LapRightCol) then
      Exit(hdRight);
    if (ACell.Col = LapRightCol) and (ACell.Row < LapBottomRow) then
      Exit(hdDown);
    if (ACell.Row = LapBottomRow) and (ACell.Col > LapLeftCol) then
      Exit(hdLeft);
    Exit(hdUp);
  end;

  if (ACell.Row = LapTopRow) and (ACell.Col > LapLeftCol) then
    Exit(hdLeft);
  if (ACell.Col = LapLeftCol) and (ACell.Row < LapBottomRow) then
    Exit(hdDown);
  if (ACell.Row = LapBottomRow) and (ACell.Col < LapRightCol) then
    Exit(hdRight);
  Result := hdUp;
end;

// Along the longer leg of the way
function HeadingToward(const AFrom, ATo: TCell): THeading;
begin
  var Across := ATo.Col - AFrom.Col;
  var Down := ATo.Row - AFrom.Row;
  if Abs(Across) >= Abs(Down) then
  begin
    if Across >= 0 then
      Exit(hdRight);
    Exit(hdLeft);
  end;
  if Down >= 0 then
    Exit(hdDown);
  Result := hdUp;
end;

function WayTo(const AFrom, ATo: TPlace): TPlace;
begin
  Result.X := ATo.X - AFrom.X;
  Result.Y := ATo.Y - AFrom.Y;
end;

function LengthOf(const AWay: TPlace): Double;
begin
  Result := Sqrt(Sqr(AWay.X) + Sqr(AWay.Y));
end;

// True once there
function Approach(var AFeet: TPlace; const ATarget: TPlace;
  AStride: Double): Boolean;
begin
  var Way := WayTo(AFeet, ATarget);
  var Distance := LengthOf(Way);
  Result := Distance <= AStride;
  if Result then
  begin
    AFeet := ATarget;
    Exit;
  end;
  AFeet.X := AFeet.X + Way.X / Distance * AStride;
  AFeet.Y := AFeet.Y + Way.Y / Distance * AStride;
end;

// Never faster than the body flew
function BrakeStride(ADistance: Double; AStep: Integer): Double;
begin
  Result := ADistance * BrakeShare;
  if Result > AStep then
    Result := AStep;
  if Result < MinBrakeStride then
    Result := MinBrakeStride;
end;

function LapTicks(AStep: Integer): Integer;
begin
  Result := LapLength div Max(1, AStep);
end;

function RollRestTicks(AStep: Integer): Integer;
begin
  var Laps := MinRestLaps + Random * (MaxRestLaps - MinRestLaps);
  Result := Round(LapTicks(AStep) * Laps);
end;

// ---------------------------------------------------------------------------
// TPilot
// ---------------------------------------------------------------------------

constructor TPilot.Create(const ALevel: TLevel; AScreen, ABaseStep: Integer);
begin
  inherited Create;
  FLevel := ALevel;
  FScreen := AScreen;
  FBaseStep := ABaseStep;
  FTactics := ptLaps;
  FState := psLap;
  FHeading := hdDown;
  FClockwise := True;
end;

procedure TPilot.SetTactics(ATactics: TPilotTactics);
begin
  if ATactics = FTactics then
    Exit;
  FTactics := ATactics;
  FLapRestTicks := 0;
  FRestWaived := True;
end;

function TPilot.Busy: Boolean;
begin
  Result := FState <> psLap;
end;

function TPilot.Charge: Single;
begin
  Result := 0;
  if FState = psPonder then
    Result := 1 - FTicksLeft / PonderTicks;
end;

function TPilot.SpinScale(ALapScale: Single): Single;
begin
  Result := ALapScale;
  if FState in [psBrake, psPonder] then
    Result := ALapScale + ManeuverSpinBoost;
end;

function TPilot.CellOpen(const ACell: TCell): Boolean;
begin
  var InArena := (ACell.Col >= 0) and (ACell.Col < ScreenCols) and
    (ACell.Row >= ArenaTopRow) and (ACell.Row <= ArenaBottomRow);
  Result := InArena and not FLevel.SolidAt(FScreen, ACell.Col, ACell.Row);
end;

function TPilot.CanGo(AHeading: THeading): Boolean;
begin
  Result := CellOpen(Neighbour(FTargetCell, AHeading));
end;

procedure TPilot.Tick(var AX, AY: Double; const ABrief: TPilotBrief);
var
  Feet: TPlace;
begin
  FPortsDue := False;

  Feet.X := AX;
  Feet.Y := AY;
  Fly(Feet, ABrief);
  AX := Feet.X;
  AY := Feet.Y;
end;

procedure TPilot.Fly(var AFeet: TPlace; const ABrief: TPilotBrief);
begin
  // The dying keep the slide of 2008 along the lap; off it they hang
  // where death found them
  if not ABrief.BodyAlive then
  begin
    if FState = psLap then
      FlyLap(AFeet, ABrief.Step);
    Exit;
  end;

  case FState of
    psLap:
      Cruise(AFeet, ABrief);
    psBrake:
      Brake(AFeet, ABrief.Step);
    psPonder:
      Ponder(ABrief);
    psDive:
      Dive(AFeet, ABrief);
    psReturn:
      FlyBack(AFeet, ABrief.Step);
  end;
end;

procedure TPilot.FlyLap(var AFeet: TPlace; AStep: Integer);
begin
  AFeet.X := AFeet.X + HeadingX[FHeading] * AStep;
  AFeet.Y := AFeet.Y + HeadingY[FHeading] * AStep;
  if not PastLapMark(FHeading, AFeet) then
    Exit;
  if FClockwise then
    FHeading := ClockwiseTurn[FHeading]
  else
    FHeading := CounterclockwiseTurn[FHeading];
end;

// One cell on from where the body is, on the lane its heading flies. A
// side overshoots its mark and a bullet shoves the body off its lane:
// the cell stays on the lap all the same.
function TPilot.LapCellAhead(const AFeet: TPlace): TCell;
begin
  Result := Neighbour(CellAt(AFeet), FHeading);
  Result.Col := EnsureRange(Result.Col, LapLeftCol, LapRightCol);
  Result.Row := EnsureRange(Result.Row, LapTopRow, LapBottomRow);

  var Lane := CounterclockwiseLane[FHeading];
  if FClockwise then
    Lane := ClockwiseLane[FHeading];
  if FHeading in [hdDown, hdUp] then
    Result.Col := Lane
  else
    Result.Row := Lane;
end;

procedure TPilot.Cruise(var AFeet: TPlace; const ABrief: TPilotBrief);
begin
  FlyLap(AFeet, ABrief.Step);
  if FTactics = ptLaps then
    Exit;
  if FLapRestTicks > 0 then
  begin
    Dec(FLapRestTicks);
    Exit;
  end;

  BeginBrake(LapCellAhead(AFeet));
end;

procedure TPilot.BeginBrake(const ACell: TCell);
begin
  FTargetCell := ACell;
  FState := psBrake;
end;

procedure TPilot.Brake(var AFeet: TPlace; AStep: Integer);
begin
  var Target := FeetOf(FTargetCell);
  var Stride := BrakeStride(LengthOf(WayTo(AFeet, Target)), AStep);
  if not Approach(AFeet, Target, Stride) then
    Exit;
  FTicksLeft := PonderTicks;
  FState := psPonder;
end;

procedure TPilot.Ponder(const ABrief: TPilotBrief);
begin
  Dec(FTicksLeft);
  var Elapsed := PonderTicks - FTicksLeft;
  FPortsDue := (Elapsed >= PortsLeadTicks) and
    ((Elapsed - PortsLeadTicks) mod PortsEveryTicks = 0);
  if FTicksLeft > 0 then
    Exit;

  // The maneuver now flown is the one new tactics were promised at once
  FRestWaived := False;
  BeginDive(CellAt(HeroFeet(ABrief)));
end;

procedure TPilot.BeginDive(const AHero: TCell);
begin
  FHeading := HeadingToward(FTargetCell, AHero);
  FTicksLeft := DiveTicks;
  FState := psDive;
end;

// Of the two ways across the heading, the one the hero is on
function TPilot.HeroSide(const AHero: TCell): THeading;
begin
  if FHeading in [hdLeft, hdRight] then
  begin
    if AHero.Row >= FTargetCell.Row then
      Exit(hdDown);
    Exit(hdUp);
  end;
  if AHero.Col >= FTargetCell.Col then
    Exit(hdRight);
  Result := hdLeft;
end;

// The hero is straight across the heading: in the column a dive flies
// through, in the row it climbs past
function TPilot.CrossesHeroLine(const AHero: TCell): Boolean;
begin
  if FHeading in [hdLeft, hdRight] then
    Result := (AHero.Col = FTargetCell.Col) and (AHero.Row <> FTargetCell.Row)
  else
    Result := (AHero.Row = FTargetCell.Row) and (AHero.Col <> FTargetCell.Col);
end;

// Every turn of a dive has a cause the player can learn: the hero's
// line crossed, or a wall ahead - and then his side first
function TPilot.DiveHeading(const AHero: TCell): THeading;
begin
  var Side := HeroSide(AHero);
  if CrossesHeroLine(AHero) and CanGo(Side) then
    Exit(Side);
  if CanGo(FHeading) then
    Exit(FHeading);

  if CanGo(Side) then
    Exit(Side);
  if CanGo(Opposite[Side]) then
    Exit(Opposite[Side]);
  Result := Opposite[FHeading];
end;

procedure TPilot.Dive(var AFeet: TPlace; const ABrief: TPilotBrief);
begin
  if FTicksLeft > 0 then
    Dec(FTicksLeft);
  if not Approach(AFeet, FeetOf(FTargetCell), FBaseStep) then
    Exit;

  if FTicksLeft = 0 then
  begin
    BeginReturn(AFeet);
    Exit;
  end;
  FHeading := DiveHeading(CellAt(HeroFeet(ABrief)));
  // Walled in on all four sides, the dive stays where it is
  if CanGo(FHeading) then
    FTargetCell := Neighbour(FTargetCell, FHeading);
end;

// The shortest way over open cells to the lap, AFrom first. A body
// walled in gets AFrom alone and joins the lap from where it is.
function TPilot.PathToLap(const AFrom: TCell): TArray<TCell>;
var
  Seen: array [0..ScreenCols - 1, 0..ScreenRows - 1] of Boolean;
  CameBy: array [0..ScreenCols - 1, 0..ScreenRows - 1] of THeading;
  Queue: array [0..ScreenCols * ScreenRows - 1] of TCell;

  function Before(const ACell: TCell): TCell;
  begin
    Result := Neighbour(ACell, Opposite[CameBy[ACell.Col, ACell.Row]]);
  end;

begin
  FillChar(Seen, SizeOf(Seen), 0);
  Seen[AFrom.Col, AFrom.Row] := True;
  Queue[0] := AFrom;
  var Head := 0;
  var Tail := 1;
  while (Head < Tail) and not OnLap(Queue[Head]) do
  begin
    var Cell := Queue[Head];
    Inc(Head);
    for var Heading := Low(THeading) to High(THeading) do
    begin
      var Next := Neighbour(Cell, Heading);
      // CellOpen first: it is what keeps Next on the grid Seen spans
      if not CellOpen(Next) or Seen[Next.Col, Next.Row] then
        Continue;
      Seen[Next.Col, Next.Row] := True;
      CameBy[Next.Col, Next.Row] := Heading;
      Queue[Tail] := Next;
      Inc(Tail);
    end;
  end;

  var Goal := AFrom;
  if Head < Tail then
    Goal := Queue[Head];
  var Hops := 0;
  var Back := Goal;
  while not SameCell(Back, AFrom) do
  begin
    Back := Before(Back);
    Inc(Hops);
  end;

  SetLength(Result, Hops + 1);
  Back := Goal;
  for var i := Hops downto 1 do
  begin
    Result[i] := Back;
    Back := Before(Back);
  end;
  Result[0] := AFrom;
end;

procedure TPilot.BeginReturn(const AFeet: TPlace);
begin
  FReturnPath := PathToLap(CellAt(AFeet));
  FReturnIndex := 0;
  FState := psReturn;
end;

procedure TPilot.FlyBack(var AFeet: TPlace; AStep: Integer);
begin
  var Target := FeetOf(FReturnPath[FReturnIndex]);
  if not Approach(AFeet, Target, AStep) then
    Exit;
  if FReturnIndex < High(FReturnPath) then
  begin
    Inc(FReturnIndex);
    Exit;
  end;
  JoinLap(FReturnPath[FReturnIndex], AStep);
end;

procedure TPilot.JoinLap(const ACell: TCell; AStep: Integer);
begin
  FClockwise := not FClockwise;
  FHeading := LapHeadingAt(ACell, FClockwise);
  FState := psLap;
  FLapRestTicks := 0;
  if not FRestWaived then
    FLapRestTicks := RollRestTicks(AStep);
end;

end.
