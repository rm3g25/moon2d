{
  Render.DomeFrames - the dome frames of a chase's city (Levels.FarPlane):
  geodesic half-ellipsoids drawn by code in a 3D of their own, riding with
  the city past the sun that stands still.

  A frame is an icosahedron cut Frequency times along each side and pushed
  out onto the sphere, a vertex at the top, cut at the equator; the equator
  itself is the ring it stands on. It is built once, then stretched to the
  frame's width and height and seen through the city's camera: the far half
  stands behind the buildings, the near half over them, so the city stands
  inside. Lit from behind, nothing of a frame faces the eye in the light: a
  rib is a dark silhouette with a thin rim on its side toward the sun,
  brighter the nearer the sun it runs. The ribs throw long shadows toward
  the eye on the crater floor, and the sun's own glare is laid over the
  ribs that cross its disc. The stand (tools/chase/stand.template.html) is
  the reference, number for number.

  TDomeFrames is the geometry: it does not touch SDL - the ribs and the
  shadows on the screen, in units, for a ride of the city.
  TDomeFramePainter draws them as strips of triangles, the colour and the
  alpha in the vertices: the rim is a strip of its own, and every edge
  fades out over one pixel of the window, the smoothing a canvas gives a
  line for free.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Render.DomeFrames;
{$I ..\Moon2D.inc}

interface

uses
  Sdl2.Core, Levels.FarPlane;

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
  end;

  // A rib's shadow on the crater floor, in units
  TRibShadow = record
    A, B: TSdlFPoint;
    W: Single;
  end;

  // The frames as they stand on the screen at one ride of the city
  TFrameView = record
    // Behind the buildings, far to near
    Far: TArray<TFrameRib>;
    // Over the buildings, far to near
    Near: TArray<TFrameRib>;
    Shadows: TArray<TRibShadow>;
  end;

  TDomeFrames = class
  private type
    TPoint3 = record
      X, Y, Z: Double;
    end;
    // An edge on the unit half-sphere: Y up, Z into the screen
    TEdge = record
      A, B: TPoint3;
      // The ring the frame stands on, thicker than a rib
      Ring: Boolean;
    end;
    // A view being filled: its arrays as long as they may get, and how
    // much of each is filled
    TViewFill = record
      View: TFrameView;
      FarCount, NearCount, ShadowCount: Integer;
    end;
  private
    FDef: TFarPlaneDef;
    // By frame; frames of one frequency share them
    FEdges: TArray<TArray<TEdge>>;
    // From the scene toward the sun, a unit long
    FToSun: TPoint3;
    // Where the crater floor ends below: no shadow past it
    FFloorBottom: Single;
    function SharedEdges(AFrame: Integer): TArray<TEdge>;
    function Project(const AFrame: TDomeFrame; ACityOffset: Double;
      const AAt: TPoint3; out AScreen: TSdlFPoint; out ANearness: Single): Boolean;
    function DropToFloor(const AAt: TPoint3): TPoint3;
    procedure LightRim(var ARib: TFrameRib);
    procedure AddFrame(AFrame: Integer; ACityOffset: Double; var AFill: TViewFill);
    procedure AddEdge(const AFrame: TDomeFrame; ACityOffset: Double;
      const AEdge: TEdge; var AFill: TViewFill);
    procedure AddShadow(const AFrame: TDomeFrame; ACityOffset: Double;
      const AFrom, ATo: TPoint3; AWidth: Single; var AFill: TViewFill);
  public
    // ADef - the level's far plane; one without frames shows none
    constructor Create(const ADef: TFarPlaneDef);
    function Present: Boolean;
    // ACityOffset - how far the city's layer has ridden left
    function View(ACityOffset: Double): TFrameView;
  end;

  TDomeFramePainter = class
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
    function AddVertex(AX, AY: Single; AColor: TSdlColor): Integer;
    procedure AddTriangle(AFirst, ASecond, AThird: Integer);
    procedure AddStrip(const AFrom, ATo, ANormal: TSdlFPoint;
      AShift, AHalfWidth: Single; AColor: TSdlColor);
    procedure AddDisc(const ACentre: TSdlFPoint; ARadius: Single; AColor: TSdlColor);
    procedure Flush;
  public
    // AGlow - a point glow (Render.Glow) the caller owns and keeps alive
    // past the painter
    constructor Create(ARenderer: PSdlRenderer; const ASun: TFarPlaneSun;
      AGlow: PSdlTexture);
    procedure DrawShadows(const AShadows: TArray<TRibShadow>);
    procedure DrawRibs(const ARibs: TArray<TFrameRib>);
    // ACover - how far the domes before the sun have turned it
    // (TFarPlaneDef.SunCover)
    procedure DrawGlare(ACover: Single);
  end;

implementation

uses
  System.SysUtils, System.Math, System.Generics.Collections,
  System.Generics.Defaults, Render.Brush, Render.Glow;

type
  TPoint3 = TDomeFrames.TPoint3;
  TEdge = TDomeFrames.TEdge;

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
  RingThickening = 1.6;
  // A point nearer the eye than this share of the focal length is behind it
  NearestShare = 0.15;
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
  ShadowWidening = 1.4;
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

function Edge(const AFrom, ATo: TPoint3; ARing: Boolean): TEdge;
begin
  Result.A := AFrom;
  Result.B := ATo;
  Result.Ring := ARing;
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
      Edges.Add(Edge(AFrom, ATo, False));
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
      Over.Z + (Under.Z - Over.Z) * Cut), False));
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
        Point3(Cos(ToAngle), 0, Sin(ToAngle)), True));
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

