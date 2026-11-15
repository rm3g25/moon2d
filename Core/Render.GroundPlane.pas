{
  Render.GroundPlane - draws the crater floor as a plane under the titles'
  eye (Levels.GroundPlane): the ground's tile laid from under the eye to
  the ridge's foot, a row of the window's pixels at a time.

  A row is one depth of the plane, so the tile lies across it unsheared: a
  strip of triangles (SDL_RenderGeometry), a quad for each turn of the
  tile - SDL has no sampler that wraps - all of the quad taken from one row
  of the tile's copy, filtered between its two rows of pixels. The rows of
  one copy go out together. Where a row goes to the far ground's colour, a
  plain quad of that colour lies over it, after the tile's.

  The copies are the set's (tools/chase/make_ground.py). At the eye's rest
  the floor's band and the near hills cover the plane whole, and nothing is
  drawn.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Render.GroundPlane;
{$I ..\Moon2D.inc}

interface

uses
  Sdl2.Core, Render.Sprites, Levels.FarPlane, Levels.GroundPlane;

type
  TGroundPlanePainter = class
  private type
    // Triangles being gathered: the arrays as long as they have had to
    // get, and how much of each is filled
    TMesh = record
      Vertices: TArray<TSdlVertex>;
      Indices: TArray<Integer>;
      VertexCount, IndexCount: Integer;
    end;
  private
    FRenderer: PSdlRenderer;
    FDef: TFarPlaneDef;
    // The copies of the tile, the tile itself first; none - no plane
    FLevels: TArray<PSdlTexture>;
    FTileRows: Integer;
    FTile, FFarGround: TMesh;
    // One pixel of the window, in units
    function PixelDeep: Single;
    // A quad over APlace, all of it from the row ATileRow of a picture, a
    // share of the picture's height
    procedure AddQuad(var AMesh: TMesh; const APlace: TSdlFRect; ATileRow: Single;
      AColor: TSdlColor);
    // AStrip - the row's place across the whole screen
    procedure AddTileRow(const ARow: TPlaneRow; const AStrip: TSdlFRect);
    procedure AddFarRow(const ARow: TPlaneRow; const AStrip: TSdlFRect);
    // nil - plain triangles of their corners' colour
    procedure Flush(var AMesh: TMesh; ATexture: PSdlTexture);
  public
    // Resolves the tile's copies now, so one the set lacks raises at level
    // load. ACache - the level's object art, with the far plane's set
    // attached; it must outlive the painter. A far plane without a plane
    // draws none
    constructor Create(ARenderer: PSdlRenderer; ACache: TSpriteCache;
      const ADef: TFarPlaneDef);
    // AEye - the titles' eye; AEyeAlong - where it stands along the city's
    // strip
    procedure Draw(const AEye: TFarPlaneEye; AEyeAlong: Double);
  end;

implementation

uses
  System.SysUtils, System.Math;

const
  // The copies make_ground.py puts into the set: the tile's id and the level
  TileCopySprite = '%s-%d';
  LeastBuffer = 256;
  SolidAlpha = 255;
  NoLevel = -1;
  Unshaded: TSdlColor = (R: 255; G: 255; B: 255; A: SolidAlpha);

constructor TGroundPlanePainter.Create(ARenderer: PSdlRenderer; ACache: TSpriteCache;
  const ADef: TFarPlaneDef);
var
  Width: Integer;
begin
  inherited Create;
  FRenderer := ARenderer;
  FDef := ADef;
  if not ADef.Plane.Present then
    Exit;
  SetLength(FLevels, ADef.Plane.Levels);
  for var i := 0 to High(FLevels) do
  begin
    FLevels[i] := ACache.Get(ADef.SpriteName(Format(TileCopySprite, [ADef.Plane.Tile, i])));
    SDL_SetTextureScaleMode(FLevels[i], SdlScaleModeLinear);
  end;
  SDL_QueryTexture(FLevels[0], nil, nil, @Width, @FTileRows);
end;

function TGroundPlanePainter.PixelDeep: Single;
var
  ScaleX, ScaleY: Single;
begin
  SDL_RenderGetScale(FRenderer, @ScaleX, @ScaleY);
  Result := 1;
  if ScaleY > 0 then
    Result := 1 / ScaleY;
end;

procedure TGroundPlanePainter.AddQuad(var AMesh: TMesh; const APlace: TSdlFRect;
  ATileRow: Single; AColor: TSdlColor);
const
  // Top left, top right, bottom right, bottom left
  CornerX: array [0..3] of Integer = (0, 1, 1, 0);
  CornerY: array [0..3] of Integer = (0, 0, 1, 1);
  Triangles: array [0..5] of Integer = (0, 1, 2, 0, 2, 3);
begin
  if AMesh.VertexCount + 4 > Length(AMesh.Vertices) then
    SetLength(AMesh.Vertices, Max(LeastBuffer, 2 * Length(AMesh.Vertices)));
  if AMesh.IndexCount + 6 > Length(AMesh.Indices) then
    SetLength(AMesh.Indices, Max(LeastBuffer, 2 * Length(AMesh.Indices)));
  var First := AMesh.VertexCount;
  for var i := 0 to 3 do
  begin
    var Vertex: TSdlVertex;
    Vertex.Position.X := APlace.X + APlace.W * CornerX[i];
    Vertex.Position.Y := APlace.Y + APlace.H * CornerY[i];
    Vertex.TexCoord.X := CornerX[i];
    Vertex.TexCoord.Y := ATileRow;
    Vertex.Color := AColor;
    AMesh.Vertices[First + i] := Vertex;
  end;
  for var i := 0 to High(Triangles) do
    AMesh.Indices[AMesh.IndexCount + i] := First + Triangles[i];
  Inc(AMesh.VertexCount, 4);
  Inc(AMesh.IndexCount, Length(Triangles));
end;

// One turn of the tile after another from the screen's left edge on
procedure TGroundPlanePainter.AddTileRow(const ARow: TPlaneRow;
  const AStrip: TSdlFRect);
begin
  var Turn: Double := FDef.Plane.TileUnits * ARow.Scale;
  var Left: Double := ARow.FirstTurn;
  var Place := AStrip;
  Place.W := Turn;
  while Left < AStrip.X + AStrip.W do
  begin
    Place.X := Left;
    AddQuad(FTile, Place, ARow.TileRow, Unshaded);
    Left := Left + Turn;
  end;
end;

procedure TGroundPlanePainter.AddFarRow(const ARow: TPlaneRow; const AStrip: TSdlFRect);
begin
  var Shaded := FDef.Plane.FarColor;
  var Color: TSdlColor;
  Color.R := Shaded.R;
  Color.G := Shaded.G;
  Color.B := Shaded.B;
  Color.A := Round(SolidAlpha * ARow.FarShare);
  AddQuad(FFarGround, AStrip, 0, Color);
end;

procedure TGroundPlanePainter.Flush(var AMesh: TMesh; ATexture: PSdlTexture);
begin
  if AMesh.IndexCount > 0 then
  begin
    SDL_SetRenderDrawBlendMode(FRenderer, SdlBlendModeBlend);
    SDL_RenderGeometry(FRenderer, ATexture, @AMesh.Vertices[0], AMesh.VertexCount,
      @AMesh.Indices[0], AMesh.IndexCount);
  end;
  AMesh.VertexCount := 0;
  AMesh.IndexCount := 0;
end;

// Down the screen the rows come nearer, and their copies only less
// squeezed: the rows of one copy lie together
procedure TGroundPlanePainter.Draw(const AEye: TFarPlaneEye; AEyeAlong: Double);
begin
  if (Length(FLevels) = 0) or AEye.AtRest then
    Exit;
  var Pixel := PixelDeep;
  var Horizon: Double := FDef.Camera.Horizon;
  var Last: Integer := Ceil(FDef.ScreenHeight / Pixel) - 1;
  var Gathered := NoLevel;
  var Strip: TSdlFRect;
  Strip.X := 0;
  Strip.W := FDef.ScreenWidth;
  Strip.H := Pixel;
  for var i := Ceil(Horizon / Pixel) to Last do
  begin
    var Row := PlaneRow(FDef, AEye, AEyeAlong, (i + 0.5) * Pixel - Horizon, Pixel, FTileRows);
    if not Row.Ground then
      Continue;
    if (Gathered <> NoLevel) and (Row.Level <> Gathered) then
      Flush(FTile, FLevels[Gathered]);
    Gathered := Row.Level;
    Strip.Y := i * Pixel;
    if Row.FarShare < 1 then
      AddTileRow(Row, Strip);
    if Row.FarShare > 0 then
      AddFarRow(Row, Strip);
  end;
  if Gathered <> NoLevel then
    Flush(FTile, FLevels[Gathered]);
  Flush(FFarGround, nil);
end;

end.
