{
  Levels.FarPlane - the far plane of a chase as data: a strip of layers
  riding left behind the play layer at speeds of their own, and a sun that
  stands still under them all.

  A level names the screen and the layout file in its "farPlane" section,
  as "screen" and "layout" (chase-backdrop.json for level 2). The layout
  lies beside the level file and is the one tools/chase/build_stand.py
  plays on the stand, so a number tuned there is the number the game
  plays. Its pictures are the set named as the layout file without its
  extension, which the level lists among its "objectSets".

  A layer is a seamless band, repeated across, and elements standing on
  it: x their left edge along the layer, y their feet, w their width in
  units, the height following the picture. A band may start at an x of its
  layer, its left end fading in. Each layer rides by one of four motions -
  the near ground, the tunnel, the city, the ridge; how fast each runs is
  Game.FarPlane's business. An element marked "existing" is the screen's
  own backdrop, riding with its layer. The keys only the stand reads (the
  road's speed and ramp, the cliff's edge marks, the city's kit) are let
  be.

  The city has a depth. One camera ("camera": the crater floor's horizon,
  the domes' base line, the focal length) sets how near a thing of it is
  by its feet alone: the lower they stand, the nearer, and the faster it
  rides - k times the layer, k = 1 at the base line. A picture's width in
  the layout is already its width at its depth; a thing hanging in the air
  gives the feet of what it stands on as "groundY". Without a camera the
  city is flat. The dome frames ("frames") are geodesic half-ellipsoids
  drawn by code over that camera (Render.DomeFrames); one marked tintsSun
  turns the sun while it stands before it, as an element marked so does.

  The fangs are no layer: separate pictures of basalt rising from below
  the bottom edge, riding by on a motion of their own between the near
  ground and the road, behind the play layer. The "fangs" section gives
  their kit and the numbers of their scatter - scale, the road between
  two, where the top of a low one and of a tall one stands, how many are
  tall, their tint in the tunnel and outside; the speed is the "fangs" of
  the speeds. Where each one stands is Game.Fangs' business. A layout
  without the section has no fangs.

  The city lives: its lights ("cityLights" - a box and a colour on a piece
  of the kit, riding with every building drawn from it), the TEK emblem
  standing on a spire ("emblem"), the red beacons on a frame's upper nodes
  ("beacons", and "beaconsAbove" of the frame) and the emblem as old paint
  on a wall ("paint" of a placed building). Here they are numbers; how
  bright each one is at a tick is Levels.CityLife's business. The train
  ("train") shuttles on the monorail between the city's two stations;
  where it stands at a time is Levels.Monorail's. The searchlights
  ("searchlights") wander over the sky from the main dome; where a beam
  points at a time is Levels.Searchlights'.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Levels.FarPlane;
{$I ..\Moon2D.inc}

interface

uses
  System.SysUtils, System.JSON, Sdl2.Core, Render.Brush, Levels.Tint;

type
  EFarPlaneError = class(Exception);

  TFarPlaneMotion = (fmRidge, fmCity, fmTunnel, fmGround, fmFangs);

  // How far each motion has taken its layers to the left, in units
  TFarPlaneOffsets = array [TFarPlaneMotion] of Double;

  TFarPlaneSun = record
    X, Y: Single;
    // Radii, units
    Disc, Halo: Single;
    White, Tint: TRgb;
    // Over how many units at each end of a dome the sun turns its colour
    TintRamp: Single;
    // From white (0) to the tint (1), as far as the domes before it turn it
    function ColorAt(ACover: Single): TRgb;
  end;

  TFarPlaneCamera = record
    Present: Boolean;
    // y down: where the crater floor meets the sky, and the line the domes
    // stand on
    Horizon, BaseY: Single;
    // Units
    Focal: Single;
  end;

  // A dome frame drawn by code: X its left edge along the city's layer, W
  // and H its size at the base line
  TDomeFrame = record
    Id: string;
    X, W, H: Single;
    // How many times each side of the icosahedron is cut
    Frequency: Integer;
    // The thickness of a rib, units
    Rib: Single;
    TintsSun: Boolean;
    // Its nodes above BeaconsAbove of its height carry beacons
    Beacons: Boolean;
    BeaconsAbove: Double;
  end;

  // A box in shares of a picture: from its top left, U across and V down
  TPictureBox = record
    U, V, W, H: Single;
  end;

  TCityLightKind = (lkWindow, lkNeon, lkStrip, lkLamp);
  TCityGlowKind = lkWindow..lkStrip;

  // A lamp's box is a point: its width and height are nothing
  TCityLight = record
    Kind: TCityLightKind;
    Box: TPictureBox;
    Color: TRgb;
  end;

  // A glow over a light's box: its core the box scaled by Core, its halo
  // the box scaled by Halo and grown by HaloPad units on each side at the
  // domes' nearness; the levels 0..1
  TCityGlowLook = record
    CoreW, CoreH, CoreLevel: Single;
    HaloW, HaloH, HaloPad, HaloLevel: Single;
  end;

  // A sign's clock, in ticks of the far plane: a slow breath, and windows
  // of time, a share of them carrying a fault - flips down to FaultLow and
  // back. The shares are Double: they are compared with the dice
  TCityFlicker = record
    BreathDepth: Double;
    BreathLeast, BreathMost: Integer;
    WindowLeast, WindowMost: Integer;
    FaultShare: Double;
    FlipsLeast, FlipsMost: Integer;
    FlipLeast, FlipMost: Integer;
    FaultLow: Double;
  end;

  // A window's time is cut into spans, OnShare of them lit
  TCityWindows = record
    OnShare: Double;
    SpanLeast, SpanMost: Integer;
  end;

  TCityPieceLights = record
    Piece: string;
    Lights: TArray<TCityLight>;
  end;

  TCityLights = record
    Present: Boolean;
    Looks: array [TCityGlowKind] of TCityGlowLook;
    Flicker: TCityFlicker;
    Windows: TCityWindows;
    Pieces: TArray<TCityPieceLights>;
    // Empty for a piece without lights
    function LightsOf(const APiece: string): TArray<TCityLight>;
    function HasLamps: Boolean;
  end;

  // The TEK emblem: a neon sign on the lower point of its frame at the tip
  // of a building drawn from Piece (AtU, AtV of its picture). W units wide
  // at the domes' nearness, H = W * Aspect; the metal at Shade, the tubes
  // and their glows added in Color. Parts and Halos are boxes in shares of
  // the emblem, the parts in the order they light, the first one the frame
  TCityEmblem = record
    Present: Boolean;
    Piece: string;
    AtU, AtV: Single;
    W, Aspect: Single;
    Shade: Single;
    Color: TRgb;
    CoreLevel, HaloLevel: Single;
    FaultShare: Double;
    RelightLeast, RelightMost: Integer;
    DarkLeast, DarkMost: Integer;
    PartLeast, PartMost: Integer;
    Parts, Halos: TArray<TPictureBox>;
  end;

  // The red warning lights: a dim glow and a short flash, each on its own
  // period. Size and Halo in units at the node's nearness
  TCityBeacons = record
    Present: Boolean;
    Color: TRgb;
    Size, Halo: Single;
    GlowLevel, FlashLevel: Single;
    FlashTicks: Integer;
    PeriodLeast, PeriodMost: Integer;
  end;

  // The train on the monorail, shuttling between the two elements of the
  // city drawn from Station. Mouth - where a station's box begins, a share
  // of its picture from its left (unmirrored); W its width in units, Y its
  // feet; at a stop its nose stands Inside units past the mouth. A run
  // pushes up to Cruise (units a second) over AccelTicks and down the same
  // way; a dwell lasts DwellLeast..DwellMost ticks
  TCityTrain = record
    Present: Boolean;
    Piece, Station: string;
    Mouth: Single;
    W, Y, Shade: Single;
    Inside: Single;
    Cruise: Double;
    AccelTicks: Integer;
    DwellLeast, DwellMost: Integer;
  end;

  // One of a searchlight's two slow waves: Degrees each way, over
  // PeriodTicks
  TSweepWave = record
    Degrees: Double;
    PeriodTicks: Double;
  end;

  // A lamp of the searchlights: X along the city's layer, Y its feet, Lift
  // how high over them it stands; Aim in degrees on the screen, -90 straight
  // up, and the two waves around it
  TSearchlightLamp = record
    X, Y, Lift: Single;
    Aim: Double;
    Waves: array [0..1] of TSweepWave;
  end;

  // A lamp's own clock now and then eases to a hold: its time is cut into
  // windows of WindowLeast..WindowMost ticks, Share of them holding a pause
  // - EaseTicks down, HoldLeast..HoldMost still, EaseTicks back up
  TSearchlightPause = record
    WindowLeast, WindowMost: Integer;
    Share: Double;
    EaseTicks: Integer;
    HoldLeast, HoldMost: Integer;
  end;

  // Warm beams from the main dome: Level at the lamp to GlassLevel where the
  // beam leaves the dome's silhouette, a spot there and a step down to
  // TailShare of it, a tail of Tail units; half width RootHalf plus Spread a
  // unit of the way. Units at the lamp's depth
  TCitySearchlights = record
    Present: Boolean;
    Color: TRgb;
    Level, GlassLevel, TailShare, Tail: Single;
    RootHalf, Spread: Single;
    SpotSize, SpotLevel: Single;
    GlintSize, GlintLevel: Single;
    Pause: TSearchlightPause;
    Lamps: TArray<TSearchlightLamp>;
  end;

  // The emblem as old paint on a wall: at U, V of the picture, W of its
  // width, Alpha opaque
  TElementPaint = record
    Present: Boolean;
    U, V, W, Alpha: Single;
  end;

  // Units a second; the shares are of another layer's speed
  TFarPlaneSpeeds = record
    TunnelPeak: Single;
    TunnelCruise: Single;
    EaseSec: Single;
    CityShareInTunnel: Single;
    CityCruise: Single;
    CityBrakeZone: Single;
    CityLeast: Single;
    RidgeShareOfCity: Single;
    Ground: Single;
    Fangs: Single;
  end;

  TFarPlaneBand = record
    Present: Boolean;
    Texture: string;
    Top, Bottom: Single;
    // Over how many units its top fades in
    FadeTop: Single;
    // The band starts at this x of its layer; -1 = it runs the whole width
    From: Single;
    // Over how many units from its start it fades in
    FeatherLeft: Single;
    // How much of its colour it keeps while the tunnel is all on the
    // screen; it brightens to the full as the tunnel leaves. 1 - always full
    ShadeInTunnel: Single;
  end;

  TFarPlaneElement = record
    Id: string;
    X, Y, W, H: Single;
    // Where its nearness is read: its feet, or the feet of what it hangs on
    DepthY: Single;
    // 0..1, how much of its colour the picture keeps
    Shade: Single;
    TintsSun: Boolean;
    // Over how many units its left end fades in
    FeatherLeft: Single;
    // Drawn left for right: the light of a picture lit from the wrong side
    Mirror: Boolean;
    // The screen's own backdrop, not a picture of the set
    Backdrop: Boolean;
    Paint: TElementPaint;
  end;

  TFarPlaneLayer = record
    Id: string;
    Motion: TFarPlaneMotion;
    // Units along the layer; 0 = no end of its own
    Length: Single;
    Band: TFarPlaneBand;
    Elements: TArray<TFarPlaneElement>;
  end;

  // A picture of the fangs' kit: its size in units at the scale of 1
  TFangKind = record
    Sprite: string;
    W, H: Single;
    // May stand as a tall one, its top over the city
    Tall: Boolean;
  end;

  TFarPlaneFangs = record
    Kinds: TArray<TFangKind>;
    ScaleLeast, ScaleMost: Single;
    // The road between two fangs along their layer, edge to edge
    GapLeast, GapMost: Single;
    // Where the top of a low one and of a tall one may stand, y down
    LowTopHighest, LowTopLowest: Single;
    TallTopHighest, TallTopLowest: Single;
    // 0..1, of the fangs the dice make tall
    TallShare: Single;
    TintInTunnel, Tint: TColorTint;
    // How far a fang's tint may stray from the common one, percent
    TintJitter: Integer;
    function Present: Boolean;
  end;

  TFarPlaneDef = record
    // 1-based; 0 - the level has no far plane
    Screen: Integer;
    SetName: string;
    ScreenWidth, ScreenHeight: Single;
    Sun: TFarPlaneSun;
    Speeds: TFarPlaneSpeeds;
    Camera: TFarPlaneCamera;
    // Ride with the city's layer
    Frames: TArray<TDomeFrame>;
    // Back to front
    Layers: TArray<TFarPlaneLayer>;
    Fangs: TFarPlaneFangs;
    Lights: TCityLights;
    Emblem: TCityEmblem;
    Beacons: TCityBeacons;
    Train: TCityTrain;
    Searchlights: TCitySearchlights;
    function Present: Boolean;
    // How near a thing of the city whose feet stand at AY is, the domes'
    // centres 1: it rides that share of its layer's speed
    function Nearness(AY: Single): Single;
    // Where an element's left edge stands on the screen. One of the city
    // brings its centre to the middle of the screen when its layer has
    // ridden it there, and drifts from it Nearness times as fast
    function ElementLeft(const ALayer: TFarPlaneLayer;
      const AElement: TFarPlaneElement; const AOffsets: TFarPlaneOffsets): Double;
    // The length of the city's layer: where the strip ends
    function CityLength: Single;
    // The elements of the city's layer drawn from APiece, in its order
    function CityElements(const APiece: string): TArray<TFarPlaneElement>;
    // The middle of every building of the city whose middle is on the
    // screen where the offsets have taken it, in the city's order
    function CityPoints(const AOffsets: TFarPlaneOffsets): TArray<TSdlFPoint>;
    // Where the tunnel's last element ends along its layer: once that is
    // past the left edge, the tunnel is gone
    function TunnelEnd: Single;
    // How far the domes before the sun have turned it, 0 (white) .. 1
    function SunCover(const AOffsets: TFarPlaneOffsets): Single;
    // How much of the tunnel has left the screen, 0 .. 1
    function TunnelPassed(const AOffsets: TFarPlaneOffsets): Single;
    // How much of its colour a band keeps where the offsets have taken it
    function BandShade(const ABand: TFarPlaneBand;
      const AOffsets: TFarPlaneOffsets): Single;
    // The sprite of the set a picture is drawn from
    function SpriteName(const AId: string): string;
    // A fang's tint where the offsets have taken it: as dark as in the
    // tunnel while the tunnel is all on the screen, the common one once it
    // has left; AJitter percent off it
    function FangTint(AJitter: Integer; const AOffsets: TFarPlaneOffsets): TColorTint;
  end;

// The "farPlane" section of a level and its layout; absent = no far plane.
// ALevelDir - where the layout lies. A layout that is missing or does not
// read, a layer of an unknown speed, an element without width, a city
// without length, fangs that cannot be scattered, a camera that sees no
// depth and a frame without size or without a camera raise. So do the
// city's life that cannot play: a light of an unknown kind or without a
// box, a clock of fewer ticks than it needs, a paint without width, an
// emblem without parts, lamps or frame beacons without "beacons", an
// emblem without "cityLights", a train without size or speed, of a dwell
// of no ticks or without two stations in the city, and searchlights without
// a level, a tail or an ease, or a lamp whose waves do not turn.
function ReadFarPlane(const ARoot: TJSONObject;
  const ALevelId, ALevelDir: string): TFarPlaneDef;

implementation

uses
  System.Generics.Collections, System.IOUtils, System.Math;

resourcestring
  SFarPlaneNoLayout = 'Level "%s": the layout of its far plane "%s" is missing';
  SFarPlaneBadLayout = 'Level "%s": the layout of its far plane "%s" does not read';
  SFarPlaneBadSpeed = 'Level "%s": far plane layer "%s" takes speed "%s" - '
    + 'ridge, city, tunnel or ground';
  SFarPlaneBadElement = 'Level "%s": far plane element "%s" is %g units wide';
  SFarPlaneNoCity = 'Level "%s": its far plane has no city layer with a length';
  SFarPlaneBadColor = 'Level "%s": far plane colour "%s" is not three bytes';
  SFarPlaneNoFangs = 'Level "%s": the fangs of its far plane have an empty kit';
  SFarPlaneBadFang = 'Level "%s": fang "%s" is %g by %g units';
  SFarPlaneBadRange = 'Level "%s": fangs "%s" takes two numbers, the least first';
  SFarPlaneBadScale = 'Level "%s": fangs "scale" must be above zero';
  SFarPlaneBadCamera = 'Level "%s": the camera of its far plane needs its base line '
    + 'below the horizon and a focal length above zero';
  SFarPlaneBadFrame = 'Level "%s": frame "%s" needs a size, a frequency of 1 '
    + 'or more and a rib above zero';
  SFarPlaneFramesNoCamera = 'Level "%s": its far plane has frames and no camera';
  SFarPlaneBadLightKind = 'Level "%s": a light of piece "%s" is of kind "%s" - '
    + 'window, neon, strip or lamp';
  SFarPlaneBadBox = 'Level "%s": %s needs a box of four numbers, its width and '
    + 'height not below zero';
  SFarPlaneBadTicks = 'Level "%s": "%s" takes two whole numbers, the least first '
    + 'and %d at the least';
  SFarPlaneBadPaint = 'Level "%s": the paint of "%s" needs four numbers and a width '
    + 'above zero';
  SFarPlaneBadEmblem = 'Level "%s": the emblem needs a part at the least, a halo to '
    + 'each part, and a width and an aspect above zero';
  SFarPlaneLampsNoBeacons = 'Level "%s": its city has lamps and no "beacons" to '
    + 'blink them by';
  SFarPlaneFrameNoBeacons = 'Level "%s": frame "%s" has beacons and the far plane '
    + 'no "beacons"';
  SFarPlaneEmblemNoLights = 'Level "%s": its emblem flickers by the signs'' clock '
    + 'and the city has no "cityLights"';
  SFarPlaneBadPair = 'Level "%s": "%s" takes two numbers';
  SFarPlaneBadTrain = 'Level "%s": the train needs a width, a cruise and a push of a '
    + 'tick at the least';
  SFarPlaneTrainStations = 'Level "%s": the train runs between two "%s" of the city, '
    + 'and it has %d';
  SFarPlaneBadSearchlights = 'Level "%s": the searchlights need a level, a tail and a '
    + 'spread above zero and an ease of a tick at the least';
  SFarPlaneBadSearchlight = 'Level "%s": searchlight %d needs two sweeps and two '
    + 'periods above zero';
  SLightOfPiece = 'a light of piece "%s"';
  SEmblemPart = 'emblem part %d';
  SEmblemHalo = 'emblem halo %d';

const
  FullShade = 1.0;
  NoBandStart = -1;
  // The stand's floor: a thing far back on the horizon still rides
  LeastNearness = 0.05;
  // As the stand draws a frame missing them
  DefaultFrequency = 3;
  DefaultRib = 2;

function TFarPlaneSun.ColorAt(ACover: Single): TRgb;
begin
  Result.R := Round(White.R + (Tint.R - White.R) * ACover);
  Result.G := Round(White.G + (Tint.G - White.G) * ACover);
  Result.B := Round(White.B + (Tint.B - White.B) * ACover);
end;

function TFarPlaneDef.Present: Boolean;
begin
  Result := Screen > 0;
end;

function TFarPlaneDef.CityLength: Single;
begin
  Result := 0;
  for var Layer in Layers do
    if Layer.Motion = fmCity then
      Result := Max(Result, Layer.Length);
end;

function TFarPlaneDef.CityElements(const APiece: string): TArray<TFarPlaneElement>;
begin
  Result := [];
  for var Layer in Layers do
    if Layer.Motion = fmCity then
      for var Element in Layer.Elements do
        if Element.Id = APiece then
          Result := Result + [Element];
end;

function TFarPlaneDef.CityPoints(const AOffsets: TFarPlaneOffsets): TArray<TSdlFPoint>;
begin
  Result := [];
  for var Layer in Layers do
  begin
    if Layer.Motion <> fmCity then
      Continue;
    for var Element in Layer.Elements do
    begin
      var Point: TSdlFPoint;
      Point.X := ElementLeft(Layer, Element, AOffsets) + Element.W / 2;
      Point.Y := Element.Y - Element.H / 2;
      if (Point.X >= 0) and (Point.X < ScreenWidth) then
        Result := Result + [Point];
    end;
  end;
end;

function TFarPlaneDef.TunnelEnd: Single;
begin
  Result := 0;
  for var Layer in Layers do
    if Layer.Motion = fmTunnel then
      for var Element in Layer.Elements do
      begin
        var Right: Single := Element.X + Element.W;
        Result := Max(Result, Right);
      end;
end;

// How far inside a span the sun stands, ramped in over TintRamp at each end
function SpanCover(const ASun: TFarPlaneSun; ALeft, AWidth: Double): Single;
begin
  var FromLeftEdge: Double := ASun.X - ALeft;
  var ToRightEdge: Double := ALeft + AWidth - ASun.X;
  Result := EnsureRange(Min(FromLeftEdge, ToRightEdge) / ASun.TintRamp, 0.0, 1.0);
end;

// Deepest of the domes: the sun is as covered as the dome it is furthest
// inside
function TFarPlaneDef.SunCover(const AOffsets: TFarPlaneOffsets): Single;
begin
  Result := 0;
  if Sun.TintRamp <= 0 then
    Exit;
  for var Layer in Layers do
    for var Element in Layer.Elements do
      if Element.TintsSun then
        Result := Max(Result,
          SpanCover(Sun, Element.X - AOffsets[Layer.Motion], Element.W));
  for var Frame in Frames do
    if Frame.TintsSun then
      Result := Max(Result, SpanCover(Sun, Frame.X - AOffsets[fmCity], Frame.W));
end;

function TFarPlaneDef.Nearness(AY: Single): Single;
begin
  if not Camera.Present then
    Exit(1);
  Result := (AY - Camera.Horizon) / (Camera.BaseY - Camera.Horizon);
  if Result < LeastNearness then
    Result := LeastNearness;
end;

function TFarPlaneDef.ElementLeft(const ALayer: TFarPlaneLayer;
  const AElement: TFarPlaneElement; const AOffsets: TFarPlaneOffsets): Double;
begin
  var Offset: Double := AOffsets[ALayer.Motion];
  if ALayer.Motion <> fmCity then
    Exit(AElement.X - Offset);
  var Middle: Double := ScreenWidth / 2;
  var Centre: Double := AElement.X + AElement.W / 2;
  Result := Middle + (Centre - Offset - Middle) * Nearness(AElement.DepthY) - AElement.W / 2;
end;

function TFarPlaneDef.TunnelPassed(const AOffsets: TFarPlaneOffsets): Single;
begin
  var Passed: Double := 1;
  if TunnelEnd > 0 then
    Passed := AOffsets[fmTunnel] / TunnelEnd;
  Result := EnsureRange(Passed, 0.0, 1.0);
end;

function TFarPlaneDef.BandShade(const ABand: TFarPlaneBand;
  const AOffsets: TFarPlaneOffsets): Single;
begin
  Result := ABand.ShadeInTunnel + (1 - ABand.ShadeInTunnel) * TunnelPassed(AOffsets);
end;

function TFarPlaneDef.SpriteName(const AId: string): string;
begin
  Result := SetName + ':' + AId;
end;

function TFarPlaneDef.FangTint(AJitter: Integer;
  const AOffsets: TFarPlaneOffsets): TColorTint;

  function Channel(AInTunnel, AOutside: Byte; APassed: Single): Byte;
  begin
    var Level: Integer := Round(AInTunnel + (AOutside - AInTunnel) * APassed) + AJitter;
    Result := EnsureRange(Level, 0, 100);
  end;

begin
  var Passed := TunnelPassed(AOffsets);
  Result.R := Channel(Fangs.TintInTunnel.R, Fangs.Tint.R, Passed);
  Result.G := Channel(Fangs.TintInTunnel.G, Fangs.Tint.G, Passed);
  Result.B := Channel(Fangs.TintInTunnel.B, Fangs.Tint.B, Passed);
end;

function TFarPlaneFangs.Present: Boolean;
begin
  Result := Length(Kinds) > 0;
end;

function TCityLights.LightsOf(const APiece: string): TArray<TCityLight>;
begin
  for var Own in Pieces do
    if Own.Piece = APiece then
      Exit(Own.Lights);
  Result := [];
end;

function TCityLights.HasLamps: Boolean;
begin
  for var Own in Pieces do
    for var Light in Own.Lights do
      if Light.Kind = lkLamp then
        Exit(True);
  Result := False;
end;

function ParseMotion(const AWord, ALevelId, ALayerId: string): TFarPlaneMotion;
begin
  if AWord = 'ridge' then
    Result := fmRidge
  else if AWord = 'city' then
    Result := fmCity
  else if AWord = 'tunnel' then
    Result := fmTunnel
  else if AWord = 'ground' then
    Result := fmGround
  else
    raise EFarPlaneError.CreateFmt(SFarPlaneBadSpeed, [ALevelId, ALayerId, AWord]);
end;

function ReadColor(const AObj: TJSONObject; const AKey, ALevelId: string): TRgb;
var
  Channels: TJSONArray;
begin
  if not AObj.TryGetValue<TJSONArray>(AKey, Channels) or (Channels.Count <> 3) then
    raise EFarPlaneError.CreateFmt(SFarPlaneBadColor, [ALevelId, AKey]);
  Result.R := EnsureRange(Channels.Items[0].GetValue<Integer>, 0, 255);
  Result.G := EnsureRange(Channels.Items[1].GetValue<Integer>, 0, 255);
  Result.B := EnsureRange(Channels.Items[2].GetValue<Integer>, 0, 255);
end;

function ReadSun(const AObj: TJSONObject; const ALevelId: string): TFarPlaneSun;
begin
  Result.X := AObj.GetValue<Double>('x');
  Result.Y := AObj.GetValue<Double>('y');
  Result.Disc := AObj.GetValue<Double>('disc');
  Result.Halo := AObj.GetValue<Double>('halo');
  Result.White := ReadColor(AObj, 'white', ALevelId);
  Result.Tint := ReadColor(AObj, 'tint', ALevelId);
  Result.TintRamp := AObj.GetValue<Double>('tintRamp', 0);
end;

function ReadSpeeds(const AObj: TJSONObject): TFarPlaneSpeeds;
begin
  Result.TunnelPeak := AObj.GetValue<Double>('tunnelPeak');
  Result.TunnelCruise := AObj.GetValue<Double>('tunnelCruise');
  Result.EaseSec := AObj.GetValue<Double>('easeSec');
  Result.CityShareInTunnel := AObj.GetValue<Double>('cityShareInTunnel');
  Result.CityCruise := AObj.GetValue<Double>('cityCruise');
  Result.CityBrakeZone := AObj.GetValue<Double>('cityBrakeZone');
  Result.CityLeast := AObj.GetValue<Double>('cityLeast');
  Result.RidgeShareOfCity := AObj.GetValue<Double>('ridgeShareOfCity');
  Result.Ground := AObj.GetValue<Double>('ground', 0);
  Result.Fangs := AObj.GetValue<Double>('fangs', 0);
end;

function ReadBand(const ALayer: TJSONObject): TFarPlaneBand;
var
  Obj: TJSONObject;
begin
  Result := Default(TFarPlaneBand);
  Result.From := NoBandStart;
  if not ALayer.TryGetValue<TJSONObject>('band', Obj) then
    Exit;
  Result.Present := True;
  Result.Texture := Obj.GetValue<string>('texture');
  Result.Top := Obj.GetValue<Double>('top');
  Result.Bottom := Obj.GetValue<Double>('bottom');
  Result.FadeTop := Obj.GetValue<Double>('fadeTop', 0);
  Result.From := Obj.GetValue<Double>('from', NoBandStart);
  Result.FeatherLeft := Obj.GetValue<Double>('featherLeft', 0);
  Result.ShadeInTunnel := EnsureRange(Obj.GetValue<Double>('shadeInTunnel', FullShade),
    0.0, 1.0);
end;

function ReadPaint(const AObj: TJSONObject; const AId, ALevelId: string): TElementPaint;
var
  Numbers: TJSONArray;
begin
  Result := Default(TElementPaint);
  if not AObj.TryGetValue<TJSONArray>('paint', Numbers) then
    Exit;
  if Numbers.Count <> 4 then
    raise EFarPlaneError.CreateFmt(SFarPlaneBadPaint, [ALevelId, AId]);
  Result.Present := True;
  Result.U := Numbers.Items[0].GetValue<Double>;
  Result.V := Numbers.Items[1].GetValue<Double>;
  Result.W := Numbers.Items[2].GetValue<Double>;
  Result.Alpha := EnsureRange(Numbers.Items[3].GetValue<Double>, 0.0, 1.0);
  if Result.W <= 0 then
    raise EFarPlaneError.CreateFmt(SFarPlaneBadPaint, [ALevelId, AId]);
end;

function ReadElement(const AObj: TJSONObject; const ALevelId: string): TFarPlaneElement;
begin
  Result.Id := AObj.GetValue<string>('id');
  Result.X := AObj.GetValue<Double>('x');
  Result.Y := AObj.GetValue<Double>('y');
  Result.W := AObj.GetValue<Double>('w');
  Result.H := AObj.GetValue<Double>('h', 0);
  if Result.W <= 0 then
    raise EFarPlaneError.CreateFmt(SFarPlaneBadElement, [ALevelId, Result.Id, Result.W]);
  Result.DepthY := AObj.GetValue<Double>('groundY', Result.Y);
  Result.Shade := EnsureRange(AObj.GetValue<Double>('shade', FullShade), 0.0, 1.0);
  Result.TintsSun := AObj.GetValue<Boolean>('tintsSun', False);
  Result.FeatherLeft := AObj.GetValue<Double>('featherLeft', 0);
  Result.Mirror := AObj.GetValue<Boolean>('mirror', False);
  Result.Backdrop := AObj.GetValue<string>('existing', '') <> '';
  Result.Paint := ReadPaint(AObj, Result.Id, ALevelId);
end;

function ReadLayer(const AObj: TJSONObject; const ALevelId: string): TFarPlaneLayer;
var
  Items: TJSONArray;
begin
  Result.Id := AObj.GetValue<string>('id');
  Result.Motion := ParseMotion(AObj.GetValue<string>('speed'), ALevelId, Result.Id);
  Result.Length := AObj.GetValue<Double>('length', 0);
  Result.Band := ReadBand(AObj);
  Result.Elements := [];
  if AObj.TryGetValue<TJSONArray>('elements', Items) then
    for var Item in Items do
      Result.Elements := Result.Elements + [ReadElement(Item as TJSONObject, ALevelId)];
end;

procedure ReadRange(const AObj: TJSONObject; const AKey, ALevelId: string;
  out ALeast, AMost: Single);
var
  Pair: TJSONArray;
begin
  if not AObj.TryGetValue<TJSONArray>(AKey, Pair) or (Pair.Count <> 2) then
    raise EFarPlaneError.CreateFmt(SFarPlaneBadRange, [ALevelId, AKey]);
  ALeast := Pair.Items[0].GetValue<Double>;
  AMost := Pair.Items[1].GetValue<Double>;
  if ALeast > AMost then
    raise EFarPlaneError.CreateFmt(SFarPlaneBadRange, [ALevelId, AKey]);
end;

function ReadFangKind(const AObj: TJSONObject; const ALevelId: string): TFangKind;
begin
  Result.Sprite := AObj.GetValue<string>('sprite');
  Result.W := AObj.GetValue<Double>('w', 0);
  Result.H := AObj.GetValue<Double>('h', 0);
  Result.Tall := AObj.GetValue<Boolean>('tall', False);
  if (Result.W <= 0) or (Result.H <= 0) then
    raise EFarPlaneError.CreateFmt(SFarPlaneBadFang,
      [ALevelId, Result.Sprite, Result.W, Result.H]);
end;

function ReadFangs(const ARoot: TJSONObject; const ALevelId: string): TFarPlaneFangs;
var
  Obj: TJSONObject;
  Kit: TJSONArray;
begin
  Result := Default(TFarPlaneFangs);
  if not ARoot.TryGetValue<TJSONObject>('fangs', Obj) then
    Exit;
  if Obj.TryGetValue<TJSONArray>('kit', Kit) then
    for var Item in Kit do
      Result.Kinds := Result.Kinds + [ReadFangKind(Item as TJSONObject, ALevelId)];
  if not Result.Present then
    raise EFarPlaneError.CreateFmt(SFarPlaneNoFangs, [ALevelId]);
  ReadRange(Obj, 'scale', ALevelId, Result.ScaleLeast, Result.ScaleMost);
  if Result.ScaleLeast <= 0 then
    raise EFarPlaneError.CreateFmt(SFarPlaneBadScale, [ALevelId]);
  ReadRange(Obj, 'gap', ALevelId, Result.GapLeast, Result.GapMost);
  if Result.GapLeast < 0 then
    raise EFarPlaneError.CreateFmt(SFarPlaneBadRange, [ALevelId, 'gap']);
  ReadRange(Obj, 'lowTop', ALevelId, Result.LowTopHighest, Result.LowTopLowest);
  ReadRange(Obj, 'tallTop', ALevelId, Result.TallTopHighest, Result.TallTopLowest);
  Result.TallShare := EnsureRange(Obj.GetValue<Double>('tallShare', 0), 0.0, 1.0);
  Result.TintInTunnel := ReadTint(Obj, 'fangs', 'tintInTunnel');
  Result.Tint := ReadTint(Obj, 'fangs');
  Result.TintJitter := Obj.GetValue<Integer>('tintJitter', 0);
end;

function ReadCamera(const ARoot: TJSONObject; const ALevelId: string): TFarPlaneCamera;
var
  Obj: TJSONObject;
begin
  Result := Default(TFarPlaneCamera);
  if not ARoot.TryGetValue<TJSONObject>('camera', Obj) then
    Exit;
  Result.Present := True;
  Result.Horizon := Obj.GetValue<Double>('horizon');
  Result.BaseY := Obj.GetValue<Double>('baseY');
  Result.Focal := Obj.GetValue<Double>('focal');
  if (Result.BaseY <= Result.Horizon) or (Result.Focal <= 0) then
    raise EFarPlaneError.CreateFmt(SFarPlaneBadCamera, [ALevelId]);
end;

function ReadFrame(const AObj: TJSONObject; const ALevelId: string): TDomeFrame;
begin
  Result.Id := AObj.GetValue<string>('id');
  Result.X := AObj.GetValue<Double>('x');
  Result.W := AObj.GetValue<Double>('w', 0);
  Result.H := AObj.GetValue<Double>('h', 0);
  Result.Frequency := AObj.GetValue<Integer>('frequency', DefaultFrequency);
  Result.Rib := AObj.GetValue<Double>('rib', DefaultRib);
  Result.TintsSun := AObj.GetValue<Boolean>('tintsSun', False);
  var Above: TJSONValue := AObj.GetValue('beaconsAbove');
  Result.Beacons := Above <> nil;
  Result.BeaconsAbove := 0;
  if Result.Beacons then
    Result.BeaconsAbove := Above.GetValue<Double>;
  var HasSize := (Result.W > 0) and (Result.H > 0);
  if not HasSize or (Result.Frequency < 1) or (Result.Rib <= 0) then
    raise EFarPlaneError.CreateFmt(SFarPlaneBadFrame, [ALevelId, Result.Id]);
end;

function ReadFrames(const ARoot: TJSONObject; const ALevelId: string): TArray<TDomeFrame>;
var
  Obj: TJSONObject;
  Items: TJSONArray;
begin
  Result := [];
  if ARoot.TryGetValue<TJSONObject>('frames', Obj) and
    Obj.TryGetValue<TJSONArray>('items', Items) then
    for var Item in Items do
      Result := Result + [ReadFrame(Item as TJSONObject, ALevelId)];
end;

procedure ReadPair(const AObj: TJSONObject; const AKey, ALevelId: string;
  out AFirst, ASecond: Single);
var
  Pair: TJSONArray;
begin
  if not AObj.TryGetValue<TJSONArray>(AKey, Pair) or (Pair.Count <> 2) then
    raise EFarPlaneError.CreateFmt(SFarPlaneBadPair, [ALevelId, AKey]);
  AFirst := Pair.Items[0].GetValue<Double>;
  ASecond := Pair.Items[1].GetValue<Double>;
end;

// A range of whole numbers, ALeastAllowed at the least: a clock of fewer
// ticks would never end its span or would divide by nothing
procedure ReadWholeRange(const AObj: TJSONObject; const AKey, ALevelId: string;
  ALeastAllowed: Integer; out ALeast, AMost: Integer);
var
  Pair: TJSONArray;
begin
  if not AObj.TryGetValue<TJSONArray>(AKey, Pair) or (Pair.Count <> 2) then
    raise EFarPlaneError.CreateFmt(SFarPlaneBadTicks, [ALevelId, AKey, ALeastAllowed]);
  ALeast := Pair.Items[0].GetValue<Integer>;
  AMost := Pair.Items[1].GetValue<Integer>;
  if (ALeast < ALeastAllowed) or (ALeast > AMost) then
    raise EFarPlaneError.CreateFmt(SFarPlaneBadTicks, [ALevelId, AKey, ALeastAllowed]);
end;

function ReadBox(const AValue: TJSONValue; const AWhat, ALevelId: string): TPictureBox;
begin
  if not (AValue is TJSONArray) or (TJSONArray(AValue).Count <> 4) then
    raise EFarPlaneError.CreateFmt(SFarPlaneBadBox, [ALevelId, AWhat]);
  var Numbers := TJSONArray(AValue);
  Result.U := Numbers.Items[0].GetValue<Double>;
  Result.V := Numbers.Items[1].GetValue<Double>;
  Result.W := Numbers.Items[2].GetValue<Double>;
  Result.H := Numbers.Items[3].GetValue<Double>;
  if (Result.W < 0) or (Result.H < 0) then
    raise EFarPlaneError.CreateFmt(SFarPlaneBadBox, [ALevelId, AWhat]);
end;

function ParseLightKind(const AWord, ALevelId, APiece: string): TCityLightKind;
begin
  if AWord = 'window' then
    Result := lkWindow
  else if AWord = 'neon' then
    Result := lkNeon
  else if AWord = 'strip' then
    Result := lkStrip
  else if AWord = 'lamp' then
    Result := lkLamp
  else
    raise EFarPlaneError.CreateFmt(SFarPlaneBadLightKind, [ALevelId, APiece, AWord]);
end;

function ReadLight(const AObj: TJSONObject; const APiece, ALevelId: string): TCityLight;
begin
  Result.Kind := ParseLightKind(AObj.GetValue<string>('kind'), ALevelId, APiece);
  Result.Box := ReadBox(AObj.GetValue('box'), Format(SLightOfPiece, [APiece]), ALevelId);
  Result.Color := ReadColor(AObj, 'color', ALevelId);
end;

function ReadGlowLook(const AObj: TJSONObject; const ALevelId: string): TCityGlowLook;
begin
  ReadPair(AObj, 'core', ALevelId, Result.CoreW, Result.CoreH);
  Result.CoreLevel := AObj.GetValue<Double>('coreLevel');
  ReadPair(AObj, 'halo', ALevelId, Result.HaloW, Result.HaloH);
  Result.HaloPad := AObj.GetValue<Double>('haloPad', 0);
  Result.HaloLevel := AObj.GetValue<Double>('haloLevel');
end;

function ReadFlicker(const AObj: TJSONObject; const ALevelId: string): TCityFlicker;
begin
  Result.BreathDepth := AObj.GetValue<Double>('breathDepth');
  ReadWholeRange(AObj, 'breathTicks', ALevelId, 1, Result.BreathLeast, Result.BreathMost);
  ReadWholeRange(AObj, 'windowTicks', ALevelId, 1, Result.WindowLeast, Result.WindowMost);
  Result.FaultShare := AObj.GetValue<Double>('faultShare');
  ReadWholeRange(AObj, 'flips', ALevelId, 0, Result.FlipsLeast, Result.FlipsMost);
  ReadWholeRange(AObj, 'flipTicks', ALevelId, 1, Result.FlipLeast, Result.FlipMost);
  Result.FaultLow := AObj.GetValue<Double>('faultLow');
end;

function ReadCityLights(const ARoot: TJSONObject; const ALevelId: string): TCityLights;
const
  LookKeys: array [TCityGlowKind] of string = ('window', 'neon', 'strip');
var
  Obj, PiecesObj: TJSONObject;
begin
  Result := Default(TCityLights);
  if not ARoot.TryGetValue<TJSONObject>('cityLights', Obj) then
    Exit;
  Result.Present := True;
  for var Kind := Low(TCityGlowKind) to High(TCityGlowKind) do
    Result.Looks[Kind] := ReadGlowLook(Obj.GetValue<TJSONObject>(LookKeys[Kind]), ALevelId);
  Result.Flicker := ReadFlicker(Obj.GetValue<TJSONObject>('flicker'), ALevelId);

  var WindowsObj := Obj.GetValue<TJSONObject>('windows');
  Result.Windows.OnShare := WindowsObj.GetValue<Double>('onShare');
  ReadWholeRange(WindowsObj, 'spanTicks', ALevelId, 1, Result.Windows.SpanLeast,
    Result.Windows.SpanMost);

  if not Obj.TryGetValue<TJSONObject>('pieces', PiecesObj) then
    Exit;
  for var Pair in PiecesObj do
  begin
    var Own: TCityPieceLights;
    Own.Piece := Pair.JsonString.Value;
    Own.Lights := [];
    for var Item in Pair.JsonValue as TJSONArray do
      Own.Lights := Own.Lights + [ReadLight(Item as TJSONObject, Own.Piece, ALevelId)];
    Result.Pieces := Result.Pieces + [Own];
  end;
end;

function ReadEmblem(const ARoot: TJSONObject; const ALevelId: string): TCityEmblem;
var
  Obj: TJSONObject;
  Parts, Halos: TJSONArray;
begin
  Result := Default(TCityEmblem);
  Parts := nil;
  Halos := nil;
  if not ARoot.TryGetValue<TJSONObject>('emblem', Obj) then
    Exit;
  Result.Present := True;
  Result.Piece := Obj.GetValue<string>('on');
  ReadPair(Obj, 'at', ALevelId, Result.AtU, Result.AtV);
  Result.W := Obj.GetValue<Double>('w');
  Result.Aspect := Obj.GetValue<Double>('aspect');
  Result.Shade := EnsureRange(Obj.GetValue<Double>('shade', FullShade), 0.0, 1.0);
  Result.Color := ReadColor(Obj, 'color', ALevelId);
  Result.CoreLevel := Obj.GetValue<Double>('coreLevel');
  Result.HaloLevel := Obj.GetValue<Double>('haloLevel');
  Result.FaultShare := Obj.GetValue<Double>('faultShare');
  ReadWholeRange(Obj, 'relightTicks', ALevelId, 1, Result.RelightLeast, Result.RelightMost);
  ReadWholeRange(Obj, 'darkTicks', ALevelId, 0, Result.DarkLeast, Result.DarkMost);
  ReadWholeRange(Obj, 'partTicks', ALevelId, 0, Result.PartLeast, Result.PartMost);

  var HasParts := Obj.TryGetValue<TJSONArray>('parts', Parts) and
    Obj.TryGetValue<TJSONArray>('halos', Halos);
  if not HasParts or (Parts.Count = 0) or (Halos.Count <> Parts.Count) or
    (Result.W <= 0) or (Result.Aspect <= 0) then
    raise EFarPlaneError.CreateFmt(SFarPlaneBadEmblem, [ALevelId]);
  for var i := 0 to Parts.Count - 1 do
  begin
    Result.Parts := Result.Parts + [ReadBox(Parts.Items[i], Format(SEmblemPart, [i + 1]),
      ALevelId)];
    Result.Halos := Result.Halos + [ReadBox(Halos.Items[i], Format(SEmblemHalo, [i + 1]),
      ALevelId)];
  end;
end;

function ReadBeacons(const ARoot: TJSONObject; const ALevelId: string): TCityBeacons;
var
  Obj: TJSONObject;
begin
  Result := Default(TCityBeacons);
  if not ARoot.TryGetValue<TJSONObject>('beacons', Obj) then
    Exit;
  Result.Present := True;
  Result.Color := ReadColor(Obj, 'color', ALevelId);
  Result.Size := Obj.GetValue<Double>('size');
  Result.Halo := Obj.GetValue<Double>('halo');
  Result.GlowLevel := Obj.GetValue<Double>('glowLevel');
  Result.FlashLevel := Obj.GetValue<Double>('flashLevel');
  Result.FlashTicks := Obj.GetValue<Integer>('flashTicks');
  ReadWholeRange(Obj, 'periodTicks', ALevelId, 1, Result.PeriodLeast, Result.PeriodMost);
end;

function ReadTrain(const ARoot: TJSONObject; const ALevelId: string): TCityTrain;
var
  Obj: TJSONObject;
begin
  Result := Default(TCityTrain);
  if not ARoot.TryGetValue<TJSONObject>('train', Obj) then
    Exit;
  Result.Present := True;
  Result.Piece := Obj.GetValue<string>('piece');
  Result.Station := Obj.GetValue<string>('station');
  Result.Mouth := Obj.GetValue<Double>('mouth');
  Result.W := Obj.GetValue<Double>('w', 0);
  Result.Y := Obj.GetValue<Double>('y');
  Result.Shade := EnsureRange(Obj.GetValue<Double>('shade', FullShade), 0.0, 1.0);
  Result.Inside := Obj.GetValue<Double>('inside', 0);
  Result.Cruise := Obj.GetValue<Double>('cruise', 0);
  Result.AccelTicks := Obj.GetValue<Integer>('accelTicks', 0);
  ReadWholeRange(Obj, 'dwellTicks', ALevelId, 1, Result.DwellLeast, Result.DwellMost);
  if (Result.W <= 0) or (Result.Cruise <= 0) or (Result.AccelTicks < 1) then
    raise EFarPlaneError.CreateFmt(SFarPlaneBadTrain, [ALevelId]);
end;

function ReadSearchlightLamp(const AObj: TJSONObject; AIndex: Integer;
  const ALevelId: string): TSearchlightLamp;
var
  Sweep, Periods: TJSONArray;
begin
  Result.X := AObj.GetValue<Double>('x');
  Result.Y := AObj.GetValue<Double>('y');
  Result.Lift := AObj.GetValue<Double>('lift', 0);
  Result.Aim := AObj.GetValue<Double>('aim');
  var HasWaves := AObj.TryGetValue<TJSONArray>('sweep', Sweep) and
    AObj.TryGetValue<TJSONArray>('periodTicks', Periods) and
    (Sweep.Count = Length(Result.Waves)) and (Periods.Count = Length(Result.Waves));
  if not HasWaves then
    raise EFarPlaneError.CreateFmt(SFarPlaneBadSearchlight, [ALevelId, AIndex]);
  for var i := 0 to High(Result.Waves) do
  begin
    Result.Waves[i].Degrees := Sweep.Items[i].GetValue<Double>;
    Result.Waves[i].PeriodTicks := Periods.Items[i].GetValue<Double>;
    if Result.Waves[i].PeriodTicks <= 0 then
      raise EFarPlaneError.CreateFmt(SFarPlaneBadSearchlight, [ALevelId, AIndex]);
  end;
end;

function ReadSearchlightPause(const AObj: TJSONObject;
  const ALevelId: string): TSearchlightPause;
begin
  ReadWholeRange(AObj, 'windowTicks', ALevelId, 1, Result.WindowLeast, Result.WindowMost);
  ReadWholeRange(AObj, 'holdTicks', ALevelId, 0, Result.HoldLeast, Result.HoldMost);
  Result.Share := EnsureRange(AObj.GetValue<Double>('share', 0), 0.0, 1.0);
  Result.EaseTicks := AObj.GetValue<Integer>('easeTicks', 0);
  if Result.EaseTicks < 1 then
    raise EFarPlaneError.CreateFmt(SFarPlaneBadSearchlights, [ALevelId]);
end;

function ReadSearchlights(const ARoot: TJSONObject;
  const ALevelId: string): TCitySearchlights;
var
  Obj: TJSONObject;
  Items: TJSONArray;
begin
  Result := Default(TCitySearchlights);
  if not ARoot.TryGetValue<TJSONObject>('searchlights', Obj) then
    Exit;
  Result.Present := True;
  Result.Color := ReadColor(Obj, 'color', ALevelId);
  Result.Level := Obj.GetValue<Double>('level');
  Result.GlassLevel := Obj.GetValue<Double>('glassLevel');
  Result.TailShare := Obj.GetValue<Double>('tailShare');
  Result.Tail := Obj.GetValue<Double>('tail', 0);
  Result.RootHalf := Obj.GetValue<Double>('rootHalf');
  Result.Spread := Obj.GetValue<Double>('spread', 0);
  Result.SpotSize := Obj.GetValue<Double>('spotSize');
  Result.SpotLevel := Obj.GetValue<Double>('spotLevel');
  Result.GlintSize := Obj.GetValue<Double>('glintSize');
  Result.GlintLevel := Obj.GetValue<Double>('glintLevel');
  if (Result.Level <= 0) or (Result.Tail <= 0) or (Result.Spread <= 0) then
    raise EFarPlaneError.CreateFmt(SFarPlaneBadSearchlights, [ALevelId]);
  Result.Pause := ReadSearchlightPause(Obj.GetValue<TJSONObject>('pause'), ALevelId);
  if Obj.TryGetValue<TJSONArray>('items', Items) then
    for var i := 0 to Items.Count - 1 do
      Result.Lamps := Result.Lamps +
        [ReadSearchlightLamp(Items.Items[i] as TJSONObject, i, ALevelId)];
end;

// The parts of the city's life lean on each other: a lamp blinks as the
// beacons do, the emblem flickers by the signs' clock
procedure CheckCityLife(const ADef: TFarPlaneDef; const ALevelId: string);
begin
  if ADef.Lights.HasLamps and not ADef.Beacons.Present then
    raise EFarPlaneError.CreateFmt(SFarPlaneLampsNoBeacons, [ALevelId]);
  for var Frame in ADef.Frames do
    if Frame.Beacons and not ADef.Beacons.Present then
      raise EFarPlaneError.CreateFmt(SFarPlaneFrameNoBeacons, [ALevelId, Frame.Id]);
  if ADef.Emblem.Present and not ADef.Lights.Present then
    raise EFarPlaneError.CreateFmt(SFarPlaneEmblemNoLights, [ALevelId]);
  if not ADef.Train.Present then
    Exit;
  var Stations := Length(ADef.CityElements(ADef.Train.Station));
  if Stations <> 2 then
    raise EFarPlaneError.CreateFmt(SFarPlaneTrainStations,
      [ALevelId, ADef.Train.Station, Stations]);
end;

function ReadLayout(const AFileName, ALevelId: string): TFarPlaneDef;
begin
  Result := Default(TFarPlaneDef);
  if not FileExists(AFileName) then
    raise EFarPlaneError.CreateFmt(SFarPlaneNoLayout, [ALevelId, AFileName]);
  var Root := TJSONObject.ParseJSONValue(
    TFile.ReadAllText(AFileName, TEncoding.UTF8)) as TJSONObject;
  if Root = nil then
    raise EFarPlaneError.CreateFmt(SFarPlaneBadLayout, [ALevelId, AFileName]);
  try
    var ScreenObj := Root.GetValue<TJSONObject>('screen');
    Result.ScreenWidth := ScreenObj.GetValue<Double>('w');
    Result.ScreenHeight := ScreenObj.GetValue<Double>('h');
    Result.Sun := ReadSun(Root.GetValue<TJSONObject>('sun'), ALevelId);
    Result.Speeds := ReadSpeeds(Root.GetValue<TJSONObject>('speeds'));
    Result.Camera := ReadCamera(Root, ALevelId);
    Result.Frames := ReadFrames(Root, ALevelId);
    for var Item in Root.GetValue<TJSONArray>('layers') do
      Result.Layers := Result.Layers + [ReadLayer(Item as TJSONObject, ALevelId)];
    Result.Fangs := ReadFangs(Root, ALevelId);
    Result.Lights := ReadCityLights(Root, ALevelId);
    Result.Emblem := ReadEmblem(Root, ALevelId);
    Result.Beacons := ReadBeacons(Root, ALevelId);
    Result.Train := ReadTrain(Root, ALevelId);
    Result.Searchlights := ReadSearchlights(Root, ALevelId);
  finally
    Root.Free;
  end;
  if Result.CityLength <= 0 then
    raise EFarPlaneError.CreateFmt(SFarPlaneNoCity, [ALevelId]);
  if (Length(Result.Frames) > 0) and not Result.Camera.Present then
    raise EFarPlaneError.CreateFmt(SFarPlaneFramesNoCamera, [ALevelId]);
  CheckCityLife(Result, ALevelId);
end;

function ReadFarPlane(const ARoot: TJSONObject;
  const ALevelId, ALevelDir: string): TFarPlaneDef;
var
  Section: TJSONObject;
begin
  Result := Default(TFarPlaneDef);
  if not ARoot.TryGetValue<TJSONObject>('farPlane', Section) then
    Exit;
  var LayoutFile := Section.GetValue<string>('layout');
  Result := ReadLayout(TPath.Combine(ALevelDir, LayoutFile), ALevelId);
  Result.Screen := Section.GetValue<Integer>('screen');
  Result.SetName := TPath.GetFileNameWithoutExtension(LayoutFile);
end;

end.
