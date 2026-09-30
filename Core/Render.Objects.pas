{
  Render.Objects - draws the free-form art a level places over its
  backdrop (TLevelObject of Levels.Defs): pictures of any shape at any
  point of a screen, between the backdrop and the tiles.

  The art is as dense as the HD backdrops and carries honest PNG alpha:
  the cache the composition root hands in has no color key (black glass
  and shadows would vanish through one) and filters linearly. The set is
  <assetsDir>-objects.mset, found by convention like the backdrops.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Render.Objects;
{$I ..\Moon2D.inc}

interface

uses
  Sdl2.Core, Render.Sprites, Levels.Defs;

type
  TObjectScreenRenderer = class
  private type
    TPlacedArt = record
      Screen: Integer;
      Texture: PSdlTexture;
      Dest: TSdlRect;
      Tint: TColorTint;
    end;
  private
    FSprites: TSpriteRenderer;
    FPlaced: TArray<TPlacedArt>;
  public
    // Resolves every picture now, so a sprite the set lacks raises at
    // level load rather than on the screen that shows it. Owns none of
    // the collaborators; the cache must outlive this renderer.
    constructor Create(const ASprites: TSpriteRenderer;
      const ACache: TSpriteCache; const ALevel: TLevel);

    procedure Draw(AScreen: Integer);
  end;

implementation

constructor TObjectScreenRenderer.Create(const ASprites: TSpriteRenderer;
  const ACache: TSpriteCache; const ALevel: TLevel);
var
  ArtWidth, ArtHeight: Integer;
begin
  inherited Create;
  FSprites := ASprites;

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

    FPlaced := FPlaced + [Art];
  end;
end;

procedure TObjectScreenRenderer.Draw(AScreen: Integer);
begin
  for var Art in FPlaced do
  begin
    if Art.Screen <> AScreen then
      Continue;
    TintTexture(Art.Texture, Art.Tint.R, Art.Tint.G, Art.Tint.B);
    FSprites.DrawRect(Art.Texture, Art.Dest);
  end;
end;

end.
