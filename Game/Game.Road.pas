{
  Game.Road - the road of the chase running out. The orb launcher taken,
  the world moves off again and the made road of TeK goes no farther: the
  tiles beyond a break line fall away into the crater one after another,
  the farthest first, and what is left - the pier - rides the belt left
  with the rest of the world. Later the pier itself falls, tile by tile
  from its end, once the barge has waited long enough for the hero or has
  him aboard (Game.Barge tells when).

  Only the tiles' places: which stand, which fall and where a falling one
  is this tick. The floor under the hero is a pad the game trims to the
  pier (Pads.World), the grid's row of the road erased (Levels.Defs); the
  pictures are the painter's below, the sounds and the shake the game's.
  The end itself does not touch SDL.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.Road;
{$I ..\Moon2D.inc}

interface

uses
  Sdl2.Core, Render.Sprites;

const
  // The tiles of the road as it runs out: a screen of them, and the one
  // the right edge cuts
  RoadTiles = 17;
  // Beyond this x of the screen the road breaks away at once: two cells
  // past where the orb launcher lies
  RoadBreakX = 320.0;
  // The first tiles fall this many ticks apart, the farthest first
  BreakGapTicks = 3;
  // The pier falls this many ticks apart once it goes
  CollapseGapTicks = 5;
  // A falling tile: pushed down to start, pulled down a little more every
  // tick, turning as it goes; gone this far under the road
  FallStart = 0.6;
  FallPull = 0.35;
  FallSpin = 2.0;
  FallGone = 3 * TileSize;

type
  TRoadTile = record
    // Its left edge on the screen; it rides the belt, standing or falling
    Left: Double;
    Falling: Boolean;
    // Fallen out of sight: nothing left to draw
    Gone: Boolean;
    // Units under the road since it broke off, and degrees clockwise
    Drop: Double;
    Tilt: Double;
  end;

  TRoadCue = record
    // A tile broke off this tick
    Broke: Boolean;
  end;

  TRoadEnd = class
  private
    FTiles: TArray<TRoadTile>;
    FLastTiles: TArray<TRoadTile>;
    FSpeeds: TArray<Double>;
    FRunning: Boolean;
    // The run of falls under way: tiles still to fall, the gap between two
    // and the ticks till the next; a run of 0 is none
    FToFall: Integer;
    FGap: Integer;
    FDue: Integer;
    FCollapsing: Boolean;
    function LastStanding: Integer;
    procedure BreakNext;
    procedure TickFall(AIndex: Integer; AWay: Double);
  public
    // The road runs out: its tiles stand at APhase - TileSize, and a tile
    // apart from there; those whose left edge is at ABreakX or beyond fall
    // away at once, the farthest first
    procedure Start(APhase: Double; ABreakX: Double = RoadBreakX);
    // A death, a new level: a whole road again, of the grid
    procedure Clear;
    // The pier falls from now on, from its end; nothing once it falls
    procedure Collapse;
    // The belt went AWay this tick, below 0 to the left: every tile rides it
    function Tick(AWay: Double): TRoadCue;
    // A tile is standing: not fallen, not falling
    function Standing(AIndex: Integer): Boolean;
    // Any tile standing
    function PierStands: Boolean;
    // The pier: from the first tile's left edge to the last standing one's
    // right edge; both 0 with none standing
    function PierLeft: Double;
    function PierRight: Double;
    // The tile AAlpha of the way from the last tick to this one
    function TileAt(AIndex: Integer; AAlpha: Single): TRoadTile;
    property Running: Boolean read FRunning;
    property Collapsing: Boolean read FCollapsing;
  end;

  // The tiles of the road that runs out, drawn in the road tile's picture:
  // the standing ones on the road's line, the falling ones under it,
  // turning. Owns nothing.
  TRoadPainter = class
  private
    FTexture: PSdlTexture;
  public
    constructor Create(ATexture: PSdlTexture);
    // ATop - the road's line, the top of its tiles
    procedure Draw(const ASprites: TSpriteRenderer; const ARoad: TRoadEnd;
      ATop: Double; AAlpha: Single);
  end;

implementation

uses
  System.Math;

function Lerp(AFrom, ATo: Double; AShare: Single): Double;
begin
  Result := AFrom + (ATo - AFrom) * AShare;
end;

// ---------------------------------------------------------------------------
// TRoadEnd
// ---------------------------------------------------------------------------

procedure TRoadEnd.Start(APhase: Double; ABreakX: Double);
begin
  Clear;
  FRunning := True;
  SetLength(FTiles, RoadTiles);
  SetLength(FSpeeds, RoadTiles);
  FToFall := 0;
  for var i := 0 to RoadTiles - 1 do
  begin
    FTiles[i] := Default(TRoadTile);
    FTiles[i].Left := APhase - TileSize + TileSize * i;
    FSpeeds[i] := 0;
    if FTiles[i].Left >= ABreakX then
      Inc(FToFall);
  end;
  FLastTiles := Copy(FTiles);
  FGap := BreakGapTicks;
  // The first falls on the first tick
  FDue := 0;
end;

procedure TRoadEnd.Clear;
begin
  FRunning := False;
  FCollapsing := False;
  FTiles := nil;
  FLastTiles := nil;
  FSpeeds := nil;
  FToFall := 0;
  FGap := 0;
  FDue := 0;
end;

procedure TRoadEnd.Collapse;
begin
  if not FRunning or FCollapsing then
    Exit;
  FCollapsing := True;
  var StillUp := 0;
  for var i := 0 to High(FTiles) do
    if Standing(i) then
      Inc(StillUp);
  // The first falls at once, unless a run of falls is still under way
  if FToFall = 0 then
    FDue := 0
  else
    FDue := Min(FDue, CollapseGapTicks);
  FToFall := StillUp;
  FGap := CollapseGapTicks;
end;

function TRoadEnd.LastStanding: Integer;
begin
  for var i := High(FTiles) downto 0 do
    if Standing(i) then
      Exit(i);
  Result := -1;
end;

procedure TRoadEnd.BreakNext;
begin
  var Last := LastStanding;
  if Last < 0 then
  begin
    FToFall := 0;
    Exit;
  end;
  FTiles[Last].Falling := True;
  FSpeeds[Last] := FallStart;
  Dec(FToFall);
end;

procedure TRoadEnd.TickFall(AIndex: Integer; AWay: Double);
begin
  var Tile := FTiles[AIndex];
  Tile.Left := Tile.Left + AWay;
  if Tile.Falling and not Tile.Gone then
  begin
    Tile.Drop := Tile.Drop + FSpeeds[AIndex];
    FSpeeds[AIndex] := FSpeeds[AIndex] + FallPull;
    // Every other tile turns the other way
    if Odd(AIndex) then
      Tile.Tilt := Tile.Tilt - FallSpin
    else
      Tile.Tilt := Tile.Tilt + FallSpin;
    Tile.Gone := Tile.Drop >= FallGone;
  end;
  FTiles[AIndex] := Tile;
end;

function TRoadEnd.Tick(AWay: Double): TRoadCue;
begin
  Result := Default(TRoadCue);
  if not FRunning then
    Exit;
  FLastTiles := Copy(FTiles);
  if FToFall > 0 then
  begin
    if FDue <= 0 then
    begin
      Result.Broke := LastStanding >= 0;
      BreakNext;
      FDue := FGap;
    end;
    Dec(FDue);
  end;
  for var i := 0 to High(FTiles) do
    TickFall(i, AWay);
end;

function TRoadEnd.Standing(AIndex: Integer): Boolean;
begin
  Result := FRunning and (AIndex >= 0) and (AIndex <= High(FTiles)) and
    not FTiles[AIndex].Falling;
end;

function TRoadEnd.PierStands: Boolean;
begin
  Result := LastStanding >= 0;
end;

function TRoadEnd.PierLeft: Double;
begin
  if not PierStands then
    Exit(0);
  Result := FTiles[0].Left;
end;

function TRoadEnd.PierRight: Double;
begin
  var Last := LastStanding;
  if Last < 0 then
    Exit(0);
  Result := FTiles[Last].Left + TileSize;
end;

function TRoadEnd.TileAt(AIndex: Integer; AAlpha: Single): TRoadTile;
begin
  Result := FTiles[AIndex];
  var Last := FLastTiles[AIndex];
  Result.Left := Lerp(Last.Left, Result.Left, AAlpha);
  Result.Drop := Lerp(Last.Drop, Result.Drop, AAlpha);
  Result.Tilt := Lerp(Last.Tilt, Result.Tilt, AAlpha);
end;

// ---------------------------------------------------------------------------
// TRoadPainter
// ---------------------------------------------------------------------------

constructor TRoadPainter.Create(ATexture: PSdlTexture);
begin
  inherited Create;
  FTexture := ATexture;
end;

procedure TRoadPainter.Draw(const ASprites: TSpriteRenderer;
  const ARoad: TRoadEnd; ATop: Double; AAlpha: Single);
var
  Dest: TSdlFRect;
begin
  if not ARoad.Running then
    Exit;
  Dest.W := TileSize;
  Dest.H := TileSize;
  for var i := 0 to RoadTiles - 1 do
  begin
    var Tile := ARoad.TileAt(i, AAlpha);
    if Tile.Gone then
      Continue;
    Dest.X := Tile.Left;
    Dest.Y := ATop + Tile.Drop;
    ASprites.DrawRectF(FTexture, Dest, Tile.Tilt);
  end;
end;

end.
