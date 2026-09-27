{
  Game.Space - the two sizes of the game's coordinate space, kept apart
  on purpose.

  The SCREEN is one flip-screen of a level: the grid the tiles fill, the
  space the hero, the monsters and the bullets move in. The FRAME is what
  the window shows: the SDL logical size, where the HUD panels, the menu
  and the centered captions live. In the 4:3 game the two coincide, and
  for eighteen years one constant served both. They part with the wide
  frame: the frame grows to 16:9 while a 4:3 level keeps its screen and
  sits centered inside it, and later the screen size follows the level.

  So: a cell, a wall, a door, a bullet leaving the world - ScreenWidth /
  ScreenHeight. A panel in a corner, text centered on the display, the
  logical size of the renderer - FrameWidth / FrameHeight. Never the
  other one, however equal the numbers look today.

  Moon 2D remake. Requires Delphi 10.3+ (inline var).
}
unit Game.Space;
{$I Moon2D.inc}

interface

uses
  Render.Sprites;

const
  // One level screen in cells (SetMaxC(512, 384) of 2008 over 32-unit
  // tiles) and in game units
  ScreenCols = 16;
  ScreenRows = 12;
  ScreenWidth = ScreenCols * TileSize;  // 512
  ScreenHeight = ScreenRows * TileSize; // 384

  // What the window shows, in game units. Equal to the screen until the
  // wide frame arrives; every reader of these two must survive them
  // growing past the screen.
  FrameWidth = ScreenWidth;
  FrameHeight = ScreenHeight;

implementation

end.
