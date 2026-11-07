# Level 4: the ore train (step 5 after 3.0)

Status: a direction, not a design; fifth of the six steps after 3.0
(`ROADMAP.md`). Nothing built; the lore is `lore/LORE.md`, section 9,
item 4.

## What it is
The ore transporter - the road down to the mines and the labs. A large
moving freight train: the interior of the wagons plus roof sections.
Wagons of different kinds - ore cars, crate cars, barrel cars.

## What exists for it (2026-11-07)
Arena 3 built the two things a moving train needs, so the level brings
almost no new engine code and is content on ready mechanics:
- **The belt** (`Game.Belt`): the world stands still on the screen and
  the road slides under it, carrying what rides on it, with a smooth
  ramp up to cruise and down from it. A train's floor is a road that
  runs; the wagon stands, the ground outside runs.
- **The living backdrop** (`Levels.FarPlane`, `Render.FarPlane`): layers
  moved by offsets per motion kind, elements riding by behind the play
  layer (the fangs of the chase), a sun in code. The land outside the
  windows is such a backdrop.
- **The chase itself** (`mechanics/arena-3.md`) as the reference for a
  screen in motion: the drifting pads, the pieces let go past the left
  edge, the hero carried in the air by the belt.
- The wagons of level 1 live in `train.mset` as whole wagons (no cut
  pieces); they are planned to be redrawn, not reused as they are.

## Open
- **Stationary or moving.** Moving needs the backdrop above and a way up
  onto the roof - a `screenUp` move between a wagon's interior and its
  roof. Decided neither way yet; the ready mechanics tilt it toward
  moving.
- Whether the roof sections run as separate screens over the interior
  ones, or as one room of two frames in height (`big-rooms.md` would make
  the second possible; the order puts it after this level).
