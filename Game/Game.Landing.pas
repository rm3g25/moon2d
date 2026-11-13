{
  Game.Landing - the end of the flight, from the hull's burst to the
  picture the titles stand on. The fight is over the moment the hull's
  last life goes: nothing wounds the hero from then on. The flight runs
  on at its pace a while, under the burst and its pieces; then it slows
  down, the main barge glides to its berth in the middle of the screen,
  and the road comes back - its edge in from beyond the right edge, riding
  the slowing world up against the barge's right side. Docked there, the
  barge rides on with the road, and the world comes to rest with the barge
  against the left edge of the screen and the road from its side on: no
  abyss left to fall into. A breath over the still picture, and the titles
  take over: the hand-over. The end track is not the landing's - it came in
  with the hull's burst.

  Only the clock and what each tick tells: the belt, the road, the barge,
  the hero and the sound are the caller's. The road's edge comes in where
  the slowdown left to run brings it exactly to its stop - the caller
  tells that every tick. No SDL.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.Landing;
{$I ..\Moon2D.inc}

interface

uses
  Game.Barge;

const
  // From the burst to the slowdown: the pieces fly at the flight's pace
  LandingSlowAfterTicks = 66;
  // The slowdown: from the flight's pace to a standstill in six seconds -
  // long enough for the road to come in from beyond the right edge, meet
  // the barge at its berth and take it to the left edge
  LandingSlowTicks = 198;
  // The main barge glides to its berth this fast: there well before the
  // road reaches it
  LandingBerthTicks = 50;
  // The still picture holds its breath this long before the titles
  LandingHandOverAfterTicks = 66;
  // The road's edge stops a barge's length from the left edge: the main
  // barge, docked against it, stops against the left edge
  LandingRoadStop = BargeLength;
  // The road's edge comes in no farther than this beyond the right edge
  LandingRoadEnterGap = 8.0;

type
  // lgIdle - the fight on, or no fight; lgFlying - the burst, the flight
  // at its pace; lgSlowing - the world slowing to a standstill; lgStanding
  // - at rest, the barge against the left edge and the road
  TLandingStage = (lgIdle, lgFlying, lgSlowing, lgStanding);

  TLandingCue = record
    // The flight slows down from now on
    SlowsDown: Boolean;
    // The road's edge comes in at RoadLeft: from here it rides the world
    // to its stop
    RoadIn: Boolean;
    RoadLeft: Double;
    // The world stands
    Stands: Boolean;
    // The titles take over
    HandsOver: Boolean;
  end;

  TLanding = class
  private
    FStage: TLandingStage;
    FTicks: Integer;
    FRoadIn: Boolean;
    FHandedOver: Boolean;
  public
    constructor Create;
    // The hull's last life is gone; nothing once begun, till a clear
    procedure Start;
    // A death before the end, a new level: none
    procedure Clear;
    // ATravelLeft - what the slowing world has still to run, units; AStands
    // - the world stands this tick
    function Tick(ATravelLeft: Double; AStands: Boolean): TLandingCue;
    // From the burst on: nothing wounds him
    function Running: Boolean;
    property Stage: TLandingStage read FStage;
    property HandedOver: Boolean read FHandedOver;
  end;

implementation

uses
  Game.Space;

constructor TLanding.Create;
begin
  inherited Create;
  Clear;
end;

procedure TLanding.Start;
begin
  if FStage <> lgIdle then
    Exit;
  FStage := lgFlying;
  FTicks := 0;
end;

procedure TLanding.Clear;
begin
  FStage := lgIdle;
  FTicks := 0;
  FRoadIn := False;
  FHandedOver := False;
end;

function TLanding.Tick(ATravelLeft: Double; AStands: Boolean): TLandingCue;
begin
  Result := Default(TLandingCue);
  if FStage = lgIdle then
    Exit;
  Inc(FTicks);
  case FStage of
    lgFlying:
      if FTicks >= LandingSlowAfterTicks then
      begin
        Result.SlowsDown := True;
        FStage := lgSlowing;
        FTicks := 0;
      end;
    lgSlowing:
      begin
        var Comes := LandingRoadStop + ATravelLeft <=
          ScreenWidth + LandingRoadEnterGap;
        if not FRoadIn and Comes then
        begin
          FRoadIn := True;
          Result.RoadIn := True;
          Result.RoadLeft := LandingRoadStop + ATravelLeft;
        end;
        if AStands then
        begin
          Result.Stands := True;
          FStage := lgStanding;
          FTicks := 0;
        end;
      end;
    lgStanding:
      if FTicks = LandingHandOverAfterTicks then
      begin
        Result.HandsOver := True;
        FHandedOver := True;
      end;
  end;
end;

function TLanding.Running: Boolean;
begin
  Result := FStage <> lgIdle;
end;

end.
