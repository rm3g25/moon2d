# docs/

One mechanic, one file. A session that builds a mechanic is written into
that mechanic's file, under its design; the journal of the project is the
sum of those files, not a diary of its own. The documents are of four
kinds, and the kind decides where a thing goes.

## The map

| file | kind | what it holds |
|---|---|---|
| `PORTING-NOTES.md` | handoff | what is: the status in a few lines, the architecture, the deliberate deviations from 2008, the debug keys, the open questions of the original. A session that builds starts here and, with its mechanic's file, stops here. |
| `ROADMAP.md` | roadmap | what comes next and in what order: the version lines, the boundary of the 3.0 release, the debt of version 3.0, the six steps after 3.0, the ideas without a place, the phases. A session that plans starts here. |
| `plans/<name>.md` | plan | the design of one thing not built yet (why, what is decided, what is proposed, what is open). When its work begins the file moves to `mechanics/` and grows a journal. |
| `PORT-JOURNAL.md` | log | the journal of the 2.x port as it was kept, part by part; closed, kept as written |
| `CHANGELOG.md` | log | what each version brought, newest first, one paragraph a version |
| `CODEBASE-MAP.md` | reference | every unit, type and data file, and which files a task touches. Regenerated once a release, patched in between; the code wins when they disagree. |
| `mechanics/<name>.md` | mechanic | the design of one mechanic (why, what is decided, the model, the architecture, the stages) and, at the end, the journal of the sessions that built it |
| `TESTING.md` | reference | what the test suite is for, its rules and the conveyor that writes it |
| `testing/<namespace>.md` | reference | the tables of the tests, one section per unit under test |
| `REPAINT.md` | guide | how a screen of levels 1-2 goes from 2008 tiles to HD art; its journal at the end |
| `MSET-FORMAT.md` | reference | the `.mset` sprite set format; the journal of its birth at the end |
| `lore/LORE.md`, `lore/LORE-ru.md` | canon | the universe; the source of every story text in the game |
| `moon2dscreen1.png`, `moon2dscreen2.png` | - | the screenshots of the root README |

## The plans

Not built. One file per thing, in the order of `ROADMAP.md`.

| file | what |
|---|---|
| `video-sprites.md` | step 1: the hero and the monsters from AI video on a green screen, the utility that cuts the frames |
| `wide-frame.md` | step 2: the 21x12 frame, a 4:3 level centered in it; what is in place and what is still hard-wired |
| `level-editor.md` | step 3: the editor on the game's own renderer, the assistant chat inside it, generation by reference |
| `level-3.md` | step 4: the residential sector, the first wide level |
| `train-level.md` | step 5: the ore train on the belt and the living backdrop of arena 3 |
| `big-rooms.md` | step 6: a room larger than the frame, the camera over it; the assessment against the code |
| `hero-forms.md` | several forms and henshins, the third kind of bullet |
| `selene-menu.md` | the menu moon becoming Selene; the texture is done |
| `wad-packing.md` | one container for the resources |

## The mechanics

| file | what |
|---|---|
| `arena-2.md` | level 2 screen 9, the gravel arena (first boss of level 2) |
| `arena-3/` | level 2 finale: the tunnels and the TEK machine (end of 3.0) - a folder, one file per part of the fight, its index in `arena-3/README.md` |
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
| `tek-platform.md` | the flying platform TEK-K10 in HD |
| `tek-tank.md` | the tank TEK-J02 in HD |
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
- A mechanic that outgrows one file (`arena-3/`): a folder named after
  it, one file per part, each with its design and its `## Journal`, and a
  `README.md` as the index - the files, the rules that hold for every
  part, how to read it. Section names stay unique across the folder, so a
  pointer by name still finds its place. The table above names the
  folder.
- A thing not built yet - a step of the roadmap, an idea waiting for its
  level: a file in `plans/`, named after the thing; its line in the
  table above. What is decided and what is only proposed are marked
  apart. When the work begins, `git mv` the file to `mechanics/`, give it
  the status line and a `## Journal`; its line moves between the tables.
- A decision about the order of things, a new step, a change of the
  release boundary: `ROADMAP.md`, the section that holds its kind.
- A version: a paragraph at the top of `CHANGELOG.md`, and the status of
  `PORTING-NOTES.md` replaced, not stacked - a few lines: the version,
  what is in work, where to read. The paragraph is CHANGELOG's.
- A test unit: its table in the `testing/` file of its namespace.
- A deviation from 2008, a debug key, an open question of the original:
  `PORTING-NOTES.md`, the section that already holds its kind.

## Language

The documents are in English. New text is English in every file, a
Russian one included. A Russian file is translated whole the first time
a session opens it for new work: a commit of its own that changes
nothing but the language, its numbers checked against the original. A
file nobody opens for new work stays as it was written.

Russian stays in three places:
- `lore/LORE-ru.md`: the source of the Russian texts of the game
  (`bin/lang/ru.json`).
- Quotes of 2008: names and strings from the original source and data,
  letter for letter - they are grep anchors to the original.
- Text the player sees in Russian, quoted as the game shows it.

## What a session reads

The documents are split so that a session takes only what its task
needs and the future does not leak into the present.

- **Building a mechanic** (a stage of arena 3, say): `PORTING-NOTES.md`,
  `mechanics/<name>.md`, `CODEBASE-MAP.md` for the units it touches,
  `TESTING.md` and its `testing/` file when it writes tests. Not
  `ROADMAP.md`, not `plans/`: a step that is not yet taken is not the
  context of the step under way, and a plan read beside a mechanic pulls
  the code toward a future that may still change.
- **Planning** (the order of steps, the shape of a thing not built):
  `ROADMAP.md`, the `plans/` file in question, and the mechanics files
  the plan leans on. The plan says what it leans on.
- **Opening a step of the roadmap**: its `plans/` file moves to
  `mechanics/` first (above), and from then on the session is a
  building one.
- **Repainting a screen of levels 1-2**: `REPAINT.md`.
- **The history of the port**: `PORT-JOURNAL.md`, `CHANGELOG.md`. Nobody
  needs it for current work.

## The one-line test

Asking "where does X live?" -> `CODEBASE-MAP.md`.
Asking "how does X work and why is it like that?" -> `mechanics/X.md`.
Asking "how will X work?" (not built) -> `plans/X.md`.
Asking "what comes next, and why in that order?" -> `ROADMAP.md`.
Asking "what state is the project in?" -> `PORTING-NOTES.md`, then
`CHANGELOG.md`.
Asking "how did the port go?" -> `PORT-JOURNAL.md`.
