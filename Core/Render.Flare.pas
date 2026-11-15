{
  Render.Flare - the sunrise of the titles' flight
  (docs/mechanics/finale-flight.md, "The flight through the dome"): the sun
  comes out of the main dome's glass on a cue of the track and floods the
  lens - a bloom about the disc, a streak across the whole frame, ghosts on
  the line from the sun through the frame's middle, and the exposure blown
  for a moment, then settled to a glow that stays. The lens's, not the
  world's: drawn on the window over the turned frame, its streak level
  whatever the bank. A sun the domes still cover does not flare.

  Every part is a radial gradient of the stand's (tools/chase/
  stand.template.html - flareNow, drawFlare) drawn as a mesh: a ring of
  vertices at each stop of the gradient carrying the stop's colour, so the
  colour runs straight between the stops across the radius as the
  canvas's does; the streak is the bloom's mesh squeezed flat. All of it
  is added to what lies under it, the canvas's "lighter".

  The state and the mesh touch no SDL (FlareAt, FlareMesh); TFlarePainter
  draws the mesh.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Render.Flare;
{$I ..\Moon2D.inc}

interface

uses
  Sdl2.Core;

type
  // How much of the flare there is: Burst - the blown moment, 1 at its
  // peak and gone as the lens settles; Level - all of it, the burst over
  // what it settles to
  TFlareState = record
    Level, Burst: Single;
  end;

  // The flare as triangles on the window, in the frame's units
  TFlareMesh = record
    Vertices: TArray<TSdlVertex>;
    Indices: TArray<Integer>;
  end;

  TFlarePainter = class
  private
    FRenderer: PSdlRenderer;
    FFrameWidth, FFrameHeight: Integer;
  public
    // AFrameWidth by AFrameHeight - the frame in units, the renderer's
    // logical size
    constructor Create(ARenderer: PSdlRenderer; AFrameWidth, AFrameHeight: Integer);
    // ASun - where the sun stands on the window, units. Nothing before the
    // cue
    procedure Draw(const AState: TFlareState; const ASun: TSdlFPoint);
  end;

// ASince - seconds from the cue, below 0 before it; ACover - how much of
// the sun the domes still take (TFarPlaneDef.SunCover): none of that flares
function FlareAt(ASince: Double; ACover: Single): TFlareState;
// The flare of AState about the sun at ASun in a frame AFrameWidth by
// AFrameHeight, units; empty for none
function FlareMesh(const AState: TFlareState; const ASun: TSdlFPoint;
  AFrameWidth, AFrameHeight: Integer): TFlareMesh;

implementation

type
  // A stop of a radial gradient: its share of the radius, its colour, its
  // alpha 0..1
  TFlareStop = record
    Share: Single;
    R, G, B: Byte;
    Alpha: Single;
  end;

  TFlareStops = array [0..2] of TFlareStop;

  // Where a gradient lies: its middle and its radius each way, units
  TFlareSpot = record
    X, Y: Single;
    RadiusX, RadiusY: Single;
  end;

  // A mesh being filled: its arrays as long as they have grown, and how
  // much of each is filled
  TMeshFill = record
    Mesh: TFlareMesh;
    VertexCount, IndexCount: Integer;
  end;

  // A ghost on the line from the sun through the frame's middle: Along -
  // how far, the middle 1; its radius, colour and level
  TFlareGhost = record
    Along, Size: Single;
    R, G, B: Byte;
    Level: Single;
  end;

const
  AttackSeconds = 0.12;
  SettleSeconds = 1.4;
  // The burst falls to e^-3 of itself over the settling
  SettleFalls = 3;
  // What the flare settles to, a share of its peak
  HoldShare = 0.42;
  // The bloom's radius at the peak, units; at none of the flare it is
  // BloomLeast of that
  BloomReach = 150;
  BloomLeast = 0.55;
  // The streak is the frame's width each way, this share of it tall
  StreakFlat = 0.035;
  // The white over the frame at the peak, by the burst squared
  VeilLevel = 0.6;
  // Corners of a gradient's ring
  FanSegments = 64;
  LeastBuffer = 1024;

  BloomStops: TFlareStops = (
    (Share: 0; R: 255; G: 246; B: 224; Alpha: 0.95),
    (Share: 0.22; R: 255; G: 236; B: 200; Alpha: 0.5),
    (Share: 1; R: 255; G: 220; B: 170; Alpha: 0));
  StreakStops: TFlareStops = (
    (Share: 0; R: 235; G: 244; B: 255; Alpha: 1),
    (Share: 0.3; R: 170; G: 205; B: 255; Alpha: 0.5),
    (Share: 1; R: 120; G: 170; B: 255; Alpha: 0));
  // A ghost is flat to 0.8 of its radius and fades out from there
  GhostFlatShare = 0.8;
  Ghosts: array [0..3] of TFlareGhost = (
    (Along: 0.55; Size: 9; R: 120; G: 170; B: 255; Level: 0.12),
    (Along: 1.35; Size: 22; R: 255; G: 170; B: 90; Level: 0.08),
    (Along: 1.8; Size: 6; R: 160; G: 255; B: 220; Level: 0.12),
    (Along: 2.3; Size: 34; R: 120; G: 150; B: 255; Level: 0.06));
  VeilColor: TSdlColor = (R: 255; G: 244; B: 220; A: 255);

