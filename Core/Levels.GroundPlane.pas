{
  Levels.GroundPlane - the crater floor as a plane under the titles' eye
  (docs/mechanics/finale-flight.md, "The ground for a lifted eye"): where a
  row of the screen under the horizon lies on the floor, and what of the
  ground's tile it is drawn from. The arithmetic is the stand's
  (tools/chase: drawPlane), number for number.

  The tile is the ground seen from straight above, its top edge the far
  one, laid on the plane the city's feet stand on, a turn every TileUnits
  both ways: along the city's strip from the strip's own start, into the
  depth from the eye's rest. A row of the screen is one depth of that
  plane, the nearer the lower. A far row covers many rows of the tile:
  taken from the tile itself it would shimmer in motion, so it is taken
  from a copy squeezed that many times (the "plane" section of the layout,
  TGroundPlaneDef); past the deepest copy, and far off the eye, it goes to
  the tile's mean colour - that far the same dunes come round again and
  again across the frame, a grid. The ridge is the edge of the world: no
  ground lies beyond its foot.

  Deliberately not here: the drawing (Render.GroundPlane), and the band of
  the floor that lies over the plane and melts (Levels.FarPlane). No SDL.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Levels.GroundPlane;
{$I ..\Moon2D.inc}

interface

uses
  Levels.FarPlane;

type
  // A row of the screen on the plane
  TPlaneRow = record
    // False - above the horizon or beyond the ridge's foot: no ground
    Ground: Boolean;
    // How far off the eye the row lies, units
    Depth: Double;
    // The copy of the tile it is taken from, 0 the tile itself
    Level: Integer;
    // The row of that copy under the middle of the screen's row, a share
    // of the copy's height from its top
    TileRow: Double;
    // Units of the screen to a unit of the plane, across
    Scale: Double;
    // Where the turn of the tile that covers the screen's left edge
    // begins, units of the screen: at 0 or left of it
    FirstTurn: Double;
    // How far it has gone to the far ground's colour, 0..1
    FarShare: Double;
  end;

// The row of the screen whose middle lies ADown units under the horizon,
// APixel units deep. AEyeAlong - where the eye stands along the city's
// strip; ATileRows - how many rows of pixels the tile has
function PlaneRow(const ADef: TFarPlaneDef; const AEye: TFarPlaneEye;
  AEyeAlong, ADown, APixel: Double; ATileRows: Integer): TPlaneRow;

implementation

uses
  System.Math;

// The whole turns in ATurns are dropped: what is left of the last one
function TurnShare(ATurns: Double): Double;
begin
  Result := ATurns - Floor(ATurns);
end;

// Where the world ends, units off the eye: at the ridge's foot. A ridge
// with no depth of its own ends nothing
function WorldEnd(const ADef: TFarPlaneDef; const AEye: TFarPlaneEye): Double;
begin
  var RidgeNearness: Double := ADef.MotionNearness(fmRidge);
  if RidgeNearness <= 0 then
    Exit(MaxDouble);
  Result := ADef.Camera.Focal / RidgeNearness - AEye.Push;
end;

function PlaneRow(const ADef: TFarPlaneDef; const AEye: TFarPlaneEye;
  AEyeAlong, ADown, APixel: Double; ATileRows: Integer): TPlaneRow;
begin
  Result := Default(TPlaneRow);
  if ADown <= 0 then
    Exit;
  var Focal: Double := ADef.Camera.Focal;
  var TileUnits: Double := ADef.Plane.TileUnits;
  var Height: Double := ADef.EyeHeight(AEye);
  Result.Depth := Height * Focal / ADown;
  Result.Ground := Result.Depth <= WorldEnd(ADef, AEye);
  if not Result.Ground then
    Exit;

  // How many rows of the tile this row of the screen covers
  var RowDeep: Double := Result.Depth * Result.Depth / (Height * Focal) * APixel *
    ATileRows / TileUnits;
  var Squeeze: Double := 0;
  if RowDeep > 1 then
    Squeeze := Log2(RowDeep);
  var Deepest: Integer := ADef.Plane.Levels - 1;
  // The stand rounds a half up
  Result.Level := Floor(Squeeze + 0.5);
  if Result.Level > Deepest then
    Result.Level := Deepest;

  Result.Scale := Focal / Result.Depth;
  var Left: Double := AEyeAlong - ADef.ScreenWidth / 2 * Result.Depth / Focal;
  Result.FirstTurn := -TurnShare(Left / TileUnits) * TileUnits * Result.Scale;
  Result.TileRow := 1 - TurnShare((AEye.Push + Result.Depth) / TileUnits);

  var TooSqueezed: Double := SmoothShare(Squeeze, Deepest - 1, Deepest + 1);
  Result.FarShare := SmoothShare(Result.Depth, ADef.Plane.FarFrom, ADef.Plane.FarTill);
  if TooSqueezed > Result.FarShare then
    Result.FarShare := TooSqueezed;
end;

end.