// Where the segment crosses the height AY
function PointAtY(const AFrom, ATo: TSdlFPoint; AY: Single): TSdlFPoint;
begin
  var Share: Single := (AY - AFrom.Y) / (ATo.Y - AFrom.Y);
  Result.X := AFrom.X + (ATo.X - AFrom.X) * Share;
  Result.Y := AY;
end;

// Keeps the part of the segment above ABottom (y down); False - none of it
function KeepAbove(var AFrom, ATo: TSdlFPoint; ABottom: Single): Boolean;
begin
  Result := (AFrom.Y <= ABottom) or (ATo.Y <= ABottom);
  if not Result then
    Exit;
  if AFrom.Y > ABottom then
    AFrom := PointAtY(ATo, AFrom, ABottom)
  else if ATo.Y > ABottom then
    ATo := PointAtY(AFrom, ATo, ABottom);
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
  for var i := 0 to High(FDef.Frames) do
    FEdges[i] := SharedEdges(i);

  var Focal: Double := FDef.Camera.Focal;
  var SunX: Double := FDef.Sun.X - FDef.ScreenWidth / 2;
  var SunY: Double := FDef.Camera.Horizon - FDef.Sun.Y;
  var Reach := Sqrt(SunX * SunX + SunY * SunY + Focal * Focal);
  FToSun := Point3(SunX / Reach, SunY / Reach, Focal / Reach);

  FFloorBottom := FDef.ScreenHeight;
  for var Layer in FDef.Layers do
    if (Layer.Motion = fmCity) and Layer.Band.Present then
      FFloorBottom := Layer.Band.Bottom;
end;

function TDomeFrames.Present: Boolean;
begin
  Result := Length(FDef.Frames) > 0;
end;

function TDomeFrames.SharedEdges(AFrame: Integer): TArray<TEdge>;
begin
  var Frequency := FDef.Frames[AFrame].Frequency;
  for var i := 0 to AFrame - 1 do
    if FDef.Frames[i].Frequency = Frequency then
      Exit(FEdges[i]);
  Result := BuildGeodesic(Frequency);
end;