function Smoothed(AShare: Double): Double;
begin
  if AShare <= 0 then
    Exit(0);
  if AShare >= 1 then
    Exit(1);
  Result := AShare * AShare * (3 - 2 * AShare);
end;

function FlareAt(ASince: Double; ACover: Single): TFlareState;
begin
  Result := Default(TFlareState);
  if ASince <= 0 then
    Exit;
  var Up: Double := Smoothed(ASince / AttackSeconds) * (1 - ACover);
  var Settling: Double := ASince - AttackSeconds;
  if Settling < 0 then
    Settling := 0;
  var Burst: Double := Up * Exp(-Settling / SettleSeconds * SettleFalls);
  Result.Burst := Burst;
  Result.Level := HoldShare * Up + (1 - HoldShare) * Burst;
end;

function ColorOf(ARed, AGreen, ABlue: Byte; AAlpha: Double): TSdlColor;
begin
  Result.R := ARed;
  Result.G := AGreen;
  Result.B := ABlue;
  var Alpha: Integer := Round(255 * AAlpha);
  if Alpha < 0 then
    Alpha := 0
  else if Alpha > 255 then
    Alpha := 255;
  Result.A := Alpha;
end;

procedure AddVertex(var AFill: TMeshFill; AX, AY: Single; const AColor: TSdlColor);
begin
  if AFill.VertexCount = Length(AFill.Mesh.Vertices) then
    SetLength(AFill.Mesh.Vertices, 2 * AFill.VertexCount + LeastBuffer);
  var Vertex: TSdlVertex;
  Vertex.Position.X := AX;
  Vertex.Position.Y := AY;
  Vertex.Color := AColor;
  Vertex.TexCoord.X := 0;
  Vertex.TexCoord.Y := 0;
  AFill.Mesh.Vertices[AFill.VertexCount] := Vertex;
  Inc(AFill.VertexCount);
end;

procedure AddTriangle(var AFill: TMeshFill; AFirst, ASecond, AThird: Integer);
begin
  if AFill.IndexCount + 3 > Length(AFill.Mesh.Indices) then
    SetLength(AFill.Mesh.Indices, 2 * AFill.IndexCount + LeastBuffer);
  AFill.Mesh.Indices[AFill.IndexCount] := AFirst;
  AFill.Mesh.Indices[AFill.IndexCount + 1] := ASecond;
  AFill.Mesh.Indices[AFill.IndexCount + 2] := AThird;
  Inc(AFill.IndexCount, 3);
end;

// The middle at the first stop, then a ring at each stop after it; the
// alphas of the stops times ALevel
procedure AddGradient(var AFill: TMeshFill; const ASpot: TFlareSpot;
  const AStops: TFlareStops; ALevel: Single);
var
  Was, Ring: array [0..FanSegments - 1] of Integer;
begin
  var Middle := AFill.VertexCount;
  var First := AStops[0];
  AddVertex(AFill, ASpot.X, ASpot.Y, ColorOf(First.R, First.G, First.B,
    First.Alpha * ALevel));
  for var Stop := 1 to High(AStops) do
  begin
    var Own := AStops[Stop];
    var Color := ColorOf(Own.R, Own.G, Own.B, Own.Alpha * ALevel);
    for var i := 0 to FanSegments - 1 do
    begin
      var Angle: Double := i / FanSegments * 2 * Pi;
      Ring[i] := AFill.VertexCount;
      AddVertex(AFill, ASpot.X + Cos(Angle) * ASpot.RadiusX * Own.Share,
        ASpot.Y + Sin(Angle) * ASpot.RadiusY * Own.Share, Color);
    end;
    for var i := 0 to FanSegments - 1 do
    begin
      var Next := (i + 1) mod FanSegments;
      if Stop = 1 then
        AddTriangle(AFill, Middle, Ring[i], Ring[Next])
      else
      begin
        AddTriangle(AFill, Was[i], Ring[i], Ring[Next]);
        AddTriangle(AFill, Was[i], Ring[Next], Was[Next]);
      end;
    end;
    Was := Ring;
  end;
