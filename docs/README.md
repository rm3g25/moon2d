# docs/

One mechanic, one file. A session that builds a mechanic is written into
that mechanic's file, under its design; the journal of the project is the
sum of those files, not a diary of its own. The documents are of four
kinds, and the kind decides where a thing goes.

## The map

| file | kind | what it holds |
|---|---|---|
| `PORTING-NOTES.md` | handoff | the current status, the architecture, the deliberate deviations from 2008, the debug keys, the strategy and the roadmap, the open questions of the original. A new session starts here. |
| `CHANGELOG.md` | log | what each version brought, newest first, one paragraph a version |
| `CODEBASE-MAP.md`, `CODEBASE-MAP-ru.md` | reference | every unit, type and data file, and which files a task touches. Regenerated once a release, patched in between; the code wins when they disagree. Both languages change together or neither does. |
| `mechanics/<name>.md` | mechanic | the design of one mechanic (why, what is decided, the model, the architecture, the stages) and, at the end, the journal of the sessions that built it |
| `TESTING.md` | reference | what the test suite is for, its rules and the conveyor that writes it |
| `testing/<namespace>.md` | reference | the tables of the tests, one section per unit under test |
| `REPAINT.md` | guide | how a screen of levels 1-2 goes from 2008 tiles to HD art; its journal at the end |
| `MSET-FORMAT.md` | reference | the `.mset` sprite set format; the journal of its birth at the end |
| `lore/LORE.md`, `lore/LORE-ru.md` | canon | the universe; the source of every story text in the game |
| `moon2dscreen1.png`, `moon2dscreen2.png` | - | the screenshots of the root README |

## The mechanics

| file | what |
|---|---|
| `arena-2.md` | level 2 screen 9, the gravel arena (first boss of level 2) |
| `arena-3.md` | level 2 finale: the tunnels and the TeK machine (end of 3.0) |
| `blasts.md` | the look of an explosion, sparks, the blast wave, the shards |
| `boss-1.md` | the level 1 boss TEK-R1 in HD, its pilot, the damage ceiling |
| `engine.md` | the frame: window, frame and screen, shake, settings, unit folders, draw batching, system requirements |
| `fans.md` | the `fan` dynamics |
| `font.md` | the bitmap font in HD |
| `graph.md` | the `graph` dynamics (the medlab monitor) |
| `henshin.md` | the henshin ceremony on orbs, the suit coming on and off |
| `hero-shroud.md` | the shroud: the hero's respawn and the glow after henshin |
| `hud.md` | the health monitor, the health rows, the bonus slot, the 2008 mode and its end |
| `level-objects.md` | static objects, dynamics in general, level events; the 3.0 release plan |
| `lightning.md` | the `lightning` dynamics: switchboards, wrecked machines, the boss |
| `menu.md` | the main menu |
| `monsters.md` | rules common to all monsters |
| `orbs.md` | the orbs: the flock, the aura, the harvest, the rain |
| `pads.md` | the pads: platforms, the falling pad, the shelf, the carousel, the decks |
| `pickups.md` | taking a medkit or a weapon in; the HD medkit |
| `scenes.md` | scenes without losing control; the first one, TEK-Q6 over screen 9 |
| `sky.md` | HD backdrops, the Earth in the sky, Selene |
| `smoke.md` | the `smoke` dynamics: gas, wrecked machines, the barrel |
| `tek-mount.md` | the ceiling mount in HD |
| `tek-platform.md` | the flying platform TeK-K10 in HD |
| `tek-tank.md` | the tank TeK-J02 in HD |
| `terminal.md` | the terminal: hints and the level briefing |

## How a mechanic's file is read

The head of the file is the design as it was written, with a status line
dated at the top; the journal at the end is newer than that line. When
the two disagree, the journal is right about what happened and the code
is right about what is. `CHANGELOG.md` says in one paragraph where a
version left things.

## Where a new thing goes

- A new mechanic: a new file in `mechanics/`, named after the thing, not
  after the stage (`shelf`, not `SHELF-PLAN`). The design goes in first;
  the sessions follow under `## Journal` (or `## Журнал`) as `###`
  headings, in the order they happened. A line for it in the table above.
- A session on an existing mechanic: at the end of its journal.
- A version: a paragraph at the top of `CHANGELOG.md`, and the status
  paragraph of `PORTING-NOTES.md` replaced, not stacked.
- A test unit: its table in the `testing/` file of its namespace.
- A deviation from 2008, a debug key, an open question of the original:
  `PORTING-NOTES.md`, the section that already holds its kind.

## The one-line test

Asking "where does X live?" -> `CODEBASE-MAP.md`.
Asking "how does X work and why is it like that?" -> `mechanics/X.md`.
Asking "what state is the project in?" -> `PORTING-NOTES.md`, then
`CHANGELOG.md`.
