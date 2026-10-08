# Repainting the old levels

How a screen of levels 1-2 goes from the tile art of 2008 to HD art, and
what was learned doing it. Written for a session that arrives cold: read
this, then the last repaint session in `PORTING-NOTES.md` for where the
work stands.

## What a repaint is

A screen of 2008 is tiles on a 16x12 grid. A repainted screen keeps the
grid as matter and loses it as a picture:

- `tiles.screens[n].rows` of the screen go to zero - nothing is drawn
  from the palette;
- `tiles.screens[n].collision` stays - the hero stands where he stood;
- the picture comes back as level objects (`objects`), which collide with
  nothing;
- what moves is not painted: pads (`pads`), fans, lamps, smoke, sparks
  (`dynamics`) are the game's.

The palette is never trimmed: every index after a removed name would
shift.

Level 1 is repainted whole (screens 1-17, set `level1-structures`).
Level 2: screens 1-4 so far (set `level2-objects`).
Levels 1-2 stay 4:3.

## The order of work on a screen

1. **The idea.** What the room is, in a sentence, and what each part of
   the old screen becomes. Agreed before anything is drawn.
2. **The plan and the blockout.** Two pictures made by script from the
   level file: a numbered plan to read, and a clean blockout to feed the
   generator.
3. **The prompts.** One for the main picture, ready to paste. Separate
   things (a gate, a cabinet) get a prompt each, after the room is
   accepted. A long list of small pieces is not wanted.
4. **Generation** happens outside the session, in ChatGPT.
5. **Seating.** The picture is measured against the grid, set in place,
   wired into the level file and packed into the set.
6. **A preview and the checks**, then a live run.

## What each thing becomes

| On the old screen | Becomes |
|---|---|
| Ground, walls, floors | Matter as before, drawn by an object |
| A room | One object for the whole screen, `sNN-room`, at 0, 0, width 512 |
| A separate structure (a gate, a crane) | Its own object, `sNN-name` |
| Platforms hanging in the air | Pads; their cells leave `collision` |
| A fan, a vent | A dynamic `fan`; the picture keeps an empty well |
| A lamp | Painted lit; see "Life on a screen" |
| Wires, pipes, panels | Part of the room's picture |

Pads were pictures-with-collision once (objects over solid cells) on
level 2: a pad that does not move is still a pad, not a tile.

## Pads

A pad of the old levels is `s16-platform` (or `s16-platform-out`, the
broken one), `width` 32, `bullets` "block", `bob` 1 or 1.5, the rig
`pad` (or `padBroken`), a tag `sNN-plat-NN` numbered in file order. The
rigs are written again in each level file's `rigs`.

- A pad's cell leaves `collision`; a pad may not stand in a wall or pass
  through one on its path.
- Nothing static stands on a pad. A pad sways and travels, a static
  object does not, and the two part company: the crystals of level 1
  were taken off the pads of level 2 for it. What rides a pad hangs on
  it as a rig.
- The hero comes onto a screen where the backdrop shows him and where
  the picture has ground for him: on the line of the cliff, not high
  among the lit mountains, where he is lost, and not deep in the black
  under it, where he hangs in nothing.
- A pad that carries the hero across a gap: `path`, route `pingpong`,
  one stop, `speed` about 30, `pause` 1. Pads of one screen get different
  periods so they never fall into step.
- Jumps are judged by the hero's own arc. `Hero.JumpReach(rise)`: up 0-1
  rows - 3 empty cells across, up 2 - 2, up 3 - none, down 1-4 - 4. Port
  the function for a check, do not copy the table.
- A crossing must hold at every phase of the pads, and what the crossing
  guards must be out of reach without them: check both.
- `JumpReach` knows nothing of ceilings. In a corridor three rows high
  the hero's head stops the rise and the jump is cut short: his middle
  travels 72 units floor to floor, 56 onto a deck a row up, 54 down
  from one; the ice form's boost makes it shorter, not longer. A pit of
  two cells there is jumped, a pit of three is not. For a pit under a
  ceiling run the arc of `Tick` with `BumpCeiling`, not the table.
- A passage one cell high cannot be jumped into. A pad that delivers the
  hero to one stops flush with its floor and waits there.
- A respawn point needs a floor: a wall below, or a pad with no path and
  no group under the cell's middle.
- A monster that carries a trigger (a title, `heroY`) and loses its floor
  falls into the pit with it: move it.

## The blockout

Drawn by script from `collision`, 1440x1080 (90 px a cell), nothing by
hand:

