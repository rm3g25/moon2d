{
  Game.Road - the road of the chase running out. The orb launcher taken,
  the chase goes on, and the made road of TeK has an end now: a cliff
  over the crater that comes in from beyond the right edge with the rest
  of the world and rides on left past the hero - the pier. The barge
  waits a hop past it (Game.Barge).

  Only the pier's place: where its first tile's left edge is and where it
  ends. The floor under the hero is a pad the game carries with it
  (Pads.World), the grid's row of the road erased (Levels.Defs); the
  pictures are the painter's below. The end itself does not touch SDL.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.Road;
{$I ..\Moon2D.inc}

interface

uses
  Sdl2.Core, Render.Sprites;

const
  // The tiles of the road as it runs out: a screen of them and the one the
  // right edge cuts - so its end comes in from beyond the right edge
  RoadTiles = 17;

type
  TRoadEnd = class
  private
    FRunning: Boolean;
    FLeft, FLastLeft: Double;
  public
    // The road runs out: its first tile stands at APhase - TileSize, the
    // rest a tile apart from there
    procedure Start(APhase: Double);
    // A death, a new level: a whole road again, of the grid
    procedure Clear;
    // The belt went AWay this tick, below 0 to the left: the pier rides it
    procedure Tick(AWay: Double);
    // Any of the pier still on the screen
    function PierStands: Boolean;
    // The pier: from the first tile's left edge to the last one's right
    // edge, the cliff; both 0 when it is not running
    function PierLeft: Double;
    function PierRight: Double;
    // The first tile's left edge AAlpha of the way from the last tick to
    // this one
    function LeftAt(AAlpha: Single): Double;
    property Running: Boolean read FRunning;
  end;

  // The tiles of the pier, drawn in the road tile's picture on the road's
  // line. Owns nothing.
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
  Game.Space;

// ---------------------------------------------------------------------------
// TRoadEnd
// ---------------------------------------------------------------------------

procedure TRoadEnd.Start(APhase: Double);
begin
  FRunning := True;
  FLeft := APhase - TileSize;
  FLastLeft := FLeft;
end;

procedure TRoadEnd.Clear;
begin
  FRunning := False;
  FLeft := 0;
  FLastLeft := 0;
end;

procedure TRoadEnd.Tick(AWay: Double);
begin
  if not FRunning then
    Exit;
  FLastLeft := FLeft;
  FLeft := FLeft + AWay;
end;

function TRoadEnd.PierStands: Boolean;
begin
  Result := FRunning and (PierRight > 0);
end;

function TRoadEnd.PierLeft: Double;
begin
  if not FRunning then
    Exit(0);
  Result := FLeft;
end;

function TRoadEnd.PierRight: Double;
begin
  if not FRunning then
    Exit(0);
  Result := FLeft + TileSize * RoadTiles;
end;

function TRoadEnd.LeftAt(AAlpha: Single): Double;
begin
  Result := FLastLeft + (FLeft - FLastLeft) * AAlpha;
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
  Dest.Y := ATop;
  var Left := ARoad.LeftAt(AAlpha);
  for var i := 0 to RoadTiles - 1 do
  begin
    Dest.X := Left + TileSize * i;
    var OffScreen := (Dest.X + TileSize <= 0) or (Dest.X >= ScreenWidth);
    if not OffScreen then
      ASprites.DrawRectF(FTexture, Dest, 0);
  end;
end;

end.
