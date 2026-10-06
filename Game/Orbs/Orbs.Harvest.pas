{
  Orbs.Harvest - where the orbs of an aura come from: the matter around
  the hero. Matter is the solid cells of his screen and the bodies of the
  pads standing on it; an orb shows through on a face of it that looks
  into the open.

  One function and no state: the matter of a screen, the hero's center
  and a count in, that many spots out. The dice are the caller's, so the
  same matter and the same dice give the same spots - it can be tried on
  a bench with no game behind it.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Orbs.Harvest;
{$I ..\..\Moon2D.inc}

interface

uses
  Sdl2.Core, Render.Brush, Game.Space;

type
  // The solid cells of one screen, by row and by column
  TSolidCells = array [0..ScreenRows - 1, 0..ScreenCols - 1] of Boolean;

  // The matter of one screen
  TMatter = record
    Cells: TSolidCells;
    // The bodies of the pads standing in front, in screen units
    Bodies: TArray<TSdlFRect>;
  end;

  // A point on a face of matter. The normal looks into the open, a unit
  // along one axis; a spot in thin air has none.
  TFaceSpot = record
    X, Y: Single;
    NormalX, NormalY: Single;
    // Where the spot lies from the hero's center: units, and radians
    // from the X axis
    Away: Single;
    Turn: Single;
  end;

// ACount spots on the open faces of AMatter, those nearer ACenter first,
// give or take. What the matter is short of stands in thin air around
// the center, after the rest.
function HarvestSpots(const AMatter: TMatter; ACenter: TSdlFPoint;
  ACount: Integer; var ADice: TXorShift): TArray<TFaceSpot>;

implementation

uses
  System.Math, System.Generics.Collections, System.Generics.Defaults,
  Render.Sprites;

const
  // A face gives a spot to every stretch of this length
  StretchLength = TileSize / 4;
  // A spot stands off the middle of its stretch by up to half of this:
  // the orbs of a floor do not show through in a rank
  SpotScatter = 4;
  // The open side of a stretch is tried this far off its middle
  ProbeReach = 1;
  // A spot is sorted as up to this share farther than it is: the nearer
  // come first, but not by the ruler
  NearnessScatter = 0.45;
  // A spot in thin air stands this far from the center
  AirNearest = 50;
  AirFarthest = 90;

  // The normal of a face: Y grows downward
  LooksUp = -1;
  LooksDown = 1;
  LooksLeft = -1;
  LooksRight = 1;

type
  // One side of a box of matter: Span units from Start along Along; the
  // normal looks out of the box
  TFace = record
    StartX, StartY: Single;
    AlongX, AlongY: Single;
    Span: Single;
    NormalX, NormalY: Single;
  end;

  TRankedSpot = record
    Spot: TFaceSpot;
    Farness: Single; // what the spots are sorted by
  end;

function NearerFirst(const ALeft, ARight: TRankedSpot): Integer;
begin
  Result := CompareValue(ALeft.Farness, ARight.Farness);
end;

function OnScreen(AX, AY: Single): Boolean;
begin
  Result := (AX >= 0) and (AX < ScreenWidth) and (AY >= 0) and
    (AY < ScreenHeight);
end;

function BodyHolds(const ABody: TSdlFRect; AX, AY: Single): Boolean;
begin
  Result := (AX >= ABody.X) and (AX < ABody.X + ABody.W) and
    (AY >= ABody.Y) and (AY < ABody.Y + ABody.H);
end;

// The point is in the open: on the screen and in no matter
function OpenAt(const AMatter: TMatter; AX, AY: Single): Boolean;
begin
  if not OnScreen(AX, AY) then
    Exit(False);
  if AMatter.Cells[Trunc(AY / TileSize), Trunc(AX / TileSize)] then
    Exit(False);
  for var Body in AMatter.Bodies do
    if BodyHolds(Body, AX, AY) then
      Exit(False);
  Result := True;
end;

function CellBox(ACol, ARow: Integer): TSdlFRect;
begin
  Result.X := ACol * TileSize;
  Result.Y := ARow * TileSize;
  Result.W := TileSize;
  Result.H := TileSize;
end;

// A side that lies - a floor, a ceiling: it runs across from the point
function LyingFace(AX, AY, ASpan, ANormalY: Single): TFace;
begin
  Result := Default(TFace);
  Result.StartX := AX;
  Result.StartY := AY;
  Result.AlongX := 1;
  Result.Span := ASpan;
  Result.NormalY := ANormalY;
end;

// A side that stands - a wall: it runs down from the point
function StandingFace(AX, AY, ASpan, ANormalX: Single): TFace;
begin
  Result := Default(TFace);
  Result.StartX := AX;
  Result.StartY := AY;
  Result.AlongY := 1;
  Result.Span := ASpan;
  Result.NormalX := ANormalX;
end;

// The point AAlong units along the face and AOut units out of it
function PointOn(const AFace: TFace; AAlong, AOut: Single): TSdlFPoint;
begin
  Result.X := AFace.StartX + AFace.AlongX * AAlong + AFace.NormalX * AOut;
  Result.Y := AFace.StartY + AFace.AlongY * AAlong + AFace.NormalY * AOut;
end;

function HarvestSpots(const AMatter: TMatter; ACenter: TSdlFPoint;
  ACount: Integer; var ADice: TXorShift): TArray<TFaceSpot>;
var
  Found: TList<TRankedSpot>;

  procedure Keep(APlace: TSdlFPoint; ANormalX, ANormalY: Single);
  var
    Ranked: TRankedSpot;
  begin
    Ranked.Spot.X := APlace.X;
    Ranked.Spot.Y := APlace.Y;
    Ranked.Spot.NormalX := ANormalX;
    Ranked.Spot.NormalY := ANormalY;
    Ranked.Spot.Away := Hypot(APlace.X - ACenter.X, APlace.Y - ACenter.Y);
    Ranked.Spot.Turn := ArcTan2(APlace.Y - ACenter.Y, APlace.X - ACenter.X);
    Ranked.Farness := Ranked.Spot.Away *
      (1 + ADice.NextUnit * NearnessScatter);
    Found.Add(Ranked);
  end;

  // A spot from every stretch of the face that looks into the open
  procedure Glean(const AFace: TFace);
  begin
    for var i := 0 to Trunc(AFace.Span / StretchLength) - 1 do
    begin
      var Middle: Single := (i + 0.5) * StretchLength;
      var Probe := PointOn(AFace, Middle, ProbeReach);
      if not OpenAt(AMatter, Probe.X, Probe.Y) then
        Continue;
      var Along: Single := Middle + (ADice.NextUnit - 0.5) * SpotScatter;
      Keep(PointOn(AFace, Along, 0), AFace.NormalX, AFace.NormalY);
    end;
  end;

  // The four sides of a box of matter, a cell or a body
  procedure GleanBox(const ABox: TSdlFRect);
  begin
    Glean(LyingFace(ABox.X, ABox.Y, ABox.W, LooksUp));
    Glean(LyingFace(ABox.X, ABox.Y + ABox.H, ABox.W, LooksDown));
    Glean(StandingFace(ABox.X, ABox.Y, ABox.H, LooksLeft));
    Glean(StandingFace(ABox.X + ABox.W, ABox.Y, ABox.H, LooksRight));
  end;

  procedure KeepAirSpot;
  var
    Place: TSdlFPoint;
  begin
    var Turn: Single := ADice.NextUnit * 2 * Pi;
    var Away: Single := AirNearest +
      ADice.NextUnit * (AirFarthest - AirNearest);
    Place.X := ACenter.X + Cos(Turn) * Away;
    Place.Y := ACenter.Y + Sin(Turn) * Away;
    Keep(Place, 0, 0);
  end;

begin
  Found := TList<TRankedSpot>.Create;
  try
    for var Row := 0 to ScreenRows - 1 do
      for var Col := 0 to ScreenCols - 1 do
      begin
        if not AMatter.Cells[Row, Col] then
          Continue;
        GleanBox(CellBox(Col, Row));
      end;
    for var Body in AMatter.Bodies do
      GleanBox(Body);
    Found.Sort(TComparer<TRankedSpot>.Construct(NearerFirst));

    // After the sort: thin air is the last to be drawn on
    while Found.Count < ACount do
      KeepAirSpot;

    SetLength(Result, ACount);
    for var i := 0 to ACount - 1 do
      Result[i] := Found[i].Spot;
  finally
    Found.Free;
  end;
end;

end.
