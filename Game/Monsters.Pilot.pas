{
  Monsters.Pilot - the one who flies a monster of the mkBossFly kind:
  where its body goes this tick and what it is up to. The monster keeps
  its place, its step and its guns; the pilot moves the place.

  The lap is the rectangle of 2008 with its top mark lowered clear of
  the HUD: four marks, every side overshooting its mark by what the step
  leaves, no wall asked. A maneuver (a 2026 addition) leaves the lap and
  comes back to it, the other way round. Every maneuver opens the same
  way, so there is one tell to learn: the body brakes onto a cell and
  ponders there - a hunt alone has no time for it. What follows is
  picked by the tactics the level's events set (TPilotTactics). Off the
  lap the pilot minds the walls: the level's grid and the bodies of its
  pads (Pads.World), the body one cell big.

  The lap may be held (Pads.Arena, while it rebuilds the pads): the body
  ends the maneuver it is in, comes back to the lap - a hunt too - and
  starts no other until it is let go. Let go, it rests on the lap anew,
  but a hunt goes on hunting at once, and new tactics still open with
  their maneuver.

  Not here: what a maneuver looks and sounds like. The disc, the bullets
  and the sparks of a crash are the monster's and the game's.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Monsters.Pilot;
{$I ..\Moon2D.inc}

interface

uses
  Levels.Defs, Monsters.Defs, Pads.World;

type
  THeading = (hdDown, hdLeft, hdUp, hdRight);

  TPilotState = (psLap, psBrake, psPonder, psDive, psAim, psDash, psStun,
    psReturn);

  TPilotGaze = (pgHero, pgAimPoint, pgNowhere);

  // 0-based
  TCell = record
    Col, Row: Integer;
  end;

  // Screen units: a point, or a direction across the screen
  TPlace = record
    X, Y: Double;
  end;

  // Screen units and units per tick. The point is the rim of the body
  // that struck; the normal is the way the wall faces, a unit vector.
  TPilotCrash = record
    X, Y: Single;
    SpeedX, SpeedY: Single;
    NormalX, NormalY: Single;
    // The crash as a blow to a pad the body may have struck
    Blow: TPadBlow;
  end;

  // A tick of the lap ahead: the feet point of the body, the cell under
  // its middle and the way it flew there
  TLapStep = record
    Feet: TPlace;
    Cell: TCell;
    Heading: THeading;
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
    FPads: TPadWorld;
    FScreen: Integer;
    FBaseStep: Integer;
    FTactics: TPilotTactics;
    FState: TPilotState;
    FHeading: THeading;
    FClockwise: Boolean;
    FLapRestTicks: Integer;
    // New tactics open with a maneuver at once
    FRestWaived: Boolean;
    FSearchTicks: Integer; // of the lap, for a cell with a runway
    FTargetCell: TCell;
    FTicksLeft: Integer; // of the state that counts them
    FReturnPath: TArray<TCell>;
    FReturnIndex: Integer;
    FPortsDue: Boolean;
    FAimPoint: TPlace; // the middle of the hero as the eye locked on
    FDashFrom: TPlace; // the middle of the body as the dash set off
    FDashDirection: TPlace; // a unit vector
    FDashTouchedHero: Boolean;
    FRammedLast: Boolean; // the maneuver before this one was a ram
    FLastCrash: TPilotCrash;
    FCrashed: Boolean;
    FOwesPrize: Boolean;
    FLapHeld: Boolean;
    FLapStep: Integer; // the monster's step, as the last brief told it
    function Walled(AX, AY: Single): Boolean;
    function CellOpen(const ACell: TCell): Boolean;
    function CanGo(AHeading: THeading): Boolean;
    function BodyBlocked(const AFeet: TPlace): Boolean;
    function Advance(var AFeet: TPlace; const ADirection: TPlace;
      AUnits: Integer): Boolean;
    function HasRunway(const ACell: TCell; const APoint: TPlace): Boolean;
    procedure Fly(var AFeet: TPlace; const ABrief: TPilotBrief);
    procedure FlyLap(var AFeet: TPlace; AStep: Integer);
    function LapCellAhead(const AFeet: TPlace): TCell;
    function SearchesForRunway(const ACell: TCell;
      const ABrief: TPilotBrief): Boolean;
    procedure Cruise(var AFeet: TPlace; const ABrief: TPilotBrief);
    procedure BeginBrake(const ACell: TCell);
    procedure Brake(var AFeet: TPlace; const ABrief: TPilotBrief);
    procedure Ponder(const ABrief: TPilotBrief);
    function MayRam: Boolean;
    procedure PickManeuver(const ABrief: TPilotBrief);
    procedure EndManeuver(const AFeet: TPlace);
    procedure BeginDive(const AHero: TCell);
    function HeroSide(const AHero: TCell): THeading;
    function CrossesHeroLine(const AHero: TCell): Boolean;
    function DiveHeading(const AHero: TCell): THeading;
    procedure Dive(var AFeet: TPlace; const ABrief: TPilotBrief);
    procedure BeginAim(const APoint: TPlace);
    procedure Aim(var AFeet: TPlace);
    procedure BeginDash(const AFeet: TPlace);
    function DashStride: Integer;
    procedure Dash(var AFeet: TPlace);
    function WallNormal(const AFeet: TPlace): TPlace;
    procedure HitWall(const AFeet: TPlace);
    function DashCameToAim(const AFeet: TPlace): Boolean;
    procedure Stun(const AFeet: TPlace);
    function PathToLap(const AFrom: TCell): TArray<TCell>;
    procedure BeginReturn(const AFeet: TPlace);
    procedure FlyBack(var AFeet: TPlace; AStep: Integer);
    procedure JoinLap(const ACell: TCell; AStep: Integer);
  public
    // ABaseStep - the step of the monster's definition: a dash is flown
    // by it whatever the rage has made of the monster's own. APads must
    // outlive the pilot.
    constructor Create(const ALevel: TLevel; const APads: TPadWorld;
      AScreen, ABaseStep: Integer);

    // One logic tick. AX, AY - the feet point of the body.
    procedure Tick(var AX, AY: Double; const ABrief: TPilotBrief);
    procedure SetTactics(ATactics: TPilotTactics);
    procedure NoteHeroContact;
    // The lap is held: back to it at the end of the maneuver, and no other
    // from it; let go - a new rest on it, none for a hunt or when new
    // tactics are owed at once
    procedure HoldLap(AHold: Boolean);
    function FliesLap: Boolean;
    // ATicks of the lap flown on from the feet point AX, AY, where it
    // would take the body: the pilot itself goes nowhere
    function LapAhead(AX, AY: Double; ATicks: Integer): TArray<TLapStep>;
    // In a maneuver
    function Busy: Boolean;
    // The monster's aimed gun is silent: off the lap the maneuver is the
    // threat, and a held lap is a breath while the arena is rebuilt. The
    // gun speaks on a free lap alone.
    function GunHeld: Boolean;
    function Gaze: TPilotGaze;
    // 0..1, for the sensor of the disc
    function Charge: Single;
    // ALapScale - the spin scale of the disc on the lap
    function SpinScale(ALapScale: Single): Single;
    // One tick only
    property PortsDue: Boolean read FPortsDue;
    property AimPoint: TPlace read FAimPoint;
    // One tick only; LastCrash says how the dash ended
    property Crashed: Boolean read FCrashed;
    property LastCrash: TPilotCrash read FLastCrash;
    // One tick only, the one after the crash
    property OwesPrize: Boolean read FOwesPrize;
  end;

// The point lies in a cell of the boss's lap. He flies the lap without
// asking the walls: nothing may be knocked into it.
function LapHolds(AX, AY: Single): Boolean;

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
  // above its bottom row - that one is floor and pits, nobody to chase.
  // In screen units: the top edge of a body in the top row, the feet
  // line of one in the bottom row.
  ArenaTopRow = LapTopRow;
  ArenaBottomRow = ScreenRows - 2;
  ArenaTop = ArenaTopRow * TileSize;
  ArenaBottom = (ArenaBottomRow + 1) * TileSize;

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
  HuntDiveTicks = 65; // a hunt looks for a ram twice as often

  AimTicks = 15; // the eye stands on its point: time to leave the line
  DashStepScale = 4; // of the definition's step
  StunTicks = 50;
  // A wall grazed by less than this does not stop a body
  BodyInset = 2;
  // A ram is flown where the dash has this much open flight before the
  // first wall: room to be seen coming
  MinRunway = 64;
  // A dash has come to its point when it is this close: bodies that
  // near touch (the game's contact box is 16 units either way across),
  // and the hero may stand closer to a wall than the body can fly
  SightGap = 12;
  // From the middle of a body to the point of it that struck: a unit
  // short of the wall, where a spark is not born inside it
  StrikeReach = SpriteSize / 2 - BodyInset - 1;
  // A way shorter than this has no direction
  MinDirectionLength = 1.0;

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

// The body at AFeet by the corners BodyBlocked asks the walls about,
// flying AWay: a pad holding a corner is knocked out for the stun
function BlowOf(const AFeet, AWay: TPlace): TPadBlow;
begin
  Result.Left := AFeet.X + BodyInset;
  Result.Right := AFeet.X + SpriteSize - BodyInset;
  Result.Top := AFeet.Y - SpriteSize + BodyInset;
  Result.Bottom := AFeet.Y - BodyInset;
  Result.WayX := AWay.X;
  Result.WayY := AWay.Y;
  Result.Ticks := StunTicks;
end;

function LapHolds(AX, AY: Single): Boolean;
begin
  var Cell: TCell;
  Cell.Col := Floor(AX / TileSize);
  Cell.Row := Floor(AY / TileSize);
  Result := OnLap(Cell);
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

// A tick of the lap: on along the heading, which turns past its mark
procedure FlyLapStep(var AFeet: TPlace; var AHeading: THeading;
  AClockwise: Boolean; AStep: Integer);
begin
  AFeet.X := AFeet.X + HeadingX[AHeading] * AStep;
  AFeet.Y := AFeet.Y + HeadingY[AHeading] * AStep;
  if not PastLapMark(AHeading, AFeet) then
    Exit;
  if AClockwise then
    AHeading := ClockwiseTurn[AHeading]
  else
    AHeading := CounterclockwiseTurn[AHeading];
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

// Straight down for a way too short to have a direction
function UnitOf(const AWay: TPlace): TPlace;
begin
  Result.X := 0;
  Result.Y := 1;
  var Reach := LengthOf(AWay);
  if Reach < MinDirectionLength then
    Exit;
  Result.X := AWay.X / Reach;
  Result.Y := AWay.Y / Reach;
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

constructor TPilot.Create(const ALevel: TLevel; const APads: TPadWorld;
  AScreen, ABaseStep: Integer);
begin
  inherited Create;
  FLevel := ALevel;
  FPads := APads;
  FScreen := AScreen;
  FBaseStep := ABaseStep;
  FTactics := ptLaps;
  FState := psLap;
  FHeading := hdDown;
  FClockwise := True;
  FLapStep := ABaseStep;
end;

procedure TPilot.SetTactics(ATactics: TPilotTactics);
begin
  if ATactics = FTactics then
    Exit;
  FTactics := ATactics;
  FLapRestTicks := 0;
  FRestWaived := True;
end;

procedure TPilot.NoteHeroContact;
begin
  FDashTouchedHero := True;
end;

procedure TPilot.HoldLap(AHold: Boolean);
begin
  if AHold = FLapHeld then
    Exit;
  FLapHeld := AHold;
  if AHold then
    Exit;
  FLapRestTicks := 0;
  var Rests := not FRestWaived and (FTactics <> ptHunts);
  if Rests then
    FLapRestTicks := RollRestTicks(FLapStep);
end;

function TPilot.FliesLap: Boolean;
begin
  Result := FState = psLap;
end;

function TPilot.Busy: Boolean;
begin
  Result := FState <> psLap;
end;

function TPilot.GunHeld: Boolean;
begin
  Result := Busy or FLapHeld;
end;

function TPilot.Gaze: TPilotGaze;
begin
  case FState of
    psAim, psDash:
      Result := pgAimPoint;
    psStun:
      Result := pgNowhere;
  else
    Result := pgHero;
  end;
end;

function TPilot.Charge: Single;
begin
  case FState of
    psPonder:
      Result := 1 - FTicksLeft / PonderTicks;
    psAim, psDash:
      Result := 1;
  else
    Result := 0;
  end;
end;

function TPilot.SpinScale(ALapScale: Single): Single;
begin
  case FState of
    psBrake, psPonder, psAim, psDash:
      Result := ALapScale + ManeuverSpinBoost;
    psStun:
      Result := 0;
  else
    Result := ALapScale;
  end;
end;

// A wall of the grid or the body of a pad at the point
function TPilot.Walled(AX, AY: Single): Boolean;
begin
  Result := FLevel.SolidAtPoint(FScreen, AX, AY) or
    FPads.BodyAt(FScreen, AX, AY);
end;

function TPilot.CellOpen(const ACell: TCell): Boolean;
begin
  var InArena := (ACell.Col >= 0) and (ACell.Col < ScreenCols) and
    (ACell.Row >= ArenaTopRow) and (ACell.Row <= ArenaBottomRow);
  var Middle := MiddleOf(FeetOf(ACell));
  Result := InArena and not Walled(Middle.X, Middle.Y);
end;

function TPilot.CanGo(AHeading: THeading): Boolean;
begin
  Result := CellOpen(Neighbour(FTargetCell, AHeading));
end;

// A body at the point would stand in a wall or out of the arena
function TPilot.BodyBlocked(const AFeet: TPlace): Boolean;
begin
  var OutOfArena := (AFeet.X < 0) or (AFeet.X + SpriteSize > ScreenWidth) or
    (AFeet.Y - SpriteSize < ArenaTop) or (AFeet.Y > ArenaBottom);
  if OutOfArena then
    Exit(True);

  var Left := AFeet.X + BodyInset;
  var Right := AFeet.X + SpriteSize - BodyInset;
  var Top := AFeet.Y - SpriteSize + BodyInset;
  var Bottom := AFeet.Y - BodyInset;
  Result := Walled(Left, Top) or Walled(Right, Top) or
    Walled(Left, Bottom) or Walled(Right, Bottom);
end;

// Unit by unit, asking the walls at every one: the body stops where it
// touches, not a stride short. False once a wall has stopped it.
function TPilot.Advance(var AFeet: TPlace; const ADirection: TPlace;
  AUnits: Integer): Boolean;
begin
  for var i := 1 to AUnits do
  begin
    var Onward := AFeet;
    Onward.X := Onward.X + ADirection.X;
    Onward.Y := Onward.Y + ADirection.Y;
    if BodyBlocked(Onward) then
      Exit(False);
    AFeet := Onward;
  end;
  Result := True;
end;

// A dash from the cell at the point would fly its runway, or come to the
// point, before a wall stops it - whatever hides the point beyond. The
// test is the dash itself, flown ahead of time.
function TPilot.HasRunway(const ACell: TCell; const APoint: TPlace): Boolean;
begin
  var Feet := FeetOf(ACell);
  var Way := WayTo(MiddleOf(Feet), APoint);
  var Units: Integer := Min(MinRunway, Trunc(LengthOf(Way)) - SightGap);
  Result := Advance(Feet, UnitOf(Way), Units);
end;

procedure TPilot.Tick(var AX, AY: Double; const ABrief: TPilotBrief);
var
  Feet: TPlace;
begin
  FPortsDue := False;
  FCrashed := False;
  FOwesPrize := False;
  FLapStep := ABrief.Step;

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
      Brake(AFeet, ABrief);
    psPonder:
      Ponder(ABrief);
    psDive:
      Dive(AFeet, ABrief);
    psAim:
      Aim(AFeet);
    psDash:
      Dash(AFeet);
    psStun:
      Stun(AFeet);
    psReturn:
      FlyBack(AFeet, ABrief.Step);
  end;
end;

procedure TPilot.FlyLap(var AFeet: TPlace; AStep: Integer);
begin
  FlyLapStep(AFeet, FHeading, FClockwise, AStep);
end;

function TPilot.LapAhead(AX, AY: Double; ATicks: Integer): TArray<TLapStep>;
var
  Feet: TPlace;
begin
  SetLength(Result, ATicks);
  Feet.X := AX;
  Feet.Y := AY;
  var Heading := FHeading;
  for var i := 0 to ATicks - 1 do
  begin
    Result[i].Heading := Heading;
    FlyLapStep(Feet, Heading, FClockwise, FLapStep);
    Result[i].Feet := Feet;
    Result[i].Cell := CellAt(Feet);
  end;
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

// A ram is worth pondering where a dash at the hero has its runway: the
// pilot flies on until the cell ahead has one, a lap at most
function TPilot.SearchesForRunway(const ACell: TCell;
  const ABrief: TPilotBrief): Boolean;
begin
  Result := (FTactics = ptRams) and (FSearchTicks < LapTicks(ABrief.Step)) and
    not HasRunway(ACell, MiddleOf(HeroFeet(ABrief)));
end;

procedure TPilot.Cruise(var AFeet: TPlace; const ABrief: TPilotBrief);
begin
  FlyLap(AFeet, ABrief.Step);
  if (FTactics = ptLaps) or FLapHeld then
    Exit;
  if FLapRestTicks > 0 then
  begin
    Dec(FLapRestTicks);
    Exit;
  end;

  var Ahead := LapCellAhead(AFeet);
  if SearchesForRunway(Ahead, ABrief) then
  begin
    Inc(FSearchTicks);
    Exit;
  end;
  BeginBrake(Ahead);
end;

procedure TPilot.BeginBrake(const ACell: TCell);
begin
  FSearchTicks := 0;
  FTargetCell := ACell;
  FState := psBrake;
end;

procedure TPilot.Brake(var AFeet: TPlace; const ABrief: TPilotBrief);
begin
  var Target := FeetOf(FTargetCell);
  var Stride := BrakeStride(LengthOf(WayTo(AFeet, Target)), ABrief.Step);
  if not Approach(AFeet, Target, Stride) then
    Exit;
  // A hunt has no time to ponder: on the cell, the next maneuver at once
  if FTactics = ptHunts then
  begin
    PickManeuver(ABrief);
    Exit;
  end;
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
  PickManeuver(ABrief);
end;

// A hunt never rams twice running: the dive between two rams keeps it
// on the move
function TPilot.MayRam: Boolean;
begin
  case FTactics of
    ptRams:
      Result := True;
    ptHunts:
      Result := not FRammedLast;
  else
    Result := False;
  end;
end;

// A ram is flown at where the hero stands, seen or not; with no runway
// it is a dive. What was pondered is flown even if the tactics are laps
// again.
procedure TPilot.PickManeuver(const ABrief: TPilotBrief);
begin
  // The maneuver now flown is the one new tactics were promised at once
  FRestWaived := False;
  var Hero := HeroFeet(ABrief);
  if MayRam and HasRunway(FTargetCell, MiddleOf(Hero)) then
    BeginAim(MiddleOf(Hero))
  else
    BeginDive(CellAt(Hero));
end;

// A hunt goes back to the lap only while it is held: else the next
// maneuver starts from the cell this one has ended at
procedure TPilot.EndManeuver(const AFeet: TPlace);
begin
  if (FTactics = ptHunts) and not FLapHeld then
    BeginBrake(CellAt(AFeet))
  else
    BeginReturn(AFeet);
end;

procedure TPilot.BeginDive(const AHero: TCell);
begin
  FHeading := HeadingToward(FTargetCell, AHero);
  FTicksLeft := DiveTicks;
  if FTactics = ptHunts then
    FTicksLeft := HuntDiveTicks;
  FRammedLast := False;
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
  if not Approach(AFeet, FeetOf(FTargetCell), ABrief.Step) then
    Exit;

  if FTicksLeft = 0 then
  begin
    EndManeuver(AFeet);
    Exit;
  end;
  FHeading := DiveHeading(CellAt(HeroFeet(ABrief)));
  // Walled in on all four sides, the dive stays where it is
  if CanGo(FHeading) then
    FTargetCell := Neighbour(FTargetCell, FHeading);
end;

procedure TPilot.BeginAim(const APoint: TPlace);
begin
  FAimPoint := APoint;
  FTicksLeft := AimTicks;
  FRammedLast := True;
  FState := psAim;
end;

procedure TPilot.Aim(var AFeet: TPlace);
begin
  Dec(FTicksLeft);
  if FTicksLeft > 0 then
    Exit;
  // The first stride in this very tick: its contact is then the dash's,
  // not the standing body's
  BeginDash(AFeet);
  Dash(AFeet);
end;

procedure TPilot.BeginDash(const AFeet: TPlace);
begin
  FDashFrom := MiddleOf(AFeet);
  FDashDirection := UnitOf(WayTo(FDashFrom, FAimPoint));
  FDashTouchedHero := False;
  FState := psDash;
end;

function TPilot.DashStride: Integer;
begin
  Result := DashStepScale * FBaseStep;
end;

procedure TPilot.Dash(var AFeet: TPlace);
begin
  if not Advance(AFeet, FDashDirection, DashStride) then
    HitWall(AFeet);
end;

// The way the wall faces: back along the one axis it stops the dash on,
// straight back at the body where a corner is met head-on
function TPilot.WallNormal(const AFeet: TPlace): TPlace;
begin
  var Sideways := AFeet;
  Sideways.X := Sideways.X + FDashDirection.X;
  var Upright := AFeet;
  Upright.Y := Upright.Y + FDashDirection.Y;
  var StopsAcross := BodyBlocked(Sideways);
  var StopsDown := BodyBlocked(Upright);

  Result.X := -FDashDirection.X;
  Result.Y := -FDashDirection.Y;
  if StopsAcross = StopsDown then
    Exit;
  if StopsAcross then
  begin
    Result.X := -Sign(FDashDirection.X);
    Result.Y := 0;
  end
  else
  begin
    Result.X := 0;
    Result.Y := -Sign(FDashDirection.Y);
  end;
end;

procedure TPilot.HitWall(const AFeet: TPlace);
begin
  var Normal := WallNormal(AFeet);
  var Middle := MiddleOf(AFeet);
  FLastCrash.X := Middle.X - Normal.X * StrikeReach;
  FLastCrash.Y := Middle.Y - Normal.Y * StrikeReach;
  FLastCrash.SpeedX := FDashDirection.X * DashStride;
  FLastCrash.SpeedY := FDashDirection.Y * DashStride;
  FLastCrash.NormalX := Normal.X;
  FLastCrash.NormalY := Normal.Y;
  // The step the walls refused: what it would have cut into is struck
  var Onward := AFeet;
  Onward.X := Onward.X + FDashDirection.X;
  Onward.Y := Onward.Y + FDashDirection.Y;
  FLastCrash.Blow := BlowOf(Onward, FDashDirection);
  FCrashed := True;

  FTicksLeft := StunTicks;
  FState := psStun;
end;

// A wall short of the point the eye had locked on stopped a dash nobody
// had to dodge. In whole units, as HasRunway counts them.
function TPilot.DashCameToAim(const AFeet: TPlace): Boolean;
begin
  var Flown := LengthOf(WayTo(FDashFrom, MiddleOf(AFeet)));
  var Aimed := LengthOf(WayTo(FDashFrom, FAimPoint));
  Result := Round(Flown) >= Trunc(Aimed) - SightGap;
end;

procedure TPilot.Stun(const AFeet: TPlace);
begin
  // The tick after the crash: by now the game has reported every touch
  // of the dash, the last one too
  if FTicksLeft = StunTicks then
    FOwesPrize := DashCameToAim(AFeet) and not FDashTouchedHero;
  Dec(FTicksLeft);
  if FTicksLeft = 0 then
    EndManeuver(AFeet);
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
  FRammedLast := False;
  FState := psLap;
  FLapRestTicks := 0;
  if not FRestWaived then
    FLapRestTicks := RollRestTicks(AStep);
end;

end.