- transparent outside the structure;
- solid cells - flat mid-grey, with a lighter line on every edge between
  a solid cell and an open one;
- open cells inside the structure - flat dark navy. "Inside" is a flood
  fill from a cell of each room; a sealed chamber is filled from a cell
  of its own;
- a fan well - a black disc in a grey ring;
- a lamp - a white bar; a hazard mark - a yellow bar;
- no text, no numbers, no figures.

The plan is the same picture over the screen's backdrop, with the real
fans and a hero for scale, and numbers on it. **The plan never goes to
the generator**: it paints what it sees, blades included.

Nothing in the blockout may cross a floor. Two pipes drawn through a
corridor floor came back as a gap in the floor with a door in it.

## The seam between two screens

The game flips screens, it does not scroll: two screens are never seen
together. A seam has to read as a continuation - the same things at
about the same heights - and no more. What must be exact is the floor
line and the height of the doorway, and those the grid gives.

- Measure the neighbour's edge in its seated picture (level 2 screen 3,
  right edge: duct 105-143 units, ceiling slab 161-192, cables at 210,
  floor line 288) and put the same things at the same heights into the
  blockout.
- Send the generator a strip of that edge as a reference of its own,
  beside the blockout, and say the edge continues it line for line.
- Ten units of difference in a duct's thickness came back and are not
  seen across a flip.

## The prompt

Attach the blockout first, then the style references: art already
accepted next door (the tunnel gate, a finished room).

What a prompt must say, each line paid for by a generation that went
wrong:

- **One image only.** Asked for two variations, the generator returns
  both side by side on one canvas at half the size.
- **Transparent where the blockout is transparent**, and no rock, sky or
  background painted there.
- **Flat side view, no perspective.**
- **Floors strictly from the side: no visible top surface, no grating in
  perspective; the top edge of a floor is one straight line where the
  blockout has it.** A floor painted with its top face stands half a cell
  off the grid.
- **Which openings run off the edge of the image**, by name, and that no
  frame, door or wall closes them. Unsaid, the generator frames them.
- **Nothing hangs into a passage one figure tall.**
- **A fan well is empty**: a collar round a flat black opening, no
  blades, hub or grille.
- **What the game draws is not painted**: fan blades, smoke, steam,
  sparks, halos in the air, figures, monsters.
- **The inside is darker and lower in contrast than the structure**, so
  a bright figure reads against it.
- **Text**: one stencilled letter, one TeK emblem, nothing else.

The reading of the blockout is spelled out colour by colour: what
mid-grey, navy, a black disc, a white bar, a yellow mark stand for.

A separate object is asked for as "only the artwork that goes inside the
frame, edge to edge", with its bands given as shares of the height.
Props come as one row of separate things on a transparent background.

## When the picture comes back

Look at the alpha, not at the preview.

- A checkerboard that is part of the pixels (the file is RGB) is no
  transparency: ask again.
- Real transparency keeps junk colour under alpha 1-15; a viewer shows
  it as grey smudges. It is still a hole.

Then measure. Scan lines of alpha and brightness across the walls give
every edge in cells; a structure that fits the grid has all its edges at
one fraction of a cell. Draw the grid over the picture and look.

**A picture that is wrong is generated again, not repaired.** Retouching
and warping it costs more than a new generation and shows: a warp that
blends two fits across a wall bends the wall, and a lean of three
degrees reads as crooked. The picture is never resampled piece by piece.

**The grid is not sacred.** A picture that lies by a few units is better
than a bent one. The hero stands by the cell under his middle, so a wall
face a few units off is not seen. What lies by a whole cell is fixed in
`collision`, not in the picture.

**The generator does not hold a width.** Asked for a pit of four cells,
it gave three and a half in one generation and seven in two more. Take
the generation whose proportions are nearest to the old screen and move
the matter to it: a pit, a pair of crates, a monster are a few
characters in `collision` and `entities`.

What may be done to an accepted picture, and nothing else:

- moved as a whole by whole pixels, the part past the screen cut off;
- a fan well painted black, by its own alpha - through a transparent
  well the backdrop shows between the blades;
- a doorway at the edge of the screen carried to the edge by mirroring
  the columns beside it;
- as a last resort for a floor half a cell off, rows inserted above it
  as a palindrome of the rows right above (726, 725 .. 707, 708 .. 726,
  727): every row stays beside its neighbour, nothing is stretched. Over
  a dozen units of it is a reason to generate again.