end;

function Spot(AX, AY, ARadiusX, ARadiusY: Single): TFlareSpot;
begin
  Result.X := AX;
  Result.Y := AY;
  Result.RadiusX := ARadiusX;
  Result.RadiusY := ARadiusY;
end;

function GhostStops(const AGhost: TFlareGhost): TFlareStops;
begin
  for var i := 0 to High(Result) do
  begin
    Result[i].R := AGhost.R;
    Result[i].G := AGhost.G;
    Result[i].B := AGhost.B;
    Result[i].Alpha := AGhost.Level;
  end;
  Result[0].Share := 0;
  Result[1].Share := GhostFlatShare;
  Result[2].Share := 1;
  Result[2].Alpha := 0;
end;

procedure AddVeil(var AFill: TMeshFill; AFrameWidth, AFrameHeight: Integer;
  ABurst: Single);
begin
  var Color := ColorOf(VeilColor.R, VeilColor.G, VeilColor.B, VeilLevel * ABurst * ABurst);
  var Corner := AFill.VertexCount;
  AddVertex(AFill, 0, 0, Color);
  AddVertex(AFill, AFrameWidth, 0, Color);
  AddVertex(AFill, AFrameWidth, AFrameHeight, Color);
  AddVertex(AFill, 0, AFrameHeight, Color);
  AddTriangle(AFill, Corner, Corner + 1, Corner + 2);
  AddTriangle(AFill, Corner, Corner + 2, Corner + 3);
end;

// The bloom and the streak about the sun, the ghosts, the veil
procedure AddParts(var AFill: TMeshFill; const AState: TFlareState;
  const ASun: TSdlFPoint; AFrameWidth, AFrameHeight: Integer);
begin
  var Level := AState.Level;
  var Bloom: Single := BloomReach * (BloomLeast + (1 - BloomLeast) * Level);
  AddGradient(AFill, Spot(ASun.X, ASun.Y, Bloom, Bloom), BloomStops, Level);
  AddGradient(AFill, Spot(ASun.X, ASun.Y, AFrameWidth, AFrameWidth * StreakFlat),
    StreakStops, Level);

  var MiddleX: Single := AFrameWidth / 2;
  var MiddleY: Single := AFrameHeight / 2;
  for var Ghost in Ghosts do
  begin
    var GhostX: Single := ASun.X + (MiddleX - ASun.X) * Ghost.Along;
    var GhostY: Single := ASun.Y + (MiddleY - ASun.Y) * Ghost.Along;
    AddGradient(AFill, Spot(GhostX, GhostY, Ghost.Size, Ghost.Size), GhostStops(Ghost),
      Level);
  end;
  AddVeil(AFill, AFrameWidth, AFrameHeight, AState.Burst);
end;

function FlareMesh(const AState: TFlareState; const ASun: TSdlFPoint;
  AFrameWidth, AFrameHeight: Integer): TFlareMesh;
var
  Fill: TMeshFill;
begin
  Fill := Default(TMeshFill);
  if AState.Level > 0 then
    AddParts(Fill, AState, ASun, AFrameWidth, AFrameHeight);
  SetLength(Fill.Mesh.Vertices, Fill.VertexCount);
  SetLength(Fill.Mesh.Indices, Fill.IndexCount);
  Result := Fill.Mesh;
end;

{ TFlarePainter }

constructor TFlarePainter.Create(ARenderer: PSdlRenderer; AFrameWidth,
  AFrameHeight: Integer);
begin
  inherited Create;
  FRenderer := ARenderer;
  FFrameWidth := AFrameWidth;
  FFrameHeight := AFrameHeight;
end;

// A mesh with no texture takes the renderer's draw blend
procedure TFlarePainter.Draw(const AState: TFlareState; const ASun: TSdlFPoint);
begin
  var Mesh := FlareMesh(AState, ASun, FFrameWidth, FFrameHeight);
  if Length(Mesh.Indices) = 0 then
    Exit;
  SDL_SetRenderDrawBlendMode(FRenderer, SdlBlendModeAdd);
  SDL_RenderGeometry(FRenderer, nil, @Mesh.Vertices[0], Length(Mesh.Vertices),
    @Mesh.Indices[0], Length(Mesh.Indices));
  SDL_SetRenderDrawBlendMode(FRenderer, SdlBlendModeBlend);
end;

end.
