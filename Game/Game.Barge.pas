{
  Game.Barge - the TeK hover-barge of the air phase, the hero's deck over
  the crater once the road runs out (Game.Road). It comes in from beyond
  the right edge as the road breaks away and moors a hop past the pier's
  end, riding left with the pier as the belt carries it - and no farther
  left than its mooring's floor, so it is never carried off the screen.
  The hero aboard, it casts off: it glides to its station and holds it
  while the world speeds up round it. The pier is given a grace to be
  boarded from; when it is over, or soon after the hero boards, the pier
  falls - the cue here, the falling Game.Road's.

  Only where the barge's left edge is and what it tells: the pad that is
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
  // From beyond the right edge to the mooring, in two seconds
  ComeFromX = ScreenWidth + 32.0;
  ComeTicks = 66;
  // Its station once the hero is aboard, its left edge: the right of the
  // screen is his, the city rides by on the left; the glide there in
  // three seconds
  StationLeft = 320.0;
  CastOffTicks = 100;
  // The pier's grace from the mooring, eight seconds; aboard, the pier
  // falls a second and a half after him
  GraceTicks = 264;
  BoardedPierTicks = 50;

type
  // bsAway - beyond the right edge; bsComing - gliding in to the mooring;
  // bsMoored - at the pier's end, riding with it; bsCasting - the hero
  // aboard, gliding to its station; bsStation - holding it
  TBargeStage = (bsAway, bsComing, bsMoored, bsCasting, bsStation);

  TBargeCue = record
    // It came to its mooring this tick
    Moored: Boolean;
    // The hero came aboard this tick: it casts off, the world speeds up
    Boarded: Boolean;
    // The pier's grace is over: it falls
    PierFalls: Boolean;
  end;

  TBargeRide = class
  private
    FStage: TBargeStage;
    // Ticks into a glide, and where it set off from
    FTicks: Integer;
    FFrom: Double;
    FLeft, FLastLeft: Double;
    // Ticks of the grace left; the pier told to fall already
    FGraceLeft: Integer;
    FPierTold: Boolean;
    procedure CastOff(var ACue: TBargeCue);
    function Mooring(APierRight: Double): Double;
  public
    constructor Create;
    // The road breaks away: the barge sets off from beyond the right edge
    // to the mooring; nothing unless away
    procedure Come;
    // At its station at once, the pier long gone: a restart in the air
    // phase
    procedure Station;
    // A death, a new level: away again
    procedure Clear;
    // APierRight - the pier's end on the screen, heard while APierStands;
    // AAboard - the hero stands on the barge's deck this tick
    function Tick(APierRight: Double; APierStands, AAboard: Boolean): TBargeCue;
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
  FFrom := ComeFromX;
  FLeft := ComeFromX;
  FLastLeft := ComeFromX;
  FGraceLeft := 0;
  FPierTold := False;
end;

procedure TBargeRide.Come;
begin
  if FStage <> bsAway then
    Exit;
  FStage := bsComing;
  FTicks := 0;
  FFrom := FLeft;
end;

procedure TBargeRide.Station;
begin
  FStage := bsStation;
  FTicks := 0;
  FFrom := StationLeft;
  FLeft := StationLeft;
  FLastLeft := StationLeft;
  FPierTold := True;
end;

function TBargeRide.Mooring(APierRight: Double): Double;
begin
  Result := Max(APierRight + MoorGap, MoorFloorX);
end;

procedure TBargeRide.CastOff(var ACue: TBargeCue);
begin
  FStage := bsCasting;
  FTicks := 0;
  FFrom := FLeft;
  FGraceLeft := BoardedPierTicks;
  ACue.Boarded := True;
end;

function TBargeRide.Tick(APierRight: Double; APierStands,
  AAboard: Boolean): TBargeCue;
begin
  Result := Default(TBargeCue);
  FLastLeft := FLeft;
  // The grace runs while it is moored, and the short one after he boards -
  // from the tick after either
  if (FStage in [bsMoored, bsCasting, bsStation]) and not FPierTold then
  begin
    Dec(FGraceLeft);
    if FGraceLeft <= 0 then
    begin
      FPierTold := True;
      Result.PierFalls := True;
    end;
  end;
  case FStage of
    bsComing:
      begin
        Inc(FTicks);
        // With no pier left the mooring is its floor
        var Berth: Double := MoorFloorX;
        if APierStands then
          Berth := Mooring(APierRight);
        FLeft := FFrom + (Berth - FFrom) * SmoothStep(FTicks / ComeTicks);
        if AAboard then
          CastOff(Result)
        else if FTicks >= ComeTicks then
        begin
          FStage := bsMoored;
          FGraceLeft := GraceTicks;
          Result.Moored := True;
        end;
      end;
    bsMoored:
      if AAboard then
        CastOff(Result)
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
