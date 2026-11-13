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
  strip or a window, then the TEK emblem if it stands on that building; the
  frames' beacons go with their halves. The glows are Render.Glow's, the
  emblem's pictures the set's (made by tools/chase/make_emblem.py).

  The train rides at its depth among the buildings, where Levels.Monorail
  puts it on the clock with its fraction, and is drawn between the
  stations' mouths only: its picture and its lights are cut there, as it
  goes in.

  The searchlights stand at their lamps' depth among the buildings, where
  Levels.Searchlights points them on the clock with its fraction: a strip
  of triangles along each beam over Render.Glow's beam - Gaussian across,
  flat along - its corners carrying the level, bright inside the dome and
  a faint tail past its glass. After the near ribs, a hot spot where the
  beam leaves the glass and a glint on each near rib it crosses.

  The farm stands under its long dome (Levels.Farm, on the far plane's
  clock): each greenhouse's lit glass - the picture <id>-glow of the set,
  made by tools/chase/make_glow.py - over its shaded picture at its glow's
  level, not shaded; the air of the dome and the floor in front of it as
  strips of triangles whose light lies in their corners, added; the far
  ribs of its dome lit on their inner face. While its dome stands before
  the sun, the sun's glare gives way to the glass (TFarPlaneDef.GlareLevel).

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
  Levels.Monorail, Levels.Searchlights, Levels.Farm, Render.DomeFrames;

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
    // Where on the screen a light is shown, units across
    TScreenSpan = record
      Left, Right: Single;
    end;
    // A point along a beam, units from its lamp, and its level there
    TBeamSample = record
      Distance, Level: Double;
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
    // nil without a train
    FTrain: PSdlTexture;
    FTrainLine: TMonorailLine;
    // The train as a building of the city, for its lights
    FTrainElement: TFarPlaneElement;
    FFrames: TDomeFrames;
    FFramePainter: TDomeFramePainter;
    // The frames at this frame's ride of the city: the city's layer and the
    // near ground's both draw from it
    FFrameView: TFrameView;
    // The searchlights at this frame's clock, and which of them the city's
    // layer has drawn so far
    FBeams: TArray<TSearchlightBeam>;
    FBeamsDrawn: TArray<Boolean>;
    // By element of the city's layer: its lit glass, nil for one without;
    // its height in units
    FGlassPictures: TArray<PSdlTexture>;
    FCityHeights: TArray<Double>;
    // The farm at this frame's clock and ride: the city's layer and the
    // near ground's both draw from it
    FFarm: TFarmView;
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
    procedure GlowWithin(ATexture: PSdlTexture; ACentreX, ACentreY, AWidth,
      AHeight: Single; const AColor: TRgb; ALevel: Single; const ASpan: TScreenSpan);
    procedure DrawBeacon(const AColor: TRgb; AX, AY, ANearness, ALevel: Single);
    procedure DrawBeacons(const ABeacons: TArray<TFrameBeacon>; ATick: Integer);
    function LightLevel(AKind: TCityLightKind; ASeed: Cardinal; ATick: Integer): Double;
    // ALeft, AHeight - where the building was drawn, units; ASpan - where
    // its lights are shown
    procedure DrawLight(const AElement: TFarPlaneElement; const ALight: TCityLight;
      ASeed: Cardinal; ALeft, AHeight: Double; ATick: Integer; const ASpan: TScreenSpan);
    procedure DrawPaint(const AElement: TFarPlaneElement; ALeft, AHeight: Double);
    procedure DrawEmblem(const AElement: TFarPlaneElement; ALeft, AHeight: Double;
      ATick: Integer);
    // AIndex - the building's place in the city's layer: the seed of its
    // lights' clocks
    procedure DrawLife(const AElement: TFarPlaneElement; AIndex: Integer;
      ALeft, AHeight: Double; ATick: Integer);
    // AIndex - one past the city's buildings: the seed of its lights' clocks
    procedure DrawTrain(ACityOffset: Double; AIndex, ATick: Integer; AClock: Double);
    procedure AddBeamPiece(const ABeam: TSearchlightBeam; const AFrom, ATill: TBeamSample);
    procedure DrawBeam(const ABeam: TSearchlightBeam);
    // Each beam not drawn yet whose lamp stands behind ADepth
    procedure DrawBeamsBefore(ADepth: Single);
    procedure DrawBeamGlints(const ABeam: TSearchlightBeam);
    procedure LoadFarm(ACache: TSpriteCache);
    function FarmLit: Boolean;
    // Added over the scene, clipped to ATop..ABottom when AClipped
    procedure DrawLightMesh(const AMesh: TFarmMesh; AClipped: Boolean; ATop, ABottom: Single);
    // The floor in front of the farm's dome, between ATop and ABottom
    procedure DrawApron(ACityOffset: Double; ATop, ABottom: Single);
    procedure DrawAir(ACityOffset: Double);
    // AHeight - its piece's height in units
    procedure DrawGlass(AIndex: Integer; const AElement: TFarPlaneElement;
      ALeft, AHeight: Double);
    procedure LightFarRibs;
    procedure DrawLayer(ALayer: Integer; const AOffsets: TFarPlaneOffsets;
      ATick: Integer; AClock: Double; const ABackdrop: TBackdropView);
  public
    // Resolves every picture now, so a sprite the set lacks raises at
    // level load. ACache - the level's object art, with the far plane's set
    // attached; it must outlive the painter.
    constructor Create(ARenderer: PSdlRenderer; ACache: TSpriteCache;
      const ADef: TFarPlaneDef);
    destructor Destroy; override;
    // ATick - the far plane's clock (TFarPlane.Clock), AClock - the same
    // between its ticks, as the offsets are (TFarPlane.ClockAt); ABackdrop -
    // the screen's own, drawn where its element rides
    procedure Draw(const AOffsets: TFarPlaneOffsets; ATick: Integer; AClock: Double;
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
  // A greenhouse's lit glass, tools/chase/make_glow.py
  FarmGlassSprite = '%s-glow';
  // The halo is two glows fitted to the stand's radial gradient (0.55 at
  // the disc's edge, 0.16 a quarter of the way out, nothing at the halo's
  // rim): a core and a wide glare, sized by the halo's radius
  HaloCoreSize = 0.92;
  HaloCoreLevel = 0.38;
  HaloGlareSize = 3.1;
  HaloGlareLevel = 0.19;
  SolidAlpha = 255;
  Unshaded = 1.0;
  NoStart = -MaxInt;
  // The stand's samples of a beam: inside the dome and along its tail
  BeamInsideSamples = 20;
  BeamTailSamples = 12;
  // A rib this near parallel to a beam crosses it nowhere
  ParallelSlack = 1E-6;
  WholeScreen: TFarPlanePainter.TScreenSpan = (Left: -MaxSingle; Right: MaxSingle);
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
  if FDef.Train.Present then
  begin
    FTrain := ACache.Get(FDef.SpriteName(FDef.Train.Piece));
    FTrainLine := MonorailLine(FDef);
    FTrainElement := Default(TFarPlaneElement);
    FTrainElement.Id := FDef.Train.Piece;
    FTrainElement.Y := FDef.Train.Y;
    FTrainElement.W := FDef.Train.W;
    FTrainElement.DepthY := FTrainLine.Depth;
  end;
  if FDef.Farm.Present then
    LoadFarm(ACache);
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

// A beam is flat along, so the part of its glow within the span is the glow
// over that part; a point is drawn whole while its centre is in it
procedure TFarPlanePainter.GlowWithin(ATexture: PSdlTexture; ACentreX, ACentreY,
  AWidth, AHeight: Single; const AColor: TRgb; ALevel: Single; const ASpan: TScreenSpan);
begin
  if ATexture <> FBeamGlow then
  begin
    if (ACentreX >= ASpan.Left) and (ACentreX <= ASpan.Right) then
      GlowAround(ATexture, ACentreX, ACentreY, AWidth, AHeight, AColor, ALevel);
    Exit;
  end;
  var Left: Single := ACentreX - AWidth / 2;
  var Right: Single := ACentreX + AWidth / 2;
  if (Left >= ASpan.Left) and (Right <= ASpan.Right) then
  begin
    GlowAround(ATexture, ACentreX, ACentreY, AWidth, AHeight, AColor, ALevel);
    Exit;
  end;
  if Left < ASpan.Left then
    Left := ASpan.Left;
  if Right > ASpan.Right then
    Right := ASpan.Right;
  if Right > Left then
    GlowAround(ATexture, (Left + Right) / 2, ACentreY, Right - Left, AHeight, AColor, ALevel);
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
  const ALight: TCityLight; ASeed: Cardinal; ALeft, AHeight: Double; ATick: Integer;
  const ASpan: TScreenSpan);