// AAt - X across, Y up, Z into the screen, from the frame's centre on its
// base line; False - behind the eye
function TDomeFrames.Project(const AFrame: TDomeFrame; ACityOffset: Double;
  const AAt: TPoint3; out AScreen: TSdlFPoint; out ANearness: Single): Boolean;
begin
  var Camera := FDef.Camera;
  Result := Camera.Focal + AAt.Z >= Camera.Focal * NearestShare;
  if not Result then
    Exit;
  ANearness := Camera.Focal / (Camera.Focal + AAt.Z);
  var Middle: Double := FDef.ScreenWidth / 2;
  var Centre: Double := AFrame.X + AFrame.W / 2 - ACityOffset - Middle;
  AScreen.X := Middle + (Centre + AAt.X) * ANearness;
  AScreen.Y := Camera.Horizon + (Camera.BaseY - Camera.Horizon - AAt.Y) * ANearness;
end;

// Along the sun's light down to the floor: toward the eye, and long - the
// sun is low
function TDomeFrames.DropToFloor(const AAt: TPoint3): TPoint3;
begin
  var Run: Double := AAt.Y / FToSun.Y;
  Result := Point3(AAt.X - FToSun.X * Run, 0, AAt.Z - FToSun.Z * Run);
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

procedure TDomeFrames.AddShadow(const AFrame: TDomeFrame; ACityOffset: Double;
  const AFrom, ATo: TPoint3; AWidth: Single; var AFill: TViewFill);
var
  Shadow: TRibShadow;
  Nearness: Single;
begin
  if not Project(AFrame, ACityOffset, DropToFloor(AFrom), Shadow.A, Nearness) or
    not Project(AFrame, ACityOffset, DropToFloor(ATo), Shadow.B, Nearness) then
    Exit;
  if not KeepAbove(Shadow.A, Shadow.B, FFloorBottom) then
    Exit;
  Shadow.W := AWidth;
  AFill.View.Shadows[AFill.ShadowCount] := Shadow;
  Inc(AFill.ShadowCount);
end;

procedure TDomeFrames.AddEdge(const AFrame: TDomeFrame; ACityOffset: Double;
  const AEdge: TEdge; var AFill: TViewFill);
var
  Rib: TFrameRib;
  NearnessA, NearnessB: Single;
begin
  var Radius: Double := AFrame.W / 2;
  var From := Point3(AEdge.A.X * Radius, AEdge.A.Y * AFrame.H, AEdge.A.Z * Radius);
  var Till := Point3(AEdge.B.X * Radius, AEdge.B.Y * AFrame.H, AEdge.B.Z * Radius);
  if not Project(AFrame, ACityOffset, From, Rib.A, NearnessA) or
    not Project(AFrame, ACityOffset, Till, Rib.B, NearnessB) then
    Exit;
  Rib.Z := (From.Z + Till.Z) / 2;
  Rib.W := AFrame.Rib * (NearnessA + NearnessB) / 2;
  if AEdge.Ring then
    Rib.W := Rib.W * RingThickening;
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
    AddShadow(AFrame, ACityOffset, From, Till, Rib.W, AFill);
end;

procedure TDomeFrames.AddFrame(AFrame: Integer; ACityOffset: Double;
  var AFill: TViewFill);
var
  Left, Right: TSdlFPoint;
  Nearness: Single;
begin
  var Frame := FDef.Frames[AFrame];
  var Radius: Double := Frame.W / 2;
  Project(Frame, ACityOffset, Point3(-Radius, 0, 0), Left, Nearness);
  Project(Frame, ACityOffset, Point3(Radius, 0, 0), Right, Nearness);
  if (Right.X < -Radius) or (Left.X > FDef.ScreenWidth + Radius) then
    Exit;
  for var Edge in FEdges[AFrame] do
    AddEdge(Frame, ACityOffset, Edge, AFill);
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

  for var i := 0 to High(FDef.Frames) do
    AddFrame(i, ACityOffset, Fill);

  SetLength(Fill.View.Far, Fill.FarCount);
  SetLength(Fill.View.Near, Fill.NearCount);
  SetLength(Fill.View.Shadows, Fill.ShadowCount);
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

