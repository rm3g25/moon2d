{
  Game.Barge - the TeK hover-barge of the air phase, the hero's deck over
  the crater once the road runs out (Game.Road). It hangs a hop past the
  pier's end from the moment the road runs out, so it comes in from
  beyond the right edge with the cliff and rides left with it - no
  farther left than its mooring's floor, so it is never carried off the
  screen. The hero aboard, it casts off: it glides to its station in the
  middle of the screen and holds it while the world speeds up round it.

  The fight on - the caller says when - it lets go of the station and
  drifts on a slow wide loop of its own - a figure of eight lying on its
  side, its middle across the middle three fifths of the screen and its
  deck half a cell up and down about the line it was moored on. It sets
  off gently, from the station itself, and never stops again: it follows
  neither the hero nor the Ram, and a hero who leaves it does not stop it.

  A blow from above rocks it: its deck dips and swings back to its line, a
  spring dying out, on top of the drift.

  Only where the barge's left edge and its deck are and when he boards:
  the pad that is the barge (Pads.World) is carried by the way this gives
  and bobs by itself, the belt's paces are Game.Belt's, the checkpoint on
  its deck is the game's, the small barges round it are Game.Flock's. No
  SDL.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.Barge;
{$I ..\Moon2D.inc}

interface

uses
  Game.Space;

const
  // The barge of the pier: five cells
  BargeLength = 160.0;
  // The mooring: this much open crater between the pier's end and the
  // barge - a plain jump
  MoorGap = 32.0;
  // Moored, it rides no farther left than this, its left edge: a hero who
  // falls off the pier's end still comes back onto a barge on the screen
  MoorFloorX = 64.0;
  // Its station once the hero is aboard, its left edge: the middle of the
  // screen; the glide there in three seconds
  StationLeft = (ScreenWidth - BargeLength) / 2;
  CastOffTicks = 100;
  // The drift: its middle swings this far either side of the screen's -
  // across the middle three fifths - and its deck this far over and under
  // its line, a lap of the eight in 18 s; it comes up to its pace from the
  // station over 2 s
  DriftReachX = 0.3 * ScreenWidth;
  DriftReachY = 16.0;
  DriftLapTicks = 594;
  LooseTicks = 66;

type
  // bsAway - not there; bsMoored - a hop past the pier's end, riding with
  // it; bsCasting - the hero aboard, gliding to its station; bsStation -
  // holding it; bsDrift - the fight on, drifting on its loop
  TBargeStage = (bsAway, bsMoored, bsCasting, bsStation, bsDrift);

  TBargeRide = class
  private
    FStage: TBargeStage;
    // Ticks into the glide, and where it set off from
    FTicks: Integer;
    FFrom: Double;
    FLeft, FLastLeft: Double;
    // Units under the line it was moored on, below 0 over it
    FDip, FLastDip: Double;
    // How far round the eight it has gone, in radians
    FTurn: Double;
    // The rock of a blow: units under where the drift has the deck, and
    // units a tick
    FRock: Double;
    FRockPace: Double;
    function Mooring(APierRight: Double): Double;
    procedure Drift;
    procedure Swing;
  public
    constructor Create;
    // The road runs out, its end at APierRight: the barge hangs a hop past
    // it; nothing unless away
    procedure Moor(APierRight: Double);
    // At its station at once, the pier long gone: a restart in the air
    // phase
    procedure Station;
    // A death, a new level: away again
    procedure Clear;
    // The fight is on: it lets go of its station and drifts from the next
    // tick on; nothing unless at its station
    procedure Loose;
    // Struck from above: its deck dips by about ADepth and swings back
    procedure Rock(ADepth: Double);
    // APierRight - the pier's end on the screen, heard while APierStands;
    // AAboard - the hero stands on the barge's deck this tick. True the
    // tick he comes aboard: it casts off, the world speeds up.
    function Tick(APierRight: Double; APierStands, AAboard: Boolean): Boolean;
    // How far it went across this tick, below 0 to the left
    function Way: Double;
    // How far it went down this tick, below 0 up
    function WayDown: Double;
    // Its left edge AAlpha of the way from the last tick to this one
    function LeftAt(AAlpha: Single): Double;
    property Stage: TBargeStage read FStage;
    property Left: Double read FLeft;
    // Units its deck is under the line it was moored on, below 0 over it
    property Dip: Double read FDip;
  end;

implementation

uses
  System.Math;

const
  // The rock's spring: a swing of about a second, all but gone after two
  RockPull = 0.04;
  RockDrag = 0.1;
  // The pace a blow gives for each unit of depth asked: the spring then
  // goes about that deep
  RockKick = 0.31;

function SmoothStep(AShare: Single): Single;
begin
  var Share := EnsureRange(AShare, 0.0, 1.0);
  Result := Share * Share * (3 - 2 * Share);
end;

constructor TBargeRide.Create;
begin
  inherited Create;
  Clear;
end;

procedure TBargeRide.Clear;
begin
  FStage := bsAway;
  FTicks := 0;
  FFrom := ScreenWidth;
  FLeft := ScreenWidth;
  FLastLeft := ScreenWidth;
  FDip := 0;
  FLastDip := 0;
  FTurn := 0;
  FRock := 0;
  FRockPace := 0;
end;

procedure TBargeRide.Moor(APierRight: Double);
begin
  if FStage <> bsAway then
    Exit;
  FStage := bsMoored;
  FLeft := Mooring(APierRight);
  FLastLeft := FLeft;
end;

procedure TBargeRide.Station;
begin
  FStage := bsStation;
  FTicks := 0;
  FFrom := StationLeft;
  FLeft := StationLeft;
  FLastLeft := StationLeft;
  FDip := 0;
  FLastDip := 0;
  FTurn := 0;
  FRock := 0;
  FRockPace := 0;
end;

function TBargeRide.Mooring(APierRight: Double): Double;
begin
  Result := Max(APierRight + MoorGap, MoorFloorX);
end;

// From the station round a figure of eight lying on its side: across
// once a lap, up and down twice; the pace grown into from a standstill
procedure TBargeRide.Drift;
begin
  Inc(FTicks);
  var Pace := 2 * Pi / DriftLapTicks * SmoothStep(FTicks / LooseTicks);
  FTurn := FTurn + Pace;
  var Middle := ScreenWidth / 2 + DriftReachX * Sin(FTurn);
  FLeft := Middle - BargeLength / 2;
  FDip := -DriftReachY * Sin(2 * FTurn) + FRock;
end;

procedure TBargeRide.Loose;
begin
  if FStage <> bsStation then
    Exit;
  FStage := bsDrift;
  FTicks := 0;
  FTurn := 0;
end;

procedure TBargeRide.Rock(ADepth: Double);
begin
  FRockPace := FRockPace + ADepth * RockKick;
end;

procedure TBargeRide.Swing;
begin
  FRockPace := FRockPace - RockPull * FRock - RockDrag * FRockPace;
  FRock := FRock + FRockPace;
end;

function TBargeRide.Tick(APierRight: Double; APierStands,
  AAboard: Boolean): Boolean;
begin
  Result := False;
  FLastLeft := FLeft;
  FLastDip := FDip;
  case FStage of
    bsMoored:
      if AAboard then
      begin
        FStage := bsCasting;
        FTicks := 0;
        FFrom := FLeft;
        Result := True;
      end
      else if APierStands then
        FLeft := Mooring(APierRight);
    bsCasting:
      begin
        Inc(FTicks);
        FLeft := FFrom + (StationLeft - FFrom) * SmoothStep(FTicks / CastOffTicks);
        if FTicks >= CastOffTicks then
          FStage := bsStation;
      end;
    bsDrift:
      begin
        Swing;
        Drift;
      end;
  end;
end;

function TBargeRide.Way: Double;
begin
  Result := FLeft - FLastLeft;
end;

function TBargeRide.WayDown: Double;
begin
  Result := FDip - FLastDip;
end;

function TBargeRide.LeftAt(AAlpha: Single): Double;
begin
  Result := FLastLeft + (FLeft - FLastLeft) * AAlpha;
end;

end.
