{
  Render.Tiles - draws one level screen: background image behind,
  palette tiles on the 16x12 grid in front.

  Layering (confirmed against the original): _scrX.bmp backgrounds are a
  full-screen backdrop, grid tiles draw over it. Every tile cell shows
  the top-left 64x64 pixels of its art bitmap - the 2008 loader's crop
  (sttextures.pas), reproduced by DrawTile - scaled into a 32-unit cell.
  Big art (the ship) is a level object (Render.Objects), not tiles.

  Uses two sprite caches with different roots: the tile palette stores
  paths relative to textures\ ("level1\doom1.bmp"), background images
  live in the level's own folder ("levels\level1\_scr0.bmp").

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Render.Tiles;
{$I ..\Moon2D.inc}

interface

uses
  Render.Sprites, Levels.Defs;

type
  TTileScreenRenderer = class
  private
    FSprites: TSpriteRenderer;
    FTileCache: TSpriteCache;       // rooted at textures\
    FBackgroundCache: TSpriteCache; // rooted at levels\<level>\
    FLevel: TLevel;
    // Screen size in GAME UNITS (512x384) - the SDL logical size the
    // whole pipeline draws in, not window pixels.
    FScreenWidth: Integer;
    FScreenHeight: Integer;
  public
    // Does not own any of the collaborators; the composition root does.
    constructor Create(const ASprites: TSpriteRenderer;
      const ATileCache, ABackgroundCache: TSpriteCache;
      const ALevel: TLevel);

    // Two layers, drawn by the caller in this order - separately, so the
    // backdrop can stand still while the tiles shake
    procedure DrawBackground(AScreen: Integer);
    procedure DrawTiles(AScreen: Integer);
  end;

implementation

uses
  Sdl2.Core;

constructor TTileScreenRenderer.Create(const ASprites: TSpriteRenderer;
  const ATileCache, ABackgroundCache: TSpriteCache; const ALevel: TLevel);
begin
  inherited Create;
  FSprites := ASprites;
  FTileCache := ATileCache;
  FBackgroundCache := ABackgroundCache;
  FLevel := ALevel;
  FScreenWidth := ALevel.GridWidth * TileSize;
  FScreenHeight := ALevel.GridHeight * TileSize;
end;

procedure TTileScreenRenderer.DrawBackground(AScreen: Integer);
var
  Dest: TSdlRect;
begin
  var Backdrop := FLevel.BackgroundFor(AScreen);
  if Backdrop.Image = '' then
    Exit; // no backdrop defined - night blue from the clear color shows

  var Texture := FBackgroundCache.Get(Backdrop.Image);
  // Set on every draw, not once at load: two changes may share one
  // picture under different tints
  TintTexture(Texture, Backdrop.Tint.R, Backdrop.Tint.G, Backdrop.Tint.B);

  Dest.X := 0;
  Dest.Y := 0;
  Dest.W := FScreenWidth;
  Dest.H := FScreenHeight;
  FSprites.DrawRect(Texture, Dest);
end;

procedure TTileScreenRenderer.DrawTiles(AScreen: Integer);
begin
  for var Row := 0 to FLevel.GridHeight - 1 do
    for var Col := 0 to FLevel.GridWidth - 1 do
    begin
      var Tile := FLevel.TileAt(AScreen, Col, Row);
      if Tile = EmptyTile then
        Continue;

      // Grid ids are 1-based: 0 is EmptyTile, N maps to
      // TilePalette[N - 1] (the contract at EmptyTile, Levels.Defs).
      FSprites.DrawTile(FTileCache.Get(FLevel.TilePalette[Tile - 1]),
        Col, Row);
    end;
end;

end.
