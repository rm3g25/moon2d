{
  Render.FarPlane - draws the far plane of a chase (Levels.FarPlane) where
  its offsets have taken it: the black sky, the sun, then the layers back
  to front, each its band repeated across and its elements on it.

  The sun is code: a disc and a halo of two glows added over the black,
  white while nothing stands before it, turned toward the tint while a
  dome marked tintsSun does. The layers in front hide it where they are
  solid: it comes out from behind the cliff by itself.

  Every picture is a strip of triangles (SDL_RenderGeometry): the alpha of
  its corners fades a band's top in, a band's start in, and the cliff's left
  end into the wall it continues, and their colour is the element's shade -
  the vertices carry it, so no colour mod of the shared cache is touched.

  The city has a depth: a building rides by its feet, the nearer the
  faster (TFarPlaneDef.ElementLeft). Its dome frames are code
  (Render.DomeFrames): their shadows on the crater floor and their far half
  go under the buildings, their near half and the sun's glare over them.
  The shadows run on over the near ground, from the top of its band down.

  The city lives (Levels.CityLife, on the far plane's clock): after each
  building its paint - the emblem worn on its wall, at its shade - then its
  lights added over it, a point glow over a sign or a lamp, a beam over a
  strip or a window, then the TeK emblem if it stands on that building; the
  frames' beacons go with their halves. The glows are Render.Glow's, the
  emblem's pictures the set's (made by tools/chase/make_emblem.py).

  While the screen's own backdrop covers the whole screen, nothing behind
  its layer is drawn: the arena before the chase costs one picture more,
  the cliff's end over the wall.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Render.FarPlane;
{$I ..\Moon2D.inc}

interface

uses
  Sdl2.Core, Render.Brush, Render.Sprites, Levels.FarPlane, Levels.Dynamics,
  Render.DomeFrames;

type
  TFarPlanePainter = class
  private type
    // How much of its alpha each edge of a quad keeps, 0..1; a corner keeps
    // the product of its two edges
    TQuadAlpha = record
      Left, Right, Top, Bottom: Single;
    end;
    // One turn of a band's texture on the screen, and where the band
    // starts there; NoStart - it runs the whole width
    TBandTurn = record
      Layer: Integer;
      Color: TSdlColor;
      Left, Width: Double;
      Start: Double;
    end;
  private
    FRenderer: PSdlRenderer;
    FDef: TFarPlaneDef;
    // By layer; nil for a layer without a band
    FBands: TArray<PSdlTexture>;
    // By layer, by element; nil for the screen's own backdrop
    FPictures: TArray<TArray<PSdlTexture>>;
    FPointGlow: PSdlTexture;
    FDiscGlow: PSdlTexture;
    FBeamGlow: PSdlTexture;
    // The set's; nil without an emblem or without paint
    FEmblemMetal: PSdlTexture;
    FEmblemTubes, FEmblemHalos: TArray<PSdlTexture>;
    FPaint: PSdlTexture;
    FFrames: TDomeFrames;
    FFramePainter: TDomeFramePainter;
    // The frames at this frame's ride of the city: the city's layer and the
    // near ground's both draw from it
    FFrameView: TFrameView;
    FVertices: TArray<TSdlVertex>;
    FIndices: TArray<Integer>;
    procedure AddQuad(const APlace, ASource: TSdlFRect; AColor: TSdlColor;
      const AAlpha: TQuadAlpha);
    procedure AddBandPiece(const ATurn: TBandTurn; ALeft, ARight: Double);
    procedure Flush(ATexture: PSdlTexture);
    function FirstSeenLayer(const AOffsets: TFarPlaneOffsets): Integer;
    procedure DrawSky;
    procedure DrawSun(const AOffsets: TFarPlaneOffsets);
    procedure DrawBand(ALayer: Integer; const AOffsets: TFarPlaneOffsets);
    // False - it stands off the screen, nothing drawn
    function DrawElement(const AElement: TFarPlaneElement;
      ATexture: PSdlTexture; ALeft: Double; AColor: TSdlColor): Boolean;
    procedure DrawFrameShadows(ATop, ABottom: Single);
    procedure LoadEmblem(ACache: TSpriteCache);
    procedure GlowInto(ATexture: PSdlTexture; const APlace: TSdlFRect;
      const AColor: TRgb; ALevel: Single);
    procedure GlowAround(ATexture: PSdlTexture; ACentreX, ACentreY, AWidth,
      AHeight: Single; const AColor: TRgb; ALevel: Single);
    procedure DrawBeacon(const AColor: TRgb; AX, AY, ANearness, ALevel: Single);
    procedure DrawBeacons(const ABeacons: TArray<TFrameBeacon>; ATick: Integer);
    function LightLevel(AKind: TCityLightKind; ASeed: Cardinal; ATick: Integer): Double;
    // ALeft, AHeight - where the building was drawn, units
    procedure DrawLight(const AElement: TFarPlaneElement; const ALight: TCityLight;
      ASeed: Cardinal; ALeft, AHeight: Double; ATick: Integer);
    procedure DrawPaint(const AElement: TFarPlaneElement; ALeft, AHeight: Double);
    procedure DrawEmblem(const AElement: TFarPlaneElement; ALeft, AHeight: Double;
      ATick: Integer);
    // AIndex - the building's place in the city's layer: the seed of its
    // lights' clocks
    procedure DrawLife(const AElement: TFarPlaneElement; AIndex: Integer;
      ALeft, AHeight: Double; ATick: Integer);
    procedure DrawLayer(ALayer: Integer; const AOffsets: TFarPlaneOffsets;
      ATick: Integer; const ABackdrop: TBackdropView);
  public
    // Resolves every picture now, so a sprite the set lacks raises at
    // level load. ACache - the level's object art, with the far plane's set
    // attached; it must outlive the painter.
    constructor Create(ARenderer: PSdlRenderer; ACache: TSpriteCache;
      const ADef: TFarPlaneDef);
    destructor Destroy; override;
    // ATick - the far plane's clock (TFarPlane.Clock); ABackdrop - the
    // screen's own, drawn where its element rides
    procedure Draw(const AOffsets: TFarPlaneOffsets; ATick: Integer;
      const ABackdrop: TBackdropView);
  end;

implementation

uses
  System.SysUtils, System.Math, Levels.Tint, Render.Glow, Levels.CityLife;

const
  PointGlowSide = 128;
  DiscGlowSide = 64;
  // The stand's glows are drawn at this size
  BeamGlowSide = 128;
  // A beacon's halo burns at half its level
  BeaconHaloShare = 0.5;
  // The pictures tools/chase/make_emblem.py puts into the set
  EmblemMetalSprite = 'tek-emblem';
  EmblemTubeSprite = 'tek-%d';
  EmblemHaloSprite = 'tek-%d-halo';
  EmblemPaintSprite = 'tek-paint';
  // The halo is two glows fitted to the stand's radial gradient (0.55 at
  // the disc's edge, 0.16 a quarter of the way out, nothing at the halo's
  // rim): a core and a wide glare, sized by the halo's radius
  HaloCoreSize = 0.92;
  HaloCoreLevel = 0.38;
  HaloGlareSize = 3.1;
  HaloGlareLevel = 0.19;
  SolidAlpha = 255;
  NoStart = -MaxInt;
  SkyBlack: TSdlColor = (R: 0; G: 0; B: 0; A: 255);

function TextureAspect(ATexture: PSdlTexture): Single;
var
  Width, Height: Integer;
begin
  SDL_QueryTexture(ATexture, nil, nil, @Width, @Height);
  Result := Height / Width;
end;

function ShadeColor(AShade: Single): TSdlColor;
begin
  var Level := Round(255 * AShade);
  Result.R := Level;
  Result.G := Level;
  Result.B := Level;
  Result.A := SolidAlpha;
end;

function TintColor(const ATint: TColorTint): TSdlColor;
begin
  Result.R := PercentToColorMod(ATint.R);
  Result.G := PercentToColorMod(ATint.G);
  Result.B := PercentToColorMod(ATint.B);
  Result.A := SolidAlpha;
end;

// A box of a picture laid on a place: ALeft, ATop and the size of the whole
function BoxPlace(const ABox: TPictureBox; ALeft, ATop, AWidth, AHeight: Single): TSdlFRect;
begin
  Result.X := ALeft + ABox.U * AWidth;
  Result.Y := ATop + ABox.V * AHeight;
  Result.W := ABox.W * AWidth;
  Result.H := ABox.H * AHeight;
end;

function QuadAlpha(ALeft, ARight, ATop, ABottom: Single): TFarPlanePainter.TQuadAlpha;
begin
  Result.Left := ALeft;
  Result.Right := ARight;
  Result.Top := ATop;
  Result.Bottom := ABottom;
end;

function FloatRect(AX, AY, AW, AH: Single): TSdlFRect;
begin
  Result.X := AX;
  Result.Y := AY;
  Result.W := AW;
  Result.H := AH;
end;

function HasPaint(const ADef: TFarPlaneDef): Boolean;
begin
  for var Layer in ADef.Layers do
    for var Element in Layer.Elements do
      if Element.Paint.Present then
        Exit(True);
  Result := False;
end;

constructor TFarPlanePainter.Create(ARenderer: PSdlRenderer; ACache: TSpriteCache;
  const ADef: TFarPlaneDef);
begin
  inherited Create;
  FRenderer := ARenderer;
  FDef := ADef;
  SetLength(FBands, Length(FDef.Layers));
  SetLength(FPictures, Length(FDef.Layers));
  for var i := 0 to High(FDef.Layers) do
  begin
    var Layer := FDef.Layers[i];
    if Layer.Band.Present then
    begin
      FBands[i] := ACache.Get(FDef.SpriteName(Layer.Band.Texture));
      // A band fades its top in by the alpha of its corners: an opaque
      // texture would ignore it
      SDL_SetTextureBlendMode(FBands[i], SdlBlendModeBlend);
    end;
    SetLength(FPictures[i], Length(Layer.Elements));
    for var j := 0 to High(Layer.Elements) do
      if not Layer.Elements[j].Backdrop then
        FPictures[i][j] := ACache.Get(FDef.SpriteName(Layer.Elements[j].Id));
  end;
  if FDef.Emblem.Present then
    LoadEmblem(ACache);
  if HasPaint(FDef) then
  begin
    FPaint := ACache.Get(FDef.SpriteName(EmblemPaintSprite));
    SDL_SetTextureScaleMode(FPaint, SdlScaleModeLinear);
  end;
  FPointGlow := CreateGlowShape(ARenderer, gsPoint, PointGlowSide);
  FDiscGlow := CreateGlowShape(ARenderer, gsDisc, DiscGlowSide);
  FBeamGlow := CreateGlowShape(ARenderer, gsBeam, BeamGlowSide);
  FFrames := TDomeFrames.Create(ADef);
  FFramePainter := TDomeFramePainter.Create(ARenderer, ADef.Sun, FPointGlow);
end;

destructor TFarPlanePainter.Destroy;
begin
  // The frame painter borrows the point glow
  FFramePainter.Free;
  FFrames.Free;
  // A sprite the set lacks stops the constructor before the glows exist
  if Assigned(FPointGlow) then
    SDL_DestroyTexture(FPointGlow);
  if Assigned(FDiscGlow) then
    SDL_DestroyTexture(FDiscGlow);
  if Assigned(FBeamGlow) then
    SDL_DestroyTexture(FBeamGlow);
  inherited;
end;

// A picture of the set that is light: added, and filtered when scaled far
// down at the city's distance
procedure MakeLight(ATexture: PSdlTexture);
begin
  SDL_SetTextureBlendMode(ATexture, SdlBlendModeAdd);
  SDL_SetTextureScaleMode(ATexture, SdlScaleModeLinear);
end;

procedure TFarPlanePainter.LoadEmblem(ACache: TSpriteCache);
begin
  FEmblemMetal := ACache.Get(FDef.SpriteName(EmblemMetalSprite));
  SDL_SetTextureScaleMode(FEmblemMetal, SdlScaleModeLinear);
  SetLength(FEmblemTubes, Length(FDef.Emblem.Parts));
  SetLength(FEmblemHalos, Length(FDef.Emblem.Parts));
  for var i := 0 to High(FDef.Emblem.Parts) do
  begin
    FEmblemTubes[i] := ACache.Get(FDef.SpriteName(Format(EmblemTubeSprite, [i + 1])));
    FEmblemHalos[i] := ACache.Get(FDef.SpriteName(Format(EmblemHaloSprite, [i + 1])));
    MakeLight(FEmblemTubes[i]);
    MakeLight(FEmblemHalos[i]);
  end;
end;

procedure TFarPlanePainter.AddQuad(const APlace, ASource: TSdlFRect;
  AColor: TSdlColor; const AAlpha: TQuadAlpha);
const
  // Top left, top right, bottom right, bottom left
  CornerX: array [0..3] of Integer = (0, 1, 1, 0);
  CornerY: array [0..3] of Integer = (0, 0, 1, 1);
  Triangles: array [0..5] of Integer = (0, 1, 2, 0, 2, 3);
begin
  var First := Length(FVertices);
  SetLength(FVertices, First + 4);
  for var i := 0 to 3 do
  begin
    var Across := AAlpha.Left;
    if CornerX[i] = 1 then
      Across := AAlpha.Right;
    var Down := AAlpha.Top;
    if CornerY[i] = 1 then
      Down := AAlpha.Bottom;
    var Vertex: TSdlVertex;
    Vertex.Position.X := APlace.X + APlace.W * CornerX[i];
    Vertex.Position.Y := APlace.Y + APlace.H * CornerY[i];
    Vertex.TexCoord.X := ASource.X + ASource.W * CornerX[i];
    Vertex.TexCoord.Y := ASource.Y + ASource.H * CornerY[i];
    Vertex.Color := AColor;
    Vertex.Color.A := Round(AColor.A * Across * Down);
    FVertices[First + i] := Vertex;
  end;
  for var Corner in Triangles do
    FIndices := FIndices + [First + Corner];
end;

procedure TFarPlanePainter.Flush(ATexture: PSdlTexture);
begin
  if Length(FIndices) > 0 then
    SDL_RenderGeometry(FRenderer, ATexture, @FVertices[0], Length(FVertices),
      @FIndices[0], Length(FIndices));
  FVertices := nil;
  FIndices := nil;
end;

// The frontmost layer whose backdrop covers the whole screen hides all
// behind it, the sky and the sun too; -1 - none does
// The part of a picture from AU, AWidth across, read from the right for one
// drawn mirrored
function Across(const AElement: TFarPlaneElement; AU, AWidth: Single): TSdlFRect;
begin
  Result := FloatRect(AU, 0, AWidth, 1);
  if AElement.Mirror then
    Result := FloatRect(1 - AU, 0, -AWidth, 1);
end;

function TFarPlanePainter.FirstSeenLayer(const AOffsets: TFarPlaneOffsets): Integer;
begin
  for var i := High(FDef.Layers) downto 0 do
  begin
    var Layer := FDef.Layers[i];
    for var Element in Layer.Elements do
    begin
      var Left := Element.X - AOffsets[Layer.Motion];
      if Element.Backdrop and (Left <= 0) and (Left + Element.W >= FDef.ScreenWidth) then
        Exit(i);
    end;
  end;
  Result := -1;
end;

procedure TFarPlanePainter.DrawSky;
begin
  var Whole := FloatRect(0, 0, FDef.ScreenWidth, FDef.ScreenHeight);
  SDL_SetRenderDrawBlendMode(FRenderer, SdlBlendModeNone);
  SDL_SetRenderDrawColor(FRenderer, SkyBlack.R, SkyBlack.G, SkyBlack.B, SkyBlack.A);
  SDL_RenderFillRectF(FRenderer, @Whole);
end;

procedure TFarPlanePainter.DrawSun(const AOffsets: TFarPlaneOffsets);
begin
  var Sun := FDef.Sun;
  var Color := Sun.ColorAt(FDef.SunCover(AOffsets));

  DrawGlow(FRenderer, FPointGlow, Sun.X, Sun.Y, Sun.Halo * HaloGlareSize, Color,
    HaloGlareLevel);
  DrawGlow(FRenderer, FPointGlow, Sun.X, Sun.Y, Sun.Halo * HaloCoreSize, Color,
    HaloCoreLevel);
  DrawGlow(FRenderer, FDiscGlow, Sun.X, Sun.Y, Sun.Disc * 2, Color, 1);
end;

// A piece of one turn of a band, ALeft to ARight on the screen: its top
// faded in when the band fades, its start faded in over the band's feather
procedure TFarPlanePainter.AddBandPiece(const ATurn: TBandTurn; ALeft, ARight: Double);

  function StartShare(AX: Double): Single;
  begin
    var Feather := FDef.Layers[ATurn.Layer].Band.FeatherLeft;
    if (ATurn.Start = NoStart) or (Feather <= 0) then
      Exit(1);
    Result := EnsureRange((AX - ATurn.Start) / Feather, 0.0, 1.0);
  end;

begin
  var Band := FDef.Layers[ATurn.Layer].Band;
  var Height := Band.Bottom - Band.Top;
  var FadeShare: Single := Band.FadeTop / Height;
  if FadeShare > 1 then
    FadeShare := 1;
  var U := (ALeft - ATurn.Left) / ATurn.Width;
  var UWidth := (ARight - ALeft) / ATurn.Width;
  var LeftKeeps := StartShare(ALeft);
  var RightKeeps := StartShare(ARight);
  if FadeShare > 0 then
    AddQuad(FloatRect(ALeft, Band.Top, ARight - ALeft, Band.FadeTop),
      FloatRect(U, 0, UWidth, FadeShare), ATurn.Color,
      QuadAlpha(LeftKeeps, RightKeeps, 0, 1));
  AddQuad(FloatRect(ALeft, Band.Top + Band.FadeTop, ARight - ALeft, Height - Band.FadeTop),
    FloatRect(U, FadeShare, UWidth, 1 - FadeShare), ATurn.Color,
    QuadAlpha(LeftKeeps, RightKeeps, 1, 1));
end;

// One turn of the texture after another from left of the screen, the turn
// under the band's start cut there and cut again where its feather ends
procedure TFarPlanePainter.DrawBand(ALayer: Integer; const AOffsets: TFarPlaneOffsets);
var
  ScreenWidth, Visible, FeatherEnd: Double;
  Turn: TBandTurn;
begin
  var Band := FDef.Layers[ALayer].Band;
  var Texture := FBands[ALayer];
  var Offset: Double := AOffsets[FDef.Layers[ALayer].Motion];
  ScreenWidth := FDef.ScreenWidth;
  Turn.Layer := ALayer;
  Turn.Color := ShadeColor(FDef.BandShade(Band, AOffsets));
  Turn.Width := (Band.Bottom - Band.Top) / TextureAspect(Texture);
  Turn.Start := NoStart;
  Visible := 0;
  FeatherEnd := 0;
  if Band.From >= 0 then
  begin
    Turn.Start := Band.From - Offset;
    Visible := Max(Visible, Turn.Start);
    FeatherEnd := Turn.Start + Band.FeatherLeft;
  end;
  if Visible >= ScreenWidth then
    Exit;

  Turn.Left := -FMod(Offset, Turn.Width);
  if Turn.Left > 0 then
    Turn.Left := Turn.Left - Turn.Width;
  while Turn.Left < ScreenWidth do
  begin
    var Left: Double := Max(Turn.Left, Visible);
    var Right: Double := Min(Turn.Left + Turn.Width, ScreenWidth);
    if (Left < FeatherEnd) and (FeatherEnd < Right) then
    begin
      AddBandPiece(Turn, Left, FeatherEnd);
      AddBandPiece(Turn, FeatherEnd, Right);
    end
    else if Right > Left then
      AddBandPiece(Turn, Left, Right);
    Turn.Left := Turn.Left + Turn.Width;
  end;
  Flush(Texture);
end;

function TFarPlanePainter.DrawElement(const AElement: TFarPlaneElement;
  ATexture: PSdlTexture; ALeft: Double; AColor: TSdlColor): Boolean;
var
  Height, Feather, FeatherShare: Double;
begin
  Result := (ALeft < FDef.ScreenWidth) and (ALeft + AElement.W > 0);
  if not Result then
    Exit;
  Height := AElement.W * TextureAspect(ATexture);
  Feather := Min(Double(AElement.FeatherLeft), Double(AElement.W));
  FeatherShare := Feather / AElement.W;
  var Top := AElement.Y - Height;
  if Feather > 0 then
    AddQuad(FloatRect(ALeft, Top, Feather, Height),
      Across(AElement, 0, FeatherShare), AColor, QuadAlpha(0, 1, 1, 1));
  AddQuad(FloatRect(ALeft + Feather, Top, AElement.W - Feather, Height),
    Across(AElement, FeatherShare, 1 - FeatherShare), AColor, QuadAlpha(1, 1, 1, 1));
  Flush(ATexture);
end;

// The frames' shadows across the screen, between ATop and ABottom
procedure TFarPlanePainter.DrawFrameShadows(ATop, ABottom: Single);
var
  Clip: TSdlRect;
begin
  Clip.X := 0;
  Clip.Y := Round(ATop);
  Clip.W := Round(FDef.ScreenWidth);
  Clip.H := Round(ABottom - ATop);
  FFramePainter.DrawShadows(FFrameView.Shadows, Clip);
end;

procedure TFarPlanePainter.GlowInto(ATexture: PSdlTexture; const APlace: TSdlFRect;
  const AColor: TRgb; ALevel: Single);
begin
  if ALevel > 0 then
    DrawGlowRect(FRenderer, ATexture, APlace, AColor, ALevel);
end;

procedure TFarPlanePainter.GlowAround(ATexture: PSdlTexture; ACentreX, ACentreY,
  AWidth, AHeight: Single; const AColor: TRgb; ALevel: Single);
begin
  GlowInto(ATexture, FloatRect(ACentreX - AWidth / 2, ACentreY - AHeight / 2, AWidth,
    AHeight), AColor, ALevel);
end;

procedure TFarPlanePainter.DrawBeacon(const AColor: TRgb; AX, AY, ANearness,
  ALevel: Single);
begin
  var Halo: Single := FDef.Beacons.Halo * ANearness;
  var Size: Single := FDef.Beacons.Size * ANearness;
  GlowAround(FPointGlow, AX, AY, Halo, Halo, AColor, ALevel * BeaconHaloShare);
  GlowAround(FPointGlow, AX, AY, Size, Size, AColor, ALevel);
end;

procedure TFarPlanePainter.DrawBeacons(const ABeacons: TArray<TFrameBeacon>;
  ATick: Integer);
begin
  for var Beacon in ABeacons do
    DrawBeacon(FDef.Beacons.Color, Beacon.At.X, Beacon.At.Y, Beacon.Nearness,
      BeaconLevel(FDef.Beacons, Beacon.Seed, ATick));
end;

// A strip burns steady
function TFarPlanePainter.LightLevel(AKind: TCityLightKind; ASeed: Cardinal;
  ATick: Integer): Double;
begin
  case AKind of
    lkNeon:
      Result := NeonLevel(FDef.Lights.Flicker, ASeed, ATick, FDef.Lights.Flicker.FaultShare);
    lkWindow:
      Result := WindowLevel(FDef.Lights, ASeed, ATick);
  else
    Result := 1;
  end;
end;

// A lamp blinks as the beacons do; any other light is a core over its box
// and a halo around it
procedure TFarPlanePainter.DrawLight(const AElement: TFarPlaneElement;
  const ALight: TCityLight; ASeed: Cardinal; ALeft, AHeight: Double; ATick: Integer);
begin
  var Box := ALight.Box;
  var Top: Double := AElement.Y - AHeight;
  var Nearness := FDef.Nearness(AElement.DepthY);
  if ALight.Kind = lkLamp then
  begin
    var LampU: Single := Box.U;
    if AElement.Mirror then
      LampU := 1 - Box.U;
    DrawBeacon(ALight.Color, ALeft + LampU * AElement.W, Top + Box.V * AHeight, Nearness,
      BeaconLevel(FDef.Beacons, ASeed, ATick));
    Exit;
  end;

  var Level := LightLevel(ALight.Kind, ASeed, ATick);
  if Level <= 0 then
    Exit;
  var Look := FDef.Lights.Looks[ALight.Kind];
  var U: Single := Box.U;
  if AElement.Mirror then
    U := 1 - Box.U - Box.W;
  var CentreX: Single := ALeft + (U + Box.W / 2) * AElement.W;
  var CentreY: Single := Top + (Box.V + Box.H / 2) * AHeight;
  var Width: Single := Box.W * AElement.W;
  var Height: Single := Box.H * AHeight;
  var Shape := FBeamGlow;
  if ALight.Kind = lkNeon then
    Shape := FPointGlow;
  var Pad: Single := 2 * Look.HaloPad * Nearness;

  GlowAround(Shape, CentreX, CentreY, Width * Look.HaloW + Pad, Height * Look.HaloH + Pad,
    ALight.Color, Look.HaloLevel * Level);
  GlowAround(Shape, CentreX, CentreY, Width * Look.CoreW, Height * Look.CoreH,
    ALight.Color, Look.CoreLevel * Level);
end;

// Lit as its wall is, so at the building's shade; a mirrored building moves
// it and never turns it - the letters read the right way round
procedure TFarPlanePainter.DrawPaint(const AElement: TFarPlaneElement;
  ALeft, AHeight: Double);
begin
  var Paint := AElement.Paint;
  var U: Single := Paint.U;
  if AElement.Mirror then
    U := 1 - Paint.U - Paint.W;
  var Width: Single := Paint.W * AElement.W;
  var Color := ShadeColor(AElement.Shade);
  Color.A := Round(SolidAlpha * Paint.Alpha);

  AddQuad(FloatRect(ALeft + U * AElement.W, AElement.Y - AHeight + Paint.V * AHeight, Width,
    Width * TextureAspect(FPaint)), FloatRect(0, 0, 1, 1), Color, QuadAlpha(1, 1, 1, 1));
  Flush(FPaint);
end;

// It stands on the lower point of its frame - the first part - at the tip
// of the building, as near as the building; it is never mirrored
procedure TFarPlanePainter.DrawEmblem(const AElement: TFarPlaneElement;
  ALeft, AHeight: Double; ATick: Integer);
begin
  var Emblem := FDef.Emblem;
  var Width: Single := Emblem.W * FDef.Nearness(AElement.DepthY);
  var Height: Single := Width * Emblem.Aspect;
  var AtU: Single := Emblem.AtU;
  if AElement.Mirror then
    AtU := 1 - Emblem.AtU;
  var TipX: Single := ALeft + AtU * AElement.W;
  var TipY: Single := AElement.Y - AHeight + Emblem.AtV * AHeight;
  var Frame := Emblem.Parts[0];
  var Left: Single := TipX - (Frame.U + Frame.W / 2) * Width;
  var Top: Single := TipY - (Frame.V + Frame.H) * Height;

  AddQuad(FloatRect(Left, Top, Width, Height), FloatRect(0, 0, 1, 1),
    ShadeColor(Emblem.Shade), QuadAlpha(1, 1, 1, 1));
  Flush(FEmblemMetal);

  for var i := 0 to High(Emblem.Parts) do
  begin
    var Level := EmblemPartLevel(Emblem, FDef.Lights.Flicker, i, ATick);
    GlowInto(FEmblemHalos[i], BoxPlace(Emblem.Halos[i], Left, Top, Width, Height),
      Emblem.Color, Emblem.HaloLevel * Level);
    GlowInto(FEmblemTubes[i], BoxPlace(Emblem.Parts[i], Left, Top, Width, Height),
      Emblem.Color, Emblem.CoreLevel * Level);
  end;
end;

procedure TFarPlanePainter.DrawLife(const AElement: TFarPlaneElement; AIndex: Integer;
  ALeft, AHeight: Double; ATick: Integer);
begin
  if AElement.Paint.Present then
    DrawPaint(AElement, ALeft, AHeight);
  var Lights := FDef.Lights.LightsOf(AElement.Id);
  for var i := 0 to High(Lights) do
    DrawLight(AElement, Lights[i], LightSeed(AIndex, i), ALeft, AHeight, ATick);
  if FDef.Emblem.Present and (AElement.Id = FDef.Emblem.Piece) then
    DrawEmblem(AElement, ALeft, AHeight, ATick);
end;

// The city stands inside its frames: their shadows on its floor and their
// far half before its buildings, their near half and the glare after. The
// shadows run on over the near ground's band: over the sky between its
// crests they fall on the crater floor, which they shade too
procedure TFarPlanePainter.DrawLayer(ALayer: Integer; const AOffsets: TFarPlaneOffsets;
  ATick: Integer; const ABackdrop: TBackdropView);
begin
  var Layer := FDef.Layers[ALayer];
  if Layer.Band.Present then
    DrawBand(ALayer, AOffsets);
  if Layer.Band.Present and (Layer.Motion = fmGround) and FFrames.Present then
    DrawFrameShadows(Layer.Band.Top, FDef.ScreenHeight);

  var Framed := (Layer.Motion = fmCity) and FFrames.Present;
  if Framed then
  begin
    var FloorTop: Single := 0;
    var FloorBottom: Single := FDef.ScreenHeight;
    if Layer.Band.Present then
    begin
      FloorTop := Layer.Band.Top;
      FloorBottom := Layer.Band.Bottom;
    end;
    DrawFrameShadows(FloorTop, FloorBottom);
    FFramePainter.DrawRibs(FFrameView.Far);
    DrawBeacons(FFrameView.FarBeacons, ATick);
  end;

  for var j := 0 to High(Layer.Elements) do
  begin
    var Element := Layer.Elements[j];
    var Left := FDef.ElementLeft(Layer, Element, AOffsets);
    if Element.Backdrop then
    begin
      if ABackdrop.Texture <> nil then
        DrawElement(Element, ABackdrop.Texture, Left, TintColor(ABackdrop.Tint));
      Continue;
    end;
    var Picture := FPictures[ALayer][j];
    var Shown := DrawElement(Element, Picture, Left, ShadeColor(Element.Shade));
    if Shown and (Layer.Motion = fmCity) then
      DrawLife(Element, j, Left, Element.W * TextureAspect(Picture), ATick);
  end;

  if Framed then
  begin
    FFramePainter.DrawRibs(FFrameView.Near);
    DrawBeacons(FFrameView.NearBeacons, ATick);
    FFramePainter.DrawGlare(FDef.SunCover(AOffsets));
  end;
end;

procedure TFarPlanePainter.Draw(const AOffsets: TFarPlaneOffsets; ATick: Integer;
  const ABackdrop: TBackdropView);
begin
  if FFrames.Present then
    FFrameView := FFrames.View(AOffsets[fmCity]);
  var First := FirstSeenLayer(AOffsets);
  if First < 0 then
  begin
    DrawSky;
    DrawSun(AOffsets);
    First := 0;
  end;
  for var i := First to High(FDef.Layers) do
    DrawLayer(i, AOffsets, ATick, ABackdrop);
end;

end.