begin
  var Box := ALight.Box;
  var Top: Double := AElement.Y - AHeight;
  var Nearness := FDef.Nearness(AElement.DepthY);
  if ALight.Kind = lkLamp then
  begin
    var LampU: Single := Box.U;
    if AElement.Mirror then
      LampU := 1 - Box.U;
    var LampX: Single := ALeft + LampU * AElement.W;
    if (LampX >= ASpan.Left) and (LampX <= ASpan.Right) then
      DrawBeacon(ALight.Color, LampX, Top + Box.V * AHeight, Nearness,
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

  GlowWithin(Shape, CentreX, CentreY, Width * Look.HaloW + Pad, Height * Look.HaloH + Pad,
    ALight.Color, Look.HaloLevel * Level, ASpan);
  GlowWithin(Shape, CentreX, CentreY, Width * Look.CoreW, Height * Look.CoreH,
    ALight.Color, Look.CoreLevel * Level, ASpan);
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
    DrawLight(AElement, Lights[i], LightSeed(AIndex, i), ALeft, AHeight, ATick, WholeScreen);
  if FDef.Emblem.Present and (AElement.Id = FDef.Emblem.Piece) then
    DrawEmblem(AElement, ALeft, AHeight, ATick);
end;

// Its picture and its lights between the mouths: what has gone into a
// station is not drawn
procedure TFarPlanePainter.DrawTrain(ACityOffset: Double; AIndex, ATick: Integer;
  AClock: Double);
begin
  var Train := FDef.Train;
  var Place := TrainLeft(Train, FTrainLine, AClock);
  var Shown := TrainShown(Train, FTrainLine, Place);
  if not Shown.Any then
    Exit;
  var Left: Double := Place - ACityOffset * FTrainLine.Nearness;
  var Span: TScreenSpan;
  Span.Left := Left + Shown.From * Train.W;
  Span.Right := Left + Shown.Till * Train.W;
  if (Span.Right < 0) or (Span.Left > FDef.ScreenWidth) then
    Exit;

  var Height: Double := Train.W * TextureAspect(FTrain);
  AddQuad(FloatRect(Span.Left, Train.Y - Height, Span.Right - Span.Left, Height),
    FloatRect(Shown.From, 0, Shown.Till - Shown.From, 1), ShadeColor(Train.Shade),
    QuadAlpha(1, 1, 1, 1));
  Flush(FTrain);

  var Lights := FDef.Lights.LightsOf(Train.Piece);
  for var i := 0 to High(Lights) do
    DrawLight(FTrainElement, Lights[i], LightSeed(AIndex, i), Left, Height, ATick, Span);
end;

function InsideSample(const ALights: TCitySearchlights; const ABeam: TSearchlightBeam;
  AIndex: Integer): TFarPlanePainter.TBeamSample;
begin
  Result.Distance := ABeam.Glass * AIndex / BeamInsideSamples;
  Result.Level := BeamLevel(ALights, ABeam, Result.Distance);
end;

function TailSample(const ALights: TCitySearchlights; const ABeam: TSearchlightBeam;
  AIndex: Integer): TFarPlanePainter.TBeamSample;
begin
  var Share: Double := AIndex / BeamTailSamples;
  Result.Distance := ABeam.Glass + ALights.Tail * Share;
  Result.Level := TailLevel(ALights, Share);
end;

// The beam's texture is Gaussian across V and flat along U
procedure TFarPlanePainter.AddBeamPiece(const ABeam: TSearchlightBeam;
  const AFrom, ATill: TBeamSample);
const
  // From's edges, then Till's: the side, the level's end
  Side: array [0..3] of Integer = (-1, 1, 1, -1);
  AtTill: array [0..3] of Boolean = (False, False, True, True);
  Triangles: array [0..5] of Integer = (0, 1, 2, 0, 2, 3);
begin
  var Lights := FDef.Searchlights;
  var NormalX := -ABeam.DirY;
  var NormalY := ABeam.DirX;
  var First := Length(FVertices);
  SetLength(FVertices, First + 4);
  for var i := 0 to 3 do
  begin
    var Sample := AFrom;
    if AtTill[i] then
      Sample := ATill;
    var Half: Double := Lights.RootHalf + Lights.Spread * Sample.Distance;
    var Vertex: TSdlVertex;
    Vertex.Position.X := ABeam.AtX(Sample.Distance) + NormalX * Half * Side[i];
    Vertex.Position.Y := ABeam.AtY(Sample.Distance) + NormalY * Half * Side[i];
    Vertex.TexCoord.X := 0.5;
    Vertex.TexCoord.Y := (Side[i] + 1) / 2;
    Vertex.Color.R := Lights.Color.R;
    Vertex.Color.G := Lights.Color.G;
    Vertex.Color.B := Lights.Color.B;
    Vertex.Color.A := Round(SolidAlpha * EnsureRange(Sample.Level, 0.0, 1.0));
    FVertices[First + i] := Vertex;
  end;
  for var Corner in Triangles do
    FIndices := FIndices + [First + Corner];
end;

// Inside the dome from the lamp's level to the glass's; past the glass the
// tail starts a step lower and fades out
procedure TFarPlanePainter.DrawBeam(const ABeam: TSearchlightBeam);
begin
  var Lights := FDef.Searchlights;
  if ABeam.Glass > 0 then
    for var n := 0 to BeamInsideSamples - 1 do
      AddBeamPiece(ABeam, InsideSample(Lights, ABeam, n), InsideSample(Lights, ABeam, n + 1));
  for var n := 0 to BeamTailSamples - 1 do
    AddBeamPiece(ABeam, TailSample(Lights, ABeam, n), TailSample(Lights, ABeam, n + 1));
  // The vertices carry the colour and the level; the shared glow may still
  // hold the mods of the last glow drawn through it
  SDL_SetTextureColorMod(FBeamGlow, 255, 255, 255);
  SDL_SetTextureAlphaMod(FBeamGlow, SolidAlpha);
  Flush(FBeamGlow);
end;

procedure TFarPlanePainter.DrawBeamsBefore(ADepth: Single);
begin
  for var i := 0 to High(FBeams) do
  begin
    if FBeamsDrawn[i] or (FDef.Searchlights.Lamps[i].Y >= ADepth) then
      Continue;
    DrawBeam(FBeams[i]);
    FBeamsDrawn[i] := True;
  end;
end;

// A near rib stands in front of the beam and is lit from behind where the
// beam crosses it inside the dome
procedure TFarPlanePainter.DrawBeamGlints(const ABeam: TSearchlightBeam);
begin
  if ABeam.Glass <= 0 then
    Exit;
  var Lights := FDef.Searchlights;
  GlowAround(FPointGlow, ABeam.AtX(ABeam.Glass), ABeam.AtY(ABeam.Glass), Lights.SpotSize,
    Lights.SpotSize, Lights.Color, Lights.SpotLevel);
  for var Rib in FFrameView.Near do
  begin
    var RibX: Double := Rib.B.X - Rib.A.X;
    var RibY: Double := Rib.B.Y - Rib.A.Y;
    var Cross := ABeam.DirX * RibY - ABeam.DirY * RibX;
    if Abs(Cross) < ParallelSlack then
      Continue;
    var ToRibX: Double := Rib.A.X - ABeam.FromX;
    var ToRibY: Double := Rib.A.Y - ABeam.FromY;
    var Along := (ToRibX * RibY - ToRibY * RibX) / Cross;
    var OnRib := (ToRibX * ABeam.DirY - ToRibY * ABeam.DirX) / Cross;
    var Crosses := (OnRib >= 0) and (OnRib <= 1) and (Along > 0) and (Along < ABeam.Glass);
    if not Crosses then
      Continue;
    GlowAround(FPointGlow, ABeam.AtX(Along), ABeam.AtY(Along), Lights.GlintSize,
      Lights.GlintSize, Lights.Color,
      Lights.GlintLevel * BeamLevel(Lights, ABeam, Along) / Lights.Level);
  end;
end;

procedure TFarPlanePainter.LoadFarm(ACache: TSpriteCache);
var
  Glass: TFarmGlass;
begin
  for var i := 0 to High(FDef.Layers) do
  begin
    var Layer := FDef.Layers[i];
    if Layer.Motion <> fmCity then
      Continue;
    SetLength(FGlassPictures, Length(Layer.Elements));
    SetLength(FCityHeights, Length(Layer.Elements));
    for var j := 0 to High(Layer.Elements) do
    begin
      if FPictures[i][j] <> nil then
        FCityHeights[j] := Layer.Elements[j].W * TextureAspect(FPictures[i][j]);
      if FDef.Farm.GlassOf(Layer.Elements[j].Id, Glass) then
        FGlassPictures[j] := ACache.Get(FDef.SpriteName(Format(FarmGlassSprite,
          [Layer.Elements[j].Id])));
    end;
    Exit;
  end;
end;

// The farm lights nothing while none of its greenhouses near the screen is lit
function TFarPlanePainter.FarmLit: Boolean;
begin
  Result := Length(FFarm.Sources) > 0;
end;

// No texture: the triangles take the renderer's draw blend
procedure TFarPlanePainter.DrawLightMesh(const AMesh: TFarmMesh; AClipped: Boolean;
  ATop, ABottom: Single);
var
  Clip: TSdlRect;
begin
  if Length(AMesh.Indices) = 0 then
    Exit;
  var Vertices: TArray<TSdlVertex>;
  SetLength(Vertices, Length(AMesh.Corners));
  for var i := 0 to High(AMesh.Corners) do
  begin
    var Corner := AMesh.Corners[i];
    Vertices[i].Position.X := Corner.X;
    Vertices[i].Position.Y := Corner.Y;
    Vertices[i].Color.R := Round(255 * EnsureRange(Corner.Light.R, 0.0, 1.0));
    Vertices[i].Color.G := Round(255 * EnsureRange(Corner.Light.G, 0.0, 1.0));
    Vertices[i].Color.B := Round(255 * EnsureRange(Corner.Light.B, 0.0, 1.0));
    Vertices[i].Color.A := SolidAlpha;
    Vertices[i].TexCoord.X := 0;
    Vertices[i].TexCoord.Y := 0;
  end;
  if AClipped then
  begin
    Clip.X := 0;
    Clip.Y := Round(ATop);
    Clip.W := Round(FDef.ScreenWidth);
    Clip.H := Round(ABottom - ATop);
    SDL_RenderSetClipRect(FRenderer, @Clip);
  end;
  SDL_SetRenderDrawBlendMode(FRenderer, SdlBlendModeAdd);
  SDL_RenderGeometry(FRenderer, nil, @Vertices[0], Length(Vertices),
    @AMesh.Indices[0], Length(AMesh.Indices));
  SDL_SetRenderDrawBlendMode(FRenderer, SdlBlendModeBlend);
  if AClipped then
    SDL_RenderSetClipRect(FRenderer, nil);
end;

procedure TFarPlanePainter.DrawApron(ACityOffset: Double; ATop, ABottom: Single);
begin
  DrawLightMesh(FarmApronMesh(FDef, FFarm.Sources, ACityOffset), True, ATop, ABottom);
end;

procedure TFarPlanePainter.DrawAir(ACityOffset: Double);
begin
  DrawLightMesh(FarmAirMesh(FDef, FFarm.Sources, ACityOffset), False, 0, 0);
end;

// Over its shaded picture, at its glow's level and not shaded: the glass is
// the one thing of the farm that shines
procedure TFarPlanePainter.DrawGlass(AIndex: Integer; const AElement: TFarPlaneElement;
  ALeft, AHeight: Double);
begin
  var Level := FFarm.Glass[AIndex];
  if (FGlassPictures[AIndex] = nil) or (Level <= 0) then
    Exit;
  var Color := ShadeColor(Unshaded);
  Color.A := Round(SolidAlpha * Min(Level, 1.0));
  AddQuad(FloatRect(ALeft, AElement.Y - AHeight, AElement.W, AHeight), Across(AElement, 0, 1),
    Color, QuadAlpha(1, 1, 1, 1));
  Flush(FGlassPictures[AIndex]);
end;

// The farm's far ribs turn their inner face to the eye, and its light lands
// there: the dark of a rib, and the light at its middle times RibLevel
procedure TFarPlanePainter.LightFarRibs;
begin
  for var i := 0 to High(FFrameView.Far) do
  begin
    var Rib := FFrameView.Far[i];
    if not Rib.Farm then
      Continue;
    var Light := Exposed(FarmLight(FDef.Farm, FFarm.Sources, (Rib.A.X + Rib.B.X) / 2,
      (Rib.A.Y + Rib.B.Y) / 2), FDef.Farm.RibLevel);
    Rib.Dark.R := Round(Rib.Dark.R + (255 - Rib.Dark.R) * Light.R);
    Rib.Dark.G := Round(Rib.Dark.G + (255 - Rib.Dark.G) * Light.G);
    Rib.Dark.B := Round(Rib.Dark.B + (255 - Rib.Dark.B) * Light.B);
    FFrameView.Far[i] := Rib;
  end;
end;

// The city stands inside its frames: their shadows on its floor and their
// far half before its buildings, their near half and the glare after. The
// shadows run on over the near ground's band: over the sky between its
// crests they fall on the crater floor, which they shade too
procedure TFarPlanePainter.DrawLayer(ALayer: Integer; const AOffsets: TFarPlaneOffsets;
  ATick: Integer; AClock: Double; const ABackdrop: TBackdropView);
begin
  var Layer := FDef.Layers[ALayer];
  if Layer.Band.Present then
    DrawBand(ALayer, AOffsets);
  if Layer.Band.Present and (Layer.Motion = fmGround) and FFrames.Present then
  begin
    DrawFrameShadows(Layer.Band.Top, FDef.ScreenHeight);
    if FarmLit then
      DrawApron(AOffsets[fmCity], Layer.Band.Top, FDef.ScreenHeight);
  end;

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
    if FarmLit then
    begin
      DrawApron(AOffsets[fmCity], FloorTop, FloorBottom);
      LightFarRibs;
    end;
    FFramePainter.DrawRibs(FFrameView.Far);
    DrawBeacons(FFrameView.FarBeacons, ATick);
  end;

  // The train at its depth: before the first building in front of the line
  var TrainDue := (Layer.Motion = fmCity) and FDef.Train.Present;
  // Each beam at its lamp's depth: the buildings in front hide the lamp
  FBeams := nil;
  if (Layer.Motion = fmCity) and FDef.Searchlights.Present then
  begin
    SetLength(FBeams, Length(FDef.Searchlights.Lamps));
    for var i := 0 to High(FBeams) do
      FBeams[i] := SearchlightBeam(FDef, i, AOffsets[fmCity], AClock);
  end;
  FBeamsDrawn := nil;
  SetLength(FBeamsDrawn, Length(FBeams));
  for var j := 0 to High(Layer.Elements) do
  begin
    var Element := Layer.Elements[j];
    if TrainDue and (Element.DepthY > FTrainLine.Depth) then
    begin
      DrawTrain(AOffsets[fmCity], Length(Layer.Elements), ATick, AClock);
      TrainDue := False;
    end;
    DrawBeamsBefore(Element.DepthY);
    var Left := FDef.ElementLeft(Layer, Element, AOffsets);
    if Element.Backdrop then
    begin
      if ABackdrop.Texture <> nil then
        DrawElement(Element, ABackdrop.Texture, Left, TintColor(ABackdrop.Tint));
      Continue;
    end;
    var Picture := FPictures[ALayer][j];
    var Shown := DrawElement(Element, Picture, Left, ShadeColor(Element.Shade));
    if not Shown or (Layer.Motion <> fmCity) then
      Continue;
    var Height := Element.W * TextureAspect(Picture);
    if Length(FGlassPictures) > 0 then
      DrawGlass(j, Element, Left, Height);
    DrawLife(Element, j, Left, Height, ATick);
  end;
  if TrainDue then
    DrawTrain(AOffsets[fmCity], Length(Layer.Elements), ATick, AClock);
  DrawBeamsBefore(MaxSingle);
  if (Layer.Motion = fmCity) and FarmLit then
    DrawAir(AOffsets[fmCity]);

  if Framed then
  begin
    FFramePainter.DrawRibs(FFrameView.Near);
    DrawBeacons(FFrameView.NearBeacons, ATick);
    for var Beam in FBeams do
      DrawBeamGlints(Beam);
    FFramePainter.DrawGlare(FDef.SunCover(AOffsets), FDef.GlareLevel(AOffsets));
  end;
end;

procedure TFarPlanePainter.Draw(const AOffsets: TFarPlaneOffsets; ATick: Integer;
  AClock: Double; const ABackdrop: TBackdropView);
begin
  if FFrames.Present then
    FFrameView := FFrames.View(AOffsets[fmCity]);
  FFarm := FarmView(FDef, AOffsets, ATick, FCityHeights);
  var First := FirstSeenLayer(AOffsets);
  if First < 0 then
  begin
    DrawSky;
    DrawSun(AOffsets);
    First := 0;
  end;
  for var i := First to High(FDef.Layers) do
    DrawLayer(i, AOffsets, ATick, AClock, ABackdrop);
end;

end.
