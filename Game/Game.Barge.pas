{
  Game.Barge - the TeK hover-barge of the air phase, the hero's deck over
  the crater once the road runs out (Game.Road). It hangs a hop past the
  pier's end from the moment the road runs out, so it comes in from
  beyond the right edge with the cliff and rides left with it - no
  farther left than its mooring's floor, so it is never carried off the
  screen. The hero aboard, it casts off: it glides to its station in the
  middle of the screen and holds it while the world speeds up round it.

  Only where the barge's left edge is and when he boards: the pad that is
  the barge (Pads.World) is carried by the way this gives and bobs by
  itself, the belt's paces are Game.Belt's, the checkpoint on its deck is
  the game's. No SDL.

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

type
  // bsAway - not there; bsMoored - a hop past the pier's end, riding with
  // it; bsCasting - the hero aboard, gliding to its station; bsStation -
  // holding it
  TBargeStage = (bsAway, bsMoored, bsCasting, bsStation);

  TBargeRide = class
  private
    FStage: TBargeStage;
    // Ticks into the glide, and where it set off from
    FTicks: Integer;
    FFrom: Double;
    FLeft, FLastLeft: Double;
    function Mooring(APierRight: Double): Double;
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
    // APierRight - the pier's end on the screen, heard while APierStands;
    // AAboard - the hero stands on the barge's deck this tick. True the
    // tick he comes aboard: it casts off, the world speeds up
    function Tick(APierRight: Double; APierStands, AAboard: Boolean): Boolean;
    // How far it went across this tick, below 0 to the left
    function Way: Double;
    // Its left edge AAlpha of the way from the last tick to this one
    function LeftAt(AAlpha: Single): Double;
    property Stage: TBargeStage read FStage;
    property Left: Double read FLeft;
  end;

implementation

uses
  System.Math;

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
end;

function TBargeRide.Mooring(APierRight: Double): Double;
begin
  Result := Max(APierRight + MoorGap, MoorFloorX);
end;

function TBargeRide.Tick(APierRight: Double; APierStands,
  AAboard: Boolean): Boolean;
begin
  Result := False;
  FLastLeft := FLeft;
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
    bsStation:
      FLeft := StationLeft;
  end;
end;

function TBargeRide.Way: Double;
begin
  Result := FLeft - FLastLeft;
end;

function TBargeRide.LeftAt(AAlpha: Single): Double;
begin
  Result := FLastLeft + (FLeft - FLastLeft) * AAlpha;
end;

end.
