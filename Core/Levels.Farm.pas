{
  Levels.Farm - the light of the farm under the long dome (Levels.FarPlane,
  "farm"), at a ride of the city and a tick of the far plane's clock.

  Each greenhouse's grow light runs on a clock of its own: its time cut
  into spans, a share of them lit; a light switched on after a dark span
  catches with a flicker and warms up, a sodium lamp's way; one switched
  off goes out at once. The dice are Levels.CityLife's, so a hall lights on
  the same tick on the stand and in the game.

  The lit glass is the farm's only light. Each lit greenhouse is a source:
  its glass's colour, at its glass's centre, as strong as its glass's share
  of its picture times the picture's size over a hall's, falling off as
  exp(-(d / reach)^2), the reach at its nearness. Many halls together
  brighten a light toward full and never past it, so it keeps its colour:
  1 - exp(-light * level). The air of the dome takes that light at the
  corners of the dome's near half - the half that covers its silhouette -
  and the floor in front of it from its near foot toward the eye, fading
  out, the ribs' feet throwing gaps.

  The stand (tools/chase/stand.template.html, the farm) is the reference,
  number for number. No SDL: Render.FarPlane draws the glass and the
  meshes, added.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Levels.Farm;
{$I ..\Moon2D.inc}

interface

uses
  Render.Brush, Levels.FarPlane;

const
  // Corners of the air's mesh along the dome and round its near half
  FarmAirAlong = 64;
  FarmAirRound = 6;

type
  // Light in shares of full, a channel each
  TFarmLight = record
    R, G, B: Double;
  end;

  // A lit greenhouse on the screen, units: where its glass's centre is, its
  // colour, how much light it gives - a hall's glass at full gives 1 - and
  // how near it stands
  TFarmSource = record
    X, Y: Double;
    Color: TRgb;
    Power: Double;
    Nearness: Double;
  end;

  TFarmView = record
    Sources: TArray<TFarmSource>;
    // By element of the city's layer: how bright its glass is; 0 for one
    // dark, without glass, or too far off the screen to light it
    Glass: TArray<Double>;
  end;

  TFarmCorner = record
    X, Y: Single;
    Light: TFarmLight;
  end;

  // Triangles whose light lies in their corners, three indices each
  TFarmMesh = record
    Corners: TArray<TFarmCorner>;
    Indices: TArray<Integer>;
  end;

// AElement - the greenhouse's place in the city's layer
function FarmSeed(AElement: Integer): Cardinal;
// 0 .. the glow's level
function FarmGlowLevel(const AGlow: TFarmGlow; ASeed: Cardinal; ATick: Integer): Double;
// AHeights - the height of each element of the city's layer in units, as
// its picture has it. Nothing without a farm
function FarmView(const ADef: TFarPlaneDef; const AOffsets: TFarPlaneOffsets;
  ATick: Integer; const AHeights: TArray<Double>): TFarmView;
// At a point of the screen, units: a channel at 1 is a hall's glass at full
function FarmLight(const AFarm: TCityFarm; const ASources: TArray<TFarmSource>;
  AX, AY: Double): TFarmLight;
// As drawn at ALevel, 0..1 a channel
function Exposed(const ALight: TFarmLight; ALevel: Double): TFarmLight;
// The light of the air over the dome's near half
function FarmAirMesh(const ADef: TFarPlaneDef; const ASources: TArray<TFarmSource>;
  ACityOffset: Double): TFarmMesh;
// The light on the floor in front of the dome, a quad between each two feet
// of its near ribs: lit at the foot, dark the apron's length toward the eye
function FarmApronMesh(const ADef: TFarPlaneDef; const ASources: TArray<TFarmSource>;
  ACityOffset: Double): TFarmMesh;

implementation

uses
  System.Math, Sdl2.Core, Levels.CityLife, Levels.Capsule;

const
  FarmSeedBase = 4096;
  FirstSpanKey = 6;
  SpanKeys = 10;
  SpanOnKeys = 500;
  // A flickering light is out two ticks of every four
  FlickerCycle = 4;
  FlickerDark = 2;
  // A picture this many square units is one hall
  HallArea = 400;
  // A source lighting a point less than this adds nothing
  LeastLight = 1E-4;
  // The apron's light is taken a little over the foot, inside the glass
  ApronLift = 4;
  // Its ends' feet run in quads of half a row
  EndQuads = 4;

function FarmSeed(AElement: Integer): Cardinal;
begin
  Result := Mix(FarmSeedBase + AElement);
end;

function FarmGlowLevel(const AGlow: TFarmGlow; ASeed: Cardinal; ATick: Integer): Double;
begin
  var Start := -RollInt(ASeed, FirstSpanKey, 0, AGlow.SpanMost);
  var WasLit := True;
  var Span: Cardinal := 0;
  while True do
  begin
    var SpanLength := RollInt(ASeed, SpanKeys + Span, AGlow.SpanLeast, AGlow.SpanMost);
    var Lit := Roll(ASeed, SpanOnKeys + Span) < AGlow.OnShare;
    if ATick < Start + SpanLength then
    begin
      if not Lit then
        Exit(0);
      if WasLit then
        Exit(AGlow.Level);
      var Inside := ATick - Start;
      if (Inside < AGlow.FlickerTicks) and (Inside mod FlickerCycle < FlickerDark) then
        Exit(0);
      Exit(AGlow.Level * Min(1.0, (Inside + 1) / AGlow.WarmTicks));
    end;
    WasLit := Lit;
    Inc(Start, SpanLength);
    Inc(Span);
  end;
end;

function CityLayer(const ADef: TFarPlaneDef): Integer;
begin
  for var i := 0 to High(ADef.Layers) do
    if ADef.Layers[i].Motion = fmCity then
      Exit(i);
  Result := -1;
end;

function FarmView(const ADef: TFarPlaneDef; const AOffsets: TFarPlaneOffsets;
  ATick: Integer; const AHeights: TArray<Double>): TFarmView;
var
  Glass: TFarmGlass;
begin
  Result.Sources := [];
  Result.Glass := [];
  var City := CityLayer(ADef);
  if not ADef.Farm.Present or (City < 0) then
    Exit;
  var Layer := ADef.Layers[City];
  SetLength(Result.Glass, Length(Layer.Elements));
  var Margin: Double := ADef.Farm.AirReach * 2;
  for var i := 0 to High(Layer.Elements) do
  begin
    var Element := Layer.Elements[i];
    if not ADef.Farm.GlassOf(Element.Id, Glass) then
      Continue;
    var Left := ADef.ElementLeft(Layer, Element, AOffsets);
    if (Left > ADef.ScreenWidth + Margin) or (Left + Element.W < -Margin) then
      Continue;
    var Level := FarmGlowLevel(ADef.Farm.Glow, FarmSeed(i), ATick);
    Result.Glass[i] := Level;
    if Level <= 0 then
      Continue;

    var Height := AHeights[i];
    var AtU: Double := Glass.AtU;
    if Element.Mirror then
      AtU := 1 - Glass.AtU;
    var Source: TFarmSource;
    Source.X := Left + AtU * Element.W;
    Source.Y := Element.Y - Height + Glass.AtV * Height;
    Source.Color := Glass.Color;
    Source.Power := Level * Glass.Share * Element.W * Height / HallArea;
    Source.Nearness := ADef.Nearness(Element.DepthY);
    Result.Sources := Result.Sources + [Source];
  end;
end;

function FarmLight(const AFarm: TCityFarm; const ASources: TArray<TFarmSource>;
  AX, AY: Double): TFarmLight;
begin
  Result := Default(TFarmLight);
  for var Source in ASources do
  begin
    var Reach: Double := AFarm.AirReach * Source.Nearness;
    var Across: Double := (AX - Source.X) / Reach;
    var Down: Double := (AY - Source.Y) / Reach;
    var Strength := Source.Power * Exp(-(Across * Across + Down * Down));
    if Strength < LeastLight then
      Continue;
    Result.R := Result.R + Source.Color.R / 255 * Strength;
    Result.G := Result.G + Source.Color.G / 255 * Strength;
    Result.B := Result.B + Source.Color.B / 255 * Strength;
  end;
end;

function Exposed(const ALight: TFarmLight; ALevel: Double): TFarmLight;
begin
  Result.R := 1 - Exp(-ALight.R * ALevel);
  Result.G := 1 - Exp(-ALight.G * ALevel);
  Result.B := 1 - Exp(-ALight.B * ALevel);
end;

function Dark: TFarmLight;
begin
  Result := Default(TFarmLight);
end;

function Corner(AX, AY: Single; const ALight: TFarmLight): TFarmCorner;
begin
  Result.X := AX;
  Result.Y := AY;
  Result.Light := ALight;
end;

function Point(AX, AY, AZ: Double): TFramePoint;
begin
  Result.X := AX;
  Result.Y := AY;
  Result.Z := AZ;
end;

// Off along ANormal by ALength
function Moved(const AAt, ANormal: TFramePoint; ALength: Double): TFramePoint;
begin
  Result := Point(AAt.X + ANormal.X * ALength, AAt.Y + ANormal.Y * ALength,
    AAt.Z + ANormal.Z * ALength);
end;

function FarmAirMesh(const ADef: TFarPlaneDef; const ASources: TArray<TFarmSource>;
  ACityOffset: Double): TFarmMesh;
var
  Screen: TSdlFPoint;
  Nearness: Single;
begin
  var Dome := ADef.Frames[ADef.Farm.Frame];
  var Tip := CapsuleEnd(Dome);
  var Half: Double := Dome.Rows / 2;
  SetLength(Result.Corners, (FarmAirAlong + 1) * (FarmAirRound + 1));
  Result.Indices := [];
  for var a := 0 to FarmAirAlong do
    for var r := 0 to FarmAirRound do
    begin
      var At := CapsulePoint(Dome, -Tip + 2 * Tip * a / FarmAirAlong,
        Half + Half * r / FarmAirRound);
      ADef.FramePoint(Dome, ACityOffset, At, Screen, Nearness);
      var Light := Exposed(FarmLight(ADef.Farm, ASources, Screen.X, Screen.Y),
        ADef.Farm.AirLevel);
      var Here := a * (FarmAirRound + 1) + r;
      Result.Corners[Here] := Corner(Screen.X, Screen.Y, Light);
      if (a = 0) or (r = 0) then
        Continue;
      var Back := Here - (FarmAirRound + 1);
      Result.Indices := Result.Indices + [Back - 1, Here - 1, Here, Back - 1, Here, Back];
    end;
end;

type
  // A stretch of the near foot between two ribs' feet, and the way out from
  // each end of it toward the eye
  TApronFoot = record
    A, B: TFramePoint;
    OutA, OutB: TFramePoint;
  end;

function ApronFoot(const AA, AB, AOutA, AOutB: TFramePoint): TApronFoot;
begin
  Result.A := AA;
  Result.B := AB;
  Result.OutA := AOutA;
  Result.OutB := AOutB;
end;

// On an end's foot, on the side ASide: ARow from the tip (Rows / 2) to the
// near corner (Rows), and the way out from there
procedure EndFootAt(const ADome: TDomeFrame; ASide: Integer; ARow: Double;
  out AAt, AOut: TFramePoint);
begin
  var Radius: Double := ADome.D / 2;
  var Phi: Double := Pi * ARow / ADome.Rows;
  AAt := Point(ASide * (CapsuleBarrel(ADome) + Radius * Sin(Phi)), 0, Radius * Cos(Phi));
  AOut := Point(ASide * Sin(Phi), 0, Cos(Phi));
end;

// The barrel's feet at every cell, then the ends' at their even rows, in
// quarters of two rows; a gap of AGap units at every rib's foot
function ApronFeet(const ADome: TDomeFrame; AGap: Double): TArray<TApronFoot>;
var
  FromAt, ToAt, FromOut, ToOut: TFramePoint;
begin
  Result := [];
  var Radius: Double := ADome.D / 2;
  var Barrel := CapsuleBarrel(ADome);
  var Cell: Double := 2 * Barrel / ADome.Cells;
  var Toward := Point(0, 0, -1);
  for var i := 0 to ADome.Cells - 1 do
  begin
    var From: Double := -Barrel + i * Cell;
    Result := Result + [ApronFoot(Point(From + AGap / 2, 0, -Radius),
      Point(From + Cell - AGap / 2, 0, -Radius), Toward, Toward)];
  end;

  // The gap in rows: a row is a quarter turn over Rows / 2 of the arc
  var Shrink: Double := AGap / 2 / (Pi * Radius / ADome.Rows);
  for var Side in TArray<Integer>.Create(-1, 1) do
  begin
    var Row := ADome.Rows div 2;
    while Row < ADome.Rows do
    begin
      for var k := 0 to EndQuads - 1 do
      begin
        var FromRow: Double := Row + 2 * k / EndQuads;
        if k = 0 then
          FromRow := FromRow + Shrink;
        var ToRow: Double := Row + 2 * (k + 1) / EndQuads;
        if k = EndQuads - 1 then
          ToRow := ToRow - Shrink;
        EndFootAt(ADome, Side, FromRow, FromAt, FromOut);
        EndFootAt(ADome, Side, ToRow, ToAt, ToOut);
        Result := Result + [ApronFoot(FromAt, ToAt, FromOut, ToOut)];
      end;
      Inc(Row, 2);
    end;
  end;
end;

function FarmApronMesh(const ADef: TFarPlaneDef; const ASources: TArray<TFarmSource>;
  ACityOffset: Double): TFarmMesh;
var
  FootA, FootB, OutA, OutB: TSdlFPoint;
  Nearness: Single;
begin
  Result.Corners := [];
  Result.Indices := [];
  var Farm := ADef.Farm;
  var Dome := ADef.Frames[Farm.Frame];
  for var Foot in ApronFeet(Dome, Farm.ApronGap) do
  begin
    var Seen := ADef.FramePoint(Dome, ACityOffset, Foot.A, FootA, Nearness) and
      ADef.FramePoint(Dome, ACityOffset, Foot.B, FootB, Nearness);
    if not Seen or (Max(FootA.X, FootB.X) < 0) or (Min(FootA.X, FootB.X) > ADef.ScreenWidth) then
      Continue;
    var Reached := ADef.FramePoint(Dome, ACityOffset, Moved(Foot.B, Foot.OutB, Farm.ApronLength),
      OutB, Nearness) and ADef.FramePoint(Dome, ACityOffset,
      Moved(Foot.A, Foot.OutA, Farm.ApronLength), OutA, Nearness);
    if not Reached then
      Continue;
    var LightA := Exposed(FarmLight(Farm, ASources, FootA.X, FootA.Y - ApronLift),
      Farm.ApronLevel);
    var LightB := Exposed(FarmLight(Farm, ASources, FootB.X, FootB.Y - ApronLift),
      Farm.ApronLevel);
    var Base := Length(Result.Corners);
    Result.Corners := Result.Corners + [Corner(FootA.X, FootA.Y, LightA),
      Corner(FootB.X, FootB.Y, LightB), Corner(OutB.X, OutB.Y, Dark),
      Corner(OutA.X, OutA.Y, Dark)];
    Result.Indices := Result.Indices + [Base, Base + 1, Base + 2, Base, Base + 2, Base + 3];
  end;
end;

end.
