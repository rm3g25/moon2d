{
  Render.Objects - draws the free-form art a level places over its
  backdrop (TLevelObject of Levels.Defs): pictures of any shape at any
  point of a screen, between the backdrop and the tiles.

  The art is as dense as the HD backdrops and carries honest PNG alpha:
  the cache the composition root hands in has no color key (black glass
  and shadows would vanish through one) and filters linearly. The set is
  <assetsDir>-objects.mset, found by convention like the backdrops.
  The pictures of a belt - the road of a chase - slide left as far as the
  road has run, wrapped round the width of the screen.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Render.Objects;
{$I ..\Moon2D.inc}

interface

uses
  Sdl2.Core, Render.Sprites, Levels.Tint, Levels.Defs;

type
  TObjectScreenRenderer = class
  private type
    TPlacedArt = record
      Screen: Integer;
      Texture: PSdlTexture;
      Dest: TSdlRect;
      Tint: TColorTint;
      OnBelt: Boolean;
    end;
  private
    FSprites: TSpriteRenderer;
    FPlaced: TArray<TPlacedArt>;
    FScreenWidth: Integer;
    procedure DrawOnBelt(const AArt: TPlacedArt; ABeltTravel: Double);
  public
    // Resolves every picture now, so a sprite the set lacks raises at
    // level load rather than on the screen that shows it. Owns none of
    // the collaborators; the cache must outlive this renderer.
    constructor Create(const ASprites: TSpriteRenderer;
      const ACache: TSpriteCache; const ALevel: TLevel);

    // ABeltTravel - units the road of a chase has run to the left
    procedure Draw(AScreen: Integer; ABeltTravel: Double = 0);
  end;

// Where a picture placed at AX stands once the road has run ATravel to
// the left: wrapped round ASpan, from 0 up to ASpan
function BeltX(AX, ATravel, ASpan: Double): Double;

implementation

uses
  System.Math;

function BeltX(AX, ATravel, ASpan: Double): Double;
begin
  Result := FMod(AX - ATravel, ASpan);
  if Result < 0 then
    Result := Result + ASpan;
end;

constructor TObjectScreenRenderer.Create(const ASprites: TSpriteRenderer;
  const ACache: TSpriteCache; const ALevel: TLevel);
var
  ArtWidth, ArtHeight: Integer;
begin
  inherited Create;
  FSprites := ASprites;
  FScreenWidth := ALevel.GridWidth * TileSize;

  for var Placement in ALevel.Objects do
  begin
    var Art: TPlacedArt;
    Art.Screen := Placement.Screen;
    Art.Texture := ACache.Get(Placement.Sprite);
    Art.Tint := Placement.Tint;

    SDL_QueryTexture(Art.Texture, nil, nil, @ArtWidth, @ArtHeight);
    Art.Dest.X := Placement.X;
    Art.Dest.Y := Placement.Y;
    Art.Dest.W := Placement.Width;
    Art.Dest.H := Round(Placement.Width * ArtHeight / ArtWidth);
    Art.OnBelt := Placement.Belt;

    FPlaced := FPlaced + [Art];
  end;
end;

procedure TObjectScreenRenderer.Draw(AScreen: Integer; ABeltTravel: Double);
begin
  for var Art in FPlaced do
  begin
    if Art.Screen <> AScreen then
      Continue;
    TintTexture(Art.Texture, Art.Tint.R, Art.Tint.G, Art.Tint.B);
    if Art.OnBelt then
      DrawOnBelt(Art, ABeltTravel)
    else
      FSprites.DrawRect(Art.Texture, Art.Dest);
  end;
end;

// A picture over the right edge shows its rest at the left one
procedure TObjectScreenRenderer.DrawOnBelt(const AArt: TPlacedArt;
  ABeltTravel: Double);
var
  Dest: TSdlFRect;
begin
  Dest.X := BeltX(AArt.Dest.X, ABeltTravel, FScreenWidth);
  Dest.Y := AArt.Dest.Y;
  Dest.W := AArt.Dest.W;
  Dest.H := AArt.Dest.H;
  FSprites.DrawRectF(AArt.Texture, Dest);
  if Dest.X + Dest.W <= FScreenWidth then
    Exit;
  Dest.X := Dest.X - FScreenWidth;
  FSprites.DrawRectF(AArt.Texture, Dest);
end;

end.