- a band of whole columns taken out, from top to bottom, where all it
  crosses runs straight across or straight down (a duct, a slab, the
  back wall of a shaft): the place is the one where the column before
  the band differs least from the column after it, and the join is
  looked at. 41 columns left the shaft of level 2 screen 4 to make its
  pit 96 units. What stands on the band's line elsewhere (a junction
  box, a lamp, an emblem) rules the place out.

Whatever was done goes into the sprite's description in the set.

## Seating

- An object's `x`, `y` and `width` are whole units; its height follows
  the picture. A shift under a unit is put into the canvas, not into the
  numbers.
- A room is a canvas of 4:3 at 0, 0, width 512 - 1448x1086 as the
  generator gives it is fine, backdrop density. A small object is kept
  at 6 px a unit.
- A prop asked for as squares comes back as it likes: the crates of
  level 2 screen 4 are 1.16 wide to 1 tall. Scale it whole and split
  the lie between its top and its sides (70 units over two cells: 3 a
  side, 2 on top), feet on the floor line.
- Feet stand on a floor's top line. That line is the one to get right;
  ceilings and wall faces forgive a few units.
- Objects are drawn in file order: the room goes before what stands on
  it.
- Draw order of a frame: backdrop, sky, objects, pads, the back layer of
  the dynamics, tiles, figures, the front layer. A fan is in the back
  layer: over the room, under the hero.

## Fans

The art is ready in `ventilation.mset`; none is generated.

- `parent` is the room's tag; `x`, `y` - the middle of the well as
  measured in the seated picture, not as planned.
- `size`: the ring of the `spider` guard spans 82-95.5% of the half
  size, the blade tips of the `heavy` rotor end at 90.6%. A size of the
  opening divided by 0.9 lays the ring on the lip.
- `rpm`: blades are sharp up to 40, a smear from 110, a disc from 230. A
  big fan turns at about 20, a working pair at 60-70 with opposite
  signs, a turbine in a `bezel` plate at 150-180.
- `light` - the glow of the shaft; no `back` over a well painted black.
- A dynamic object rolls its dice from its place (`x`, `y`, `parent`):
  moved, it flickers anew; the order in the list is draw order only.

## Life on a screen

Every repainted screen gets a little life from the dynamics; the picture
is the steady state.

- One lamp a screen is painted unlit and lit by a `faulty` or `dying`
  beacon. Ask the generator for that one lamp switched off.
- **No beacon over a lamp painted lit**: it shows nothing.
- A slow pulse where something is alive, small indicators on machinery,
  sparks from a switchboard - each at its own pace.
- No beacon on the hero's path that would read as something to pick up
  or to avoid.

## Writing the level file

The file is formatted by hand in places: `rigs`, `pads`, `entities` and
`respawns` do not survive a round trip through a JSON writer. Rebuild
only the sections touched (`objects`, `dynamics`, `tiles` come out of a
two-space writer as they are) and carry the rest over as text. LF, no
BOM.

The level's own art lives in `<assetsDir>-objects.mset`, found by that
name, never declared. A new sprite is added at the end: the pictures
before it keep their bytes. A bare name carried by two attached sets
stops the level at load, and level 2 attaches `level1-structures`, which
holds `s01-` to `s17-` names of its own: check a new name against every
set the level declares.

## Checks without the compiler

- The file parses; only the sections meant to change differ from the
  one in the repository; `collision` and `entities` are as they were
  unless the change is about them.
- The loader's rules, ported: pad tags are unique; a stop keeps the pad
  on its screen; a `parent` is carried by exactly one of an object, a
  pad, an entity; a respawn point has a floor; no pad in a wall.
- Jumps, by the ported `JumpReach`, at every phase of every pad.
- The set reads back; the sprites before the new one are byte for byte.
- A preview: the backdrop at its tint, the objects, the fans, a hero on
  every floor. It is put together by hand and says so; it is not a
  screenshot.

None of this is a live run. First things to look at in the game: the
level loads, the hero stands on every floor, nothing hangs into a
passage.

## Commits

Data only, so no version in the subject. The subjects so far:

- `Put the level 2 screen 1-2 platforms on pads`
- `Stand level 2 screen 3 on a repainted room`
- `Stand level 2 screen 4 on a repainted room`

The docs follow in a commit of their own: the session in
`PORTING-NOTES.md`, both maps, and a line in `ASSETS.md` for every
generated picture. The release script lives outside the repository and
names the sets one by one: a new set has to be added to it.
