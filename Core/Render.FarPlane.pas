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

  While the screen's own backdrop covers the whole screen, nothing behind
  its layer is drawn: the arena before the chase costs one picture more,
  the cliff's end over the wall.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Render.FarPlane;
{$I ..\Moon2D.inc}

interface

uses
  Sdl2.Core, Render.Sprites, Levels.FarPlane, Levels.Dynamics;

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
    procedure DrawElement(const AElement: TFarPlaneElement;
      ATexture: PSdlTexture; AOffset: Double; AColor: TSdlColor);
    procedure DrawLayer(ALayer: Integer; const AOffsets: TFarPlaneOffsets;
      const ABackdrop: TBackdropView);
  public
    // Resolves every picture now, so a sprite the set lacks raises at
    // level load. ACache - the level's object art, with the far plane's set
    // attached; it must outlive the painter.
    constructor Create(ARenderer: PSdlRenderer; ACache: TSpriteCache;
      const ADef: TFarPlaneDef);
    destructor Destroy; override;
    // ABackdrop - the screen's own, drawn where its element rides
    procedure Draw(const AOffsets: TFarPlaneOffsets; const ABackdrop: TBackdropView);
  end;

implementation

uses
  System.Math, Levels.Tint, Render.Brush, Render.Glow;

const
  PointGlowSide = 128;
  DiscGlowSide = 64;
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
  FPointGlow := CreateGlowShape(ARenderer, gsPoint, PointGlowSide);
  FDiscGlow := CreateGlowShape(ARenderer, gsDisc, DiscGlowSide);
end;

destructor TFarPlanePainter.Destroy;
begin
  // A sprite the set lacks stops the constructor before the glows exist
  if Assigned(FPointGlow) then
    SDL_DestroyTexture(FPointGlow);
  if Assigned(FDiscGlow) then
    SDL_DestroyTexture(FDiscGlow);
  inherited;
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
  var Cover := FDef.SunCover(AOffsets);
  var Color: TRgb;
  Color.R := Round(Sun.White.R + (Sun.Tint.R - Sun.White.R) * Cover);
  Color.G := Round(Sun.White.G + (Sun.Tint.G - Sun.White.G) * Cover);
  Color.B := Round(Sun.White.B + (Sun.Tint.B - Sun.White.B) * Cover);

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

procedure TFarPlanePainter.DrawElement(const AElement: TFarPlaneElement;
  ATexture: PSdlTexture; AOffset: Double; AColor: TSdlColor);
var
  Left, Height, Feather, FeatherShare: Double;
begin
  Left := AElement.X - AOffset;
  if (Left >= FDef.ScreenWidth) or (Left + AElement.W <= 0) then
    Exit;
  Height := AElement.W * TextureAspect(ATexture);
  Feather := Min(Double(AElement.FeatherLeft), Double(AElement.W));
  FeatherShare := Feather / AElement.W;
  var Top := AElement.Y - Height;
  if Feather > 0 then
    AddQuad(FloatRect(Left, Top, Feather, Height),
      Across(AElement, 0, FeatherShare), AColor, QuadAlpha(0, 1, 1, 1));
  AddQuad(FloatRect(Left + Feather, Top, AElement.W - Feather, Height),
    Across(AElement, FeatherShare, 1 - FeatherShare), AColor, QuadAlpha(1, 1, 1, 1));
  Flush(ATexture);
end;

procedure TFarPlanePainter.DrawLayer(ALayer: Integer; const AOffsets: TFarPlaneOffsets;
  const ABackdrop: TBackdropView);
begin
  var Layer := FDef.Layers[ALayer];
  var Offset: Double := AOffsets[Layer.Motion];
  if Layer.Band.Present then
    DrawBand(ALayer, AOffsets);
  for var j := 0 to High(Layer.Elements) do
  begin
    var Element := Layer.Elements[j];
    if not Element.Backdrop then
      DrawElement(Element, FPictures[ALayer][j], Offset, ShadeColor(Element.Shade))
    else if ABackdrop.Texture <> nil then
      DrawElement(Element, ABackdrop.Texture, Offset, TintColor(ABackdrop.Tint));
  end;
end;

procedure TFarPlanePainter.Draw(const AOffsets: TFarPlaneOffsets;
  const ABackdrop: TBackdropView);
begin
  var First := FirstSeenLayer(AOffsets);
  if First < 0 then
  begin
    DrawSky;
    DrawSun(AOffsets);
    First := 0;
  end;
  for var i := First to High(FDef.Layers) do
    DrawLayer(i, AOffsets, ABackdrop);
end;

end.
