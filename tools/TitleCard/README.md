# TitleCard

Prints arbitrary text in Moon 2D's own bitmap font and saves it as a PNG
for the trailer edit. Side effect, and the reason it exists at all: this
is the first time the game's renderer runs outside the game loop. The
level editor will need exactly the same trick.

## Build

1. Open `Moon2D.groupproj` in the repository root and build the group -
   the tool compiles alongside the game, which is the point: a change to
   a shared unit breaks here the day it is made, not the day you sit
   down to edit a trailer.
2. The shared units are pulled in by relative path from the `uses`
   clause of the `.dpr`, so there is no search path to configure. That
   also means the tool only builds inside a full checkout.
3. **Copy `SDL2.dll` and `SDL2_image.dll` next to the produced exe.**
   `Sdl2.Core` imports SDL2 statically, so Windows resolves it at process
   load, before any code of ours could point the loader elsewhere. The
   image DLL decodes the PNG the atlas is stored as. No DLLs, no start.
4. Nothing is copied next to the exe beyond that: the tool walks up from
   its own folder (six levels, enough for `Win32\Release`) until it finds
   `bin\sprites\ui.mset`, and reads the `fonty` sprite out of it.

## Using it

* **Line breaks in the memo are sacred.** Nothing re-flows them unless
  you tick "Emergency word wrap". The break is usually the joke.
* **Scale** is in whole atlas cells. `x2` means each 28 px glyph cell is
  drawn 56 px tall - every source pixel becomes the same block, no
  shimmer. Auto picks the largest whole step that fits the margins;
  "Auto - free" drops the whole-step rule when you want it gone.
* **The status line is the authoring tool.** It reports the character
  limit for the current scale and how many characters each offending
  line is over. Rewrite the break; do not shrink the type.
* **Preview is composited on black.** The alpha channel is real and it
  lands in the file; you just cannot see transparency on a screen.
* **Batch**: a `.txt` where a blank line separates cards. Output goes to
  a `cards` folder next to the txt, named by `FileNamePattern`. With
  "one scale for the whole batch" ticked, every card gets the smallest
  scale any of them needs - cards of wandering type size read as an
  accident. `cards.txt` here is the trailer script, already broken.

## How wide is too wide

The font is wide: one character costs `1.07 x` the cap height. That
makes the character budget per line brutal and worth knowing before
writing:

| card         | x1 | x2 | x3 |
|--------------|----|----|----|
| 1024 x 768   | 23 | 11 |  7 |
| 2048 x 1536  | 47 | 23 | 15 |
| 1920 x 1080  | 44 | 22 | 14 |
| 1080 x 1440  | 25 | 12 |  8 |

(15% margins each side.) A 35-character sentence at `x2` on 16:9 simply
does not exist - it has to become two lines. That is not a limitation to
work around, it is what a trailer card looks like anyway.

Note the first two rows: 4:3 is the game's own aspect, so cards in that
shape cut against gameplay footage without black bars. `1024 x 768` is
native but cramped - eleven characters at `x2`. Author on `2048 x 1536`
instead: same proportions, same line breaks, twice the pixels, and the
character budget matches 16:9. Downscale it in the edit only by a whole
factor, or the bitmap font smears back into the greyness it was drawn to
avoid.

## Settings

`TitleCard.ini` sits next to the exe and is written with defaults on the
first run. `[Paths] SpriteSet` pins the container and `FontSprite` picks
the atlas inside it - `fontx` is the same font in the other orientation,
should the trap in `Render.Font` ever need re-testing. Every measurement in it is a whole percent on purpose:
`ReadFloat` would go through the locale decimal separator, and an INI
that silently reverts to defaults on a comma locale is a bad afternoon.

## What it touches in the game

* `Sdl2.Core.pas` gained the offscreen half of the API: `SDL_CreateTexture`,
  `SDL_SetRenderTarget`, `SDL_RenderReadPixels`,
  `SDL_SetRenderDrawBlendMode`, plus the hidden-window, render-target and
  scale-quality constants. Additions only; nothing existing moved.
* `Render.Font.pas` is untouched. `DrawScaled` already draws at any size
  with the game's own proportions, which is precisely the look wanted.
* Nothing else. `Image.Png.pas` - an 8-bit RGBA PNG writer over
  `System.ZLib` - lives here in the tool, because the tool is its only
  caller. When the level editor wants one too, it moves up to
  `tools\shared\`: one unit, two callers, one home. Parking it in the
  game root today would mean a unit the game never compiles, quietly
  rotting until somebody edits it blind.
