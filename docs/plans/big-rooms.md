# Big rooms: a screen larger than the frame (step 6 after 3.0)

Status: an idea (2026-11-07) with an assessment against the code the
same day; sixth of the six steps after 3.0 (`ROADMAP.md`). Nothing built.

## The idea (decided 2026-11-07)
A half-scroller. One screen of a level - a room - is larger than the
frame the monitor shows: 3x3 frames, say. The camera moves over it; the
backdrop's motion is designed per room, as it is in the chase of arena 3
(`mechanics/chase-backdrop.md`) - there the scroll is driven by the Ram,
not by the player. From level 5 or so; level 3 is an ordinary wide
level, level 4 the trains.

The rule it must keep: an improvement of the engine, not a new game.
Levels 1-2 stay as they are, with no extra effort - a room of 1x1 frames
is the ordinary flip screen, and the flip between rooms stays what it
was.

## The assessment (2026-11-07, against the code)

**What is in place already.**
- `Game.Space` keeps the SCREEN (the world the hero, the monsters and the
  bullets move in) apart from the FRAME (what the window shows), and its
  header says the screen size will follow the level. A big room is a
  screen larger than the frame - the same idea one step on.
- `Render.Sprites` has `Origin`: a shift of every draw, the hook of the
  screen shake. A camera is the same `Origin` that travels instead of
  trembling. The physics, the collisions, the monsters and the bullets
  stay in world coordinates and never hear of the camera.
- `Levels.FarPlane` moves its layers by offsets per motion kind
  (`TFarPlaneOffsets`). The chase feeds the offsets from the belt; a
  room feeds them from the camera - parallax by layer on the same
  machine. That is "the backdrop designed per room as in the chase".
- The flip between rooms is untouched: at the edge of a room, the old
  screen change.

**How the chase differs.** The chase is not a camera: `Game.Belt` slides
the world left under a standing frame. In a room the world stands and the
camera moves. What carries over is the smooth ramp (`SmoothStep`, no
jerk at start or stop) and the idea that a script may drive the scroll.
The belt itself does not carry over. So there are two camera modes: one
that follows the hero (with a dead zone) and one on rails (a script, as
the Ram).

**Where the work is - not the camera, the unspoken "screen = world".**
- `ScreenWidth` / `ScreenHeight` / `ScreenCols` / `ScreenRows` are used
  about 157 times in 28 units: a bullet leaving the world, the cell
  oracles, the edges for the monsters. Mostly mechanical: the constant
  becomes a property of the level - step 2 of `wide-frame.md`, the same
  places. Visited once if the two steps are planned together
  (`ROADMAP.md`, the notes on the order).
- The hard-wired places listed in `wide-frame.md`: the boss's flight
  32..448, the minions `Random(15) + 1`, the fans of the explosions sized
  for 512x384. For a 1x1 room they give 2008 exactly; for a 3x3 room they
  must scale to the room, or the boss flies in the top left corner of it.
- New meaning, "in the room but out of the frame": does a monster the
  player cannot see fire? Does a bullet die at the edge of the camera or
  of the room? Decisions of the design, to be taken before the code.

**Proposed stages, not decided.**
- **6.1** - the room size from the level, `Origin` = the camera, the
  camera standing at 0. Nothing changes from outside; the check is that
  levels 1-2 show zero difference.
- **6.2** - the camera follows the hero; the parallax of the backdrop
  from the camera; the tiles outside the frame are not drawn.
- **6.3** - the camera on rails (a script) and the first level that uses
  it.

## Traps
- The camera is interpolated between ticks by alpha like everything else,
  or at 33 Hz the eye sees the step at once.
- A fractional camera over 64 px tiles with scaling leaves seams between
  tiles: round the camera to a pixel of the output, or draw the tiles
  with an overlap.
- Some drawing goes past `Origin` (the HUD brush, the health rows - noted
  in `wide-frame.md`). The HUD must; every other such path is checked -
  is it of the frame or of the world?
