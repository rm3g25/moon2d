{
  Render.DomeFrames - the dome frames of a chase's city (Levels.FarPlane):
  geodesic half-ellipsoids and capsules drawn by code in a 3D of their own,
  riding with the city past the sun that stands still.

  A frame is an icosahedron cut Frequency times along each side and pushed
  out onto the sphere, a vertex at the top, cut at the equator; the equator
  itself is the ring it stands on. It is built once, then stretched to the
  frame's width and height; a capsule's frame is Levels.Capsule's. A frame
  is seen through the city's camera: the far half stands behind the
  buildings, the near half over them, so the city stands inside. Lit from
  behind, nothing of a frame faces the eye in the light: a rib is a dark
  silhouette with a thin rim on its side toward the sun, brighter the
  nearer the sun it runs. The ribs throw long shadows toward
  the eye: the sun is low, so a shadow streams down the crater floor and on
  over the near ground, cut where it passes the eye. The sun is a disc, not
  a point: past its rib a shadow softens and widens, its penumbra spread by
  the disc's angle over the way the light runs from the rib, and a rib
  thinner than the spread hides only a part of the disc - a stroke, dark at
  a dome's foot and faint toward the eye. The sun's own glare is laid over
  the ribs that cross its disc. A frame may carry red beacons on its nodes
  above a share of its height: they ride in 3D with it, the far ones
  behind the buildings, the near ones with the near ribs; each one's seed
  is its place on the frame (Levels.CityLife). The far ribs of the farm's
  dome turn their inner face to the eye: the caller lights their dark
  (TFrameRib.Dark, Levels.Farm). The stand
  (tools/chase/stand.template.html) is the reference, number for number.

  TDomeFrames is the geometry: it does not touch SDL - the ribs, the
  shadows and the beacons on the screen, in units, for a ride of the city.
  TDomeFramePainter draws them as strips of triangles, the colour and the
  alpha in the vertices: the rim is a strip of its own, and every edge
  fades out over one pixel of the window, the smoothing a canvas gives a
  line for free; a shadow is a mesh of such strips, its dark fading out
  across it and along it.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Render.DomeFrames;
{$I ..\Moon2D.inc}

interface

uses
  Sdl2.Core, Levels.FarPlane;

const
  // Points along a shadow's stroke
  ShadowSamples = 16;

type
  // A rib of a frame on the screen, in units: A to B, W thick. Its rim of
  // light lies on the side of Normal, Light bright, 0..1
  TFrameRib = record
    A, B: TSdlFPoint;
    W: Single;
    // How deep its middle stands behind its frame's centre, units; below
    // zero - in front of it
    Z: Single;
    Normal: TSdlFPoint;
    Light: Single;
    // A rib of the farm's dome
    Farm: Boolean;
    // Its colour, the rim's aside
    Dark: TSdlColor;
  end;

  // A point along a rib's shadow, in units: its middle, the half width of
  // the plateau of its dark and of its whole, and how dark the plateau is,
  // a share of a shadow's full dark
  TShadowSample = record
    At: TSdlFPoint;
    CoreHalf, OuterHalf: Single;
    Peak: Single;
  end;

  // A rib's shadow on the ground, its samples from one end of the rib's to
  // the other
  TRibShadow = record
    Samples: array [0..ShadowSamples - 1] of TShadowSample;
  end;

  // A warning light on a node of a frame, on the screen in units
  TFrameBeacon = record
    At: TSdlFPoint;
    Nearness: Single;
    Seed: Cardinal;
  end;

  // The frames as they stand on the screen at one ride of the city
  TFrameView = record
    // Behind the buildings, far to near
    Far: TArray<TFrameRib>;
    // Over the buildings, far to near
    Near: TArray<TFrameRib>;
    // Down to where they pass the eye: on the crater floor, then on over
    // the ground nearer the eye
    Shadows: TArray<TRibShadow>;
    // Behind the buildings, and with the near ribs
    FarBeacons, NearBeacons: TArray<TFrameBeacon>;
  end;

  TDomeFrames = class
  private type
    TPoint3 = TFramePoint;
    // An edge in units from its frame's centre on the base line: Y up, Z
    // into the screen; its thickness in ribs
    TEdge = record
      A, B: TPoint3;
      Thickening: Single;
    end;
    // A node of a frame that carries a beacon, in units as an edge's
    TBeaconNode = record
      At: TPoint3;
      Seed: Cardinal;
    end;
    TBeaconNodes = TArray<TBeaconNode>;
    // A view being filled: its arrays as long as they may get, and how
    // much of each is filled
    TViewFill = record
      View: TFrameView;
      FarCount, NearCount, ShadowCount: Integer;
      FarBeaconCount, NearBeaconCount: Integer;
    end;
  private
    FDef: TFarPlaneDef;
    // By frame
    FEdges: TArray<TArray<TEdge>>;
    // By frame; empty for a frame without beacons
    FBeaconNodes: TArray<TBeaconNodes>;
    // From the scene toward the sun, a unit long
    FToSun: TPoint3;
    // The sun's disc as seen from the scene: its radius over the focal length
    FSunSpread: Double;
    function FrameEdges(AFrame: Integer): TArray<TEdge>;
    function BeaconNodes(AFrame: Integer): TBeaconNodes;
    function CapsuleBeaconNodes(AFrame: Integer): TBeaconNodes;
    function DropToFloor(const AAt: TPoint3): TPoint3;
    function CutAtEye(const AFrom, ATo: TPoint3;
      out AFromShare, AToShare: Double): Boolean;
    procedure LightRim(var ARib: TFrameRib);
    procedure AddFrame(AFrame: Integer; ACityOffset: Double; var AFill: TViewFill);
    procedure AddBeacons(AFrame: Integer; ACityOffset: Double; var AFill: TViewFill);
    // AOfFarm - the frame is the farm's dome
    procedure AddEdge(const AFrame: TDomeFrame; ACityOffset: Double;
      const AEdge: TEdge; AOfFarm: Boolean; var AFill: TViewFill);
    // AThickness - the rib's own, at the frame's centre
    procedure AddShadow(const AFrame: TDomeFrame; ACityOffset: Double;
      const AFrom, ATo: TPoint3; AThickness: Single; var AFill: TViewFill);
  public
    // ADef - the level's far plane; one without frames shows none
    constructor Create(const ADef: TFarPlaneDef);
    function Present: Boolean;
    // ACityOffset - how far the city's layer has ridden left
    function View(ACityOffset: Double): TFrameView;
  end;

  TDomeFramePainter = class
  private type
    // A corner of a strip, its alpha a share of the strip's colour
    TStripCorner = record
      X, Y, Alpha: Single;
    end;
    // The four lines along a strip, across one point of it: the outer two
    // clear, the inner two at its peak
    TStripEnd = array [0..3] of TStripCorner;
    TStrip = record
      AtFrom, AtTo: TStripEnd;
    end;
  private
    FRenderer: PSdlRenderer;
    FSun: TFarPlaneSun;
    FGlow: PSdlTexture;
    FVertices: TArray<TSdlVertex>;
    FIndices: TArray<Integer>;
    FVertexCount, FIndexCount: Integer;
    // One pixel of the window, in units
    FPixel: Single;
    procedure MeasurePixel;
    function StripEnd(const AAt, ANormal: TSdlFPoint;
      AShift, ACoreHalf, AOuterHalf, APeak: Single): TStripEnd;
    function SolidStrip(const AFrom, ATo, ANormal: TSdlFPoint;
      AShift, AHalfWidth: Single): TStrip;
    function AddVertex(AX, AY: Single; AColor: TSdlColor): Integer;
    procedure AddTriangle(AFirst, ASecond, AThird: Integer);
    procedure AddStrip(const AStrip: TStrip; AColor: TSdlColor);
    procedure AddStroke(const AShadow: TRibShadow);
    procedure AddDisc(const ACentre: TSdlFPoint; ARadius: Single; AColor: TSdlColor);
    procedure Flush;
  public
    // AGlow - a point glow (Render.Glow) the caller owns and keeps alive
    // past the painter
    constructor Create(ARenderer: PSdlRenderer; const ASun: TFarPlaneSun;
      AGlow: PSdlTexture);
    // Only where they fall inside AClip, logical units: the crater floor's
    // band, or the near ground's
    procedure DrawShadows(const AShadows: TArray<TRibShadow>; const AClip: TSdlRect);
    procedure DrawRibs(const ARibs: TArray<TFrameRib>);
    // ACover - how far the domes before the sun have turned it
    // (TFarPlaneDef.SunCover), ALevel - how much of itself it keeps
    // (TFarPlaneDef.GlareLevel)
    procedure DrawGlare(ACover, ALevel: Single);
  end;

implementation

uses
  System.SysUtils, System.Math, System.Generics.Collections,
  System.Generics.Defaults, Render.Brush, Render.Glow, Levels.CityLife, Levels.Capsule;

type
  TPoint3 = TDomeFrames.TPoint3;
  TEdge = TDomeFrames.TEdge;
  TBeaconNode = TDomeFrames.TBeaconNode;
  TBeaconNodes = TDomeFrames.TBeaconNodes;

const
  Golden = 1.6180339887498949;
  IcosaCorners: array [0..11, 0..2] of Double = (
    (-1, Golden, 0), (1, Golden, 0), (-1, -Golden, 0), (1, -Golden, 0),
    (0, -1, Golden), (0, 1, Golden), (0, -1, -Golden), (0, 1, -Golden),
    (Golden, 0, -1), (Golden, 0, 1), (-Golden, 0, -1), (-Golden, 0, 1));
  IcosaFaces: array [0..19, 0..2] of Integer = (
    (0, 11, 5), (0, 5, 1), (0, 1, 7), (0, 7, 10), (0, 10, 11), (1, 5, 9),
    (5, 11, 4), (11, 10, 2), (10, 7, 6), (7, 1, 8), (3, 9, 4), (3, 4, 2),
    (3, 2, 6), (3, 6, 8), (3, 8, 9), (4, 9, 5), (2, 4, 11), (6, 2, 10),
    (8, 6, 7), (9, 8, 1));
  // Points nearer than this are one point: the faces share their edges
  PointKeyScale = 10000;
  // A point this far under the equator is below it, this far over it
  // above: the points on it carry the noise of the arithmetic
  UnderEquator = -1E-6;
  OverEquator = 1E-6;
  RingSegments = 96;
  // A shadow is cut this many units in front of that plane: cut on it, the
  // arithmetic could put its end behind it
  EyeCutMargin = 1E-3;
  // How much wider than its rib a shadow's dark is drawn
  ShadowWidening = 1.4;
  // The rim: how far from the sun it fades, units, the least of it far off
  // and turned away, and where it lies on the rib - in shares of the rib's
  // width
  RimReach = 150;
  RimFloor = 0.12;
  RimSideFloor = 0.35;
  RimShift = 0.35;
  RimWidth = 0.3;
  // A rim darker than this is not drawn
  LeastRim = 0.03;
  DiscSegments = 10;
  LeastBuffer = 1024;
  RibDark: TSdlColor = (R: 26; G: 23; B: 21; A: 255);
  ShadowColor: TSdlColor = (R: 0; G: 0; B: 0; A: 115);
  RimColor: TSdlColor = (R: 255; G: 226; B: 180; A: 255);
  // The glare is two glows fitted to the stand's radial gradient (0.55 at
  // the middle, 0.22 a third of the way out, nothing at 3.2 discs): a core
  // and a wide one, sized by that reach
  GlareReach = 3.2;
  GlareCoreSize = 0.84;
  GlareCoreLevel = 0.21;
  GlareWideSize = 2.9;
  GlareWideLevel = 0.32;

function Point3(AX, AY, AZ: Double): TPoint3;
begin
  Result.X := AX;
  Result.Y := AY;
  Result.Z := AZ;
end;

function UnitPoint(const APoint: TPoint3): TPoint3;
begin
  var Reach := Sqrt(Sqr(APoint.X) + Sqr(APoint.Y) + Sqr(APoint.Z));
  Result := Point3(APoint.X / Reach, APoint.Y / Reach, APoint.Z / Reach);
end;

function PointKey(const APoint: TPoint3): string;
begin
  Result := Format('%d,%d,%d', [Round(APoint.X * PointKeyScale),
    Round(APoint.Y * PointKeyScale), Round(APoint.Z * PointKeyScale)]);
end;

// A point of the unit half-sphere on a frame ARadius wide each way and
// AHeight tall
function Stretched(const APoint: TPoint3; ARadius, AHeight: Double): TPoint3;
begin
  Result := Point3(APoint.X * ARadius, APoint.Y * AHeight, APoint.Z * ARadius);
end;

function Edge(const AFrom, ATo: TPoint3; AThickening: Single): TEdge;
begin
  Result.A := AFrom;
  Result.B := ATo;
  Result.Thickening := AThickening;
end;

// The corners on the unit sphere, turned about X so that the top corner
// stands straight up
function IcosaPoints: TArray<TPoint3>;
begin
  var Tilt := ArcTan2(-Golden, 1);
  var CosTilt := Cos(Tilt);
  var SinTilt := Sin(Tilt);
  SetLength(Result, Length(IcosaCorners));
  for var i := 0 to High(IcosaCorners) do
  begin
    var Corner := UnitPoint(Point3(IcosaCorners[i, 0], IcosaCorners[i, 1],
      IcosaCorners[i, 2]));
    Result[i] := Point3(Corner.X, Corner.Y * CosTilt - Corner.Z * SinTilt,
      Corner.Y * SinTilt + Corner.Z * CosTilt);
  end;
end;

// The upper half of a geodesic sphere: every edge once, an edge across the
// equator cut at it, and the equator added as the ring
function BuildGeodesic(AFrequency: Integer): TArray<TEdge>;
var
  Seen: TDictionary<string, Boolean>;
  Edges: TList<TEdge>;

  procedure Add(const AFrom, ATo: TPoint3);
  begin
    var FromKey := PointKey(AFrom);
    var ToKey := PointKey(ATo);
    var Key := ToKey + '|' + FromKey;
    if FromKey < ToKey then
      Key := FromKey + '|' + ToKey;
    if Seen.ContainsKey(Key) then
      Exit;
    Seen.Add(Key, True);

    if (AFrom.Y < UnderEquator) and (ATo.Y < UnderEquator) then
      Exit;
    if (AFrom.Y >= UnderEquator) and (ATo.Y >= UnderEquator) then
    begin
      Edges.Add(Edge(AFrom, ATo, 1));
      Exit;
    end;
    var Under := AFrom;
    var Over := ATo;
    if ATo.Y < AFrom.Y then
    begin
      Under := ATo;
      Over := AFrom;
    end;
    var Cut: Double := Over.Y / (Over.Y - Under.Y);
    Edges.Add(Edge(Over, Point3(Over.X + (Under.X - Over.X) * Cut, 0,
      Over.Z + (Under.Z - Over.Z) * Cut), 1));
  end;

  // A point of a face's grid, AAlong steps toward its second corner and
  // AAcross toward its third, out on the sphere
  function GridPoint(const ACorner, AToSecond, AToThird: TPoint3;
    AAlong, AAcross: Integer): TPoint3;
  begin
    var Along: Double := AAlong / AFrequency;
    var Across: Double := AAcross / AFrequency;
    Result := UnitPoint(Point3(
      ACorner.X + AToSecond.X * Along + AToThird.X * Across,
      ACorner.Y + AToSecond.Y * Along + AToThird.Y * Across,
      ACorner.Z + AToSecond.Z * Along + AToThird.Z * Across));
  end;

begin
  Seen := TDictionary<string, Boolean>.Create;
  Edges := TList<TEdge>.Create;
  try
    var Corners := IcosaPoints;
    for var Face := 0 to High(IcosaFaces) do
    begin
      var First := Corners[IcosaFaces[Face, 0]];
      var Second := Corners[IcosaFaces[Face, 1]];
      var Third := Corners[IcosaFaces[Face, 2]];
      var ToSecond := Point3(Second.X - First.X, Second.Y - First.Y, Second.Z - First.Z);
      var ToThird := Point3(Third.X - First.X, Third.Y - First.Y, Third.Z - First.Z);
      for var i := 0 to AFrequency - 1 do
        for var j := 0 to AFrequency - 1 - i do
        begin
          var Here := GridPoint(First, ToSecond, ToThird, i, j);
          var Next := GridPoint(First, ToSecond, ToThird, i + 1, j);
          var Aside := GridPoint(First, ToSecond, ToThird, i, j + 1);
          Add(Here, Next);
          Add(Here, Aside);
          Add(Next, Aside);
        end;
    end;

    for var i := 0 to RingSegments - 1 do
    begin
      var FromAngle := i / RingSegments * 2 * Pi;
      var ToAngle := (i + 1) / RingSegments * 2 * Pi;
      Edges.Add(Edge(Point3(Cos(FromAngle), 0, Sin(FromAngle)),
        Point3(Cos(ToAngle), 0, Sin(ToAngle)), FrameRingThickening));
    end;
    Result := Edges.ToArray;
  finally
    Edges.Free;
    Seen.Free;
  end;
end;

// The deepest first: drawn far to near. Exact, not CompareValue: its slack
// makes the ribs on the equator equal to their neighbours one way and not
// the other, and the sort leaves them out of order
function DeeperFirst(const ALeft, ARight: TFrameRib): Integer;
begin
  if ALeft.Z > ARight.Z then
    Result := -1
  else if ALeft.Z < ARight.Z then
    Result := 1
  else
    Result := 0;
end;

procedure SortFarToNear(var ARibs: TArray<TFrameRib>);
begin
  TArray.Sort<TFrameRib>(ARibs, TComparer<TFrameRib>.Construct(DeeperFirst));
end;

// The point AShare of the way from AFrom to ATo
function PointBetween(const AFrom, ATo: TPoint3; AShare: Double): TPoint3;
begin
  Result := Point3(AFrom.X + (ATo.X - AFrom.X) * AShare,
    AFrom.Y + (ATo.Y - AFrom.Y) * AShare, AFrom.Z + (ATo.Z - AFrom.Z) * AShare);
end;

function NormalOf(const AFrom, ATo: TSdlFPoint): TSdlFPoint;
begin
  var AlongX: Single := ATo.X - AFrom.X;
  var AlongY: Single := ATo.Y - AFrom.Y;
  var RibLength: Single := Sqrt(AlongX * AlongX + AlongY * AlongY);
  if RibLength = 0 then
    RibLength := 1;
  Result.X := -AlongY / RibLength;
  Result.Y := AlongX / RibLength;
end;

{ TDomeFrames }

constructor TDomeFrames.Create(const ADef: TFarPlaneDef);
begin
  inherited Create;
  FDef := ADef;
  if not Present then
    Exit;

  SetLength(FEdges, Length(FDef.Frames));
  SetLength(FBeaconNodes, Length(FDef.Frames));
  for var i := 0 to High(FDef.Frames) do
  begin
    FEdges[i] := FrameEdges(i);
    if FDef.Frames[i].Kind = fkCapsule then
      FBeaconNodes[i] := CapsuleBeaconNodes(i)
    else
      FBeaconNodes[i] := BeaconNodes(i);
  end;

  var Focal: Double := FDef.Camera.Focal;
  var SunX: Double := FDef.Sun.X - FDef.ScreenWidth / 2;
  var SunY: Double := FDef.Camera.Horizon - FDef.Sun.Y;
  var Reach := Sqrt(SunX * SunX + SunY * SunY + Focal * Focal);
  FToSun := Point3(SunX / Reach, SunY / Reach, Focal / Reach);
  FSunSpread := FDef.Sun.Disc / Focal;
end;

function TDomeFrames.Present: Boolean;
begin
  Result := Length(FDef.Frames) > 0;
end;

// A capsule's are its own; a dome's the geodesic's on the unit half-sphere,
// stretched to its width and height
function TDomeFrames.FrameEdges(AFrame: Integer): TArray<TEdge>;
begin
  var Frame := FDef.Frames[AFrame];
  if Frame.Kind = fkCapsule then
  begin
    var Shape := CapsuleShape(Frame);
    SetLength(Result, Length(Shape.Edges));
    for var i := 0 to High(Shape.Edges) do
      Result[i] := Edge(Shape.Edges[i].A, Shape.Edges[i].B, Shape.Edges[i].Thickening);
    Exit;
  end;

  Result := BuildGeodesic(Frame.Frequency);
  var Radius: Double := Frame.W / 2;
  for var i := 0 to High(Result) do
  begin
    Result[i].A := Stretched(Result[i].A, Radius, Frame.H);
    Result[i].B := Stretched(Result[i].B, Radius, Frame.H);
  end;
end;

// Every end of an edge above the equator once, the ones above the frame's
// share of its height kept; the seed by the place on the unit half-sphere
function TDomeFrames.BeaconNodes(AFrame: Integer): TBeaconNodes;
var
  Frame: TDomeFrame;
  Nodes: TBeaconNodes;
  Seen: TDictionary<string, Boolean>;

  procedure Take(const APoint: TPoint3);
  begin
    var Key := PointKey(APoint);
    if (APoint.Y <= OverEquator) or Seen.ContainsKey(Key) then
      Exit;
    Seen.Add(Key, True);
    if APoint.Y <= Frame.BeaconsAbove then
      Exit;
    var Node: TBeaconNode;
    Node.At := Stretched(APoint, Frame.W / 2, Frame.H);
    Node.Seed := BeaconSeed(AFrame, APoint.X, APoint.Z);
    Nodes := Nodes + [Node];
  end;

begin
  Frame := FDef.Frames[AFrame];
  Nodes := [];
  if not Frame.Beacons then
    Exit(Nodes);
  Seen := TDictionary<string, Boolean>.Create;
  try
    for var Edge in BuildGeodesic(Frame.Frequency) do
    begin
      Take(Edge.A);
      Take(Edge.B);
    end;
  finally
    Seen.Free;
  end;
  Result := Nodes;
end;

// The capsule's nodes above the frame's share of its height
function TDomeFrames.CapsuleBeaconNodes(AFrame: Integer): TBeaconNodes;
begin
  Result := [];
  var Frame := FDef.Frames[AFrame];
  if not Frame.Beacons then
    Exit;
  for var Node in CapsuleShape(Frame).Nodes do
  begin
    if Node.At.Y / Frame.H <= Frame.BeaconsAbove then
      Continue;
    var Beacon: TBeaconNode;
    Beacon.At := Node.At;
    Beacon.Seed := BeaconSeed(AFrame, Node.KeyX, Node.KeyZ);
    Result := Result + [Beacon];
  end;
end;

// Along the sun's light down to the floor: toward the eye, and long - the
// sun is low
function TDomeFrames.DropToFloor(const AAt: TPoint3): TPoint3;
begin
  var Run: Double := AAt.Y / FToSun.Y;
  Result := Point3(AAt.X - FToSun.X * Run, 0, AAt.Z - FToSun.Z * Run);
end;

// The part of a shadow on the floor in front of the eye, AFrom to ATo, as
// shares of the way between them; False - none of it. A lifted rib drops
// an end behind the eye, and its shadow streams toward the bottom of the
// screen
function TDomeFrames.CutAtEye(const AFrom, ATo: TPoint3;
  out AFromShare, AToShare: Double): Boolean;
begin
  var Plane: Double := FDef.Camera.Focal * (FrameNearestShare - 1) + EyeCutMargin;
  AFromShare := 0;
  AToShare := 1;
  Result := (AFrom.Z >= Plane) or (ATo.Z >= Plane);
  if not Result then
    Exit;
  var Crossing: Double := 0;
  if (AFrom.Z < Plane) or (ATo.Z < Plane) then
    Crossing := (Plane - AFrom.Z) / (ATo.Z - AFrom.Z);
  if AFrom.Z < Plane then
    AFromShare := Crossing
  else if ATo.Z < Plane then
    AToShare := Crossing;
end;

procedure TDomeFrames.LightRim(var ARib: TFrameRib);
begin
  ARib.Normal := NormalOf(ARib.A, ARib.B);
  var ToSunX: Single := FDef.Sun.X - (ARib.A.X + ARib.B.X) / 2;
  var ToSunY: Single := FDef.Sun.Y - (ARib.A.Y + ARib.B.Y) / 2;
  var Distance: Single := Sqrt(ToSunX * ToSunX + ToSunY * ToSunY);
  if Distance = 0 then
    Distance := 1;
  var Facing: Single := (ARib.Normal.X * ToSunX + ARib.Normal.Y * ToSunY) / Distance;
  if Facing < 0 then
  begin
    ARib.Normal.X := -ARib.Normal.X;
    ARib.Normal.Y := -ARib.Normal.Y;
    Facing := -Facing;
  end;
  var Nearby: Single := Exp(-Distance / RimReach);
  ARib.Light := (RimFloor + (1 - RimFloor) * Nearby) *
    (RimSideFloor + (1 - RimSideFloor) * Facing);
end;

// A sample a share of the way along the rib: the light runs from there down
// to the floor, and the farther it runs, the wider the penumbra and the
// less of the disc the rib hides
procedure TDomeFrames.AddShadow(const AFrame: TDomeFrame; ACityOffset: Double;
  const AFrom, ATo: TPoint3; AThickness: Single; var AFill: TViewFill);
var
  Shadow: TRibShadow;
  FromShare, ToShare: Double;
  Nearness: Single;
begin
  if not CutAtEye(DropToFloor(AFrom), DropToFloor(ATo), FromShare, ToShare) then
    Exit;
  var Width: Double := AThickness * ShadowWidening;
  for var i := 0 to ShadowSamples - 1 do
  begin
    var Share: Double := FromShare + (ToShare - FromShare) * i / (ShadowSamples - 1);
    var Caster := PointBetween(AFrom, ATo, Share);
    if not FDef.FramePoint(AFrame, ACityOffset, DropToFloor(Caster), Shadow.Samples[i].At,
      Nearness) then
      Exit;
    var Spread: Double := FSunSpread * Caster.Y / FToSun.Y;
    var Penumbra: Double := 2 * Spread;
    if Penumbra < Width then
      Penumbra := Width;
    Shadow.Samples[i].CoreHalf := Nearness * Abs(Width / 2 - Spread);
    Shadow.Samples[i].OuterHalf := Nearness * (Width / 2 + Spread);
    Shadow.Samples[i].Peak := Width / Penumbra;
  end;
  AFill.View.Shadows[AFill.ShadowCount] := Shadow;
  Inc(AFill.ShadowCount);
end;

procedure TDomeFrames.AddEdge(const AFrame: TDomeFrame; ACityOffset: Double;
  const AEdge: TEdge; AOfFarm: Boolean; var AFill: TViewFill);
var
  Rib: TFrameRib;
  NearnessA, NearnessB: Single;
begin
  var From := AEdge.A;
  var Till := AEdge.B;
  if not FDef.FramePoint(AFrame, ACityOffset, From, Rib.A, NearnessA) or
    not FDef.FramePoint(AFrame, ACityOffset, Till, Rib.B, NearnessB) then
    Exit;
  Rib.Z := (From.Z + Till.Z) / 2;
  var Thickness: Single := AFrame.Rib * AEdge.Thickening;
  Rib.W := Thickness * (NearnessA + NearnessB) / 2;
  Rib.Farm := AOfFarm;
  Rib.Dark := RibDark;
  LightRim(Rib);

  if Rib.Z > 0 then
  begin
    AFill.View.Far[AFill.FarCount] := Rib;
    Inc(AFill.FarCount);
  end
  else
  begin
    AFill.View.Near[AFill.NearCount] := Rib;
    Inc(AFill.NearCount);
  end;

  var Lifted := (AEdge.A.Y > OverEquator) or (AEdge.B.Y > OverEquator);
  if Lifted and (FToSun.Y > 0) then
    AddShadow(AFrame, ACityOffset, From, Till, Thickness, AFill);
end;

procedure TDomeFrames.AddFrame(AFrame: Integer; ACityOffset: Double;
  var AFill: TViewFill);
var
  Left, Right: TSdlFPoint;
  Nearness: Single;
begin
  var Frame := FDef.Frames[AFrame];
  var Radius: Double := Frame.W / 2;
  FDef.FramePoint(Frame, ACityOffset, Point3(-Radius, 0, 0), Left, Nearness);
  FDef.FramePoint(Frame, ACityOffset, Point3(Radius, 0, 0), Right, Nearness);
  if (Right.X < -Radius) or (Left.X > FDef.ScreenWidth + Radius) then
    Exit;
  var OfFarm := FDef.Farm.Present and (FDef.Farm.Frame = AFrame);
  for var Edge in FEdges[AFrame] do
    AddEdge(Frame, ACityOffset, Edge, OfFarm, AFill);
  AddBeacons(AFrame, ACityOffset, AFill);
end;

procedure TDomeFrames.AddBeacons(AFrame: Integer; ACityOffset: Double;
  var AFill: TViewFill);
var
  Beacon: TFrameBeacon;
begin
  var Frame := FDef.Frames[AFrame];
  for var Node in FBeaconNodes[AFrame] do
  begin
    if not FDef.FramePoint(Frame, ACityOffset, Node.At, Beacon.At, Beacon.Nearness) then
      Continue;
    Beacon.Seed := Node.Seed;
    // The top stands at Z 0, near on the stand; the FPU's extended
    // precision puts it a hair off either way
    if Node.At.Z > OverEquator then
    begin
      AFill.View.FarBeacons[AFill.FarBeaconCount] := Beacon;
      Inc(AFill.FarBeaconCount);
    end
    else
    begin
      AFill.View.NearBeacons[AFill.NearBeaconCount] := Beacon;
      Inc(AFill.NearBeaconCount);
    end;
  end;
end;

function TDomeFrames.View(ACityOffset: Double): TFrameView;
var
  Fill: TViewFill;
begin
  Fill := Default(TViewFill);
  var Most := 0;
  for var Edges in FEdges do
    Inc(Most, Length(Edges));
  SetLength(Fill.View.Far, Most);
  SetLength(Fill.View.Near, Most);
  SetLength(Fill.View.Shadows, Most);
  var MostBeacons := 0;
  for var Nodes in FBeaconNodes do
    Inc(MostBeacons, Length(Nodes));
  SetLength(Fill.View.FarBeacons, MostBeacons);
  SetLength(Fill.View.NearBeacons, MostBeacons);

  for var i := 0 to High(FDef.Frames) do
    AddFrame(i, ACityOffset, Fill);

  SetLength(Fill.View.Far, Fill.FarCount);
  SetLength(Fill.View.Near, Fill.NearCount);
  SetLength(Fill.View.Shadows, Fill.ShadowCount);
  SetLength(Fill.View.FarBeacons, Fill.FarBeaconCount);
  SetLength(Fill.View.NearBeacons, Fill.NearBeaconCount);
  SortFarToNear(Fill.View.Far);
  SortFarToNear(Fill.View.Near);
  Result := Fill.View;
end;

{ TDomeFramePainter }

constructor TDomeFramePainter.Create(ARenderer: PSdlRenderer;
  const ASun: TFarPlaneSun; AGlow: PSdlTexture);
begin
  inherited Create;
  FRenderer := ARenderer;
  FSun := ASun;
  FGlow := AGlow;
  FPixel := 1;
end;

// The window may have been resized since the last frame
procedure TDomeFramePainter.MeasurePixel;
var
  ScaleX, ScaleY: Single;
begin
  SDL_RenderGetScale(FRenderer, @ScaleX, @ScaleY);
  FPixel := 1;
  if ScaleY > 0 then
    FPixel := 1 / ScaleY;
end;

// Four corners across AAt along ANormal, AShift its middle: the inner two
// ACoreHalf to each side at APeak, the outer two AOuterHalf out and clear
function TDomeFramePainter.StripEnd(const AAt, ANormal: TSdlFPoint;
  AShift, ACoreHalf, AOuterHalf, APeak: Single): TStripEnd;
var
  Offsets, Alphas: array [0..3] of Single;
begin
  Offsets[0] := AShift - AOuterHalf;
  Offsets[1] := AShift - ACoreHalf;
  Offsets[2] := AShift + ACoreHalf;
  Offsets[3] := AShift + AOuterHalf;
  Alphas[0] := 0;
  Alphas[1] := APeak;
  Alphas[2] := APeak;
  Alphas[3] := 0;
  for var i := 0 to 3 do
  begin
    Result[i].X := AAt.X + ANormal.X * Offsets[i];
    Result[i].Y := AAt.Y + ANormal.Y * Offsets[i];
    Result[i].Alpha := Alphas[i];
  end;
end;

// A band along AFrom..ATo, its middle AShift along ANormal, AHalfWidth to
// each side: solid inside, fading out over one pixel at both edges
function TDomeFramePainter.SolidStrip(const AFrom, ATo, ANormal: TSdlFPoint;
  AShift, AHalfWidth: Single): TStrip;
begin
  var Inner: Single := AHalfWidth - FPixel / 2;
  if Inner < 0 then
    Inner := 0;
  var Outer: Single := AHalfWidth + FPixel / 2;
  Result.AtFrom := StripEnd(AFrom, ANormal, AShift, Inner, Outer, 1);
  Result.AtTo := StripEnd(ATo, ANormal, AShift, Inner, Outer, 1);
end;

function TDomeFramePainter.AddVertex(AX, AY: Single; AColor: TSdlColor): Integer;
begin
  if FVertexCount = Length(FVertices) then
    SetLength(FVertices, Max(LeastBuffer, 2 * Length(FVertices)));
  Result := FVertexCount;
  FVertices[Result].Position.X := AX;
  FVertices[Result].Position.Y := AY;
  FVertices[Result].Color := AColor;
  FVertices[Result].TexCoord.X := 0;
  FVertices[Result].TexCoord.Y := 0;
  Inc(FVertexCount);
end;

procedure TDomeFramePainter.AddTriangle(AFirst, ASecond, AThird: Integer);
begin
  if FIndexCount + 3 > Length(FIndices) then
    SetLength(FIndices, Max(LeastBuffer, 2 * Length(FIndices)));
  FIndices[FIndexCount] := AFirst;
  FIndices[FIndexCount + 1] := ASecond;
  FIndices[FIndexCount + 2] := AThird;
  Inc(FIndexCount, 3);
end;

procedure TDomeFramePainter.AddStrip(const AStrip: TStrip; AColor: TSdlColor);
var
  FromIds, ToIds: array [0..3] of Integer;
begin
  for var i := 0 to 3 do
  begin
    var Color := AColor;
    Color.A := Round(AColor.A * AStrip.AtFrom[i].Alpha);
    FromIds[i] := AddVertex(AStrip.AtFrom[i].X, AStrip.AtFrom[i].Y, Color);
    ToIds[i] := AddVertex(AStrip.AtTo[i].X, AStrip.AtTo[i].Y, Color);
  end;
  for var i := 0 to 2 do
  begin
    AddTriangle(FromIds[i], ToIds[i], ToIds[i + 1]);
    AddTriangle(FromIds[i], ToIds[i + 1], FromIds[i + 1]);
  end;
end;

// Four lines across every sample, joined sample to sample: the dark of the
// stroke fades out across it to its edges and along it as its peak falls.
// Its edges fade over a pixel at the least
procedure TDomeFramePainter.AddStroke(const AShadow: TRibShadow);
var
  Was, Ids: array [0..3] of Integer;
begin
  var Normal := NormalOf(AShadow.Samples[0].At,
    AShadow.Samples[ShadowSamples - 1].At);
  for var i := 0 to ShadowSamples - 1 do
  begin
    var Sample := AShadow.Samples[i];
    var Outer: Single := Sample.CoreHalf + FPixel;
    if Sample.OuterHalf > Outer then
      Outer := Sample.OuterHalf;
    var Across := StripEnd(Sample.At, Normal, 0, Sample.CoreHalf, Outer, Sample.Peak);
    for var j := 0 to 3 do
    begin
      var Color := ShadowColor;
      Color.A := Round(ShadowColor.A * Across[j].Alpha);
      Ids[j] := AddVertex(Across[j].X, Across[j].Y, Color);
    end;
    if i > 0 then
      for var j := 0 to 2 do
      begin
        AddTriangle(Was[j], Ids[j], Ids[j + 1]);
        AddTriangle(Was[j], Ids[j + 1], Was[j + 1]);
      end;
    Was := Ids;
  end;
end;

// The round end of a rib, its edge faded out over one pixel as a strip's
procedure TDomeFramePainter.AddDisc(const ACentre: TSdlFPoint; ARadius: Single;
  AColor: TSdlColor);
var
  InnerIds, OuterIds: array [0..DiscSegments - 1] of Integer;
begin
  var Inner: Single := ARadius - FPixel / 2;
  if Inner < 0 then
    Inner := 0;
  var Outer: Single := ARadius + FPixel / 2;
  var Clear := AColor;
  Clear.A := 0;

  var Middle := AddVertex(ACentre.X, ACentre.Y, AColor);
  for var i := 0 to DiscSegments - 1 do
  begin
    var Angle := i / DiscSegments * 2 * Pi;
    InnerIds[i] := AddVertex(ACentre.X + Cos(Angle) * Inner,
      ACentre.Y + Sin(Angle) * Inner, AColor);
    OuterIds[i] := AddVertex(ACentre.X + Cos(Angle) * Outer,
      ACentre.Y + Sin(Angle) * Outer, Clear);
  end;
  for var i := 0 to DiscSegments - 1 do
  begin
    var Next := (i + 1) mod DiscSegments;
    AddTriangle(Middle, InnerIds[i], InnerIds[Next]);
    AddTriangle(InnerIds[i], OuterIds[i], OuterIds[Next]);
    AddTriangle(InnerIds[i], OuterIds[Next], InnerIds[Next]);
  end;
end;

// A strip of triangles with no texture takes the renderer's draw blend,
// not a texture's: the sky leaves it at none
procedure TDomeFramePainter.Flush;
begin
  if FIndexCount > 0 then
  begin
    SDL_SetRenderDrawBlendMode(FRenderer, SdlBlendModeBlend);
    SDL_RenderGeometry(FRenderer, nil, @FVertices[0], FVertexCount,
      @FIndices[0], FIndexCount);
  end;
  FVertexCount := 0;
  FIndexCount := 0;
end;

procedure TDomeFramePainter.DrawShadows(const AShadows: TArray<TRibShadow>;
  const AClip: TSdlRect);
begin
  MeasurePixel;
  for var Shadow in AShadows do
    AddStroke(Shadow);
  SDL_RenderSetClipRect(FRenderer, @AClip);
  Flush;
  SDL_RenderSetClipRect(FRenderer, nil);
end;

// Each rib dark, then its rim: the next rib over it covers both, as the
// stand strokes them
procedure TDomeFramePainter.DrawRibs(const ARibs: TArray<TFrameRib>);
begin
  MeasurePixel;
  for var Rib in ARibs do
  begin
    var Width: Single := Max(Rib.W, FPixel);
    AddStrip(SolidStrip(Rib.A, Rib.B, Rib.Normal, 0, Width / 2), Rib.Dark);
    AddDisc(Rib.A, Width / 2, Rib.Dark);
    AddDisc(Rib.B, Width / 2, Rib.Dark);
    if Rib.Light < LeastRim then
      Continue;
    var Rim := RimColor;
    Rim.A := Round(255 * Min(Rib.Light, Single(1)));
    var RimWide: Single := Width * RimWidth;
    if RimWide < FPixel then
      RimWide := FPixel;
    AddStrip(SolidStrip(Rib.A, Rib.B, Rib.Normal, Width * RimShift, RimWide / 2),
      Rim);
  end;
  Flush;
end;

procedure TDomeFramePainter.DrawGlare(ACover, ALevel: Single);
begin
  var Color := FSun.ColorAt(ACover);
  var Reach: Single := FSun.Disc * GlareReach;
  DrawGlow(FRenderer, FGlow, FSun.X, FSun.Y, Reach * GlareWideSize, Color,
    GlareWideLevel * ALevel);
  DrawGlow(FRenderer, FGlow, FSun.X, FSun.Y, Reach * GlareCoreSize, Color,
    GlareCoreLevel * ALevel);
end;

end.