// A band along AFrom..ATo, its middle AShift along ANormal, AHalfWidth to
// each side: solid inside, fading out over one pixel at both edges
procedure TDomeFramePainter.AddStrip(const AFrom, ATo, ANormal: TSdlFPoint;
  AShift, AHalfWidth: Single; AColor: TSdlColor);
var
  Offsets: array [0..3] of Single;
  Colors: array [0..3] of TSdlColor;
  FromIds, ToIds: array [0..3] of Integer;
begin
  var Inner: Single := AHalfWidth - FPixel / 2;
  if Inner < 0 then
    Inner := 0;
  var Outer: Single := AHalfWidth + FPixel / 2;
  var Clear := AColor;
  Clear.A := 0;
  Offsets[0] := AShift - Outer;
  Offsets[1] := AShift - Inner;
  Offsets[2] := AShift + Inner;
  Offsets[3] := AShift + Outer;
  Colors[0] := Clear;
  Colors[1] := AColor;
  Colors[2] := AColor;
  Colors[3] := Clear;

  for var i := 0 to 3 do
  begin
    FromIds[i] := AddVertex(AFrom.X + ANormal.X * Offsets[i],
      AFrom.Y + ANormal.Y * Offsets[i], Colors[i]);
    ToIds[i] := AddVertex(ATo.X + ANormal.X * Offsets[i],
      ATo.Y + ANormal.Y * Offsets[i], Colors[i]);
  end;
  for var i := 0 to 2 do
  begin
    AddTriangle(FromIds[i], ToIds[i], ToIds[i + 1]);
    AddTriangle(FromIds[i], ToIds[i + 1], FromIds[i + 1]);
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

procedure TDomeFramePainter.DrawShadows(const AShadows: TArray<TRibShadow>);
begin
  MeasurePixel;
  for var Shadow in AShadows do
  begin
    var Width: Single := Shadow.W * ShadowWidening;
    if Width < FPixel then
      Width := FPixel;
    AddStrip(Shadow.A, Shadow.B, NormalOf(Shadow.A, Shadow.B), 0, Width / 2,
      ShadowColor);
  end;
  Flush;
end;

// Each rib dark, then its rim: the next rib over it covers both, as the
// stand strokes them
procedure TDomeFramePainter.DrawRibs(const ARibs: TArray<TFrameRib>);
begin
  MeasurePixel;
  for var Rib in ARibs do
  begin
    var Width: Single := Max(Rib.W, FPixel);
    AddStrip(Rib.A, Rib.B, Rib.Normal, 0, Width / 2, RibDark);
    AddDisc(Rib.A, Width / 2, RibDark);
    AddDisc(Rib.B, Width / 2, RibDark);
    if Rib.Light < LeastRim then
      Continue;
    var Rim := RimColor;
    Rim.A := Round(255 * Min(Rib.Light, Single(1)));
    var RimWide: Single := Width * RimWidth;
    if RimWide < FPixel then
      RimWide := FPixel;
    AddStrip(Rib.A, Rib.B, Rib.Normal, Width * RimShift, RimWide / 2, Rim);
  end;
  Flush;
end;

procedure TDomeFramePainter.DrawGlare(ACover: Single);
begin
  var Color := FSun.ColorAt(ACover);
  var Reach: Single := FSun.Disc * GlareReach;
  DrawGlow(FRenderer, FGlow, FSun.X, FSun.Y, Reach * GlareWideSize, Color,
    GlareWideLevel);
  DrawGlow(FRenderer, FGlow, FSun.X, FSun.Y, Reach * GlareCoreSize, Color,
    GlareCoreLevel);
end;

end.
