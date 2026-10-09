{
  Orbs.Harvest - where orbs come from: the matter around the hero. Matter
  is the solid cells of his screen and the bodies of the pads standing on
  it; an orb shows through on a face of it that looks into the open.

  Two functions and no state: the matter of a screen, the hero's center
  and a count in, spots out. HarvestSpots gives that many spots, the
  nearer first. HarvestAround gives them in waves, each wave from all
  sides of the hero, the first off the nearest faces and the last off the
  farthest. The dice are the caller's, so the same matter and the same
  dice give the same spots - it can be tried on a bench with no game
  behind it.

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

// APerWave spots for each of AWaves waves, from all sides of ACenter:
// the first wave off the nearest faces, the last off the farthest.
// Within a wave the spots go by their turn about the center.
function HarvestAround(const AMatter: TMatter; ACenter: TSdlFPoint;
  APerWave, AWaves: Integer; var ADice: TXorShift): TArray<TArray<TFaceSpot>>;

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

  // HarvestAround sorts a spot as up to this share farther than it is,
  // and puts a spot of thin air this far from the center
  AroundScatter = 0.3;
  AroundAirNearest = 70;
  AroundAirFarthest = 110;
  // A spot nearer the center than this is passed by
  NearestAway = 34;
  // The turns about the center are cut into this many equal sectors
  SectorCount = 12;
  NoLimit = MaxInt;

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

  // The spots of the faces, the nearer first, and which of them a wave
  // has taken
  TStock = record
    Spots: TArray<TRankedSpot>;
    Taken: TArray<Boolean>;
  end;

function NearerFirst(const ALeft, ARight: TRankedSpot): Integer;
begin
  Result := CompareValue(ALeft.Farness, ARight.Farness);
end;

function ByTurn(const ALeft, ARight: TFaceSpot): Integer;
begin
  Result := CompareValue(ALeft.Turn, ARight.Turn);
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

// The spot at APlace, with where it lies from ACenter
function SpotAt(ACenter, APlace: TSdlFPoint;
  ANormalX, ANormalY: Single): TFaceSpot;
begin
  Result.X := APlace.X;
  Result.Y := APlace.Y;
  Result.NormalX := ANormalX;
  Result.NormalY := ANormalY;
  Result.Away := Hypot(APlace.X - ACenter.X, APlace.Y - ACenter.Y);
  Result.Turn := ArcTan2(APlace.Y - ACenter.Y, APlace.X - ACenter.X);
end;

// The spot, sorted as up to AScatter of its distance farther than it is
function RankSpot(const ASpot: TFaceSpot; AScatter: Double;
  var ADice: TXorShift): TRankedSpot;
begin
  Result.Spot := ASpot;
  Result.Farness := ASpot.Away * (1 + ADice.NextUnit * AScatter);
end;

// A spot in thin air, ANearest to AFarthest units from ACenter, in any
// direction
function AirSpot(ACenter: TSdlFPoint; ANearest, AFarthest: Integer;
  var ADice: TXorShift): TFaceSpot;
var
  Place: TSdlFPoint;
begin
  var Turn: Single := ADice.NextUnit * 2 * Pi;
  var Away: Single := ANearest + ADice.NextUnit * (AFarthest - ANearest);
  Place.X := ACenter.X + Cos(Turn) * Away;
  Place.Y := ACenter.Y + Sin(Turn) * Away;
  Result := SpotAt(ACenter, Place, 0, 0);
end;

// A spot from every stretch of every open face of AMatter, a cell or a
// body, ranked by AScatter; not sorted
function GleanFaces(const AMatter: TMatter; ACenter: TSdlFPoint;
  AScatter: Double; var ADice: TXorShift): TArray<TRankedSpot>;
var
  Found: TList<TRankedSpot>;

  procedure Keep(APlace: TSdlFPoint; ANormalX, ANormalY: Single);
  begin
    Found.Add(RankSpot(SpotAt(ACenter, APlace, ANormalX, ANormalY),
      AScatter, ADice));
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
    Result := Found.ToArray;
  finally
    Found.Free;
  end;
end;

function HarvestSpots(const AMatter: TMatter; ACenter: TSdlFPoint;
  ACount: Integer; var ADice: TXorShift): TArray<TFaceSpot>;
begin
  var Ranked: TArray<TRankedSpot> :=
    GleanFaces(AMatter, ACenter, NearnessScatter, ADice);
  TArray.Sort<TRankedSpot>(Ranked, TComparer<TRankedSpot>.Construct(NearerFirst));

  // After the sort: thin air is the last to be drawn on
  var Faces := Length(Ranked);
  SetLength(Ranked, Max(Faces, ACount));
  for var i := Faces to High(Ranked) do
    Ranked[i] := RankSpot(AirSpot(ACenter, AirNearest, AirFarthest, ADice),
      NearnessScatter, ADice);

  SetLength(Result, ACount);
  for var i := 0 to ACount - 1 do
    Result[i] := Ranked[i].Spot;
end;

// The spots of ASpots that lie farther from the center than the nearest
// a spot may be
function PastNearest(const ASpots: TArray<TRankedSpot>): TArray<TRankedSpot>;
begin
  SetLength(Result, Length(ASpots));
  var Kept := 0;
  for var Ranked in ASpots do
    if Ranked.Spot.Away >= NearestAway then
    begin
      Result[Kept] := Ranked;
      Inc(Kept);
    end;
  SetLength(Result, Kept);
end;

// The sector of a turn about the center, 0..SectorCount - 1
function SectorOf(ATurn: Single): Integer;
begin
  var Sector: Integer := Trunc((ATurn + Pi) * SectorCount / (2 * Pi));
  Result := EnsureRange(Sector, 0, SectorCount - 1);
end;

// Takes free spots, the nearer first, into APicks as their places among
// the spots of AStock, until APicks holds AMost of them; of one sector
// no more than ASectorLimit in this call
procedure TakeNearestFree(var AStock: TStock; ASectorLimit, AMost: Integer;
  APicks: TList<Integer>);
begin
  var Counts: TArray<Integer>;
  SetLength(Counts, SectorCount);
  for var i := 0 to High(AStock.Spots) do
  begin
    if APicks.Count >= AMost then
      Break;
    if AStock.Taken[i] then
      Continue;
    var Sector := SectorOf(AStock.Spots[i].Spot.Turn);
    if Counts[Sector] >= ASectorLimit then
      Continue;
    Inc(Counts[Sector]);
    AStock.Taken[i] := True;
    APicks.Add(i);
  end;
end;

// One wave: from every sector the nearest free spots, the same number of
// each; then, if the sectors gave short, the nearest free of the rest;
// then, if the matter gave short, thin air. The spots go by their turn.
function ReapWave(var AStock: TStock; ACenter: TSdlFPoint; APerWave: Integer;
  var ADice: TXorShift): TArray<TFaceSpot>;
begin
  var Picks := TList<Integer>.Create;
  try
    var PerSector := (APerWave + SectorCount - 1) div SectorCount;
    TakeNearestFree(AStock, PerSector, APerWave, Picks);
    TakeNearestFree(AStock, NoLimit, APerWave, Picks);

    SetLength(Result, APerWave);
    for var i := 0 to Picks.Count - 1 do
      Result[i] := AStock.Spots[Picks[i]].Spot;
    for var i := Picks.Count to APerWave - 1 do
      Result[i] := AirSpot(ACenter, AroundAirNearest, AroundAirFarthest, ADice);
  finally
    Picks.Free;
  end;
  TArray.Sort<TFaceSpot>(Result, TComparer<TFaceSpot>.Construct(ByTurn));
end;

function HarvestAround(const AMatter: TMatter; ACenter: TSdlFPoint;
  APerWave, AWaves: Integer; var ADice: TXorShift): TArray<TArray<TFaceSpot>>;
var
  Stock: TStock;
begin
  Stock.Spots := PastNearest(GleanFaces(AMatter, ACenter, AroundScatter, ADice));
  TArray.Sort<TRankedSpot>(Stock.Spots,
    TComparer<TRankedSpot>.Construct(NearerFirst));
  SetLength(Stock.Taken, Length(Stock.Spots));

  SetLength(Result, AWaves);
  for var i := 0 to AWaves - 1 do
    Result[i] := ReapWave(Stock, ACenter, APerWave, ADice);
end;

end.
