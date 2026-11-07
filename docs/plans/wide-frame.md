# The wide frame (step 2 after 3.0)

Status: planned (2026-09-27), step by step, no dates; second of the six
steps after 3.0 (`ROADMAP.md`), after the sprites from video. Not built; what is built already is
listed at the end.

## Why
More play area: the player sees where he jumps and who waits before he
is shot at. A step toward a game for platformer fans, not only for
geeks.

## The format
A grid of 21x12 cells (672x384 units) - the same height, the same scale,
a wider world. Exactly 16:9 does not exist at a 32-unit cell and 12 rows
(21.33); 1.75 leaves bars of about 15 px on 1920x1080 - unnoticeable. A
16x9 grid (512x288) is rejected: the world comes too close, the vertical
screens get cramped.

The scope (corrected 2026-10-02): 16:9 is for new levels, drawn in the
new editor. Levels 1-2 stay 4:3 and are not converted; later they are
simply torn down and drawn anew. Until then both formats live, and the
proportion of the window must not jump - that is the work of the frame
below.

## The order
1. **The wide frame** - a separate preparation, the mechanics of the game
   do not change. The logical frame is always 672x384. A 4:3 level is
   drawn centered, shifted by 80 units; at its sides the game's own
   frame, not the black bars of SDL (SDL draws those by itself - that is
   no solution, the proportion jumps). The corner HUDs move into the side
   bars and stop covering the level; the main menu is wider; the mouse
   reaches the bars; the windowed mode is 16:9 by default (1344x768 =
   672x384 x2). Under this stands the `Origin` of the sprite renderer
   (the shake works through it already); to finish: the mouse (minus the
   shift), the HUD brush and the health rows (they draw past `Origin`).
2. **The screen size from the level** - BEFORE the editor, so that the
   editor takes its grid from the data from its first day and knows both
   4:3 and wide.
3. **The level editor** (`level-editor.md`).
4. **Level 3 - the first wide level** (`level-3.md`); the wide screen is
   its new code, by the rule "every level brings new code"; the editor is
   run in on a clean sheet.
5. Levels 1-2 anew in the wide format - later, with a run-in editor, by
   tearing down and drawing anew (not by widening: see the scope above).

## Already in place
- `grid` in `levelN.json`; `Levels.Defs` and `Render.Tiles` read it; the
  corner HUDs are recreated with the level.
- Since 3.0.1 the frame and the screen are different constants
  (`Game.Space`: `Frame*` and `Screen*`); every 512 / 384 / 16 / 12 of
  `Hero`, `Monsters`, `Bullets` and the dpr is brought to them, `Menu`
  uses `Frame*` too (`mechanics/engine.md`, "раскол кадра и экрана").
- The 2008 sprite variants `@2008` are gone - nothing to switch any more.

## Still hard-wired (constants, not a property of the level)
- `ScreenCols` / `ScreenRows` and `ScreenWidth` / `ScreenHeight` are
  constants of `Game.Space`, the logical size of SDL is set once at
  start - to become a property of the level (`GridWidth` / `GridHeight`
  are there already), the SDL size set on load;
- the cell oracles `ScreenCols * x / ScreenWidth` in `Hero`, `Monsters`
  and the game - to read `FLevel` once the size moves into the level;
- the boss's flight 32..448 x 96..320, the minions from the sky
  `Random(15) + 1`;
- the menu, the intro and the finale under 512x384 (NDC 256/192; the sky
  is a 16:9 nebula, `CoverSource` cuts it to the frame, it survives a
  wide frame) - may stay 4:3 with bars while 4:3 lives;
- the fans of the explosions (from 10x18 to 24x44) are sized for 512x384 -
  thin at the edges, look only; the fire rain (a grid with a step of 16,
  32x24 over 512x384; orbs since 3.0.33 - a column per 16 units of screen
  width) counts from `ScreenWidth` / `ScreenHeight` and follows the size
  by itself.

The count at 2026-11-07: about 157 uses of the four `Screen*` constants
in 28 units - the same places `big-rooms.md` needs, which is why the two
plans are weighed together in `ROADMAP.md`.
